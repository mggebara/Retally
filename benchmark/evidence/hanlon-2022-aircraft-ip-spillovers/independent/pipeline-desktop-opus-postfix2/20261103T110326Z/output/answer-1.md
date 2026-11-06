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
is_us <- function(x) {
  x <- trimws(tolower(to_chr(x)))
  x %in% c('us', 'usa', 'u.s.', 'u.s.a.', 'united states', 'united states of america', 'america', 'american')
}
is_uk <- function(x) {
  x <- trimws(tolower(to_chr(x)))
  x %in% c('uk', 'u.k.', 'united kingdom', 'britain', 'great britain', 'gb', 'england', 'british')
}
is_fb <- function(x) {
  x <- tolower(to_chr(x))
  grepl('fight|bomb|pursuit', x)
}

spline_vars <- function(d) {
  d$pre26 <- pmin(d$year - 1926, 0)
  d$post26 <- pmax(d$year - 1926, 0)
  d
}

# choose among candidate restriction sets the one matching the paper's count
pick_sample <- function(cands, target) {
  ns <- sapply(cands, function(z) z$n)
  exact <- which(ns == target)
  if (length(exact) > 0) return(exact[1])
  which.min(abs(ns - target))
}

# ---------------- Airframes ----------------
air <- read_dta(air_path)
air <- as.data.frame(air)
air$year <- as.numeric(air$year)
air$ln_wingload <- as.numeric(air$ln_wingload)
air$ln_maxspeed <- as.numeric(air$ln_maxspeed)
air$us <- as.integer(is_us(air$country))
air$uk <- as.integer(is_uk(air$country))
type_chr <- to_chr(air$type)
has_type_info <- any(is_fb(type_chr), na.rm = TRUE)
air$fb <- if (has_type_info) as.integer(is_fb(type_chr)) else 1L

n_loaded_air <- nrow(air)

mk_air <- function(country_flag, type_restrict, year_restrict) {
  d <- air[country_flag == 1, , drop = FALSE]
  steps <- list(country = nrow(d))
  if (type_restrict) { d <- d[d$fb == 1, , drop = FALSE] }
  steps$fighters_bombers <- nrow(d)
  if (year_restrict) { d <- d[!is.na(d$year) & d$year >= 1918 & d$year <= 1935, , drop = FALSE] }
  steps$years_1918_1935 <- nrow(d)
  list(d = d, steps = steps)
}

cands <- list()
opts <- expand.grid(type = c(TRUE, FALSE), yr = c(FALSE, TRUE))
for (i in seq_len(nrow(opts))) {
  s <- mk_air(air$us, opts$type[i], opts$yr[i])
  s$n <- sum(!is.na(s$d$ln_wingload) & !is.na(s$d$year))
  s$type <- opts$type[i]; s$yr <- opts$yr[i]
  cands[[i]] <- s
}
k <- pick_sample(cands, 116)
use_type <- cands[[k]]$type
use_yr <- cands[[k]]$yr
if (!has_type_info) cat('DEVIATION: airframe type variable has no fighter/bomber labels; type restriction not applied\n')
if (cands[[k]]$n != 116) cat(sprintf('DEVIATION: US wing load sample has %d obs vs 116 in paper\n', cands[[k]]$n))

report_air <- function(name, s, y) {
  cat(sprintf('SAMPLE:%s:loaded=%d\n', name, n_loaded_air))
  cat(sprintf('SAMPLE:%s:country=%d\n', name, s$steps$country))
  if (use_type) cat(sprintf('SAMPLE:%s:fighters_bombers=%d\n', name, s$steps$fighters_bombers))
  if (use_yr) cat(sprintf('SAMPLE:%s:years_1918_1935=%d\n', name, s$steps$years_1918_1935))
}

us_s <- mk_air(air$us, use_type, use_yr)
us_d <- spline_vars(us_s$d)
pool_flag <- as.integer(air$us == 1 | air$uk == 1)
pool_s <- mk_air(pool_flag, use_type, use_yr)
pool_d <- spline_vars(pool_s$d)
pool_d$pre26_us <- pool_d$pre26 * pool_d$us
pool_d$post26_us <- pool_d$post26 * pool_d$us

m1 <- feols(ln_wingload ~ pre26 + post26, data = us_d, vcov = 'hetero')
m2 <- feols(ln_maxspeed ~ pre26 + post26, data = us_d, vcov = 'hetero')
m3 <- feols(ln_wingload ~ us + pre26 + post26 + pre26_us + post26_us, data = pool_d, vcov = 'hetero')
m4 <- feols(ln_maxspeed ~ us + pre26 + post26 + pre26_us + post26_us, data = pool_d, vcov = 'hetero')

report_air('t1_c1_us_wingload', us_s); cat(sprintf('SAMPLE:t1_c1_us_wingload:estimation=%d\n', nobs(m1)))
report_air('t1_c2_us_maxspeed', us_s); cat(sprintf('SAMPLE:t1_c2_us_maxspeed:estimation=%d\n', nobs(m2)))
report_air('t1_c3_usuk_wingload', pool_s); cat(sprintf('SAMPLE:t1_c3_usuk_wingload:estimation=%d\n', nobs(m3)))
report_air('t1_c4_usuk_maxspeed', pool_s); cat(sprintf('SAMPLE:t1_c4_usuk_maxspeed:estimation=%d\n', nobs(m4)))

# ---------------- Engines ----------------
eng <- as.data.frame(read_dta(eng_path))
eng$year <- as.numeric(eng$year)
eng$ln_hp_per_lbs <- as.numeric(eng$ln_hp_per_lbs)
eng$liquid_cooled <- as.numeric(eng$liquid_cooled)
n_loaded_eng <- nrow(eng)
eng_us <- eng[is_us(eng$country), , drop = FALSE]
n_us_eng <- nrow(eng_us)
eng_us_yr <- eng_us[!is.na(eng_us$year) & eng_us$year >= 1918 & eng_us$year <= 1935, , drop = FALSE]
n_a <- sum(complete.cases(eng_us[, c('ln_hp_per_lbs', 'year', 'liquid_cooled')]))
n_b <- sum(complete.cases(eng_us_yr[, c('ln_hp_per_lbs', 'year', 'liquid_cooled')]))
use_eng_yr <- (n_b == 85 && n_a != 85) || (abs(n_b - 85) < abs(n_a - 85))
eng_d <- spline_vars(if (use_eng_yr) eng_us_yr else eng_us)
m5 <- feols(ln_hp_per_lbs ~ pre26 + post26 + liquid_cooled, data = eng_d, vcov = 'hetero')
cat(sprintf('SAMPLE:t4_c1_us_engine:loaded=%d\n', n_loaded_eng))
cat(sprintf('SAMPLE:t4_c1_us_engine:country=%d\n', n_us_eng))
if (use_eng_yr) cat(sprintf('SAMPLE:t4_c1_us_engine:years_1918_1935=%d\n', nrow(eng_us_yr)))
cat(sprintf('SAMPLE:t4_c1_us_engine:estimation=%d\n', nobs(m5)))
if (nobs(m5) != 85) cat(sprintf('DEVIATION: US engine sample has %d obs vs 85 in paper\n', nobs(m5)))

out <- function(name, v) cat(sprintf('RESULT:%s=%.6f\n', name, v))
se <- function(m) sqrt(diag(vcov(m)))

out('airframe_wingload_trend_before_1926_us', coef(m1)['pre26'])
out('airframe_wingload_trend_after_1926_us', coef(m1)['post26'])
out('airframe_maxspeed_trend_before_1926_us', coef(m2)['pre26'])
out('airframe_maxspeed_trend_after_1926_us', coef(m2)['post26'])
out('airframe_wingload_trend_before_1926_us_vs_uk', coef(m3)['pre26_us'])
out('airframe_wingload_trend_after_1926_us_vs_uk', coef(m3)['post26_us'])
out('airframe_maxspeed_trend_before_1926_us_vs_uk', coef(m4)['pre26_us'])
out('airframe_maxspeed_trend_after_1926_us_vs_uk', coef(m4)['post26_us'])
out('engine_hp_per_weight_trend_before_1926_us', coef(m5)['pre26'])
out('engine_hp_per_weight_trend_after_1926_us', coef(m5)['post26'])
out('airframe_wingload_trend_before_1926_us_se', se(m1)['pre26'])
out('airframe_wingload_trend_after_1926_us_se', se(m1)['post26'])
out('engine_hp_per_weight_trend_before_1926_us_se', se(m5)['pre26'])
out('engine_hp_per_weight_trend_after_1926_us_se', se(m5)['post26'])
cat(sprintf('RESULT:observations_airframe_wingload_us=%d\n', nobs(m1)))
cat(sprintf('RESULT:observations_engine_us=%d\n', nobs(m5)))
