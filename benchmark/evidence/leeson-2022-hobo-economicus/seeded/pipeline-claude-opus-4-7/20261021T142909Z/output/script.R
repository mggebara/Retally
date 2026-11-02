suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(lubridate)
  library(fixest)
  library(car)
})

set.seed(42)

base <- "<repo>/.cache/datasets/leeson_2022_hobo_economicus/3 replication package/replicate/replicate/data"

metrovisits <- read_csv(file.path(base, "metrovisitslog.csv"), show_col_types = FALSE)
passersby   <- read_csv(file.path(base, "passersby.csv"), show_col_types = FALSE)
service     <- read_csv(file.path(base, "service.csv"), show_col_types = FALSE)
shuttle     <- read_csv(file.path(base, "shuttle.csv"), show_col_types = FALSE)
friendliness<- read_csv(file.path(base, "friendliness.csv"), show_col_types = FALSE)
receipts    <- read_csv(file.path(base, "receipts.csv"), show_col_types = FALSE)

# Prepare metrovisits
metrovisits <- metrovisits %>%
  mutate(day = mdy(date),
         month = month(day),
         year = year(day))

# Service and shuttle
service <- service %>% filter(!is.na(metro) & metro != "") %>%
  mutate(service = as.integer(servicemin <= 10)) %>%
  select(metro, service)

shuttle <- shuttle %>% filter(!is.na(metro) & metro != "") %>%
  mutate(shuttle = as.integer(shuttleman <- shuttlemin <= 10)) %>%
  select(metro, shuttle)

# Friendliness per passerby -> station average
friendliness <- friendliness %>%
  mutate(friendly = case_when(
    passresp5 == 1 ~ 5,
    passresp4 == 1 ~ 4,
    passresp3 == 1 ~ 3,
    passresp2 == 1 ~ 2,
    passresp1 == 1 ~ 1,
    TRUE ~ NA_real_
  ))

station_friendly <- friendliness %>%
  group_by(metro) %>%
  summarise(friendly = mean(friendly, na.rm = TRUE), .groups = "drop")

# Combine
stationvisit <- metrovisits %>%
  left_join(passersby, by = c("metro", "month", "year")) %>%
  left_join(service, by = "metro") %>%
  left_join(shuttle, by = "metro") %>%
  left_join(station_friendly, by = "metro")

# Five-station subsample
sub_stations <- c("Farragut North", "Farragut West", "Gallery Place-Chinatown",
                  "Gallery Place", "McPherson Square", "Metro Center")
stationvisit <- stationvisit %>%
  mutate(subsample = as.integer(metro %in% sub_stations))

# Full sample regression
m1 <- feols(panhandlers ~ passersby + friendly + shuttle + service | day,
            data = stationvisit, cluster = ~metro, fixef.rm = "none")

# Five-station subsample
m2 <- feols(panhandlers ~ passersby + friendly + shuttle + service | day,
            data = stationvisit %>% filter(subsample == 1),
            cluster = ~metro, fixef.rm = "none")

n1 <- m1$nobs
n2 <- m2$nobs

b_pass_full <- coef(m1)["passersby"]
b_pass_sub  <- coef(m2)["passersby"]
b_friend_full <- coef(m1)["friendly"]
b_shut_full <- coef(m1)["shuttle"]
b_shut_sub  <- coef(m2)["shuttle"]

# Receipts: hourly donations/dollars
receipts <- receipts %>%
  mutate(hourlydonations = 60 * donations / minutes,
         hourlydollars = 60 * (cash + inkind) / minutes)

# Restrict to 5 downtown stations (as in Stata, receipts data only contains those)
rec_don <- receipts %>% filter(!is.na(hourlydonations))
rec_dol <- receipts %>% filter(!is.na(hourlydollars))

# Brown-Forsythe (median-centered Levene) via car::leveneTest
bf_don <- leveneTest(hourlydonations ~ factor(metro), data = rec_don, center = median)
bf_dol <- leveneTest(hourlydollars ~ factor(metro), data = rec_dol, center = median)

bf_don_W <- bf_don$`F value`[1]
bf_dol_W <- bf_dol$`F value`[1]

# ANOVA
a_don <- summary(aov(hourlydonations ~ factor(metro), data = rec_don))
a_dol <- summary(aov(hourlydollars ~ factor(metro), data = rec_dol))

f_don <- a_don[[1]]$`F value`[1]
f_dol <- a_dol[[1]]$`F value`[1]

cat(sprintf("RESULT:passersby_full_sample=%.6f\n", b_pass_full))
cat(sprintf("RESULT:passersby_five_station_subsample=%.6f\n", b_pass_sub))
cat(sprintf("RESULT:friendliness_full_sample=%.6f\n", b_friend_full))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.6f\n", b_shut_full))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.6f\n", b_shut_sub))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.6f\n", bf_don_W))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.6f\n", bf_dol_W))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.6f\n", f_don))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.6f\n", f_dol))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", as.integer(n1)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", as.integer(n2)))