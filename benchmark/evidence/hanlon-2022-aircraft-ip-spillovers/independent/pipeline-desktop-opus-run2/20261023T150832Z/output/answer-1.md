suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "/Users/matthew/dev/Retally/.cache/datasets/hanlon_2022_aircraft_ip_spillovers.script-free"
af <- haven::read_dta(file.path(base, "3 replication files/data/dta/airframe_data.dta"))
en <- haven::read_dta(file.path(base, "3 replication files/data/dta/engine_data.dta"))

to_chr <- function(x) {
  if (haven::is.labelled(x)) as.character(haven::as_factor(x, levels = "labels")) else as.character(x)
}

is_country <- function(x, which) {
  s <- tolower(trimws(to_chr(x)))
  if (which == "US") {
    s %in% c("us", "usa", "u.s.", "u.s.a.", "united states", "united states of america", "america", "unitedstates")
  } else {
    s %in% c("uk", "u.k.", "united kingdom", "britain", "great britain", "gb", "england", "unitedkingdom")
  }
}

cat("Airframe country values:\n"); print(table(to_chr(af$country), useNA = "ifany"))
cat("Airframe type values:\n"); print(table(to_chr(af$type), useNA = "ifany"))
cat("Engine country values:\n"); print(table(to_chr(en$country), useNA = "ifany"))

af <- af %>% mutate(
  ctry_us = is_country(country, "US"),
  ctry_uk = is_country(country, "UK"),
  type_chr = tolower(to_chr(type)),
  year = as.numeric(year)
)
en <- en %>% mutate(
  ctry_us = is_country(country, "US"),
  ctry_uk = is_country(country, "UK"),
  year = as.numeric(year)
)

# Restrict to fighters and bombers if the type field contains other categories
fb <- grepl("fight|bomb|pursuit|attack", af$type_chr)
if (any(fb) && !all(fb | is.na(af$type_chr))) {
  af <- af[fb, ]
}

# Window 1918-1935
af <- af %>% filter(year >= 1918, year <= 1935)
en <- en %>% filter(year >= 1918, year <= 1935)

# Continuous two-piece linear spline, knot at 1926
mk_spline <- function(d) {
  d$pre  <- pmin(d$year, 1926) - 1926
  d$post <- pmax(d$year - 1926, 0)
  d
}
af <- mk_spline(af)
en <- mk_spline(en)

# ---- Table 1 col 1 & 2: US only ----
us_af <- af %>% filter(ctry_us)
m1 <- feols(ln_wingload ~ pre + post, data = us_af %>% filter(!is.na(ln_wingload)), vcov = "hetero")
m2 <- feols(ln_maxspeed ~ pre + post, data = us_af %>% filter(!is.na(ln_maxspeed)), vcov = "hetero")
print(summary(m1)); print(summary(m2))

# ---- Table 1 col 3 & 4: US vs UK ----
usuk <- af %>% filter(ctry_us | ctry_uk) %>%
  mutate(US = as.numeric(ctry_us), pre_US = pre * US, post_US = post * US)
m3 <- feols(ln_wingload ~ US + pre + post + pre_US + post_US,
            data = usuk %>% filter(!is.na(ln_wingload)), vcov = "hetero")
m4 <- feols(ln_maxspeed ~ US + pre + post + pre_US + post_US,
            data = usuk %>% filter(!is.na(ln_maxspeed)), vcov = "hetero")
print(summary(m3)); print(summary(m4))

# ---- Table 4 col 1: US engines ----
us_en <- en %>% filter(ctry_us, !is.na(ln_hp_per_lbs), is.finite(ln_hp_per_lbs))
m5 <- feols(ln_hp_per_lbs ~ pre + post + liquid_cooled, data = us_en, vcov = "hetero")
print(summary(m5))

cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us=%.6f\n", coef(m1)["pre"]))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us=%.6f\n", coef(m1)["post"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us=%.6f\n", coef(m2)["pre"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us=%.6f\n", coef(m2)["post"]))
cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=%.6f\n", coef(m3)["pre_US"]))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=%.6f\n", coef(m3)["post_US"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=%.6f\n", coef(m4)["pre_US"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=%.6f\n", coef(m4)["post_US"]))
cat(sprintf("RESULT:engine_hp_per_weight_trend_before_1926_us=%.6f\n", coef(m5)["pre"]))
cat(sprintf("RESULT:engine_hp_per_weight_trend_after_1926_us=%.6f\n", coef(m5)["post"]))
cat(sprintf("RESULT:observations_airframe_wingload_us=%d\n", as.integer(nobs(m1))))
cat(sprintf("RESULT:observations_engine_us=%d\n", as.integer(nobs(m5))))
