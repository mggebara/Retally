suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
  library(rdrobust)
})

set.seed(42)

base <- "<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians.script-free"

# ---------------------------------------------------------------
# Cross-national analysis (Table 1)
# ---------------------------------------------------------------
cn <- haven::read_dta(file.path(base, "cross-national-data.dta"))
cn <- haven::zap_labels(cn)
cn <- as.data.frame(cn)

cat("Cross-national data:", nrow(cn), "rows\n")
for (v in names(cn)) {
  x <- cn[[v]]
  if (is.numeric(x)) {
    cat(sprintf("  %-15s n=%d NA=%d min=%.3f max=%.3f nuniq=%d\n", v, sum(!is.na(x)), sum(is.na(x)),
                suppressWarnings(min(x, na.rm = TRUE)), suppressWarnings(max(x, na.rm = TRUE)),
                length(unique(na.omit(x)))))
  }
}

# Programmaticness: average of two items (constructed variable, programmatic2)
prog_var <- if ("programmatic2" %in% names(cn)) "programmatic2" else "programmatic"
cn$prog <- cn[[prog_var]]
cn$pers <- cn$personal

# Volatility rescaled to 0-1
cn$vol <- cn$ev_total
if (max(cn$vol, na.rm = TRUE) > 1.5) cn$vol <- cn$vol / 100

cn$extreme <- cn$extremist2
cn$ethnic <- as.numeric(cn$ethnic)

# Ballot rules (open / closed / mixed) as categorical
cn$erule_f <- factor(cn$erule)
# Separation-of-powers / democratic system as categorical if few levels
n_demsys <- length(unique(na.omit(cn$demsys)))
cn$demsys_f <- if (n_demsys <= 6) factor(cn$demsys) else cn$demsys

party_ctrl <- c("partysize", "unions", "business", "religious")
country_ctrl <- c("pluralty", "pr", "erule_f", "mdmh", "polity", "cl", "demsys_f",
                  "gdppc", "gini", "ethfrac")

needed <- c("pers", "prog", "vol", "ethnic", "extreme", "ccode", party_ctrl, country_ctrl)
smp <- cn[complete.cases(cn[, needed]), ]
cat("Estimation sample:", nrow(smp), "parties in", length(unique(smp$ccode)), "countries\n")

ctrl_str <- paste(c(party_ctrl, country_ctrl), collapse = " + ")

q25 <- as.numeric(quantile(smp$vol, 0.25))
q75 <- as.numeric(quantile(smp$vol, 0.75))
dq <- q75 - q25
cat(sprintf("Volatility p25=%.4f p75=%.4f\n", q25, q75))

fit <- function(y, extra = NULL) {
  rhs <- paste(c("vol", extra, ctrl_str), collapse = " + ")
  feols(as.formula(paste(y, "~", rhs)), data = smp, cluster = ~ccode)
}

# Overall
m_pers <- fit("pers")
m_prog <- fit("prog")
pers_diff_overall <- coef(m_pers)["vol"] * dq
prog_diff_overall <- coef(m_prog)["vol"] * dq
cat(sprintf("Overall: pers diff %.3f (SE %.3f); prog diff %.3f (SE %.3f)\n",
            pers_diff_overall, se(m_pers)["vol"] * dq,
            prog_diff_overall, se(m_prog)["vol"] * dq))

# Ethnicity interaction
m_pers_e <- fit("pers", c("ethnic", "vol:ethnic"))
m_prog_e <- fit("prog", c("ethnic", "vol:ethnic"))
gc <- function(m, n) { v <- coef(m); if (n %in% names(v)) v[[n]] else v[[sub("vol:(.*)", "\\1:vol", n)]] }
pers_diff_nonethnic <- gc(m_pers_e, "vol") * dq
prog_diff_nonethnic <- gc(m_prog_e, "vol") * dq
pers_eth_low <- gc(m_pers_e, "ethnic") + gc(m_pers_e, "vol:ethnic") * q25
prog_eth_high <- gc(m_prog_e, "ethnic") + gc(m_prog_e, "vol:ethnic") * q75

# Ideology interaction (extremist at distance 3)
m_pers_x <- fit("pers", c("extreme", "vol:extreme"))
m_prog_x <- fit("prog", c("extreme", "vol:extreme"))
pers_diff_moderate <- gc(m_pers_x, "vol") * dq
prog_diff_moderate <- gc(m_prog_x, "vol") * dq
pers_ext_low <- 3 * (gc(m_pers_x, "extreme") + gc(m_pers_x, "vol:extreme") * q25)
prog_ext_high <- 3 * (gc(m_prog_x, "extreme") + gc(m_prog_x, "vol:extreme") * q75)

n_obs <- nobs(m_pers)

# ---------------------------------------------------------------
# Brazil RD (Table 2)
# ---------------------------------------------------------------
br <- haven::read_dta(file.path(base, "brazil-RD-data.dta"))
br <- as.data.frame(haven::zap_labels(br))
cat("Brazil data:", nrow(br), "rows\n")
print(table(br$dlameduck_runs, useNA = "ifany"))

# Sample: winning candidate not term-limited (dlameduck_runs == 0)
brs <- br[!is.na(br$dlameduck_runs) & br$dlameduck_runs == 0, ]

run_rd <- function(yv) {
  d <- brs[!is.na(brs[[yv]]) & !is.na(brs$mv_incparty), ]
  r <- rdrobust(y = d[[yv]], x = d$mv_incparty, c = 0, p = 1, kernel = "triangular",
                bwselect = "mserd")
  cat(sprintf("RD %s: tau=%.4f robust p=%.4f CI [%.4f, %.4f] h=%.3f b=%.3f N-=%d N+=%d\n",
              yv, r$coef[1], r$pv[3], r$ci[3, 1], r$ci[3, 2], r$bws[1, 1], r$bws[2, 1],
              r$N_h[1], r$N_h[2]))
  r$coef[1]
}

rd_young <- tryCatch(run_rd("youngF_inc_for1"), error = function(e) { cat("RD error:", conditionMessage(e), "\n"); NA })
rd_young_out <- tryCatch(run_rd("outyg1F_inc_for1"), error = function(e) { cat("RD error:", conditionMessage(e), "\n"); NA })

# ---------------------------------------------------------------
# Results
# ---------------------------------------------------------------
out <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, as.numeric(v)))
out("personalism_volatility_difference_overall", pers_diff_overall)
out("programmaticness_volatility_difference_overall", prog_diff_overall)
out("personalism_volatility_difference_nonethnic", pers_diff_nonethnic)
out("programmaticness_volatility_difference_nonethnic", prog_diff_nonethnic)
out("personalism_ethnic_minus_nonethnic_low_volatility", pers_eth_low)
out("programmaticness_ethnic_minus_nonethnic_high_volatility", prog_eth_high)
out("personalism_volatility_difference_moderate", pers_diff_moderate)
out("programmaticness_volatility_difference_moderate", prog_diff_moderate)
out("personalism_extremist_minus_moderate_low_volatility", pers_ext_low)
out("programmaticness_extremist_minus_moderate_high_volatility", prog_ext_high)
out("n_obs_table1", n_obs)
out("rd_effect_young", rd_young)
out("rd_effect_young_outsider", rd_young_out)
