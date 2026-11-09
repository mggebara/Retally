suppressMessages(library(data.table))
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-07-a/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/Data_to run_DOFILE3.csv"
v <- c("T2","dup","time","id","year","BISEMANA","c_ele","g_ele","lnc_ele","lng_ele","lnp_kwh","lny","y","lny_ad","y_ad","IMPEXAC","lnp_papas","lnp_aguav","lnp_gascar","lnPRE","lnPRE_papas","lnPRE_aguav","lnPRE_gascar","lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_","lnaPRE_papas","dist","Tm","trim","mayores","mayores_count","alqui","edif25","urban","CAPROV","NHABIT","SUPERF","NMIEMB","PENSIO_j","SITUACTHOG_j","SITSOCIRE_j","TAMAMU","CCAA","ESTUDREDSP","IP","g_papas","c_papas","g_aguav","c_aguav","g_car","c_car")
d <- fread(f, select=v)
d <- d[!is.na(T2)]
cat("rows", nrow(d), "ids", uniqueN(d$id), "\n")
for (x in v) { z <- d[[x]]; cat(sprintf("%-14s nNA=%6d  min=%g mean=%g max=%g nuniq=%d\n", x, sum(is.na(z)), min(z,na.rm=T), mean(z,na.rm=T), max(z,na.rm=T), length(unique(z)))) }
cat("check lnp = lng - lnc:", max(abs(d$lnp_kwh - (d$lng_ele - d$lnc_ele))), "\n")
cat("check lny vs log(y):", summary(d$lny - log(d$y)), "\n")
cat("check lny vs log(y/12):", summary(d$lny - log(d$y/12)), "\n")
cat("check lnPRE vs lnp-IP:", summary(d$lnPRE - (d$lnp_kwh - d$IP)), "\n")
cat("check lnp_papas vs log(g/c):", summary(d$lnp_papas - log(d$g_papas/d$c_papas)), "\n")
base <- c("lnc_ele","lng_ele","lnp_kwh","lny","dist","T2","year","trim","NMIEMB","NHABIT","SUPERF","alqui","edif25","urban","CAPROV","TAMAMU","CCAA","ESTUDREDSP")
cc <- function(vars) { k <- complete.cases(d[, ..vars]); sprintf("N=%d ids=%d", sum(k), uniqueN(d$id[k])) }
cat("base:", cc(base), "\n")
for (extra in list("mayores","SITUACTHOG_j","SITSOCIRE_j","PENSIO_j", c("mayores","SITUACTHOG_j"), c("mayores","SITUACTHOG_j","PENSIO_j"), c("mayores","SITSOCIRE_j","PENSIO_j"))) cat(paste(extra,collapse="+"), cc(c(base,extra)), "\n")
ivs <- c("lnp_papas","lnp_aguav","lnp_gascar")
cat("base+iv:", cc(c(base,ivs)), "\n")
for (extra in list("mayores","SITUACTHOG_j", c("mayores","SITUACTHOG_j"), c("mayores","SITUACTHOG_j","PENSIO_j"),c("mayores","SITSOCIRE_j"))) cat("iv+",paste(extra,collapse="+"), cc(c(base,ivs,extra)), "\n")
ivs2 <- c("lnPRE_papas","lnPRE_aguav","lnPRE_gascar")
cat("base+ivPRE:", cc(c(base,ivs2)), "\n")
print(table(d$SITUACTHOG_j, useNA="ifany")); print(table(d$SITSOCIRE_j, useNA="ifany")); print(table(d$mayores, useNA="ifany"))
print(table(d$dup, d$year))
