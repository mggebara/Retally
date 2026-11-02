suppressMessages({library(data.table); library(haven)})
B <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/blind/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data"
f <- file.path(B, "Working/pisa_full_gps_final.dta")
cols <- c("country","wave","pv1math","patience","risktaking","female","imfemale","age","image","migra0","migra1","migra2","immigra0","wgtc")
x <- as.data.table(zap_labels(read_dta(f, col_select = all_of(cols), skip = 1850000)))
cat("tail rows", nrow(x), "\n"); print(sapply(x, function(v) sum(is.na(v))))
print(x[, .(n = .N, nw = uniqueN(wave), pat = patience[1]), by = country])
# header N parse
con <- file(f, "rb"); h <- readBin(con, "raw", 300); close(con)
p <- grepRaw("<N>", h); cat("header N:", readBin(h[(p + 3):(p + 10)], "integer", size = 8, endian = "little"), "\n")
