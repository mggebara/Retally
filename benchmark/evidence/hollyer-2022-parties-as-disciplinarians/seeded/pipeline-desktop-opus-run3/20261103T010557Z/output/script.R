suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians"

# ---------------------------------------------------------------
# Cross-national analysis (Table 1)
# ---------------------------------------------------------------
cn <- as.data.frame(zap_labels(read_dta(file.path(base, "cross-national-data.dta"))))
for (v in names(cn)) cn[[v]] <- as.numeric(cn[[v]])
cn$gini <- cn$gini / 100

# Stata "summarize, detail" percentile definition
stata_pct <- function(x, p) {
  x <- sort(x[!is.na(x)])
  n <- length(x)
  np <- n * p / 100
  k <- floor(np + 1e-12)
  if (abs(np - k) < 1e-9) {
    if (k == 0) return(x[1])
    return((x[k] + x[min(k + 1, n)]) / 2)
  }
  x[min(k + 1, n)]
}

p_controls <- c("partysize", "unions", "business", "religious")
c_controls <- c("pluralty", "pr", "cl", "mdmh", "system", "demsys", "polity",
                "gdppc", "gini", "ethfrac")

prep <- function(dv, extra) {
  vars <- unique(c(dv, "ev_total", extra, p_controls, c_controls, "ccode"))
  d <- cn[complete.cases(cn[, vars]), vars]
  d$cl_f <- relevel(factor(d$cl), ref = if ("3" %in% as.character(d$cl)) "3" else levels(factor(d$cl))[1])
  d$system_f <- relevel(factor(d$system), ref = if ("1" %in% as.character(d$system)) "1" else levels(factor(d$system))[1])
  d
}

rhs_controls <- "partysize + unions + business + religious + pluralty + pr + cl_f + mdmh + system_f + demsys + polity + gdppc + gini + ethfrac"

# --- Overall (H1)
fit_overall <- function(dv) {
  d <- prep(dv, character(0))
  m <- feols(as.formula(paste(dv, "~ ev_total +", rhs_controls)), data = d, cluster = ~ccode)
  lov <- stata_pct(d$ev_total, 25); hiv <- stata_pct(d$ev_total, 75)
  list(m = m, diff = unname(coef(m)["ev_total"]) * (hiv - lov), n = nobs(m))
}

# --- Interaction models (H2/H3)
fit_inter <- function(dv, z, hia_override = NULL) {
  d <- prep(dv, z)
  f <- as.formula(paste(dv, "~", z, "* ev_total +", rhs_controls))
  m <- feols(f, data = d, cluster = ~ccode)
  b <- coef(m)
  bz <- unname(b[z]); bv <- unname(b["ev_total"])
  bi <- unname(b[paste0(z, ":ev_total")])
  if (is.na(bi)) bi <- unname(b[paste0("ev_total:", z)])
  lov <- stata_pct(d$ev_total, 25); hiv <- stata_pct(d$ev_total, 75)
  hia <- if (is.null(hia_override)) stata_pct(d[[z]], 90) else hia_override
  list(
    m = m,
    hia = hia,
    diff_low_alpha = (hiv - lov) * bv,
    diff_high_alpha = (hiv - lov) * (bv + bi * hia),
    grp_low_vol = hia * (bz + bi * lov),
    grp_high_vol = hia * (bz + bi * hiv),
    n = nobs(m)
  )
}

o_pers <- fit_overall("personal")
o_prog <- fit_overall("programmatic")

e_pers <- fit_inter("personal", "ethnic")
e_prog <- fit_inter("programmatic", "ethnic")

x_pers <- fit_inter("personal", "extremist2")
x_prog <- fit_inter("programmatic", "extremist2")

# Paper-text variant: extremist party at distance 3
x3_pers <- fit_inter("personal", "extremist2", hia_override = 3)
x3_prog <- fit_inter("programmatic", "extremist2", hia_override = 3)

# ---------------------------------------------------------------
# Brazil RD (Table 2)
# ---------------------------------------------------------------
br <- as.data.frame(zap_labels(read_dta(file.path(base, "brazil-RD-data.dta"))))
for (v in names(br)) br[[v]] <- as.numeric(br[[v]])
idx <- !is.na(br$dlameduck_runs) & br$dlameduck_runs == 0

rr_y <- rdrobust(y = br$youngF_inc_for1[idx], x = br$mv_incparty[idx])
rr_yo <- rdrobust(y = br$outyg1F_inc_for1[idx], x = br$mv_incparty[idx])

# ---------------------------------------------------------------
# Output
# ---------------------------------------------------------------
out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))

out("personalism_volatility_difference_overall", o_pers$diff)
out("programmaticness_volatility_difference_overall", o_prog$diff)
out("personalism_volatility_difference_nonethnic", e_pers$diff_low_alpha)
out("programmaticness_volatility_difference_nonethnic", e_prog$diff_low_alpha)
out("personalism_ethnic_minus_nonethnic_low_volatility", e_pers$grp_low_vol)
out("programmaticness_ethnic_minus_nonethnic_high_volatility", e_prog$grp_high_vol)
out("personalism_volatility_difference_moderate", x_pers$diff_low_alpha)
out("programmaticness_volatility_difference_moderate", x_prog$diff_low_alpha)
out("personalism_extremist_minus_moderate_low_volatility", x_pers$grp_low_vol)
out("programmaticness_extremist_minus_moderate_high_volatility", x_prog$grp_high_vol)
out("personalism_extremist_minus_moderate_low_volatility_dist3", x3_pers$grp_low_vol)
out("programmaticness_extremist_minus_moderate_high_volatility_dist3", x3_prog$grp_high_vol)
out("extremist_p90_value", x_pers$hia)
out("n_obs_table1", o_pers$n)
out("rd_effect_young", rr_y$Estimate[1])
out("rd_effect_young_outsider", rr_yo$Estimate[1])