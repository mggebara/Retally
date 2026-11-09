## Hanlon et al. (2022), Tables 1 and 4: independent reproduction.
## Two-piece linear spline in year with knot at 1926 (continuous level):
##   s_before = min(year, 1926), s_after = max(year - 1926, 0)
## so coefficients are the before/after-1926 slopes. OLS with robust (HC1) SEs.
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/independent/2026-11-07-a/mount/hanlon_2022_aircraft_ip_spillovers/3 replication files/data/dta/"
a <- read_dta(paste0(d, "airframe_data.dta")) %>% zap_labels() %>% as.data.frame()
e <- read_dta(paste0(d, "engine_data.dta")) %>% zap_labels() %>% as.data.frame()

spl <- function(df) {
  df$s_before <- pmin(df$year, 1926)
  df$s_after  <- pmax(df$year - 1926, 0)
  df$us <- as.integer(df$country == "United States")
  df$us_before <- df$s_before * df$us
  df$us_after  <- df$s_after * df$us
  df
}
a <- spl(a %>% filter(type %in% c("fighter", "bomber")))
e <- spl(e)

us_a  <- a %>% filter(country == "United States")
usuk  <- a %>% filter(country %in% c("United States", "United Kingdom"))

m1 <- feols(ln_wingload ~ s_before + s_after, data = us_a, vcov = "hetero")
m2 <- feols(ln_maxspeed ~ s_before + s_after, data = us_a, vcov = "hetero")
# Eq. (5): common spline (= UK spline, the comparison country) + US dummy + US x spline
m3 <- feols(ln_wingload ~ us_before + us_after + us + s_before + s_after, data = usuk, vcov = "hetero")
m4 <- feols(ln_maxspeed ~ us_before + us_after + us + s_before + s_after, data = usuk, vcov = "hetero")
# Table 4 col 1: US engines, spline + liquid-cooled indicator
us_e <- e %>% filter(country == "United States")
m5 <- feols(ln_hp_per_lbs ~ s_before + s_after + liquid_cooled, data = us_e, vcov = "hetero")

etable(m1, m2, m3, m4, m5, digits = 3)

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("airframe_wingload_trend_before_1926_us", coef(m1)["s_before"])
r("airframe_wingload_trend_after_1926_us", coef(m1)["s_after"])
r("airframe_maxspeed_trend_before_1926_us", coef(m2)["s_before"])
r("airframe_maxspeed_trend_after_1926_us", coef(m2)["s_after"])
r("airframe_wingload_trend_before_1926_us_vs_uk", coef(m3)["us_before"])
r("airframe_wingload_trend_after_1926_us_vs_uk", coef(m3)["us_after"])
r("airframe_maxspeed_trend_before_1926_us_vs_uk", coef(m4)["us_before"])
r("airframe_maxspeed_trend_after_1926_us_vs_uk", coef(m4)["us_after"])
r("engine_hp_per_weight_trend_before_1926_us", coef(m5)["s_before"])
r("engine_hp_per_weight_trend_after_1926_us", coef(m5)["s_after"])
r("observations_airframe_wingload_us", nobs(m1))
r("observations_engine_us", nobs(m5))
