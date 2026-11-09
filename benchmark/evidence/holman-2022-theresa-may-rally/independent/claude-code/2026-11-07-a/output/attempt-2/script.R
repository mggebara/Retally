library(haven); library(dplyr); library(fixest)
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-07-a/mount/holman_2022_theresa_may_rally"
g <- zap_labels(read_dta(file.path(D,"global_approval.dta")))
print(table(g$execrlc, useNA="ifany"))
print(table(g$kill_16, g$female_pres, useNA="ifany"))
print(table(g$manchester, g$female_pres, useNA="ifany"))
print(g %>% filter(kill_16==1, female_pres==1) %>% select(country, qtr, lag_approval, kill_16, rally_kill), n=20)
g <- g %>% arrange(country_code, qtr) %>% group_by(country_code) %>%
  mutate(gap = qtr - lag(qtr), F1 = ifelse(lead(qtr)==qtr+1, lead(lag_approval), NA),
         F2 = ifelse(lead(qtr,2)==qtr+2, lead(lag_approval,2), NA),
         L1k = ifelse(lag(qtr)==qtr-1, lag(kill_16), NA)) %>% ungroup()
print(table(g$gap, useNA="ifany"))
print(length(unique(g$country_code))); print(length(unique(g$country)))
print(g %>% filter(country=="United Kingdom", qtr>=225) %>% select(qtr, lag_approval, kill_16, manchester, female_pres, growth), n=20)
ctrl <- "female_pres + growth + log_inflation + execrlc + election_qtr"
for (dv in c("lag_approval","F1","F2")) for (tr in c("kill_16","L1k")) {
  f <- as.formula(paste(dv, "~", tr, "*female_pres +", ctrl, "| country_code"))
  m <- feols(f, data=g)
  cat(dv, tr, "N=", nobs(m), "\n"); print(coef(m)[c(1,length(coef(m)))])
  f2 <- as.formula(paste(dv, "~", tr, "*female_pres + growth + log_inflation + i(execrlc) + election_qtr | country_code"))
  m2 <- feols(f2, data=g); cat(" factor execrlc N=", nobs(m2), "\n"); print(coef(m2)[c(1,length(coef(m2)))])
}
dd <- zap_labels(read_dta(file.path(D,"did_data.dta"), col_select=c(wave,time,treatment1,likeMayW,bestPMW,may_bestpm,white,gender,labour,party_other,income,ideology,ideology2,ideo3,conservative,id)))
print(table(dd$wave, dd$bestPMW, useNA="ifany"))
for (ideo in c("ideology","ideology2","ideo3")) {
 cc <- complete.cases(dd[,c("likeMayW","treatment1","time","white","gender","labour","party_other","income",ideo)])
 cat(ideo, "like N", sum(cc), "\n"); print(table(dd$wave[cc]))
 cc <- complete.cases(dd[,c("bestPMW","treatment1","time","white","gender","labour","party_other","income",ideo)])
 cat(ideo, "bestPM N", sum(cc), "\n"); print(table(dd$wave[cc]))
}
