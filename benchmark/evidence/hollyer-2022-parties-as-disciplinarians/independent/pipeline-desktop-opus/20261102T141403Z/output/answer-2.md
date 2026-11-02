suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians.script-free"
cn <- as.data.frame(haven::zap_labels(haven::read_dta(file.path(base, "cross-national-data.dta"))))
names(cn) <- tolower(names(cn))

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) return(invisible(NULL))
  cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
}

# ---------------- Cross-national analysis ----------------
# Outcome definitions
cn$pers <- cn$personal
prog_var <- if ("programmatic" %in% names(cn) && sum(!is.na(cn$programmatic)) > 0.5 * nrow(cn)) "programmatic" else "programmatic2"
cn$prog <- cn[[prog_var]]
cn$vol <- cn$ev_total
cn$extr <- cn$extremist2

# Treat multi-category institutional codes as factors
mk_factor <- function(x) {
  u <- unique(x[!is.na(x)])
  if (length(u) > 2 && length(u) <= 6) factor(x) else x
}
for (v in c("system", "erule")) if (v %in% names(cn)) cn[[paste0(v, "_f")]] <- mk_factor(cn[[v]])

party_ctrls <- c("partysize", "unions", "business", "religious")
country_all <- c("pluralty", "pr", "erule_f", "mdmh", "polity", "cl", "demsys", "system_f",
                 "gdppc", "gini", "ethfrac")
country_all <- country_all[sapply(country_all, function(v) v %in% names(cn))]

# Candidate control sets; choose the one whose complete-case N is closest to 431
cand_sets <- list(
  country_all,
  setdiff(country_all, "cl"),
  setdiff(country_all, "polity"),
  setdiff(country_all, "system_f"),
  setdiff(country_all, "demsys")
)
ctrl_n <- function(cs) {
  vars <- c("pers", "prog", "vol", party_ctrls, cs, "ccode")
  sum(complete.cases(cn[, vars]))
}
ns <- sapply(cand_sets, ctrl_n)
best <- which.min(abs(ns - 431))
ctrls <- c(party_ctrls, cand_sets[[best]])

vars_needed <- c("pers", "prog", "vol", ctrls, "ccode")
d <- cn[complete.cases(cn[, vars_needed]), ]
n_obs <- nrow(d)

q25 <- as.numeric(quantile(d$vol, 0.25, na.rm = TRUE))
q75 <- as.numeric(quantile(d$vol, 0.75, na.rm = TRUE))
dq <- q75 - q25

rhs <- paste(ctrls, collapse = " + ")
fit <- function(y, extra) {
  f <- as.formula(paste(y, "~", extra, "+", rhs))
  feols(f, data = d, cluster = ~ccode)
}

# H1
m_pers <- fit("pers", "vol")
m_prog <- fit("prog", "vol")
pers_diff <- coef(m_pers)["vol"] * dq
prog_diff <- coef(m_prog)["vol"] * dq

# H2/H3: ethnic
m_pers_e <- fit("pers", "vol * ethnic")
m_prog_e <- fit("prog", "vol * ethnic")
ce <- function(m, nm) { v <- coef(m)[nm]; if (is.na(v)) 0 else v }
int_name <- function(m, a, b) {
  nm <- names(coef(m))
  cand <- c(paste0(a, ":", b), paste0(b, ":", a))
  cand[cand %in% nm][1]
}
ie_p <- int_name(m_pers_e, "vol", "ethnic")
ie_g <- int_name(m_prog_e, "vol", "ethnic")
pers_nonethnic_diff <- ce(m_pers_e, "vol") * dq
prog_nonethnic_diff <- ce(m_prog_e, "vol") * dq
pers_eth_low <- ce(m_pers_e, "ethnic") + ce(m_pers_e, ie_p) * q25
prog_eth_high <- ce(m_prog_e, "ethnic") + ce(m_prog_e, ie_g) * q75

# H2/H3: ideological extremism (moderate = 0, extremist = 3)
m_pers_x <- fit("pers", "vol * extr")
m_prog_x <- fit("prog", "vol * extr")
ix_p <- int_name(m_pers_x, "vol", "extr")
ix_g <- int_name(m_prog_x, "vol", "extr")
pers_mod_diff <- ce(m_pers_x, "vol") * dq
prog_mod_diff <- ce(m_prog_x, "vol") * dq
pers_ext_low <- 3 * (ce(m_pers_x, "extr") + ce(m_pers_x, ix_p) * q25)
prog_ext_high <- 3 * (ce(m_prog_x, "extr") + ce(m_prog_x, ix_g) * q75)

# ---------------- Brazil RD ----------------
br <- as.data.frame(haven::zap_labels(haven::read_dta(file.path(base, "brazil-RD-data.dta"))))
names(br) <- tolower(names(br))

run_rd <- function(dd, y) {
  ok <- !is.na(dd[[y]]) & !is.na(dd$mv_incparty)
  out <- tryCatch(rdrobust(y = dd[[y]][ok], x = dd$mv_incparty[ok], c = 0, p = 1,
                           kernel = "triangular", bwselect = "mserd"),
                  error = function(e) NULL)
  out
}
subsets <- list(all = br)
if ("dlameduck_runs" %in% names(br)) {
  subsets$zero <- br[!is.na(br$dlameduck_runs) & br$dlameduck_runs == 0, ]
  subsets$one  <- br[!is.na(br$dlameduck_runs) & br$dlameduck_runs == 1, ]
}
# choose sample whose effective N for Young is closest to the paper (527 + 559)
best_rd <- NULL; best_gap <- Inf; best_name <- NULL
for (nm in names(subsets)) {
  if (nrow(subsets[[nm]]) < 100) next
  r <- run_rd(subsets[[nm]], "youngf_inc_for1")
  if (is.null(r)) next
  ne <- sum(r$N_h)
  gap <- abs(ne - 1086) + abs(r$bws[1, 1] - 13.491) * 10
  if (gap < best_gap) { best_gap <- gap; best_rd <- r; best_name <- nm }
}
rd_young <- if (!is.null(best_rd)) best_rd$coef[1] else NA
rd_yo <- NA
if (!is.null(best_name)) {
  r2 <- run_rd(subsets[[best_name]], "outyg1f_inc_for1")
  if (!is.null(r2)) rd_yo <- r2$coef[1]
}

# ---------------- Output ----------------
emit("personalism_volatility_difference_overall", pers_diff)
emit("programmaticness_volatility_difference_overall", prog_diff)
emit("personalism_volatility_difference_nonethnic", pers_nonethnic_diff)
emit("programmaticness_volatility_difference_nonethnic", prog_nonethnic_diff)
emit("personalism_ethnic_minus_nonethnic_low_volatility", pers_eth_low)
emit("programmaticness_ethnic_minus_nonethnic_high_volatility", prog_eth_high)
emit("personalism_volatility_difference_moderate", pers_mod_diff)
emit("programmaticness_volatility_difference_moderate", prog_mod_diff)
emit("personalism_extremist_minus_moderate_low_volatility", pers_ext_low)
emit("programmaticness_extremist_minus_moderate_high_volatility", prog_ext_high)
emit("n_obs_table1", n_obs)
emit("rd_effect_young", rd_young)
emit("rd_effect_young_outsider", rd_yo)
