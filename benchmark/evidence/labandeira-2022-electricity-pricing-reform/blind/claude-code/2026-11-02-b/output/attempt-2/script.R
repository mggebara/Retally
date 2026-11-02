library(haven); library(dplyr)
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/blind/2026-11-02-b/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
keep <- c("T2","dup","time","month","id","year","BIS","BISEMANA","ANOENC","c_ele","c_ele2","c_ELE","g_ele","g_ele2","g_ELE",
 "p_kwh","lnp_kwh","lnc_ELE","lnc_ele","lng_ele","lnc_elem","lng_elem","c_elem","g_elem","lny","lny2","y","yh","lny_ad",
 "dist","Tm","TT199","TT202","trim","lnPRE","lnPRE_papas","lnPRE_aguav","lnPRE_gascar","lnaPRE_papas","lnaPRE_aguav","lnaPRE_gascar",
 "lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_","lnp_papas","lnp_aguav","lnp_gascar","p_papas","p_aguav","p_gascar",
 "edif25","urban","mayores","CAPROV","REGTEN","NHABIT","SUPERF","NMIEMB","ESTUDREDSP","SITUACTHOG_j","TAMAMU","CCAA","alqui","PENSIO_j","_merge","we","IP","LnPRE_M")
d <- read_dta(f, col_select = all_of(keep))
cat("rows", nrow(d), "\n")
print(table(d$year))
d <- zap_labels(d)
s <- d %>% filter(year >= 2011, year <= 2014)
cat("rows 2011-14", nrow(s), "\n")
for (v in c("T2","dup","Tm","TT199","TT202","trim","_merge","REGTEN","alqui","PENSIO_j","ESTUDREDSP","SITUACTHOG_j","TAMAMU","edif25","urban","mayores","CAPROV")) {
  cat("==", v, "\n"); print(table(s[[v]], useNA="ifany"))
}
print(summary(s[, setdiff(keep, c("T2","dup","Tm","TT199","TT202","trim","_merge"))]))
cat("== year x month\n"); print(table(s$year, s$month))
cat("== year x dup\n"); print(table(s$year, s$dup, useNA="ifany"))
cat("== dist by year-month\n"); print(s %>% group_by(year, month) %>% summarise(n=n(), dmin=min(dist,na.rm=T), dmax=max(dist,na.rm=T), T2=mean(T2,na.rm=T), Tm=mean(Tm,na.rm=T), TT199=mean(TT199,na.rm=T), TT202=mean(TT202,na.rm=T), nlnc=sum(!is.na(lnc_ELE)), npr=sum(!is.na(lnPRE_papas)), .groups="drop"), n=100)
cat("ids per id count\n"); print(table(table(s$id)))
