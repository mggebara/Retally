suppressMessages({library(data.table); library(haven)})
B <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/blind/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data"
f <- file.path(B, "Working/pisa_full_gps_final.dta")
rd <- function(off, mb) { t0 <- Sys.time(); con <- file(f, "rb"); seek(con, off); n <- 0
  for (i in 1:(mb/20)) { b <- readBin(con, "raw", 20e6); n <- n + length(b) }; close(con)
  cat("offset", off/1e6, "MB read", n/1e6, "secs", as.numeric(difftime(Sys.time(), t0, units="secs")), "\n") }
rd(0, 400)
rd(400e6, 200)
t0 <- Sys.time()
m <- as.data.table(zap_labels(read_dta(file.path(B, "Working/pisa_full_gps_final_imcoo.dta"))))
cat("imcoo secs", as.numeric(difftime(Sys.time(), t0, units="secs")), "rows", nrow(m), "\n")
print(table(m$wave)); cat("coo", uniqueN(m$coo), "res", uniqueN(m$country), "cw", uniqueN(m$countrywave), "\n")
print(sapply(m[, .(pv1math, coo_patience, coo_risktaking, coo_posrecip, coo_oecd, female, age, migra0, migra1, migra2, wgt, patience_sd, coo_patience_orig)], function(v) sum(is.na(v))))
cc <- unique(m[, .(coo, coo_patience, coo_patience_orig, coo_risktaking, coo_risktaking_orig, coo_posrecip, coo_posrecip_orig, coo_negrecip, coo_negrecip_orig, coo_altruism, coo_altruism_orig, coo_trust, coo_trust_orig)])
cat("unique coo rows", nrow(cc), "\n")
for (v in c("patience","risktaking","posrecip","negrecip","altruism","trust")) {
  fit <- lm(cc[[paste0("coo_",v)]] ~ cc[[paste0("coo_",v,"_orig")]]); cat(v, "std = a + b*orig:", coef(fit), " R2", summary(fit)$r.squared, "\n")
  cat("  cty-level mean/sd of std:", mean(cc[[paste0("coo_",v)]]), sd(cc[[paste0("coo_",v)]]), "\n") }
# is patience_sd constant within coo or within residence country?
cat("patience_sd unique per coo (max):", m[, uniqueN(patience_sd), by=coo][, max(V1)], " per country:", m[, uniqueN(patience_sd), by=country][, max(V1)], "\n")
print(head(unique(m[, .(coo, patience_sd, risktaking_sd, coo_patience_orig)])[order(coo)], 60))
print(m[, .N, by=.(migra0,migra1,migra2)][order(-N)][1:8])
print(summary(m[, .(wgt, migage, image, imfemale, coo_oecd)]))
cat("wgt sum by countrywave (first 10):\n"); print(head(m[, .(sw=sum(wgt), N=.N), by=countrywave], 10))
print(table(m$immigra0, m$immigra1))
