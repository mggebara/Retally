suppressPackageStartupMessages({library(haven); library(data.table)})
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/blind/2026-11-02-a/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
vars <- c("T2","dup","time","month","id","year","BIS","BISEMANA","ANOENC","trim","dist","Tm","TT199","TT202",
 "lnp_kwh","lnc_ele","lnc_ELE","lng_ele","lny","lny2","lnc_ele_ad","lny_ad","p_kwh","c_ele","c_ELE","g_ele","g_ELE",
 "lnp_papas","lnp_aguav","lnp_gascar","lnPRE_papas","lnPRE_aguav","lnPRE_gascar","lnaPRE_papas","lnaPRE_aguav","lnaPRE_gascar",
 "lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_","we","IP","lnPRE","_merge","NMIEMB","NHABIT","SUPERF","mayores","alqui","edif25","urban","CAPROP","TAMAMU","ESTUDREDSP","SITUACTHOG_j","CCAA","iestud1","isitu1","itam1","idensi1","DENSI","PENSIO_j","FACTOR")
d <- as.data.table(read_dta(f, col_select = any_of(vars)))
print(dim(d))
for (v in names(d)) { x <- d[[v]]; lab <- attr(x,"label"); cat(sprintf("%-14s %-40s ", v, substr(ifelse(is.null(lab),"",lab),1,40)));
  if (is.numeric(x)) cat(sprintf("n=%d na=%d mean=%.4g min=%.4g max=%.4g nuniq=%d\n", length(x), sum(is.na(x)), mean(x,na.rm=T), min(x,na.rm=T), max(x,na.rm=T), length(unique(x)))) else cat(class(x), "\n") }
cat("\nyear x T2\n"); print(table(d$year, d$T2, useNA="ifany"))
cat("\nyear x TT199\n"); print(table(d$year, d$TT199, useNA="ifany"))
cat("\nyear x TT202\n"); print(table(d$year, d$TT202, useNA="ifany"))
cat("\nyear x dup\n"); print(table(d$year, d$dup, useNA="ifany"))
cat("\ntime range by year\n"); print(d[, .(mn=min(time,na.rm=T), mx=max(time,na.rm=T), mmin=min(month,na.rm=T), mmax=max(month,na.rm=T)), by=year][order(year)])
cat("\ndist by year/month (2012-2014)\n"); print(d[year %in% 2011:2014, .N, by=.(year,month,dist,Tm,TT199,TT202,T2)][order(year,month)], nrows=500)
cat("\nids per id count\n"); print(table(d[, .N, by=id]$N))
cat("\nhead\n"); print(head(d[year==2013, .(id,year,ANOENC,BIS,BISEMANA,month,time,trim,dist,Tm,T2,TT199,TT202,dup)],20))
