# Leeson (2022) reproduction: Table 2 regressions and Tables 3-4 equalisation tests.
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(lubridate); library(fixest); library(car)
})
set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus.script-free/3 replication package/replicate/replicate/data"

visits  <- read_csv(file.path(base, "metrovisitslog.csv"), show_col_types = FALSE)
pass    <- read_csv(file.path(base, "passersby.csv"), show_col_types = FALSE)
friend  <- read_csv(file.path(base, "friendliness.csv"), show_col_types = FALSE)
receipts<- read_csv(file.path(base, "receipts.csv"), show_col_types = FALSE)
service <- read_csv(file.path(base, "service.csv"), show_col_types = FALSE)
shuttle <- read_csv(file.path(base, "shuttle.csv"), show_col_types = FALSE)

# Station names are matched on a lower-case alphanumeric key.
norm <- function(x) tolower(gsub("[^A-Za-z0-9]", "", as.character(x)))

# Dates may arrive as text or as Date; try several common orders.
pdate <- function(x) {
  if (inherits(x, "Date")) return(x)
  as.Date(parse_date_time(as.character(x),
                          orders = c("mdy", "ymd", "dmy", "mdY", "Ymd")))
}

visits <- visits %>%
  mutate(key = norm(metro), d = pdate(date),
         month = month(d), year = year(d),
         panhandlers = as.numeric(panhandlers))
cat("Visit rows:", nrow(visits), "\n")

# Passersby: month may be numeric or a month name.
to_month <- function(m) {
  if (is.numeric(m)) return(as.integer(m))
  mm <- suppressWarnings(as.integer(m))
  if (all(is.na(mm) == is.na(m))) return(mm)
  idx <- match(tolower(substr(m, 1, 3)), tolower(month.abb))
  as.integer(idx)
}
pass <- pass %>%
  mutate(key = norm(metro), month = to_month(month),
         year = as.integer(year), passersby = as.numeric(passersby))
yr <- pass$year
if (all(yr < 100, na.rm = TRUE)) pass$year <- pass$year + 2000L

# Georgetown is assigned Foggy Bottom-GWU's exits.
gt_key <- unique(visits$key[grepl("georgetown", visits$key)])
fb_key <- unique(pass$key[grepl("foggy", pass$key)])
if (length(gt_key) > 0 && length(fb_key) > 0 && !any(pass$key %in% gt_key)) {
  pass <- bind_rows(pass, pass %>% filter(key == fb_key[1]) %>% mutate(key = gt_key[1]))
}
pass <- pass %>%
  group_by(key, month, year) %>%
  summarise(passersby = mean(passersby, na.rm = TRUE), .groups = "drop")

# Rescale to thousands of exits if the file is in raw counts.
if (mean(pass$passersby, na.rm = TRUE) > 20000) pass$passersby <- pass$passersby / 1000

# Friendliness: friendliest response per passerby, then station average.
# Heuristic for an undocumented coding (codebook not consulted):
#  - if passresp1..5 are all 0/1, treat them as category dummies and take the
#    highest category with a 1;
#  - otherwise treat them as 1-5 scores and take the maximum.
pr <- as.matrix(friend[, grep("^passresp", names(friend))])
pr <- apply(pr, 2, function(z) suppressWarnings(as.numeric(z)))
if (all(pr %in% c(0, 1, NA))) {
  best <- apply(pr, 1, function(r) {
    w <- which(r == 1)
    if (length(w)) max(w) else NA
  })
} else {
  best <- apply(pr, 1, function(r) {
    if (all(is.na(r))) NA else max(r, na.rm = TRUE)
  })
}
friend$best <- best
fr <- friend %>%
  mutate(key = norm(metro)) %>%
  group_by(key) %>%
  summarise(friendliness = mean(best, na.rm = TRUE), .groups = "drop")

# Homeless service and shuttle-stop dummies: within a 10-minute walk.
service <- service %>%
  mutate(key = norm(metro), service = as.integer(as.numeric(servicemin) <= 10)) %>%
  select(key, service)
shuttle <- shuttle %>%
  mutate(key = norm(metro), shuttle = as.integer(as.numeric(shuttlemin) <= 10)) %>%
  select(key, shuttle)

df <- visits %>%
  left_join(pass, by = c("key", "month", "year")) %>%
  left_join(fr, by = "key") %>%
  left_join(service, by = "key") %>%
  left_join(shuttle, by = "key") %>%
  mutate(datefe = as.character(d))

cat("Missing passersby:", sum(is.na(df$passersby)),
    " missing friendliness:", sum(is.na(df$friendliness)), "\n")

# Full sample: visits made in 2016-2017 (if the log also holds other years).
full <- df
if (any(full$year %in% c(2016, 2017)) && any(!full$year %in% c(2016, 2017))) {
  full <- full %>% filter(year %in% c(2016, 2017))
}

# Five-station subsample (station names normalised).
five <- norm(c("Farragut North", "Farragut West", "Gallery Place-Chinatown",
               "McPherson Square", "Metro Center"))
match_five <- function(k) {
  sapply(k, function(x) any(sapply(five, function(f) {
    x == f || grepl(f, x, fixed = TRUE) || grepl(x, f, fixed = TRUE)
  })))
}
sub <- df %>% filter(match_five(key) | grepl("gallery", key) | grepl("mcpherson", key) |
                       grepl("farragut", key) | grepl("metrocent", key))

fml <- panhandlers ~ passersby + friendliness + shuttle + service | datefe
m1 <- feols(fml, data = full, cluster = ~metro)
m2 <- feols(fml, data = sub, cluster = ~metro)
print(summary(m1)); print(summary(m2))

# Coefficients dropped for collinearity are reported as NA.
gc <- function(m, v) {
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA
}

# Receipts: rates of return per hour of observed work.
receipts <- receipts %>%
  mutate(key = norm(metro),
         donations = as.numeric(donations),
         minutes = as.numeric(minutes),
         cash = suppressWarnings(as.numeric(cash)),
         inkind = suppressWarnings(as.numeric(inkind)),
         declinedoffer = suppressWarnings(as.numeric(declinedoffer)),
         don_hr = donations / minutes * 60)

# Dollars: $0 for zero donations, missing if the counting offer was declined,
# otherwise cash plus the market value of in-kind donations.
receipts <- receipts %>%
  mutate(dollars = case_when(
           donations == 0 ~ 0,
           !is.na(declinedoffer) & declinedoffer == 1 ~ NA_real_,
           is.na(cash) & is.na(inkind) ~ NA_real_,
           TRUE ~ coalesce(cash, 0) + coalesce(inkind, 0)),
         dol_hr = dollars / minutes * 60)

rA <- receipts %>% filter(!is.na(don_hr))
rB <- receipts %>% filter(!is.na(dol_hr))
cat("Receipts N donations:", nrow(rA), " N dollars:", nrow(rB), "\n")

# Brown-Forsythe = Levene's test centred on the median; then one-way ANOVA.
bfA <- leveneTest(don_hr ~ factor(metro), data = rA, center = median)
bfB <- leveneTest(dol_hr ~ factor(metro), data = rB, center = median)
print(bfA); print(bfB)
aA <- oneway.test(don_hr ~ factor(metro), data = rA, var.equal = TRUE)
aB <- oneway.test(dol_hr ~ factor(metro), data = rB, var.equal = TRUE)
print(aA); print(aB)

cat(sprintf("RESULT:passersby_full_sample=%.6f\n", gc(m1, "passersby")))
cat(sprintf("RESULT:passersby_five_station_subsample=%.6f\n", gc(m2, "passersby")))
cat(sprintf("RESULT:friendliness_full_sample=%.6f\n", gc(m1, "friendliness")))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.6f\n", gc(m1, "shuttle")))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.6f\n", gc(m2, "shuttle")))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.6f\n", bfA[1, "F value"]))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.6f\n", bfB[1, "F value"]))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.6f\n", unname(aA$statistic)))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.6f\n", unname(aB$statistic)))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", nobs(m1)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", nobs(m2)))