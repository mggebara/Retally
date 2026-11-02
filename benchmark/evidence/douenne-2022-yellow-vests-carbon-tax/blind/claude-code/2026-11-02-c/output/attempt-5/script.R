# Retally blind independent reproduction: Douenne & Fabre (2022), Tables 4, 6, 8
set.seed(42)
suppressPackageStartupMessages(library(fixest))

load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-c/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")

# Strip memisc/labelled classes (memisc is not installed) to plain vectors
cv <- function(x) { a <- attributes(x); v <- x; attributes(v) <- NULL
  if (isS4(v)) v <- asS3(v, complete = FALSE)
  if (!is.null(a$levels)) v <- factor(a$levels[v], levels = a$levels); v }
d <- s
for (nm in names(d)) d[[nm]] <- tryCatch(cv(d[[nm]]), error = function(e) NA)
d <- as.data.frame(d)
cat("N respondents:", nrow(d), "\n")

# ---- Variables ----
d$GF      <- as.numeric(d$gagnant_feedback_categorie != "Perdant")   # believes does not lose after feedback
d$GF_win  <- as.numeric(d$gagnant_feedback_categorie == "Gagnant")   # believes wins after feedback
d$Gamma   <- as.numeric(as.character(d$simule_gagnant))              # predicted winner (feedback shown)
d$g       <- d$simule_gain                                           # estimated net gain per c.u. (EUR/yr)
d$g2      <- d$g^2
d$A0      <- as.numeric(d$tax_acceptance)                            # initial acceptance (not "No")
d$YV      <- as.numeric(d$gilets_jaunes > 0)                         # part of / supports Yellow Vests
d$G0      <- as.numeric(d$gagnant_categorie != "Perdant")            # initially believes does not lose
d$G0cat   <- factor(d$gagnant_categorie)                             # initial win/lose category
d$feedback <- d$variante_taxe_info == "f"

# Incomes: continuous piecewise-linear in percentiles of respondent and second adult, kinks at p20, p70
d$p1 <- d$percentile_revenu; d$p2 <- d$percentile_revenu_conjoint
d$p1_20 <- pmin(d$p1 - 20, 0); d$p1_70 <- pmin(d$p1 - 70, 0)
d$p2_20 <- pmin(d$p2 - 20, 0); d$p2_70 <- pmin(d$p2 - 70, 0)
inc <- "p1 + p1_20 + p1_70 + p2 + p2_20 + p2_70"

# Socio-demographics
d$age_f <- factor(d$age); d$dipl_f <- factor(d$diplome4); d$agglo_f <- factor(d$taille_agglo)
socio <- "sexe + age_f + statut_emploi + csp + region + dipl_f + taille_menage + nb_14_et_plus + nb_adultes + fume + actualite + agglo_f + uc"

# Other motives
d$eff_f   <- factor(d$taxe_efficace)                  # belief in environmental effectiveness (Oui/Non/NSP)
d$prog    <- as.numeric(d$prog_not_no)                # perceives progressivity (not "No")
d$eff_yes <- as.numeric(d$taxe_efficace == "Oui")
d$approve0 <- as.numeric(d$tax_approval)
motives_selfint <- "eff_f + prog"                     # for self-interest regressions
motives_eff     <- "G0cat + prog"                     # for effectiveness regressions (self-interest belief + progressivity)

gains <- "g + g2"
ctrl4 <- paste(gains, inc, socio, motives_selfint, sep = " + ")

# ---- Table 4 ----
fb <- subset(d, feedback)
fb50 <- subset(fb, abs(g) < 50)
cat("Feedback sample:", nrow(fb), " |gain|<50:", nrow(fb50), "\n")

m1 <- feols(as.formula(paste("GF ~ Gamma + A0 +", ctrl4)), data = fb50, vcov = "hetero")
m2 <- feols(as.formula(paste("GF ~ Gamma + A0 +", ctrl4)), data = fb,   vcov = "hetero")
m3 <- feols(as.formula(paste("GF ~ Gamma + A0 + YV + Gamma:A0 + Gamma:YV + Gamma:G0 + G0cat +", ctrl4)), data = fb50, vcov = "hetero")
m4 <- feols(as.formula(paste("GF_win ~ Gamma + A0 +", ctrl4)), data = fb50, vcov = "hetero")
print(etable(m1, m2, m3, m4, keep = c("Gamma", "A0", "YV", "G0")))

# ---- Table 6 col 1: tax & targeted dividend, 2SLS ----
d$T1 <- d$traite_cible; d$T2 <- d$traite_cible_conjoint; d$T12 <- d$T1 * d$T2
d$GT <- d$win_cible_category; d$AT <- d$tax_cible_acceptance
d$cible_f <- factor(d$cible)
in_rng <- function(p) !is.na(p) & p >= 10 & p <= 60
d$p10_60 <- in_rng(d$p1) | (d$nb_adultes > 1 & in_rng(d$p2))
s6 <- subset(d, p10_60)
cat("Table 6 [p10;p60] sample:", nrow(s6), "\n")
ctrl6 <- paste("cible_f + single + A0", gains, inc, socio, motives_selfint, sep = " + ")
m6 <- feols(as.formula(paste("AT ~", ctrl6, "| GT ~ T1 + T2 + T12")), data = s6, vcov = "hetero")
print(summary(m6, stage = 1:2))

# ---- Table 8 col 1: effectiveness, 2SLS ----
ctrl8 <- paste(socio, motives_eff, inc, gains, sep = " + ")
m8 <- feols(as.formula(paste("approve0 ~", ctrl8, "| eff_yes ~ apres_modifs + info_CC")), data = d, vcov = "hetero")
print(summary(m8, stage = 1:2))

cf <- function(m, nm) unname(coef(m)[nm])
out <- c(
  predicted_winner_believes_not_lose_table4_col1 = cf(m1, "Gamma"),
  initial_acceptance_believes_not_lose_table4_col1 = cf(m1, "A0"),
  predicted_winner_believes_not_lose_full_sample_table4_col2 = cf(m2, "Gamma"),
  predicted_winner_heterogeneity_table4_col3 = cf(m3, "Gamma"),
  initial_acceptance_heterogeneity_table4_col3 = cf(m3, "A0"),
  yellow_vests_supporter_heterogeneity_table4_col3 = cf(m3, "YV"),
  winner_x_initial_acceptance_table4_col3 = cf(m3, "Gamma:A0"),
  winner_x_yellow_vests_supporter_table4_col3 = cf(m3, "Gamma:YV"),
  winner_x_initial_win_belief_table4_col3 = cf(m3, "Gamma:G0"),
  predicted_winner_believes_wins_table4_col4 = cf(m4, "Gamma"),
  n_obs_table4_col1 = nobs(m1),
  believes_not_lose_on_acceptance_iv_table6_col1 = cf(m6, "fit_GT"),
  believes_effective_on_approval_iv_table8_col1 = cf(m8, "fit_eff_yes")
)
for (k in names(out)) cat(sprintf("RESULT:%s=%.6f\n", k, out[[k]]))
