suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lubridate)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus.script-free/3 replication package/replicate/replicate/data"
rd <- function(f) suppressMessages(readr::read_csv(file.path(base, f), show_col_types = FALSE))

visits  <- rd("metrovisitslog.csv")
pass    <- rd("passersby.csv")
friend  <- rd("friendliness.csv")
shuttle <- rd("shuttle.csv")
service <- rd("service.csv")
receipts <- rd("receipts.csv")

normkey <- function(x) gsub("[^a-z0-9]", "", tolower(trimws(as.character(x))))

# map keys in 'from' to keys in 'ref' (exact first, then approximate)
map_keys <- function(from, ref) {
  ref <- unique(ref)
  sapply(from, function(k) {
    if (is.na(k)) return(NA_character_)
    if (k %in% ref) return(k)
    hit <- ref[startsWith(ref, k) | startsWith(k, ref)]
    if (length(hit) >= 1) return(hit[which.max(nchar(hit))])
    d <- adist(k, ref)
    ref[which.min(d)]
  }, USE.NAMES = FALSE)
}

parse_dt <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  d <- suppressWarnings(as.Date(lubridate::parse_date_time(as.character(x),
              orders = c("mdy", "ymd", "dmy", "mdY", "Ymd", "dmY", "dby", "dbY", "bdY", "bdy"))))
  d
}

parse_num <- function(x) {
  if (is.numeric(x)) return(x)
  suppressWarnings(readr::parse_number(as.character(x)))
}

# ---------------- Visits ----------------
visits <- visits %>% mutate(key = normkey(metro), d = parse_dt(date),
                            mon = month(d), yr = year(d),
                            panhandlers = parse_num(panhandlers))
cat(sprintf("SAMPLE:full:loaded=%d\n", nrow(visits)))

# ---------------- Passersby ----------------
mon_parse <- function(m) {
  if (is.numeric(m)) return(as.integer(m))
  mm <- suppressWarnings(as.integer(m))
  idx <- is.na(mm)
  if (any(idx)) mm[idx] <- match(tolower(substr(trimws(m[idx]), 1, 3)), tolower(month.abb))
  mm
}
pass <- pass %>% mutate(key = normkey(metro), mon = mon_parse(month),
                        yr = as.integer(parse_num(year)),
                        passersby = parse_num(passersby))
pass$yr <- ifelse(!is.na(pass$yr) & pass$yr < 100, pass$yr + 2000L, pass$yr)
pass$key <- map_keys(pass$key, unique(visits$key))
pass <- pass %>% group_by(key, mon, yr) %>% summarise(passersby = mean(passersby, na.rm = TRUE), .groups = "drop")

# Georgetown gets Foggy Bottom-GWU's ridership
gt_key <- unique(visits$key[grepl("georgetown|wisconsin", visits$key)])
fb_key <- unique(c(visits$key, pass$key)[grepl("foggy", c(visits$key, pass$key))])
if (length(gt_key) >= 1 && length(fb_key) >= 1) {
  fb <- pass %>% filter(key == fb_key[1])
  for (g in gt_key) {
    pass <- pass %>% filter(key != g)
    pass <- bind_rows(pass, fb %>% mutate(key = g))
  }
}
if (mean(pass$passersby, na.rm = TRUE) > 10000) pass$passersby <- pass$passersby / 1000

# ---------------- Friendliness ----------------
rcols <- grep("^passresp", names(friend), value = TRUE)
friend[rcols] <- lapply(friend[rcols], parse_num)
friend$best <- apply(as.matrix(friend[rcols]), 1, function(r) if (all(is.na(r))) NA_real_ else max(r, na.rm = TRUE))
friend$key <- map_keys(normkey(friend$metro), unique(visits$key))
fr_st <- friend %>% group_by(key) %>% summarise(friendliness = mean(best, na.rm = TRUE), .groups = "drop")

# ---------------- Shuttle / service ----------------
shuttle <- shuttle %>% mutate(key = map_keys(normkey(metro), unique(visits$key)),
                              shuttlemin = parse_num(shuttlemin),
                              shuttle_stop = as.integer(!is.na(shuttlemin) & shuttlemin <= 10)) %>%
  group_by(key) %>% summarise(shuttle_stop = max(shuttle_stop), .groups = "drop")
service <- service %>% mutate(key = map_keys(normkey(metro), unique(visits$key)),
                              servicemin = parse_num(servicemin),
                              homeless_service = as.integer(!is.na(servicemin) & servicemin <= 10)) %>%
  group_by(key) %>% summarise(homeless_service = max(homeless_service), .groups = "drop")

# ---------------- Merge ----------------
df <- visits %>%
  left_join(pass, by = c("key", "mon", "yr")) %>%
  left_join(fr_st, by = "key") %>%
  left_join(shuttle, by = "key") %>%
  left_join(service, by = "key") %>%
  mutate(date_fe = as.character(d), metro_cl = key)
cat(sprintf("SAMPLE:full:merged_station_characteristics=%d\n", nrow(df)))

five_pat <- "farragutnorth|farragutwest|gallery|mcpherson|metrocenter"
df5 <- df %>% filter(grepl(five_pat, key))
cat(sprintf("SAMPLE:five_station:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:five_station:five_downtown_stations=%d\n", nrow(df5)))

fml <- panhandlers ~ passersby + friendliness + shuttle_stop + homeless_service | date_fe
m1 <- feols(fml, data = df, cluster = ~metro_cl)
m2 <- feols(fml, data = df5, cluster = ~metro_cl)
cat(sprintf("SAMPLE:full:estimation=%d\n", nobs(m1)))
cat(sprintf("SAMPLE:five_station:estimation=%d\n", nobs(m2)))

getc <- function(m, v) { cf <- coef(m); if (v %in% names(cf)) unname(cf[v]) else NA_real_ }
gets <- function(m, v) { s <- sqrt(diag(vcov(m))); if (v %in% names(s)) unname(s[v]) else NA_real_ }

# ---------------- Receipts ----------------
receipts <- receipts %>% mutate(
  station = factor(normkey(metro)),
  donations = parse_num(donations), minutes = parse_num(minutes),
  cash = parse_num(cash), inkind = parse_num(inkind),
  donations_per_hour = donations / minutes * 60,
  dollars = ifelse(is.na(cash) & is.na(inkind), NA_real_,
                   ifelse(is.na(cash), 0, cash) + ifelse(is.na(inkind), 0, inkind)),
  dollars_per_hour = dollars / minutes * 60)

rA <- receipts %>% filter(!is.na(donations_per_hour) & is.finite(donations_per_hour))
cat(sprintf("SAMPLE:receipts_donations:loaded=%d\n", nrow(receipts)))
cat(sprintf("SAMPLE:receipts_donations:estimation=%d\n", nrow(rA)))
rB <- receipts %>% filter(!is.na(dollars_per_hour) & is.finite(dollars_per_hour))
cat(sprintf("SAMPLE:receipts_dollars:loaded=%d\n", nrow(receipts)))
cat(sprintf("SAMPLE:receipts_dollars:dollar_count_available=%d\n", nrow(rB)))
cat(sprintf("SAMPLE:receipts_dollars:estimation=%d\n", nrow(rB)))

bf_test <- function(y, g) {
  g <- droplevels(factor(g))
  med <- ave(y, g, FUN = median)
  z <- abs(y - med)
  a <- anova(lm(z ~ g))
  a[["F value"]][1]
}
anova_f <- function(y, g) {
  g <- droplevels(factor(g))
  a <- anova(lm(y ~ g))
  a[["F value"]][1]
}

bfA <- bf_test(rA$donations_per_hour, rA$station)
bfB <- bf_test(rB$dollars_per_hour, rB$station)
fA <- anova_f(rA$donations_per_hour, rA$station)
fB <- anova_f(rB$dollars_per_hour, rB$station)

cat(sprintf("RESULT:passersby_full_sample=%.8f\n", getc(m1, "passersby")))
cat(sprintf("RESULT:passersby_full_sample_se=%.8f\n", gets(m1, "passersby")))
cat(sprintf("RESULT:passersby_five_station_subsample=%.8f\n", getc(m2, "passersby")))
cat(sprintf("RESULT:passersby_five_station_subsample_se=%.8f\n", gets(m2, "passersby")))
cat(sprintf("RESULT:friendliness_full_sample=%.8f\n", getc(m1, "friendliness")))
cat(sprintf("RESULT:friendliness_full_sample_se=%.8f\n", gets(m1, "friendliness")))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.8f\n", getc(m1, "shuttle_stop")))
cat(sprintf("RESULT:shuttle_stop_full_sample_se=%.8f\n", gets(m1, "shuttle_stop")))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.8f\n", getc(m2, "shuttle_stop")))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample_se=%.8f\n", gets(m2, "shuttle_stop")))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.8f\n", bfA))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.8f\n", bfB))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.8f\n", fA))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.8f\n", fB))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", as.integer(nobs(m1))))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", as.integer(nobs(m2))))