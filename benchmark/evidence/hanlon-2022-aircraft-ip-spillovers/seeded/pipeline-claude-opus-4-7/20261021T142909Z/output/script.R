suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(estimatr)
})

set.seed(42)

base <- "/Users/matthew/dev/Retally/.cache/datasets/hanlon_2022_aircraft_ip_spillovers"

# Load airframe data
af <- read_dta(file.path(base, "3 replication files/data/dta/airframe_data.dta"))
af <- af %>%
  filter(country %in% c("United States", "United Kingdom"),
         type %in% c("fighter", "bomber"))

af <- af %>%
  mutate(US = as.integer(country == "United States"),
         pre1926 = pmin(year, 1926),
         post1926 = pmax(year, 1926),
         pre1926_US = US * pre1926,
         post1926_US = US * post1926)

# Column 1: US only, wing load
m1 <- lm_robust(ln_wingload ~ pre1926_US + post1926_US,
                data = filter(af, US == 1), se_type = "HC1")
b_wl_pre_us <- coef(m1)["pre1926_US"]
b_wl_post_us <- coef(m1)["post1926_US"]
n_wl_us <- m1$nobs

# Column 2: US only, max speed
m2 <- lm_robust(ln_maxspeed ~ pre1926_US + post1926_US,
                data = filter(af, US == 1), se_type = "HC1")
b_ms_pre_us <- coef(m2)["pre1926_US"]
b_ms_post_us <- coef(m2)["post1926_US"]

# Column 3: US & UK, wing load
m3 <- lm_robust(ln_wingload ~ pre1926_US + post1926_US + pre1926 + post1926 + US,
                data = af, se_type = "HC1")
b_wl_pre_usuk <- coef(m3)["pre1926_US"]
b_wl_post_usuk <- coef(m3)["post1926_US"]

# Column 4: US & UK, max speed
m4 <- lm_robust(ln_maxspeed ~ pre1926_US + post1926_US + pre1926 + post1926 + US,
                data = af, se_type = "HC1")
b_ms_pre_usuk <- coef(m4)["pre1926_US"]
b_ms_post_usuk <- coef(m4)["post1926_US"]

# Engine data
en <- read_dta(file.path(base, "3 replication files/data/dta/engine_data.dta"))
en <- en %>%
  filter(country %in% c("United States", "United Kingdom")) %>%
  mutate(US = as.integer(country == "United States"),
         pre1926 = pmin(year, 1926),
         post1926 = pmax(year, 1926),
         pre1926_US = US * pre1926,
         post1926_US = US * post1926)

# Table 4, Column 1: US only, hp per lbs
me1 <- lm_robust(ln_hp_per_lbs ~ pre1926_US + post1926_US + liquid_cooled,
                 data = filter(en, US == 1), se_type = "HC1")
b_e_pre_us <- coef(me1)["pre1926_US"]
b_e_post_us <- coef(me1)["post1926_US"]
n_e_us <- me1$nobs

cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us=%.6f\n", b_wl_pre_us))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us=%.6f\n", b_wl_post_us))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us=%.6f\n", b_ms_pre_us))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us=%.6f\n", b_ms_post_us))
cat(sprintf("RESULT:airframe_wingload_trend_before_1926_us_vs_uk=%.6f\n", b_wl_pre_usuk))
cat(sprintf("RESULT:airframe_wingload_trend_after_1926_us_vs_uk=%.6f\n", b_wl_post_usuk))
cat(sprintf("RESULT:airframe_maxspeed_trend_before_1926_us_vs_uk=%.6f\n", b_ms_pre_usuk))
cat(sprintf("RESULT:airframe_maxspeed_trend_after_1926_us_vs_uk=%.6f\n", b_ms_post_usuk))
cat(sprintf("RESULT:engine_hp_per_weight_trend_before_1926_us=%.6f\n", b_e_pre_us))
cat(sprintf("RESULT:engine_hp_per_weight_trend_after_1926_us=%.6f\n", b_e_post_us))
cat(sprintf("RESULT:observations_airframe_wingload_us=%d\n", as.integer(n_wl_us)))
cat(sprintf("RESULT:observations_engine_us=%d\n", as.integer(n_e_us)))