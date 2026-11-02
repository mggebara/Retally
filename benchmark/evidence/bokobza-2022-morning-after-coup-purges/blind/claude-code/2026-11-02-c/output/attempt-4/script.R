suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-c/mount/bokobza_2022_morning_after_coup_purges"
c <- read_dta(file.path(D,"morning_after_dataset_countrylevel.dta"))
c <- c %>% arrange(COUNTRY_ID, YEAR_DATA) %>% group_by(COUNTRY_ID) %>%
  mutate(ok = dplyr::lag(YEAR_DATA)==YEAR_DATA-1,
         ldem = ifelse(ok, dplyr::lag(democracy1), NA),
         lgdp = ifelse(ok, dplyr::lag(gdp_cap_pwt_ln), NA),
         lpop = ifelse(ok, dplyr::lag(pop_pwt_ln), NA),
         lleader = ifelse(ok, dplyr::lag(leader_cab_id), NA)) %>% ungroup()
bb <- c %>% filter(!is.na(replacement_rateadj_minister), !is.na(coupattempt_whogov), !is.na(lgdp), !is.na(lpop), ldem==0, YEAR_DATA %in% 1967:2016)
f <- function(d, lab) cat(lab, "N=", nrow(d), " countries=", n_distinct(d$COUNTRY_ID), " leaders=", n_distinct(d$leader_cab_id), "\n")
f(bb, "base")
f(bb %>% filter(leaderexperience_continuous>1), "leaderexp>1")
f(bb %>% filter(leader_cab_id==lleader), "same leader as last year")
x <- bb %>% filter(leaderexperience_continuous>1); ls <- x %>% count(leader_cab_id) %>% filter(n==1); cat(" leaderexp>1 minus leader singletons:", nrow(x)-nrow(ls), "\n")
x <- bb %>% filter(leader_cab_id==lleader); ls <- x %>% count(leader_cab_id) %>% filter(n==1); cat(" sameleader minus leader singletons:", nrow(x)-nrow(ls), "\n")
print(table(bb$leaderexperience_continuous)[1:5])
f(bb %>% filter(!is.na(democracy1)), "dem1 nonNA")
f(bb %>% filter(!is.na(ldemocracy_br)), "ldem_br nonNA")
f(bb %>% filter(!is.na(growth_pwt)), "growth nonNA")
f(bb %>% filter(!is.na(gdp_cap_pwt_ln)), "gdp current nonNA")
f(bb %>% filter(!is.na(coupattempt_whogov_br)), "coup_br nonNA")
f(bb %>% filter(!is.na(lpolity2)), "lpolity nonNA")
i <- readRDS(file.path(D,"morning_after_dataset_individuallevel.rds"))
i <- i %>% filter(leader==0, importance_numeric %in% c("0.5","1","2","3","4"))
g <- function(d, lab) cat(lab, "N=", nrow(d), " countries=", n_distinct(d$country_isocode), "\n")
g(i %>% filter(democracy_lag==0, year %in% 1967:2016, !is.na(gdp_cap_pwt_ln_lag), !is.na(pop_pwt_ln_lag), !is.na(coupattempt_presentyear)), "imp base")
g(i %>% filter(democracy_lag==0, !is.na(gdp_cap_pwt_ln_lag), !is.na(pop_pwt_ln_lag), !is.na(coupattempt_presentyear)), "imp no year")
g(i %>% filter(democracy_lag==0, year %in% 1967:2016, !is.na(gdp_cap_pwt_ln_lag), !is.na(pop_pwt_ln_lag)), "imp coupNA kept")
g(i %>% filter(democracy_lag==0, !is.na(gdp_cap_pwt_ln_lag), !is.na(pop_pwt_ln_lag)), "imp coupNA kept no year")
g(i %>% filter(democracy_lag==0, year %in% 1967:2016, !is.na(gdp_cap_pwt_ln_lag), !is.na(pop_pwt_ln_lag), !is.na(coupattempt_presentyear_br)), "imp coup_br nonNA")
x <- i %>% filter(democracy_lag==0, year %in% 1967:2016, !is.na(gdp_cap_pwt_ln_lag), !is.na(pop_pwt_ln_lag))
print(table(x$year[is.na(x$coupattempt_presentyear)]))
