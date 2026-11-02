# Retally independent/blind reproduction: Acemoglu, De Feo, De Luca, Russo (2022 QJE)
# "War, Socialism, and the Rise of Fascism" -- Tables I-III
set.seed(42)
suppressPackageStartupMessages({ library(haven); library(fixest) })

d <- read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/blind/2026-11-02-c/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta")
d <- as.data.frame(zap_labels(d))
cat("Rows in fascism_db:", nrow(d), "\n")

# ---- variables -------------------------------------------------------------
reg_fe   <- grep("^d_reg", names(d), value = TRUE)          # regiment dummies (any deaths in regiment)
reg_fe   <- reg_fe[sapply(d[reg_fe], function(x) var(x, na.rm = TRUE) > 0)]
demo     <- c("lpop1911", "lpop2", "lpop3", "lpop4", "sh_pop_1911_be6")   # quartic in log pop + share < 6
geo      <- c("larea", "centre_alt", "max_alt")
soc13    <- c("psu1913_vv")
military <- c("veterans74_95", "veterans96_00", "ard_vol_pop6m", "army_suppliers_d", "cruent_d")
agri     <- c("dlab", "shcrop", "landlord_ass")
urban    <- c("ind_workers", "ind_firms", "literacy", "elites", "bourgeoisie")
cat("Regiment dummies used:", length(reg_fe), "\n")

ctrl <- list(
  c1 = c(demo, reg_fe),
  c2 = c(demo, reg_fe, geo),
  c3 = c(demo, reg_fe, geo, soc13),
  c4 = c(demo, reg_fe, geo, soc13, military),
  c5 = c(demo, reg_fe, geo, soc13, military, agri),
  c6 = c(demo, reg_fe, geo, soc13, military, agri, urban)
)

# check that the quartic terms are powers of lpop1911
cat("max |lpop2 - lpop1911^2|:", max(abs(d$lpop2 - d$lpop1911^2)), "\n")

# ---- standardization (full database; both sides) ---------------------------
zs <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
for (v in c("psu1919_vv", "foots_pop6m", "fascist_violence", "fascist_branch",
            "fascist1921_vv", "fascist1924_vv"))
  d[[paste0("z_", v)]] <- zs(d[[v]])

d$province <- factor(d$provincia1921)
d$district <- factor(d$circondario1921)

rhs <- function(cs) paste(c(cs, "province"), collapse = " + ")

# ---- Table I: first stage ---------------------------------------------------
fs <- list()
for (k in c("c1", "c6")) {
  f <- as.formula(paste("z_psu1919_vv ~ z_foots_pop6m +", rhs(ctrl[[k]])))
  fs[[k]] <- feols(f, data = d, cluster = ~district)
}
b1 <- coef(fs$c1)["z_foots_pop6m"]; b6 <- coef(fs$c6)["z_foots_pop6m"]
t6 <- b6 / se(fs$c6)["z_foots_pop6m"]
F6 <- unname(t6^2)
cat("First stage col1:", b1, " se", se(fs$c1)["z_foots_pop6m"], "\n")
cat("First stage col6:", b6, " se", se(fs$c6)["z_foots_pop6m"], " F", F6, "\n")
n_main  <- nobs(fs$c6)
cl_main <- length(unique(d$district[obs(fs$c6)]))
cat("N main:", n_main, " clusters:", cl_main, "\n")

# ---- 2SLS --------------------------------------------------------------------
iv <- function(y, k) {
  f <- as.formula(paste(y, "~", rhs(ctrl[[k]]), "| z_psu1919_vv ~ z_foots_pop6m"))
  feols(f, data = d, cluster = ~district)
}
m_viol6 <- iv("z_fascist_violence", "c6")
m_bran6 <- iv("z_fascist_branch", "c6")
m_v21_6 <- iv("z_fascist1921_vv", "c6")
m_v24_1 <- iv("z_fascist1924_vv", "c1")
m_v24_6 <- iv("z_fascist1924_vv", "c6")
for (m in list(m_viol6, m_bran6, m_v21_6, m_v24_1, m_v24_6))
  cat(as.character(m$fml)[2], " coef", coef(m)["fit_z_psu1919_vv"], " se", se(m)["fit_z_psu1919_vv"],
      " N", nobs(m), "\n")

n_21  <- nobs(m_v21_6)
cl_21 <- length(unique(d$district[obs(m_v21_6)]))

cat(sprintf("RESULT:first_stage_casualties_table1_col1=%.6f\n", b1))
cat(sprintf("RESULT:first_stage_casualties_table1_col6=%.6f\n", b6))
cat(sprintf("RESULT:first_stage_fstat_table1_col6=%.6f\n", F6))
cat(sprintf("RESULT:iv_violence_table2_panelA_col6=%.6f\n", coef(m_viol6)["fit_z_psu1919_vv"]))
cat(sprintf("RESULT:iv_branches_table2_panelC_col6=%.6f\n", coef(m_bran6)["fit_z_psu1919_vv"]))
cat(sprintf("RESULT:iv_fascist_vote1921_table3_panelA_col6=%.6f\n", coef(m_v21_6)["fit_z_psu1919_vv"]))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col1=%.6f\n", coef(m_v24_1)["fit_z_psu1919_vv"]))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col6=%.6f\n", coef(m_v24_6)["fit_z_psu1919_vv"]))
cat(sprintf("RESULT:n_obs_main_sample=%d\n", n_main))
cat(sprintf("RESULT:n_clusters_main_sample=%d\n", cl_main))
cat(sprintf("RESULT:n_obs_fascist_vote1921=%d\n", n_21))
cat(sprintf("RESULT:n_clusters_fascist_vote1921=%d\n", cl_21))
