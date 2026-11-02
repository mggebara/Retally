# Exploratory: timing of haven col_select read of the big .dta (no RESULT lines)
library(haven)
D <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data"
t0 <- Sys.time()
m <- read_dta(file.path(D,"Working/pisa_full_gps_final_imcoo.dta"), col_select=c(pv1math,coo_patience,coo_risktaking,coo_posrecip,coo_negrecip,coo_altruism,coo_trust,female,age,imfemale,image,coo_oecd,countrywave,coo,wave))
message("imcoo read secs ", round(as.numeric(difftime(Sys.time(),t0,units="secs")),1))
print(dim(m)); print(summary(m)); print(table(m$wave))
t0 <- Sys.time()
x <- read_dta(file.path(D,"Working/pisa_full_gps_final.dta"),
  col_select=c(pv1math,patience,risktaking,female,age,migra0,migra1,migra2,image,imfemale,immigra1,wave,wgtc,country))
message("big read secs ", round(as.numeric(difftime(Sys.time(),t0,units="secs")),1))
print(dim(x)); print(summary(x)); print(sapply(x, function(v) class(v)[1]))
print(table(x$wave)); print(length(unique(x$country)))
message("mem MB ", round(as.numeric(object.size(x))/1e6))
