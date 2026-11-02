suppressPackageStartupMessages({library(haven); library(fixest); library(dplyr)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/seeded/2026-11-02-a/mount/mokyr_2022_wheels_of_change"
d <- as.data.frame(zap_labels(read_dta(file.path(base, "3 replication package/Replication files/Data/replication_data.dta"))))
# main.do
d$GAZ_CNTY[d$GAZ_CNTY == ""] <- NA
d$county_id <- as.integer(factor(d$GAZ_CNTY))
d$mills_pc   <- d$mills / d$pcmean
d$wrights_pc <- d$wrights / d$pcmean
d$wheat_suit <- ifelse(is.na(d$wheat_tmean), NA, as.numeric(d$wheat_tmean <= 5))
d$riv_rug26count <- d$riv_rug26count / 1000
d$msuit26mean <- d$wheat_suit * d$riv_rug26count

geo   <- c("latitude","longitude","dist_rug_mean","dist_elevation_mean")
agr3  <- c("suitmean","wheat_suit","dist_grass_mean")
clim  <- c("precip_mean_dist","temp_mean_dist")
other <- c("pcmean","min_harbor","DIST_London","min_dist_to_roman_rds","min_dist_2nav_rivers","area")

ds <- d[!is.na(d$mills_pc) & !is.na(d$wrights_pc), ]
cat("Rows total:", nrow(d), " with mills_pc & wrights_pc:", nrow(ds), " clusters:", length(unique(ds$county_id)),
    " missing county:", sum(is.na(ds$county_id)), "\n")

ols <- function(ctrls, data = ds) {
  f <- as.formula(paste("wrights_pc ~", paste(c("mills_pc", ctrls), collapse = " + ")))
  feols(f, data = data, cluster = ~county_id)
}
t2 <- list(ols(NULL), ols(geo), ols(c(geo, agr3)), ols(c(geo, agr3, clim)), ols(c(geo, agr3, clim, other)))
for (i in 1:5) cat(sprintf("T2 col%d: b=%.4f se=%.4f N=%d\n", i, coef(t2[[i]])["mills_pc"], se(t2[[i]])["mills_pc"], nobs(t2[[i]])))

t3c5 <- ols(c("wheat_suit","riv_rug26count", geo, "suitmean","dist_grass_mean", clim, other))
cat(sprintf("T3 col5 OLS: b=%.4f se=%.4f N=%d\n", coef(t3c5)["mills_pc"], se(t3c5)["mills_pc"], nobs(t3c5)))

iv <- function(ctrls) {
  f <- as.formula(paste("wrights_pc ~", paste(ctrls, collapse = " + "), "| mills_pc ~ msuit26mean"))
  m <- feols(f, data = ds, cluster = ~county_id)
  # ivreg2 widstat (Kleibergen-Paap rk Wald F; one endogenous, one excluded instrument):
  # first-stage Wald on the excluded instrument using the unadjusted cluster VCE,
  # scaled by (N-K)/N * (G-1)/G (ivreg2 default, no 'small' option).
  ff <- as.formula(paste("mills_pc ~ msuit26mean +", paste(ctrls, collapse = " + ")))
  fs <- feols(ff, data = ds)
  V0 <- vcov(fs, cluster = ~county_id, ssc = ssc(adj = FALSE, cluster.adj = FALSE))
  w  <- coef(fs)["msuit26mean"]^2 / V0["msuit26mean","msuit26mean"]
  N <- nobs(fs); K <- length(coef(fs)); G <- length(unique(ds$county_id))
  Fkp <- w * (N - K) / N * (G - 1) / G
  Fstd <- (coef(fs)["msuit26mean"] / se(fs, cluster = ~county_id)["msuit26mean"])^2
  list(m = m, F = unname(Fkp), Fstd = unname(Fstd), N = nobs(m))
}
i2 <- iv(c("riv_rug26count","wheat_suit"))
i4 <- iv(c("wheat_suit","riv_rug26count", geo, "suitmean","dist_grass_mean", clim))
i6 <- iv(c("wheat_suit","riv_rug26count", geo, "suitmean","dist_grass_mean", clim, other))
for (nm in c("i2","i4","i6")) { x <- get(nm)
  cat(sprintf("T3 %s IV: b=%.4f se=%.4f N=%d  F_KP=%.3f (cluster t^2 with Stata small-sample adj=%.3f)\n", nm,
      coef(x$m)["fit_mills_pc"], se(x$m)["fit_mills_pc"], x$N, x$F, x$Fstd)) }

ns <- c(sapply(t2, nobs), nobs(t3c5), i2$N, i4$N, i6$N)
if (length(unique(ns)) != 1) cat("NOTE: observation counts differ across columns:", ns, "\n")

cat(sprintf("RESULT:watermills_table2_col%d=%.6f\n", 1:5, sapply(t2, function(m) coef(m)["mills_pc"])), sep = "")
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", coef(t3c5)["mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", coef(i2$m)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", coef(i4$m)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", coef(i6$m)["fit_mills_pc"]))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.6f\n", i2$F))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.6f\n", i4$F))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.6f\n", i6$F))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", ns[1]))
