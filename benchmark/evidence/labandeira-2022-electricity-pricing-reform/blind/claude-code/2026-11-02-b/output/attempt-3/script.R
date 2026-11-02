library(haven); library(dplyr)
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/blind/2026-11-02-b/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
keep <- c("T2","dup","time","month","id","year","BIS","c_ele","g_ele","p_kwh","lnp_kwh","lnc_ele","lng_ele","lny","lny2","y","IP",
 "dist","Tm","TT199","TT202","trim","lnPRE","lnPRE_papas","lnPRE_aguav","lnPRE_gascar","lnaPRE_papas","lnaPRE_aguav","lnaPRE_gascar",
 "lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_","lnp_papas","lnp_aguav","lnp_gascar",
 "edif25","urban","mayores","CAPROV","REGTEN","NHABIT","SUPERF","NMIEMB","ESTUDREDSP","SITUACTHOG_j","SITUACTHOG","TAMAMU","CCAA","alqui","PENSIO_j","NUMACTI","DENSI")
d <- zap_labels(read_dta(f, col_select = all_of(keep)))
s <- d %>% filter(!is.na(T2))
cat("T2 sample", nrow(s), " ids", n_distinct(s$id), "\n")
print(table(table(s$id)))
cat("check lnp_kwh vs log(g/c):", max(abs(s$lnp_kwh - log(s$g_ele/s$c_ele))), "\n")
cat("check lnPRE - lnp_kwh + IP:", summary(s$lnPRE - s$lnp_kwh + s$IP), "\n")
cat("check lny - log(y) + IP:", summary(s$lny - log(s$y) + s$IP), "\n")
cat("check lny2 - lny^2:", summary(s$lny2 - s$lny^2), "\n")
cat("check lnPRE_papas - lnp_papas + IP:", summary(s$lnPRE_papas - s$lnp_papas + s$IP), "\n")
cat("check lnc_ele - log(c_ele):", summary(s$lnc_ele - log(s$c_ele)), "\n")
cat("check lng_ele - log(g_ele):", summary(s$lng_ele - log(s$g_ele)), "\n")
for (v in c("papas","aguav","gascar")) {
  a <- s[[paste0("lnPRE_",v)]]; b <- s[[paste0("lnPRE_",v,"_")]]; m <- s[[paste0("lnaPRE_",v)]]
  cat(v, " nonNA equal:", max(abs(a-b),na.rm=T), " NA count", sum(is.na(a)), " underscore==avg where NA:", max(abs(b[is.na(a)]-m[is.na(a)])), "\n")
  # is lnaPRE constant within time?
  cat("  lnaPRE sd within time:", s %>% group_by(time) %>% summarise(sd=sd(.data[[paste0("lnaPRE_",v)]])) %>% pull(sd) %>% max(na.rm=T),
      " within time x CCAA:", s %>% group_by(time,CCAA) %>% summarise(sd=sd(.data[[paste0("lnaPRE_",v)]]), .groups="drop") %>% pull(sd) %>% max(na.rm=T), "\n")
}
cat("NA counts in T2 sample\n"); print(sapply(s, function(x) sum(is.na(x))))
print(table(s$SITUACTHOG_j, s$SITUACTHOG, useNA="ifany"))
print(table(s$SITUACTHOG_j, s$NUMACTI, useNA="ifany"))
print(table(s$T2, s$Tm)); print(table(s$T2, s$year))
print(table(s$Tm, s$year))
print(table(s$dist, s$T2))
cat("NHABIT\n"); print(table(s$NHABIT, useNA="ifany"))
