## Acemoglu et al. (2022) War, Socialism and the Rise of Fascism -- Tables I-III (seeded)
## Translation of Tables1-7.do: egen std on each variable, OLS/2SLS with regiment
## dummies (d_reg*), province dummies, controls; clustered by circondario1921.
suppressPackageStartupMessages({library(haven); library(fixest)})
set.seed(42)
d <- as.data.frame(read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/seeded/2026-10-22-a/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta"))
nm <- names(d)
zstd <- function(x) { x <- as.numeric(x); (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE) }
base <- c("psu1919_vv","foots_pop6m","fascist_violence","fascist_branch","fascist1921_vv","fascist1924_vv",
          "lpop1911","lpop2","lpop3","lpop4","sh_pop_1911_be6","larea","centre_alt","max_alt","psu1913_vv",
          "veterans74_95","veterans96_00","ard_vol_pop6m","cruent_d","army_suppliers_d","dlab","shcrop",
          "landlord_ass","ind_workers","ind_firms","literacy","elites","bourgeoisie")
for (v in base) d[[paste0("z_", v)]] <- zstd(d[[v]])
dreg <- nm[grepl("^d_reg", nm)]
prov <- nm[grepl("^province", nm)]
for (v in c(dreg, prov)) d[[v]] <- as.numeric(d[[v]])
fe <- c(dreg, prov)
spec <- list()
spec[[1]] <- c("z_lpop1911","z_lpop2","z_lpop3","z_lpop4","z_sh_pop_1911_be6", fe)
spec[[2]] <- c(spec[[1]], "z_larea","z_centre_alt","z_max_alt")
spec[[3]] <- c(spec[[2]], "z_psu1913_vv")
spec[[4]] <- c(spec[[3]], "z_veterans74_95","z_veterans96_00","z_ard_vol_pop6m","z_cruent_d","z_army_suppliers_d")
spec[[5]] <- c(spec[[4]], "z_dlab","z_shcrop","z_landlord_ass")
spec[[6]] <- c(spec[[5]], "z_ind_workers","z_ind_firms","z_literacy","z_elites","z_bourgeoisie")

cl <- ~circondario1921
ols_fs <- function(i) {
  f <- as.formula(paste("z_psu1919_vv ~ z_foots_pop6m +", paste(spec[[i]], collapse = " + ")))
  feols(f, data = d, cluster = cl, ssc = ssc(adj = TRUE, cluster.adj = TRUE))
}
iv <- function(y, i) {
  f <- as.formula(paste(y, "~", paste(spec[[i]], collapse = " + "), "| z_psu1919_vv ~ z_foots_pop6m"))
  feols(f, data = d, cluster = cl)
}
fs1 <- ols_fs(1); fs6 <- ols_fs(6)
b1 <- coef(fs1)["z_foots_pop6m"]; b6 <- coef(fs6)["z_foots_pop6m"]
F6 <- (b6 / se(fs6)["z_foots_pop6m"])^2
viol6 <- iv("z_fascist_violence", 6)
br6 <- iv("z_fascist_branch", 6)
v21_6 <- iv("z_fascist1921_vv", 6)
v24_1 <- iv("z_fascist1924_vv", 1)
v24_6 <- iv("z_fascist1924_vv", 6)
ncl <- function(m) length(unique(d$circondario1921[obs(m)]))
cat("DIAG fs6 N", nobs(fs6), " v21 N", nobs(v21_6), "\n")
cat(sprintf("RESULT:first_stage_casualties_table1_col1=%.6f\n", b1))
cat(sprintf("RESULT:first_stage_casualties_table1_col6=%.6f\n", b6))
cat(sprintf("RESULT:first_stage_fstat_table1_col6=%.6f\n", F6))
cat(sprintf("RESULT:iv_violence_table2_panelA_col6=%.6f\n", coef(viol6)["fit_z_psu1919_vv"]))
cat(sprintf("RESULT:iv_branches_table2_panelC_col6=%.6f\n", coef(br6)["fit_z_psu1919_vv"]))
cat(sprintf("RESULT:iv_fascist_vote1921_table3_panelA_col6=%.6f\n", coef(v21_6)["fit_z_psu1919_vv"]))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col1=%.6f\n", coef(v24_1)["fit_z_psu1919_vv"]))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col6=%.6f\n", coef(v24_6)["fit_z_psu1919_vv"]))
cat(sprintf("RESULT:n_obs_main_sample=%d\n", nobs(fs6)))
cat(sprintf("RESULT:n_clusters_main_sample=%d\n", ncl(fs6)))
cat(sprintf("RESULT:n_obs_fascist_vote1921=%d\n", nobs(v21_6)))
cat(sprintf("RESULT:n_clusters_fascist_vote1921=%d\n", ncl(v21_6)))
