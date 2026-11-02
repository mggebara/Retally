#!/usr/bin/env Rscript
set.seed(42)

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

base <- "/Users/matthew/dev/Retally/.cache/datasets/hanlon_2022_aircraft_ip_spillovers.script-free"

airframe <- read_dta(file.path(base, "3 replication files/data/dta/airframe_data.dta"))
engine   <- read_dta(file.path(base, "3 replication files/data/dta/engine_data.dta"))

# Inspect country values
# print(unique(airframe$country))

# Restrict to fighters and bombers
af <- airframe %>%
  filter(!is.na(type)) %>%
  mutate(type_lower = tolower(as.character(type))) %>%
  filter(grepl("fighter|bomber", type_lower)) %>%
  filter(year >= 1918, year <= 1935)

# Normalize country strings
af <- af %>%
  mutate(
    country_str = tolower(trimws(as.character(country))),
    US = as.integer(country_str %in% c("us", "united states", "usa", "u.s.", "u.s.a.")),
    UK = as.integer(country_str %in% c("uk", "united kingdom", "u.k.", "britain", "great britain", "england"))
  )

af <- af %>%
  mutate(
    year_before = pmin(year, 1926),
    year_after  = pmax(year, 1926)
  )

# ----- Column 1: US only, log wing load -----
us_af <- af %>% filter(US == 1, !is.na(ln_wingload))
m1 <- feols(ln_wingload ~ year_before + year_after, data = us_af, vcov = "hetero")

# ----- Column 2: US only, log max speed -----
us_af_ms <- af %>% filter(US == 1, !is.na(ln_maxspeed))
m2 <- feols(ln_maxspeed ~ year_before + year_after, data = us_af_ms, vcov = "hetero")

# ----- Columns 3,4: US vs UK pooled -----
uk_us_af <- af %>% filter(US == 1 | UK == 1)
uk_us_af <- uk_us_af %>%
  mutate(
    yb_us = year_before * US,
    ya_us = year_after * US
  )

m3_data <- uk_us_af %>% filter(!is.na(ln_wingload))
m3 <- feols(ln_wingload ~ US + year_before + year_after + yb_us + ya_us,
            data = m3_data, vcov = "hetero")

m4_data <- uk_us_af %>% filter(!is.na(ln_maxspeed))
m4 <- feols(ln_maxspeed ~ US + year_before + year_after + yb_us + ya_us,
            data = m4_data, vcov = "hetero")

# ----- Engines: Table 4, column 1 -----
eng <- engine %>%
  filter(year >= 1918, year <= 1935) %>%
  mutate(
    country_str = tolower(trimws(as.character(country))),
    US = as.integer(country_str %in% c("us", "united states", "usa", "u.s.", "u.s.a.")),
    year_before = pmin(year, 1926),
    year_after  = pmax(year, 1926)
  )

us_eng <- eng %>% filter(US == 1, !is.na(ln_hp_per_lbs))
m5 <- feols(ln_hp_per_lbs ~ year_before + year_after + liquid_cooled,
            data = us_eng, vcov = "hetero")

# Extract
c1_b <- coef(m1)["year_before"]
c1_a <- coef(m1)["year_after"]
c2_b <- coef(m2)["year_before"]
c2_a <- coef(m2)["year_after"]
c3_b <- coef(m3)["yb_us"]
c3_a <- coef(m3)["ya_us"]
c4_b <- coef(m4)["yb_us"]
c4_a <- coef(m4)["ya_us"]
c5_b <- coef(m5)["year_before"]
c5_a <- coef(m5)["year_after"]

n1 <- nobs(m1)
n5 <- nobs(m5)

cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us=%.6f\n", c1_b))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us=%.6f\n", c1_a))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us=%.6f\n", c2_b))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us=%.6f\n", c2_a))
cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=%.6f\n", c3_b))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=%.6f\n", c3_a))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=%.6f\n", c4_b))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=%.6f\n", c4_a))
cat(sprintf("RESULT:engine_hp_per_weight_trend_before_1926_us=%.6f\n", c5_b))
cat(sprintf("RESULT:engine_hp_per_weight_trend_after_1926_us=%.6f\n", c5_a))
cat(sprintf("RESULT:observations_airframe_wingload_us=%d\n", as.integer(n1)))
cat(sprintf("RESULT:observations_engine_us=%d\n", as.integer(n5)))