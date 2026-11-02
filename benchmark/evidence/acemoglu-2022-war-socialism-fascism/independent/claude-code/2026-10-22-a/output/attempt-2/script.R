set.seed(42)
suppressPackageStartupMessages({ library(haven); library(fixest) })
d <- read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/independent/2026-10-22-a/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta")
d <- as.data.frame(zap_labels(d))
cat("lpop vars:", grep("^lpop", names(d), value = TRUE), "\n")

regs <- grep("^d_reg", names(d), value = TRUE)
# drop regiment dummies with no variation
regs <- regs[sapply(regs, function(v) length(unique(d[[v]][!is.na(d[[v]])])) > 1)]
cat("n regiment dummies:", length(regs), "\n")

lp <- d$lpop1911
d$lp1 <- lp; d$lp2 <- lp^2; d$lp3 <- lp^3; d$lp4 <- lp^4
demo <- c("lp1", "lp2", "lp3", "lp4", "sh_pop_1911_be6")
geo  <- c("larea", "centre_alt", "max_alt")
s13  <- "psu1913_vv"
mil  <- c("veterans74_95", "veterans96_00", "ard_vol_pop6m", "army_suppliers_d", "cruent_d")
agr  <- c("dlab", "shcrop", "landlord_ass")
urb  <- c("ind_workers", "ind_firms", "literacy", "elites", "bourgeoisie")
ctrl <- list(c1 = demo, c6 = c(demo, geo, s13, mil, agr, urb))

zs <- function(x) (x - mean(x)) / sd(x)
stdvars <- c("psu1919_vv", "foots_pop6m", "fascist_violence", "fascist_branch",
             "fascist1921_vv", "fascist1924_vv", demo, geo, s13, mil, agr, urb)

prep <- function(dep) {
  need <- unique(c(dep, "psu1919_vv", "foots_pop6m", stdvars, regs, "provincia1921", "circondario1921"))
  need <- intersect(need, names(d))
  s <- d[complete.cases(d[, c(dep, "psu1919_vv", "foots_pop6m", demo, geo, s13, mil, agr, urb,
                                "provincia1921", "circondario1921")]), ]
  for (v in intersect(stdvars, names(s))) s[[v]] <- zs(s[[v]])
  s
}

rhs <- function(cn) paste(c(ctrl[[cn]], regs), collapse = " + ")

fs <- function(cn) {
  s <- prep("psu1919_vv")
  f <- as.formula(paste("psu1919_vv ~ foots_pop6m +", rhs(cn), "| provincia1921"))
  feols(f, data = s, cluster = ~circondario1921)
}
iv <- function(dep, cn) {
  s <- prep(dep)
  f <- as.formula(paste(dep, "~", rhs(cn), "| provincia1921 | psu1919_vv ~ foots_pop6m"))
  feols(f, data = s, cluster = ~circondario1921)
}

out <- list()
m1 <- fs("c1"); m6 <- fs("c6")
print(coeftable(m1)["foots_pop6m", ]); print(coeftable(m6)["foots_pop6m", ])
out$first_stage_casualties_table1_col1 <- coef(m1)["foots_pop6m"]
out$first_stage_casualties_table1_col6 <- coef(m6)["foots_pop6m"]
out$first_stage_fstat_table1_col6 <- (coef(m6)["foots_pop6m"] / se(m6)["foots_pop6m"])^2
out$n_obs_main_sample <- nobs(m6)
out$n_clusters_main_sample <- length(unique(prep("psu1919_vv")$circondario1921))
cat("R2 col1:", r2(m1, "r2"), " col6:", r2(m6, "r2"), "\n")

v6 <- iv("fascist_violence", "c6"); print(coeftable(v6)["fit_psu1919_vv", ])
b6 <- iv("fascist_branch", "c6"); print(coeftable(b6)["fit_psu1919_vv", ])
f21 <- iv("fascist1921_vv", "c6"); print(coeftable(f21)["fit_psu1919_vv", ])
f24a <- iv("fascist1924_vv", "c1"); print(coeftable(f24a)["fit_psu1919_vv", ])
f24f <- iv("fascist1924_vv", "c6"); print(coeftable(f24f)["fit_psu1919_vv", ])
out$iv_violence_table2_panelA_col6 <- coef(v6)["fit_psu1919_vv"]
out$iv_branches_table2_panelC_col6 <- coef(b6)["fit_psu1919_vv"]
out$iv_fascist_vote1921_table3_panelA_col6 <- coef(f21)["fit_psu1919_vv"]
out$iv_fascist_vote1924_table3_panelC_col1 <- coef(f24a)["fit_psu1919_vv"]
out$iv_fascist_vote1924_table3_panelC_col6 <- coef(f24f)["fit_psu1919_vv"]
out$n_obs_fascist_vote1921 <- nobs(f21)
out$n_clusters_fascist_vote1921 <- length(unique(prep("fascist1921_vv")$circondario1921))

for (n in names(out)) cat(sprintf("RESULT:%s=%.6g\n", n, unname(out[[n]])))
