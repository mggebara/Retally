suppressMessages({library(haven); library(data.table)})
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-02-b/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
d <- as.data.table(read_dta(f))
s <- d[!is.na(T2)]
cat("N T2 sample:", nrow(s), " ids:", uniqueN(s$id), "\n")
vars <- c("lnc_ele","lng_ele","lnp_kwh","lny","lny2","T2","dist","Tm","NMIEMB","NHABIT","SUPERF","mayores","mayores_count","ESTUDREDSP","SITUACTHOG_j","SITSOCIRE_j","PENSIO_j","alqui","edif25","TAMAMU","urban","CAPROV","CCAA","trim","lnPRE_papas","lnPRE_aguav","lnPRE_gascar","lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_","lnaPRE_papas","TT199","TT202","isitu1","lnc_ele_ad","lnc_ELE","lny_ad","we","LnPRE_M","lnPRE")
for (v in vars) cat(v, "NA=", sum(is.na(s[[v]])), " mean=", mean(s[[v]], na.rm=TRUE), "\n")
print(table(s$year, s$dup)); print(table(s$dist, s$T2, useNA="ifany")); print(table(s$Tm, s$T2, useNA="ifany"))
cat("obs per id:\n"); print(table(table(s$id)))
cc <- function(v) { k <- complete.cases(s[, ..v]); cat(paste(v, collapse=" "), "\n  N=", sum(k), " ids=", uniqueN(s$id[k]), "\n") }
base <- c("lnc_ele","lnp_kwh","lny","lny2","T2","dist","NMIEMB","NHABIT","SUPERF","ESTUDREDSP","alqui","edif25","TAMAMU","urban","CAPROV","CCAA","trim")
cc(base); cc(c(base,"mayores")); cc(c(base,"SITUACTHOG_j")); cc(c(base,"mayores","SITUACTHOG_j")); cc(c(base,"mayores","SITUACTHOG_j","PENSIO_j"))
cc(c(base,"mayores","SITUACTHOG_j","lnPRE_papas","lnPRE_aguav","lnPRE_gascar"))
cc(c(base,"lnPRE_papas","lnPRE_aguav","lnPRE_gascar"))
cc(c(base,"mayores","SITUACTHOG_j","PENSIO_j","SITSOCIRE_j"))
cc(c(base,"TT199")); cc(c(base,"TT202"))
print(summary(s[, .(c_ele, g_ele, p_kwh, y)]))
print(table(s$SITUACTHOG_j, useNA="ifany")); print(table(s$SITUACTHOG, useNA="ifany"))
print(head(s[, .(id, year, month, BIS, T2, Tm, dist, dup, time)], 20))
