suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(lmtest)
})

set.seed(42)

base <- "/Users/matthew/dev/Retally/.cache/datasets/hanlon_2022_aircraft_ip_spillovers"
af_path <- file.path(base, "3 replication files/data/dta/airframe_data.dta")
en_path <- file.path(base, "3 replication files/data/dta/engine_data.dta")

to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) {
    as.character(haven::as_factor(x, levels = "labels"))
  } else {
    as.character(x)
  }
}
to_num <- function(x) as.numeric(haven::zap_labels(x))

fmt <- function(x) formatC(x, digits = 8, format = "g")

emit <- function(name, value) {
  cat(sprintf("RESULT:%s=%s\n", name, fmt(value)))
}

# Stata: mkspline pre1926 1926 post1926 = year
make_spline <- function(d) {
  d$pre1926 <- pmin(d$year, 1926)
  d$post1926 <- pmax(d$year - 1926, 0)
  d$pre1926_US <- d$US * d$pre1926
  d$post1926_US <- d$US * d$post1926
  d
}

fit_robust <- function(formula, data) {
  m <- lm(formula, data = data)
  V <- sandwich::vcovHC(m, type = "HC1")
  list(model = m, coef = coef(m), se = sqrt(diag(V)), n = nobs(m))
}

# ---------------- Table 1: Airframes ----------------
af <- haven::read_dta(af_path)
af <- as.data.frame(af)
af$country <- to_chr(af$country)
af$type <- to_chr(af$type)
af$year <- to_num(af$year)
af$ln_wingload <- to_num(af$ln_wingload)
af$ln_maxspeed <- to_num(af$ln_maxspeed)

af <- af[af$country %in% c("United States", "United Kingdom"), ]
af <- af[!is.na(af$type) & af$type %in% c("fighter", "bomber"), ]
af$US <- as.numeric(af$country == "United States")
af <- make_spline(af)

af_us <- af[af$US == 1, ]

# Column 1: US only, wing load
r1 <- fit_robust(ln_wingload ~ pre1926_US + post1926_US, af_us)
# Column 2: US only, max speed
r2 <- fit_robust(ln_maxspeed ~ pre1926_US + post1926_US, af_us)
# Column 3: US and UK, wing load
r3 <- fit_robust(ln_wingload ~ pre1926 + pre1926_US + post1926 + post1926_US + US, af)
# Column 4: US and UK, max speed
r4 <- fit_robust(ln_maxspeed ~ pre1926 + pre1926_US + post1926 + post1926_US + US, af)

# ---------------- Table 4: Engines ----------------
en <- haven::read_dta(en_path)
en <- as.data.frame(en)
en$country <- to_chr(en$country)
en$year <- to_num(en$year)
en$ln_hp_per_lbs <- to_num(en$ln_hp_per_lbs)
en$liquid_cooled <- to_num(en$liquid_cooled)

en <- en[en$country %in% c("United States", "United Kingdom"), ]
en$US <- as.numeric(en$country == "United States")
en <- make_spline(en)
en_us <- en[en$US == 1, ]

e1 <- fit_robust(ln_hp_per_lbs ~ pre1926_US + post1926_US + liquid_cooled, en_us)

# ---------------- Output ----------------
emit("airframe_wingload_trend_before_1926_us", r1$coef["pre1926_US"])
emit("airframe_wingload_trend_after_1926_us", r1$coef["post1926_US"])
emit("airframe_maxspeed_trend_before_1926_us", r2$coef["pre1926_US"])
emit("airframe_maxspeed_trend_after_1926_us", r2$coef["post1926_US"])
emit("airframe_wingload_trend_before_1926_us_vs_uk", r3$coef["pre1926_US"])
emit("airframe_wingload_trend_after_1926_us_vs_uk", r3$coef["post1926_US"])
emit("airframe_maxspeed_trend_before_1926_us_vs_uk", r4$coef["pre1926_US"])
emit("airframe_maxspeed_trend_after_1926_us_vs_uk", r4$coef["post1926_US"])
emit("engine_hp_per_weight_trend_before_1926_us", e1$coef["pre1926_US"])
emit("engine_hp_per_weight_trend_after_1926_us", e1$coef["post1926_US"])
emit("observations_airframe_wingload_us", r1$n)
emit("observations_engine_us", e1$n)

# Robust (HC1) standard errors, as in Stata's vce(r)
emit("airframe_wingload_trend_before_1926_us_se", r1$se["pre1926_US"])
emit("airframe_wingload_trend_after_1926_us_se", r1$se["post1926_US"])
emit("airframe_maxspeed_trend_before_1926_us_se", r2$se["pre1926_US"])
emit("airframe_maxspeed_trend_after_1926_us_se", r2$se["post1926_US"])
emit("airframe_wingload_trend_before_1926_us_vs_uk_se", r3$se["pre1926_US"])
emit("airframe_wingload_trend_after_1926_us_vs_uk_se", r3$se["post1926_US"])
emit("airframe_maxspeed_trend_before_1926_us_vs_uk_se", r4$se["pre1926_US"])
emit("airframe_maxspeed_trend_after_1926_us_vs_uk_se", r4$se["post1926_US"])
emit("engine_hp_per_weight_trend_before_1926_us_se", e1$se["pre1926_US"])
emit("engine_hp_per_weight_trend_after_1926_us_se", e1$se["post1926_US"])