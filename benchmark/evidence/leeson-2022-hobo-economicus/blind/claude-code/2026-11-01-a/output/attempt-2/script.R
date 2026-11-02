# Leeson & co. (2022) "Hobo Economicus" -- independent blind reproduction (R)
suppressMessages({library(tidyverse); library(lubridate); library(fixest); library(car)})
set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/leeson-2022-hobo-economicus/blind/2026-11-01-a/mount/leeson_2022_hobo_economicus/3 replication package/replicate/replicate/data/"
v  <- read_csv(paste0(d,"metrovisitslog.csv"), show_col_types=FALSE) %>% mutate(date=mdy(date), month=month(date), year=year(date))
p  <- read_csv(paste0(d,"passersby.csv"), show_col_types=FALSE)
f  <- read_csv(paste0(d,"friendliness.csv"), show_col_types=FALSE)
r  <- read_csv(paste0(d,"receipts.csv"), show_col_types=FALSE)
sh <- read_csv(paste0(d,"shuttle.csv"), show_col_types=FALSE)
se <- read_csv(paste0(d,"service.csv"), show_col_types=FALSE)

# Passersby: Georgetown assigned Foggy Bottom-GWU's monthly exits (paper fn. 9)
fb <- p %>% filter(metro=="Foggy Bottom")
p2 <- bind_rows(p %>% filter(metro!="Georgetown"), fb %>% mutate(metro="Georgetown"))
# Friendliness: each passerby's friendliest response (highest category marked), averaged by station
resp <- as.matrix(f[,paste0("passresp",1:5)])
f$friendliest <- apply(resp, 1, function(x) max(which(x==1)))
fs <- f %>% group_by(metro) %>% summarise(friendliness=mean(friendliest))
# Within ten-minute walk indicators
st <- sh %>% select(metro, shuttlemin) %>% left_join(se %>% select(metro, servicemin), by="metro") %>%
  mutate(shuttle=as.integer(shuttlemin<=10), service=as.integer(servicemin<=10))

df <- v %>% left_join(p2 %>% select(metro,month,year,passersby), by=c("metro","month","year")) %>%
  left_join(fs, by="metro") %>% left_join(st, by="metro")
cat("visits:", nrow(df), " missing passersby:", sum(is.na(df$passersby)), "\n")
print(summary(df %>% select(panhandlers, passersby, friendliness, service, shuttle)))

five <- c("Farragut North","Farragut West","Gallery Place","McPherson Square","Metro Center")
m1 <- feols(panhandlers ~ passersby + friendliness + shuttle + service | date, data=df, cluster=~metro)
m2 <- feols(panhandlers ~ passersby + friendliness + shuttle + service | date, data=filter(df, metro %in% five), cluster=~metro)
print(summary(m1)); print(summary(m2))

# Receipts per hour across the five subsample stations
r <- r %>% mutate(don_hr = donations/minutes*60,
                  dol_hr = (cash+inkind)/minutes*60,
                  metro=factor(metro))
rd <- r %>% filter(!is.na(dol_hr))
cat("N donations:", nrow(r), " N dollars:", nrow(rd), "\n")
bf_don <- leveneTest(don_hr ~ metro, data=r, center=median)
bf_dol <- leveneTest(dol_hr ~ metro, data=rd, center=median)
a_don <- summary(aov(don_hr ~ metro, data=r))[[1]]
a_dol <- summary(aov(dol_hr ~ metro, data=rd))[[1]]
print(bf_don); print(bf_dol); print(a_don); print(a_dol)

cat(sprintf("RESULT:passersby_full_sample=%.10g\n", coef(m1)[["passersby"]]))
cat(sprintf("RESULT:passersby_five_station_subsample=%.10g\n", coef(m2)[["passersby"]]))
cat(sprintf("RESULT:friendliness_full_sample=%.10g\n", coef(m1)[["friendliness"]]))
cat(sprintf("RESULT:shuttle_stop_full_sample=%.10g\n", coef(m1)[["shuttle"]]))
cat(sprintf("RESULT:shuttle_stop_five_station_subsample=%.10g\n", coef(m2)[["shuttle"]]))
cat(sprintf("RESULT:brown_forsythe_donations_per_hour=%.10g\n", bf_don[1,"F value"]))
cat(sprintf("RESULT:brown_forsythe_dollars_per_hour=%.10g\n", bf_dol[1,"F value"]))
cat(sprintf("RESULT:anova_f_donations_per_hour=%.10g\n", a_don[1,"F value"]))
cat(sprintf("RESULT:anova_f_dollars_per_hour=%.10g\n", a_dol[1,"F value"]))
cat(sprintf("RESULT:station_visits_full_sample=%d\n", nobs(m1)))
cat(sprintf("RESULT:station_visits_five_station_subsample=%d\n", nobs(m2)))
