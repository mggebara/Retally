suppressPackageStartupMessages({library(readr); library(dplyr); library(fixest); library(car)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/leeson-2022-hobo-economicus/independent/2026-10-21-b/mount/leeson_2022_hobo_economicus/3 replication package/replicate/replicate/data"
rd <- function(f) suppressMessages(read_csv(file.path(D, f), show_col_types = FALSE))
visits <- rd("metrovisitslog.csv"); fr <- rd("friendliness.csv"); pb <- rd("passersby.csv")
rc <- rd("receipts.csv"); sh <- rd("shuttle.csv"); sv <- rd("service.csv")

visits <- visits %>% mutate(d = as.Date(date, "%m/%d/%Y"), month = as.integer(format(d, "%m")),
                            year = as.integer(format(d, "%Y")),
                            pbmetro = ifelse(metro == "Georgetown", "Foggy Bottom", metro))
# friendliness: friendliest (highest) response category per passerby, averaged by station
fr$friendliest <- apply(as.matrix(fr[, paste0("passresp", 1:5)]), 1, function(r) {
  r[is.na(r)] <- 0; if (any(r == 1)) max(which(r == 1)) else NA })
frs <- fr %>% group_by(metro) %>% summarise(friendliness = mean(friendliest, na.rm = TRUE))
df <- visits %>%
  left_join(pb, by = c("pbmetro" = "metro", "month", "year")) %>%
  left_join(frs, by = "metro") %>%
  left_join(sh %>% transmute(metro, shuttle = as.integer(shuttlemin <= 10)), by = "metro") %>%
  left_join(sv %>% transmute(metro, service = as.integer(servicemin <= 10)), by = "metro")
cat("Missing passersby:", sum(is.na(df$passersby)), " missing friendliness:", sum(is.na(df$friendliness)), "\n")
print(as.data.frame(df %>% summarise(across(c(panhandlers, passersby, friendliness, service, shuttle),
                              list(m = ~mean(.x, na.rm = TRUE), s = ~sd(.x, na.rm = TRUE))))))
five <- c("Farragut North", "Farragut West", "Gallery Place", "McPherson Square", "Metro Center")
m1 <- feols(panhandlers ~ passersby + friendliness + shuttle + service | date, data = df, cluster = ~metro, fixef.rm = "none")
m2 <- feols(panhandlers ~ passersby + friendliness + shuttle + service | date,
            data = filter(df, metro %in% five), cluster = ~metro, fixef.rm = "none")
print(etable(m1, m2, fitstat = ~ n + ar2))

# receipts
rc <- rc %>% mutate(don_hr = donations / minutes * 60,
                    dol_hr = (cash + inkind) / minutes * 60, metro = factor(metro))
cat("N donations/hr:", sum(!is.na(rc$don_hr)), " N dollars/hr:", sum(!is.na(rc$dol_hr)), "\n")
print(summary(rc[, c("don_hr", "dol_hr")]))
bf1 <- leveneTest(don_hr ~ metro, data = rc, center = median)
bf2 <- leveneTest(dol_hr ~ metro, data = filter(rc, !is.na(dol_hr)), center = median)
print(bf1); print(bf2)
a1 <- anova(lm(don_hr ~ metro, data = rc)); a2 <- anova(lm(dol_hr ~ metro, data = rc))
print(a1); print(a2)

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
