suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base <- "<repo>/.cache/datasets/hanlon_2022_aircraft_ip_spillovers.script-free"
af_path <- file.path(base, "3 replication files/data/dta/airframe_data.dta")
en_path <- file.path(base, "3 replication files/data/dta/engine_data.dta")

air <- haven::read_dta(af_path)
eng <- haven::read_dta(en_path)

to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) {
    as.character(haven::as_factor(x, levels = "labels"))
  } else {
    as.character(x)
  }
}

classify_country <- function(x) {
  s <- tolower(trimws(to_chr(x)))
  out <- rep(NA_character_, length(s))
  out[grepl("^us$|^u\\.s\\.?$|^usa$|united states|america|^u\\.s\\.a\\.?$", s)] <- "US"
  out[grepl("^uk$|^u\\.k\\.?$|united kingdom|brit|^gb$|england", s)] <- "UK"
  out
}

cat("Airframe country values:\n"); print(table(to_chr(air$country), useNA = "ifany"))
cat("Airframe type values:\n"); print(table(to_chr(air$type), useNA = "ifany"))
cat("Engine country values:\n"); print(table(to_chr(eng$country), useNA = "ifany"))

air <- air %>%
  mutate(ctry = classify_country(country),
         type_chr = tolower(to_chr(type)),
         year = as.numeric(year))

# Keep fighters and bombers (pursuit = fighter in US nomenclature)
fb <- grepl("fight|bomb|pursuit", air$type_chr)
if (sum(fb, na.rm = TRUE) > 0) {
  air <- air[fb & !is.na(fb), ]
} else {
  cat("Note: could not identify fighter/bomber types; using all airframes\n")
}

air <- air %>% filter(!is.na(year), year >= 1918, year <= 1935)

knot <- 1926
mk_spline <- function(df) {
  df$s_pre <- pmin(df$year, knot)
  df$s_post <- pmax(df$year - knot, 0)
  df
}
air <- mk_spline(air)

# ln outcomes (construct if missing)
if (!"ln_wingload" %in% names(air) || all(is.na(air$ln_wingload))) {
  air$ln_wingload <- log(air$wingload)
}
if (!"ln_maxspeed" %in% names(air) || all(is.na(air$ln_maxspeed))) {
  air$ln_maxspeed <- log(air$maxspeed)
}
air$ln_wingload[!is.finite(air$ln_wingload)] <- NA
air$ln_maxspeed[!is.finite(air$ln_maxspeed)] <- NA

us_air <- air %>% filter(ctry == "US")
usuk_air <- air %>% filter(ctry %in% c("US", "UK")) %>% mutate(us = as.numeric(ctry == "US"))

# Equation (4): US only
m1 <- feols(ln_wingload ~ s_pre + s_post, data = us_air %>% filter(!is.na(ln_wingload)), vcov = "hetero")
m2 <- feols(ln_maxspeed ~ s_pre + s_post, data = us_air %>% filter(!is.na(ln_maxspeed)), vcov = "hetero")
print(summary(m1)); print(summary(m2))

# Equation (5): US vs UK, US-interacted spline gives US slope relative to UK
usuk_air <- usuk_air %>% mutate(us_pre = us * s_pre, us_post = us * s_post)
m3 <- feols(ln_wingload ~ us + s_pre + s_post + us_pre + us_post,
            data = usuk_air %>% filter(!is.na(ln_wingload)), vcov = "hetero")
m4 <- feols(ln_maxspeed ~ us + s_pre + s_post + us_pre + us_post,
            data = usuk_air %>% filter(!is.na(ln_maxspeed)), vcov = "hetero")
print(summary(m3)); print(summary(m4))

# Engines: US only
eng <- eng %>%
  mutate(ctry = classify_country(country),
         year = as.numeric(year),
         liquid_cooled = as.numeric(liquid_cooled))
eng <- mk_spline(eng)
us_eng <- eng %>% filter(ctry == "US", !is.na(ln_hp_per_lbs), is.finite(ln_hp_per_lbs), !is.na(year))
m5 <- feols(ln_hp_per_lbs ~ s_pre + s_post + liquid_cooled, data = us_eng, vcov = "hetero")
print(summary(m5))

fmt <- function(x) formatC(as.numeric(x), digits = 6, format = "f")

cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us=%s\n", fmt(coef(m1)["s_pre"])))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us=%s\n", fmt(coef(m1)["s_post"])))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us=%s\n", fmt(coef(m2)["s_pre"])))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us=%s\n", fmt(coef(m2)["s_post"])))
cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=%s\n", fmt(coef(m3)["us_pre"])))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=%s\n", fmt(coef(m3)["us_post"])))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=%s\n", fmt(coef(m4)["us_pre"])))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=%s\n", fmt(coef(m4)["us_post"])))
cat(sprintf("RESULT:engine_hp_per_weight_trend_before_1926_us=%s\n", fmt(coef(m5)["s_pre"])))
cat(sprintf("RESULT:engine_hp_per_weight_trend_after_1926_us=%s\n", fmt(coef(m5)["s_post"])))
cat(sprintf("RESULT:observations_airframe_wingload_us=%d\n", as.integer(nobs(m1))))
cat(sprintf("RESULT:observations_engine_us=%d\n", as.integer(nobs(m5))))