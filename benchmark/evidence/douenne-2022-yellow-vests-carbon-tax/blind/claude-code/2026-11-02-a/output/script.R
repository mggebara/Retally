# Douenne & Fabre (2022, AEJ:EP) "Yellow Vests, Pessimistic Beliefs, and Carbon Tax Aversion"
# Blind independent reproduction of Table 4 (cols 1-4), Table 6 col 1, Table 8 col 1.
set.seed(42)
suppressPackageStartupMessages(library(fixest))

load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
s <- as.data.frame(s)
# memisc S4 item columns -> plain vectors (memisc not installed)
strip <- function(x) { if (!isS4(x)) return(x); y <- x; attributes(y) <- NULL; y }
s[] <- lapply(s, strip)

# ---------------- variable construction ----------------
s$cible_n <- as.numeric(as.character(s$cible))
num <- function(x) as.numeric(as.character(x))
s$gamma   <- num(s$simule_gain)          # estimated net gain per c.u. (EUR/yr)
s$gamma_k <- s$gamma / 1000              # scaled (same as Simule_gain)
s$gamma_k2 <- s$gamma_k^2                # (same as Simule_gain2)
s$winner_fb <- num(s$simule_gagnant)     # predicted winner indicator (feedback shown)
s$A0  <- as.numeric(as.logical(s$tax_acceptance))      # initial acceptance (Yes or DK)
s$A0_approval <- as.numeric(as.logical(s$tax_approval)) # initial approval (Yes)
s$G0_notlose <- as.numeric(as.character(s$winning_category) != "Loser")  # initial belief does not lose
s$G0_cat <- factor(as.character(s$winning_category))
fbcat <- as.character(s$gagnant_feedback_categorie)
s$GF_notlose <- ifelse(is.na(fbcat), NA, as.numeric(fbcat != "Perdant"))
s$GF_win     <- ifelse(is.na(fbcat), NA, as.numeric(fbcat == "Gagnant"))
s$yv_supporter <- as.numeric(as.character(s$Gilets_jaunes) %in% c("soutient", "est_dedans"))
s$GT_notlose <- num(s$win_cible_category)
s$AT_accept  <- num(s$tax_cible_acceptance)
s$T1 <- num(s$traite_cible); s$T2 <- num(s$traite_cible_conjoint); s$T12 <- s$T1 * s$T2
s$single_n <- num(s$single)
s$eff_yes <- as.numeric(as.character(s$taxe_efficace) == "Oui")
s$Z_E  <- as.numeric(as.logical(s$apres_modifs))   # info on scientific consensus on effectiveness
s$Z_CC <- num(s$info_CC)                           # info on climate change
# income: continuous piecewise linear in income percentiles, kinks at p20 and p70 (both adults)
p1 <- num(s$percentile_revenu); p2 <- num(s$percentile_revenu_conjoint)
s$I1 <- p1; s$I1_20 <- pmin(p1 - 20, 0); s$I1_70 <- pmin(p1 - 70, 0)
s$I2 <- p2; s$I2_20 <- pmin(p2 - 20, 0); s$I2_70 <- pmin(p2 - 70, 0)
# controls
s$f_age <- factor(s$age); s$f_dipl <- factor(s$diplome4); s$f_agglo <- factor(s$taille_agglo)
s$f_sexe <- factor(as.character(s$sexe)); s$f_statut <- factor(as.character(s$statut_emploi)); s$f_csp <- factor(as.character(s$csp))
s$f_region <- factor(as.character(s$region)); s$f_gd <- factor(as.character(s$Gauche_droite))
s$f_fume <- factor(as.character(s$fume)); s$f_actu <- factor(as.character(s$actualite))
s$n_menage <- num(s$taille_menage); s$n_14 <- num(s$nb_14_et_plus)
s$f_eff <- factor(as.character(s$taxe_efficace)); s$f_prog <- factor(as.character(s$prog_na))
s$f_cible <- factor(s$cible_n)

income <- "I1 + I1_20 + I1_70 + I2 + I2_20 + I2_70"
sociodemo <- "f_sexe + f_age + f_statut + f_csp + f_dipl + f_agglo + f_region + n_menage + n_14 + f_gd + f_fume + f_actu"
motives <- "f_eff + f_prog"
gains <- "gamma_k + gamma_k2"
ctrl <- paste(income, gains, sociodemo, motives, sep = " + ")

# ---------------- Table 4 ----------------
fb <- s[s$variante_taxe_info == "f", ]
near <- fb[abs(fb$gamma) < 50, ]
cat("feedback respondents:", nrow(fb), " |gamma|<50:", nrow(near), "\n")

m1 <- feols(as.formula(paste("GF_notlose ~ winner_fb + A0 +", ctrl)), data = near, vcov = "hetero")
m2 <- feols(as.formula(paste("GF_notlose ~ winner_fb + A0 +", ctrl)), data = fb, vcov = "hetero")
m3 <- feols(as.formula(paste("GF_notlose ~ winner_fb + A0 + yv_supporter + G0_cat + winner_fb:A0 + winner_fb:yv_supporter + winner_fb:G0_notlose +", ctrl)), data = near, vcov = "hetero")
m4 <- feols(as.formula(paste("GF_win ~ winner_fb + A0 +", ctrl)), data = near, vcov = "hetero")
print(coeftable(m1)[1:3, ]); print(coeftable(m2)[1:3, ]); print(coeftable(m3)[c("winner_fb","A0","yv_supporter","winner_fb:A0","winner_fb:yv_supporter","winner_fb:G0_notlose"), ]); print(coeftable(m4)[1:3, ])
cat("R2:", r2(m1, "r2"), r2(m2, "r2"), r2(m3, "r2"), r2(m4, "r2"), " N:", nobs(m1), nobs(m2), nobs(m3), nobs(m4), "\n")

# ---------------- Table 6 col 1 ----------------
in_band <- function(p) p >= 10 & p <= 60
s6 <- s[in_band(p1) | in_band(p2), ]
m6 <- feols(as.formula(paste("AT_accept ~ f_cible + single_n + A0 +", ctrl, "| GT_notlose ~ T1 + T2 + T12")), data = s6, vcov = "hetero")
print(coeftable(m6)[1:3, ]); cat("Table6 N:", nobs(m6), "\n"); print(fitstat(m6, ~ ivf1))

# ---------------- Table 8 col 1 ----------------
# Progressivity belief was only elicited in the survey wave that also received the E.E. information
# (apres_modifs), so its "not asked" level is collinear with the instrument Z_E: excluded here.
motives8 <- "G0_cat"
ctrl8 <- paste(income, gains, sociodemo, motives8, sep = " + ")
m8 <- feols(as.formula(paste("A0_approval ~", ctrl8, "| eff_yes ~ Z_E + Z_CC")), data = s, vcov = "hetero")
print(coeftable(m8)[1:2, ]); cat("Table8 N:", nobs(m8), "\n"); print(fitstat(m8, ~ ivf1))

# ---------------- results ----------------
r <- function(name, v) cat(sprintf("RESULT:%s=%.6f\n", name, v))
r("predicted_winner_believes_not_lose_table4_col1", coef(m1)["winner_fb"])
r("initial_acceptance_believes_not_lose_table4_col1", coef(m1)["A0"])
r("predicted_winner_believes_not_lose_full_sample_table4_col2", coef(m2)["winner_fb"])
r("predicted_winner_heterogeneity_table4_col3", coef(m3)["winner_fb"])
r("initial_acceptance_heterogeneity_table4_col3", coef(m3)["A0"])
r("yellow_vests_supporter_heterogeneity_table4_col3", coef(m3)["yv_supporter"])
r("winner_x_initial_acceptance_table4_col3", coef(m3)["winner_fb:A0"])
r("winner_x_yellow_vests_supporter_table4_col3", coef(m3)["winner_fb:yv_supporter"])
r("winner_x_initial_win_belief_table4_col3", coef(m3)["winner_fb:G0_notlose"])
r("predicted_winner_believes_wins_table4_col4", coef(m4)["winner_fb"])
cat(sprintf("RESULT:n_obs_table4_col1=%d\n", nobs(m1)))
r("believes_not_lose_on_acceptance_iv_table6_col1", coef(m6)["fit_GT_notlose"])
r("believes_effective_on_approval_iv_table8_col1", coef(m8)["fit_eff_yes"])
cat("DEVIATION: control lists (online appendix) unavailable; sociodemo/other-motive/income controls reconstructed from variable names; heteroskedasticity-robust SEs.\n")
cat("DEVIATION: Table 8 other-motive controls = initial win/lose category only (progressivity belief omitted: its missingness coincides with the E.E. information wave, collinear with the instrument).\n")
