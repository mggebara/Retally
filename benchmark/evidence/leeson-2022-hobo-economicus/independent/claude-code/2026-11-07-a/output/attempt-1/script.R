suppressPackageStartupMessages({library(readr); library(dplyr); library(fixest); library(car)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/leeson-2022-hobo-economicus/independent/2026-11-07-a/mount/leeson_2022_hobo_economicus/3 replication package/replicate/replicate/data"
rd <- function(f) read_csv(file.path(D, f), show_col_types = FALSE)
visits <- rd("metrovisitslog.csv"); pass <- rd("passersby.csv"); fr <- rd("friendliness.csv")
sh <- rd("shuttle.csv"); sv <- rd("service.csv"); rc <- rd("receipts.csv")

visits <- visits %>% mutate(d = as.Date(date, "%m/%d/%Y"),
                            month = as.integer(format(d, "%m")),
                            year = as.integer(format(d, "%Y")))
# Friendliness: each passerby's friendliest response (1-5), averaged by station
fr$best <- apply(as.matrix(fr[, paste0("passresp", 1:5)]), 1,
                 function(r) { k <- which(r == 1); if (length(k)) max(k) else NA })
frs <- fr %>% group_by(metro) %>% summarise(friendliness = mean(best, na.rm = TRUE))
df <- visits %>% left_join(pass, by = c("metro", "month", "year")) %>%
  left_join(frs, by = "metro") %>%
  left_join(sh %>% transmute(metro, shuttle = as.integer(shuttlemin <= 10)), by = "metro") %>%
  left_join(sv %>% transmute(metro, service = as.integer(servicemin <= 10)), by = "metro")
cat("rows", nrow(df), "missing passersby", sum(is.na(df$passersby)),
    "missing friendliness", sum(is.na(df$friendliness)), "\n")
vars <- c("panhandlers", "passersby", "friendliness", "service", "shuttle")
print(sapply(df[, vars], mean, na.rm = TRUE)); print(sapply(df[, vars], sd, na.rm = TRUE))
five <- c("Farragut North", "Farragut West", "Gallery Place", "McPherson Square", "Metro Center")
df5 <- df %>% filter(metro %in% five)
cat("five rows", nrow(df5), "\n")
print(sapply(df5[, vars], mean, na.rm = TRUE))
f <- panhandlers ~ passersby + friendliness + shuttle + service | date
m1 <- feols(f, df, cluster = ~metro); m2 <- feols(f, df5, cluster = ~metro)
print(etable(m1, m2, fitstat = ~ n + ar2))

rc <- rc %>% mutate(don_hr = donations / minutes * 60,
                    dollars = ifelse(is.na(cash), NA, cash + coalesce(inkind, 0)),
                    dol_hr = dollars / minutes * 60, metro = factor(metro))
cat("receipts n", nrow(rc), "dollars nonmissing", sum(!is.na(rc$dol_hr)), "\n")
print(as.data.frame(rc %>% group_by(metro) %>%
  summarise(m = mean(don_hr), s = sd(don_hr), n = n(),
            md = mean(dol_hr, na.rm = TRUE), sdd = sd(dol_hr, na.rm = TRUE), nd = sum(!is.na(dol_hr)))))
rcd <- rc %>% filter(!is.na(dol_hr))
bf1 <- leveneTest(don_hr ~ metro, data = rc, center = median)
bf2 <- leveneTest(dol_hr ~ metro, data = rcd, center = median)
a1 <- summary(aov(don_hr ~ metro, data = rc))[[1]]
a2 <- summary(aov(dol_hr ~ metro, data = rcd))[[1]]
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
