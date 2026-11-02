# Retally blind independent reproduction: Acemoglu, De Feo, De Luca, Russo (2022 QJE)
# "War, Socialism, and the Rise of Fascism" -- Tables I-III (selected cells)
set.seed(42)
# Province FE are kept for all municipalities (no singleton removal), as with explicit province dummies.
suppressPackageStartupMessages({ library(haven); library(fixest) })

d <- as.data.frame(read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/blind/2026-11-01-a/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta"))
d <- zap_labels(d)

reg   <- grep("^d_reg", names(d), value = TRUE)          # regiment dummies (any death in regiment)
demo  <- c("lpop1911", "lpop2", "lpop3", "lpop4", "sh_pop_1911_be6")   # quartic in log pop + share < 6
geo   <- c("larea", "centre_alt", "max_alt")
soc13 <- "psu1913_vv"
mil   <- c("veterans74_95", "veterans96_00", "ard_vol_pop6m", "army_suppliers_d", "cruent_d")
agr   <- c("dlab", "shcrop", "landlord_ass")
urb   <- c("ind_workers", "ind_firms", "literacy", "elites", "bourgeoisie")
ctrl1 <- c(reg, demo)
ctrl6 <- c(reg, demo, geo, soc13, mil, agr, urb)

endo <- "psu1919_vv"; inst <- "foots_pop6m"
cat("regiment dummies:", length(reg), "\n")

zs <- function(x) (x - mean(x)) / sd(x)

# Build the estimation sample for a given outcome and control set, standardize
# outcome, endogenous regressor, instrument and controls within that sample.
prep <- function(y, ctrl) {
  vars <- unique(c(y, endo, inst, ctrl, "provincia1921", "circondario1921"))
  s <- d[complete.cases(d[, vars]), vars]
  for (v in unique(c(y, endo, inst, ctrl))) {
    if (sd(s[[v]]) > 0) s[[v]] <- zs(s[[v]]) else s[[v]] <- 0
  }
  s
}

fs <- function(ctrl) {
  s <- prep(endo, ctrl)
  f <- as.formula(paste(endo, "~", paste(c(inst, ctrl), collapse = " + "), "| provincia1921"))
  m <- feols(f, data = s, cluster = ~circondario1921, fixef.rm = "none")
  list(m = m, s = s)
}

iv <- function(y, ctrl) {
  s <- prep(y, ctrl)
  f <- as.formula(paste(y, "~", paste(ctrl, collapse = " + "), "| provincia1921 |", endo, "~", inst))
  m <- feols(f, data = s, cluster = ~circondario1921, fixef.rm = "none")
  list(m = m, s = s)
}

# Table I
t1c1 <- fs(ctrl1); t1c6 <- fs(ctrl6)
b1 <- coef(t1c1$m)[inst]; b6 <- coef(t1c6$m)[inst]
se6 <- se(t1c6$m)[inst]
F6 <- unname((b6 / se6)^2)   # cluster-robust Wald F for the single excluded instrument
cat("Table I col1:", b1, "se", se(t1c1$m)[inst], "N", nobs(t1c1$m), "\n")
cat("Table I col6:", b6, "se", se6, "N", nobs(t1c6$m), "\n")
cat("IV-model first-stage Wald (fixest ivwald1):\n")

# Table II / III
a6  <- iv("fascist_violence", ctrl6)
c6  <- iv("fascist_branch",   ctrl6)
v21 <- iv("fascist1921_vv",   ctrl6)
v24a <- iv("fascist1924_vv",  ctrl1)
v24f <- iv("fascist1924_vv",  ctrl6)
print(fitstat(a6$m, ~ivwald1))
for (nm in c("a6", "c6", "v21", "v24a", "v24f")) {
  m <- get(nm)$m
  cat(nm, ": b =", coef(m)[paste0("fit_", endo)], " se =", se(m)[paste0("fit_", endo)], " N =", nobs(m), "\n")
}

ncl <- function(s) length(unique(s$circondario1921))
n_main <- nobs(t1c6$m); cl_main <- ncl(t1c6$s)
n21 <- nobs(v21$m); cl21 <- ncl(v21$s)
cat("N main (col1/col6/IIA6/IIIC1):", nobs(t1c1$m), n_main, nobs(a6$m), nobs(v24a$m), "\n")

out <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
out("first_stage_casualties_table1_col1", b1)
out("first_stage_casualties_table1_col6", b6)
out("first_stage_fstat_table1_col6", F6)
out("iv_violence_table2_panelA_col6", coef(a6$m)[paste0("fit_", endo)])
out("iv_branches_table2_panelC_col6", coef(c6$m)[paste0("fit_", endo)])
out("iv_fascist_vote1921_table3_panelA_col6", coef(v21$m)[paste0("fit_", endo)])
out("iv_fascist_vote1924_table3_panelC_col1", coef(v24a$m)[paste0("fit_", endo)])
out("iv_fascist_vote1924_table3_panelC_col6", coef(v24f$m)[paste0("fit_", endo)])
out("n_obs_main_sample", n_main)
out("n_clusters_main_sample", cl_main)
out("n_obs_fascist_vote1921", n21)
out("n_clusters_fascist_vote1921", cl21)
