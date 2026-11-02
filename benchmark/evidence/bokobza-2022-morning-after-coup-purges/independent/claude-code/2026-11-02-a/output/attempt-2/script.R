library(haven); library(dplyr); library(fixest)
P <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges"
c <- read_dta(file.path(P,"morning_after_dataset_countrylevel.dta")) %>% zap_labels()
c <- c %>% arrange(COUNTRY_ID, YEAR_DATA) %>% group_by(COUNTRY_ID) %>%
  mutate(lagok = lag(YEAR_DATA)==YEAR_DATA-1,
         ldem = ifelse(lagok, lag(democracy1), NA),
         lgdp = ifelse(lagok, lag(gdp_cap_pwt_ln), NA),
         lpop = ifelse(lagok, lag(pop_pwt_ln), NA),
         lmil = ifelse(lagok, lag(military_c), NA),
         lmon = ifelse(lagok, lag(monarchy_c), NA),
         lpar = ifelse(lagok, lag(party_c), NA)) %>% ungroup()
cat("dup country-year:", sum(duplicated(c[,c("COUNTRY_ID","YEAR_DATA")])), "\n")
for (s in list(c(1967,2016), c(1966,2016), c(1967,2017))) {
  d <- c %>% filter(ldem==0, YEAR_DATA>=s[1], YEAR_DATA<=s[2], !is.na(replacement_rateadj_minister), !is.na(coupattempt_whogov), !is.na(lgdp), !is.na(lpop))
  cat(s, "N base", nrow(d), "countries", n_distinct(d$COUNTRY_ID), "coups", sum(d$coupattempt_whogov), "\n")
  d2 <- d %>% filter(!is.na(lmil), !is.na(lmon), !is.na(lpar)); cat(" N main", nrow(d2), n_distinct(d2$COUNTRY_ID), "\n")
}
# check whether coupattempt_whogov looks July-recoded: month distribution
print(table(c$coupattempt_month_whogov, c$coupattempt_whogov))

i <- readRDS(file.path(P,"morning_after_dataset_individuallevel.rds"))
cat("pop lag == gdp lag:", all.equal(i$pop_pwt_ln_lag, i$gdp_cap_pwt_ln_lag), "\n")
print(table(i$coupattempt_presentyear, i$coup_presentyear, useNA="a"))
print(table(i$importance_factor, i$importance_numeric, useNA="a"))
print(table(i$experience_group, i$experience))
print(table(i$minister_type, i$importance_numeric, useNA="a"))
b <- i %>% filter(democracy_lag==0, year>=1967, year<=2016, leader==0)
cat("base rows", nrow(b), "ministers", n_distinct(paste(b$country_isocode,b$name)), "countries", n_distinct(b$country_isocode), "\n")
b2 <- b %>% filter(!is.na(coupattempt_presentyear), !is.na(gdp_cap_pwt_ln_lag))
cat("with coup & gdp lag", nrow(b2), "\n")
print(table(b2$importance_factor, useNA="a"))
print(table(b2$party_group, useNA="a"))
print(table(b2$minister_type, useNA="a"))
# country-year lags constructed from individual data
cy <- i %>% distinct(country_isocode, year, gdp_cap_pwt_ln, pop_pwt_ln) %>% arrange(country_isocode, year)
cat("cy dups:", sum(duplicated(cy[,1:2])), "\n")
# compare with given gdp lag
cy <- cy %>% group_by(country_isocode) %>% mutate(lg=ifelse(lag(year)==year-1, lag(gdp_cap_pwt_ln), NA), lp=ifelse(lag(year)==year-1, lag(pop_pwt_ln), NA)) %>% ungroup()
j <- i %>% left_join(cy %>% select(country_isocode, year, lg, lp), by=c("country_isocode","year"))
cat("gdp lag matches:", mean(abs(j$lg - j$gdp_cap_pwt_ln_lag) < 1e-8, na.rm=TRUE), sum(is.na(j$lg)), sum(is.na(j$gdp_cap_pwt_ln_lag)), "\n")
bb <- j %>% filter(democracy_lag==0, year>=1967, year<=2016, leader==0, !is.na(coupattempt_presentyear), !is.na(lg), !is.na(lp))
cat("N with own lags", nrow(bb), "\n")
cat("N excl junior", sum(bb$importance_factor != levels(bb$importance_factor)[2] | is.na(bb$importance_factor)), "\n")
cat("N excl junior and NA imp", sum(!is.na(bb$importance_factor) & bb$importance_factor != levels(bb$importance_factor)[2]), "\n")
print(levels(i$importance_factor)); print(levels(i$coupattempt_presentyear))
