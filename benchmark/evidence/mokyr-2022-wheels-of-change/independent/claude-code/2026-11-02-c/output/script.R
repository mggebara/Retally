suppressMessages({library(haven); library(fixest)})
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/independent/2026-11-02-c/mount/mokyr_2022_wheels_of_change/3 replication package/Replication files/Data/replication_data.dta")
d <- as.data.frame(zap_labels(d))

# Per capita (per 10,000) using mean population 1710-50 (pcmean, in 10,000s; matches Table 1 means)
d$w_pc     <- d$wrights / d$pcmean
d$mills_pc <- d$mills / d$pcmean
d$wheat_hi <- as.numeric(d$wheat_tmean <= 5)          # high wheat suitability indicator
d$riv_suit <- d$riv_rug26count / 1000                 # river length with ruggedness 2-6 (scale irrelevant for mills coef)
d$iv       <- d$riv_suit * d$wheat_hi
d <- d[!is.na(d$mills_pc), ]                          # Domesday coverage: 298 districts

main  <- "latitude + longitude + dist_rug_mean + dist_elevation_mean"
agri  <- "suitmean + wheat_hi + dist_grass_mean"
clim  <- "precip_mean_dist + temp_mean_dist"
other <- "pcmean + min_harbor + DIST_London + min_dist_to_roman_rds + min_dist_2nav_rivers + area"

cl <- ~GAZ_CNTY
f <- function(rhs) as.formula(paste("w_pc ~ mills_pc", if (nchar(rhs)) paste("+", rhs) else ""))

ols <- list(
  feols(f(""), d, cluster = cl),
  feols(f(main), d, cluster = cl),
  feols(f(paste(main, agri, sep = " + ")), d, cluster = cl),
  feols(f(paste(main, agri, clim, sep = " + ")), d, cluster = cl),
  feols(f(paste(main, agri, clim, other, sep = " + ")), d, cluster = cl)
)
for (i in 1:5) cat(sprintf("T2 col%d: b=%.4f se=%.4f n=%d adjR2=%.3f\n", i, coef(ols[[i]])["mills_pc"], se(ols[[i]])["mills_pc"], nobs(ols[[i]]), r2(ols[[i]], "ar2")))

ols35 <- feols(f(paste(main, agri, clim, other, "riv_suit", sep = " + ")), d, cluster = cl)
cat(sprintf("T3 col5 OLS: b=%.4f se=%.4f adjR2=%.3f\n", coef(ols35)["mills_pc"], se(ols35)["mills_pc"], r2(ols35, "ar2")))

ivf <- function(ctrl) as.formula(paste("w_pc ~", ctrl, "| mills_pc ~ iv"))
c2 <- "riv_suit + wheat_hi"
c4 <- paste(c2, main, "suitmean + dist_grass_mean", clim, sep = " + ")
c6 <- paste(c4, other, sep = " + ")
iv <- list(feols(ivf(c2), d, cluster = cl), feols(ivf(c4), d, cluster = cl), feols(ivf(c6), d, cluster = cl))
Fcl <- Fiid <- Fhc <- numeric(3)
for (i in 1:3) {
  m <- iv[[i]]
  Fcl[i]  <- fitstat(m, "ivwald1", cluster = cl)[[1]]$stat
  Fiid[i] <- fitstat(m, "ivf1")[[1]]$stat
  Fhc[i]  <- fitstat(m, "ivwald1", vcov = "hetero")[[1]]$stat
  cat(sprintf("T3 IV col%d: b=%.4f se=%.4f  F(cluster)=%.2f F(iid)=%.2f F(HC1)=%.2f\n", 2*i, coef(m)["fit_mills_pc"], se(m)["fit_mills_pc"], Fcl[i], Fiid[i], Fhc[i]))
}

cat(sprintf("RESULT:watermills_table2_col1=%.6f\n", coef(ols[[1]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col2=%.6f\n", coef(ols[[2]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col3=%.6f\n", coef(ols[[3]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col4=%.6f\n", coef(ols[[4]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col5=%.6f\n", coef(ols[[5]])["mills_pc"]))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", coef(ols35)["mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", coef(iv[[1]])["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", coef(iv[[2]])["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", coef(iv[[3]])["fit_mills_pc"]))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.4f\n", Fcl[1]))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.4f\n", Fcl[2]))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.4f\n", Fcl[3]))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", nobs(ols[[5]])))
