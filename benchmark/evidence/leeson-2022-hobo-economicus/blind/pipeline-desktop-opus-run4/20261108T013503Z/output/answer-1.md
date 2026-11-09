suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lubridate)
  library(fixest)
  library(car)
})
set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus.script-free/3 replication package/replicate/replicate/data"
rd <- function(f) read_csv(file.path(base, f), col_types = cols(.default = col_character()), show_col_types = FALSE)

visits   <- rd("metrovisitslog.csv")
pass     <- rd("passersby.csv")
friend   <- rd("friendliness.csv")
service  <- rd("service.csv")
shuttle  <- rd("shuttle.csv")
receipts <- rd("receipts.csv")

normkey <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x <- gsub("[^a-z0-9]+", " ", x)
  trimws(gsub("\\s+", " ", x))
}
num <- function(x) suppressWarnings(readr::parse_number(as.character(x)))
pdate <- function(x) {
  d <- suppressWarnings(parse_date_time(x, orders = c("mdy", "ymd", "dmy", "mdY HM", "ymd HMS")))
  as.Date(d)
}

# ---------------- Visits ----------------
visits <- visits %>%
  mutate(key = normkey(metro),
         dte = pdate(date),
         panhandlers = num(panhandlers)) %>%
  filter(!is.na(panhandlers))
visits$vmonth <- month(visits$dte)
visits$vyear  <- year(visits$dte)

# ---------------- Passersby (monthly exits) ----------------
mon <- pass$month
mnum <- suppressWarnings(as.numeric(mon))
if (any(is.na(mnum) & !is.na(mon))) {
  mm <- match(substr(tolower(trimws(mon)), 1, 3), tolower(month.abb))
  mnum <- ifelse(is.na(mnum), mm, mnum)
}
pass <- pass %>%
  mutate(key = normkey(metro), pmonth = mnum, pyear = num(year), passersby = num(passersby))
yr <- pass$pyear
pass$pyear <- ifelse(!is.na(yr) & yr < 100, yr + 2000, yr)

# Georgetown assigned Foggy Bottom-GWU's exits
gt_keys <- unique(visits$key[grepl("georgetown|wisconsin", visits$key)])
fb_key  <- unique(pass$key[grepl("foggy", pass$key)])
if (length(gt_keys) > 0 && length(fb_key) > 0) {
  pass <- pass %>% filter(!(key %in% gt_keys))
  fb <- pass %>% filter(key == fb_key[1])
  for (g in gt_keys) pass <- bind_rows(pass, fb %>% mutate(key = g))
}
pass_m <- pass %>% group_by(key, pmonth, pyear) %>% summarise(passersby = mean(passersby, na.rm = TRUE), .groups = "drop")

# ---------------- Friendliness ----------------
rcols <- grep("^passresp", names(friend), value = TRUE)
rmat <- sapply(rcols, function(cc) num(friend[[cc]]))
if (is.null(dim(rmat))) rmat <- matrix(rmat, nrow = 1)
vals <- unique(as.vector(rmat[!is.na(rmat)]))
if (all(vals %in% c(0, 1))) {
  lev <- as.numeric(gsub("\\D", "", rcols))
  best <- apply(rmat, 1, function(r) { k <- which(r == 1); if (length(k) == 0) NA_real_ else max(lev[k]) })
} else {
  best <- apply(rmat, 1, function(r) if (all(is.na(r))) NA_real_ else max(r, na.rm = TRUE))
}
friend$best <- best
friend_s <- friend %>% mutate(key = normkey(metro)) %>%
  group_by(key) %>% summarise(friendliness = mean(best, na.rm = TRUE), .groups = "drop")

# ---------------- Service & shuttle ----------------
service_s <- service %>% mutate(key = normkey(metro), smin = num(servicemin)) %>%
  group_by(key) %>% summarise(homeless_service = as.numeric(min(smin, na.rm = TRUE) <= 10), .groups = "drop")
shuttle_s <- shuttle %>% mutate(key = normkey(metro), shmin = num(shuttlemin)) %>%
  group_by(key) %>% summarise(shuttle_stop = as.numeric(min(shmin, na.rm = TRUE) <= 10), .groups = "drop")

# ---------------- Merge ----------------
df <- visits %>%
  left_join(pass_m, by = c("key" = "key", "vmonth" = "pmonth", "vyear" = "pyear")) %>%
  left_join(friend_s, by = "key") %>%
  left_join(service_s, by = "key") %>%
  left_join(shuttle_s, by = "key")

# Table 1 units: thousands of exits per month
if (mean(df$passersby, na.rm = TRUE) > 5000) df$passersby <- df$passersby / 1000
df$date_fe <- as.character(df$dte)
df$date_fe[is.na(df$date_fe)] <- as.character(df$date[is.na(df$date_fe)])

# Five-station subsample
five_pat <- c("farragut north", "farragut west", "gallery", "mcpherson", "metro cent")
five_keys <- unique(df$key[sapply(df$key, function(k) any(sapply(five_pat, function(p) grepl(p, k))))])
if (length(five_keys) != 5) {
  rk <- unique(normkey(receipts$metro))
  if (length(intersect(rk, unique(df$key))) == 5) five_keys <- intersect(rk, unique(df$key))
}

fml <- panhandlers ~ passersby + friendliness + shuttle_stop + homeless_service | date_fe
m1 <- feols(fml, data = df, cluster = ~key)
df5 <- df %>% filter(key %in% five_keys)
m2 <- feols(fml, data = df5, cluster = ~key)

getc <- function(m, v) { cf <- coef(m); if (v %in% names(cf)) unname(cf[v]) else NA_real_ }

# ---------------- Receipts ----------------
rc <- receipts %>%
  mutate(station = factor(normkey(metro)),
         donations = num(donations), minutes = num(minutes),
         cash = num(cash), inkind = num(inkind))
rc <- rc %>% mutate(don_hr = donations / minutes * 60)
rA <- rc %>% filter(!is.na(don_hr), is.finite(don_hr))
rB <- rc %>% filter(!(is.na(cash) & is.na(inkind)), !is.na(minutes)) %>%
  mutate(dol_hr = (ifelse(is.na(cash), 0, cash) + ifelse(is.na(inkind), 0, inkind)) / minutes * 60) %>%
  filter(is.finite(dol_hr))
rA$station <- droplevels(rA$station); rB$station <- droplevels(rB$station)

bfA <- leveneTest(don_hr ~ station, data = rA, center = median)
bfB <- leveneTest(dol_hr ~ station, data = rB, center = median)
aA <- summary(aov(don_hr ~ station, data = rA))[[1]]
aB <- summary(aov(dol_hr ~ station, data = rB))[[1]]

cat(sprintf("RESULT:passersby_full_sample=%.8f\n", getc(m1, "passersby")))
cat(sprintf("RESULT:passersby_five_station_subsample=%.8f\n", getc(m2, "passersby")))
cat(sprintf("RESULT:friendliness_full_sample=%.8f\n", getc(m1, "friendliness")))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.8f\n", getc(m1, "shuttle_stop")))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.8f\n", getc(m2, "shuttle_stop")))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.6f\n", bfA[1, "F value"]))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.6f\n", bfB[1, "F value"]))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.6f\n", aA[1, "F value"]))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.6f\n", aB[1, "F value"]))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", nobs(m1)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", nobs(m2)))
