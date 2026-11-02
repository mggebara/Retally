suppressMessages({library(haven); library(fixest)})
set.seed(42)
d <- haven::read_dta("<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/independent/2026-11-02-a/mount/mokyr_2022_wheels_of_change/3 replication package/Replication files/Data/replication_data.dta")
d <- as.data.frame(zap_labels(d))

# Per capita, using mean district population 1710-50 (pcmean)
d$wright_pc <- d$wrights / d$pcmean
d$mills_pc  <- d$mills / d$pcmean
d$wheat_suit <- as.numeric(d$wheat_tmean <= 5)          # high wheat suitability
d$river_suit <- d$riv_rug26count                       # river length with ruggedness 2-6
d$iv <- d$river_suit * d$wheat_suit
cat(sprintf("Diag: mean wright_pc=%.3f (paper 3.76), mean mills_pc=%.3f (paper 18.922)\n",
            mean(d$wright_pc), mean(d$mills_pc, na.rm = TRUE)))

s <- d[!is.na(d$mills_pc), ]
cat("Diag: N =", nrow(s), " clusters =", length(unique(s$GAZ_CNTY)), "\n")

main_geo <- c("latitude", "longitude", "dist_rug_mean", "dist_elevation_mean")
agri     <- c("suitmean", "wheat_suit", "dist_grass_mean")
clim     <- c("precip_mean_dist", "temp_mean_dist")
other    <- c("pcmean", "min_harbor", "DIST_London", "min_dist_to_roman_rds", "min_dist_2nav_rivers", "area")

ols <- function(ctrl) {
  f <- as.formula(paste("wright_pc ~ mills_pc", if (length(ctrl)) paste("+", paste(ctrl, collapse = " + ")) else ""))
  feols(f, data = s, cluster = ~GAZ_CNTY)
}
m1 <- ols(character(0))
m2 <- ols(main_geo)
m3 <- ols(c(main_geo, agri))
m4 <- ols(c(main_geo, agri, clim))
m5 <- ols(c(main_geo, agri, clim, other))
t3c5 <- ols(c(main_geo, agri, clim, other, "river_suit"))

ivm <- function(ctrl) {
  ctrl <- unique(c("river_suit", "wheat_suit", ctrl))
  f <- as.formula(paste("wright_pc ~", paste(ctrl, collapse = " + "), "| mills_pc ~ iv"))
  feols(f, data = s, cluster = ~GAZ_CNTY)
}
iv2 <- ivm(character(0))
iv4 <- ivm(c(main_geo, agri, clim))
iv6 <- ivm(c(main_geo, agri, clim, other))

fs_F <- function(m) {
  # cluster-robust Wald F on the excluded instrument in the first stage
  fs <- summary(m, stage = 1, cluster = ~GAZ_CNTY)
  unname((coef(fs)["iv"] / se(fs)["iv"])^2)
}
fs_F_iid <- function(m) unname(fitstat(m, "ivf1")[[1]]$stat)
fs_F_het <- function(m) {
  fs <- summary(m, stage = 1, vcov = "hetero"); unname((coef(fs)["iv"] / se(fs)["iv"])^2)
}

for (nm in c("m1","m2","m3","m4","m5","t3c5","iv2","iv4","iv6")) {
  m <- get(nm)
  cat(sprintf("Diag: %-5s b=%.4f se_cl=%.4f N=%d\n", nm, coef(m)[grep("mills_pc", names(coef(m)))[1]],
              se(m)[grep("mills_pc", names(coef(m)))[1]], nobs(m)))
}
for (nm in c("iv2","iv4","iv6")) {
  m <- get(nm)
  cat(sprintf("Diag: %s F cluster=%.2f iid=%.2f hetero=%.2f\n", nm, fs_F(m), fs_F_iid(m), fs_F_het(m)))
}

b <- function(m) unname(coef(m)[grep("mills_pc", names(coef(m)))[1]])
cat(sprintf("RESULT:watermills_table2_col1=%.6f\n", b(m1)))
cat(sprintf("RESULT:watermills_table2_col2=%.6f\n", b(m2)))
cat(sprintf("RESULT:watermills_table2_col3=%.6f\n", b(m3)))
cat(sprintf("RESULT:watermills_table2_col4=%.6f\n", b(m4)))
cat(sprintf("RESULT:watermills_table2_col5=%.6f\n", b(m5)))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", b(t3c5)))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", b(iv2)))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", b(iv4)))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", b(iv6)))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.4f\n", fs_F(iv2)))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.4f\n", fs_F(iv4)))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.4f\n", fs_F(iv6)))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", nobs(m1)))
