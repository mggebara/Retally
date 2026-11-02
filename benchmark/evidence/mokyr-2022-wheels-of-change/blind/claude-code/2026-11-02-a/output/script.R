## Mokyr, Sarid & van der Beek (2022, EJ) "The Wheels of Change" -- Tables 2 and 3
## Independent, blind reproduction from the paper text only.
set.seed(42)
suppressPackageStartupMessages({ library(haven); library(fixest) })

d <- as.data.frame(read_dta("<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/blind/2026-11-02-a/mount/mokyr_2022_wheels_of_change/3 replication package/Replication files/Data/replication_data.dta"))

## Per capita (per 10,000) using mean district population 1710-50 (pcmean).
## The common scale cancels in the coefficient; it is kept for readability.
d$w_pc     <- d$wrights / d$pcmean
d$mills_pc <- d$mills   / d$pcmean
## High wheat suitability: mean wheat suitability category <= 5 (lower = more suitable)
d$wheat_hi <- as.numeric(d$wheat_tmean <= 5)
## River suitability: length of rivers through terrain with ruggedness 2-6
d$riv_suit <- d$riv_rug26count
d$iv       <- d$riv_suit * d$wheat_hi

## Sample: districts with Domesday mill data
s <- d[!is.na(d$mills_pc) & !is.na(d$w_pc), ]
cat("N districts:", nrow(s), " counties:", length(unique(s$GAZ_CNTY)), "\n")

main  <- c("latitude", "longitude", "dist_rug_mean", "dist_elevation_mean")
agri  <- c("suitmean", "wheat_hi", "dist_grass_mean")
clim  <- c("precip_mean_dist", "temp_mean_dist")
other <- c("pcmean", "min_harbor", "DIST_London", "min_dist_to_roman_rds", "min_dist_2nav_rivers", "area")

f_ols <- function(ctrl) as.formula(paste("w_pc ~ mills_pc", if (length(ctrl)) paste("+", paste(ctrl, collapse = " + ")) else ""))
cl <- ~GAZ_CNTY

## ---- Table 2 (OLS) ----
t2 <- list(
  c1 = character(0),
  c2 = main,
  c3 = c(main, agri),
  c4 = c(main, agri, clim),
  c5 = c(main, agri, clim, other)
)
m2 <- lapply(t2, function(x) feols(f_ols(x), data = s, cluster = cl))
for (k in names(m2)) {
  ct <- coeftable(m2[[k]])["mills_pc", ]
  cat(sprintf("Table2 %s: b=%.4f se(cluster county)=%.4f N=%d\n", k, ct[1], ct[2], nobs(m2[[k]])))
}

## ---- Table 3 ----
## col 5 OLS: Table 2 col 5 + river suitability
c5ctrl <- unique(c("riv_suit", main, agri, clim, other))
m3_5 <- feols(f_ols(c5ctrl), data = s, cluster = cl)

f_iv <- function(ctrl) as.formula(paste("w_pc ~", paste(ctrl, collapse = " + "), "| mills_pc ~ iv"))
iv2ctrl <- c("riv_suit", "wheat_hi")
iv4ctrl <- unique(c("riv_suit", "wheat_hi", main, agri, clim))
iv6ctrl <- unique(c("riv_suit", "wheat_hi", main, agri, clim, other))
m3_2 <- feols(f_iv(iv2ctrl), data = s, cluster = cl)
m3_4 <- feols(f_iv(iv4ctrl), data = s, cluster = cl)
m3_6 <- feols(f_iv(iv6ctrl), data = s, cluster = cl)

## First-stage F for the single excluded instrument, using the same (county-clustered) VCOV
fsF <- function(m) {
  w <- fitstat(m, "ivwald1")[[1]]$stat  # model estimated with cluster = ~GAZ_CNTY
  w
}
fsF_iid <- function(m) fitstat(m, "ivf1")[[1]]$stat
fsF_het <- function(m) fitstat(m, "ivwald1", vcov = "hetero")[[1]]$stat

for (nm in c("m3_2", "m3_4", "m3_6")) {
  m <- get(nm); ct <- coeftable(m)["fit_mills_pc", ]
  cat(sprintf("Table3 %s IV: b=%.4f se=%.4f N=%d | 1st-stage F: cluster=%.3f hetero=%.3f iid=%.3f\n",
              nm, ct[1], ct[2], nobs(m), fsF(m), fsF_het(m), fsF_iid(m)))
}
ct <- coeftable(m3_5)["mills_pc", ]
cat(sprintf("Table3 col5 OLS: b=%.4f se=%.4f\n", ct[1], ct[2]))

cat(sprintf("RESULT:watermills_table2_col1=%.6f\n", coef(m2$c1)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col2=%.6f\n", coef(m2$c2)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col3=%.6f\n", coef(m2$c3)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col4=%.6f\n", coef(m2$c4)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col5=%.6f\n", coef(m2$c5)["mills_pc"]))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", coef(m3_5)["mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", coef(m3_2)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", coef(m3_4)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", coef(m3_6)["fit_mills_pc"]))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.6f\n", fsF(m3_2)))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.6f\n", fsF(m3_4)))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.6f\n", fsF(m3_6)))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", nobs(m2$c5)))
