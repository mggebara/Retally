# Independent, blind reproduction: Acemoglu, De Feo, De Luca, Russo (2022 QJE)
# "War, Socialism, and the Rise of Fascism" -- Tables I-III selected cells.
set.seed(42)
suppressMessages({ library(haven); library(fixest) })

d <- read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/blind/2026-11-07-a/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta")
d <- as.data.frame(zap_labels(d))
d$prov <- as.character(d$provincia1921)
d$dist <- as.character(d$circondario1921)
cat("rows:", nrow(d), " provinces:", length(unique(d$prov)), " districts:", length(unique(d$dist)), "\n")
cat("check lpop2 == lpop1911^2:", max(abs(d$lpop2 - d$lpop1911^2)), "\n")

# Regiment dummies: any death from the municipality in a given regiment/unit
reg <- grep("^d_reg", names(d), value = TRUE)
reg <- reg[sapply(d[reg], function(x) var(x, na.rm = TRUE) > 0)]
cat("regiment dummies with variation:", length(reg), "\n")

demo  <- c("lpop1911", "lpop2", "lpop3", "lpop4", "sh_pop_1911_be6")
geo   <- c("larea", "centre_alt", "max_alt")
s13   <- "psu1913_vv"
mil   <- c("veterans74_95", "veterans96_00", "ard_vol_pop6m", "army_suppliers_d", "cruent_d")
agr   <- c("dlab", "shcrop", "landlord_ass")
urb   <- c("ind_workers", "ind_firms", "literacy", "elites", "bourgeoisie")
ctrl1 <- c(demo, reg)
ctrl6 <- c(demo, geo, s13, mil, agr, urb, reg)

z <- function(x) (x - mean(x)) / sd(x)

prep <- function(dat, y, ctrls) {
  vars <- unique(c(y, "psu1919_vv", "foots_pop6m", ctrls, "prov", "dist"))
  s <- dat[complete.cases(dat[, vars]), vars]
  for (v in setdiff(vars, c("prov", "dist", reg))) s[[v]] <- z(s[[v]])
  s
}

fs <- function(ctrls) {
  s <- prep(d, NULL, ctrls)
  f <- as.formula(paste("psu1919_vv ~ foots_pop6m +", paste(ctrls, collapse = "+"), "| prov"))
  m <- feols(f, data = s, cluster = ~dist)
  list(m = m, s = s)
}

iv <- function(y, ctrls) {
  s <- prep(d, y, ctrls)
  f <- as.formula(paste(y, "~", paste(ctrls, collapse = "+"), "| prov | psu1919_vv ~ foots_pop6m"))
  m <- feols(f, data = s, cluster = ~dist)
  list(m = m, s = s)
}

f1 <- fs(ctrl1); f6 <- fs(ctrl6)
b1 <- coef(f1$m)["foots_pop6m"]; b6 <- coef(f6$m)["foots_pop6m"]
t6 <- b6 / se(f6$m)["foots_pop6m"]
F6 <- unname(t6^2)
print(coeftable(f1$m)["foots_pop6m", ]); print(coeftable(f6$m)["foots_pop6m", ])

ivA6 <- iv("fascist_violence", ctrl6)
ivC6 <- iv("fascist_branch", ctrl6)
iv21 <- iv("fascist1921_vv", ctrl6)
iv24_1 <- iv("fascist1924_vv", ctrl1)
iv24_6 <- iv("fascist1924_vv", ctrl6)
for (m in list(ivA6, ivC6, iv21, iv24_1, iv24_6)) print(coeftable(m$m)["fit_psu1919_vv", ])
cat("1st-stage F within IV (fixest ivwald):\n"); print(fitstat(ivA6$m, "ivwald"))

nobs_main <- nobs(f6$m); ncl_main <- length(unique(f6$s$dist))
nobs21 <- nobs(iv21$m); ncl21 <- length(unique(iv21$s$dist))
stopifnot(nobs(f1$m) == nobs_main, nobs(iv24_1$m) == nobs_main)

out <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
out("first_stage_casualties_table1_col1", b1)
out("first_stage_casualties_table1_col6", b6)
out("first_stage_fstat_table1_col6", F6)
out("iv_violence_table2_panelA_col6", coef(ivA6$m)["fit_psu1919_vv"])
out("iv_branches_table2_panelC_col6", coef(ivC6$m)["fit_psu1919_vv"])
out("iv_fascist_vote1921_table3_panelA_col6", coef(iv21$m)["fit_psu1919_vv"])
out("iv_fascist_vote1924_table3_panelC_col1", coef(iv24_1$m)["fit_psu1919_vv"])
out("iv_fascist_vote1924_table3_panelC_col6", coef(iv24_6$m)["fit_psu1919_vv"])
cat(sprintf("RESULT:n_obs_main_sample=%d\n", nobs_main))
cat(sprintf("RESULT:n_clusters_main_sample=%d\n", ncl_main))
cat(sprintf("RESULT:n_obs_fascist_vote1921=%d\n", nobs21))
cat(sprintf("RESULT:n_clusters_fascist_vote1921=%d\n", ncl21))
