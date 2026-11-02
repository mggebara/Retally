# Retally blind reproduction: mokyr-2022-wheels-of-change, Tables 2 and 3
set.seed(42)
suppressMessages({library(haven); library(fixest)})

d <- haven::read_dta("<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/blind/2026-11-02-b/mount/mokyr_2022_wheels_of_change/3 replication package/Replication files/Data/replication_data.dta")
d <- as.data.frame(zap_labels(d))

# Per capita (per mean population 1710-50). Common scaling (e.g. per 10,000)
# does not affect the slope since both sides share the same denominator.
d$w_pc     <- d$wrights / d$pcmean
d$mills_pc <- d$mills / d$pcmean
# High wheat suitability indicator: mean wheat suitability category <= 5
d$wheat_suit <- as.numeric(d$wheat_tmean <= 5)
# River suitability: river length in terrain of ruggedness between 2 and 6
d$riv_suit <- d$riv_rug26count
d$iv <- d$riv_suit * d$wheat_suit

# Sample: districts with Domesday mills data
s <- d[!is.na(d$mills_pc), ]
cat("N districts:", nrow(s), " counties:", length(unique(s$GAZ_CNTY)), "\n")

geo   <- "latitude + longitude + dist_rug_mean + dist_elevation_mean"
agri  <- "suitmean + wheat_suit + dist_grass_mean"
clim  <- "precip_mean_dist + temp_mean_dist"
other <- "pcmean + min_harbor + DIST_London + min_dist_to_roman_rds + min_dist_2nav_rivers + area"
cl <- ~GAZ_CNTY

f2 <- list(
  c1 = "w_pc ~ mills_pc",
  c2 = paste("w_pc ~ mills_pc +", geo),
  c3 = paste("w_pc ~ mills_pc +", geo, "+", agri),
  c4 = paste("w_pc ~ mills_pc +", geo, "+", agri, "+", clim),
  c5 = paste("w_pc ~ mills_pc +", geo, "+", agri, "+", clim, "+", other)
)
t2 <- lapply(f2, function(f) feols(as.formula(f), data = s, cluster = cl))
for (n in names(t2)) { cat("\n== Table 2", n, "==\n"); print(coeftable(t2[[n]])["mills_pc", ]); cat("nobs", nobs(t2[[n]]), "\n") }

# Table 3 OLS col 5: Table 2 col 5 + river suitability
ols5 <- feols(as.formula(paste("w_pc ~ mills_pc + riv_suit +", geo, "+", agri, "+", clim, "+", other)), data = s, cluster = cl)
cat("\n== Table 3 OLS col5 ==\n"); print(coeftable(ols5)["mills_pc", ])

# IVs
iv2 <- feols(w_pc ~ riv_suit + wheat_suit | mills_pc ~ iv, data = s, cluster = cl)
iv4 <- feols(as.formula(paste("w_pc ~ riv_suit +", geo, "+", agri, "+", clim, "| mills_pc ~ iv")), data = s, cluster = cl)
iv6 <- feols(as.formula(paste("w_pc ~ riv_suit +", geo, "+", agri, "+", clim, "+", other, "| mills_pc ~ iv")), data = s, cluster = cl)

fs_F <- function(m) {
  # first-stage F on the single excluded instrument, cluster-robust (= KP Wald F)
  w <- fitstat(m, "ivwald1", cluster = cl)[[1]]$stat
  u <- fitstat(m, "ivf1")[[1]]$stat
  c(clustered = w, iid = u)
}
for (n in c("iv2", "iv4", "iv6")) {
  m <- get(n); cat("\n==", n, "==\n"); print(coeftable(m)["fit_mills_pc", ])
  cat("first stage F (clustered, iid):", fs_F(m), " nobs", nobs(m), "\n")
}
F2 <- fs_F(iv2)["clustered"]; F4 <- fs_F(iv4)["clustered"]; F6 <- fs_F(iv6)["clustered"]

cat("\n")
cat(sprintf("RESULT:watermills_table2_col1=%.6f\n", coef(t2$c1)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col2=%.6f\n", coef(t2$c2)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col3=%.6f\n", coef(t2$c3)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col4=%.6f\n", coef(t2$c4)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col5=%.6f\n", coef(t2$c5)["mills_pc"]))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", coef(ols5)["mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", coef(iv2)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", coef(iv4)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", coef(iv6)["fit_mills_pc"]))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.4f\n", F2))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.4f\n", F4))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.4f\n", F6))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", nobs(t2$c5)))
