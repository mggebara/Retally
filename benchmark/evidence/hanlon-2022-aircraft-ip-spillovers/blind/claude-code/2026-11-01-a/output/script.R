# Hanlon et al. (2022) - Table 1 cols 1-4, Table 4 col 1. Independent, blind reproduction.
set.seed(42)
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
d <- "/Users/matthew/dev/Retally/benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/blind/2026-11-01-a/mount/hanlon_2022_aircraft_ip_spillovers/3 replication files/data/dta/"
a <- read_dta(paste0(d, "airframe_data.dta"))
e <- read_dta(paste0(d, "engine_data.dta"))

# two-piece continuous linear spline, knot at 1926 (Stata mkspline, non-marginal):
# coefficient on each piece is the slope within that segment
spl <- function(df) df %>% mutate(before = pmin(year, 1926), after = pmax(year - 1926, 0))

af <- a %>% filter(type %in% c("fighter", "bomber"), year >= 1918, year <= 1935) %>%
  spl() %>% mutate(us = as.numeric(country == "United States"),
                   us_before = us * before, us_after = us * after)
us_af <- af %>% filter(us == 1)
ukus  <- af %>% filter(country %in% c("United States", "United Kingdom"))

# Eq. (4): US only
m1 <- feols(ln_wingload ~ before + after, data = us_af, vcov = "hetero")
m2 <- feols(ln_maxspeed ~ before + after, data = us_af, vcov = "hetero")
# Eq. (5): US vs UK; common (UK baseline) spline + US indicator + US-interacted spline
m3 <- feols(ln_wingload ~ us_before + us_after + us + before + after, data = ukus, vcov = "hetero")
m4 <- feols(ln_maxspeed ~ us_before + us_after + us + before + after, data = ukus, vcov = "hetero")

# Table 4 col 1: US engines used in fighters/bombers, with liquid-cooled indicator
en <- e %>% filter(country == "United States", year >= 1918, year <= 1935) %>% spl()
m5 <- feols(ln_hp_per_lbs ~ before + after + liquid_cooled, data = en, vcov = "hetero")

for (m in list(m1, m2, m3, m4, m5)) print(summary(m))

out <- c(
  airframe_wingload_trend_before_1926_us = coef(m1)[["before"]],
  airframe_wingload_trend_after_1926_us  = coef(m1)[["after"]],
  airframe_maxspeed_trend_before_1926_us = coef(m2)[["before"]],
  airframe_maxspeed_trend_after_1926_us  = coef(m2)[["after"]],
  airframe_wingload_trend_before_1926_us_vs_uk = coef(m3)[["us_before"]],
  airframe_wingload_trend_after_1926_us_vs_uk  = coef(m3)[["us_after"]],
  airframe_maxspeed_trend_before_1926_us_vs_uk = coef(m4)[["us_before"]],
  airframe_maxspeed_trend_after_1926_us_vs_uk  = coef(m4)[["us_after"]],
  engine_hp_per_weight_trend_before_1926_us = coef(m5)[["before"]],
  engine_hp_per_weight_trend_after_1926_us  = coef(m5)[["after"]],
  observations_airframe_wingload_us = nobs(m1),
  observations_engine_us = nobs(m5)
)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
