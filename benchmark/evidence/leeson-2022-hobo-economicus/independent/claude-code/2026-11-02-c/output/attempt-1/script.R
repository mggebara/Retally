suppressPackageStartupMessages({library(readr); library(dplyr); library(fixest); library(car); library(lubridate)})
set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/leeson-2022-hobo-economicus/independent/2026-11-02-c/mount/leeson_2022_hobo_economicus/3 replication package/replicate/replicate/data"
rd <- function(f) read_csv(file.path(d, f), show_col_types = FALSE)
visits <- rd("metrovisitslog.csv"); fr <- rd("friendliness.csv"); pb <- rd("passersby.csv")
rc <- rd("receipts.csv"); sv <- rd("service.csv"); sh <- rd("shuttle.csv")

# Friendliness: each passerby's friendliest response (highest category marked), averaged by station
R <- as.matrix(fr[, paste0("passresp", 1:5)]); R[is.na(R)] <- 0
fr$friendliest <- apply(R, 1, function(r) if (any(r > 0)) max(which(r > 0)) else NA_real_)
cat("passersby with no response marked:", sum(is.na(fr$friendliest)), "\n")
frs <- fr %>% group_by(metro) %>% summarise(friend = mean(friendliest, na.rm = TRUE))

visits <- visits %>% mutate(dt = mdy(date), month = month(dt), year = year(dt))
pb <- pb %>% distinct(metro, month, year, .keep_all = TRUE)
df <- visits %>% left_join(pb, by = c("metro", "month", "year")) %>%
  left_join(frs, by = "metro") %>%
  left_join(sv %>% transmute(metro, service = as.numeric(servicemin <= 10)), by = "metro") %>%
  left_join(sh %>% transmute(metro, shuttle = as.numeric(shuttlemin <= 10)), by = "metro")
cat("missing passersby:", sum(is.na(df$passersby)), " missing friend:", sum(is.na(df$friend)), "\n")
vars <- c("panhandlers", "passersby", "friend", "service", "shuttle")
cat("means:", sapply(df[, vars], mean, na.rm = TRUE), "\n")
cat("SDs:", sapply(df[, vars], sd, na.rm = TRUE), "\n")

five <- c("Farragut North", "Farragut West", "Gallery Place", "McPherson Square", "Metro Center")
sub <- filter(df, metro %in% five)
cat("subsample means:", sapply(sub[, vars], mean, na.rm = TRUE), "\n")
m1 <- feols(panhandlers ~ passersby + friend + shuttle + service | date, data = df, cluster = ~metro)
m2 <- feols(panhandlers ~ passersby + friend + shuttle + service | date, data = sub, cluster = ~metro)
print(etable(m1, m2, fitstat = ~ n + ar2))

# Receipts
rc <- rc %>% mutate(metro = factor(metro), don_hr = donations / minutes * 60,
                    dol_hr = (cash + inkind) / minutes * 60)
rd_d <- filter(rc, !is.na(don_hr)); rd_s <- filter(rc, !is.na(dol_hr))
cat("N donations:", nrow(rd_d), " N dollars:", nrow(rd_s), " mean don/hr", mean(rd_d$don_hr), " mean $/hr", mean(rd_s$dol_hr), "\n")
bf_d <- leveneTest(don_hr ~ metro, data = rd_d, center = median)
bf_s <- leveneTest(dol_hr ~ metro, data = rd_s, center = median)
av_d <- summary(aov(don_hr ~ metro, data = rd_d))[[1]]
av_s <- summary(aov(dol_hr ~ metro, data = rd_s))[[1]]
print(bf_d); print(bf_s); print(av_d); print(av_s)

out <- c(passersby_full_sample = coef(m1)[["passersby"]],
         passersby_five_station_subsample = coef(m2)[["passersby"]],
         friendliness_full_sample = coef(m1)[["friend"]],
         shuttle_stop_full_sample = coef(m1)[["shuttle"]],
         shuttle_stop_five_station_subsample = coef(m2)[["shuttle"]],
         brown_forsythe_donations_per_hour = bf_d[1, "F value"],
         brown_forsythe_dollars_per_hour = bf_s[1, "F value"],
         anova_f_donations_per_hour = av_d[1, "F value"],
         anova_f_dollars_per_hour = av_s[1, "F value"],
         station_visits_full_sample = nobs(m1),
         station_visits_five_station_subsample = nobs(m2))
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
