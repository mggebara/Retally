suppressMessages(library(data.table))
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-07-a/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/Data_to run_DOFILE3.csv"
v <- c("T2","dup","time","month","id","year","BIS","BISEMANA","ANOENC","c_ele","g_ele","c_ELE","g_ELE","lnc_ele","lnc_ELE","lng_ele","lnp_kwh","p_kwh","lny","y","lnp_papas","lnp_aguav","lnp_gascar","lnPRE","lnPRE_papas","lnPRE_aguav","lnPRE_gascar","lnaPRE_papas","lnPRE_papas_","dist","Tm","trim","TT199","TT202","mayores","alqui","edif25","urban","CAPROV","NHABIT","SUPERF","NMIEMB","PENSIO_j","SITUACTHOG_j","TAMAMU","CCAA","ESTUDREDSP","DENSI","_merge","we","IP","LnPRE_M")
d <- fread(f, select=v)
cat(dim(d),"\n")
print(d[, .N, by=year][order(year)])
for (x in v) { z <- d[[x]]; cat(sprintf("%-14s nNA=%7d  ", x, sum(is.na(z)))); if (is.numeric(z)) cat(sprintf("min=%g mean=%g max=%g nuniq=%d", min(z,na.rm=T), mean(z,na.rm=T), max(z,na.rm=T), length(unique(z)))); cat("\n") }
print(d[, .N, by=.(T2,dup)])
print(d[!is.na(T2), .N, by=.(year,T2,Tm)][order(year,T2,Tm)])
print(d[!is.na(T2), .N, by=.(time)][order(time)])
print(head(d[!is.na(T2), .(id,year,month,time,BISEMANA,T2,Tm,dist,TT199,TT202,trim)],30))
print(d[!is.na(T2), table(dist, Tm, useNA="ifany")])
