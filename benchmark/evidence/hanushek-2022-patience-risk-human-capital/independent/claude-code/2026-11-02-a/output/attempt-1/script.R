suppressMessages(library(data.table))
D <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/independent/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/CSV/"
t0 <- Sys.time()
cols <- c("isocode","country","wave","wgt","wgtc","patience","risktaking","pv1math","pv1mathorig","female","imfemale","age","image","migra0","migra1","migra2","immigra0","immigra1","immigra2")
x <- fread(paste0(D,"pisa_full_gps_final.csv"), select=cols, nThread=1, showProgress=FALSE)
cat("load secs", as.numeric(Sys.time()-t0,units="secs"), "\n")
cat("nrow", nrow(x), "\n"); str(x)
print(summary(x))
cat("countries", uniqueN(x$isocode), " cw", uniqueN(x[,.(isocode,wave)]), "\n")
print(x[, .(sw=sum(wgtc), swgt=sum(wgt), n=.N), by=.(isocode)][order(isocode)][1:10])
print(x[, .(sw=sum(wgtc), n=.N), by=.(isocode,wave)][1:10])
cc <- unique(x[,.(isocode,patience,risktaking)]); cat("country-level sd pat", sd(cc$patience), " risk", sd(cc$risktaking), " mean", mean(cc$patience), "\n")
cat("student-level sd pat", sd(x$patience), " mean", mean(x$patience), "\n")
print(table(x$migra0+x$migra1+x$migra2, useNA="ifany"))
print(table(x$wave))
cat("pv1math vs orig:", head(x$pv1math), head(x$pv1mathorig), "\n")

# migrant file
y <- haven::read_dta("<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/independent/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/Working/pisa_full_gps_final_imcoo.dta",
  col_select=c(country,isocode,wave,wgt,coo,coo_isocode,coo_patience,coo_risktaking,coo_posrecip,coo_negrecip,coo_altruism,coo_trust,coo_patience_orig,coo_oecd,pv1math,female,imfemale,age,image,migra0,migra1,migra2,countrywave))
y <- as.data.table(y); cat("imcoo nrow", nrow(y), "\n"); print(summary(y))
cat("res countries", uniqueN(y$isocode), " coo", uniqueN(y$coo_isocode), " cw", uniqueN(y$countrywave), "\n")
co <- unique(y[,.(coo_isocode,coo_patience,coo_risktaking)]); cat("coo-level sd", sd(co$coo_patience), sd(co$coo_risktaking), "student sd", sd(y$coo_patience), "\n")
print(table(y$wave))
