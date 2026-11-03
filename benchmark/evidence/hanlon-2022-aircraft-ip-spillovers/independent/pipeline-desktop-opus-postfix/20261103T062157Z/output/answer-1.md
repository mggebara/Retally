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
  trimws(as.character(x))
}
is_us <- function(x) {
  s <- tolower(to_chr(x))
  s %in% c("us", "usa", "u.s.", "u.s.a.", "united states", "united states of america", "america", "unitedstates")
}
is_uk <- function(x) {
  s <- tolower(to_chr(x))
  s %in% c("uk", "u.k.", "united kingdom", "britain", "great britain", "england", "gb", "unitedkingdom")
}
is_fb <- function(x) {
  s <- tolower(to_chr(x))
  grepl("fight|bomb|pursuit|attack", s)
}
num <- function(x) as.numeric(haven::zap_labels(x))

add_spline <- function(d) {
  d$year <- num(d$year)
  d$pre  <- pmin(d$year - 1926, 0)
  d$post <- pmax(d$year - 1926, 0)
  d
}

# ---------------- Airframes ----------------
af <- haven::read_dta(af_path)
af <- as.data.frame(af)
af$year <- num(af$year)
if (!"ln_wingload" %in% names(af) || all(is.na(af$ln_wingload))) af$ln_wingload <- log(num(af$wingload))
if (!"ln_maxspeed" %in% names(af) || all(is.na(af$ln_maxspeed))) af$ln_maxspeed <- log(num(af$maxspeed))
af$ln_wingload <- num(af$ln_wingload)
af$ln_maxspeed <- num(af$ln_maxspeed)
af$us <- as.integer(is_us(af$country))
af$uk <- as.integer(is_uk(af$country))
af$fb <- is_fb(af$type)
# if type is not informative (e.g. data already restricted), treat all as fighters/bombers
type_informative <- any(af$fb) && !all(af$fb)
if (!any(af$fb)) af$fb <- TRUE
af <- add_spline(af)

build_af <- function(d, cond_country, outcome, use_years) {
  steps <- list(loaded = nrow(d))
  d <- d[cond_country(d), , drop = FALSE]; steps$country <- nrow(d)
  d <- d[d$fb, , drop = FALSE]; steps$fighters_bombers <- nrow(d)
  if (use_years) { d <- d[!is.na(d$year) & d$year >= 1918 & d$year <= 1935, , drop = FALSE]; steps$years_1918_1935 <- nrow(d) }
  d <- d[!is.na(d[[outcome]]) & is.finite(d[[outcome]]) & !is.na(d$year), , drop = FALSE]; steps$nonmissing_outcome <- nrow(d)
  list(d = d, steps = steps)
}

us_cond <- function(d) d$us == 1
usuk_cond <- function(d) d$us == 1 | d$uk == 1

# choose whether to apply 1918-1935 window by matching the stated N = 116
cand_y <- build_af(af, us_cond, "ln_wingload", TRUE)
cand_n <- build_af(af, us_cond, "ln_wingload", FALSE)
use_years <- TRUE
if (nrow(cand_y$d) != 116 && nrow(cand_n$d) == 116) use_years <- FALSE
if (nrow(cand_y$d) != 116 && nrow(cand_n$d) != 116) {
  cat(sprintf("DEVIATION: US wing load sample is %d (with 1918-1935 window) / %d (without); paper states 116\n",
              nrow(cand_y$d), nrow(cand_n$d)))
}
if (!type_informative) cat("DEVIATION: type variable does not distinguish fighters/bombers; assuming file already restricted\n")

print_steps <- function(name, steps, model) {
  for (s in names(steps)) cat(sprintf("SAMPLE:%s:%s=%d\n", name, s, steps[[s]]))
  cat(sprintf("SAMPLE:%s:estimation=%d\n", name, nobs(model)))
}

# Equation (4): US only
s1 <- build_af(af, us_cond, "ln_wingload", use_years)
m1 <- feols(ln_wingload ~ pre + post, data = s1$d, vcov = "hetero")
print_steps("t1_c1_us_wingload", s1$steps, m1)

s2 <- build_af(af, us_cond, "ln_maxspeed", use_years)
m2 <- feols(ln_maxspeed ~ pre + post, data = s2$d, vcov = "hetero")
print_steps("t1_c2_us_maxspeed", s2$steps, m2)

# Equation (5): US vs UK
s3 <- build_af(af, usuk_cond, "ln_wingload", use_years)
s3$d$us_pre <- s3$d$us * s3$d$pre; s3$d$us_post <- s3$d$us * s3$d$post
m3 <- feols(ln_wingload ~ us + pre + post + us_pre + us_post, data = s3$d, vcov = "hetero")
print_steps("t1_c3_usuk_wingload", s3$steps, m3)

s4 <- build_af(af, usuk_cond, "ln_maxspeed", use_years)
s4$d$us_pre <- s4$d$us * s4$d$pre; s4$d$us_post <- s4$d$us * s4$d$post
m4 <- feols(ln_maxspeed ~ us + pre + post + us_pre + us_post, data = s4$d, vcov = "hetero")
print_steps("t1_c4_usuk_maxspeed", s4$steps, m4)

# ---------------- Engines ----------------
en <- as.data.frame(haven::read_dta(en_path))
en_steps <- list(loaded = nrow(en))
en$us <- as.integer(is_us(en$country))
en <- en[en$us == 1, , drop = FALSE]; en_steps$country_us <- nrow(en)
en <- add_spline(en)
en$ln_hp_per_lbs <- num(en$ln_hp_per_lbs)
en$liquid_cooled <- num(en$liquid_cooled)
en_y <- en[!is.na(en$year) & en$year >= 1918 & en$year <= 1935, , drop = FALSE]
ok <- function(d) d[!is.na(d$ln_hp_per_lbs) & is.finite(d$ln_hp_per_lbs) & !is.na(d$liquid_cooled), , drop = FALSE]
use_years_en <- TRUE
if (nrow(ok(en_y)) != 85 && nrow(ok(en)) == 85) use_years_en <- FALSE
if (nrow(ok(en_y)) != 85 && nrow(ok(en)) != 85) {
  cat(sprintf("DEVIATION: US engine sample is %d (with 1918-1935 window) / %d (without); paper states 85\n",
              nrow(ok(en_y)), nrow(ok(en))))
}
if (use_years_en) { en <- en_y; en_steps$years_1918_1935 <- nrow(en) }
en <- ok(en); en_steps$nonmissing_outcome <- nrow(en)
m5 <- feols(ln_hp_per_lbs ~ pre + post + liquid_cooled, data = en, vcov = "hetero")
print_steps("t4_c1_us_engine_hp_weight", en_steps, m5)

# ---------------- Results ----------------
g <- function(m, v) unname(coef(m)[v])
se <- function(m, v) unname(sqrt(diag(vcov(m)))[v])
out <- list(
  airframe_wingload_trend_before_1926_us = g(m1, "pre"),
  airframe_wingload_trend_after_1926_us = g(m1, "post"),
  airframe_maxspeed_trend_before_1926_us = g(m2, "pre"),
  airframe_maxspeed_trend_after_1926_us = g(m2, "post"),
  airframe_wingload_trend_before_1926_us_vs_uk = g(m3, "us_pre"),
  airframe_wingload_trend_after_1926_us_vs_uk = g(m3, "us_post"),
  airframe_maxspeed_trend_before_1926_us_vs_uk = g(m4, "us_pre"),
  airframe_maxspeed_trend_after_1926_us_vs_uk = g(m4, "us_post"),
  engine_hp_per_weight_trend_before_1926_us = g(m5, "pre"),
  engine_hp_per_weight_trend_after_1926_us = g(m5, "post"),
  observations_airframe_wingload_us = nobs(m1),
  observations_engine_us = nobs(m5)
)
ses <- list(
  airframe_wingload_trend_before_1926_us_se = se(m1, "pre"),
  airframe_wingload_trend_after_1926_us_se = se(m1, "post"),
  airframe_maxspeed_trend_before_1926_us_se = se(m2, "pre"),
  airframe_maxspeed_trend_after_1926_us_se = se(m2, "post"),
  airframe_wingload_trend_before_1926_us_vs_uk_se = se(m3, "us_pre"),
  airframe_wingload_trend_after_1926_us_vs_uk_se = se(m3, "us_post"),
  airframe_maxspeed_trend_before_1926_us_vs_uk_se = se(m4, "us_pre"),
  airframe_maxspeed_trend_after_1926_us_vs_uk_se = se(m4, "us_post"),
  engine_hp_per_weight_trend_before_1926_us_se = se(m5, "pre"),
  engine_hp_per_weight_trend_after_1926_us_se = se(m5, "post")
)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
for (n in names(ses)) cat(sprintf("RESULT:%s=%.6f\n", n, ses[[n]]))
