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
  if (inherits(x, "haven_labelled")) x <- as.character(haven::as_factor(x))
  as.character(x)
}

fmt <- function(x) formatC(x, digits = 6, format = "f")

# Stata: mkspline pre1926 1926 post1926 = year
mk_spline <- function(d) {
  d$pre1926 <- pmin(d$year, 1926)
  d$post1926 <- pmax(d$year - 1926, 0)
  d$pre1926_US <- d$US * d$pre1926
  d$post1926_US <- d$US * d$post1926
  d
}

robust_fit <- function(formula, data) {
  m <- lm(formula, data = data)
  V <- sandwich::vcovHC(m, type = "HC1")
  list(model = m, coef = coef(m), se = sqrt(diag(V)), n = nobs(m))
}

# ---------------- Table 1: Airframes ----------------
af <- haven::read_dta(af_path)
af$country <- to_chr(af$country)
af$type <- to_chr(af$type)
af$year <- as.numeric(af$year)
af$ln_wingload <- as.numeric(af$ln_wingload)
af$ln_maxspeed <- as.numeric(af$ln_maxspeed)
af <- af[af$country %in% c("United States", "United Kingdom"), ]
af <- af[af$type %in% c("fighter", "bomber"), ]
af$US <- as.numeric(af$country == "United States")
af <- mk_spline(af)

af_us <- af[af$US == 1, ]

# Col 1: US only, wing load
r1 <- robust_fit(ln_wingload ~ pre1926_US + post1926_US, af_us[!is.na(af_us$ln_wingload) & !is.na(af_us$year), ])
# Col 2: US only, max speed
r2 <- robust_fit(ln_maxspeed ~ pre1926_US + post1926_US, af_us[!is.na(af_us$ln_maxspeed) & !is.na(af_us$year), ])
# Col 3: US & UK, wing load
r3 <- robust_fit(ln_wingload ~ pre1926 + pre1926_US + post1926 + post1926_US + US,
                 af[!is.na(af$ln_wingload) & !is.na(af$year), ])
# Col 4: US & UK, max speed
r4 <- robust_fit(ln_maxspeed ~ pre1926 + pre1926_US + post1926 + post1926_US + US,
                 af[!is.na(af$ln_maxspeed) & !is.na(af$year), ])

# ---------------- Table 4: Engines ----------------
en <- haven::read_dta(en_path)
en$country <- to_chr(en$country)
en$year <- as.numeric(en$year)
en$ln_hp_per_lbs <- as.numeric(en$ln_hp_per_lbs)
en$liquid_cooled <- as.numeric(en$liquid_cooled)
en <- en[en$country %in% c("United States", "United Kingdom"), ]
en$US <- as.numeric(en$country == "United States")
en <- mk_spline(en)
en_us <- en[en$US == 1, ]
en_us <- en_us[!is.na(en_us$ln_hp_per_lbs) & !is.na(en_us$year) & !is.na(en_us$liquid_cooled), ]

e1 <- robust_fit(ln_hp_per_lbs ~ pre1926_US + post1926_US + liquid_cooled, en_us)

# ---------------- Output ----------------
cat("RESULT:airframe_wingload_trend_before_1926_us=", fmt(r1$coef["pre1926_US"]), "\n", sep = "")
cat("RESULT:airframe_wingload_trend_after_1926_us=", fmt(r1$coef["post1926_US"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_before_1926_us=", fmt(r2$coef["pre1926_US"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_after_1926_us=", fmt(r2$coef["post1926_US"]), "\n", sep = "")
cat("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=", fmt(r3$coef["pre1926_US"]), "\n", sep = "")
cat("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=", fmt(r3$coef["post1926_US"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=", fmt(r4$coef["pre1926_US"]), "\n", sep = "")
cat("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=", fmt(r4$coef["post1926_US"]), "\n", sep = "")
cat("RESULT:engine_hp_per_weight_trend_before_1926_us=", fmt(e1$coef["pre1926_US"]), "\n", sep = "")
cat("RESULT:engine_hp_per_weight_trend_after_1926_us=", fmt(e1$coef["post1926_US"]), "\n", sep = "")
cat("RESULT:observations_airframe_wingload_us=", r1$n, "\n", sep = "")
cat("RESULT:observations_engine_us=", e1$n, "\n", sep = "")
