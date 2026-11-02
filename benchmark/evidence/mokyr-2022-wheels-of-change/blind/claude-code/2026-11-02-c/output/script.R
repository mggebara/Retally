# Retally blind independent reproduction: mokyr-2022-wheels-of-change, Tables 2 and 3
set.seed(42)
suppressPackageStartupMessages({ library(haven); library(fixest) })

d <- read_dta("<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/blind/2026-11-02-c/mount/mokyr_2022_wheels_of_change/3 replication package/Replication files/Data/replication_data.dta")
d <- as.data.frame(zap_labels(d))

# Per-capita conversion: counts divided by mean district population 1710-50 (pcmean).
# (Table 1 means: watermills pc 18.9, wrights pc 3.76 match mills/pcmean and wrights/pcmean.)
d$w_pc     <- d$wrights / d$pcmean
d$mills_pc <- d$mills / d$pcmean
d$wheat_suit <- as.numeric(d$wheat_tmean <= 5)        # high wheat suitability indicator
d$riv_suit   <- d$riv_rug26count                       # river length with ruggedness 2-6
d$iv         <- d$riv_suit * d$wheat_suit              # instrument
d$county     <- d$GAZ_CNTY

s <- d[!is.na(d$mills_pc), ]
cat("N districts with Domesday mills:", nrow(s), " counties:", length(unique(s$county)), "\n")

geo   <- "latitude + longitude + dist_rug_mean + dist_elevation_mean"
agr   <- "suitmean + wheat_suit + dist_grass_mean"
agr_nowheat <- "suitmean + dist_grass_mean"
clim  <- "precip_mean_dist + temp_mean_dist"
other <- "pcmean + min_harbor + DIST_London + min_dist_to_roman_rds + min_dist_2nav_rivers + area"

f2 <- list(
  "w_pc ~ mills_pc",
  paste("w_pc ~ mills_pc +", geo),
  paste("w_pc ~ mills_pc +", geo, "+", agr),
  paste("w_pc ~ mills_pc +", geo, "+", agr, "+", clim),
  paste("w_pc ~ mills_pc +", geo, "+", agr, "+", clim, "+", other)
)
cl <- ~county
t2 <- lapply(f2, function(f) feols(as.formula(f), data = s, cluster = cl))
for (i in 1:5) { cat("\nTable 2 col", i, "\n"); print(coeftable(t2[[i]])["mills_pc", ]) ; cat("nobs", nobs(t2[[i]]), "\n") }

# Table 3 col 5 OLS: Table 2 col 5 + river suitability
t3c5 <- feols(as.formula(paste("w_pc ~ mills_pc + riv_suit +", geo, "+", agr, "+", clim, "+", other)), data = s, cluster = cl)
cat("\nTable 3 col5 OLS\n"); print(coeftable(t3c5)[c("mills_pc", "riv_suit", "wheat_suit"), ])

# IV columns
iv2 <- feols(w_pc ~ riv_suit + wheat_suit | mills_pc ~ iv, data = s, cluster = cl)
iv4 <- feols(as.formula(paste("w_pc ~ riv_suit + wheat_suit +", geo, "+", agr_nowheat, "+", clim, "| mills_pc ~ iv")), data = s, cluster = cl)
iv6 <- feols(as.formula(paste("w_pc ~ riv_suit + wheat_suit +", geo, "+", agr_nowheat, "+", clim, "+", other, "| mills_pc ~ iv")), data = s, cluster = cl)

fstat <- function(m) {
  # first-stage Wald F for the single excluded instrument, using the clustered vcov
  fw_cl  <- fitstat(m, "ivwald1", vcov = ~county)[[1]]$stat
  fw_het <- fitstat(m, "ivwald1", vcov = "hetero")[[1]]$stat
  f_iid  <- fitstat(m, "ivf1")[[1]]$stat
  cat(sprintf("  first-stage F: clustered=%.4f hetero=%.4f iid=%.4f\n", fw_cl, fw_het, f_iid))
  fw_cl
}
cat("\nIV col2\n"); print(coeftable(iv2)["fit_mills_pc", ]); F2 <- fstat(iv2)
cat("IV col4\n"); print(coeftable(iv4)["fit_mills_pc", ]); F4 <- fstat(iv4)
cat("IV col6\n"); print(coeftable(iv6)["fit_mills_pc", ]); F6 <- fstat(iv6)
cat("IV nobs:", nobs(iv2), nobs(iv4), nobs(iv6), "\n")

cat("DEVIATION: first-stage F reported as cluster-robust (historical county) Wald F of the excluded instrument; paper's exact F variant not stated\n")
cat(sprintf("RESULT:watermills_table2_col1=%.6f\n", coef(t2[[1]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col2=%.6f\n", coef(t2[[2]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col3=%.6f\n", coef(t2[[3]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col4=%.6f\n", coef(t2[[4]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col5=%.6f\n", coef(t2[[5]])["mills_pc"]))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", coef(t3c5)["mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", coef(iv2)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", coef(iv4)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", coef(iv6)["fit_mills_pc"]))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.4f\n", F2))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.4f\n", F4))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.4f\n", F6))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", nobs(t2[[5]])))
