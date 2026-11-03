# Retally blind independent reproduction: Douenne & Fabre (2022), Tables 4, 6, 8
set.seed(42)
suppressMessages(library(fixest))

suppressMessages(load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-03-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData"))

# Strip memisc / Hmisc classes (memisc is not installed) to plain vectors
d <- s
for (nm in names(d)) {
  x <- d[[nm]]
  if (isS4(x)) x <- asS4(x, FALSE, complete = FALSE)
  if (is.factor(x)) x <- as.character(x)
  attributes(x) <- NULL
  d[[nm]] <- x
}
d <- as.data.frame(d)

num <- function(x) as.numeric(as.character(x))

# ---- Variables -------------------------------------------------------------
d$Gamma_hat   <- num(d$simule_gagnant)              # win feedback (predicted winner)
d$gamma_hat   <- d$simule_gain                      # estimated net gain per c.u.
d$gamma_hat2  <- d$gamma_hat^2
d$feedback    <- d$variante_taxe_info == "f"        # received customized win/lose feedback
d$GF_notlose  <- as.numeric(d$gagnant_feedback_categorie != "Perdant")   # belief after feedback: not lose
d$GF_win      <- as.numeric(d$gagnant_feedback_categorie == "Gagnant")   # belief after feedback: win
d$A0          <- as.numeric(d$tax_acceptance)       # initial acceptance (not "No")
d$A0_approve  <- as.numeric(d$tax_approval)         # initial approval ("Yes")
d$G0_notlose  <- as.numeric(d$gagnant_categorie != "Perdant")            # initial belief not lose
d$G0_cat      <- factor(d$gagnant_categorie)
d$YV          <- as.numeric(d$gilets_jaunes_soutien == "TRUE" | d$gilets_jaunes_dedans == "TRUE")  # part of / supports
d$eff_notno   <- as.numeric(d$taxe_efficace != "Non")   # other motive: effectiveness (broad)
d$eff_yes     <- as.numeric(d$taxe_efficace == "Oui")   # Table 8 endogenous (strict)
d$prog_motive <- as.numeric(d$prog_not_no)              # other motive: progressivity
d$GT_notlose  <- as.numeric(d$gagnant_cible_categorie != "Perdant")      # belief targeted policy: not lose
d$AT          <- num(d$tax_cible_acceptance)            # acceptance targeted policy
d$T1          <- num(d$traite_cible)
d$T2          <- num(d$traite_cible_conjoint)
d$cible_f     <- factor(d$cible)
d$single      <- num(d$single)
d$Z_E         <- as.numeric(d$apres_modifs == "TRUE")   # info on effectiveness (scientific consensus)
d$Z_CC        <- num(d$info_CC)                         # info on climate change

# Income: continuous piecewise linear in percentiles of respondent and second adult, kinks at p20 and p70
d$I1 <- d$percentile_revenu; d$I2 <- d$percentile_revenu_conjoint
d$I1_20 <- pmin(d$I1 - 20, 0); d$I1_70 <- pmin(d$I1 - 70, 0)
d$I2_20 <- pmin(d$I2 - 20, 0); d$I2_70 <- pmin(d$I2 - 70, 0)
inc <- "I1 + I1_20 + I1_70 + I2 + I2_20 + I2_70"

# Socio-demographics
d$sexe_f <- factor(d$sexe); d$age_f <- factor(d$age); d$csp_f <- factor(d$csp)
d$dipl_f <- factor(d$diplome4); d$agglo_f <- factor(d$taille_agglo); d$region_f <- factor(d$region)
socio <- "sexe_f + age_f + csp_f + dipl_f + agglo_f + region_f + taille_menage + nb_14_et_plus"
gains <- "gamma_hat + gamma_hat2"
motives <- "eff_notno + prog_motive"

w <- ~weight

# ---- Table 4 ----------------------------------------------------------------
fb   <- d[d$feedback, ]
fb50 <- fb[abs(fb$gamma_hat) < 50, ]
ctrl4 <- paste(gains, inc, socio, motives, sep = " + ")

f41 <- as.formula(paste("GF_notlose ~ Gamma_hat + A0 +", ctrl4))
m41 <- feols(f41, data = fb50, weights = w, vcov = "hetero")
m42 <- feols(f41, data = fb,   weights = w, vcov = "hetero")
f43 <- as.formula(paste("GF_notlose ~ Gamma_hat + A0 + YV + Gamma_hat:A0 + Gamma_hat:YV + Gamma_hat:G0_notlose + G0_cat +", ctrl4))
m43 <- feols(f43, data = fb50, weights = w, vcov = "hetero")
f44 <- as.formula(paste("GF_win ~ Gamma_hat + A0 +", ctrl4))
m44 <- feols(f44, data = fb50, weights = w, vcov = "hetero")
print(etable(m41, m42, m43, m44, keep = c("Gamma_hat", "A0", "YV", "G0"), fitstat = ~ n + r2))

# ---- Table 6 col 1: 2SLS, targeted dividend, [p10; p60] ----------------------
in1060 <- function(p) !is.na(p) & p >= 10 & p <= 60
sub6 <- d[in1060(d$I1) | in1060(d$I2), ]
ctrl6 <- paste("single + A0", inc, gains, socio, motives, sep = " + ")
f61 <- as.formula(paste("AT ~", ctrl6, "| cible_f | GT_notlose ~ T1 + T2 + T1:T2"))
m61 <- feols(f61, data = sub6, weights = w, vcov = "hetero")
print(summary(m61, stage = 1:2))
print(fitstat(m61, ~ ivf + n))

# ---- Table 8 col 1: 2SLS, effectiveness -> initial approval, all respondents -
ctrl8 <- paste(socio, "prog_motive + G0_notlose", inc, gains, sep = " + ")
f81 <- as.formula(paste("A0_approve ~", ctrl8, "| eff_yes ~ Z_E + Z_CC"))
m81 <- feols(f81, data = d, weights = w, vcov = "hetero")
print(summary(m81, stage = 1:2))
print(fitstat(m81, ~ ivf + n))

# ---- Results -----------------------------------------------------------------
r <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))
r("predicted_winner_believes_not_lose_table4_col1", coef(m41)[["Gamma_hat"]])
r("initial_acceptance_believes_not_lose_table4_col1", coef(m41)[["A0"]])
r("predicted_winner_believes_not_lose_full_sample_table4_col2", coef(m42)[["Gamma_hat"]])
r("predicted_winner_heterogeneity_table4_col3", coef(m43)[["Gamma_hat"]])
r("initial_acceptance_heterogeneity_table4_col3", coef(m43)[["A0"]])
r("yellow_vests_supporter_heterogeneity_table4_col3", coef(m43)[["YV"]])
r("winner_x_initial_acceptance_table4_col3", coef(m43)[["Gamma_hat:A0"]])
r("winner_x_yellow_vests_supporter_table4_col3", coef(m43)[["Gamma_hat:YV"]])
r("winner_x_initial_win_belief_table4_col3", coef(m43)[["Gamma_hat:G0_notlose"]])
r("predicted_winner_believes_wins_table4_col4", coef(m44)[["Gamma_hat"]])
cat(sprintf("RESULT:n_obs_table4_col1=%d\n", nobs(m41)))
r("believes_not_lose_on_acceptance_iv_table6_col1", coef(m61)[["fit_GT_notlose"]])
r("believes_effective_on_approval_iv_table8_col1", coef(m81)[["fit_eff_yes"]])
