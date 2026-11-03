suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(lmtest)
})

set.seed(42)

base <- "<repo>/.cache/datasets/hanlon_2022_aircraft_ip_spillovers"
dta_dir <- file.path(base, "3 replication files", "data", "dta")

to_chr <- function(x) {
  if (haven::is.labelled(x)) as.character(haven::as_factor(x)) else as.character(x)
}

fmt <- function(v) formatC(as.numeric(v), digits = 10, format = "g")

emit <- function(name, value) {
  cat(sprintf("RESULT:%s=%s\n", name, fmt(value)))
}

make_spline <- function(df) {
  df$pre1926  <- pmin(df$year, 1926)
  df$post1926 <- pmax(df$year - 1926, 0)
  df$pre1926_US  <- df$US * df$pre1926
  df$post1926_US <- df$US * df$post1926
  df
}

fit_robust <- function(formula, data) {
  m <- lm(formula, data = data)
  V <- sandwich::vcovHC(m, type = "HC1")
  list(model = m, coef = coef(m), se = sqrt(diag(V)), n = nobs(m))
}

## ---------------- Table 1: Airframes ----------------
af <- haven::read_dta(file.path(dta_dir, "airframe_data.dta"))
af <- as.data.frame(haven::zap_formats(af))
af$country <- to_chr(af$country)
af$type    <- to_chr(af$type)
af$year    <- as.numeric(haven::zap_labels(af$year))
af$ln_wingload <- as.numeric(haven::zap_labels(af$ln_wingload))
af$ln_maxspeed <- as.numeric(haven::zap_labels(af$ln_maxspeed))

af <- af[af$country %in% c("United States", "United Kingdom") &
           af$type %in% c("fighter", "bomber"), ]
af$US <- as.numeric(af$country == "United States")
af <- make_spline(af)

af_us <- af[af$US == 1, ]

# Column 1: US only, log wing load
r1 <- fit_robust(ln_wingload ~ pre1926_US + post1926_US, af_us)
# Column 2: US only, log max speed
r2 <- fit_robust(ln_maxspeed ~ pre1926_US + post1926_US, af_us)
# Column 3: US & UK, log wing load
r3 <- fit_robust(ln_wingload ~ pre1926 + pre1926_US + post1926 + post1926_US + US, af)
# Column 4: US & UK, log max speed
r4 <- fit_robust(ln_maxspeed ~ pre1926 + pre1926_US + post1926 + post1926_US + US, af)

## ---------------- Table 4: Engines ----------------
en <- haven::read_dta(file.path(dta_dir, "engine_data.dta"))
en <- as.data.frame(haven::zap_formats(en))
en$country <- to_chr(en$country)
en$year <- as.numeric(haven::zap_labels(en$year))
en$ln_hp_per_lbs <- as.numeric(haven::zap_labels(en$ln_hp_per_lbs))
en$liquid_cooled <- as.numeric(haven::zap_labels(en$liquid_cooled))

en <- en[en$country %in% c("United States", "United Kingdom"), ]
en$US <- as.numeric(en$country == "United States")
en <- make_spline(en)
en_us <- en[en$US == 1, ]

e1 <- fit_robust(ln_hp_per_lbs ~ pre1926_US + post1926_US + liquid_cooled, en_us)

## ---------------- Output ----------------
emit("airframe_wingload_trend_before_1926_us", r1$coef["pre1926_US"])
emit("airframe_wingload_trend_before_1926_us_se", r1$se["pre1926_US"])
emit("airframe_wingload_trend_after_1926_us", r1$coef["post1926_US"])
emit("airframe_wingload_trend_after_1926_us_se", r1$se["post1926_US"])

emit("airframe_maxspeed_trend_before_1926_us", r2$coef["pre1926_US"])
emit("airframe_maxspeed_trend_before_1926_us_se", r2$se["pre1926_US"])
emit("airframe_maxspeed_trend_after_1926_us", r2$coef["post1926_US"])
emit("airframe_maxspeed_trend_after_1926_us_se", r2$se["post1926_US"])

emit("airframe_wingload_trend_before_1926_us_vs_uk", r3$coef["pre1926_US"])
emit("airframe_wingload_trend_before_1926_us_vs_uk_se", r3$se["pre1926_US"])
emit("airframe_wingload_trend_after_1926_us_vs_uk", r3$coef["post1926_US"])
emit("airframe_wingload_trend_after_1926_us_vs_uk_se", r3$se["post1926_US"])

emit("airframe_maxspeed_trend_before_1926_us_vs_uk", r4$coef["pre1926_US"])
emit("airframe_maxspeed_trend_before_1926_us_vs_uk_se", r4$se["pre1926_US"])
emit("airframe_maxspeed_trend_after_1926_us_vs_uk", r4$coef["post1926_US"])
emit("airframe_maxspeed_trend_after_1926_us_vs_uk_se", r4$se["post1926_US"])

emit("engine_hp_per_weight_trend_before_1926_us", e1$coef["pre1926_US"])
emit("engine_hp_per_weight_trend_before_1926_us_se", e1$se["pre1926_US"])
emit("engine_hp_per_weight_trend_after_1926_us", e1$coef["post1926_US"])
emit("engine_hp_per_weight_trend_after_1926_us_se", e1$se["post1926_US"])

emit("observations_airframe_wingload_us", r1$n)
emit("observations_engine_us", e1$n)
