suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanlon_2022_aircraft_ip_spillovers.script-free"
af <- haven::read_dta(file.path(base, "3 replication files/data/dta/airframe_data.dta"))
en <- haven::read_dta(file.path(base, "3 replication files/data/dta/engine_data.dta"))

to_chr <- function(x) {
  if (haven::is.labelled(x)) as.character(haven::as_factor(x, levels = "labels"))
  else as.character(x)
}

country_codes <- function(cvec) {
  cc <- trimws(to_chr(cvec))
  is_us <- grepl("^(us|usa|u\\.s\\.?|u\\.s\\.a\\.?|united states.*|america.*)$", tolower(cc))
  is_uk <- grepl("^(uk|u\\.k\\.?|united kingdom|britain|great britain|gb|england|british)$", tolower(cc))
  if (!any(is_us)) {
    tab <- sort(table(cc), decreasing = TRUE)
    message("Country values not matched; falling back on frequency: ", paste(names(tab), collapse = ", "))
    is_us <- cc == names(tab)[1]
    if (!any(is_uk) && length(tab) > 1) is_uk <- cc == names(tab)[2]
  }
  list(us = is_us, uk = is_uk, raw = cc)
}

message("Airframe country values: ", paste(unique(to_chr(af$country)), collapse = " | "))
message("Airframe type values: ", paste(unique(to_chr(af$type)), collapse = " | "))
message("Engine country values: ", paste(unique(to_chr(en$country)), collapse = " | "))

# ---------- Airframes ----------
afc <- country_codes(af$country)
af$us <- as.integer(afc$us)
af$uk <- as.integer(afc$uk)
af$year <- as.numeric(af$year)
tp <- tolower(to_chr(af$type))
fb <- grepl("fight|bomb|pursuit", tp)
if (sum(fb, na.rm = TRUE) > 0) {
  af <- af[fb & !is.na(fb), ]
} else {
  message("No fighter/bomber type match; using all airframes")
}
af <- af[!is.na(af$year) & af$year >= 1918 & af$year <= 1935, ]

lw <- if ("ln_wingload" %in% names(af)) as.numeric(af$ln_wingload) else rep(NA_real_, nrow(af))
if ("wingload" %in% names(af)) {
  alt <- suppressWarnings(log(as.numeric(af$wingload)))
  lw[is.na(lw)] <- alt[is.na(lw)]
}
af$lwl <- lw
ls_ <- if ("ln_maxspeed" %in% names(af)) as.numeric(af$ln_maxspeed) else rep(NA_real_, nrow(af))
if ("maxspeed" %in% names(af)) {
  alt <- suppressWarnings(log(as.numeric(af$maxspeed)))
  ls_[is.na(ls_)] <- alt[is.na(ls_)]
}
af$lms <- ls_
af$lwl[!is.finite(af$lwl)] <- NA
af$lms[!is.finite(af$lms)] <- NA

# Continuous linear spline, knot 1926
af$pre  <- pmin(af$year - 1926, 0)
af$post <- pmax(af$year - 1926, 0)

us_af <- af[af$us == 1, ]
m1 <- lm(lwl ~ pre + post, data = us_af)
m2 <- lm(lms ~ pre + post, data = us_af)

uu <- af[af$us == 1 | af$uk == 1, ]
uu$pre_us  <- uu$pre * uu$us
uu$post_us <- uu$post * uu$us
uu$pre_uk  <- uu$pre * (1 - uu$us)
uu$post_uk <- uu$post * (1 - uu$us)
m3 <- lm(lwl ~ us + pre_uk + post_uk + pre_us + post_us, data = uu)
m4 <- lm(lms ~ us + pre_uk + post_uk + pre_us + post_us, data = uu)
# Note: with US-specific and UK-specific splines, the "x US" relative slope is
# the difference between US and UK slopes. Reparametrize: common spline + spline x US.
m3b <- lm(lwl ~ us + pre + post + pre_us + post_us, data = uu)
m4b <- lm(lms ~ us + pre + post + pre_us + post_us, data = uu)

# ---------- Engines ----------
enc <- country_codes(en$country)
en$us <- as.integer(enc$us)
en$year <- as.numeric(en$year)
en$lhpw <- as.numeric(en$ln_hp_per_lbs)
en$lhpw[!is.finite(en$lhpw)] <- NA
en$lc <- as.numeric(en$liquid_cooled)
en$pre  <- pmin(en$year - 1926, 0)
en$post <- pmax(en$year - 1926, 0)
us_en <- en[en$us == 1 & !is.na(en$year), ]
m5 <- lm(lhpw ~ pre + post + lc, data = us_en)

rob <- function(m) sqrt(diag(sandwich::vcovHC(m, type = "HC1")))
for (m in list(m1, m2, m3b, m4b, m5)) print(lmtest::coeftest(m, vcov = sandwich::vcovHC(m, type = "HC1")))

cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us=%.6f\n", coef(m1)["pre"]))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us=%.6f\n", coef(m1)["post"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us=%.6f\n", coef(m2)["pre"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us=%.6f\n", coef(m2)["post"]))
cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=%.6f\n", coef(m3b)["pre_us"]))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=%.6f\n", coef(m3b)["post_us"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=%.6f\n", coef(m4b)["pre_us"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=%.6f\n", coef(m4b)["post_us"]))
cat(sprintf("RESULT:engine_hp_per_weight_trend_before_1926_us=%.6f\n", coef(m5)["pre"]))
cat(sprintf("RESULT:engine_hp_per_weight_trend_after_1926_us=%.6f\n", coef(m5)["post"]))
cat(sprintf("RESULT:observations_airframe_wingload_us=%d\n", as.integer(nobs(m1))))
cat(sprintf("RESULT:observations_engine_us=%d\n", as.integer(nobs(m5))))
