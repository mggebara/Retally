suppressMessages({library(data.table)})
D <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/blind/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/CSV"
t0 <- Sys.time()
cols <- c("isocode","country","wave","oecd","pv1math","pv1mathorig","patience","risktaking","posrecip","negrecip","altruism","trust",
          "female","imfemale","age","image","migra0","migra1","migra2","immigra0","immigra1","immigra2","wgt","wgtc","stubrncnt","fatbrncnt","motbrncnt")
x <- fread(file.path(D,"pisa_full_gps_final.csv"), select=cols, nThread=1, showProgress=FALSE)
cat("load secs", as.numeric(difftime(Sys.time(),t0,units="secs")), "\n")
cat("nrow", nrow(x), "\n"); print(sapply(x, function(v) sum(is.na(v))))
print(table(x$wave)); cat("countries", uniqueN(x$country), " with patience:", uniqueN(x[!is.na(patience)]$country), "\n")
print(summary(x[, .(pv1math, pv1mathorig, age, wgt, wgtc)]))
cty <- x[, .(pat=mean(patience), risk=mean(risktaking), n=.N, sw=sum(wgt), swc=sum(wgtc), sdpat=sd(patience)), by=country]
print(cty[order(country)])
cat("cty-level pat mean/sd", mean(cty$pat,na.rm=T), sd(cty$pat,na.rm=T), " risk", mean(cty$risk,na.rm=T), sd(cty$risk,na.rm=T), "\n")
print(x[, .N, by=.(migra0,migra1,migra2,immigra0,immigra1,immigra2)][order(-N)])
print(x[, .N, by=.(female,imfemale)][order(-N)][1:10])
print(x[, .N, by=.(image, agena=is.na(age))])
print(x[!is.na(patience), .(nw=uniqueN(wave)), by=country][, sum(nw)])
cw <- x[!is.na(patience), .(swc=sum(wgtc)), by=.(country,wave)]; print(head(cw[order(country,wave)],15))
