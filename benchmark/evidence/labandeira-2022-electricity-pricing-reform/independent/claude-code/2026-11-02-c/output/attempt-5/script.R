# Exploratory: structure of IP, dist, instruments. No RESULT lines, no estimates of listed quantities.
suppressMessages({library(haven); library(dplyr)})
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-02-c/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
d <- zap_labels(read_dta(f, col_select = c(T2,id,year,month,BIS,time,trim,dist,Tm,TT199,TT202,IP,CCAA,lnp_kwh,lnPRE,LnPRE_M,
  lnp_papas,lnp_aguav,lnp_gascar,lnPRE_papas,lnPRE_papas_,lnaPRE_papas,lnaPRE_aguav,lnaPRE_gascar,lnPRE_aguav_,lnPRE_gascar_,we,
  i00,i01,i02,i03,i04,i05,lni04,lni05,dup,ANOENC)))
s <- d %>% filter(!is.na(T2))
cat("IP by year x trim (mean, sd)\n")
print(s %>% group_by(year, trim) %>% summarise(n=n(), IPm=mean(IP), IPsd=sd(IP), IPmin=min(IP), IPmax=max(IP), .groups="drop"), n=50)
cat("IP by CCAA within 2012 q1\n"); print(s %>% filter(year==2012, trim==1) %>% group_by(CCAA) %>% summarise(m=mean(IP), sd=sd(IP)), n=30)
cat("IP vs i0x\n"); print(summary(lm(IP ~ i04 + i05 + lni04 + lni05, data=s)))
cat("lnaPRE_papas by year/trim/ccaa variation\n")
print(summary(lm(lnaPRE_papas ~ factor(year)*factor(trim) + factor(CCAA), data=s))$r.squared)
print(summary(lm(lnaPRE_papas ~ IP, data=s))$r.squared)
print(summary(lm(lnPRE_papas_ ~ IP, data=s))$r.squared)
print(summary(lm(lnPRE ~ IP, data=s))$r.squared)
print(summary(lm(LnPRE_M ~ lnPRE, data=s)))
print(cor(s[,c("lnPRE","lnp_kwh","IP","lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_","lnaPRE_papas","lnaPRE_aguav","lnaPRE_gascar","LnPRE_M")], use="pairwise"))
cat("dist by year-month for treated\n"); print(table(paste(s$year, s$month), s$dist)[, ])
cat("TT199/TT202 vs T2\n"); print(table(s$TT199, s$T2, useNA="ifany")); print(table(s$TT202, s$T2, useNA="ifany"))
print(table(s$we > 0)); print(summary(s$we))
print(table(s$ANOENC, s$year))
