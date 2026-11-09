suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base <- "<repo>/.cache/datasets/hanlon_2022_aircraft_ip_spillovers.script-free"
air_path <- file.path(base, "3 replication files/data/dta/airframe_data.dta")
eng_path <- file.path(base, "3 replication files/data/dta/engine_data.dta")

air <- read_dta(air_path)
eng <- read_dta(eng_path)

to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) {
    as.character(haven::as_factor(x, levels = "default"))
  } else {
    as.character(x)
  }
}

is_us <- function(x) {
  x <- trimws(x)
  grepl("^(us|usa|u\\.s\\.?|u\\.s\\.a\\.?|united states.*|america.*)$", x, ignore.case = TRUE)
}
is_uk <- function(x) {
  x <- trimws(x)
  grepl("^(uk|u\\.k\\.?|united kingdom|britain|great britain|gb|gbr|england|british)$", x, ignore.case = TRUE)
}

# ---- Airframe data ----
air$country_chr <- to_chr(air$country)
air$type_chr <- to_chr(air$type)
air$year <- as.numeric(air$year)

cat("Airframe countries:\n"); print(table(air$country_chr, useNA = "ifany"))
cat("Airframe types:\n"); print(table(air$type_chr, useNA = "ifany"))
cat("Airframe year range:", range(air$year, na.rm = TRUE), "\n")

# Restrict to fighters and bombers when type info is identifiable
fb <- grepl("fight|bomb|pursuit", air$type_chr, ignore.case = TRUE)
if (any(fb)) {
  air <- air[fb, ]
} else {
  cat("NOTE: could not identify fighter/bomber labels in type; using all rows\n")
}

air <- air %>% filter(!is.na(year), year >= 1918, year <= 1935)

air <- air %>%
  mutate(
    us = as.integer(is_us(country_chr)),
    uk = as.integer(is_uk(country_chr)),
    s1 = pmin(year, 1926),
    s2 = pmax(year, 1926) - 1926
  )

cat("US rows:", sum(air$us), " UK rows:", sum(air$uk), "\n")

# Ensure log variables exist
if (!"ln_wingload" %in% names(air) || all(is.na(air$ln_wingload))) {
  air$ln_wingload <- log(as.numeric(air$wingload))
}
if (!"ln_maxspeed" %in% names(air) || all(is.na(air$ln_maxspeed))) {
  air$ln_maxspeed <- log(as.numeric(air$maxspeed))
}
air$ln_wingload <- as.numeric(air$ln_wingload)
air$ln_maxspeed <- as.numeric(air$ln_maxspeed)

us_air <- air %>% filter(us == 1)

# Table 1 col 1: US only, log wing load on two-piece spline
m1 <- feols(ln_wingload ~ s1 + s2, data = us_air, vcov = "hetero")
# Table 1 col 2: US only, log max speed
m2 <- feols(ln_maxspeed ~ s1 + s2, data = us_air, vcov = "hetero")
print(summary(m1)); print(summary(m2))

# Table 1 cols 3-4: US vs UK
usuk <- air %>% filter(us == 1 | uk == 1) %>%
  mutate(us_s1 = us * s1, us_s2 = us * s2)
m3 <- feols(ln_wingload ~ us + s1 + s2 + us_s1 + us_s2, data = usuk, vcov = "hetero")
m4 <- feols(ln_maxspeed ~ us + s1 + s2 + us_s1 + us_s2, data = usuk, vcov = "hetero")
print(summary(m3)); print(summary(m4))

# ---- Engine data ----
eng$country_chr <- to_chr(eng$country)
eng$year <- as.numeric(eng$year)
cat("Engine countries:\n"); print(table(eng$country_chr, useNA = "ifany"))
cat("Engine year range:", range(eng$year, na.rm = TRUE), "\n")

eng <- eng %>%
  mutate(
    us = as.integer(is_us(country_chr)),
    s1 = pmin(year, 1926),
    s2 = pmax(year, 1926) - 1926,
    liquid_cooled = as.numeric(liquid_cooled),
    ln_hp_per_lbs = as.numeric(ln_hp_per_lbs)
  )

us_eng <- eng %>% filter(us == 1, !is.na(year), year >= 1918, year <= 1935)
m5 <- feols(ln_hp_per_lbs ~ s1 + s2 + liquid_cooled, data = us_eng, vcov = "hetero")
print(summary(m5))

fmt <- function(x) formatC(as.numeric(x), digits = 6, format = "f")

cat(paste0("RESULT:airframe_wingload_trend_before_1926_us=", fmt(coef(m1)["s1"]), "\n"))
cat(paste0("RESULT:airframe_wingload_trend_after_1926_us=", fmt(coef(m1)["s2"]), "\n"))
cat(paste0("RESULT:airframe_maxspeed_trend_before_1926_us=", fmt(coef(m2)["s1"]), "\n"))
cat(paste0("RESULT:airframe_maxspeed_trend_after_1926_us=", fmt(coef(m2)["s2"]), "\n"))
cat(paste0("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=", fmt(coef(m3)["us_s1"]), "\n"))
cat(paste0("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=", fmt(coef(m3)["us_s2"]), "\n"))
cat(paste0("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=", fmt(coef(m4)["us_s1"]), "\n"))
cat(paste0("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=", fmt(coef(m4)["us_s2"]), "\n"))
cat(paste0("RESULT:engine_hp_per_weight_trend_before_1926_us=", fmt(coef(m5)["s1"]), "\n"))
cat(paste0("RESULT:engine_hp_per_weight_trend_after_1926_us=", fmt(coef(m5)["s2"]), "\n"))
cat(paste0("RESULT:observations_airframe_wingload_us=", nobs(m1), "\n"))
cat(paste0("RESULT:observations_engine_us=", nobs(m5), "\n"))
