suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lubridate)
  library(fixest)
  library(car)
})
set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus.script-free/3 replication package/replicate/replicate/data"
rd <- function(f) suppressWarnings(suppressMessages(read_csv(file.path(base, f), show_col_types = FALSE, guess_max = 10000)))

visits <- rd("metrovisitslog.csv")
pass   <- rd("passersby.csv")
friend <- rd("friendliness.csv")
serv   <- rd("service.csv")
shut   <- rd("shuttle.csv")
rec    <- rd("receipts.csv")

names(visits) <- tolower(names(visits)); names(pass) <- tolower(names(pass))
names(friend) <- tolower(names(friend)); names(serv) <- tolower(names(serv))
names(shut) <- tolower(names(shut)); names(rec) <- tolower(names(rec))

norm <- function(x) gsub("[^a-z0-9]", "", tolower(trimws(as.character(x))))
num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  suppressWarnings(readr::parse_number(as.character(x)))
}
pdate <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  d <- suppressWarnings(as.Date(parse_date_time(as.character(x),
         orders = c("mdy", "ymd", "dmy", "mdy HM", "ymd HMS", "mdY", "dbY", "bdY"), quiet = TRUE)))
  d
}

# map each key in 'from' to the best matching key in 'to'
match_keys <- function(from, to) {
  to <- unique(to[!is.na(to)])
  sapply(from, function(k) {
    if (is.na(k)) return(NA_character_)
    if (k %in% to) return(k)
    hit <- to[startsWith(to, k) | startsWith(k, to)]
    if (length(hit) >= 1) return(hit[which.max(nchar(hit))])
    hit <- to[startsWith(to, substr(k, 1, 8)) | startsWith(k, substr(to, 1, 8))]
    if (length(hit) == 1) return(hit)
    a <- agrep(k, to, max.distance = 0.2, value = TRUE)
    if (length(a) >= 1) return(a[1])
    a <- agrep(substr(k, 1, 10), to, max.distance = 0.2, value = TRUE)
    if (length(a) >= 1) return(a[1])
    NA_character_
  }, USE.NAMES = FALSE)
}

# ---------------- Visits panel ----------------
visits <- visits %>%
  mutate(key = norm(metro), d = pdate(date), panhandlers = num(panhandlers)) %>%
  filter(!is.na(panhandlers), !is.na(key), key != "")

# Passersby
pass <- pass %>% mutate(key = norm(metro), year = num(year))
if (is.numeric(pass$month)) {
  pass$mon <- as.integer(pass$month)
} else {
  m <- tolower(trimws(as.character(pass$month)))
  mon <- suppressWarnings(as.integer(m))
  mi <- match(m, tolower(month.name)); mon[is.na(mon)] <- mi[is.na(mon)]
  mi <- match(substr(m, 1, 3), tolower(month.abb)); mon[is.na(mon)] <- mi[is.na(mon)]
  pass$mon <- mon
}
pass$year[!is.na(pass$year) & pass$year < 100] <- pass$year[!is.na(pass$year) & pass$year < 100] + 2000
pass$passersby <- num(pass$passersby)
pass <- pass %>% group_by(key, year, mon) %>% summarise(passersby = mean(passersby, na.rm = TRUE), .groups = "drop")

vkeys <- unique(visits$key)
pk <- match_keys(vkeys, unique(pass$key))
names(pk) <- vkeys
# Georgetown gets Foggy Bottom-GWU's ridership
fb <- unique(pass$key)[grepl("foggy", unique(pass$key))]
for (k in vkeys) {
  if (grepl("georgetown|wisconsin", k) && (is.na(pk[k]) || !grepl("georgetown|wisconsin", pk[k])) && length(fb) > 0) pk[k] <- fb[1]
}
visits$pkey <- pk[visits$key]
visits$year <- year(visits$d); visits$mon <- month(visits$d)
visits <- visits %>% left_join(pass, by = c("pkey" = "key", "year" = "year", "mon" = "mon"))
# fallback: station mean if month missing
if (any(is.na(visits$passersby))) {
  pm <- pass %>% group_by(key) %>% summarise(pmean = mean(passersby, na.rm = TRUE), .groups = "drop")
  visits <- visits %>% left_join(pm, by = c("pkey" = "key")) %>%
    mutate(passersby = ifelse(is.na(passersby), pmean, passersby)) %>% select(-pmean)
}
# scale to Table 1 units (thousands of exits per month, mean ~349)
mp <- mean(visits$passersby, na.rm = TRUE)
if (is.finite(mp)) {
  if (mp > 50000) visits$passersby <- visits$passersby / 1000
  else if (mp > 2000 && mp <= 50000) {
    # likely daily average exits: convert to thousands per month
    visits$passersby <- visits$passersby * 30 / 1000
  }
}

# Friendliness: station average of each passerby's friendliest response
rcols <- grep("^passresp", names(friend), value = TRUE)
fr <- friend
for (cc in rcols) fr[[cc]] <- num(fr[[cc]])
fr$best <- apply(as.data.frame(fr[, rcols]), 1, function(r) if (all(is.na(r))) NA_real_ else max(r, na.rm = TRUE))
fr <- fr %>% mutate(key = norm(metro)) %>% filter(!is.na(best)) %>%
  group_by(key) %>% summarise(friendliness = mean(best), .groups = "drop")
fk <- match_keys(vkeys, fr$key); names(fk) <- vkeys
visits$fkey <- fk[visits$key]
visits <- visits %>% left_join(fr, by = c("fkey" = "key"))

# Service and shuttle dummies (within 10-minute walk)
serv <- serv %>% mutate(key = norm(metro), servicemin = num(servicemin)) %>%
  group_by(key) %>% summarise(servicemin = min(servicemin, na.rm = TRUE), .groups = "drop")
shut <- shut %>% mutate(key = norm(metro), shuttlemin = num(shuttlemin)) %>%
  group_by(key) %>% summarise(shuttlemin = min(shuttlemin, na.rm = TRUE), .groups = "drop")
sk <- match_keys(vkeys, serv$key); names(sk) <- vkeys
hk <- match_keys(vkeys, shut$key); names(hk) <- vkeys
visits$skey <- sk[visits$key]; visits$hkey <- hk[visits$key]
visits <- visits %>% left_join(serv, by = c("skey" = "key")) %>% left_join(shut, by = c("hkey" = "key")) %>%
  mutate(service = as.numeric(servicemin <= 10), shuttle = as.numeric(shuttlemin <= 10),
         datef = factor(as.character(ifelse(is.na(d), as.character(date), as.character(d)))))

five_pat <- "farragutnorth|farragutwest|gallery|mcpherson|metrocenter"
visits$five <- grepl(five_pat, visits$key)

res <- list()
fit_col <- function(dat) {
  feols(panhandlers ~ passersby + friendliness + shuttle + service | datef, data = dat, cluster = ~key)
}
m1 <- tryCatch(fit_col(visits), error = function(e) { message("m1: ", conditionMessage(e)); NULL })
m2 <- tryCatch(fit_col(visits[visits$five, ]), error = function(e) { message("m2: ", conditionMessage(e)); NULL })

if (!is.null(m1)) {
  cf <- coef(m1); se <- tryCatch(sqrt(diag(vcov(m1))), error = function(e) NULL)
  res$passersby_full_sample <- cf["passersby"]
  res$friendliness_full_sample <- cf["friendliness"]
  res$shuttle_stop_full_sample <- cf["shuttle"]
  res$station_visits_full_sample <- nobs(m1)
  if (!is.null(se)) {
    res$passersby_full_sample_se <- se["passersby"]
    res$friendliness_full_sample_se <- se["friendliness"]
    res$shuttle_stop_full_sample_se <- se["shuttle"]
  }
}
if (!is.null(m2)) {
  cf <- coef(m2); se <- tryCatch(sqrt(diag(vcov(m2))), error = function(e) NULL)
  res$passersby_five_station_subsample <- cf["passersby"]
  res$shuttle_stop_five_station_subsample <- cf["shuttle"]
  res$station_visits_five_station_subsample <- nobs(m2)
  if (!is.null(se)) {
    res$passersby_five_station_subsample_se <- se["passersby"]
    res$shuttle_stop_five_station_subsample_se <- se["shuttle"]
  }
}

# ---------------- Receipts tests ----------------
rec <- rec %>% mutate(donations = num(donations), minutes = num(minutes),
                      cash = num(cash), inkind = num(inkind), station = factor(norm(metro)))
dec <- rec$declinedoffer
if (!is.numeric(dec)) {
  dl <- tolower(trimws(as.character(dec)))
  dec <- ifelse(dl %in% c("1", "yes", "y", "true", "declined"), 1,
                ifelse(dl %in% c("0", "no", "n", "false"), 0, NA))
}
rec$dec <- dec
rec <- rec %>% filter(!is.na(minutes), minutes > 0)
rec$don_hr <- rec$donations / rec$minutes * 60
dol_ok <- !is.na(rec$cash) & (is.na(rec$dec) | rec$dec != 1)
if (sum(dol_ok) == 0) dol_ok <- !is.na(rec$cash) | !is.na(rec$inkind)
rec$dol_hr <- ifelse(dol_ok, (ifelse(is.na(rec$cash), 0, rec$cash) + ifelse(is.na(rec$inkind), 0, rec$inkind)) / rec$minutes * 60, NA)

A <- rec %>% filter(!is.na(don_hr))
B <- rec %>% filter(!is.na(dol_hr))
A$station <- droplevels(A$station); B$station <- droplevels(B$station)

bf <- function(dat, y) tryCatch(leveneTest(dat[[y]], dat$station, center = median)[1, "F value"], error = function(e) NA)
af <- function(dat, y) tryCatch({ s <- summary(aov(dat[[y]] ~ dat$station))[[1]]; s[1, "F value"] }, error = function(e) NA)
kw <- function(dat, y) tryCatch(unname(kruskal.test(dat[[y]], dat$station)$statistic), error = function(e) NA)

res$brown_forsythe_donations_per_hour <- bf(A, "don_hr")
res$brown_forsythe_dollars_per_hour <- bf(B, "dol_hr")
res$anova_f_donations_per_hour <- af(A, "don_hr")
res$anova_f_dollars_per_hour <- af(B, "dol_hr")
res$kruskal_wallis_donations_per_hour <- kw(A, "don_hr")
res$kruskal_wallis_dollars_per_hour <- kw(B, "dol_hr")
res$n_donations_obs <- nrow(A)
res$n_dollars_obs <- nrow(B)

for (nm in names(res)) {
  v <- suppressWarnings(as.numeric(res[[nm]])[1])
  if (!is.na(v) && is.finite(v)) cat(sprintf("RESULT:%s=%.6f\n", nm, v))
}