# Exploratory: time a full column-selected read of the big .dta; descriptive counts only, no estimates.
suppressMessages({library(data.table); library(haven)})
B <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/independent/2026-11-07-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/"
t0 <- proc.time()
x <- as.data.table(read_dta(paste0(B, "Working/pisa_full_gps_final.dta"),
  col_select = c("country","wave","pv1math","wgtc","patience","risktaking",
                 "female","age","imfemale","image","migra1","migra2",
                 "immigra0","immigra1","immigra2")))
print(proc.time() - t0)
cat("rows:", nrow(x), " countries:", uniqueN(x$country), " country-waves:", uniqueN(x[, .(country, wave)]), "\n")
print(x[, .(N=.N, swgtc=sum(wgtc)), by=wave][order(wave)])
cat("NA pv1math:", sum(is.na(x$pv1math)), " NA patience:", sum(is.na(x$patience)), "\n")
