# Reproduction script for Leeson (2022) Hobo Economicus
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(lubridate)
  library(fixest)
  library(car)
  library(stringr)
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
# Merge passersby by metro, month, year
# Handle Georgetown
passersby_fb <- passersby %>% filter(str_detect(tolower(metro), "foggy"))

mv <- metrovisits %>%
  left_join(passersby, by = c("metro", "month", "year"))

# For Georgetown rows missing passersby, assign Foggy Bottom's
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

m1 <- feols(panhandlers ~ passersby + friendliness + homeless_service + shuttle_stop | date,
            data = mv_full, cluster = ~metro)
print(summary(m1))

# Five-station subsample
five_stations <- c("Farragut North", "Farragut West", "Gallery Pl-Chinatown",
                   "McPherson Square", "Metro Center")

# Try to match station names
unique_metros <- unique(mv$metro)
cat("Unique metros:\n"); print(unique_metros)

mv_five <- mv_full %>% filter(metro %in% five_stations)

# If naming differs, try fuzzy match
if (nrow(mv_five) < 50) {
  pattern <- "farragut|gallery|mcpherson|metro center"
  mv_five <- mv_full %>% filter(str_detect(tolower(metro), pattern))
}

cat("N five-station:", nrow(mv_five), "\n")

m2 <- feols(panhandlers ~ passersby + friendliness + homeless_service + shuttle_stop | date,
            data = mv_five, cluster = ~metro)
print(summary(m2))

# Receipts analysis
receipts <- receipts %>%
  mutate(donations_per_hour = donations / minutes * 60,
         dollars_total = cash + inkind,
         dollars_per_hour = dollars_total / minutes * 60)

# Filter to five subsample stations
rec_five <- receipts %>% filter(str_detect(tolower(metro), "farragut|gallery|mcpherson|metro center"))

rec_don <- rec_five %>% filter(!is.na(donations_per_hour), is.finite(donations_per_hour))
rec_dol <- rec_five %>% filter(!is.na(dollars_per_hour), is.finite(dollars_per_hour), dollars_total > 0 | !is.na(cash))

# For dollars sample: panhandlers whose dollar receipts were counted
# Likely those where cash is observed (not NA)
rec_dol <- rec_five %>% filter(!is.na(cash), !is.na(inkind), !is.na(minutes), minutes > 0)
rec_dol <- rec_dol %>% mutate(dollars_per_hour = (cash + inkind) / minutes * 60)

cat("N donations:", nrow(rec_don), "\n")
cat("N dollars:", nrow(rec_dol), "\n")

# Brown-Forsythe test (Levene with median)
bf_don <- leveneTest(donations_per_hour ~ factor(metro), data = rec_don, center = median)
bf_dol <- leveneTest(dollars_per_hour ~ factor(metro), data = rec_dol, center = median)

print(bf_don)
print(bf_dol)

# ANOVA
anova_don <- aov(donations_per_hour ~ factor(metro), data = rec_don)
anova_dol <- aov(dollars_per_hour ~ factor(metro), data = rec_dol)

sum_don <- summary(anova_don)[[1]]
sum_dol <- summary(anova_dol)[[1]]
print(sum_don)
print(sum_dol)

# Extract results
passersby_full <- unname(coef(m1)["passersby"])
passersby_five <- unname(coef(m2)["passersby"])
friendliness_full <- unname(coef(m1)["friendliness"])
shuttle_full <- unname(coef(m1)["shuttle_stop"])
shuttle_five <- unname(coef(m2)["shuttle_stop"])

bf_W_don <- bf_don$`F value`[1]
bf_W_dol <- bf_dol$`F value`[1]
anova_F_don <- sum_don$`F value`[1]
anova_F_dol <- sum_dol$`F value`[1]

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