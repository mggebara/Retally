## Independent reproduction: Acemoglu, De Feo, De Luca, Russo (2022 QJE)
## "War, Socialism, and the Rise of Fascism" -- Tables I-III key coefficients
set.seed(42)
suppressMessages({ library(haven); library(fixest) })

d <- read_dta('<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/independent/2026-11-02-c/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta')
d <- as.data.frame(zap_labels(d))

## Regiment fixed effects: dummies for any deaths from the municipality in a regiment
reg_d <- grep("^d_reg", names(d), value = TRUE)
reg_d <- reg_d[sapply(d[reg_d], function(x) var(x, na.rm = TRUE) > 0)]
cat("regiment dummies used:", length(reg_d), "\n")

## Standardize LHS, endogenous regressor and instrument (and continuous controls;
## coefficient of interest is invariant to the scaling of controls)
z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
stdvars <- c("psu1919_vv", "foots_pop6m", "fascist_violence", "fascist_branch",
             "fascist1921_vv", "fascist1924_vv")
for (v in stdvars) d[[paste0("z_", v)]] <- z(d[[v]])

demo  <- c("lpop1911", "lpop2", "lpop3", "lpop4", "sh_pop_1911_be6")
geo   <- c("larea", "centre_alt", "max_alt")
s13   <- c("psu1913_vv")
mil   <- c("veterans74_95", "veterans96_00", "ard_vol_pop6m", "army_suppliers_d", "cruent_d")
agr   <- c("dlab", "shcrop", "landlord_ass")
urb   <- c("ind_workers", "ind_firms", "literacy", "elites", "bourgeoisie")
ctrl1 <- c(demo, reg_d)
ctrl6 <- c(demo, geo, s13, mil, agr, urb, reg_d)

rhs <- function(v) paste(v, collapse = " + ")

## ---- Table I: first stage ----
fs1 <- feols(as.formula(paste("z_psu1919_vv ~ z_foots_pop6m +", rhs(ctrl1), "| provincia1921")),
             data = d, cluster = ~circondario1921)
fs6 <- feols(as.formula(paste("z_psu1919_vv ~ z_foots_pop6m +", rhs(ctrl6), "| provincia1921")),
             data = d, cluster = ~circondario1921)
b1 <- coef(fs1)["z_foots_pop6m"]; b6 <- coef(fs6)["z_foots_pop6m"]
t6 <- b6 / se(fs6)["z_foots_pop6m"]
F6 <- unname(t6^2)
cat("FS col1: b =", b1, " se =", se(fs1)["z_foots_pop6m"], "\n")
cat("FS col6: b =", b6, " se =", se(fs6)["z_foots_pop6m"], " F =", F6, "\n")
nobs_main <- nobs(fs6)
ncl_main  <- length(unique(d$circondario1921[obs(fs6)]))

## ---- 2SLS ----
iv <- function(y, ctrl) {
  feols(as.formula(paste(y, "~", rhs(ctrl), "| provincia1921 | z_psu1919_vv ~ z_foots_pop6m")),
        data = d, cluster = ~circondario1921)
}
iv_viol6   <- iv("z_fascist_violence", ctrl6)
iv_branch6 <- iv("z_fascist_branch", ctrl6)
iv_v21_6   <- iv("z_fascist1921_vv", ctrl6)
iv_v24_1   <- iv("z_fascist1924_vv", ctrl1)
iv_v24_6   <- iv("z_fascist1924_vv", ctrl6)
gb <- function(m) unname(coef(m)["fit_z_psu1919_vv"])
for (nm in c("iv_viol6", "iv_branch6", "iv_v21_6", "iv_v24_1", "iv_v24_6")) {
  m <- get(nm); cat(nm, ": b =", gb(m), " se =", se(m)["fit_z_psu1919_vv"], " N =", nobs(m), "\n")
}
nobs_21 <- nobs(iv_v21_6)
ncl_21  <- length(unique(d$circondario1921[obs(iv_v21_6)]))

cat(sprintf("RESULT:first_stage_casualties_table1_col1=%.6f\n", b1))
cat(sprintf("RESULT:first_stage_casualties_table1_col6=%.6f\n", b6))
cat(sprintf("RESULT:first_stage_fstat_table1_col6=%.6f\n", F6))
cat(sprintf("RESULT:iv_violence_table2_panelA_col6=%.6f\n", gb(iv_viol6)))
cat(sprintf("RESULT:iv_branches_table2_panelC_col6=%.6f\n", gb(iv_branch6)))
cat(sprintf("RESULT:iv_fascist_vote1921_table3_panelA_col6=%.6f\n", gb(iv_v21_6)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col1=%.6f\n", gb(iv_v24_1)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col6=%.6f\n", gb(iv_v24_6)))
cat(sprintf("RESULT:n_obs_main_sample=%d\n", nobs_main))
cat(sprintf("RESULT:n_clusters_main_sample=%d\n", ncl_main))
cat(sprintf("RESULT:n_obs_fascist_vote1921=%d\n", nobs_21))
cat(sprintf("RESULT:n_clusters_fascist_vote1921=%d\n", ncl_21))
