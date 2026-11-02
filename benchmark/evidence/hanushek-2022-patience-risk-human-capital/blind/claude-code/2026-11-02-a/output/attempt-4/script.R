suppressMessages({library(data.table); library(haven)})
B <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/blind/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data"
f <- file.path(B, "Working/pisa_full_gps_final.dta")
cols <- c("country","wave","pv1math","patience","risktaking","female","imfemale","age","image","migra0","migra1","migra2","immigra0","wgtc")
tm <- function(expr) { t0 <- Sys.time(); r <- expr; list(r, as.numeric(difftime(Sys.time(), t0, units="secs"))) }
a <- tm(read_dta(f, col_select = all_of(cols), n_max = 10)); cat("header-only call secs", a[[2]], "\n")
a <- tm(read_dta(f, col_select = all_of(cols), skip = 1900000, n_max = 20000)); cat("skip 1.9M n 20000 secs", a[[2]], "rows", nrow(a[[1]]), "\n"); print(head(a[[1]][, 1:5], 3))
a <- tm(read_dta(f, col_select = all_of(cols), skip = 1000000, n_max = 2000)); cat("skip 1.0M n 2000 secs", a[[2]], "\n")
a <- tm(read_dta(f, col_select = all_of(cols), skip = 1500000, n_max = 2000)); cat("skip 1.5M n 2000 secs", a[[2]], "\n"); print(head(a[[1]][, 1:5], 3))
a <- tm(read_dta(f, col_select = all_of(cols), skip = 1992270, n_max = 100)); cat("tail rows got", nrow(a[[1]]), "secs", a[[2]], "\n")
# header N from dta 118 bytes
con <- file(f, "rb"); h <- readBin(con, "raw", 200); close(con)
s <- rawToChar(h[h != as.raw(0)][1:120]); cat("header text:", substr(gsub("[^[:print:]]", ".", s), 1, 110), "\n")
# decomposition validation on 58 origins
m <- as.data.table(zap_labels(read_dta(file.path(B, "Working/pisa_full_gps_final_imcoo.dta"), col_select = c("coo","coo_patience","coo_patience_orig","coo_risktaking","coo_risktaking_orig","patience_sd","risktaking_sd","country","patience","risktaking"))))
cc <- unique(m[, .(coo, coo_patience_orig, coo_risktaking_orig, patience_sd, risktaking_sd)])
for (v in c("patience","risktaking")) { mu <- cc[[paste0("coo_",v,"_orig")]]; sdw <- cc[[paste0(v,"_sd")]]
  s_tot <- sqrt(mean(sdw^2) + mean((mu - mean(mu))^2)); cat(v, "decomp individual SD (58 coo):", s_tot, " implied slope", 1/s_tot, "\n") }
res <- unique(m[, .(country, patience, risktaking)]); cat("residence countries in imcoo:", nrow(res), "\n")
cat("residence countries that are also coo:", sum(res$country %in% cc$coo), "\n")
