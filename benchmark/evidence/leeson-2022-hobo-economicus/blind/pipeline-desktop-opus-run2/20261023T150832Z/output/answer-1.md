suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lubridate)
  library(fixest)
  library(car)
})
set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus.script-free/3 replication package/replicate/replicate/data"
rd <- function(f) suppressMessages(readr::read_csv(file.path(base, f), show_col_types = FALSE, guess_max = 10000))

visits  <- rd("metrovisitslog.csv")
pass    <- rd("passersby.csv")
friend  <- rd("friendliness.csv")
receipt <- rd("receipts.csv")
service <- rd("service.csv")
shuttle <- rd("shuttle.csv")

num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  suppressWarnings(readr::parse_number(as.character(x)))
}
normname <- function(x) gsub("[^a-z0-9]", "", tolower(trimws(as.character(x))))
parse_d <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  as.Date(suppressWarnings(lubridate::parse_date_time(as.character(x),
          orders = c("Ymd", "mdY", "mdy", "dbY", "dBY", "dmY", "Ymd HMS", "mdY HM"))))
}

# Map a vector of names onto a set of canonical (visit-log) names
map_names <- function(x, canon) {
  nx <- normname(x); nc <- normname(canon)
  out <- canon[match(nx, nc)]
  miss <- which(is.na(out) & !is.na(x))
  for (i in miss) {
    # containment match
    hit <- which(sapply(nc, function(cc) grepl(cc, nx[i], fixed = TRUE) || grepl(nx[i], cc, fixed = TRUE)))
    if (length(hit) == 1) { out[i] <- canon[hit]; next }
    d <- adist(nx[i], nc)[1, ]
    if (min(d) <= max(3, 0.3 * nchar(nx[i]))) out[i] <- canon[which.min(d)]
  }
  out
}

# ---------------- Table 2 ----------------
visits <- visits %>% filter(!is.na(metro))
visits$panhandlers <- num(visits$panhandlers)
visits$date_raw <- as.character(visits$date)
visits$d <- parse_d(visits$date)
canon <- unique(as.character(visits$metro))

is_gt <- grepl("georgetown|wisconsin", normname(canon))
gt_name <- if (any(is_gt)) canon[is_gt][1] else NA
fb_cands <- canon[grepl("foggy", normname(canon))]

# passersby
pass$metro_c <- map_names(pass$metro, canon)
mo <- pass$month
if (is.numeric(mo)) {
  pass$mon <- as.integer(mo)
} else {
  mm <- suppressWarnings(as.integer(as.character(mo)))
  ab <- match(substr(tolower(as.character(mo)), 1, 3), tolower(month.abb))
  pass$mon <- ifelse(is.na(mm), ab, mm)
}
pass$yr <- as.integer(num(pass$year))
pass$yr <- ifelse(!is.na(pass$yr) & pass$yr < 100, pass$yr + 2000L, pass$yr)
pass$passersby <- num(pass$passersby)
# Georgetown gets Foggy Bottom-GWU's exits
if (!is.na(gt_name) && !any(pass$metro_c == gt_name, na.rm = TRUE)) {
  fb_rows <- pass[grepl("foggy", normname(pass$metro)), ]
  if (nrow(fb_rows) > 0) {
    fb_rows$metro_c <- gt_name
    pass <- bind_rows(pass, fb_rows)
  }
}
pass_m <- pass %>% filter(!is.na(metro_c), !is.na(mon), !is.na(yr)) %>%
  group_by(metro_c, mon, yr) %>% summarise(passersby = mean(passersby, na.rm = TRUE), .groups = "drop")
# Table 1 units: thousands of exits per month
if (mean(pass_m$passersby, na.rm = TRUE) > 20000) pass_m$passersby <- pass_m$passersby / 1000

# friendliness: each passerby's friendliest (max) response, averaged by station
rcols <- grep("^passresp", names(friend), value = TRUE)
fr <- as.data.frame(lapply(friend[rcols], num))
fr[fr <= 0 | fr > 5] <- NA
friend$best <- apply(fr, 1, function(r) if (all(is.na(r))) NA_real_ else max(r, na.rm = TRUE))
friend$metro_c <- map_names(friend$metro, canon)
fr_st <- friend %>% filter(!is.na(metro_c), !is.na(best)) %>%
  group_by(metro_c) %>% summarise(friendliness = mean(best), .groups = "drop")

# shuttle and service indicators: within a 10-minute walk
service$metro_c <- map_names(service$metro, canon)
service$homeless_service <- as.integer(num(service$servicemin) <= 10)
shuttle$metro_c <- map_names(shuttle$metro, canon)
shuttle$shuttle_stop <- as.integer(num(shuttle$shuttlemin) <= 10)
sv <- service %>% filter(!is.na(metro_c)) %>% group_by(metro_c) %>% summarise(homeless_service = max(homeless_service, na.rm = TRUE), .groups = "drop")
sh <- shuttle %>% filter(!is.na(metro_c)) %>% group_by(metro_c) %>% summarise(shuttle_stop = max(shuttle_stop, na.rm = TRUE), .groups = "drop")

dat <- visits %>%
  mutate(metro_c = as.character(metro), mon = month(d), yr = year(d)) %>%
  left_join(pass_m, by = c("metro_c", "mon", "yr")) %>%
  left_join(fr_st, by = "metro_c") %>%
  left_join(sv, by = "metro_c") %>%
  left_join(sh, by = "metro_c")

# fallback: if passersby missing for a visit month, use nearest available month for that station
if (any(is.na(dat$passersby))) {
  for (i in which(is.na(dat$passersby))) {
    pm <- pass_m[pass_m$metro_c == dat$metro_c[i], ]
    if (nrow(pm) > 0 && !is.na(dat$d[i])) {
      dd <- abs((pm$yr * 12 + pm$mon) - (dat$yr[i] * 12 + dat$mon[i]))
      if (min(dd) <= 1) dat$passersby[i] <- pm$passersby[which.min(dd)]
    }
  }
}
dat$datefe <- factor(dat$date_raw)

five_pat <- c("farragutnorth", "farragutwest", "gallery", "mcpherson", "metrocenter")
nm <- normname(dat$metro_c)
dat$five <- Reduce(`|`, lapply(five_pat, function(p) grepl(p, nm, fixed = TRUE)))

fml <- panhandlers ~ passersby + friendliness + shuttle_stop + homeless_service | datefe
m1 <- tryCatch(feols(fml, data = dat, cluster = ~metro_c), error = function(e) NULL)
m2 <- tryCatch(feols(fml, data = dat[dat$five, ], cluster = ~metro_c), error = function(e) NULL)

gc <- function(m, v) if (is.null(m)) NA else { cf <- coef(m); if (v %in% names(cf)) unname(cf[v]) else NA }

# ---------------- Tables 3-4 ----------------
receipt$donations <- num(receipt$donations)
receipt$minutes <- num(receipt$minutes)
receipt$cash <- num(receipt$cash)
receipt$inkind <- num(receipt$inkind)
receipt$station <- factor(receipt$metro)

dA <- receipt %>% filter(!is.na(donations), !is.na(minutes), minutes > 0) %>%
  mutate(y = donations / minutes * 60)
dB <- receipt %>% filter(!is.na(cash), !is.na(minutes), minutes > 0) %>%
  mutate(y = (cash + ifelse(is.na(inkind), 0, inkind)) / minutes * 60)
dA$station <- droplevels(dA$station); dB$station <- droplevels(dB$station)

bf <- function(d) tryCatch(car::leveneTest(y ~ station, data = d, center = median)[1, "F value"], error = function(e) NA)
af <- function(d) tryCatch(summary(aov(y ~ station, data = d))[[1]][1, "F value"], error = function(e) NA)

out <- c(
  passersby_full_sample = gc(m1, "passersby"),
  passersby_five_station_subsample = gc(m2, "passersby"),
  friendliness_full_sample = gc(m1, "friendliness"),
  shuttle_stop_full_sample = gc(m1, "shuttle_stop"),
  shuttle_stop_five_station_subsample = gc(m2, "shuttle_stop"),
  brown_forsythe_donations_per_hour = bf(dA),
  brown_forsythe_dollars_per_hour = bf(dB),
  anova_f_donations_per_hour = af(dA),
  anova_f_dollars_per_hour = af(dB),
  station_visits_full_sample = if (is.null(m1)) NA else nobs(m1),
  station_visits_five_station_subsample = if (is.null(m2)) NA else nobs(m2)
)
for (n in names(out)) cat(sprintf("RESULT:%s=%s\n", n, format(out[[n]], digits = 10)))
