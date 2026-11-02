#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(fixest)
  library(car)
  library(lubridate)
})

set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus.script-free/3 replication package/replicate/replicate/data"

friendliness <- read_csv(file.path(base, "friendliness.csv"), show_col_types = FALSE)
metrovisits  <- read_csv(file.path(base, "metrovisitslog.csv"), show_col_types = FALSE)
passersby    <- read_csv(file.path(base, "passersby.csv"), show_col_types = FALSE)
receipts     <- read_csv(file.path(base, "receipts.csv"), show_col_types = FALSE)
service      <- read_csv(file.path(base, "service.csv"), show_col_types = FALSE)
shuttle      <- read_csv(file.path(base, "shuttle.csv"), show_col_types = FALSE)

# Friendliness: average per passerby across 3 responses (passresp1..3?), then by station
# The description says 3 train arrivals. Use passresp1..passresp3 if present; else all.
fr_cols <- grep("^passresp", names(friendliness), value = TRUE)
friendliness$friendliness_ind <- rowMeans(friendliness[, fr_cols], na.rm = TRUE)
# Averaged by station
friend_station <- friendliness %>%
  group_by(metro) %>%
  summarise(friendliness = mean(friendliness_ind, na.rm = TRUE), .groups = "drop")

# Passersby: parse date in metrovisits to month/year
metrovisits <- metrovisits %>%
  mutate(date_parsed = suppressWarnings(mdy(date)))
# try other formats
if (all(is.na(metrovisits$date_parsed))) {
  metrovisits <- metrovisits %>% mutate(date_parsed = suppressWarnings(ymd(date)))
}
metrovisits <- metrovisits %>%
  mutate(month = month(date_parsed), year = year(date_parsed))

# Georgetown gets Foggy Bottom-GWU's count
# Merge passersby by metro, month, year
# First handle Georgetown remapping for passersby lookup
mv <- metrovisits %>%
  mutate(metro_pass = ifelse(grepl("Georgetown", metro, ignore.case = TRUE),
                              "Foggy Bottom-GWU", metro))

# Try merge - need to match exact names in passersby
mv2 <- mv %>%
  left_join(passersby, by = c("metro_pass" = "metro", "month" = "month", "year" = "year"))

# Shuttle and service: indicator if within 10 minutes
shuttle <- shuttle %>% mutate(shuttle_stop = as.integer(shuttlemin <= 10))
service <- service %>% mutate(homeless_service = as.integer(servicemin <= 10))

df <- mv2 %>%
  left_join(friend_station, by = "metro") %>%
  left_join(shuttle %>% select(metro, shuttle_stop), by = "metro") %>%
  left_join(service %>% select(metro, homeless_service), by = "metro")

# Full sample
df_full <- df %>% filter(!is.na(passersby), !is.na(friendliness),
                          !is.na(shuttle_stop), !is.na(homeless_service),
                          !is.na(panhandlers))

cat("Full sample rows:", nrow(df_full), "\n")

m1 <- feols(panhandlers ~ passersby + friendliness + shuttle_stop + homeless_service | date,
            data = df_full, cluster = ~metro)

# Five-station subsample
five <- c("Farragut North", "Farragut West", "Gallery Pl-Chinatown",
          "McPherson Square", "Metro Center", "Gallery Place-Chinatown",
          "Gallery Pl - Chinatown")
df_five <- df_full %>% filter(metro %in% five)
cat("Five station rows:", nrow(df_five), "\n")
cat("Unique metros in five:", paste(unique(df_five$metro), collapse=", "), "\n")

m2 <- feols(panhandlers ~ passersby + friendliness + shuttle_stop + homeless_service | date,
            data = df_five, cluster = ~metro)

print(summary(m1))
print(summary(m2))

coef1 <- coef(m1)
coef2 <- coef(m2)

passersby_full <- coef1["passersby"]
friend_full    <- coef1["friendliness"]
shuttle_full   <- coef1["shuttle_stop"]
passersby_five <- coef2["passersby"]
shuttle_five   <- coef2["shuttle_stop"]

# Receipts analysis
# donations per hour = donations / minutes * 60
rec <- receipts %>%
  mutate(donations = as.numeric(donations),
         minutes = as.numeric(minutes),
         cash = as.numeric(cash),
         inkind = as.numeric(inkind)) %>%
  filter(metro %in% five)

rec$don_per_hr <- rec$donations / rec$minutes * 60
rec$dollars <- rec$cash + ifelse(is.na(rec$inkind), 0, rec$inkind)
rec$dol_per_hr <- rec$dollars / rec$minutes * 60

rec_don <- rec %>% filter(!is.na(don_per_hr), is.finite(don_per_hr))
rec_dol <- rec %>% filter(!is.na(cash), !is.na(dol_per_hr), is.finite(dol_per_hr))

cat("rec_don n:", nrow(rec_don), "\n")
cat("rec_dol n:", nrow(rec_dol), "\n")

# Brown-Forsythe test: Levene with center=median
bf_don <- leveneTest(don_per_hr ~ factor(metro), data = rec_don, center = median)
bf_dol <- leveneTest(dol_per_hr ~ factor(metro), data = rec_dol, center = median)
print(bf_don)
print(bf_dol)

bf_don_W <- bf_don[1, "F value"]
bf_dol_W <- bf_dol[1, "F value"]

# ANOVA
av_don <- summary(aov(don_per_hr ~ factor(metro), data = rec_don))
av_dol <- summary(aov(dol_per_hr ~ factor(metro), data = rec_dol))
print(av_don)
print(av_dol)

F_don <- av_don[[1]]["factor(metro)", "F value"]
F_dol <- av_dol[[1]]["factor(metro)", "F value"]

cat(sprintf("RESULT:passersby_full_sample=%.6f\n", passersby_full))
cat(sprintf("RESULT:passersby_five_station_subsample=%.6f\n", passersby_five))
cat(sprintf("RESULT:friendliness_full_sample=%.6f\n", friend_full))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.6f\n", shuttle_full))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.6f\n", shuttle_five))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.6f\n", bf_don_W))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.6f\n", bf_dol_W))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.6f\n", F_don))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.6f\n", F_dol))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", nrow(df_full)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", nrow(df_five)))