library(haven); library(data.table)
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-02-a/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
cols <- c("T2","dup","time","month","id","year","BIS","ANOENC","lnc_ele","lng_ele","lnp_kwh","lnPRE","lny","lny2","lny_ad","dist","Tm","mayores","mayores_count",
          "lnPRE_papas","lnPRE_aguav","lnPRE_gascar","lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_","lnp_papas","lnp_aguav","lnp_gascar",
          "NMIEMB","NHABIT","SUPERF","edif25","alqui","REGTEN","urban","CAPROV","TAMAMU","CCAA","ESTUDREDSP","SITUACTHOG_j","trim","IP","we","TT199","TT202","c_ele","g_ele","_merge")
d <- as.data.table(read_dta(f, col_select = all_of(cols)))
cat("all rows", nrow(d), "\n"); print(table(d$year, useNA="ifany"))
for (v in c("T2","dup","dist","Tm","IP","TT199","TT202","_merge")) { cat("==", v, "\n"); print(table(d[[v]], d$year, useNA="ifany")) }
s <- d[year >= 2011 & year <= 2014]
cat("2011-14 rows", nrow(s), " ids", uniqueN(s$id), "\n")
print(s[, .N, by=.(year, month)][order(year, month)])
cat("dup by T2\n"); print(table(s$dup, s$T2, useNA="ifany"))
cat("Tm by dist\n"); print(table(s$dist, s$Tm, useNA="ifany"))
print(summary(s[, .(lnc_ele, lng_ele, lnp_kwh, lnPRE, lny, lny2, lnPRE_papas, lnPRE_aguav, lnPRE_gascar, lnPRE_papas_, lnPRE_aguav_, lnPRE_gascar_, NMIEMB, NHABIT, SUPERF, edif25, alqui, mayores, mayores_count, we)]))
cat("lny2 vs lny^2:", s[, cor(lny2, lny^2, use="c")], " max diff ", s[, max(abs(lny2-lny^2), na.rm=T)], "\n")
cat("lnPRE==lnp_kwh:", s[, max(abs(lnPRE-lnp_kwh), na.rm=T)], "\n")
# households observed twice
s[, nobs := .N, by=id]; print(table(s$nobs))
print(table(s$REGTEN, useNA="ifany")); print(table(s$ESTUDREDSP, useNA="ifany")); print(table(s$SITUACTHOG_j, useNA="ifany"))
# window Aug 2011 - Apr 2014
s[, ym := year*100+month]
print(table(s$T2, s$ym, useNA="ifany"))
