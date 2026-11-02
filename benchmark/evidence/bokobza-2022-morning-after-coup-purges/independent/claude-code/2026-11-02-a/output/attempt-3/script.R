library(haven); library(dplyr)
P <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges"
c <- read_dta(file.path(P,"morning_after_dataset_countrylevel.dta")) %>% zap_labels()
c <- c %>% arrange(COUNTRY_ID, YEAR_DATA) %>% group_by(COUNTRY_ID) %>%
  mutate(lagok = lag(YEAR_DATA)==YEAR_DATA-1,
         ldem = ifelse(lagok, lag(democracy1), NA),
         lgdp = ifelse(lagok, lag(gdp_cap_pwt_ln), NA),
         lpop = ifelse(lagok, lag(pop_pwt_ln), NA)) %>% ungroup()
f <- function(lbl, d) cat(lbl, "N", nrow(d), "countries", n_distinct(d$COUNTRY_ID), "coups", sum(d$coupattempt_whogov), "\n")
base <- function(d) d %>% filter(YEAR_DATA>=1967, YEAR_DATA<=2016, !is.na(replacement_rateadj_minister), !is.na(coupattempt_whogov), !is.na(lgdp), !is.na(lpop))
f("ldem(BMR)", base(c %>% filter(ldem==0)))
f("ldem & indep", base(c %>% filter(ldem==0, independent==1)))
f("ldemocracy_br", base(c %>% filter(ldemocracy_br==0)))
f("dem1 current", base(c %>% filter(democracy1==0)))
f("ldem & dem current", base(c %>% filter(ldem==0, democracy1==0)))
# countries with few obs
d <- base(c %>% filter(ldem==0)); print(sort(table(d$COUNTRY_DATA))[1:10])
# which ccode duplicates (e.g. Soviet Union/Russia)
print(d %>% group_by(COUNTRY_DATA) %>% summarise(n=n(), cc=first(ccode), id=first(COUNTRY_ID)) %>% filter(cc>1000 | n<5))

i <- readRDS(file.path(P,"morning_after_dataset_individuallevel.rds"))
g <- function(lbl, b) { b <- b %>% filter(year>=1967, year<=2016, !is.na(coupattempt_presentyear), !is.na(gdp_cap_pwt_ln_lag))
  cat(lbl, "N", nrow(b), "ctry", n_distinct(b$country_isocode), "junior", sum(b$classification=="Minister (Junior)"), "imp-junior", sum(b$importance_numeric=="0.5", na.rm=TRUE),
      "NAimp", sum(is.na(b$importance_numeric)), "imp0", sum(b$importance_numeric=="0",na.rm=TRUE), "pg NA/unk", sum(is.na(b$party_group) | b$party_group=="unknown"), "mt NA", sum(is.na(b$minister_type)), "\n") }
g("dl0 nonleader", i %>% filter(democracy_lag==0, leader==0))
g("dlbr Autoc nonleader", i %>% filter(democracy_lag_br=="Autocracy", leader==0))
g("dl0 all", i %>% filter(democracy_lag==0))
g("dl0 imp!=5", i %>% filter(democracy_lag==0, importance_numeric!="5" | is.na(importance_numeric)))
b <- i %>% filter(democracy_lag==0, year>=1967, year<=2016, !is.na(coupattempt_presentyear), !is.na(gdp_cap_pwt_ln_lag))
print(table(leader=b$leader, imp5=b$importance_numeric=="5", useNA="a"))
print(table(b$experience_group, b$importance_numeric=="0.5", useNA="a"))
