#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base <- "/Users/matthew/dev/Retally/.cache/datasets/hanlon_2022_aircraft_ip_spillovers.script-free"
airframe <- read_dta(file.path(base, "3 replication files/data/dta/airframe_data.dta"))
engine <- read_dta(file.path(base, "3 replication files/data/dta/engine_data.dta"))

# Restrict to fighters and bombers
af <- airframe %>%
  filter(type %in% c("fighter", "bomber", "Fighter", "Bomber") |
         grepl("fighter|bomber", tolower(as.character(type))))

# Create spline terms: continuous piecewise linear with knot at 1926
# Parameterization: year_before = year (same slope throughout) + after_adj = (year-1926)*(year>=1926)*extra
# But paper reports separate before/after slopes. Use:
# before = min(year, 1926), after = max(year - 1926, 0)
# Then slope before 1926 = coef(before), slope after 1926 = coef(before) + coef(after)
# Alternative convention that matches "Before 1926 x year" and "After 1926 x year" directly:
# Use b1 = year*(year<1926) + 1926*(year>=1926), b2 = (year-1926)*(year>=1926)
# This gives continuity at 1926. Coef on b1 = pre-slope, coef on b2 = post-slope.

make_spline <- function(y, knot = 1926) {
  b1 <- pmin(y, knot)
  b2 <- pmax(y - knot, 0)
  data.frame(b1 = b1, b2 = b2)
}

# US only - wing load
af_us <- af %>% filter(country == "US" | country == "USA" | country == "United States") %>%
  filter(!is.na(ln_wingload))

sp <- make_spline(af_us$year)
af_us$b1 <- sp$b1; af_us$b2 <- sp$b2

m1 <- feols(ln_wingload ~ b1 + b2, data = af_us, vcov = "hetero")
wl_pre_us  <- coef(m1)["b1"]
wl_post_us <- coef(m1)["b2"]
n_wl_us <- nobs(m1)

# US only - max speed
af_us_ms <- af_us %>% filter(!is.na(ln_maxspeed))
sp <- make_spline(af_us_ms$year)
af_us_ms$b1 <- sp$b1; af_us_ms$b2 <- sp$b2
m2 <- feols(ln_maxspeed ~ b1 + b2, data = af_us_ms, vcov = "hetero")
ms_pre_us  <- coef(m2)["b1"]
ms_post_us <- coef(m2)["b2"]

# US vs UK - wing load
af_uk <- af %>% filter(country %in% c("US","USA","United States","UK","GB","Britain","United Kingdom"))
# Standardize US indicator
af_uk <- af_uk %>% mutate(us = as.integer(country %in% c("US","USA","United States")))
af_uk_wl <- af_uk %>% filter(!is.na(ln_wingload))
sp <- make_spline(af_uk_wl$year)
af_uk_wl$b1 <- sp$b1; af_uk_wl$b2 <- sp$b2
# equation (5): constant, US indicator, UK spline (b1,b2), plus US-interacted spline
m3 <- feols(ln_wingload ~ b1 + b2 + us + I(b1*us) + I(b2*us), data = af_uk_wl, vcov = "hetero")
wl_pre_vs  <- coef(m3)["I(b1 * us)"]
wl_post_vs <- coef(m3)["I(b2 * us)"]

# US vs UK - max speed
af_uk_ms <- af_uk %>% filter(!is.na(ln_maxspeed))
sp <- make_spline(af_uk_ms$year)
af_uk_ms$b1 <- sp$b1; af_uk_ms$b2 <- sp$b2
m4 <- feols(ln_maxspeed ~ b1 + b2 + us + I(b1*us) + I(b2*us), data = af_uk_ms, vcov = "hetero")
ms_pre_vs  <- coef(m4)["I(b1 * us)"]
ms_post_vs <- coef(m4)["I(b2 * us)"]

# Engines - US only, hp/weight with liquid_cooled control
eng_us <- engine %>% filter(country %in% c("US","USA","United States")) %>%
  filter(!is.na(ln_hp_per_lbs))
sp <- make_spline(eng_us$year)
eng_us$b1 <- sp$b1; eng_us$b2 <- sp$b2
m5 <- feols(ln_hp_per_lbs ~ b1 + b2 + liquid_cooled, data = eng_us, vcov = "hetero")
en_pre_us  <- coef(m5)["b1"]
en_post_us <- coef(m5)["b2"]
n_en_us <- nobs(m5)

cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us=%.4f\n", wl_pre_us))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us=%.4f\n", wl_post_us))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us=%.4f\n", ms_pre_us))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us=%.4f\n", ms_post_us))
cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=%.4f\n", wl_pre_vs))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=%.4f\n", wl_post_vs))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=%.4f\n", ms_pre_vs))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=%.4f\n", ms_post_vs))
cat(sprintf("RESULT:engine_hp_per_weight_trend_before_1926_us=%.4f\n", en_pre_us))
cat(sprintf("RESULT:engine_hp_per_weight_trend_after_1926_us=%.4f\n", en_post_us))
cat(sprintf("RESULT:observations_airframe_wingload_us=%d\n", n_wl_us))
cat(sprintf("RESULT:observations_engine_us=%d\n", n_en_us))