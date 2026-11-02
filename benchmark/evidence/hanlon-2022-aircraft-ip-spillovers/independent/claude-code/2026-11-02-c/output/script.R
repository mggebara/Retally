## Hanlon (2022) independent reproduction: Table 1 cols 1-4, Table 4 col 1
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/independent/2026-11-02-c/mount/hanlon_2022_aircraft_ip_spillovers/3 replication files/data/dta/"
a <- read_dta(paste0(D, "airframe_data.dta"))
e <- read_dta(paste0(D, "engine_data.dta"))

## continuous two-piece linear spline, knot at 1926
spl <- function(d) d %>% mutate(pre = pmin(year - 1926, 0), post = pmax(year - 1926, 0),
                                 us = as.numeric(country == "United States"))

af <- a %>% filter(type %in% c("fighter", "bomber"),
                   country %in% c("United States", "United Kingdom")) %>% spl()
afus <- af %>% filter(us == 1)

## eq (4): US only
m1 <- feols(ln_wingload ~ pre + post, data = afus, vcov = "hetero")
m2 <- feols(ln_maxspeed ~ pre + post, data = afus, vcov = "hetero")
## eq (5): pooled US+UK; common (UK) spline + US indicator + US x spline
m3 <- feols(ln_wingload ~ pre + post + us + us:pre + us:post, data = af, vcov = "hetero")
m4 <- feols(ln_maxspeed ~ pre + post + us + us:pre + us:post, data = af, vcov = "hetero")
## Table 4 col 1: US engines, spline + liquid-cooled indicator
eus <- e %>% filter(country == "United States") %>% spl()
m5 <- feols(ln_hp_per_lbs ~ pre + post + liquid_cooled, data = eus, vcov = "hetero")

for (m in list(m1, m2, m3, m4, m5)) print(coeftable(m))
f <- function(x) formatC(x, digits = 6, format = "f")
cat("RESULT:airframe_wingload_trend_before_1926_us=", f(coef(m1)["pre"]), "\n", sep = "")
cat("RESULT:airframe_wingload_trend_after_1926_us=", f(coef(m1)["post"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_before_1926_us=", f(coef(m2)["pre"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_after_1926_us=", f(coef(m2)["post"]), "\n", sep = "")
cat("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=", f(coef(m3)["pre:us"]), "\n", sep = "")
cat("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=", f(coef(m3)["post:us"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=", f(coef(m4)["pre:us"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=", f(coef(m4)["post:us"]), "\n", sep = "")
cat("RESULT:engine_hp_per_weight_trend_before_1926_us=", f(coef(m5)["pre"]), "\n", sep = "")
cat("RESULT:engine_hp_per_weight_trend_after_1926_us=", f(coef(m5)["post"]), "\n", sep = "")
cat("RESULT:observations_airframe_wingload_us=", nobs(m1), "\n", sep = "")
cat("RESULT:observations_engine_us=", nobs(m5), "\n", sep = "")
