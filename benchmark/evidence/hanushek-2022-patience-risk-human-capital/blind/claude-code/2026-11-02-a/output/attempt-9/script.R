# Retally blind independent reproduction: Hanushek et al. (2022, EJ)
# "Patience, Risk-Taking, and Human Capital Investment across Countries"
# Table 1 (cols 1,2,3,5) and Table 2 (cols 1,3,4).
suppressMessages({library(data.table); library(haven); library(fixest)})
set.seed(42)
T0 <- Sys.time(); el <- function() as.numeric(difftime(Sys.time(), T0, units = "secs"))
B <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/blind/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/Working"
setFixest_nthreads(1); setFixest_estimation(fixef.rm = "none")

# ------------------------------------------------------------------ Table 2: migrant analysis
# Migrant file: students with both parents born abroad, origin country with GPS data, waves 2003-2018.
# coo_* preferences are already z-standardised in the migrant analytical sample (verified in
# exploration: coo_x = a + b * coo_x_orig exactly, b ~ 1, i.e. individual-level GPS standardisation).
mcols <- c("coo", "country", "wave", "countrywave", "pv1math", "coo_patience", "coo_risktaking",
           "coo_posrecip", "coo_negrecip", "coo_altruism", "coo_trust", "coo_oecd",
           "female", "imfemale", "age", "image", "wgt", "patience_sd", "risktaking_sd")
m <- as.data.table(zap_labels(read_dta(file.path(B, "pisa_full_gps_final_imcoo.dta"), col_select = all_of(mcols))))
m <- m[wave >= 2003]
cat("migrant file rows:", nrow(m), " origins:", uniqueN(m$coo), " residence:", uniqueN(m$country),
    " country-waves:", uniqueN(m$countrywave), " secs:", round(el(), 1), "\n")
ctrl2 <- "female + age + coo_oecd + imfemale + image"
t2c1 <- feols(as.formula(paste("pv1math ~ coo_patience +", ctrl2, "| countrywave")), m, weights = ~wgt, cluster = ~coo)
t2c3 <- feols(as.formula(paste("pv1math ~ coo_patience + coo_risktaking +", ctrl2, "| countrywave")), m, weights = ~wgt, cluster = ~coo)
t2c4 <- feols(as.formula(paste("pv1math ~ coo_patience + coo_risktaking + coo_posrecip + coo_negrecip + coo_altruism + coo_trust +", ctrl2, "| countrywave")),
              m, weights = ~wgt, cluster = ~coo)
cat("Table 2 col3 SEs (country-of-origin clustered):\n"); print(coeftable(t2c3)[1:2, ])
# within-country GPS SDs by origin country, used below to rebuild the individual-level SD for Table 1
sdtab <- unique(m[, .(cname = coo, patience_sd, risktaking_sd)])
rm(m); invisible(gc(verbose = FALSE))
cat("Table 2 done at", round(el(), 1), "s\n")

# ------------------------------------------------------------------ Table 1: cross-country analysis
f <- file.path(B, "pisa_full_gps_final.dta")
con <- file(f, "rb"); h <- readBin(con, "raw", 300); close(con)
p <- grepRaw("<N>", h); NTOT <- readBin(h[(p + 3):(p + 10)], "integer", size = 8, endian = "little")
cat("rows in full file (header):", NTOT, "\n")
cols <- c("country", "wave", "pv1math", "patience", "risktaking", "female", "imfemale", "age", "image",
          "migra0", "migra1", "migra2", "immigra0", "wgtc")
# Systematic block subsample: blocks of BL rows every ST rows (gap < smallest country's row count,
# so every country is hit), read in van der Corput order so that a deadline stop keeps the sample spread.
BL <- 3000; ST <- 6000
starts <- seq(0, NTOT - 1, by = ST)
vdc <- function(i) { r <- 0; b <- 0.5; while (i > 0) { r <- r + b * (i %% 2); i <- i %/% 2; b <- b / 2 }; r }
ord <- order(sapply(seq_along(starts) - 1, vdc))
DEADLINE <- 222
out <- vector("list", length(starts)); nread <- 0; nfail <- 0
rdblock <- function(s) as.data.table(zap_labels(read_dta(f, col_select = all_of(cols), skip = s, n_max = BL)))
for (j in ord) {
  if (el() > DEADLINE) break
  b <- tryCatch(rdblock(starts[j]), error = function(e) tryCatch(rdblock(starts[j]), error = function(e2) NULL))
  if (is.null(b)) { nfail <- nfail + 1; cat("block read failed at row", starts[j], "\n"); next }
  out[[j]] <- b; nread <- nread + 1
}
cat("failed blocks:", nfail, "\n")
x <- rbindlist(out); rm(out); invisible(gc(verbose = FALSE))
cat("blocks read:", nread, "of", length(starts), " rows loaded:", nrow(x), " share:", round(nrow(x) / NTOT, 3),
    " secs:", round(el(), 1), "\n")
cat(sprintf("DEVIATION: full PISA file (%d rows, 2.5 GB) cannot be read through the mount within the 300 s sandbox limit (~10 MB/s); Table 1 is estimated on a systematic subsample of %d rows (%.1f%%): %d-row blocks every %d rows, %d of %d blocks read; only the needed columns are loaded (haven col_select); sampling weights wgtc are renormalised within country-wave so each country keeps equal total weight and equal weight per wave.\n",
            NTOT, nrow(x), 100 * nrow(x) / NTOT, BL, ST, nread, length(starts)))
# Full-sample N: rows of the full file times the complete-case share in the loaded rows
need <- c("pv1math", "patience", "risktaking", "female", "age", "migra1", "migra2", "wgtc")
cc_share <- mean(complete.cases(x[, ..need]))
x <- x[complete.cases(x[, ..need])]
N_full <- round(NTOT * cc_share)
cat("complete-case share in loaded rows:", cc_share, " countries:", uniqueN(x$country), " country-waves:", uniqueN(x[, .(country, wave)]), "\n")
cat("DEVIATION: table1_col3_observations is the full-file row count times the complete-case share of the loaded rows (no missing values were found in any regression variable in exploratory reads of all rows).\n")

# Reweight within country-wave: each sampled country-wave gets 1/(#waves of the country), countries sum to 1
x[, w := wgtc / sum(wgtc), by = .(country, wave)]
x[, w := w / uniqueN(wave), by = country]

# Preferences: GPS country means, z-standardised at the individual GPS level in the 49-country sample.
# Only country means are in the data; the individual-level SD is rebuilt as
# sqrt(mean within-country variance + variance of country means) (equal-sized national GPS samples),
# with within-country SDs taken from the GPS SD variables of the migrant file (matched by country name;
# countries without one get the mean within-country variance).
cty <- unique(x[, .(cname = country, patience, risktaking)])
cty <- merge(cty, sdtab, by = "cname", all.x = TRUE)
cat("countries with GPS within-SD available:", sum(!is.na(cty$patience_sd)), "of", nrow(cty), "\n")
zstd <- function(mu, sdw) { v <- sdw^2; v[is.na(v)] <- mean(v, na.rm = TRUE)
  s <- sqrt(mean(v) + mean((mu - mean(mu))^2)); list(z = (mu - mean(mu)) / s, s = s) }
zp <- zstd(cty$patience, cty$patience_sd); zr <- zstd(cty$risktaking, cty$risktaking_sd)
cty[, `:=`(pat_z = zp$z, risk_z = zr$z)]
cat("individual-level GPS SD used: patience", zp$s, " risk-taking", zr$s, "\n")
cat("DEVIATION: the data hold only country-level GPS means; the individual-level z-standardisation in the 49-country sample is reconstructed with the within-country GPS SDs of the migrant file (validated on the 58 origin countries, where it reproduces the file's own standardisation slope to <1%).\n")
x <- merge(x, cty[, .(country = cname, pat_z, risk_z)], by = "country")

ctrl1 <- "female + age + migra1 + migra2 + imfemale + image + immigra0"
t1c1 <- feols(as.formula(paste("pv1math ~ pat_z +", ctrl1, "| wave")), x, weights = ~w, cluster = ~country)
t1c2 <- feols(as.formula(paste("pv1math ~ risk_z +", ctrl1, "| wave")), x, weights = ~w, cluster = ~country)
t1c3 <- feols(as.formula(paste("pv1math ~ pat_z + risk_z +", ctrl1, "| wave")), x, weights = ~w, cluster = ~country)
nat <- x[migra0 == 1 & immigra0 == 0]
nat[, w := wgtc / sum(wgtc), by = .(country, wave)]; nat[, w := w / uniqueN(wave), by = country]
t1c5 <- feols(as.formula(paste("pv1math ~ pat_z + risk_z + female + age + imfemale + image | wave")), nat, weights = ~w, cluster = ~country)
cat("Table 1 col3 SEs (country clustered):\n"); print(coeftable(t1c3)[1:2, ])
cat("Table 1 col3 loaded-sample nobs:", nobs(t1c3), " natives loaded nobs:", nobs(t1c5), " secs:", round(el(), 1), "\n")

cat(sprintf("RESULT:table1_col3_patience=%.6f\n", coef(t1c3)[["pat_z"]]))
cat(sprintf("RESULT:table1_col3_risk_taking=%.6f\n", coef(t1c3)[["risk_z"]]))
cat(sprintf("RESULT:table1_col1_patience=%.6f\n", coef(t1c1)[["pat_z"]]))
cat(sprintf("RESULT:table1_col2_risk_taking=%.6f\n", coef(t1c2)[["risk_z"]]))
cat(sprintf("RESULT:table1_col5_natives_patience=%.6f\n", coef(t1c5)[["pat_z"]]))
cat(sprintf("RESULT:table1_col5_natives_risk_taking=%.6f\n", coef(t1c5)[["risk_z"]]))
cat(sprintf("RESULT:table1_col3_observations=%d\n", as.integer(N_full)))
cat(sprintf("RESULT:table2_col3_patience=%.6f\n", coef(t2c3)[["coo_patience"]]))
cat(sprintf("RESULT:table2_col3_risk_taking=%.6f\n", coef(t2c3)[["coo_risktaking"]]))
cat(sprintf("RESULT:table2_col1_patience=%.6f\n", coef(t2c1)[["coo_patience"]]))
cat(sprintf("RESULT:table2_col4_patience=%.6f\n", coef(t2c4)[["coo_patience"]]))
cat(sprintf("RESULT:table2_col4_risk_taking=%.6f\n", coef(t2c4)[["coo_risktaking"]]))
cat(sprintf("RESULT:table2_col3_observations=%d\n", as.integer(nobs(t2c3))))
cat("total secs:", round(el(), 1), "\n")
