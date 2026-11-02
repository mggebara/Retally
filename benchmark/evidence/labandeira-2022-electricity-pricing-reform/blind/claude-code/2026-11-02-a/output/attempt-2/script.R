suppressPackageStartupMessages({library(haven); library(data.table)})
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/blind/2026-11-02-a/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
vars <- c("T2","id","year","month","trim","dist","Tm","lnp_kwh","lnPRE","lnc_ele","lng_ele","lny","lny2","lny_ad",
 "lnp_papas","lnp_aguav","lnp_gascar","lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_","IP",
 "NMIEMB","NHABIT","SUPERF","mayores","mayores_count","alqui","edif25","urban","CAPROP","TAMAMU","ESTUDREDSP","SITUACTHOG_j","CCAA","PENSIO_j","DENSI","EDADSP")
d <- as.data.table(read_dta(f, col_select = any_of(vars)))
d <- d[!is.na(T2)]
cat("rows", nrow(d), " ids", uniqueN(d$id), "\n")
print(table(table(d$id)))
cat("NA counts in T2 sample:\n"); print(sapply(d, function(x) sum(is.na(x))))
cat("CAPROP:\n"); print(table(d$CAPROP, useNA="ifany"))
cat("TAMAMU:\n"); print(table(d$TAMAMU, useNA="ifany"))
cat("SITUACTHOG_j:\n"); print(table(d$SITUACTHOG_j, useNA="ifany"))
cat("mayores:\n"); print(table(d$mayores, useNA="ifany"))
cat("urban:\n"); print(table(d$urban, useNA="ifany")); cat("edif25:\n"); print(table(d$edif25, useNA="ifany"))
cat("max|lny2-lny^2|:", max(abs(d$lny2 - d$lny^2), na.rm=TRUE), "\n")
cat("lny quantiles:\n"); print(quantile(d$lny, c(0,.01,.5,.99,1), na.rm=TRUE))
cat("max|lnPRE-(lnp_kwh-IP)|:", max(abs(d$lnPRE-(d$lnp_kwh-d$IP))), "\n")
cat("cor lnp_papas lnPRE_papas_+IP when nonmissing:", cor(d$lnp_papas, d$lnPRE_papas_+d$IP, use="complete.obs"),
    " maxdiff:", max(abs(d$lnp_papas-(d$lnPRE_papas_+d$IP)), na.rm=TRUE), "\n")
cat("year x T2\n"); print(table(d$year, d$T2))
cat("year x Tm\n"); print(table(d$year, d$Tm))
cat("trim x year\n"); print(table(d$trim, d$year))
cat("IP by year:\n"); print(d[, .(nIP=uniqueN(IP), mn=min(IP), mx=max(IP)), by=year])
