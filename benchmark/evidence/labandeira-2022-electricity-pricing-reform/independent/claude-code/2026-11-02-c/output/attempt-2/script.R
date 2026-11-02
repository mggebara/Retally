# Exploratory: sample construction checks. No RESULT lines.
suppressMessages({library(haven); library(dplyr)})
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-02-c/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
d <- read_dta(f, col_select = c(T2,dup,time,month,id,year,BIS,BISEMANA,trim,dist,Tm,lnc_ele,lng_ele,lnp_kwh,lny,lny2,y,lny_ad,
  NMIEMB,NHABIT,SUPERF,mayores,mayores_count,iestud1,iestud2,iestud3,iestud4,isitu1,isitu2,isitu3,SITUACTHOG_j,alqui,edif25,
  itam1,itam2,itam3,itam4,itam5,urban,CAPROV,CCAA,PENSIO,PENSIO_j,lnp_papas,lnp_aguav,lnp_gascar,lnPRE,lnPRE_papas,lnPRE_aguav,lnPRE_gascar,
  lnPRE_papas_,lnPRE_aguav_,lnPRE_gascar_,lnaPRE_papas,IP,FACTOR,TT199,TT202,p_kwh,c_ele,g_ele,ESTUDREDSP,TAMAMU,idensi1))
d <- zap_labels(d)
s <- d %>% filter(!is.na(T2))
cat("sample rows", nrow(s), " ids", n_distinct(s$id), "\n")
print(table(s$year, s$month, useNA="ifany"))
print(table(s$T2, s$dist, useNA="ifany"))
print(table(s$Tm, s$T2, useNA="ifany"))
print(table(s$dup, s$year))
cat("lny vs log(y):\n"); print(summary(s$lny - log(s$y))); print(summary(s$lny2 - s$lny^2)); print(summary(s$lny_ad - log(s$y)))
print(head(cbind(s$y, s$lny, s$lny2, s$lny_ad), 10))
cat("price checks\n"); print(summary(s$lnPRE - (s$lnp_kwh - s$IP))); print(summary(s$p_kwh)); print(summary(s$c_ele)); print(summary(s$g_ele))
print(summary(exp(s$lng_ele)/exp(s$lnc_ele) - s$p_kwh))
nas <- sapply(s, function(x) sum(is.na(x))); print(nas[nas>0])
base <- c("lnc_ele","lng_ele","lnp_kwh","lny","lny2","T2","dist","NMIEMB","NHABIT","SUPERF","mayores","iestud1","isitu1","alqui","edif25","itam1","urban","CAPROV","CCAA","trim","year")
cc <- function(v) sum(complete.cases(s[, v]))
cat("base", cc(base), "\n")
cat("base - mayores", cc(setdiff(base,"mayores")), "\n")
cat("base + 3 raw inst", cc(c(base,"lnp_papas","lnp_aguav","lnp_gascar")), "\n")
cat("base + 3 PRE_ inst", cc(c(base,"lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_")), "\n")
cat("base + PENSIO_j", cc(c(base,"PENSIO_j")), "\n")
cat("base + SITUACTHOG_j", cc(c(base,"SITUACTHOG_j")), "\n")
cat("base + ESTUDREDSP", cc(c(base,"ESTUDREDSP")), "\n")
for (v in base) cat(v, cc(setdiff(base, v)), "\n")
ss <- s[complete.cases(s[, base]),]
cat("ids in base cc", n_distinct(ss$id), "\n"); print(table(table(ss$id)))
print(table(table(s$id)))
print(table(s$SITUACTHOG_j, s$isitu1, useNA="ifany")); print(table(s$ESTUDREDSP, s$iestud1, useNA="ifany"))
print(table(s$mayores, s$mayores_count, useNA="ifany"))
