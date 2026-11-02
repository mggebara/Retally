suppressPackageStartupMessages({library(readr); library(dplyr); library(fixest); library(car)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/leeson-2022-hobo-economicus/seeded/2026-11-02-b/mount/leeson_2022_hobo_economicus/3 replication package/replicate/replicate/data"
rd <- function(f) read_csv(file.path(D, f), show_col_types = FALSE)

# Station visits (1_dataprep.do)
visits <- rd("metrovisitslog.csv") %>%
  mutate(day = as.Date(date, format = "%m/%d/%Y"),
         month = as.integer(format(day, "%m")), year = as.integer(format(day, "%Y")))
pass <- rd("passersby.csv")
service <- rd("service.csv") %>% filter(!is.na(metro), metro != "") %>%
  transmute(metro, service = as.integer(servicemin <= 10))
shuttle <- rd("shuttle.csv") %>% filter(!is.na(metro), metro != "") %>%
  transmute(metro, shuttle = as.integer(shuttlemin <= 10))
fr <- rd("friendliness.csv") %>%
  mutate(friendly = case_when(passresp5 == 1 ~ 5, passresp4 == 1 ~ 4, passresp3 == 1 ~ 3,
                              passresp2 == 1 ~ 2, passresp1 == 1 ~ 1, TRUE ~ NA_real_)) %>%
  group_by(metro) %>% summarise(friendly = mean(friendly, na.rm = TRUE), .groups = "drop")

sv <- visits %>% left_join(pass, by = c("metro", "month", "year")) %>%
  left_join(service, by = "metro") %>% left_join(shuttle, by = "metro") %>%
  left_join(fr, by = "metro")
# Stata encode = alphabetical ids; subsample ids 9,10,14,17,18
lv <- sort(unique(sv$metro))
sv$metroid <- match(sv$metro, lv)
sv$subsample <- as.integer(sv$metroid %in% c(9, 10, 14, 17, 18))
sv$dayf <- factor(sv$day)
cat("Subsample stations:", paste(lv[c(9,10,14,17,18)], collapse = "; "), "\n")

m1 <- feols(panhandlers ~ passersby + friendly + shuttle + service | dayf, data = sv,
            cluster = ~metroid, fixef.rm = "none")
m2 <- feols(panhandlers ~ passersby + friendly + shuttle + service | dayf,
            data = subset(sv, subsample == 1), cluster = ~metroid, fixef.rm = "none")
print(summary(m1)); print(summary(m2))

# Receipts
rc <- rd("receipts.csv") %>%
  mutate(hourlydonations = 60 * donations / minutes,
         hourlydollars = 60 * (cash + inkind) / minutes,
         metro = factor(metro))
dn <- rc %>% filter(is.finite(hourlydonations))
dl <- rc %>% filter(is.finite(hourlydollars))
cat("N donations:", nrow(dn), " N dollars:", nrow(dl), "\n")
bf_dn <- leveneTest(hourlydonations ~ metro, data = dn, center = median)
bf_dl <- leveneTest(hourlydollars ~ metro, data = dl, center = median)
lv_dn <- leveneTest(hourlydonations ~ metro, data = dn, center = mean)
lv_dl <- leveneTest(hourlydollars ~ metro, data = dl, center = mean)
cat("Levene W0 donations:", lv_dn$`F value`[1], " dollars:", lv_dl$`F value`[1], "\n")
a_dn <- anova(lm(hourlydonations ~ metro, data = dn))
a_dl <- anova(lm(hourlydollars ~ metro, data = dl))

cat(sprintf("RESULT:passersby_full_sample=%.6f\n", coef(m1)[["passersby"]]))
cat(sprintf("RESULT:passersby_five_station_subsample=%.6f\n", coef(m2)[["passersby"]]))
cat(sprintf("RESULT:friendliness_full_sample=%.6f\n", coef(m1)[["friendly"]]))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.6f\n", coef(m1)[["shuttle"]]))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.6f\n", coef(m2)[["shuttle"]]))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.6f\n", bf_dn$`F value`[1]))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.6f\n", bf_dl$`F value`[1]))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.6f\n", a_dn$`F value`[1]))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.6f\n", a_dl$`F value`[1]))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", nobs(m1)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", nobs(m2)))
