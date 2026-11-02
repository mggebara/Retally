# Acemoglu, De Feo, De Luca, Russo (2022) - Tables I-III, translated from Tables1-7.do
suppressPackageStartupMessages({library(haven); library(fixest)})
set.seed(42)
d <- as.data.frame(read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/seeded/2026-11-02-b/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta"))
nm <- names(d)
# egen z_x = std(x): standardize over all non-missing observations
zs <- function(x) { x <- as.numeric(x); (x - mean(x, na.rm=TRUE)) / sd(x, na.rm=TRUE) }
base <- c("psu1919_vv","foots_pop6m","lpop1911","lpop2","lpop3","lpop4","sh_pop_1911_be6",
          "larea","centre_alt","max_alt","psu1913_vv","veterans74_95","veterans96_00",
          "ard_vol_pop6m","cruent_d","army_suppliers_d","dlab","shcrop","landlord_ass",
          "ind_workers","ind_firms","literacy","elites","bourgeoisie",
          "fascist_violence","fascist_branch","fascist1921_vv","fascist1924_vv")
for (v in base) d[[paste0("z_", v)]] <- zs(d[[v]])
dreg <- grep("^d_reg", nm, value=TRUE)
prov <- grep("^province", nm, value=TRUE)
for (v in c(dreg, prov)) d[[v]] <- as.numeric(d[[v]])
d$circondario1921 <- as.character(d$circondario1921)  # string district id

s1 <- c("z_lpop1911","z_lpop2","z_lpop3","z_lpop4","z_sh_pop_1911_be6")
s2 <- c(s1, "z_larea","z_centre_alt","z_max_alt")
s3 <- c(s2, "z_psu1913_vv")
s4 <- c(s3, "z_veterans74_95","z_veterans96_00","z_ard_vol_pop6m","z_cruent_d","z_army_suppliers_d")
s5 <- c(s4, "z_dlab","z_shcrop","z_landlord_ass")
s6 <- c(s5, "z_ind_workers","z_ind_firms","z_literacy","z_elites","z_bourgeoisie")
spec <- list(s1, s2, s3, s4, s5, s6)
# regiment (d_reg*) and province (province*) dummies entered as regressors, as in Stata's reg/ivreg2
fe <- c(dreg, prov)

ctl <- function(i) paste(c(spec[[i]], fe), collapse=" + ")

first_stage <- function(i) {
  f <- as.formula(paste("z_psu1919_vv ~ z_foots_pop6m +", ctl(i)))
  feols(f, data=d, cluster=~circondario1921)
}
iv <- function(y, i) {
  f <- as.formula(paste(y, "~", ctl(i), "| z_psu1919_vv ~ z_foots_pop6m"))
  feols(f, data=d, cluster=~circondario1921)
}

fs1 <- first_stage(1); fs6 <- first_stage(6)
b1 <- unname(coef(fs1)["z_foots_pop6m"]); b6 <- unname(coef(fs6)["z_foots_pop6m"])
# Stata: test z_foots_pop6m after reg, cl() -> F = (b/se)^2 with cluster small-sample adjustment
F6 <- unname((coef(fs6)["z_foots_pop6m"] / se(fs6)["z_foots_pop6m"])^2)
cat("FS col1:", b1, " col6:", b6, " F6:", F6, " N:", nobs(fs6), "\n")

ivA6 <- iv("z_fascist_violence", 6)
ivC6 <- iv("z_fascist_branch", 6)
iv21 <- iv("z_fascist1921_vv", 6)
iv24_1 <- iv("z_fascist1924_vv", 1)
iv24_6 <- iv("z_fascist1924_vv", 6)
g <- function(m) unname(coef(m)["fit_z_psu1919_vv"])
ncl <- function(m) length(unique(d$circondario1921[obs(m)]))

cat(sprintf("RESULT:first_stage_casualties_table1_col1=%.6f\n", b1))
cat(sprintf("RESULT:first_stage_casualties_table1_col6=%.6f\n", b6))
cat(sprintf("RESULT:first_stage_fstat_table1_col6=%.6f\n", F6))
cat(sprintf("RESULT:iv_violence_table2_panelA_col6=%.6f\n", g(ivA6)))
cat(sprintf("RESULT:iv_branches_table2_panelC_col6=%.6f\n", g(ivC6)))
cat(sprintf("RESULT:iv_fascist_vote1921_table3_panelA_col6=%.6f\n", g(iv21)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col1=%.6f\n", g(iv24_1)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col6=%.6f\n", g(iv24_6)))
cat(sprintf("RESULT:n_obs_main_sample=%d\n", nobs(fs6)))
cat(sprintf("RESULT:n_clusters_main_sample=%d\n", ncl(fs6)))
cat(sprintf("RESULT:n_obs_fascist_vote1921=%d\n", nobs(iv21)))
cat(sprintf("RESULT:n_clusters_fascist_vote1921=%d\n", ncl(iv21)))
