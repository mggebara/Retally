suppressMessages(library(data.table))
f <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/independent/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/CSV/pisa_full_gps_final.csv"
sz <- file.size(f); cat("size", sz, "\n")
con <- file(f, "rb")
for (off in c(0, 1.0e9, 2.0e9, 2.6e9)) {
  t0 <- Sys.time(); seek(con, off); b <- readBin(con, "raw", 100e6)
  cat("raw 100MB at", off, "secs", as.numeric(Sys.time()-t0, units="secs"), "\n")
}
# parse speed on in-memory text
t0 <- Sys.time(); seek(con, 0); b <- readBin(con, "raw", 100e6)
txt <- rawToChar(b[1:max(which(b==as.raw(10)))])
cat("rawToChar secs", as.numeric(Sys.time()-t0, units="secs"), "\n")
t0 <- Sys.time()
x <- fread(text=txt, select=c("isocode","wave","wgtc","patience","pv1math"), nThread=1, showProgress=FALSE)
cat("fread text parse secs", as.numeric(Sys.time()-t0, units="secs"), " rows", nrow(x), "\n")
close(con)
# isocode order along the file (sample a few lines at offsets)
con <- file(f, "rb")
for (off in seq(0, sz-1e5, length.out=40)) { seek(con, off); b <- readBin(con, "raw", 20000); s <- strsplit(rawToChar(b), "\n")[[1]][2]; cat(substr(s,1,25), " | ") }
close(con); cat("\n")
