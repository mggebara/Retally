suppressMessages({library(haven); library(dplyr)})
d <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges"
il <- readRDS(file.path(d, "morning_after_dataset_individuallevel.rds"))
x <- il %>% filter(country_isocode %in% c("EGY","KEN")) %>% distinct(country_isocode, year, gdp_cap_pwt_ln, pop_pwt_ln, gdp_cap_pwt_ln_lag, pop_pwt_ln_lag) %>% arrange(country_isocode, year)
print(head(as.data.frame(x), 25))
# variation of pop lag within country
v <- il %>% group_by(country_isocode) %>% summarise(sdpop = sd(pop_pwt_ln_lag, na.rm=TRUE), sdpop0 = sd(pop_pwt_ln, na.rm=TRUE), n_distinct_poplag = n_distinct(pop_pwt_ln_lag))
print(summary(v))
# is pop lag a function of year only?
w <- il %>% group_by(year) %>% summarise(nd = n_distinct(pop_pwt_ln_lag), nd0 = n_distinct(pop_pwt_ln))
print(as.data.frame(w)[1:10,])
print(cor(il$pop_pwt_ln_lag, il$gdp_cap_pwt_ln_lag, use="complete"))
# country-level: lagged monarchy variation within leader
cl <- read_dta(file.path(d, "morning_after_dataset_countrylevel.dta")) %>% zap_labels() %>% as.data.frame()
cl <- cl %>% arrange(COUNTRY_ID, YEAR_DATA) %>% group_by(COUNTRY_ID) %>%
  mutate(cons = (YEAR_DATA - lag(YEAR_DATA)) == 1, l_dem = ifelse(cons, lag(democracy1), NA), l_mon = ifelse(cons, lag(monarchy_c), NA)) %>% ungroup()
cs <- cl %>% filter(l_dem == 0, YEAR_DATA >= 1967, YEAR_DATA <= 2016, !is.na(replacement_rateadj_minister), !is.na(coupattempt_whogov))
vv <- cs %>% group_by(leader_cab_id) %>% summarise(sdl = sd(l_mon, na.rm=TRUE), sdm = sd(monarchy_c, na.rm=TRUE), n=n())
cat("leaders with var in lagged monarchy:", sum(vv$sdl > 0, na.rm=TRUE), " in current monarchy:", sum(vv$sdm > 0, na.rm=TRUE), "\n")
ids <- vv$leader_cab_id[which(vv$sdl > 0)]
print(as.data.frame(cs %>% filter(leader_cab_id %in% ids) %>% select(COUNTRY_DATA, YEAR_DATA, leader_cab_id, monarchy_c, l_mon, replacement_rateadj_minister)))
