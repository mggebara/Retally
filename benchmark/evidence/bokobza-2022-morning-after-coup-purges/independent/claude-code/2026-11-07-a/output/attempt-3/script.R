D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-07-a/mount/bokobza_2022_morning_after_coup_purges"
suppressMessages({library(haven); library(dplyr)})
c <- zap_labels(read_dta(file.path(D,"morning_after_dataset_countrylevel.dta")))
c <- c %>% arrange(COUNTRY_ID, YEAR_DATA) %>% group_by(COUNTRY_ID) %>%
  mutate(cons = lag(YEAR_DATA)==YEAR_DATA-1,
         ldem = ifelse(cons, lag(democracy1), NA),
         lgdp = ifelse(cons, lag(gdp_cap_pwt_ln), NA),
         lpop = ifelse(cons, lag(pop_pwt_ln), NA),
         lmil = ifelse(cons, lag(military_c), NA), lmon = ifelse(cons, lag(monarchy_c), NA), lpar = ifelse(cons, lag(party_c), NA),
         early = as.integer(coupattempt_whogov==1 & coupattempt_month_whogov<=6),
         late  = as.integer(coupattempt_whogov==1 & coupattempt_month_whogov>=7),
         fca_rec = pmax(early, ifelse(cons, lag(late), 0), na.rm=FALSE)) %>% ungroup()
f <- function(d, lab) cat(lab, "N", nrow(d), "countries", length(unique(d$COUNTRY_ID)), "coupsraw", sum(d$coupattempt_whogov), "coupsrec", sum(d$fca_rec,na.rm=T), "\n")
base <- c %>% filter(ldem==0, !is.na(replacement_rateadj_minister), !is.na(lgdp), !is.na(lpop))
f(base %>% filter(!is.na(coupattempt_whogov)), "raw")
f(base %>% filter(!is.na(fca_rec)), "rec")
f(base %>% filter(!is.na(fca_rec), YEAR_DATA<=2016), "rec<=2016")
f(base %>% filter(!is.na(coupattempt_whogov), independent==1), "raw indep")
f(base %>% filter(!is.na(fca_rec), YEAR_DATA<=2016, independent==1), "rec indep")
m <- base %>% filter(!is.na(fca_rec), YEAR_DATA<=2016, !is.na(lmil))
f(m, "rec main")
x <- base %>% filter(!is.na(coupattempt_whogov), is.na(fca_rec)); print(table(x$YEAR_DATA)); print(table(x$COUNTRY_DATA))
# countries in base: which have few obs
tb <- table((base %>% filter(!is.na(coupattempt_whogov)))$COUNTRY_DATA); print(tb[tb<=3])

i <- readRDS(file.path(D,"morning_after_dataset_individuallevel.rds"))
g <- function(d, lab) cat(lab, nrow(d), "coup", sum(d$coupattempt_presentyear=="Coup attempt", na.rm=T), "countries", length(unique(d$country_isocode)), "\n")
b0 <- i %>% filter(democracy_lag==0, !is.na(coupattempt_presentyear), !is.na(gdp_cap_pwt_ln_lag), !is.na(pop_pwt_ln_lag), !is.na(purged_y1))
g(b0, "all yrs incl leader"); print(table(b0$year)[c(1:3)]); print(tail(table(b0$year),5))
g(b0 %>% filter(leader==0), "all yrs no leader")
b <- b0 %>% filter(leader==0, year>=1967, year<=2016)
g(b, "no leader 67-16")
g(b %>% filter(classification!="Minister (Junior)"), "no Minister(Junior)")
g(b %>% filter(is.na(importance_numeric) | importance_numeric!="0.5"), "no imp0.5 (keep NA)")
g(b %>% filter(!is.na(importance_numeric), importance_numeric!="0.5"), "no imp0.5 nonNA")
g(b %>% filter(!is.na(importance_numeric)), "nonNA imp")
g(b %>% filter(!is.na(importance_numeric), importance_numeric!="0"), "nonNA imp no 0")
g(b %>% filter(!is.na(party_group), party_group!="unknown"), "party known")
g(b %>% filter(!is.na(party_group)), "party nonNA")
g(b %>% filter(!is.na(minister_type)), "mtype")
g(b %>% filter(!is.na(minister_type), importance_numeric!="0.5"), "mtype no junior")
print(table(b$classification[b$importance_numeric=="0.5"]))
print(table(b$importance_numeric[is.na(b$minister_type)], useNA="ifany"))
print(table(b$experience_group))
