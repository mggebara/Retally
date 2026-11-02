# Hanlon (2022) -- Table 1 (cols 1-4) and Table 4 (col 1), following 2-results-main.do
suppressPackageStartupMessages({ library(haven); library(fixest) })
set.seed(42)
base <- "/Users/matthew/dev/Retally/benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/seeded/2026-10-21-b/mount/hanlon_2022_aircraft_ip_spillovers/3 replication files/data/dta"

# mkspline pre1926 1926 post1926 = year
spline <- function(d) {
  d$pre1926  <- pmin(d$year, 1926)
  d$post1926 <- pmax(d$year - 1926, 0)
  d$US <- as.integer(d$country == "United States")
  d$pre1926_US  <- d$US * d$pre1926
  d$post1926_US <- d$US * d$post1926
  d
}

## ---- Table 1: airframes ----
af <- as.data.frame(zap_labels(read_dta(file.path(base, "airframe_data.dta"))))
af <- af[af$country %in% c("United States", "United Kingdom") & af$type %in% c("fighter", "bomber"), ]
af <- spline(af)
us <- af[af$US == 1, ]

# reg y pre1926_US post1926_US if US==1, vce(r)
m1 <- feols(ln_wingload ~ pre1926_US + post1926_US, data = us, vcov = "hetero")
m2 <- feols(ln_maxspeed ~ pre1926_US + post1926_US, data = us, vcov = "hetero")
# reg y pre1926* post1926* US, vce(r)
m3 <- feols(ln_wingload ~ pre1926 + post1926 + pre1926_US + post1926_US + US, data = af, vcov = "hetero")
m4 <- feols(ln_maxspeed ~ pre1926 + post1926 + pre1926_US + post1926_US + US, data = af, vcov = "hetero")

## ---- Table 4: engines ----
en <- as.data.frame(zap_labels(read_dta(file.path(base, "engine_data.dta"))))
en <- en[en$country %in% c("United States", "United Kingdom"), ]
en <- spline(en)
# reg ln_hp_per_lbs pre1926_US post1926_US liquid_cooled if US, vce(r)
e1 <- feols(ln_hp_per_lbs ~ pre1926_US + post1926_US + liquid_cooled, data = en[en$US == 1, ], vcov = "hetero")

print(etable(m1, m2, m3, m4, e1))

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("airframe_wingload_trend_before_1926_us", coef(m1)[["pre1926_US"]])
r("airframe_wingload_trend_after_1926_us",  coef(m1)[["post1926_US"]])
r("airframe_maxspeed_trend_before_1926_us", coef(m2)[["pre1926_US"]])
r("airframe_maxspeed_trend_after_1926_us",  coef(m2)[["post1926_US"]])
r("airframe_wingload_trend_before_1926_us_vs_uk", coef(m3)[["pre1926_US"]])
r("airframe_wingload_trend_after_1926_us_vs_uk",  coef(m3)[["post1926_US"]])
r("airframe_maxspeed_trend_before_1926_us_vs_uk", coef(m4)[["pre1926_US"]])
r("airframe_maxspeed_trend_after_1926_us_vs_uk",  coef(m4)[["post1926_US"]])
r("engine_hp_per_weight_trend_before_1926_us", coef(e1)[["pre1926_US"]])
r("engine_hp_per_weight_trend_after_1926_us",  coef(e1)[["post1926_US"]])
r("observations_airframe_wingload_us", nobs(m1))
r("observations_engine_us", nobs(e1))
