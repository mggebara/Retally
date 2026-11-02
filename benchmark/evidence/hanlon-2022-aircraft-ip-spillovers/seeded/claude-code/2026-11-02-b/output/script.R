# Hanlon (2022) Table 1 cols 1-4 and Table 4 col 1, following 2-results-main.do
suppressPackageStartupMessages({library(haven); library(fixest)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/seeded/2026-11-02-b/mount/hanlon_2022_aircraft_ip_spillovers/3 replication files/data/dta"

# Stata: mkspline pre1926 1926 post1926 = year
mkspline <- function(d) {
  d$pre1926  <- pmin(d$year, 1926)
  d$post1926 <- pmax(d$year - 1926, 0)
  d$US <- as.numeric(d$country == "United States")
  d$pre1926_US  <- d$US * d$pre1926
  d$post1926_US <- d$US * d$post1926
  d
}

## Table 1
af <- as.data.frame(read_dta(file.path(base, "airframe_data.dta")))
af <- af[af$country %in% c("United States", "United Kingdom") & af$type %in% c("fighter", "bomber"), ]
af <- mkspline(af)
afus <- af[af$US == 1, ]
t1c1 <- feols(ln_wingload ~ pre1926_US + post1926_US, data = afus, vcov = "hetero")
t1c2 <- feols(ln_maxspeed ~ pre1926_US + post1926_US, data = afus, vcov = "hetero")
t1c3 <- feols(ln_wingload ~ pre1926 + pre1926_US + post1926 + post1926_US + US, data = af, vcov = "hetero")
t1c4 <- feols(ln_maxspeed ~ pre1926 + pre1926_US + post1926 + post1926_US + US, data = af, vcov = "hetero")

## Table 4
en <- as.data.frame(read_dta(file.path(base, "engine_data.dta")))
en <- en[en$country %in% c("United States", "United Kingdom"), ]
en <- mkspline(en)
t4c1 <- feols(ln_hp_per_lbs ~ pre1926_US + post1926_US + liquid_cooled, data = en[en$US == 1, ], vcov = "hetero")

for (m in list(t1c1, t1c2, t1c3, t1c4, t4c1)) print(summary(m))

out <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
out("airframe_wingload_trend_before_1926_us", coef(t1c1)[["pre1926_US"]])
out("airframe_wingload_trend_after_1926_us",  coef(t1c1)[["post1926_US"]])
out("airframe_maxspeed_trend_before_1926_us", coef(t1c2)[["pre1926_US"]])
out("airframe_maxspeed_trend_after_1926_us",  coef(t1c2)[["post1926_US"]])
out("airframe_wingload_trend_before_1926_us_vs_uk", coef(t1c3)[["pre1926_US"]])
out("airframe_wingload_trend_after_1926_us_vs_uk",  coef(t1c3)[["post1926_US"]])
out("airframe_maxspeed_trend_before_1926_us_vs_uk", coef(t1c4)[["pre1926_US"]])
out("airframe_maxspeed_trend_after_1926_us_vs_uk",  coef(t1c4)[["post1926_US"]])
out("engine_hp_per_weight_trend_before_1926_us", coef(t4c1)[["pre1926_US"]])
out("engine_hp_per_weight_trend_after_1926_us",  coef(t4c1)[["post1926_US"]])
cat(sprintf("RESULT:observations_airframe_wingload_us=%d\n", nobs(t1c1)))
cat(sprintf("RESULT:observations_engine_us=%d\n", nobs(t4c1)))
