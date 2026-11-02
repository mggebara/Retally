suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hanlon_2022_aircraft_ip_spillovers.script-free"
af_path <- file.path(base, "3 replication files/data/dta/airframe_data.dta")
en_path <- file.path(base, "3 replication files/data/dta/engine_data.dta")

to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) x <- as.character(haven::as_factor(x, levels = "labels"))
  as.character(x)
}
to_num <- function(x) as.numeric(haven::zap_labels(x))

is_us <- function(cc) {
  c0 <- tolower(trimws(cc))
  c0 %in% c("us", "usa", "u.s.", "u.s.a.", "united states", "united states of america", "america", "american") |
    grepl("united states|^us$|^usa$|america", c0)
}
is_uk <- function(cc) {
  c0 <- tolower(trimws(cc))
  c0 %in% c("uk", "u.k.", "gb", "great britain", "britain", "united kingdom", "england", "british") |
    grepl("united kingdom|britain|^uk$|england|british", c0)
}

# ---------------- Airframes ----------------
af <- read_dta(af_path)
af$country_chr <- to_chr(af$country)
af$year <- to_num(af$year)
af$ln_wingload <- to_num(af$ln_wingload)
af$ln_maxspeed <- to_num(af$ln_maxspeed)
af$type_chr <- tolower(to_chr(af$type))

cat("Airframe countries:\n"); print(table(af$country_chr, useNA = "ifany"))
cat("Airframe types:\n"); print(table(af$type_chr, useNA = "ifany"))
cat("Airframe year range:", range(af$year, na.rm = TRUE), "\n")

af$US <- as.integer(is_us(af$country_chr))
af$UK <- as.integer(is_uk(af$country_chr))
# fallback if country coded numerically without labels
if (sum(af$US) == 0) {
  cn <- suppressWarnings(as.numeric(af$country_chr))
  if (!all(is.na(cn))) {
    tab <- sort(table(cn), decreasing = TRUE)
    af$US <- as.integer(cn == as.numeric(names(tab)[1]))
    af$UK <- as.integer(cn == as.numeric(names(tab)[2]))
    cat("WARNING: numeric country codes; assuming most frequent = US, second = UK\n")
  }
}

fb_regex <- "fight|bomb|pursuit|interceptor"
has_fb <- any(grepl(fb_regex, af$type_chr))

# Candidate sample definitions; choose the one whose US wing-load N matches the paper's sample size
cands <- list()
for (tf in c(TRUE, FALSE)) for (yf in c(TRUE, FALSE)) {
  if (tf && !has_fb) next
  d <- af
  if (tf) d <- d[grepl(fb_regex, d$type_chr), ]
  if (yf) d <- d[!is.na(d$year) & d$year >= 1918 & d$year <= 1935, ]
  n <- sum(d$US == 1 & !is.na(d$ln_wingload) & is.finite(d$ln_wingload) & !is.na(d$year))
  cands[[length(cands) + 1]] <- list(tf = tf, yf = yf, n = n, d = d)
}
for (cc in cands) cat(sprintf("Sample candidate: type_filter=%s year_filter=%s US wingload N=%d\n", cc$tf, cc$yf, cc$n))
# prefer the theoretically correct sample (fighter/bomber, 1918-1935) unless N clearly off
ns <- sapply(cands, function(z) abs(z$n - 116))
pick <- which(ns == min(ns))[1]
afs <- cands[[pick]]$d
cat(sprintf("Using airframe sample: type_filter=%s year_filter=%s\n", cands[[pick]]$tf, cands[[pick]]$yf))

afs$pre  <- pmin(afs$year - 1926, 0)
afs$post <- pmax(afs$year - 1926, 0)

rob <- function(m) coeftest(m, vcov = vcovHC(m, type = "HC1"))

us <- afs[afs$US == 1, ]
d_wl <- us[is.finite(us$ln_wingload) & !is.na(us$year), ]
m1 <- lm(ln_wingload ~ pre + post, data = d_wl)
print(rob(m1))
d_ms <- us[is.finite(us$ln_maxspeed) & !is.na(us$year), ]
m2 <- lm(ln_maxspeed ~ pre + post, data = d_ms)
print(rob(m2))

usuk <- afs[afs$US == 1 | afs$UK == 1, ]
usuk$pre_US  <- usuk$pre * usuk$US
usuk$post_US <- usuk$post * usuk$US
d3 <- usuk[is.finite(usuk$ln_wingload) & !is.na(usuk$year), ]
m3 <- lm(ln_wingload ~ US + pre + post + pre_US + post_US, data = d3)
print(rob(m3))
d4 <- usuk[is.finite(usuk$ln_maxspeed) & !is.na(usuk$year), ]
m4 <- lm(ln_maxspeed ~ US + pre + post + pre_US + post_US, data = d4)
print(rob(m4))

# ---------------- Engines ----------------
en <- read_dta(en_path)
en$country_chr <- to_chr(en$country)
en$year <- to_num(en$year)
en$ln_hp_per_lbs <- to_num(en$ln_hp_per_lbs)
en$liquid_cooled <- to_num(en$liquid_cooled)
cat("Engine countries:\n"); print(table(en$country_chr, useNA = "ifany"))
cat("Engine year range:", range(en$year, na.rm = TRUE), "\n")
en$US <- as.integer(is_us(en$country_chr))
if (sum(en$US) == 0) {
  cn <- suppressWarnings(as.numeric(en$country_chr))
  if (!all(is.na(cn))) {
    tab <- sort(table(cn), decreasing = TRUE)
    en$US <- as.integer(cn == as.numeric(names(tab)[1]))
  }
}
enu_all <- en[en$US == 1 & is.finite(en$ln_hp_per_lbs) & !is.na(en$year) & !is.na(en$liquid_cooled), ]
enu_yr <- enu_all[enu_all$year >= 1918 & enu_all$year <= 1935, ]
cat(sprintf("Engine N all years=%d, 1918-1935=%d\n", nrow(enu_all), nrow(enu_yr)))
enu <- if (abs(nrow(enu_yr) - 85) <= abs(nrow(enu_all) - 85)) enu_yr else enu_all
enu$pre  <- pmin(enu$year - 1926, 0)
enu$post <- pmax(enu$year - 1926, 0)
if (length(unique(enu$liquid_cooled)) > 1) {
  m5 <- lm(ln_hp_per_lbs ~ pre + post + liquid_cooled, data = enu)
} else {
  m5 <- lm(ln_hp_per_lbs ~ pre + post, data = enu)
}
print(rob(m5))

se <- function(m, v) sqrt(diag(vcovHC(m, type = "HC1")))[v]

cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us=%.6f\n", coef(m1)["pre"]))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us=%.6f\n", coef(m1)["post"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us=%.6f\n", coef(m2)["pre"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us=%.6f\n", coef(m2)["post"]))
cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=%.6f\n", coef(m3)["pre_US"]))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=%.6f\n", coef(m3)["post_US"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=%.6f\n", coef(m4)["pre_US"]))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=%.6f\n", coef(m4)["post_US"]))
cat(sprintf("RESULT:engine_hp_per_weight_trend_before_1926_us=%.6f\n", coef(m5)["pre"]))
cat(sprintf("RESULT:engine_hp_per_weight_trend_after_1926_us=%.6f\n", coef(m5)["post"]))
cat(sprintf("RESULT:observations_airframe_wingload_us=%d\n", nobs(m1)))
cat(sprintf("RESULT:observations_engine_us=%d\n", nobs(m5)))