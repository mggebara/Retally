# Reproduction script for Leeson (2022) Hobo Economicus
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(fixest)
  library(car)
  library(stringr)
  library(sandwich)
  library(lmtest)
})

set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus.script-free/3 replication package/replicate/replicate/data"

friendliness <- read_csv(file.path(base, "friendliness.csv"), show_col_types = FALSE)
metrovisits  <- read_csv(file.path(base, "metrovisitslog.csv"), show_col_types = FALSE)
passersby    <- read_csv(file.path(base, "passersby.csv"), show_col_types = FALSE)
receipts     <- read_csv(file.path(base, "receipts.csv"), show_col_types = FALSE)
service      <- read_csv(file.path(base, "service.csv"), show_col_types = FALSE)
shuttle      <- read_csv(file.path(base, "shuttle.csv"), show_col_types = FALSE)

# Friendliness: average max response per passerby then per station
friendliness <- friendliness %>%
  rowwise() %>%
  mutate(maxresp = max(c_across(passresp1:passresp5), na.rm = TRUE)) %>%
  ungroup()

friendliness_station <- friendliness %>%
  group_by(metro) %>%
  summarise(friendliness = mean(maxresp, na.rm = TRUE), .groups = "drop")

# Parse date in metrovisits
metrovisits <- metrovisits %>%
  mutate(date_parsed = suppressWarnings(mdy(date)))
if (all(is.na(metrovisits$date_parsed))) {
  metrovisits <- metrovisits %>% mutate(date_parsed = suppressWarnings(ymd(date)))
}
metrovisits <- metrovisits %>%
  mutate(month = month(date_parsed), year = year(date_parsed))

# Georgetown gets Foggy Bottom-GWU passersby count
passersby_fb <- passersby %>% filter(str_detect(tolower(metro), "foggy"))

mv <- metrovisits %>%
  left_join(passersby, by = c("metro", "month", "year"))

geo_idx <- which(str_detect(tolower(mv$metro), "georgetown"))
if (length(geo_idx) > 0) {
  for (i in geo_idx) {
    fb <- passersby_fb %>% filter(month == mv$month[i], year == mv$year[i])
    if (nrow(fb) >= 1) mv$passersby[i] <- fb$passersby[1]
  }
}

# Merge friendliness
mv <- mv %>% left_join(friendliness_station, by = "metro")

# Shuttle and service: within 10 min walk
shuttle <- shuttle %>% mutate(shuttle_stop = as.integer(shuttlemin <= 10))
service <- service %>% mutate(homeless_service = as.integer(servicemin <= 10))

mv <- mv %>%
  left_join(shuttle %>% select(metro, shuttle_stop), by = "metro") %>%
  left_join(service %>% select(metro, homeless_service), by = "metro")

# Full sample regression
mv_full <- mv %>% filter(!is.na(panhandlers), !is.na(passersby), !is.na(friendliness),
                         !is.na(shuttle_stop), !is.na(homeless_service))

cat("N full sample:", nrow(mv_full), "\n")
cat("Unique stations full:", length(unique(mv_full$metro)), "\n")

# Use lm with factor(date) so friendliness is not dropped by singleton removal
m1_lm <- lm(panhandlers ~ passersby + friendliness + homeless_service + shuttle_stop + factor(date),
            data = mv_full)
m1_vcov <- vcovCL(m1_lm, cluster = ~metro)
m1_ct <- coeftest(m1_lm, vcov. = m1_vcov)
print(m1_ct[c("passersby","friendliness","homeless_service","shuttle_stop"), ])

# Five-station subsample - include all 5 stations' station-visits regardless of other NAs
five_stations <- c("Farragut North", "Farragut West", "Gallery Place",
                   "McPherson Square", "Metro Center")

mv_five <- mv %>% filter(metro %in% five_stations, !is.na(panhandlers))
cat("N five-station (all visits):", nrow(mv_five), "\n")

# For regression, need the covariates
mv_five_reg <- mv_five %>% filter(!is.na(passersby), !is.na(friendliness),
                                   !is.na(shuttle_stop), !is.na(homeless_service))
cat("N five-station regression:", nrow(mv_five_reg), "\n")

m2_lm <- lm(panhandlers ~ passersby + friendliness + homeless_service + shuttle_stop + factor(date),
            data = mv_five_reg)
m2_vcov <- vcovCL(m2_lm, cluster = ~metro)
m2_ct <- coeftest(m2_lm, vcov. = m2_vcov)
print(m2_ct[intersect(c("passersby","friendliness","homeless_service","shuttle_stop"), rownames(m2_ct)), , drop=FALSE])

# Receipts analysis
receipts <- receipts %>%
  mutate(donations_per_hour = donations / minutes * 60,
         dollars_total = cash + inkind,
         dollars_per_hour = dollars_total / minutes * 60)

rec_five <- receipts %>% filter(str_detect(tolower(metro), "farragut|gallery|mcpherson|metro center"))

rec_don <- rec_five %>% filter(!is.na(donations_per_hour), is.finite(donations_per_hour))
rec_dol <- rec_five %>% filter(!is.na(cash), !is.na(inkind), !is.na(minutes), minutes > 0)
rec_dol <- rec_dol %>% mutate(dollars_per_hour = (cash + inkind) / minutes * 60)

cat("N donations:", nrow(rec_don), "\n")
cat("N dollars:", nrow(rec_dol), "\n")

bf_don <- leveneTest(donations_per_hour ~ factor(metro), data = rec_don, center = median)
bf_dol <- leveneTest(dollars_per_hour ~ factor(metro), data = rec_dol, center = median)

anova_don <- aov(donations_per_hour ~ factor(metro), data = rec_don)
anova_dol <- aov(dollars_per_hour ~ factor(metro), data = rec_dol)

sum_don <- summary(anova_don)[[1]]
sum_dol <- summary(anova_dol)[[1]]

# Extract results
passersby_full <- unname(coef(m1_lm)["passersby"])
passersby_five <- unname(coef(m2_lm)["passersby"])
friendliness_full <- unname(coef(m1_lm)["friendliness"])
shuttle_full <- unname(coef(m1_lm)["shuttle_stop"])
shuttle_five <- unname(coef(m2_lm)["shuttle_stop"])

bf_W_don <- bf_don$`F value`[1]
bf_W_dol <- bf_dol$`F value`[1]
anova_F_don <- sum_don$`F value`[1]
anova_F_dol <- sum_dol$`F value`[1]

cat("DEVIATION: Used lm()+vcovCL instead of feols to prevent fixest from dropping the friendliness covariate as collinear after singleton removal\n")

cat(sprintf("RESULT:passersby_full_sample=%.6f\n", passersby_full))
cat(sprintf("RESULT:passersby_five_station_subsample=%.6f\n", passersby_five))
cat(sprintf("RESULT:friendliness_full_sample=%.6f\n", friendliness_full))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.6f\n", shuttle_full))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.6f\n", shuttle_five))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.6f\n", bf_W_don))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.6f\n", bf_W_dol))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.6f\n", anova_F_don))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.6f\n", anova_F_dol))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", nrow(mv_full)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", nrow(mv_five)))