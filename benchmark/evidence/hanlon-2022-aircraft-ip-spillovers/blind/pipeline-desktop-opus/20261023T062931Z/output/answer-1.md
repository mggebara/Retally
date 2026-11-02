```r
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
  if (haven::is.labelled(x)) x <- as.character(haven::as_factor(x))
  tolower(trimws(as.character(x)))
}
is_us <- function(x) {
  x <- gsub("[^a-z ]", "", x)
  x %in% c("us", "usa", "united states", "united states of america", "america", "unitedstates")
}
is_uk <- function(x) {
  x <- gsub("[^a-z ]", "", x)
  x %in% c("uk", "gb", "united kingdom", "britain", "great britain", "england", "unitedkingdom")
}

af <- af %>% mutate(country_c = to_chr(country), type_c = to_chr(type),
                    year = as.numeric(year))
en <- en %>% mutate(country_c = to_chr(country), year = as.numeric(year))

cat("Airframe countries:", paste(unique(af$country_c), collapse = ", "), "\n")
cat("Airframe types:", paste(unique(af$type_c), collapse = ", "), "\n")
cat("Engine countries:", paste(unique(en$country_c), collapse = ", "), "\n")

# Keep fighters and bombers if other types are present
fb <- grepl("fight|bomb|pursuit", af$type_c)
if (any(fb) && !all(fb)) {
  af <- af[fb, ]
  cat("DEVIATION: none; filtered to fighter/bomber types\n")
}

# Sample window 1918-1935
af <- af %>% filter(year >= 1918, year <= 1935)
en <- en %>% filter(year >= 1918, year <= 1935)

# Continuous two-piece linear spline, knot at 1926
add_spline <- function(d) {
  d$before <- pmin(d$year - 1926, 0)
  d$after  <- pmax(d$year - 1926, 0)
  d
}
af <- add_spline(af)
en <- add_spline(en)

af$us <- as.numeric(is_us(af$country_c))
af$uk <- as.numeric(is_uk(af$country_c))
en$us <- as.numeric(is_us(en$country_c))

robust <- function(m) coeftest(m, vcov = vcovHC(m, type = "HC1"))

# Table 1 col 1-2: US only
us_af <- af %>% filter(us == 1)
d1 <- us_af %>% filter(is.finite(ln_wingload))
m1 <- lm(ln_wingload ~ before + after, data = d1)
print(robust(m1))
d2 <- us_af %>% filter(is.finite(ln_maxspeed))
m2 <- lm(ln_maxspeed ~ before + after, data = d2)
print(robust(m2))

# Table 1 col 3-4: US vs UK, US-interacted spline (relative slopes)
uu <- af %>% filter(us == 1 | uk == 1)
d3 <- uu %>% filter(is.finite(ln_wingload))
m3 <- lm(ln_wingload ~ us + before + after + I(before * us) + I(after * us), data = d3)
print(robust(m3))
d4 <- uu %>% filter(is.finite(ln_maxspeed))
m4 <- lm(ln_maxspeed ~ us + before + after + I(before * us) + I(after * us), data = d4)
print(robust(m4))

# Table 4 col 1: US engines
d5 <- en %>% filter(us == 1, is.finite(ln_hp_per_lbs), !is.na(liquid_cooled))
d5$liquid_cooled <- as.numeric(d5$liquid_cooled)
m5 <- lm(ln_hp_per_lbs ~ before + after + liquid_cooled, data = d5)
print(robust(m5))

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
out("airframe_wingload_trend_before_1926_us", coef(m1)["before"])
out("airframe_wingload_trend_after_1926_us", coef(m1)["after"])
out("airframe_maxspeed_trend_before_1926_us", coef(m2)["before"])
out("airframe_maxspeed_trend_after_1926_us", coef(m2)["after"])
out("airframe_wingload_trend_before_1926_us_vs_uk", coef(m3)["I(before * us)"])
out("airframe_wingload_trend_after_1926_us_vs_uk", coef(m3)["I(after * us)"])
out("airframe_maxspeed_trend_before_1926_us_vs_uk", coef(m4)["I(before * us)"])
out("airframe_maxspeed_trend_after_1926_us_vs_uk", coef(m4)["I(after * us)"])
out("engine_hp_per_weight_trend_before_1926_us", coef(m5)["before"])
out("engine_hp_per_weight_trend_after_1926_us", coef(m5)["after"])
cat(sprintf("RESULT:observations_airframe_wingload_us=%d\n", nobs(m1)))
cat(sprintf("RESULT:observations_engine_us=%d\n", nobs(m5)))
```
