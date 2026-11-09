# Independent reproduction: Acemoglu, De Feo, De Luca, Russo (2022 QJE)
# "War, Socialism, and the Rise of Fascism" -- Tables I, II, III (selected cells)
set.seed(42)
suppressMessages({library(haven); library(fixest)})

d <- as.data.frame(read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/independent/2026-11-07-a/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta"))
d <- zap_labels(d)
cat("Rows:", nrow(d), "\n")
cat("lpop vars:", grep("^lpop", names(d), value = TRUE), "\n")

# ---- controls -------------------------------------------------------------
# Demographic: quartic in log population (1911) + share of pop below 6 in 1911
d$lp1 <- d$lpop1911; d$lp2 <- d$lpop1911^2; d$lp3 <- d$lpop1911^3; d$lp4 <- d$lpop1911^4
demo  <- c("lp1", "lp2", "lp3", "lp4", "sh_pop_1911_be6")
geo   <- c("larea", "centre_alt", "max_alt")
soc13 <- "psu1913_vv"
mil   <- c("veterans74_95", "veterans96_00", "ard_vol_pop6m", "army_suppliers_d", "cruent_d")
agr   <- c("dlab", "shcrop", "landlord_ass")
urb   <- c("ind_workers", "ind_firms", "literacy", "elites", "bourgeoisie")
# Regiment fixed effects: dummies for any deaths from the municipality in a regiment
regs  <- grep("^d_reg", names(d), value = TRUE)
cat("Regiment dummies:", length(regs), "\n")
# Province fixed effects absorbed via provincia1921; cluster by district (circondario1921)
d$prov <- as.factor(d$provincia1921)
d$dist <- as.factor(d$circondario1921)
cat("Provinces:", nlevels(d$prov), " Districts:", nlevels(d$dist), "\n")

ctrl1 <- c(demo, regs)
ctrl6 <- c(demo, geo, soc13, mil, agr, urb, regs)

# drop regiment dummies that never vary (all zero)
keepvar <- function(v) length(unique(d[[v]][!is.na(d[[v]])])) > 1
ctrl1 <- Filter(keepvar, ctrl1); ctrl6 <- Filter(keepvar, ctrl6)

rhs <- function(ctrls) paste(ctrls, collapse = " + ")

# standardized coefficient = b * sd(x) / sd(y) on the estimation sample
stdcoef <- function(m, y, x, data) {
  s <- data[obs(m), ]
  unname(coef(m)[x] * sd(s[[x]]) / sd(s[[y]]))
}

# ---- Table I: first stage --------------------------------------------------
fs <- function(ctrls) {
  f <- as.formula(paste("psu1919_vv ~ foots_pop6m +", rhs(ctrls), "| prov"))
  feols(f, data = d, cluster = ~dist, fixef.rm = "none")
}
fs1 <- fs(ctrl1); fs6 <- fs(ctrl6)
b_fs1 <- stdcoef(fs1, "psu1919_vv", "foots_pop6m", d)
b_fs6 <- stdcoef(fs6, "psu1919_vv", "foots_pop6m", d)
t6 <- coeftable(fs6)["foots_pop6m", "t value"]
F6 <- unname(t6^2)
cat("FS col1 std:", b_fs1, " se(std):", se(fs1)["foots_pop6m"] * sd(d$foots_pop6m) / sd(d$psu1919_vv), " F:", unname(coeftable(fs1)["foots_pop6m","t value"]^2), "\n")
cat("FS col6 std:", b_fs6, " F:", F6, " N:", nobs(fs6), " R2:", r2(fs6, "r2"), "\n")

# ---- 2SLS ------------------------------------------------------------------
iv <- function(y, ctrls) {
  f <- as.formula(paste(y, "~", rhs(ctrls), "| prov | psu1919_vv ~ foots_pop6m"))
  feols(f, data = d, cluster = ~dist, fixef.rm = "none")
}
ivstd <- function(m, y) {
  s <- d[obs(m), ]
  unname(coef(m)["fit_psu1919_vv"] * sd(s$psu1919_vv) / sd(s[[y]]))
}
ncl <- function(m) length(unique(d$dist[obs(m)]))

m_viol6   <- iv("fascist_violence", ctrl6)
m_branch6 <- iv("fascist_branch", ctrl6)
m_v21_6   <- iv("fascist1921_vv", ctrl6)
m_v24_1   <- iv("fascist1924_vv", ctrl1)
m_v24_6   <- iv("fascist1924_vv", ctrl6)

for (nm in c("m_viol6", "m_branch6", "m_v21_6", "m_v24_1", "m_v24_6")) {
  m <- get(nm)
  cat(nm, ": raw b =", coef(m)["fit_psu1919_vv"], " se =", se(m)["fit_psu1919_vv"],
      " N =", nobs(m), " clusters =", ncl(m), "\n")
}

res <- c(
  first_stage_casualties_table1_col1     = b_fs1,
  first_stage_casualties_table1_col6     = b_fs6,
  first_stage_fstat_table1_col6          = F6,
  iv_violence_table2_panelA_col6         = ivstd(m_viol6, "fascist_violence"),
  iv_branches_table2_panelC_col6         = ivstd(m_branch6, "fascist_branch"),
  iv_fascist_vote1921_table3_panelA_col6 = ivstd(m_v21_6, "fascist1921_vv"),
  iv_fascist_vote1924_table3_panelC_col1 = ivstd(m_v24_1, "fascist1924_vv"),
  iv_fascist_vote1924_table3_panelC_col6 = ivstd(m_v24_6, "fascist1924_vv"),
  n_obs_main_sample                      = nobs(fs6),
  n_clusters_main_sample                 = ncl(fs6),
  n_obs_fascist_vote1921                 = nobs(m_v21_6),
  n_clusters_fascist_vote1921            = ncl(m_v21_6)
)
for (k in names(res)) cat(sprintf("RESULT:%s=%.6g\n", k, res[[k]]))
