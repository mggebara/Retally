# Retally reproduction (seeded): Douenne & Fabre (2022), Yellow Vests, Pessimistic Beliefs, and Carbon Tax Aversion
# Follows papier.R: Table 4 (effect of feedback, cols 1-4), Table 6 col 1 (tsls_si1), Table 8 col 1 (tsls_ee1).
set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/seeded/2026-11-02-b/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/"

# papier.R loads after_preparation.RData (the prepared data frame s); the control-variable vectors
# defined in papier.R (variables_reg_*) are taken from after_papier.RData, where they are stored.
e1 <- new.env(); load(paste0(d, "after_preparation.RData"), envir = e1)
e2 <- new.env(); load(paste0(d, "after_papier.RData"), envir = e2)
s <- e1$s
variables_reg_effect_feedback <- e2$variables_reg_effect_feedback
variables_reg_self_interest <- e2$variables_reg_self_interest
variables_reg_ee <- e2$variables_reg_ee

# The memisc package (used by the authors for 'item' columns) is not installed in the sandbox.
# Strip memisc S4 item classes and Hmisc 'labelled' classes, keeping the underlying values
# (character items stay character -> factors in lm; double items stay numeric, as base model.frame treats them).
strip <- function(x) {
  if (isS4(x)) { attributes(x) <- NULL; return(x) }
  if (inherits(x, "labelled")) { class(x) <- setdiff(class(x), "labelled"); attr(x, "label") <- NULL }
  x
}
for (v in names(s)) s[[v]] <- strip(s[[v]])
w <- s$weight

# ---------------- Table 4: effect of feedback on beliefs ----------------
ctrl_fb <- paste(variables_reg_effect_feedback, collapse = " + ")
f1 <- as.formula(paste("gagnant_feedback_categorie!='Perdant' ~ simule_gagnant + tax_acceptance + (taxe_approbation=='NSP') + ", ctrl_fb))
reg1 <- lm(f1, data = s, subset = variante_taxe_info == "f" & abs(simule_gain) < 50, weights = w, na.action = "na.exclude")
reg2 <- lm(f1, data = s, subset = variante_taxe_info == "f", weights = w, na.action = "na.exclude")
s$gj <- s$gilets_jaunes > 0  # Yellow Vests supporter
f3 <- as.formula(paste("gagnant_feedback_categorie!='Perdant' ~ (gagnant_categorie!='Perdant') * simule_gagnant + simule_gagnant * gj + simule_gagnant * tax_acceptance + (taxe_approbation=='NSP') + ", ctrl_fb))
reg3 <- lm(f3, data = s, subset = variante_taxe_info == "f" & abs(simule_gain) < 50, weights = w, na.action = "na.exclude")
f4 <- as.formula(paste("gagnant_feedback_categorie=='Gagnant' ~ simule_gagnant + tax_acceptance + (taxe_approbation=='NSP') + ", ctrl_fb))
reg4 <- lm(f4, data = s, subset = variante_taxe_info == "f" & abs(simule_gain) < 50, weights = w, na.action = "na.exclude")

c1 <- coef(reg1); c2 <- coef(reg2); c3 <- coef(reg3); c4 <- coef(reg4)
cat("Table 4 col3 coefficient names of interest:\n"); print(c3[grepl("simule_gagnant|gj|tax_acceptance|gagnant_categorie", names(c3))])
g3 <- function(pattern) { k <- grep(pattern, names(c3)); if (length(k) != 1) stop("ambiguous ", pattern, ": ", paste(names(c3)[k], collapse = ",")); unname(c3[k]) }

# ---------------- Table 6 col 1: self-interest, 2SLS on [p10; p60] ----------------
ctrl_si <- paste(variables_reg_self_interest, collapse = " + ")
sub_si <- (s$percentile_revenu <= 60 & s$percentile_revenu >= 10) | (s$percentile_revenu_conjoint <= 60 & s$percentile_revenu_conjoint >= 10)
s$sub_si <- sub_si
fs_si <- as.formula(paste("gagnant_cible_categorie!='Perdant' ~ traite_cible*traite_cible_conjoint + cible + I(taxe_approbation=='NSP') + tax_acceptance + ", ctrl_si))
tsls1_si1 <- lm(fs_si, data = s, subset = sub_si, weights = w)
s$non_perdant <- NA_real_
s$non_perdant[sub_si] <- tsls1_si1$fitted.values
ss_si <- as.formula(paste("taxe_cible_approbation!='Non' ~ ", ctrl_si, "+ cible + I(taxe_approbation=='NSP') + tax_acceptance + non_perdant"))
tsls2_si1 <- lm(ss_si, data = s, subset = sub_si, weights = w)

# ---------------- Table 8 col 1: environmental effectiveness, 2SLS ----------------
ctrl_ee <- paste(variables_reg_ee, collapse = " + ")
fs_ee <- as.formula(paste("taxe_efficace=='Oui' ~", ctrl_ee, " + apres_modifs + info_CC"))
tsls1_ee1 <- lm(fs_ee, data = s, weights = w, na.action = "na.exclude")
s$taxe_efficace.hat <- fitted(tsls1_ee1)
ss_ee <- as.formula(paste("(taxe_approbation=='Oui') ~", ctrl_ee, " + taxe_efficace.hat"))
tsls2_ee1 <- lm(ss_ee, data = s, weights = w)

cat("N: t4c1", nobs(reg1), "t4c2", nobs(reg2), "t4c3", nobs(reg3), "t4c4", nobs(reg4), "t6c1", nobs(tsls2_si1), "t8c1", nobs(tsls2_ee1), "\n")

res <- c(
  predicted_winner_believes_not_lose_table4_col1 = unname(c1["simule_gagnant1"]),
  initial_acceptance_believes_not_lose_table4_col1 = unname(c1["tax_acceptanceTRUE"]),
  predicted_winner_believes_not_lose_full_sample_table4_col2 = unname(c2["simule_gagnant1"]),
  predicted_winner_heterogeneity_table4_col3 = unname(c3["simule_gagnant1"]),
  initial_acceptance_heterogeneity_table4_col3 = unname(c3["tax_acceptanceTRUE"]),
  yellow_vests_supporter_heterogeneity_table4_col3 = unname(c3["gjTRUE"]),
  winner_x_initial_acceptance_table4_col3 = g3("^simule_gagnant1:tax_acceptanceTRUE$|^tax_acceptanceTRUE:simule_gagnant1$"),
  winner_x_yellow_vests_supporter_table4_col3 = g3("^simule_gagnant1:gjTRUE$|^gjTRUE:simule_gagnant1$"),
  winner_x_initial_win_belief_table4_col3 = g3("Perdant.*TRUE:simule_gagnant1$|^simule_gagnant1:.*Perdant"),
  predicted_winner_believes_wins_table4_col4 = unname(c4["simule_gagnant1"]),
  n_obs_table4_col1 = nobs(reg1),
  believes_not_lose_on_acceptance_iv_table6_col1 = unname(coef(tsls2_si1)["non_perdant"]),
  believes_effective_on_approval_iv_table8_col1 = unname(coef(tsls2_ee1)["taxe_efficace.hat"])
)
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
