library(haven); library(data.table)
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/blind/2026-11-02-c/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
keep <- c("T2","dup","time","month","id","year","BIS","BISEMANA","ANOENC","c_ele","g_ele","p_kwh","lnc_ele","lng_ele","lnp_kwh",
  "lny","lny2","y","yh","IMPEXAC","lny_ad","NMIEMB","NHABIT","SUPERF","mayores","ESTUDREDSP","SITUACTHOG_j","alqui","edif25","TAMAMU","urban","CAPROV","CCAA","trim",
  "dist","Tm","PENSIO","PENSIO_j","lnp_papas","lnp_aguav","lnp_gascar","lnPRE","lnPRE_papas","lnPRE_aguav","lnPRE_gascar",
  "lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_","lnaPRE_papas","IP","TT199","TT202","FACTOR")
d <- as.data.table(read_dta(f, col_select = all_of(keep)))
s <- d[!is.na(T2)]
cat("rows", nrow(s), "ids", uniqueN(s$id), "\n")
print(table(s$year, s$T2, useNA="ifany"))
print(table(s$dup, useNA="ifany"))
print(table(s$year, s$month, useNA="ifany"))
print(table(s$dist, s$T2, useNA="ifany"))
print(table(s$Tm, s$T2, useNA="ifany"))
print(table(table(s$id)))
for (v in names(s)) cat(sprintf("%-14s NA=%d mean=%.4g sd=%.4g min=%.4g max=%.4g\n", v, sum(is.na(s[[v]])), mean(s[[v]],na.rm=T), sd(s[[v]],na.rm=T), min(s[[v]],na.rm=T), max(s[[v]],na.rm=T)))
cat("check lny==log(y):", summary(s$lny - log(s$y)), "\n")
cat("check lny2==lny^2:", summary(s$lny2 - s$lny^2), "\n")
cat("check lnp_kwh==log(g/c):", summary(s$lnp_kwh - log(s$g_ele/s$c_ele)), "\n")
cat("check lnPRE-lnp_kwh+IP:", summary(s$lnPRE - s$lnp_kwh + s$IP), "\n")
cat("check lnPRE_papas_ vs lnPRE_papas:", summary(s$lnPRE_papas_ - s$lnPRE_papas), "\n")
# D group: id with any T2==1
s[, D := as.integer(max(T2)==1), by=id]
print(table(s$D, s$T2))
print(s[, .(n=.N, minyr=min(year), maxyr=max(year)), by=.(D)][order(D)])
# within-id: same BIS?
cat("BIS const within id:", s[, uniqueN(BIS), by=id][, table(V1)], "\n")
print(table(s$TT199, s$T2, useNA="ifany"))
print(table(s$TT202, s$T2, useNA="ifany"))
print(quantile(s$lny, c(0,.01,.05,.5,.95,1), na.rm=T))
print(s[, .(lny=mean(lny,na.rm=T)), by=year])
