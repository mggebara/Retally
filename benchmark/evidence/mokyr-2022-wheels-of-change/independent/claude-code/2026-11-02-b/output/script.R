## Independent reproduction: Mokyr, Sarid & van der Beek (2022), "The Wheels of Change"
## Tables 2 and 3: wright apprentices per capita on Domesday watermills per capita.
set.seed(42)
suppressPackageStartupMessages({ library(haven); library(fixest) })

d <- read_dta("<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/independent/2026-11-02-b/mount/mokyr_2022_wheels_of_change/3 replication package/Replication files/Data/replication_data.dta")
d <- as.data.frame(zap_labels(d))

## Per-capita conversion using mean district population 1710-50 (pcmean)
d$wrights_pc <- d$wrights / d$pcmean
d$mills_pc   <- d$mills / d$pcmean
## High wheat suitability: mean wheat suitability category <= 5
d$wheat_suit <- as.numeric(d$wheat_tmean <= 5)
## River suitability: length of rivers through terrain with ruggedness 2-6
d$river_suit <- d$riv_rug26count
## Instrument: river suitability x wheat suitability
d$iv <- d$river_suit * d$wheat_suit

s <- d[!is.na(d$mills_pc), ]
cat(sprintf("Summary: mills_pc mean %.3f sd %.3f max %.3f; wrights_pc mean %.3f sd %.3f max %.3f; N=%d; counties=%d\n",
            mean(s$mills_pc), sd(s$mills_pc), max(s$mills_pc),
            mean(d$wrights_pc), sd(d$wrights_pc), max(d$wrights_pc), nrow(s), length(unique(s$GAZ_CNTY))))

geo  <- "latitude + longitude + dist_rug_mean + dist_elevation_mean"
agr  <- "suitmean + wheat_suit + dist_grass_mean"
agr_nowheat <- "suitmean + dist_grass_mean"
clim <- "precip_mean_dist + temp_mean_dist"
oth  <- "pcmean + min_harbor + DIST_London + min_dist_to_roman_rds + min_dist_2nav_rivers + area"

cl <- ~GAZ_CNTY
f <- function(rhs) as.formula(paste("wrights_pc ~ mills_pc", if (nchar(rhs)) paste("+", rhs) else ""))

## Table 2
t2 <- list(
  c1 = feols(f(""), s, cluster = cl),
  c2 = feols(f(geo), s, cluster = cl),
  c3 = feols(f(paste(geo, agr, sep = " + ")), s, cluster = cl),
  c4 = feols(f(paste(geo, agr, clim, sep = " + ")), s, cluster = cl),
  c5 = feols(f(paste(geo, agr, clim, oth, sep = " + ")), s, cluster = cl)
)
for (n in names(t2)) cat(sprintf("Table2 %s: b=%.4f se=%.4f N=%d adjR2=%.3f\n", n,
  coef(t2[[n]])["mills_pc"], se(t2[[n]])["mills_pc"], nobs(t2[[n]]), r2(t2[[n]], "ar2")))

## Table 3 OLS col 5: Table 2 col 5 + river suitability
ols5 <- feols(f(paste("river_suit", geo, agr, clim, oth, sep = " + ")), s, cluster = cl)

## Table 3 IVs
ivf <- function(ctrl) as.formula(paste("wrights_pc ~", ctrl, "| mills_pc ~ iv"))
c2ctrl <- "river_suit + wheat_suit"
c4ctrl <- paste(c2ctrl, geo, agr_nowheat, clim, sep = " + ")
c6ctrl <- paste(c4ctrl, oth, sep = " + ")
iv2 <- feols(ivf(c2ctrl), s, cluster = cl)
iv4 <- feols(ivf(c4ctrl), s, cluster = cl)
iv6 <- feols(ivf(c6ctrl), s, cluster = cl)

fs_F <- function(m) {
  # first-stage F on the single excluded instrument, cluster-robust (squared t)
  unname(fitstat(m, "ivwald1")[[1]]$stat)
}
fs_F_iid <- function(m) unname(fitstat(m, "ivf1")[[1]]$stat)
for (nm in c("iv2", "iv4", "iv6")) {
  m <- get(nm)
  cat(sprintf("Table3 %s: b=%.4f se=%.4f N=%d | FS F cluster=%.2f iid=%.2f hetero=%.2f\n", nm,
    coef(m)["fit_mills_pc"], se(m)["fit_mills_pc"], nobs(m), fs_F(m), fs_F_iid(m),
    unname(fitstat(summary(m, vcov = "hetero"), "ivwald1")[[1]]$stat)))
}
cat(sprintf("Table3 ols5: b=%.4f se=%.4f\n", coef(ols5)["mills_pc"], se(ols5)["mills_pc"]))

cat(sprintf("RESULT:watermills_table2_col1=%.6f\n", coef(t2$c1)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col2=%.6f\n", coef(t2$c2)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col3=%.6f\n", coef(t2$c3)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col4=%.6f\n", coef(t2$c4)["mills_pc"]))
cat(sprintf("RESULT:watermills_table2_col5=%.6f\n", coef(t2$c5)["mills_pc"]))
cat(sprintf("RESULT:watermills_ols_table3_col5=%.6f\n", coef(ols5)["mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col2=%.6f\n", coef(iv2)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col4=%.6f\n", coef(iv4)["fit_mills_pc"]))
cat(sprintf("RESULT:watermills_iv_table3_col6=%.6f\n", coef(iv6)["fit_mills_pc"]))
cat(sprintf("RESULT:first_stage_f_table3_col2=%.6f\n", fs_F(iv2)))
cat(sprintf("RESULT:first_stage_f_table3_col4=%.6f\n", fs_F(iv4)))
cat(sprintf("RESULT:first_stage_f_table3_col6=%.6f\n", fs_F(iv6)))
cat(sprintf("RESULT:n_districts_tables2_3=%d\n", nobs(t2$c5)))
