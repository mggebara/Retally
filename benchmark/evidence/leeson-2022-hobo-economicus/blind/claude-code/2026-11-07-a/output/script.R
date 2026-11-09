suppressPackageStartupMessages({library(readr); library(dplyr); library(fixest); library(car)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/leeson-2022-hobo-economicus/blind/2026-11-07-a/mount/leeson_2022_hobo_economicus/3 replication package/replicate/replicate/data"
rd <- function(f) read_csv(file.path(D, f), show_col_types = FALSE)
visits <- rd("metrovisitslog.csv"); fr <- rd("friendliness.csv"); pb <- rd("passersby.csv")
rec <- rd("receipts.csv"); svc <- rd("service.csv"); sh <- rd("shuttle.csv")

# Friendliness: each passerby's friendliest (highest-category) response; station average
pr <- as.matrix(fr[, paste0("passresp", 1:5)])
fr$best <- apply(pr, 1, function(r) { k <- which(r == 1); if (length(k)) max(k) else NA_real_ })
cat("passersby with no response coded:", sum(is.na(fr$best)), "\n")
frs <- fr %>% group_by(metro) %>% summarise(friendliness = mean(best, na.rm = TRUE))

visits <- visits %>% mutate(d = as.Date(date, "%m/%d/%Y"), month = as.integer(format(d, "%m")),
                            year = as.integer(format(d, "%Y")))
dat <- visits %>% left_join(pb, by = c("metro", "month", "year")) %>%
  left_join(frs, by = "metro") %>%
  left_join(svc %>% transmute(metro, service = as.integer(servicemin <= 10)), by = "metro") %>%
  left_join(sh %>% transmute(metro, shuttle = as.integer(shuttlemin <= 10)), by = "metro")
cat("missing passersby:", sum(is.na(dat$passersby)), " stations:", n_distinct(dat$metro), "\n")
print(summary(dat[, c("panhandlers", "passersby", "friendliness", "service", "shuttle")]))
five <- c("Farragut North", "Farragut West", "Gallery Place", "McPherson Square", "Metro Center")
sub <- dat %>% filter(metro %in% five)

# OLS with date dummies: keep singleton date groups (they do not affect coefficients)
m1 <- feols(panhandlers ~ passersby + friendliness + shuttle + service | date, data = dat, cluster = ~metro, fixef.rm = "none")
m2 <- feols(panhandlers ~ passersby + friendliness + shuttle + service | date, data = sub, cluster = ~metro, fixef.rm = "none")
print(summary(m1)); print(summary(m2))
cat("adj R2:", r2(m1, "ar2"), r2(m2, "ar2"), "\n")

# Receipts
rec <- rec %>% mutate(dph = donations / minutes * 60,
                      dollars = cash + inkind,  # missing if cash or in-kind value was not recorded
                      usdph = dollars / minutes * 60, metro = factor(metro))
r2d <- rec %>% filter(!is.na(usdph))
cat("N donations:", nrow(rec), " N dollars:", nrow(r2d), "\n")
print(rec %>% group_by(metro) %>% summarise(m = mean(dph), s = sd(dph), n = n()))
print(r2d %>% group_by(metro) %>% summarise(m = mean(usdph), s = sd(usdph), n = n()))
bf1 <- leveneTest(dph ~ metro, data = rec, center = median)
bf2 <- leveneTest(usdph ~ metro, data = r2d, center = median)
a1 <- summary(aov(dph ~ metro, data = rec))[[1]]
a2 <- summary(aov(usdph ~ metro, data = r2d))[[1]]
print(bf1); print(bf2); print(a1); print(a2)

cat(sprintf("RESULT:passersby_full_sample=%.6f\n", coef(m1)["passersby"]))
cat(sprintf("RESULT:passersby_five_station_subsample=%.6f\n", coef(m2)["passersby"]))
cat(sprintf("RESULT:friendliness_full_sample=%.6f\n", coef(m1)["friendliness"]))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.6f\n", coef(m1)["shuttle"]))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.6f\n", coef(m2)["shuttle"]))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.6f\n", bf1[1, "F value"]))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.6f\n", bf2[1, "F value"]))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.6f\n", a1[1, "F value"]))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.6f\n", a2[1, "F value"]))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", nobs(m1)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", nobs(m2)))
