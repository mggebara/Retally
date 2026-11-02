# Independent reproduction: Douenne & Fabre (2022, AEJ:EP), Tables 4, 6 (col 1), 8 (col 1)
suppressPackageStartupMessages({ library(fixest) })
set.seed(42)
load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-b/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")

# Strip memisc/labelled classes (memisc is not installed) without dispatching on them
d <- s
for (n in names(d)) { x <- d[[n]]
  if (!("factor" %in% oldClass(x))) { r <- try({ attributes(x) <- NULL; x }, silent = TRUE); if (!inherits(r, "try-error")) d[[n]] <- r } }
d <- as.data.frame(d)

tf <- function(x) as.numeric(as.character(x) %in% c("TRUE", "1"))

# ---- Variables ----
d$w          <- d$weight
d$gain_hat   <- d$simule_gain / 100          # estimated net gain per c.u. (EUR 100); rescaling only
d$gain_hat2  <- d$gain_hat^2
d$winner_hat <- as.numeric(as.character(d$simule_gagnant))   # win/lose feedback (Gamma hat)
d$A0         <- as.numeric(d$tax_acceptance)                  # initial acceptance (not "No")
d$A0_dot     <- as.numeric(d$tax_approval)                    # initial approval ("Yes")
d$GF_notlose <- as.numeric(d$gagnant_feedback_categorie != "Perdant")
d$GF_win     <- as.numeric(d$gagnant_feedback_categorie == "Gagnant")
d$G0_notlose <- as.numeric(d$gagnant_categorie != "Perdant")
d$G0_cat     <- factor(d$gagnant_categorie)
d$yv         <- as.numeric(d$gilets_jaunes >= 1)              # part of or supports the Yellow Vests
d$single     <- as.numeric(d$single)
d$feedback   <- !is.na(d$gagnant_feedback_categorie)
d$eff_cat    <- factor(d$taxe_efficace)                       # other motive: belief in effectiveness
d$eff_yes    <- as.numeric(d$taxe_efficace == "Oui")
d$ZE         <- tf(d$apres_modifs)                            # info on environmental effectiveness
d$ZCC        <- tf(d$info_CC)                                 # info on climate change
d$AT         <- as.numeric(d$tax_cible_acceptance)            # acceptance of targeted tax & dividend
d$GT         <- as.numeric(d$win_cible_category)              # believes does not lose (targeted)
d$T1         <- as.numeric(d$traite_cible)
d$T2         <- as.numeric(d$traite_cible_conjoint)
d$cible_f    <- factor(d$cible)

# Income: continuous piecewise-linear in income percentiles of respondent and second adult,
# slope changes at 20th and 70th percentiles
p1 <- d$percentile_revenu
p2 <- ifelse(d$single == 1, 0, d$percentile_revenu_conjoint)
d$I1 <- p1; d$I1_20 <- pmin(p1 - 20, 0); d$I1_70 <- pmin(p1 - 70, 0)
d$I2 <- p2; d$I2_20 <- ifelse(d$single == 1, 0, pmin(p2 - 20, 0)); d$I2_70 <- ifelse(d$single == 1, 0, pmin(p2 - 70, 0))
inc <- "I1 + I1_20 + I1_70 + I2 + I2_20 + I2_70 + single"

# Socio-demographics
d$sexe_f <- factor(d$sexe); d$age_f <- factor(d$age); d$dipl_f <- factor(d$diplome4)
d$agglo_f <- factor(d$taille_agglo); d$csp_f <- factor(d$csp); d$region_f <- factor(d$region)
socio <- "sexe_f + age_f + dipl_f + agglo_f + csp_f + region_f + taille_menage + nb_14_et_plus + nb_adultes"
gains <- "gain_hat + gain_hat2"

cat("Diagnostics\n")
cat("single x T2:\n"); print(table(single = d$single, T2 = d$T2))
cat("percentile_revenu_conjoint among singles:\n"); print(summary(d$percentile_revenu_conjoint[d$single == 1]))

# ---- Table 4 ----
fb  <- subset(d, feedback)
fb50 <- subset(fb, abs(simule_gain) < 50)
f1 <- as.formula(paste("GF_notlose ~ winner_hat + A0 +", gains, "+", inc, "+", socio, "+ eff_cat"))
m1 <- feols(f1, data = fb50, weights = ~w, vcov = "hetero")
m2 <- feols(f1, data = fb,   weights = ~w, vcov = "hetero")
f3 <- as.formula(paste("GF_notlose ~ winner_hat + A0 + yv + winner_hat:A0 + winner_hat:yv + winner_hat:G0_notlose + G0_cat +",
                       gains, "+", inc, "+", socio, "+ eff_cat"))
m3 <- feols(f3, data = fb50, weights = ~w, vcov = "hetero")
f4 <- as.formula(paste("GF_win ~ winner_hat + A0 +", gains, "+", inc, "+", socio, "+ eff_cat"))
m4 <- feols(f4, data = fb50, weights = ~w, vcov = "hetero")
for (m in list(m1, m2, m3, m4)) cat("T4 N =", nobs(m), " R2 =", round(r2(m, "r2"), 3), "\n")
print(coeftable(m3)[c("winner_hat", "A0", "yv", "winner_hat:A0", "winner_hat:yv", "winner_hat:G0_notlose"), 1:2])

# ---- Table 6, col 1: 2SLS, targeted dividend, subsample [p10; p60] ----
inr <- function(p) p >= 10 & p <= 60
d6 <- subset(d, inr(percentile_revenu) | (single == 0 & inr(percentile_revenu_conjoint)))
f6 <- as.formula(paste("AT ~ A0 + cible_f +", gains, "+", inc, "+", socio, "+ eff_cat | GT ~ T1 + T2 + T1:T2"))
m6 <- feols(f6, data = d6, weights = ~w, vcov = "hetero")
cat("T6 N =", nobs(m6), "\n"); print(fitstat(m6, ~ ivf + ivwald)); print(coeftable(m6)[1:3, 1:2])

# ---- Table 8, col 1: 2SLS, effectiveness -> approval, all respondents ----
f8 <- as.formula(paste("A0_dot ~", gains, "+", inc, "+", socio, "+ G0_cat | eff_yes ~ ZE + ZCC"))
m8 <- feols(f8, data = d, weights = ~w, vcov = "hetero")
cat("T8 N =", nobs(m8), "\n"); print(fitstat(m8, ~ ivf)); print(coeftable(m8)[1:2, 1:2])

out <- c(
  predicted_winner_believes_not_lose_table4_col1 = unname(coef(m1)["winner_hat"]),
  initial_acceptance_believes_not_lose_table4_col1 = unname(coef(m1)["A0"]),
  predicted_winner_believes_not_lose_full_sample_table4_col2 = unname(coef(m2)["winner_hat"]),
  predicted_winner_heterogeneity_table4_col3 = unname(coef(m3)["winner_hat"]),
  initial_acceptance_heterogeneity_table4_col3 = unname(coef(m3)["A0"]),
  yellow_vests_supporter_heterogeneity_table4_col3 = unname(coef(m3)["yv"]),
  winner_x_initial_acceptance_table4_col3 = unname(coef(m3)["winner_hat:A0"]),
  winner_x_yellow_vests_supporter_table4_col3 = unname(coef(m3)["winner_hat:yv"]),
  winner_x_initial_win_belief_table4_col3 = unname(coef(m3)["winner_hat:G0_notlose"]),
  predicted_winner_believes_wins_table4_col4 = unname(coef(m4)["winner_hat"]),
  n_obs_table4_col1 = nobs(m1),
  believes_not_lose_on_acceptance_iv_table6_col1 = unname(coef(m6)["fit_GT"]),
  believes_effective_on_approval_iv_table8_col1 = unname(coef(m8)["fit_eff_yes"])
)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
