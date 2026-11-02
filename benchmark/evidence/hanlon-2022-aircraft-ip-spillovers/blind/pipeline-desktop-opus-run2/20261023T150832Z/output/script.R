suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base <- "/Users/matthew/dev/Retally/.cache/datasets/hanlon_2022_aircraft_ip_spillovers.script-free"
af <- haven::read_dta(file.path(base, "3 replication files/data/dta/airframe_data.dta"))
en <- haven::read_dta(file.path(base, "3 replication files/data/dta/engine_data.dta"))

to_chr <- function(x) {
  if (haven::is.labelled(x)) x <- as.character(haven::as_factor(x, levels = "labels"))
  toupper(trimws(as.character(x)))
}
is_us <- function(s) s %in% c("US", "USA", "U.S.", "U.S.A.", "UNITED STATES", "UNITED STATES OF AMERICA", "AMERICA", "AMERICAN")
is_uk <- function(s) s %in% c("UK", "U.K.", "GB", "GBR", "BRITAIN", "GREAT BRITAIN", "UNITED KINGDOM", "ENGLAND", "BRITISH")

af$country_s <- to_chr(af$country)
en$country_s <- to_chr(en$country)
af$type_s <- to_chr(af$type)
af$year <- as.numeric(af$year)
en$year <- as.numeric(en$year)

cat("Airframe countries:\n"); print(table(af$country_s, useNA = "ifany"))
cat("Airframe types:\n"); print(table(af$type_s, useNA = "ifany"))
cat("Engine countries:\n"); print(table(en$country_s, useNA = "ifany"))
cat("Airframe year range:", range(af$year, na.rm = TRUE), "\n")
cat("Engine year range:", range(en$year, na.rm = TRUE), "\n")

# Fighters and bombers only
fb <- grepl("FIGHT|BOMB|PURSUIT", af$type_s)
if (sum(fb) == 0) {
  cat("WARNING: no fighter/bomber type labels found; using all airframes\n")
  fb <- rep(TRUE, nrow(af))
}
af <- af[fb, ]
af <- af[!is.na(af$year) & af$year >= 1918 & af$year <= 1935, ]

# Two-piece linear spline, knot at 1926 (slopes before and after)
spl <- function(d) {
  d$yr_before <- pmin(d$year, 1926)
  d$yr_after <- pmax(d$year - 1926, 0)
  d
}
af <- spl(af)
en <- spl(en)
af$us <- as.numeric(is_us(af$country_s))
af$uk <- as.numeric(is_uk(af$country_s))
en$us <- as.numeric(is_us(en$country_s))

rob <- function(m) coeftest(m, vcov = vcovHC(m, type = "HC1"))

# Table 1 col 1/2: US only
us_af <- af[af$us == 1, ]
d1 <- us_af[is.finite(us_af$ln_wingload), ]
m1 <- lm(ln_wingload ~ yr_before + yr_after, data = d1)
print(rob(m1))
d2 <- us_af[is.finite(us_af$ln_maxspeed), ]
m2 <- lm(ln_maxspeed ~ yr_before + yr_after, data = d2)
print(rob(m2))

# Table 1 col 3/4: US vs UK
pool <- af[af$us == 1 | af$uk == 1, ]
pool$b_us <- pool$yr_before * pool$us
pool$a_us <- pool$yr_after * pool$us
pool$b_uk <- pool$yr_before * (1 - pool$us)
pool$a_uk <- pool$yr_after * (1 - pool$us)
d3 <- pool[is.finite(pool$ln_wingload), ]
m3 <- lm(ln_wingload ~ us + b_us + a_us + yr_before + yr_after, data = d3)
print(rob(m3))
d4 <- pool[is.finite(pool$ln_maxspeed), ]
m4 <- lm(ln_maxspeed ~ us + b_us + a_us + yr_before + yr_after, data = d4)
print(rob(m4))

# Table 4 col 1: US engines
us_en <- en[en$us == 1 & is.finite(en$ln_hp_per_lbs) & !is.na(en$year), ]
us_en$liquid_cooled <- as.numeric(us_en$liquid_cooled)
if (length(unique(na.omit(us_en$liquid_cooled))) > 1) {
  m5 <- lm(ln_hp_per_lbs ~ yr_before + yr_after + liquid_cooled, data = us_en)
} else {
  m5 <- lm(ln_hp_per_lbs ~ yr_before + yr_after, data = us_en)
}
print(rob(m5))

cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us=%.6f\n", coef(m1)["yr_before"]))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us=%.6f\n", coef(m1)["yr_after"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us=%.6f\n", coef(m2)["yr_before"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us=%.6f\n", coef(m2)["yr_after"]))
cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=%.6f\n", coef(m3)["b_us"]))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=%.6f\n", coef(m3)["a_us"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=%.6f\n", coef(m4)["b_us"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=%.6f\n", coef(m4)["a_us"]))
cat(sprintf("RESULT:engine_hp_per_weight_trend_before_1926_us=%.6f\n", coef(m5)["yr_before"]))
cat(sprintf("RESULT:engine_hp_per_weight_trend_after_1926_us=%.6f\n", coef(m5)["yr_after"]))
cat(sprintf("RESULT:observations_airframe_wingload_us=%d\n", as.integer(nobs(m1))))
cat(sprintf("RESULT:observations_engine_us=%d\n", as.integer(nobs(m5))))