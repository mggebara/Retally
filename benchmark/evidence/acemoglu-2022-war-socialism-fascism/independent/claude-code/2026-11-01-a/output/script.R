# Independent reproduction: Acemoglu, De Feo, De Luca, Russo (2022), QJE
# "War, Socialism, and the Rise of Fascism" -- Tables I-III key estimates.
set.seed(42)
suppressPackageStartupMessages({ library(haven); library(fixest) })

d <- read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/independent/2026-11-01-a/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta")
d <- as.data.frame(zap_labels(d))
d$provincia1921 <- as.character(d$provincia1921)
d$circondario1921 <- as.character(d$circondario1921)

reg_vars <- grep("^d_reg", names(d), value = TRUE)   # regiment dummies (any deaths in regiment)
demo  <- c("lpop1911", "lpop2", "lpop3", "lpop4", "sh_pop_1911_be6")
geo   <- c("larea", "centre_alt", "max_alt")
soc13 <- "psu1913_vv"
mil   <- c("veterans74_95", "veterans96_00", "ard_vol_pop6m", "army_suppliers_d", "cruent_d")
agr   <- c("dlab", "shcrop", "landlord_ass")
urb   <- c("ind_workers", "ind_firms", "literacy", "elites", "bourgeoisie")
ctrl1 <- c(demo, reg_vars)
ctrl6 <- c(demo, geo, soc13, mil, agr, urb, reg_vars)

# Standardized coefficients: standardize LHS, endogenous regressor and instrument
# (z-scores over the full municipality sample; dummies/controls left as is --
# they do not affect the reported coefficient).
z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
for (v in c("psu1919_vv", "foots_pop6m", "fascist_violence", "fascist_branch",
            "fascist1921_vv", "fascist1924_vv")) d[[paste0("z_", v)]] <- z(d[[v]])

rhs <- function(ctrl) paste(ctrl, collapse = " + ")
# Keep singleton province FE observations (as a dummy-variable regression in Stata
# would): the paper uses all 5,775 municipalities in 181 districts.


fs <- function(ctrl) feols(as.formula(paste("z_psu1919_vv ~ z_foots_pop6m +", rhs(ctrl), "| provincia1921")),
                           data = d, cluster = ~circondario1921, fixef.rm = "none")
iv <- function(y, ctrl) feols(as.formula(paste0("z_", y, " ~ ", rhs(ctrl), " | provincia1921 | z_psu1919_vv ~ z_foots_pop6m")),
                              data = d, cluster = ~circondario1921, fixef.rm = "none")

fs1 <- fs(ctrl1); fs6 <- fs(ctrl6)
b_fs1 <- coef(fs1)["z_foots_pop6m"]; b_fs6 <- coef(fs6)["z_foots_pop6m"]
F6 <- (b_fs6 / se(fs6)["z_foots_pop6m"])^2   # cluster-robust F for single excluded instrument

ivv6  <- iv("fascist_violence", ctrl6)
ivb6  <- iv("fascist_branch", ctrl6)
iv21  <- iv("fascist1921_vv", ctrl6)
iv24a <- iv("fascist1924_vv", ctrl1)
iv24f <- iv("fascist1924_vv", ctrl6)

g <- function(m) coef(m)["fit_z_psu1919_vv"]
ncl <- function(m) length(unique(d$circondario1921[obs(m)]))

cat("First stage col1: b=", b_fs1, " se=", se(fs1)["z_foots_pop6m"], " N=", nobs(fs1), " cl=", ncl(fs1), "\n")
cat("First stage col6: b=", b_fs6, " se=", se(fs6)["z_foots_pop6m"], " F=", F6, " R2=", r2(fs6, "r2"), "\n")
for (nm in c("ivv6", "ivb6", "iv21", "iv24a", "iv24f")) {
  m <- get(nm); cat(nm, ": b=", g(m), " se=", se(m)["fit_z_psu1919_vv"], " N=", nobs(m), " cl=", ncl(m), "\n")
}

cat(sprintf("RESULT:first_stage_casualties_table1_col1=%.4f\n", b_fs1))
cat(sprintf("RESULT:first_stage_casualties_table1_col6=%.4f\n", b_fs6))
cat(sprintf("RESULT:first_stage_fstat_table1_col6=%.4f\n", F6))
cat(sprintf("RESULT:iv_violence_table2_panelA_col6=%.4f\n", g(ivv6)))
cat(sprintf("RESULT:iv_branches_table2_panelC_col6=%.4f\n", g(ivb6)))
cat(sprintf("RESULT:iv_fascist_vote1921_table3_panelA_col6=%.4f\n", g(iv21)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col1=%.4f\n", g(iv24a)))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col6=%.4f\n", g(iv24f)))
cat(sprintf("RESULT:n_obs_main_sample=%d\n", nobs(fs6)))
cat(sprintf("RESULT:n_clusters_main_sample=%d\n", ncl(fs6)))
cat(sprintf("RESULT:n_obs_fascist_vote1921=%d\n", nobs(iv21)))
cat(sprintf("RESULT:n_clusters_fascist_vote1921=%d\n", ncl(iv21)))
