suppressMessages({library(data.table); library(haven)})
T0 <- Sys.time(); el <- function() as.numeric(difftime(Sys.time(), T0, units="secs"))
B <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/blind/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data"
m <- as.data.table(zap_labels(read_dta(file.path(B, "Working/pisa_full_gps_final_imcoo.dta"), col_select = c("coo","coo_patience_orig","coo_risktaking_orig","patience_sd","risktaking_sd"))))
cat("imcoo cols read secs", el(), "\n")
cc <- unique(m[, .(coo, coo_patience_orig, coo_risktaking_orig, patience_sd, risktaking_sd)])
for (v in c("patience","risktaking")) { mu <- cc[[paste0("coo_",v,"_orig")]]; sdw <- cc[[paste0(v,"_sd")]]
  s_tot <- sqrt(mean(sdw^2) + mean((mu - mean(mu))^2)); cat(v, "decomp individual SD (58 coo):", s_tot, " implied slope", 1/s_tot, "\n") }
f <- file.path(B, "Working/pisa_full_gps_final.dta")
cols <- c("country","wave","pv1math","patience","risktaking","posrecip","female","imfemale","age","image","migra0","migra1","migra2","immigra0","wgtc")
N <- 1992276; cs <- 25000; starts <- seq(0, N - 1, by = cs)
out <- list(); t1 <- el()
for (i in seq_along(starts)) { if (el() > 285) break
  out[[i]] <- as.data.table(zap_labels(read_dta(f, col_select = all_of(cols), skip = starts[i], n_max = cs))) }
x <- rbindlist(out); cat("chunks read", length(out), "of", length(starts), "rows", nrow(x), "read secs", el() - t1, "total", el(), "\n")
print(sapply(x, function(v) sum(is.na(v))))
cty <- x[, .(pat = patience[1], risk = risktaking[1], n = .N), by = country]
cat("countries", nrow(cty), "\n"); print(cty[order(country)], nrows = 100)
cat("matched to coo with sd:", sum(cty$country %in% cc$coo), "\n"); print(setdiff(cty$country, cc$coo))
print(x[, .(sw = sum(wgtc)), by = .(country, wave)][, .(nw = .N, minsw = min(sw), maxsw = max(sw), tot = sum(sw)), by = country][order(country)], nrows = 100)
cat("cw count", uniqueN(x[, .(country, wave)]), "\n")
