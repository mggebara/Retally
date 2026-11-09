suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians.script-free"

# ------------------------------------------------------------------
# Cross-national analysis (DALP 2009)
# ------------------------------------------------------------------
cn <- haven::read_dta(file.path(base, "cross-national-data.dta"))
cn <- as.data.frame(lapply(cn, function(v) { if (inherits(v, "haven_labelled")) as.numeric(zap_labels(v)) else v }))

cat("Cross-national data:", nrow(cn), "rows\n")
print(summary(cn))

# Volatility rescaled to 0-1
cn$vol <- as.numeric(cn$ev_total)
if (max(cn$vol, na.rm = TRUE) > 1.5) cn$vol <- cn$vol / 100

# Ethnic party indicator: majority of experts report ethnic ties
cn$ethnic_d <- as.numeric(cn$ethnic)
if (length(unique(na.omit(cn$ethnic_d))) > 2) cn$ethnic_d <- as.numeric(cn$ethnic_d > 0.5)

cn$extreme <- as.numeric(cn$extremist2)

few_levels <- function(v) length(unique(na.omit(v))) <= 6

# Country-level controls: electoral system (plurality, PR; mixed omitted), ballot rules
# (closed list, erule), district magnitude, political openness, length of democracy,
# separation of powers (system), development, inequality, ethnolinguistic fractionalisation
ctrl_terms <- c("partysize", "unions", "business", "religious",
                "pluralty", "pr", "cl",
                if (few_levels(cn$erule)) "factor(erule)" else "erule",
                "mdmh", "polity", "demsys",
                if (few_levels(cn$system)) "factor(system)" else "system",
                "gdppc", "gini", "ethfrac")

needed <- c("personal", "programmatic", "vol", "ethnic_d", "extreme",
            "partysize", "unions", "business", "religious", "pluralty", "pr", "cl",
            "erule", "mdmh", "polity", "demsys", "system", "gdppc", "gini", "ethfrac", "ccode")
est <- cn[complete.cases(cn[, needed]), ]
cat("Estimation sample:", nrow(est), "parties in", length(unique(est$ccode)), "countries\n")

q25 <- as.numeric(quantile(est$vol, 0.25))
q75 <- as.numeric(quantile(est$vol, 0.75))
dq <- q75 - q25
cat("Volatility 25th pct:", q25, " 75th pct:", q75, "\n")

ctrl <- paste(ctrl_terms, collapse = " + ")
fit <- function(y, extra = NULL) {
  rhs <- paste(c("vol", extra, ctrl), collapse = " + ")
  feols(as.formula(paste(y, "~", rhs)), data = est, cluster = ~ccode)
}

# Overall
m_pers <- fit("personal")
m_prog <- fit("programmatic")
print(summary(m_pers)); print(summary(m_prog))
pers_diff_overall <- coef(m_pers)["vol"] * dq
prog_diff_overall <- coef(m_prog)["vol"] * dq

# Ethnicity interaction
m_pers_e <- fit("personal", c("ethnic_d", "vol:ethnic_d"))
m_prog_e <- fit("programmatic", c("ethnic_d", "vol:ethnic_d"))
print(summary(m_pers_e)); print(summary(m_prog_e))
ce_p <- coef(m_pers_e); ce_g <- coef(m_prog_e)
pers_diff_nonethnic <- ce_p["vol"] * dq
prog_diff_nonethnic <- ce_g["vol"] * dq
pers_eth_low <- ce_p["ethnic_d"] + ce_p["vol:ethnic_d"] * q25
prog_eth_high <- ce_g["ethnic_d"] + ce_g["vol:ethnic_d"] * q75

# Ideology interaction (moderate = 0, extremist = 3)
m_pers_i <- fit("personal", c("extreme", "vol:extreme"))
m_prog_i <- fit("programmatic", c("extreme", "vol:extreme"))
print(summary(m_pers_i)); print(summary(m_prog_i))
ci_p <- coef(m_pers_i); ci_g <- coef(m_prog_i)
pers_diff_moderate <- ci_p["vol"] * dq
prog_diff_moderate <- ci_g["vol"] * dq
pers_ext_low <- 3 * (ci_p["extreme"] + ci_p["vol:extreme"] * q25)
prog_ext_high <- 3 * (ci_g["extreme"] + ci_g["vol:extreme"] * q75)

n_obs <- nobs(m_pers)

# ------------------------------------------------------------------
# Brazil RD
# ------------------------------------------------------------------
br <- haven::read_dta(file.path(base, "brazil-RD-data.dta"))
br <- as.data.frame(lapply(br, function(v) as.numeric(zap_labels(v))))
cat("Brazil RD data:", nrow(br), "rows\n")
print(summary(br))
print(table(br$dlameduck_runs, useNA = "ifany"))

# Open-seat sample: winner not term-limited (lame duck indicator == 0)
rdsamp <- br[!is.na(br$dlameduck_runs) & br$dlameduck_runs == 0, ]
cat("RD sample rows:", nrow(rdsamp), "\n")

run_rd <- function(y) {
  d <- rdsamp[!is.na(rdsamp[[y]]) & !is.na(rdsamp$mv_incparty), ]
  r <- rdrobust(y = d[[y]], x = d$mv_incparty, c = 0, p = 1, bwselect = "mserd")
  print(summary(r))
  as.numeric(r$coef[1])
}
rd_young <- run_rd("youngF_inc_for1")
rd_young_out <- run_rd("outyg1F_inc_for1")

# ------------------------------------------------------------------
# Results
# ------------------------------------------------------------------
out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
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
cat(sprintf("RESULT:n_obs_table1=%d\n", as.integer(n_obs)))
out("rd_effect_young", rd_young)
out("rd_effect_young_outsider", rd_young_out)