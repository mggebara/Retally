# Hanlon et al. (2022) -- Table 1 cols 1-4 and Table 4 col 1, independent blind reproduction
library(haven)
library(sandwich)
library(lmtest)
set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/blind/2026-10-21-b/mount/hanlon_2022_aircraft_ip_spillovers/3 replication files/data/dta/"
a <- as.data.frame(read_dta(paste0(d, "airframe_data.dta")))
e <- as.data.frame(read_dta(paste0(d, "engine_data.dta")))

knot <- 1926
# Continuous two-piece linear spline (Stata mkspline style, marginal slopes):
#   before = min(year, 1926); after = max(year - 1926, 0)
sp_before <- function(y) pmin(y, knot)
sp_after  <- function(y) pmax(y - knot, 0)

# ---- Airframes: fighters and bombers, 1918-1935
af <- subset(a, type %in% c("fighter", "bomber") & year >= 1918 & year <= 1935 &
               country %in% c("United States", "United Kingdom"))
af$US <- as.numeric(af$country == "United States")
af$b  <- sp_before(af$year)
af$aa <- sp_after(af$year)
af$b_US  <- af$b * af$US;  af$a_US  <- af$aa * af$US
af$b_UK  <- af$b * (1 - af$US); af$a_UK <- af$aa * (1 - af$US)

rob <- function(m) coeftest(m, vcov = vcovHC(m, type = "HC1"))

us <- subset(af, US == 1)
m1 <- lm(ln_wingload ~ b + aa, data = us)
m2 <- lm(ln_maxspeed ~ b + aa, data = us)
# Equation (5): baseline (comparison-country, UK) spline on all observations,
# plus spline x US (the US slope RELATIVE to the UK), a US indicator and a constant.
m3 <- lm(ln_wingload ~ b_US + a_US + US + b + aa, data = af)
m4 <- lm(ln_maxspeed ~ b_US + a_US + US + b + aa, data = af)
for (m in list(m1, m2, m3, m4)) { print(rob(m)); cat("N =", nobs(m), "\n\n") }

# ---- Engines: US engines (engine_data is the fighter/bomber-engine file), liquid-cooled control
eu <- subset(e, country == "United States")
eu$b <- sp_before(eu$year); eu$aa <- sp_after(eu$year)
m5 <- lm(ln_hp_per_lbs ~ b + aa + liquid_cooled, data = eu)
print(rob(m5)); cat("N =", nobs(m5), "\n\n")

f <- function(x) formatC(x, digits = 10, format = "g")
cat("RESULT:airframe_wingload_trend_before_1926_us=", f(coef(m1)["b"]), "\n", sep = "")
cat("RESULT:airframe_wingload_trend_after_1926_us=", f(coef(m1)["aa"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_before_1926_us=", f(coef(m2)["b"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_after_1926_us=", f(coef(m2)["aa"]), "\n", sep = "")
cat("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=", f(coef(m3)["b_US"]), "\n", sep = "")
cat("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=", f(coef(m3)["a_US"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=", f(coef(m4)["b_US"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=", f(coef(m4)["a_US"]), "\n", sep = "")
cat("RESULT:engine_hp_per_weight_trend_before_1926_us=", f(coef(m5)["b"]), "\n", sep = "")
cat("RESULT:engine_hp_per_weight_trend_after_1926_us=", f(coef(m5)["aa"]), "\n", sep = "")
cat("RESULT:observations_airframe_wingload_us=", nobs(m1), "\n", sep = "")
cat("RESULT:observations_engine_us=", nobs(m5), "\n", sep = "")
