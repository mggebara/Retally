# Leeson, Hardy & Suarez (2022) "Hobo Economicus" -- independent blind reproduction
set.seed(42)
suppressPackageStartupMessages({library(readr); library(dplyr); library(lubridate); library(fixest); library(car)})
dd <- "<repo>/benchmark/.cache/claude-code/leeson-2022-hobo-economicus/blind/2026-10-21-b/mount/leeson_2022_hobo_economicus/3 replication package/replicate/replicate/data"
visits <- read_csv(file.path(dd,"metrovisitslog.csv"), show_col_types=FALSE)
pass   <- read_csv(file.path(dd,"passersby.csv"), show_col_types=FALSE)
fr     <- read_csv(file.path(dd,"friendliness.csv"), show_col_types=FALSE)
rec    <- read_csv(file.path(dd,"receipts.csv"), show_col_types=FALSE)
serv   <- read_csv(file.path(dd,"service.csv"), show_col_types=FALSE)
shut   <- read_csv(file.path(dd,"shuttle.csv"), show_col_types=FALSE)

# Passerby friendliness: friendliest (highest) response category per passerby, averaged by station
R <- as.matrix(fr[,paste0("passresp",1:5)])
fr$friendliest <- apply(R, 1, function(r) max(which(r == 1)))
frs <- fr %>% group_by(metro) %>% summarise(friendliness = mean(friendliest), .groups="drop")

# Indicators: within a ten-minute walk (<= 10 minutes)
serv <- serv %>% transmute(metro, service = as.integer(servicemin <= 10))
shut <- shut %>% transmute(metro, shuttle = as.integer(shuttlemin <= 10))

df <- visits %>% mutate(d = mdy(date), month = month(d), year = year(d)) %>%
  left_join(pass, by=c("metro","month","year")) %>%
  left_join(frs, by="metro") %>% left_join(serv, by="metro") %>% left_join(shut, by="metro")
stopifnot(!anyNA(df[,c("passersby","friendliness","service","shuttle")]))

five <- c("Farragut North","Farragut West","Gallery Place","McPherson Square","Metro Center")
df5 <- df %>% filter(metro %in% five)

cat("Summary (full):\n"); print(sapply(df[,c("panhandlers","passersby","friendliness","service","shuttle")], function(x) c(n=length(x), mean=mean(x), sd=sd(x))))
cat("Summary (five):\n"); print(sapply(df5[,c("panhandlers","passersby","friendliness","service","shuttle")], function(x) c(n=length(x), mean=mean(x), sd=sd(x))))

f <- panhandlers ~ passersby + friendliness + shuttle + service | date
m1 <- feols(f, data=df,  cluster=~metro)
m2 <- feols(f, data=df5, cluster=~metro)
print(summary(m1)); print(fitstat(m1, ~ar2))
print(summary(m2)); print(fitstat(m2, ~ar2))
# NOTE: in the five-station subsample, friendliness/service/shuttle are station-level and
# may be collinear with each other given only 5 stations; fixest drops collinear terms.
cat("Coefs m2:\n"); print(coef(m2))

# Receipts
rec <- rec %>% mutate(donph = donations / minutes * 60,
                      dollars = cash + inkind,          # missing if either component missing
                      dolph = dollars / minutes * 60,
                      metro = factor(metro))
recD <- rec %>% filter(!is.na(dolph))
cat("N donations:", nrow(rec), " N dollars:", nrow(recD), "\n")
print(rec %>% group_by(metro) %>% summarise(mean=mean(donph), sd=sd(donph), n=n()))
print(recD %>% group_by(metro) %>% summarise(mean=mean(dolph), sd=sd(dolph), n=n()))

bf1 <- leveneTest(donph ~ metro, data=rec,  center=median)
bf2 <- leveneTest(dolph ~ metro, data=recD, center=median)
print(bf1); print(bf2)
a1 <- anova(lm(donph ~ metro, data=rec)); a2 <- anova(lm(dolph ~ metro, data=recD))
print(a1); print(a2)

g <- function(m, v) if (v %in% names(coef(m))) unname(coef(m)[v]) else NA
cat(sprintf("RESULT:passersby_full_sample=%.6f\n", g(m1,"passersby")))
cat(sprintf("RESULT:passersby_five_station_subsample=%.6f\n", g(m2,"passersby")))
cat(sprintf("RESULT:friendliness_full_sample=%.6f\n", g(m1,"friendliness")))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.6f\n", g(m1,"shuttle")))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.6f\n", g(m2,"shuttle")))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.6f\n", bf1[1,"F value"]))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.6f\n", bf2[1,"F value"]))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.6f\n", a1[1,"F value"]))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.6f\n", a2[1,"F value"]))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", nobs(m1)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", nobs(m2)))
