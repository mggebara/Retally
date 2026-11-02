suppressMessages({library(tidyverse); library(fixest); library(car)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/leeson-2022-hobo-economicus/independent/2026-11-01-a/mount/leeson_2022_hobo_economicus/3 replication package/replicate/replicate/data"
v <- read_csv(file.path(D,"metrovisitslog.csv"), show_col_types=FALSE)
p <- read_csv(file.path(D,"passersby.csv"), show_col_types=FALSE)
f <- read_csv(file.path(D,"friendliness.csv"), show_col_types=FALSE)
sv <- read_csv(file.path(D,"service.csv"), show_col_types=FALSE)
sh <- read_csv(file.path(D,"shuttle.csv"), show_col_types=FALSE)
r <- read_csv(file.path(D,"receipts.csv"), show_col_types=FALSE)

# friendliness: each passerby's friendliest response category (1-5), averaged by station
R <- as.matrix(f[, paste0("passresp",1:5)])
f$best <- apply(R, 1, function(x) if (any(x==1, na.rm=TRUE)) max(which(x==1)) else NA)
fr <- f %>% group_by(metro) %>% summarise(friend = mean(best, na.rm=TRUE))

v <- v %>% mutate(date = mdy(date), month = month(date), year = year(date),
                  pmetro = ifelse(metro=="Georgetown" & !("Georgetown" %in% p$metro), "Foggy Bottom", metro))
d <- v %>% left_join(p %>% rename(pmetro=metro), by=c("pmetro","month","year")) %>%
  left_join(fr, by="metro") %>%
  left_join(sv %>% transmute(metro, service = as.numeric(servicemin <= 10)), by="metro") %>%
  left_join(sh %>% transmute(metro, shuttle = as.numeric(shuttlemin <= 10)), by="metro")
cat("missing passersby:", sum(is.na(d$passersby)), "\n")
print(d %>% summarise(across(c(panhandlers, passersby, friend, service, shuttle), list(m=mean, s=sd))))

five <- c("Farragut North","Farragut West","Gallery Place","McPherson Square","Metro Center")
m1 <- feols(panhandlers ~ passersby + friend + shuttle + service | date, data=d, cluster=~metro)
m2 <- feols(panhandlers ~ passersby + friend + shuttle + service | date, data=filter(d, metro %in% five), cluster=~metro)
print(etable(m1, m2, fitstat=~n+ar2))

# receipts
r <- r %>% mutate(dph = donations/minutes*60, dollars = cash + inkind, dolph = dollars/minutes*60)
rd <- filter(r, !is.na(dolph))
cat("N donations:", nrow(r), " N dollars:", nrow(rd), "\n")
print(r %>% group_by(metro) %>% summarise(m=mean(dph), s=sd(dph), n=n()))
print(rd %>% group_by(metro) %>% summarise(m=mean(dolph), s=sd(dolph), n=n()))
bf1 <- leveneTest(dph ~ factor(metro), data=r, center=median)
bf2 <- leveneTest(dolph ~ factor(metro), data=rd, center=median)
a1 <- anova(lm(dph ~ factor(metro), data=r)); a2 <- anova(lm(dolph ~ factor(metro), data=rd))
print(bf1); print(bf2); print(a1); print(a2)

cat(sprintf("RESULT:passersby_full_sample=%.6f\n", coef(m1)["passersby"]))
cat(sprintf("RESULT:passersby_five_station_subsample=%.6f\n", coef(m2)["passersby"]))
cat(sprintf("RESULT:friendliness_full_sample=%.6f\n", coef(m1)["friend"]))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.6f\n", coef(m1)["shuttle"]))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.6f\n", coef(m2)["shuttle"]))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.6f\n", bf1[1,"F value"]))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.6f\n", bf2[1,"F value"]))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.6f\n", a1[1,"F value"]))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.6f\n", a2[1,"F value"]))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", nobs(m1)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", nobs(m2)))
