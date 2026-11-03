# Hanlon et al. (2022) - Table 1 cols 1-4 and Table 4 col 1, independent blind reproduction
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/blind/2026-11-03-a/mount/hanlon_2022_aircraft_ip_spillovers/3 replication files/data/dta/"

# Continuous two-piece linear spline, knot at 1926, parameterised so that each
# coefficient IS the slope in its own segment:
#   pre  = min(year,1926) - 1926   (slope before 1926)
#   post = max(year,1926) - 1926   (slope after 1926)
spline <- function(df) {
  df %>% mutate(pre  = pmin(year, 1926) - 1926,
                post = pmax(year, 1926) - 1926,
                US = as.integer(country == "United States"),
                UK = 1L - US,
                preUS = pre * US, postUS = post * US,
                preUK = pre * UK, postUK = post * UK)
}

a <- read_dta(paste0(D, "airframe_data.dta")) %>%
  filter(type %in% c("fighter", "bomber"),
         country %in% c("United States", "United Kingdom"),
         year >= 1918, year <= 1935) %>% spline()
us <- filter(a, US == 1)

# Equation (4): US only, spline + constant, robust SE
m1 <- feols(ln_wingload ~ pre + post, data = us, vcov = "hetero")
m2 <- feols(ln_maxspeed ~ pre + post, data = us, vcov = "hetero")
# Equation (5): pooled US+UK; constant, US indicator, spline x US, spline x UK
m3 <- feols(ln_wingload ~ US + preUS + postUS + preUK + postUK, data = a, vcov = "hetero")
m4 <- feols(ln_maxspeed ~ US + preUS + postUS + preUK + postUK, data = a, vcov = "hetero")

# Table 4 col 1: US engines (fighter/bomber engines file), spline + liquid-cooled + constant
e <- read_dta(paste0(D, "engine_data.dta")) %>%
  filter(country == "United States", !is.na(ln_hp_per_lbs)) %>% spline()
m5 <- feols(ln_hp_per_lbs ~ pre + post + liquid_cooled, data = e, vcov = "hetero")

print(etable(m1, m2, m3, m4, m5))

g <- function(m, v) unname(coef(m)[v])
res <- c(
  airframe_wingload_trend_before_1926_us = g(m1, "pre"),
  airframe_wingload_trend_after_1926_us  = g(m1, "post"),
  airframe_maxspeed_trend_before_1926_us = g(m2, "pre"),
  airframe_maxspeed_trend_after_1926_us  = g(m2, "post"),
  airframe_wingload_trend_before_1926_us_vs_uk = g(m3, "preUS"),
  airframe_wingload_trend_after_1926_us_vs_uk  = g(m3, "postUS"),
  airframe_maxspeed_trend_before_1926_us_vs_uk = g(m4, "preUS"),
  airframe_maxspeed_trend_after_1926_us_vs_uk  = g(m4, "postUS"),
  engine_hp_per_weight_trend_before_1926_us = g(m5, "pre"),
  engine_hp_per_weight_trend_after_1926_us  = g(m5, "post"),
  observations_airframe_wingload_us = nobs(m1),
  observations_engine_us = nobs(m5)
)
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
