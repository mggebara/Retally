suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- '<repo>/.cache/datasets/hanlon_2022_aircraft_ip_spillovers.script-free'
air_path <- file.path(base, '3 replication files/data/dta/airframe_data.dta')
eng_path <- file.path(base, '3 replication files/data/dta/engine_data.dta')

to_chr <- function(x) {
  if (inherits(x, 'haven_labelled')) x <- as.character(haven::as_factor(x, levels = 'labels'))
  as.character(x)
}
norm <- function(x) tolower(gsub('[^A-Za-z]', '', to_chr(x)))
is_us <- function(x) { z <- norm(x); z %in% c('us', 'usa', 'unitedstates', 'unitedstatesofamerica', 'america', 'american') }
is_uk <- function(x) { z <- norm(x); z %in% c('uk', 'unitedkingdom', 'britain', 'greatbritain', 'gb', 'england', 'british') }

add_spline <- function(d, knot = 1926) {
  d$yr <- as.numeric(d$year)
  d$pre  <- pmin(d$yr - knot, 0)
  d$post <- pmax(d$yr - knot, 0)
  d
}

## ---------------- Airframes ----------------
air <- haven::read_dta(air_path)
air$country_chr <- to_chr(air$country)
air$type_chr <- tolower(to_chr(air$type))

fb_filter <- function(d) {
  has_fb <- any(grepl('fighter|bomber|pursuit|attack', d$type_chr))
  if (has_fb) d[grepl('fighter|bomber|pursuit', d$type_chr), , drop = FALSE] else d
}

build_air <- function(name, countries_fun, yvar) {
  d <- air
  cat(sprintf('SAMPLE:%s:loaded=%d\n', name, nrow(d)))
  d <- d[countries_fun(d$country), , drop = FALSE]
  cat(sprintf('SAMPLE:%s:country=%d\n', name, nrow(d)))
  d <- fb_filter(d)
  cat(sprintf('SAMPLE:%s:fighters_bombers=%d\n', name, nrow(d)))
  d <- d[!is.na(d$year) & d$year >= 1918 & d$year <= 1935, , drop = FALSE]
  cat(sprintf('SAMPLE:%s:years_1918_1935=%d\n', name, nrow(d)))
  d <- d[!is.na(d[[yvar]]) & is.finite(d[[yvar]]), , drop = FALSE]
  cat(sprintf('SAMPLE:%s:nonmissing_outcome=%d\n', name, nrow(d)))
  d <- add_spline(d)
  d$us <- as.numeric(is_us(d$country))
  d
}

# ln_wingload / ln_maxspeed: build if missing
if (!'ln_wingload' %in% names(air) || all(is.na(air$ln_wingload))) {
  wl <- if ('wingload' %in% names(air)) air$wingload else air$grossweight / air$wing_area
  air$ln_wingload <- log(wl)
}
if (!'ln_maxspeed' %in% names(air) || all(is.na(air$ln_maxspeed))) air$ln_maxspeed <- log(air$maxspeed)
air$ln_wingload <- as.numeric(air$ln_wingload)
air$ln_maxspeed <- as.numeric(air$ln_maxspeed)

us_only <- function(x) is_us(x)
us_uk <- function(x) is_us(x) | is_uk(x)

d1 <- build_air('t1c1_us_wingload', us_only, 'ln_wingload')
m1 <- feols(ln_wingload ~ pre + post, data = d1, vcov = 'hetero')
cat(sprintf('SAMPLE:t1c1_us_wingload:estimation=%d\n', nobs(m1)))

d2 <- build_air('t1c2_us_maxspeed', us_only, 'ln_maxspeed')
m2 <- feols(ln_maxspeed ~ pre + post, data = d2, vcov = 'hetero')
cat(sprintf('SAMPLE:t1c2_us_maxspeed:estimation=%d\n', nobs(m2)))

d3 <- build_air('t1c3_usuk_wingload', us_uk, 'ln_wingload')
m3 <- feols(ln_wingload ~ us + pre + post + us:pre + us:post, data = d3, vcov = 'hetero')
cat(sprintf('SAMPLE:t1c3_usuk_wingload:estimation=%d\n', nobs(m3)))

d4 <- build_air('t1c4_usuk_maxspeed', us_uk, 'ln_maxspeed')
m4 <- feols(ln_maxspeed ~ us + pre + post + us:pre + us:post, data = d4, vcov = 'hetero')
cat(sprintf('SAMPLE:t1c4_usuk_maxspeed:estimation=%d\n', nobs(m4)))

## ---------------- Engines ----------------
eng <- haven::read_dta(eng_path)
cat(sprintf('SAMPLE:t4c1_us_engine:loaded=%d\n', nrow(eng)))
e <- eng[is_us(eng$country), , drop = FALSE]
cat(sprintf('SAMPLE:t4c1_us_engine:country=%d\n', nrow(e)))
e$ln_hp_per_lbs <- as.numeric(e$ln_hp_per_lbs)
e <- e[!is.na(e$ln_hp_per_lbs) & is.finite(e$ln_hp_per_lbs) & !is.na(e$year), , drop = FALSE]
cat(sprintf('SAMPLE:t4c1_us_engine:nonmissing_outcome=%d\n', nrow(e)))
e <- add_spline(e)
e$liquid_cooled <- as.numeric(e$liquid_cooled)
m5 <- feols(ln_hp_per_lbs ~ pre + post + liquid_cooled, data = e, vcov = 'hetero')
cat(sprintf('SAMPLE:t4c1_us_engine:estimation=%d\n', nobs(m5)))

cf <- function(m, v) unname(coef(m)[v])
se <- function(m, v) unname(sqrt(diag(vcov(m)))[v])

cat(sprintf('RESULT:airframe_wingload_trend_before_1926_us=%.6f\n', cf(m1, 'pre')))
cat(sprintf('RESULT:airframe_wingload_trend_after_1926_us=%.6f\n', cf(m1, 'post')))
cat(sprintf('RESULT:airframe_maxspeed_trend_before_1926_us=%.6f\n', cf(m2, 'pre')))
cat(sprintf('RESULT:airframe_maxspeed_trend_after_1926_us=%.6f\n', cf(m2, 'post')))
cat(sprintf('RESULT:airframe_wingload_trend_before_1926_us_vs_uk=%.6f\n', cf(m3, 'us:pre')))
cat(sprintf('RESULT:airframe_wingload_trend_after_1926_us_vs_uk=%.6f\n', cf(m3, 'us:post')))
cat(sprintf('RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=%.6f\n', cf(m4, 'us:pre')))
cat(sprintf('RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=%.6f\n', cf(m4, 'us:post')))
cat(sprintf('RESULT:engine_hp_per_weight_trend_before_1926_us=%.6f\n', cf(m5, 'pre')))
cat(sprintf('RESULT:engine_hp_per_weight_trend_after_1926_us=%.6f\n', cf(m5, 'post')))
cat(sprintf('RESULT:observations_airframe_wingload_us=%d\n', nobs(m1)))
cat(sprintf('RESULT:observations_engine_us=%d\n', nobs(m5)))