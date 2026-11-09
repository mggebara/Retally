# Independent reproduction: Mokyr, Sarid & van der Beek (2022), Tables 2 and 3
suppressPackageStartupMessages({ library(haven); library(fixest) })
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/independent/2026-11-07-a/mount/mokyr_2022_wheels_of_change/3 replication package/Replication files/Data/replication_data.dta")
d <- as.data.frame(zap_labels(d))

# Per capita using mean district population 1710-50 (pcmean)
d$w_pc     <- d$wrights / d$pcmean
d$mills_pc <- d$mills / d$pcmean
# High wheat suitability: mean wheat category <= 5
d$wheat_hi <- as.numeric(d$wheat_tmean <= 5)
# River suitability: river length with ruggedness 2-6
d$riv_suit <- d$riv_rug26count
d$iv       <- d$riv_suit * d$wheat_hi

d <- d[!is.na(d$mills), ]
cat("N districts with Domesday mills:", nrow(d), "\n")

main  <- "latitude + longitude + dist_rug_mean + dist_elevation_mean"
agri  <- "suitmean + wheat_hi + dist_grass_mean"
clim  <- "precip_mean_dist + temp_mean_dist"
other <- "pcmean + min_harbor + DIST_London + min_dist_to_roman_rds + min_dist_2nav_rivers + area"
cl <- ~GAZ_CNTY

f <- function(rhs) as.formula(paste("w_pc ~ mills_pc", if (nchar(rhs)) paste("+", rhs) else ""))
t2 <- list(
  feols(f(""), d, cluster = cl),
  feols(f(main), d, cluster = cl),
  feols(f(paste(main, agri, sep = " + ")), d, cluster = cl),
  feols(f(paste(main, agri, clim, sep = " + ")), d, cluster = cl),
  feols(f(paste(main, agri, clim, other, sep = " + ")), d, cluster = cl)
)
print(etable(t2))

ols5_t3 <- feols(f(paste("riv_suit", main, agri, clim, other, sep = " + ")), d, cluster = cl)

ivf <- function(ctrl) as.formula(paste("w_pc ~", ctrl, "| mills_pc ~ iv"))
iv2 <- feols(ivf("riv_suit + wheat_hi"), d, cluster = cl)
iv4 <- feols(ivf(paste("riv_suit", main, agri, clim, sep = " + ")), d, cluster = cl)
iv6 <- feols(ivf(paste("riv_suit", main, agri, clim, other, sep = " + ")), d, cluster = cl)
print(etable(ols5_t3, iv2, iv4, iv6))

fs_F <- function(m) {
  w <- fitstat(m, "ivwald1")[[1]]$stat   # first-stage Wald F with the model's (clustered) VCOV
  u <- fitstat(m, "ivf1")[[1]]$stat      # classical first-stage F
  cat("first-stage F clustered Wald:", w, " iid F:", u, "\n")
  c(w = w, u = u)
}
F2 <- fs_F(iv2); F4 <- fs_F(iv4); F6 <- fs_F(iv6)
for (m in list(iv2, iv4, iv6)) { s <- summary(m$iv_first_stage[[1]], vcov = "hetero"); cat("first-stage F hetero:", (coef(s)["iv"]/se(s)["iv"])^2, "\n") }

cat(sprintf("RESULT:watermills_table2_col1=%.6f\n", coef(t2[[1]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col2=%.6f\n", coef(t2[[2]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col3=%.6f\n", coef(t2[[3]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col4=%.6f\n", coef(t2[[4]])["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col5=%.6f\n", coef(t2[[5]])["mills_pc"]))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", coef(ols5_t3)["mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", coef(iv2)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", coef(iv4)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", coef(iv6)["fit_mills_pc"]))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.4f\n", F2["w"]))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.4f\n", F4["w"]))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.4f\n", F6["w"]))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", nobs(t2[[5]])))
