# Hanlon et al. (2022) - Table 1 cols 1-4 and Table 4 col 1, independent blind reproduction
set.seed(42)
suppressPackageStartupMessages({ library(haven); library(fixest) })
d <- "<repo>/benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/blind/2026-11-02-c/mount/hanlon_2022_aircraft_ip_spillovers/3 replication files/data/dta/"
a <- as.data.frame(read_dta(paste0(d, "airframe_data.dta")))
e <- as.data.frame(read_dta(paste0(d, "engine_data.dta")))

# Two-piece continuous linear spline in year, knot at 1926 (Stata mkspline style):
# s_before = min(year, 1926), s_after = max(year - 1926, 0)
spl <- function(df) {
  df$s_before <- pmin(df$year, 1926)
  df$s_after  <- pmax(df$year - 1926, 0)
  df$us <- as.integer(df$country == "United States")
  df$s_before_us <- df$s_before * df$us
  df$s_after_us  <- df$s_after * df$us
  df$s_before_uk <- df$s_before * (1 - df$us)
  df$s_after_uk  <- df$s_after * (1 - df$us)
  df
}

# Airframes: fighters and bombers, 1918-1935
af <- spl(subset(a, type %in% c("fighter", "bomber") & year >= 1918 & year <= 1935))
af_us <- subset(af, us == 1)
af_usuk <- subset(af, country %in% c("United States", "United Kingdom"))

m1 <- feols(ln_wingload ~ s_before + s_after, data = af_us, vcov = "hetero")
m2 <- feols(ln_maxspeed ~ s_before + s_after, data = af_us, vcov = "hetero")
m3 <- feols(ln_wingload ~ us + s_before + s_after + s_before_us + s_after_us, data = af_usuk, vcov = "hetero")
m4 <- feols(ln_maxspeed ~ us + s_before + s_after + s_before_us + s_after_us, data = af_usuk, vcov = "hetero")

# Engines: engine_data (engines used in fighters/bombers), US only, with liquid-cooled indicator
en_us <- spl(subset(e, country == "United States" & year >= 1918 & year <= 1935))
m5 <- feols(ln_hp_per_lbs ~ s_before + s_after + liquid_cooled, data = en_us, vcov = "hetero")

for (m in list(m1, m2, m3, m4, m5)) print(summary(m))

r <- function(x) format(x, digits = 10)
cat("RESULT:airframe_wingload_trend_before_1926_us=", r(coef(m1)["s_before"]), "\n", sep = "")
cat("RESULT:airframe_wingload_trend_after_1926_us=", r(coef(m1)["s_after"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_before_1926_us=", r(coef(m2)["s_before"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_after_1926_us=", r(coef(m2)["s_after"]), "\n", sep = "")
cat("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=", r(coef(m3)["s_before_us"]), "\n", sep = "")
cat("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=", r(coef(m3)["s_after_us"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=", r(coef(m4)["s_before_us"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=", r(coef(m4)["s_after_us"]), "\n", sep = "")
cat("RESULT:engine_hp_per_weight_trend_before_1926_us=", r(coef(m5)["s_before"]), "\n", sep = "")
cat("RESULT:engine_hp_per_weight_trend_after_1926_us=", r(coef(m5)["s_after"]), "\n", sep = "")
cat("RESULT:observations_airframe_wingload_us=", nobs(m1), "\n", sep = "")
cat("RESULT:observations_engine_us=", nobs(m5), "\n", sep = "")
