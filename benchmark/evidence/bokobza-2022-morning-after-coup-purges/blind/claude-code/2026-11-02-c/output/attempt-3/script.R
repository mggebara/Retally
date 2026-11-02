suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-c/mount/bokobza_2022_morning_after_coup_purges"
c <- read_dta(file.path(D,"morning_after_dataset_countrylevel.dta"))
c <- c %>% arrange(COUNTRY_ID, YEAR_DATA) %>% group_by(COUNTRY_ID) %>%
  mutate(ok = dplyr::lag(YEAR_DATA)==YEAR_DATA-1,
         ldem = ifelse(ok, dplyr::lag(democracy1), NA),
         lgdp = ifelse(ok, dplyr::lag(gdp_cap_pwt_ln), NA),
         lpop = ifelse(ok, dplyr::lag(pop_pwt_ln), NA),
         lmil = ifelse(ok, dplyr::lag(military_c), NA),
         lmon = ifelse(ok, dplyr::lag(monarchy_c), NA),
         lpar = ifelse(ok, dplyr::lag(party_c), NA)) %>% ungroup()
cat("dup country-years:", sum(duplicated(c[,c("COUNTRY_ID","YEAR_DATA")])), "\n")
f <- function(d, lab) cat(lab, "N=", nrow(d), " countries=", n_distinct(d$COUNTRY_ID), " leaders=", n_distinct(d$leader_cab_id), " coups=", sum(d$coupattempt_whogov), "\n")
b <- c %>% filter(!is.na(replacement_rateadj_minister), !is.na(coupattempt_whogov), !is.na(lgdp), !is.na(lpop))
f(b %>% filter(ldem==0, YEAR_DATA %in% 1967:2016), "ldem==0 67-16")
f(b %>% filter(ldem==0, YEAR_DATA %in% 1967:2016, !is.na(leader_cab_id)), "  +leader nonNA")
f(b %>% filter(ldem==0, YEAR_DATA %in% 1967:2016, independent==1), "  +independent")
f(b %>% filter(ldem==0, YEAR_DATA %in% 1967:2016, !is.na(lmil), !is.na(lmon), !is.na(lpar)), "  main")
bb <- b %>% filter(ldem==0, YEAR_DATA %in% 1967:2016)
sing <- bb %>% count(COUNTRY_ID) %>% filter(n==1); cat("country singletons:", nrow(sing), "\n")
lsing <- bb %>% count(leader_cab_id) %>% filter(n==1); cat("leader singletons:", nrow(lsing), " N after:", nrow(bb)-nrow(lsing), "\n")
print(bb %>% count(COUNTRY_DATA) %>% arrange(n) %>% head(8))
print(table(bb$YEAR_DATA))
i <- readRDS(file.path(D,"morning_after_dataset_individuallevel.rds"))
g <- function(d, lab) cat(lab, "N=", nrow(d), " countries=", n_distinct(d$country_isocode), "\n")
i <- i %>% filter(year %in% 1967:2016, !is.na(gdp_cap_pwt_ln_lag), !is.na(pop_pwt_ln_lag), !is.na(coupattempt_presentyear), !is.na(purged_y1))
for (dem in c("dl0","dlbr","dl0orNAbr")) {
  a <- switch(dem, dl0 = i %>% filter(democracy_lag==0), dlbr = i %>% filter(democracy_lag_br=="Autocracy"),
              dl0orNAbr = i %>% filter(democracy_lag==0 | (is.na(democracy_lag) & democracy_lag_br=="Autocracy")))
  cat("=== ", dem, "\n")
  g(a, "all"); g(a %>% filter(leader==0), "nonleader")
  g(a %>% filter(leader==0, importance_numeric != "0.5" | is.na(importance_numeric)), "exp: nonleader nonjunior(keepNA)")
  g(a %>% filter(leader==0, importance_numeric != "0.5"), "exp: nonleader nonjunior(dropNA)")
  g(a %>% filter(importance_numeric != "0.5" | is.na(importance_numeric)), "exp: nonjunior incl leader")
  g(a %>% filter(leader==0, party_group %in% c("independent","leader_party","other_party")), "aff")
  g(a %>% filter(leader==0, !is.na(minister_type)), "resp")
  g(a %>% filter(leader==0, importance_numeric %in% c("0.5","1","2","3","4")), "imp")
}
