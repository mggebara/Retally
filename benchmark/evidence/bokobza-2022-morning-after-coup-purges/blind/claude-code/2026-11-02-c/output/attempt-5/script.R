suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-c/mount/bokobza_2022_morning_after_coup_purges"
c <- read_dta(file.path(D,"morning_after_dataset_countrylevel.dta"))
i <- readRDS(file.path(D,"morning_after_dataset_individuallevel.rds"))
ii <- i %>% group_by(country_name, year) %>% summarise(ic = first(as.integer(coupattempt_presentyear=="Coup attempt")), .groups="drop")
cat("country names in ind not in ctry:", setdiff(unique(ii$country_name), unique(c$COUNTRY_DATA)), "\n")
cc <- c %>% select(country_name=COUNTRY_DATA, year=YEAR_DATA, cw=coupattempt_whogov, m=coupattempt_month_whogov) %>%
  left_join(ii, by=c("country_name","year")) %>%
  left_join(ii %>% mutate(year=year-1) %>% rename(ic_next=ic), by=c("country_name","year")) %>%
  left_join(ii %>% mutate(year=year+1) %>% rename(ic_prev=ic), by=c("country_name","year"))
print(cc %>% filter(cw==1) %>% group_by(late = m>=7) %>% summarise(n=n(), same=sum(ic==1,na.rm=T), next_=sum(ic_next==1,na.rm=T), prev=sum(ic_prev==1,na.rm=T), naic=sum(is.na(ic))))
print(cc %>% filter(ic==1) %>% summarise(n=n(), cw_same=sum(cw==1,na.rm=T)))
