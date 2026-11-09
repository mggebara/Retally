# Exploratory: time partial reads of the big file (dta vs csv). No estimates.
suppressMessages({library(data.table); library(haven)})
B <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/independent/2026-11-07-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/"
cols <- c("country","wave","pv1math","wgtc","patience","risktaking","female","age","imfemale","image",
          "migra0","migra1","migra2","immigra0","immigra1","immigra2")
t0 <- proc.time()
d <- read_dta(paste0(B,"Working/pisa_full_gps_final.dta"), col_select=all_of(cols), n_max=200000)
print(proc.time()-t0); print(dim(d)); str(d[, 1:6])
t0 <- proc.time()
x <- fread(paste0(B,"CSV/pisa_full_gps_final.csv"), select=cols, nrows=200000, nThread=1)
print(proc.time()-t0); print(dim(x))
t0 <- proc.time()
d <- read_dta(paste0(B,"Working/pisa_full_gps_final.dta"), col_select=all_of(cols), n_max=600000)
print(proc.time()-t0); print(dim(d))
print(as.data.table(d)[, .N, by=.(migra0, migra1, migra2, immigra0)])
