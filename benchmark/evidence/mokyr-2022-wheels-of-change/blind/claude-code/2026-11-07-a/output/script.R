# Independent blind reproduction: Mokyr, Sarid & van der Beek (2022), Tables 2-3
set.seed(42)
suppressPackageStartupMessages({ library(haven); library(fixest) })
d <- read_dta("<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/blind/2026-11-07-a/mount/mokyr_2022_wheels_of_change/3 replication package/Replication files/Data/replication_data.dta")
d <- as.data.frame(zap_labels(d))

# Per capita (per 10,000) using mean district population 1710-50 (pcmean)
d$w_pc     <- d$wrights / d$pcmean
d$mills_pc <- d$mills / d$pcmean
# High wheat suitability: mean GAEZ category <= 5 (lower = more suitable)
d$wheat_suit <- as.numeric(d$wheat_tmean <= 5)
# River suitability: river length in terrain with ruggedness between 2 and 6
d$river_suit <- d$riv_rug26count
d$iv <- d$river_suit * d$wheat_suit

s <- subset(d, !is.na(mills_pc) & !is.na(w_pc))
cat("Districts with Domesday mill data:", nrow(s), "; counties:", length(unique(s$GAZ_CNTY)), "\n")

main  <- "longitude + latitude + dist_rug_mean + dist_elevation_mean"
agri  <- "suitmean + wheat_suit + dist_grass_mean"
agri_nowheat <- "suitmean + dist_grass_mean"
clim  <- "precip_mean_dist + temp_mean_dist"
other <- "pcmean + min_harbor + DIST_London + min_dist_to_roman_rds + min_dist_2nav_rivers + area"
cl <- ~GAZ_CNTY

f2 <- list(
  "w_pc ~ mills_pc",
  paste("w_pc ~ mills_pc +", main),
  paste("w_pc ~ mills_pc +", main, "+", agri),
  paste("w_pc ~ mills_pc +", main, "+", agri, "+", clim),
  paste("w_pc ~ mills_pc +", main, "+", agri, "+", clim, "+", other))
t2 <- lapply(f2, function(f) feols(as.formula(f), data = s, cluster = cl))
etable(t2, se.below = TRUE)

# Table 3
ols5 <- feols(as.formula(paste("w_pc ~ mills_pc + river_suit +", main, "+", agri, "+", clim, "+", other)), data = s, cluster = cl)
iv2 <- feols(w_pc ~ river_suit + wheat_suit | mills_pc ~ iv, data = s, cluster = cl)
iv4 <- feols(as.formula(paste("w_pc ~ river_suit + wheat_suit +", main, "+", agri_nowheat, "+", clim, "| mills_pc ~ iv")), data = s, cluster = cl)
iv6 <- feols(as.formula(paste("w_pc ~ river_suit + wheat_suit +", main, "+", agri_nowheat, "+", clim, "+", other, "| mills_pc ~ iv")), data = s, cluster = cl)
etable(ols5, iv2, iv4, iv6, se.below = TRUE)

fF <- function(m) {
  # first-stage F for the single excluded instrument: squared t of iv in first stage
  fs <- m$iv_first_stage[[1]]
  c(cluster = unname((coef(fs)["iv"] / se(fs, cluster = cl)["iv"])^2),
    hetero  = unname((coef(fs)["iv"] / se(fs, vcov = "hetero")["iv"])^2),
    iid     = unname((coef(fs)["iv"] / se(fs, vcov = "iid")["iv"])^2))
}
F2 <- fF(iv2); F4 <- fF(iv4); F6 <- fF(iv6)
cat("First-stage F (cluster / HC1 / iid):\n"); print(rbind(F2, F4, F6))

cat(sprintf("RESULT:watermills_table2_col1=%.6f\n", coef(t2[[1]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col2=%.6f\n", coef(t2[[2]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col3=%.6f\n", coef(t2[[3]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col4=%.6f\n", coef(t2[[4]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col5=%.6f\n", coef(t2[[5]])["mills_pc"]))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", coef(ols5)["mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", coef(iv2)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", coef(iv4)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", coef(iv6)["fit_mills_pc"]))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.4f\n", F2["cluster"]))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.4f\n", F4["cluster"]))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.4f\n", F6["cluster"]))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", nobs(t2[[5]])))
