# Douenne & Fabre (2022), Yellow Vests, Pessimistic Beliefs, and Carbon Tax Aversion
# Independent, blind reproduction of Table 4 (cols 1-4), Table 6 col 1, Table 8 col 1.
set.seed(42)
suppressPackageStartupMessages(library(fixest))

load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-07-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")

# The data frame columns carry memisc classes (package not installed): strip to base vectors.
strip <- function(d) {
  L <- unclass(d); out <- vector("list", length(L))
  for (i in seq_along(L)) {
    x <- L[[i]]
    if (identical(oldClass(x), "factor")) out[[i]] <- as.character(x) else { attributes(x) <- NULL; out[[i]] <- x }
  }
  names(out) <- names(L); data.frame(out, stringsAsFactors = FALSE)
}
d <- strip(s)

# ---- Variables ----
d$Gamma  <- as.numeric(as.character(d$simule_gagnant))     # predicted winner (feedback "win")
d$gam    <- d$simule_gain                                   # estimated net gain (EUR / c.u. / yr)
d$gam2   <- d$gam^2
d$GF     <- as.numeric(d$winning_feedback_category != 3)    # after feedback: believes does not lose (3 = Perdant)
d$GF_win <- as.numeric(d$winning_feedback_category == 1)    # after feedback: believes wins
d$A0     <- as.numeric(d$tax_acceptance)                    # initial acceptance (not "No")
d$YV     <- as.numeric(d$gilets_jaunes >= 1)                # part of / supports the Yellow Vests
d$G0     <- as.numeric(d$winning_category != 3)             # initially believes does not lose
d$AT     <- as.numeric(d$tax_cible_acceptance)              # acceptance of tax & targeted dividend
d$GT     <- as.numeric(d$win_cible_category)                # believes does not lose from targeted policy
d$T1     <- as.numeric(d$traite_cible)
d$T2     <- as.numeric(d$traite_cible_conjoint)
d$T12    <- d$T1 * d$T2
d$approve0 <- as.numeric(d$taxe_approbation == "Oui")
d$effective <- as.numeric(d$taxe_efficace == "Oui")
d$ZE  <- as.numeric(d$apres_modifs == "TRUE")               # info: scientists agree carbon tax is effective
d$ZCC <- as.numeric(d$info_CC == "1")                        # info on climate change
# Incomes: continuous piecewise-linear in income percentiles of respondent and second adult,
# slope changes at the 20th and 70th percentiles: (I_j, min(I_j - k, 0)) for k = 20, 70.
d$I1 <- d$percentile_revenu; d$I2 <- d$percentile_revenu_conjoint
d$I1_20 <- pmin(d$I1 - 20, 0); d$I1_70 <- pmin(d$I1 - 70, 0)
d$I2_20 <- pmin(d$I2 - 20, 0); d$I2_70 <- pmin(d$I2 - 70, 0)
d$prog_f <- ifelse(is.na(d$prog_na), "NA", d$prog_na)

inc   <- "I1 + I1_20 + I1_70 + I2 + I2_20 + I2_70"
socio <- "factor(sexe) + factor(age) + factor(statut_emploi) + factor(csp) + factor(region) + factor(diplome4) + factor(taille_agglo) + taille_menage + nb_14_et_plus + nb_adultes + uc + factor(fume) + factor(actualite)"
motives_self <- "factor(taxe_efficace) + factor(prog_f)"            # other motives when self-interest is studied
motives_eff  <- "factor(winning_category) + factor(prog_f)"         # other motives when effectiveness is studied

cat("Check: feedback indicator vs sign of estimated gain\n"); print(table(d$Gamma, d$gam > 0))

fb   <- d[d$variante_taxe_info == "f", ]
fb50 <- fb[abs(fb$gam) < 50, ]

f4 <- function(dep, extra = "") as.formula(paste(dep, "~ Gamma + A0 + gam + gam2 +", inc, "+", socio, "+", motives_self, extra))
m1 <- feols(f4("GF"), data = fb50, weights = ~weight, vcov = "hetero")
m2 <- feols(f4("GF"), data = fb,   weights = ~weight, vcov = "hetero")
m3 <- feols(as.formula(paste("GF ~ Gamma + A0 + YV + Gamma:A0 + Gamma:YV + Gamma:G0 + factor(winning_category) + gam + gam2 +", inc, "+", socio, "+", motives_self)),
            data = fb50, weights = ~weight, vcov = "hetero")
m4 <- feols(f4("GF_win"), data = fb50, weights = ~weight, vcov = "hetero")
for (m in list(m1, m2, m3, m4)) print(coeftable(m)[grepl("Gamma|A0|YV|G0", rownames(coeftable(m))), , drop = FALSE])

# ---- Table 6 col 1: 2SLS, targeted dividend, households with an adult in [p10; p60] ----
d6 <- d[(d$I1 >= 10 & d$I1 <= 60) | (d$I2 >= 10 & d$I2 <= 60), ]
f6 <- as.formula(paste("AT ~ factor(cible) + single + A0 + gam + gam2 +", inc, "+", socio, "+", motives_self, "| GT ~ T1 + T2 + T12"))
m6 <- feols(f6, data = d6, weights = ~weight, vcov = "hetero")
print(summary(m6, stage = 1)); print(fitstat(m6, ~ ivf + n))
print(coeftable(m6)["fit_GT", ])

# ---- Table 8 col 1: 2SLS, approval on belief in effectiveness, all respondents ----
f8 <- as.formula(paste("approve0 ~ gam + gam2 +", inc, "+", socio, "+", motives_eff, "| effective ~ ZE + ZCC"))
m8 <- feols(f8, data = d, weights = ~weight, vcov = "hetero")
print(fitstat(m8, ~ ivf + n))
print(coeftable(m8)["fit_effective", ])

cf <- function(m, n) unname(coef(m)[n])
cat(sprintf("RESULT:predicted_winner_believes_not_lose_table4_col1=%.6f\n", cf(m1, "Gamma")))
cat(sprintf("RESULT:initial_acceptance_believes_not_lose_table4_col1=%.6f\n", cf(m1, "A0")))
cat(sprintf("RESULT:predicted_winner_believes_not_lose_full_sample_table4_col2=%.6f\n", cf(m2, "Gamma")))
cat(sprintf("RESULT:predicted_winner_heterogeneity_table4_col3=%.6f\n", cf(m3, "Gamma")))
cat(sprintf("RESULT:initial_acceptance_heterogeneity_table4_col3=%.6f\n", cf(m3, "A0")))
cat(sprintf("RESULT:yellow_vests_supporter_heterogeneity_table4_col3=%.6f\n", cf(m3, "YV")))
cat(sprintf("RESULT:winner_x_initial_acceptance_table4_col3=%.6f\n", cf(m3, "Gamma:A0")))
cat(sprintf("RESULT:winner_x_yellow_vests_supporter_table4_col3=%.6f\n", cf(m3, "Gamma:YV")))
cat(sprintf("RESULT:winner_x_initial_win_belief_table4_col3=%.6f\n", cf(m3, "Gamma:G0")))
cat(sprintf("RESULT:predicted_winner_believes_wins_table4_col4=%.6f\n", cf(m4, "Gamma")))
cat(sprintf("RESULT:n_obs_table4_col1=%d\n", nobs(m1)))
cat(sprintf("RESULT:believes_not_lose_on_acceptance_iv_table6_col1=%.6f\n", cf(m6, "fit_GT")))
cat(sprintf("RESULT:believes_effective_on_approval_iv_table8_col1=%.6f\n", cf(m8, "fit_effective")))
