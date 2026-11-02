# Reproduction of Douenne & Fabre (2022), Tables 4, 6 (col 1) and 8 (col 1),
# following papier.R (sections 4.1.2, 5.1 and 5.2).
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/seeded/2026-11-02-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code"

# papier.R loads after_preparation.RData; the regressor-name vectors defined in
# papier.R (via variables_demo and piece.formula) are taken from after_papier.RData.
e0 <- new.env(); load(file.path(D, "after_preparation.RData"), envir = e0)
ep <- new.env(); load(file.path(D, "after_papier.RData"), envir = ep)
s <- e0$s

# Flatten Hmisc/memisc labelled classes to plain vectors (memisc unavailable); keep factors.
flatten <- function(x) {
  cl <- oldClass(x)
  if ("factor" %in% cl) { lv <- attr(x, "levels"); attributes(x) <- NULL; attr(x, "levels") <- lv; oldClass(x) <- "factor"; return(x) }
  attributes(x) <- NULL; x
}
s[] <- lapply(s, flatten)

# Rebuild the control list exactly as papier.R does
piece.formula <- function(var.names, knots, vector=F) {
  formula.sign <- rep(" - ", length(knots))
  formula.sign[knots < 0] <- " + "
  formulas <- c()
  for (v in var.names) formulas <- c(formulas, paste(v, "+", paste("I(pmin(", v, formula.sign, abs(knots), ", 0))", collapse = " + ", sep="")))
  formula <- paste(formulas, collapse = ' + ')
  if (vector) return(strsplit(formula, ' + ', fixed=T)[[1]]) else return(formula)
}
variables_demo <- e0$variables_demo
vrf <- c("prog_na", "Simule_gain", "Simule_gain2", "taxe_efficace", "single", "hausse_depenses_par_uc", variables_demo,
         piece.formula(c("percentile_revenu", "percentile_revenu_conjoint"), c(20,70), vector=T))
vrf <- vrf[!(vrf %in% c("revenu", "rev_tot", "age", "age_65_plus"))]
stopifnot(identical(vrf, ep$variables_reg_effect_feedback))
ctrl <- paste(vrf, collapse = " + ")

# ---------------- Table 4 ----------------
f1 <- as.formula(paste("gagnant_feedback_categorie!='Perdant' ~ simule_gagnant + tax_acceptance + (taxe_approbation=='NSP') + ", ctrl))
r1 <- lm(f1, data=s, subset=variante_taxe_info=='f' & abs(simule_gain) < 50, weights=weight, na.action='na.exclude')
r2 <- lm(f1, data=s, subset=variante_taxe_info=='f', weights=weight, na.action='na.exclude')
s$gj <- s$gilets_jaunes > 0
f3 <- as.formula(paste("gagnant_feedback_categorie!='Perdant' ~ (gagnant_categorie!='Perdant') * simule_gagnant + simule_gagnant * gj + simule_gagnant * tax_acceptance + (taxe_approbation=='NSP') + ", ctrl))
r3 <- lm(f3, data=s, subset=variante_taxe_info=='f' & abs(simule_gain) < 50, weights=weight, na.action='na.exclude')
f4 <- as.formula(paste("gagnant_feedback_categorie=='Gagnant' ~ simule_gagnant + tax_acceptance + (taxe_approbation=='NSP') + ", ctrl))
r4 <- lm(f4, data=s, subset=variante_taxe_info=='f' & abs(simule_gain) < 50, weights=weight, na.action='na.exclude')
c3 <- coef(r3)
cat("Table 4 col 3 coefficient names:\n"); print(grep("simule|gj|accept|Perdant", names(c3), value=TRUE))
pick <- function(cf, pattern) { n <- grep(pattern, names(cf), value=TRUE); if (length(n) != 1) stop("ambiguous: ", pattern, " -> ", paste(n, collapse=",")); cf[[n]] }

# ---------------- Table 6 col 1: tsls_si1 (manual 2SLS as in papier.R) ----------------
vsi <- ep$variables_reg_self_interest; stopifnot(identical(vsi, vrf))
sub_si <- with(s, (percentile_revenu <= 60 & percentile_revenu >= 10) | (percentile_revenu_conjoint <= 60 & percentile_revenu_conjoint >= 10))
fs1 <- as.formula(paste("gagnant_cible_categorie!='Perdant' ~ traite_cible*traite_cible_conjoint + cible + I(taxe_approbation=='NSP') + tax_acceptance + ", ctrl))
tsls1_si1 <- lm(fs1, data=s, subset=sub_si, weights=weight)
s$non_perdant <- NA_real_
stopifnot(length(fitted(tsls1_si1)) == sum(sub_si))
s$non_perdant[sub_si] <- tsls1_si1$fitted.values
fs2 <- as.formula(paste("taxe_cible_approbation!='Non' ~ ", ctrl, "+ cible + I(taxe_approbation=='NSP') + tax_acceptance + non_perdant"))
tsls2_si1 <- lm(fs2, data=s, subset=sub_si, weights=weight)
b_si <- coef(tsls2_si1)[["non_perdant"]]
cat("Table 6 col1 N:", nobs(tsls2_si1), "\n")

# ---------------- Table 8 col 1: tsls_ee1 ----------------
vee <- ep$variables_reg_ee
ctrl_ee <- paste(vee, collapse = " + ")
fe1 <- as.formula(paste("taxe_efficace=='Oui' ~", ctrl_ee, " + apres_modifs + info_CC"))
tsls1_ee1 <- lm(fe1, data=s, weights=weight, na.action='na.exclude')
s$taxe_efficace.hat <- fitted(tsls1_ee1)
fe2 <- as.formula(paste("(taxe_approbation=='Oui') ~", ctrl_ee, " + taxe_efficace.hat"))
tsls2_ee1 <- lm(fe2, data=s, weights=weight)
b_ee <- coef(tsls2_ee1)[["taxe_efficace.hat"]]
cat("Table 8 col1 N:", nobs(tsls2_ee1), "\n")

cat(sprintf("RESULT:predicted_winner_believes_not_lose_table4_col1=%.6f\n", pick(coef(r1), "^simule_gagnant1$")))
cat(sprintf("RESULT:initial_acceptance_believes_not_lose_table4_col1=%.6f\n", pick(coef(r1), "^tax_acceptanceTRUE$")))
cat(sprintf("RESULT:predicted_winner_believes_not_lose_full_sample_table4_col2=%.6f\n", pick(coef(r2), "^simule_gagnant1$")))
cat(sprintf("RESULT:predicted_winner_heterogeneity_table4_col3=%.6f\n", pick(c3, "^simule_gagnant1$")))
cat(sprintf("RESULT:initial_acceptance_heterogeneity_table4_col3=%.6f\n", pick(c3, "^tax_acceptanceTRUE$")))
cat(sprintf("RESULT:yellow_vests_supporter_heterogeneity_table4_col3=%.6f\n", pick(c3, "^gjTRUE$")))
cat(sprintf("RESULT:winner_x_initial_acceptance_table4_col3=%.6f\n", pick(c3, "^simule_gagnant1:tax_acceptanceTRUE$")))
cat(sprintf("RESULT:winner_x_yellow_vests_supporter_table4_col3=%.6f\n", pick(c3, "^simule_gagnant1:gjTRUE$")))
cat(sprintf("RESULT:winner_x_initial_win_belief_table4_col3=%.6f\n", pick(c3, "Perdant.*:simule_gagnant1$")))
cat(sprintf("RESULT:predicted_winner_believes_wins_table4_col4=%.6f\n", pick(coef(r4), "^simule_gagnant1$")))
cat(sprintf("RESULT:n_obs_table4_col1=%d\n", nobs(r1)))
cat(sprintf("RESULT:believes_not_lose_on_acceptance_iv_table6_col1=%.6f\n", b_si))
cat(sprintf("RESULT:believes_effective_on_approval_iv_table8_col1=%.6f\n", b_ee))
