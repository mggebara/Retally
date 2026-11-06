suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanlon_2022_aircraft_ip_spillovers.script-free"
af_path <- file.path(base, "3 replication files/data/dta/airframe_data.dta")
en_path <- file.path(base, "3 replication files/data/dta/engine_data.dta")

to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) x <- as.character(haven::as_factor(x, levels = "labels"))
  as.character(x)
}
is_us <- function(x) {
  s <- tolower(trimws(x))
  s %in% c("us", "usa", "u.s.", "u.s.a.", "united states", "united states of america", "america") |
    grepl("united states", s)
}
is_uk <- function(x) {
  s <- tolower(trimws(x))
  s %in% c("uk", "u.k.", "united kingdom", "britain", "great britain", "england", "gb") |
    grepl("united kingdom|britain|england", s)
}
add_spline <- function(d) {
  d$yr <- as.numeric(d$year)
  d$pre  <- pmin(d$yr - 1926, 0)
  d$post <- pmax(d$yr - 1926, 0)
  d
}

## ---------------- Airframes ----------------
af <- haven::read_dta(af_path)
af <- as.data.frame(af)
af$country_c <- to_chr(af$country)
af$type_c <- tolower(to_chr(af$type))
af$year <- as.numeric(af$year)
n_loaded_af <- nrow(af)

# restriction: fighters and bombers
fb <- grepl("fight|bomb|pursuit|attack", af$type_c)
if (sum(fb, na.rm = TRUE) > 0) af_fb <- af[fb & !is.na(fb), ] else af_fb <- af
# restriction: 1918-1935
af_fb <- af_fb[!is.na(af_fb$year) & af_fb$year >= 1918 & af_fb$year <= 1935, ]
af_fb <- add_spline(af_fb)

if (!"ln_wingload" %in% names(af_fb) || all(is.na(af_fb$ln_wingload))) af_fb$ln_wingload <- log(af_fb$wingload)
if (!"ln_maxspeed" %in% names(af_fb) || all(is.na(af_fb$ln_maxspeed))) af_fb$ln_maxspeed <- log(af_fb$maxspeed)
af_fb$ln_wingload[!is.finite(af_fb$ln_wingload)] <- NA
af_fb$ln_maxspeed[!is.finite(af_fb$ln_maxspeed)] <- NA

af_fb$us <- as.integer(is_us(af_fb$country_c))
af_fb$uk <- as.integer(is_uk(af_fb$country_c))

af_us <- af_fb[af_fb$us == 1, ]
af_usuk <- af_fb[af_fb$us == 1 | af_fb$uk == 1, ]

# US only, wing load
m1 <- feols(ln_wingload ~ pre + post, data = af_us, vcov = "hetero")
cat(sprintf("SAMPLE:airframe_us_wingload:loaded=%d\n", n_loaded_af))
cat(sprintf("SAMPLE:airframe_us_wingload:fighters_bombers=%d\n", sum(fb, na.rm = TRUE)))
cat(sprintf("SAMPLE:airframe_us_wingload:years_1918_1935=%d\n", nrow(af_fb)))
cat(sprintf("SAMPLE:airframe_us_wingload:united_states=%d\n", nrow(af_us)))
cat(sprintf("SAMPLE:airframe_us_wingload:estimation=%d\n", nobs(m1)))

# US only, max speed
m2 <- feols(ln_maxspeed ~ pre + post, data = af_us, vcov = "hetero")
cat(sprintf("SAMPLE:airframe_us_maxspeed:loaded=%d\n", n_loaded_af))
cat(sprintf("SAMPLE:airframe_us_maxspeed:fighters_bombers=%d\n", sum(fb, na.rm = TRUE)))
cat(sprintf("SAMPLE:airframe_us_maxspeed:years_1918_1935=%d\n", nrow(af_fb)))
cat(sprintf("SAMPLE:airframe_us_maxspeed:united_states=%d\n", nrow(af_us)))
cat(sprintf("SAMPLE:airframe_us_maxspeed:estimation=%d\n", nobs(m2)))

# US vs UK
af_usuk$us_pre  <- af_usuk$us * af_usuk$pre
af_usuk$us_post <- af_usuk$us * af_usuk$post
af_usuk$uk_pre  <- (1 - af_usuk$us) * af_usuk$pre
af_usuk$uk_post <- (1 - af_usuk$us) * af_usuk$post
# Equation (5): constant + US dummy + comparison-country spline + US-interacted spline (relative slopes)
m3 <- feols(ln_wingload ~ us + pre + post + us_pre + us_post, data = af_usuk, vcov = "hetero")
m4 <- feols(ln_maxspeed ~ us + pre + post + us_pre + us_post, data = af_usuk, vcov = "hetero")
for (nm in c("airframe_usuk_wingload", "airframe_usuk_maxspeed")) {
  mm <- if (nm == "airframe_usuk_wingload") m3 else m4
  cat(sprintf("SAMPLE:%s:loaded=%d\n", nm, n_loaded_af))
  cat(sprintf("SAMPLE:%s:fighters_bombers=%d\n", nm, sum(fb, na.rm = TRUE)))
  cat(sprintf("SAMPLE:%s:years_1918_1935=%d\n", nm, nrow(af_fb)))
  cat(sprintf("SAMPLE:%s:us_and_uk=%d\n", nm, nrow(af_usuk)))
  cat(sprintf("SAMPLE:%s:estimation=%d\n", nm, nobs(mm)))
}

## ---------------- Engines ----------------
en <- as.data.frame(haven::read_dta(en_path))
n_loaded_en <- nrow(en)
en$country_c <- to_chr(en$country)
en$year <- as.numeric(en$year)
en$liquid_cooled <- as.numeric(en$liquid_cooled)
en_us <- en[is_us(en$country_c), ]
n_us_en <- nrow(en_us)
en_us <- en_us[!is.na(en_us$year) & en_us$year >= 1918 & en_us$year <= 1935, ]
en_us <- add_spline(en_us)
en_us$ln_hp_per_lbs[!is.finite(en_us$ln_hp_per_lbs)] <- NA
m5 <- feols(ln_hp_per_lbs ~ pre + post + liquid_cooled, data = en_us, vcov = "hetero")
cat(sprintf("SAMPLE:engine_us_hp_per_lbs:loaded=%d\n", n_loaded_en))
cat(sprintf("SAMPLE:engine_us_hp_per_lbs:united_states=%d\n", n_us_en))
cat(sprintf("SAMPLE:engine_us_hp_per_lbs:years_1918_1935=%d\n", nrow(en_us)))
cat(sprintf("SAMPLE:engine_us_hp_per_lbs:estimation=%d\n", nobs(m5)))

## ---------------- Results ----------------
cf <- function(m, v) unname(coef(m)[v])
se <- function(m, v) unname(sqrt(diag(vcov(m)))[v])

cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us=%.6f\n", cf(m1, "pre")))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us=%.6f\n", cf(m1, "post")))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us=%.6f\n", cf(m2, "pre")))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us=%.6f\n", cf(m2, "post")))
cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=%.6f\n", cf(m3, "us_pre")))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=%.6f\n", cf(m3, "us_post")))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=%.6f\n", cf(m4, "us_pre")))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=%.6f\n", cf(m4, "us_post")))
cat(sprintf("RESULT:engine_hp_per_weight_trend_before_1926_us=%.6f\n", cf(m5, "pre")))
cat(sprintf("RESULT:engine_hp_per_weight_trend_after_1926_us=%.6f\n", cf(m5, "post")))
cat(sprintf("RESULT:observations_airframe_wingload_us=%d\n", nobs(m1)))
cat(sprintf("RESULT:observations_engine_us=%d\n", nobs(m5)))

cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us_se=%.6f\n", se(m1, "pre")))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us_se=%.6f\n", se(m1, "post")))
cat(sprintf("RESULT:engine_hp_per_weight_trend_before_1926_us_se=%.6f\n", se(m5, "pre")))
cat(sprintf("RESULT:engine_hp_per_weight_trend_after_1926_us_se=%.6f\n", se(m5, "post")))
