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
num <- function(x) as.numeric(haven::zap_labels(x))

is_us <- function(x) {
  s <- trimws(tolower(x))
  s %in% c("us", "usa", "u.s.", "u.s.a.", "united states", "united states of america", "america", "american") |
    grepl("^united states", s)
}
is_uk <- function(x) {
  s <- trimws(tolower(x))
  s %in% c("uk", "u.k.", "united kingdom", "britain", "great britain", "gb", "england", "british") |
    grepl("kingdom|britain|british", s)
}

af$country_c <- to_chr(af$country)
en$country_c <- to_chr(en$country)
cat("Airframe countries:\n"); print(table(af$country_c, useNA = "ifany"))
cat("Engine countries:\n"); print(table(en$country_c, useNA = "ifany"))

af$year <- num(af$year)
en$year <- num(en$year)

# Fighter / bomber restriction
if ("type" %in% names(af)) {
  af$type_c <- to_chr(af$type)
  cat("Airframe types:\n"); print(table(af$type_c, useNA = "ifany"))
  keep <- grepl("fight|bomb|pursuit", tolower(af$type_c))
  if (sum(keep, na.rm = TRUE) > 0) {
    af <- af[keep %in% TRUE, ]
  } else {
    cat("Type filter matched nothing; keeping all airframes\n")
  }
}

af <- af[!is.na(af$year) & af$year >= 1918 & af$year <= 1935, ]
en <- en[!is.na(en$year) & en$year >= 1918 & en$year <= 1935, ]

spline_vars <- function(d) {
  d$pre <- pmin(d$year - 1926, 0)
  d$post <- pmax(d$year - 1926, 0)
  d
}
af <- spline_vars(af)
en <- spline_vars(en)

af$ln_wingload <- num(af$ln_wingload)
af$ln_maxspeed <- num(af$ln_maxspeed)
if (all(is.na(af$ln_wingload)) && "wingload" %in% names(af)) af$ln_wingload <- log(num(af$wingload))
if (all(is.na(af$ln_maxspeed)) && "maxspeed" %in% names(af)) af$ln_maxspeed <- log(num(af$maxspeed))

af$US <- as.numeric(is_us(af$country_c))
af$UK <- as.numeric(is_uk(af$country_c))
en$US <- as.numeric(is_us(en$country_c))

us_af <- af[af$US == 1, ]
usuk_af <- af[af$US == 1 | af$UK == 1, ]

rob <- function(m) coeftest(m, vcov = vcovHC(m, type = "HC1"))

# Table 1 col 1-2: US only
d1 <- us_af[is.finite(us_af$ln_wingload), ]
m1 <- lm(ln_wingload ~ pre + post, data = d1)
print(rob(m1))
d2 <- us_af[is.finite(us_af$ln_maxspeed), ]
m2 <- lm(ln_maxspeed ~ pre + post, data = d2)
print(rob(m2))

# Table 1 col 3-4: US vs UK
d3 <- usuk_af[is.finite(usuk_af$ln_wingload), ]
m3 <- lm(ln_wingload ~ US + pre + post + I(pre * US) + I(post * US), data = d3)
print(rob(m3))
d4 <- usuk_af[is.finite(usuk_af$ln_maxspeed), ]
m4 <- lm(ln_maxspeed ~ US + pre + post + I(pre * US) + I(post * US), data = d4)
print(rob(m4))

# Table 4 col 1: US engines
en$ln_hp_per_lbs <- num(en$ln_hp_per_lbs)
en$liquid_cooled <- num(en$liquid_cooled)
d5 <- en[en$US == 1 & is.finite(en$ln_hp_per_lbs), ]
if (length(unique(na.omit(d5$liquid_cooled))) > 1) {
  m5 <- lm(ln_hp_per_lbs ~ pre + post + liquid_cooled, data = d5)
} else {
  m5 <- lm(ln_hp_per_lbs ~ pre + post, data = d5)
}
print(rob(m5))

g <- function(m, v) unname(coef(m)[v])

cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us=%.6f\n", g(m1, "pre")))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us=%.6f\n", g(m1, "post")))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us=%.6f\n", g(m2, "pre")))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us=%.6f\n", g(m2, "post")))
cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=%.6f\n", g(m3, "I(pre * US)")))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=%.6f\n", g(m3, "I(post * US)")))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=%.6f\n", g(m4, "I(pre * US)")))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=%.6f\n", g(m4, "I(post * US)")))
cat(sprintf("RESULT:engine_hp_per_weight_trend_before_1926_us=%.6f\n", g(m5, "pre")))
cat(sprintf("RESULT:engine_hp_per_weight_trend_after_1926_us=%.6f\n", g(m5, "post")))
cat(sprintf("RESULT:observations_airframe_wingload_us=%d\n", nobs(m1)))
cat(sprintf("RESULT:observations_engine_us=%d\n", nobs(m5)))