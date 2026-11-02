## Independent, blind reproduction: Acemoglu, De Feo, De Luca, Russo (2022 QJE)
## "War, Socialism, and the Rise of Fascism"
## Specification derived from paper text only (Tables I-III notes, Sections III-V).
set.seed(42)
suppressMessages({ library(haven); library(fixest) })

d <- read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/blind/2026-10-22-a/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta")
d <- as.data.frame(zap_labels(d))
cat("rows:", nrow(d), "\n")

## ---- variables ----
y_fs   <- "psu1919_vv"          # socialist vote share 1919 (endogenous / first-stage outcome)
z_inst <- "foots_pop6m"         # share of foot soldier casualties (instrument)
reg_d  <- grep("^d_reg", names(d), value = TRUE)   # regiment dummies (any death in regiment)
cat("regiment dummies:", length(reg_d), "\n")

demo  <- c("lpop1911", "lpop2", "lpop3", "lpop4", "sh_pop_1911_be6")
geo   <- c("larea", "centre_alt", "max_alt")
s13   <- c("psu1913_vv")
mil   <- c("veterans74_95", "veterans96_00", "ard_vol_pop6m", "army_suppliers_d", "cruent_d")
agr   <- c("dlab", "shcrop", "landlord_ass")
urb   <- c("ind_workers", "ind_firms", "literacy", "elites", "bourgeoisie")

ctrl <- list(
  c1 = c(demo),
  c2 = c(demo, geo),
  c3 = c(demo, geo, s13),
  c4 = c(demo, geo, s13, mil),
  c5 = c(demo, geo, s13, mil, agr),
  c6 = c(demo, geo, s13, mil, agr, urb)
)

## quick check that the quartic terms are powers of log population
cat("lpop2 == lpop1911^2 max abs diff:", max(abs(d$lpop2 - d$lpop1911^2)), "\n")

## ---- standardization ----
## Standardized coefficients: LHS, endogenous regressor and instrument standardized
## (mean 0, sd 1) over their non-missing values in the municipality database.
zs <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
outs <- c("fascist_violence", "fascist_branch", "fascist1921_vv", "fascist1924_vv")
for (v in c(y_fs, z_inst, outs)) d[[paste0("z_", v)]] <- zs(d[[v]])

rhs <- function(cs) paste(c(cs, reg_d), collapse = " + ")

first_stage <- function(cs, data) {
  f <- as.formula(paste0("z_", y_fs, " ~ z_", z_inst, " + ", rhs(cs), " | provincia1921"))
  feols(f, data = data, cluster = ~circondario1921)
}
iv <- function(yv, cs, data) {
  f <- as.formula(paste0("z_", yv, " ~ ", rhs(cs), " | provincia1921 | z_", y_fs, " ~ z_", z_inst))
  feols(f, data = data, cluster = ~circondario1921)
}

## ---- main sample: all municipalities with 1919 election data and controls ----
allv <- unique(c(y_fs, z_inst, unlist(ctrl), reg_d, "provincia1921", "circondario1921",
                 "fascist_violence", "fascist_branch", "fascist1924_vv"))
main <- d[complete.cases(d[, allv]), ]
cat("main sample:", nrow(main), " districts:", length(unique(main$circondario1921)), "\n")

## Table I
fs <- lapply(ctrl, first_stage, data = main)
for (k in names(fs)) {
  ct <- coeftable(fs[[k]])[paste0("z_", z_inst), ]
  cat(sprintf("Table I %s: b=%.4f se=%.4f F=%.2f N=%d\n", k, ct[1], ct[2], (ct[1]/ct[2])^2, nobs(fs[[k]])))
}
b_fs1 <- coef(fs$c1)[paste0("z_", z_inst)]
b_fs6 <- coef(fs$c6)[paste0("z_", z_inst)]
ct6   <- coeftable(fs$c6)[paste0("z_", z_inst), ]
F6    <- unname((ct6[1] / ct6[2])^2)
n_main  <- nobs(fs$c6)
g_main  <- length(unique(main$circondario1921[obs(fs$c6)]))

## Table II
iv_viol6   <- iv("fascist_violence", ctrl$c6, main)
iv_branch6 <- iv("fascist_branch",   ctrl$c6, main)
## Table III, Panel C
iv_v24_1 <- iv("fascist1924_vv", ctrl$c1, main)
iv_v24_6 <- iv("fascist1924_vv", ctrl$c6, main)

## Table III, Panel A: 1921 sample (fascist1921_vv available)
s21 <- main[!is.na(main$fascist1921_vv), ]
iv_v21_6 <- iv("fascist1921_vv", ctrl$c6, s21)
n_21 <- nobs(iv_v21_6)
g_21 <- length(unique(s21$circondario1921[obs(iv_v21_6)]))

endo <- paste0("fit_z_", y_fs)
show <- function(nm, m) {
  ct <- coeftable(m)[endo, ]
  cat(sprintf("%s: b=%.4f se=%.4f N=%d\n", nm, ct[1], ct[2], nobs(m)))
  unname(ct[1])
}
b_viol6   <- show("IV violence c6", iv_viol6)
b_branch6 <- show("IV branch c6", iv_branch6)
b_v21_6   <- show("IV vote1921 c6", iv_v21_6)
b_v24_1   <- show("IV vote1924 c1", iv_v24_1)
b_v24_6   <- show("IV vote1924 c6", iv_v24_6)

## ---- results ----
cat(sprintf("RESULT:first_stage_casualties_table1_col1=%.6f\n", b_fs1))
cat(sprintf("RESULT:first_stage_casualties_table1_col6=%.6f\n", b_fs6))
cat(sprintf("RESULT:first_stage_fstat_table1_col6=%.6f\n", F6))
cat(sprintf("RESULT:iv_violence_table2_panelA_col6=%.6f\n", b_viol6))
cat(sprintf("RESULT:iv_branches_table2_panelC_col6=%.6f\n", b_branch6))
cat(sprintf("RESULT:iv_fascist_vote1921_table3_panelA_col6=%.6f\n", b_v21_6))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col1=%.6f\n", b_v24_1))
cat(sprintf("RESULT:iv_fascist_vote1924_table3_panelC_col6=%.6f\n", b_v24_6))
cat(sprintf("RESULT:n_obs_main_sample=%d\n", as.integer(n_main)))
cat(sprintf("RESULT:n_clusters_main_sample=%d\n", as.integer(g_main)))
cat(sprintf("RESULT:n_obs_fascist_vote1921=%d\n", as.integer(n_21)))
cat(sprintf("RESULT:n_clusters_fascist_vote1921=%d\n", as.integer(g_21)))
