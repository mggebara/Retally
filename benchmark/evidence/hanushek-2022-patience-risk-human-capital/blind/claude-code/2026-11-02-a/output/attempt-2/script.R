suppressMessages({library(data.table); library(haven)})
B <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/blind/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data"
f <- file.path(B, "Working/pisa_full_gps_final.dta")
cat("dta size MB", file.size(f)/1e6, "\n")
t0 <- Sys.time()
con <- file(f, "rb"); n <- 0
for (i in 1:20) { b <- readBin(con, "raw", 20e6); n <- n + length(b) }
close(con); rm(b)
cat("raw read MB", n/1e6, "secs", as.numeric(difftime(Sys.time(), t0, units="secs")), "\n")
t0 <- Sys.time()
cols <- c("country","wave","pv1math","patience","risktaking","female","imfemale","age","image","migra0","migra1","migra2","immigra0","immigra1","immigra2","wgt","wgtc")
y <- read_dta(f, col_select = all_of(cols), n_max = 200000)
cat("read_dta 200k rows secs", as.numeric(difftime(Sys.time(), t0, units="secs")), "\n")
print(str(y))
y <- as.data.table(zap_labels(y))
print(summary(y))
print(y[, .N, by=.(migra0,migra1,migra2,immigra0,immigra1,immigra2)][order(-N)])
print(y[, .(N=.N, sw=sum(wgt), swc=sum(wgtc), pat=mean(patience)), by=.(country,wave)])
