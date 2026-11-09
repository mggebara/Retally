# Hanlon et al. (2022) - Table 1 cols 1-4 and Table 4 col 1, independent blind reproduction
library(haven)
library(sandwich)
library(lmtest)
set.seed(42)

b <- "<repo>/benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/blind/2026-11-07-a/mount/hanlon_2022_aircraft_ip_spillovers/3 replication files/data/dta/"
a <- as.data.frame(read_dta(paste0(b, "airframe_data.dta")))
e <- as.data.frame(read_dta(paste0(b, "engine_data.dta")))

# Continuous two-piece linear spline in year, knot at 1926 (Stata mkspline-style)
knot <- 1926
spl <- function(d) {
  d$yr_before <- pmin(d$year, knot)
  d$yr_after  <- pmax(d$year - knot, 0)
  d$us <- as.numeric(d$country == "United States")
  d
}

# Airframes: fighters and bombers, 1918-1935
af <- spl(subset(a, type %in% c("fighter", "bomber") & year >= 1918 & year <= 1935))
af_us <- subset(af, country == "United States")
af_usuk <- subset(af, country %in% c("United States", "United Kingdom"))

rob <- function(m) coeftest(m, vcov = vcovHC(m, type = "HC1"))

m1 <- lm(ln_wingload ~ yr_before + yr_after, data = af_us)
m2 <- lm(ln_maxspeed ~ yr_before + yr_after, data = af_us)
# Pooled US-UK: common (UK) spline + US-interacted spline + US indicator;
# the interaction terms are the US slopes relative to the UK.
m3 <- lm(ln_wingload ~ yr_before + yr_after + us + I(yr_before * us) + I(yr_after * us), data = af_usuk)
m4 <- lm(ln_maxspeed ~ yr_before + yr_after + us + I(yr_before * us) + I(yr_after * us), data = af_usuk)

# Engines: engine_data.dta (Jane's, engines used in fighters/bombers), US only
en_us <- spl(subset(e, country == "United States" & year >= 1918 & year <= 1935))
m5 <- lm(ln_hp_per_lbs ~ yr_before + yr_after + liquid_cooled, data = en_us)

for (m in list(m1, m2, m3, m4, m5)) { print(rob(m)); cat("N =", nobs(m), "\n\n") }

cf <- function(m, k) unname(coef(m)[k])
cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us=%.6f\n", cf(m1, "yr_before")))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us=%.6f\n", cf(m1, "yr_after")))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us=%.6f\n", cf(m2, "yr_before")))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us=%.6f\n", cf(m2, "yr_after")))
cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=%.6f\n", cf(m3, "I(yr_before * us)")))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=%.6f\n", cf(m3, "I(yr_after * us)")))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=%.6f\n", cf(m4, "I(yr_before * us)")))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=%.6f\n", cf(m4, "I(yr_after * us)")))
cat(sprintf("RESULT:engine_hp_per_weight_trend_before_1926_us=%.6f\n", cf(m5, "yr_before")))
cat(sprintf("RESULT:engine_hp_per_weight_trend_after_1926_us=%.6f\n", cf(m5, "yr_after")))
cat(sprintf("RESULT:observations_airframe_wingload_us=%d\n", nobs(m1)))
cat(sprintf("RESULT:observations_engine_us=%d\n", nobs(m5)))
