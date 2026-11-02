set.seed(42)
suppressPackageStartupMessages({ library(fixest) })
base <- "<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-c/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData"
e <- new.env(); load(base, envir = e); s <- e$s
# strip memisc / labelled classes (memisc is not installed in the sandbox)
pl <- function(x) { cl <- oldClass(x); if (!is.null(cl) && "factor" %in% cl) { lv <- attr(x, "levels"); oldClass(x) <- NULL; return(lv[x]) }; if (typeof(x) == "S4") x <- x@.Data; oldClass(x) <- NULL; attributes(x) <- NULL; x }
for (v in names(s)) s[[v]] <- pl(s[[v]])
d <- data.frame(id = seq_len(nrow(s)))
d$w        <- s$weight
# beliefs / outcomes
d$GF       <- ifelse(is.na(s$gagnant_feedback_categorie), NA, as.numeric(s$gagnant_feedback_categorie != "Perdant"))
d$GF_win   <- ifelse(is.na(s$gagnant_feedback_categorie), NA, as.numeric(s$gagnant_feedback_categorie == "Gagnant"))
d$feedback <- !is.na(s$gagnant_feedback_categorie)
d$G0       <- as.numeric(s$gagnant_categorie != "Perdant")      # initial belief does not lose
d$G0cat    <- s$gagnant_categorie
d$A0       <- as.numeric(s$taxe_approbation != "Non")           # initial acceptance
d$App0     <- as.numeric(s$taxe_approbation == "Oui")           # initial approval
d$Gamma    <- as.numeric(s$simule_gagnant)                       # predicted winner (feedback)
d$gam      <- s$simule_gain                                      # estimated net gain per c.u.
d$gam2     <- d$gam^2
d$YV       <- as.numeric(s$gilets_jaunes_dedans | s$gilets_jaunes_soutien)
# targeted dividend
d$GT  <- as.numeric(s$gagnant_cible_categorie != "Perdant")
d$AT  <- as.numeric(s$taxe_cible_approbation != "Non")
d$T1  <- as.numeric(s$traite_cible); d$T2 <- as.numeric(s$traite_cible_conjoint); d$T12 <- d$T1 * d$T2
d$cible <- factor(s$cible); d$single <- as.numeric(s$single)
# effectiveness
d$Eff  <- as.numeric(s$taxe_efficace == "Oui")
d$EffNotNo <- as.numeric(s$taxe_efficace != "Non")
d$ZE  <- as.numeric(s$apres_modifs); d$ZCC <- as.numeric(s$info_CC)
# incomes: piecewise linear in percentiles, kinks at 20 and 70, respondent and second adult
p1 <- s$percentile_revenu; p2 <- s$percentile_revenu_conjoint
d$p1 <- p1; d$p2 <- p2
d$p1_20 <- pmin(p1 - 20, 0); d$p1_70 <- pmin(p1 - 70, 0)
d$p2_20 <- pmin(p2 - 20, 0); d$p2_70 <- pmin(p2 - 70, 0)
inc <- "p1 + p1_20 + p1_70 + p2 + p2_20 + p2_70"
# sociodemographics
d$sexe <- factor(s$sexe); d$age <- factor(s$age); d$csp <- factor(s$csp); d$diplome4 <- factor(s$diplome4)
d$taille_agglo <- factor(s$taille_agglo); d$region <- factor(s$region); d$statut <- factor(s$statut_emploi)
d$uc <- s$uc; d$nb_14 <- as.numeric(s$nb_14_et_plus); d$nb_adultes <- as.numeric(s$nb_adultes)
d$fume <- as.numeric(s$fume == "Oui"); d$actualite <- factor(s$actualite)
d$gd <- factor(s$Gauche_droite); d$interet <- as.numeric(s$interet_politique)
demo <- "sexe + age + csp + diplome4 + taille_agglo + region + uc + nb_14 + fume + actualite"
# other motives
motives_eff <- "EffNotNo"          # belief in effectiveness (for self-interest regressions)
motives_si  <- "G0cat"             # initial win/lose category (for effectiveness regressions)

f <- function(txt) as.formula(txt)
fb <- subset(d, feedback); near <- subset(fb, abs(gam) < 50)
cat("N feedback:", nrow(fb), " N near:", nrow(near), "\n")
ctrl4 <- paste("gam + gam2 +", inc, "+", demo, "+", motives_eff)
m1 <- feols(f(paste("GF ~ Gamma + A0 +", ctrl4)), data = near, weights = ~w, vcov = "hetero")
m2 <- feols(f(paste("GF ~ Gamma + A0 +", ctrl4)), data = fb, weights = ~w, vcov = "hetero")
m3 <- feols(f(paste("GF ~ Gamma*A0 + Gamma*YV + Gamma*G0 + G0cat +", ctrl4)), data = near, weights = ~w, vcov = "hetero")
m4 <- feols(f(paste("GF_win ~ Gamma + A0 +", ctrl4)), data = near, weights = ~w, vcov = "hetero")
for (m in list(m1, m2, m3, m4)) { print(coeftable(m)[intersect(rownames(coeftable(m)), c("Gamma","A0","YV","G0","Gamma:A0","Gamma:YV","Gamma:G0")), 1:2]); cat("N", nobs(m), "R2", r2(m, "r2"), "\n") }

# Table 6 col 1: targeted dividend, subsample p10-p60 for at least one adult
d$insub <- (d$p1 >= 10 & d$p1 <= 60) | (d$nb_adultes > 1 & d$p2 >= 10 & d$p2 <= 60)
sub6 <- subset(d, insub)
cat("N table6 sub:", nrow(sub6), "\n")
ctrl6 <- paste("single + A0 + gam + gam2 +", inc, "+", demo, "+", motives_eff, "| cible")
iv6 <- feols(f(paste("AT ~", ctrl6, "| GT ~ T1 + T2 + T12")), data = sub6, weights = ~w, vcov = "hetero")
print(summary(iv6, stage = 1)); print(coeftable(iv6)[c("fit_GT","A0"), 1:2]); cat("N", nobs(iv6), "\n")

# Table 8 col 1: approval on effectiveness, instruments ZE and ZCC
ctrl8 <- paste("gam + gam2 +", inc, "+", demo, "+", motives_si)
iv8 <- feols(f(paste("App0 ~", ctrl8, "| Eff ~ ZE + ZCC")), data = d, weights = ~w, vcov = "hetero")
print(coeftable(summary(iv8, stage = 1))[c("ZE","ZCC"), 1:2]); print(coeftable(iv8)["fit_Eff", 1:2]); cat("N", nobs(iv8), "\n")

g <- function(m, n) unname(coef(m)[n])
cat(sprintf("RESULT:predicted_winner_believes_not_lose_table4_col1=%.4f\n", g(m1, "Gamma")))
cat(sprintf("RESULT:initial_acceptance_believes_not_lose_table4_col1=%.4f\n", g(m1, "A0")))
cat(sprintf("RESULT:predicted_winner_believes_not_lose_full_sample_table4_col2=%.4f\n", g(m2, "Gamma")))
cat(sprintf("RESULT:predicted_winner_heterogeneity_table4_col3=%.4f\n", g(m3, "Gamma")))
cat(sprintf("RESULT:initial_acceptance_heterogeneity_table4_col3=%.4f\n", g(m3, "A0")))
cat(sprintf("RESULT:yellow_vests_supporter_heterogeneity_table4_col3=%.4f\n", g(m3, "YV")))
cat(sprintf("RESULT:winner_x_initial_acceptance_table4_col3=%.4f\n", g(m3, "Gamma:A0")))
cat(sprintf("RESULT:winner_x_yellow_vests_supporter_table4_col3=%.4f\n", g(m3, "Gamma:YV")))
cat(sprintf("RESULT:winner_x_initial_win_belief_table4_col3=%.4f\n", g(m3, "Gamma:G0")))
cat(sprintf("RESULT:predicted_winner_believes_wins_table4_col4=%.4f\n", g(m4, "Gamma")))
cat(sprintf("RESULT:n_obs_table4_col1=%d\n", nobs(m1)))
cat(sprintf("RESULT:believes_not_lose_on_acceptance_iv_table6_col1=%.4f\n", g(iv6, "fit_GT")))
cat(sprintf("RESULT:believes_effective_on_approval_iv_table8_col1=%.4f\n", g(iv8, "fit_Eff")))
