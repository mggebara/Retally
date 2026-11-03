suppressPackageStartupMessages({
  library(AER)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/douenne_2022_yellow_vests_carbon_tax"
code_dir <- file.path(base_dir, "yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec", "code")
load(file.path(code_dir, "after_papier.RData"))

# --- Make sure columns are plain R vectors (memisc items may not be dispatchable) ---
for (nm in names(s)) {
  x <- s[[nm]]
  if (isS4(x)) {
    v <- tryCatch(x@.Data, error = function(e) NULL)
    if (!is.null(v)) s[[nm]] <- v
  }
}

piece.formula <- function(var.names, knots, vector = FALSE) {
  formula.sign <- rep(" - ", length(knots))
  formula.sign[knots < 0] <- " + "
  formulas <- c()
  for (v in var.names) formulas <- c(formulas, paste(v, "+", paste("I(pmin(", v, formula.sign, abs(knots), ", 0))", collapse = " + ", sep = "")))
  formula <- paste(formulas, collapse = " + ")
  if (vector) return(strsplit(formula, " + ", fixed = TRUE)[[1]])
  formula
}

# --- Control sets (as in papier.R) ---
ctrl_si <- c("prog_na", "Simule_gain", "Simule_gain2", "taxe_efficace", "single", "hausse_depenses_par_uc",
             variables_demo, piece.formula(c("percentile_revenu", "percentile_revenu_conjoint"), c(20, 70), vector = TRUE))
ctrl_si <- ctrl_si[!(ctrl_si %in% c("revenu", "rev_tot", "age", "age_65_plus"))]
variables_reg_effect_feedback <- ctrl_si
variables_reg_self_interest <- ctrl_si

variables_reg_ee <- c("Revenu", "Revenu2", "Revenu_conjoint", "Revenu_conjoint2", "single", "Simule_gain", "Simule_gain2",
                      "gagnant_categorie", variables_demo)
variables_reg_ee <- variables_reg_ee[!(variables_reg_ee %in% c("revenu", "rev_tot", "age", "age_65_plus"))]

s$gj <- s$gilets_jaunes > 0

# --- Coefficient lookup helper (robust to factor/logical naming and interaction order) ---
getc <- function(m, parts) {
  cf <- coef(m)
  for (nm in names(cf)) {
    comps <- strsplit(nm, ":", fixed = TRUE)[[1]]
    if (length(comps) != length(parts)) next
    used <- rep(FALSE, length(comps))
    ok <- TRUE
    for (p in parts) {
      hit <- which(!used & grepl(p, comps))
      if (length(hit) == 0) { ok <- FALSE; break }
      used[hit[1]] <- TRUE
    }
    if (ok) return(unname(cf[nm]))
  }
  NA_real_
}

ctrl_fb <- paste(variables_reg_effect_feedback, collapse = " + ")
sub_close <- s$variante_taxe_info == "f" & abs(s$simule_gain) < 50
sub_fb <- s$variante_taxe_info == "f"

# --- Table 4 ---
f1 <- as.formula(paste("gagnant_feedback_categorie!='Perdant' ~ simule_gagnant + tax_acceptance + (taxe_approbation=='NSP') + ", ctrl_fb))
reg1 <- lm(f1, data = s, subset = variante_taxe_info == "f" & abs(simule_gain) < 50, weights = weight, na.action = "na.exclude")
reg2 <- lm(f1, data = s, subset = variante_taxe_info == "f", weights = weight, na.action = "na.exclude")
f3 <- as.formula(paste("gagnant_feedback_categorie!='Perdant' ~ (gagnant_categorie!='Perdant') * simule_gagnant + simule_gagnant * gj + simule_gagnant * tax_acceptance + (taxe_approbation=='NSP') + ", ctrl_fb))
reg3 <- lm(f3, data = s, subset = variante_taxe_info == "f" & abs(simule_gain) < 50, weights = weight, na.action = "na.exclude")
f4 <- as.formula(paste("gagnant_feedback_categorie=='Gagnant' ~ simule_gagnant + tax_acceptance + (taxe_approbation=='NSP') + ", ctrl_fb))
reg4 <- lm(f4, data = s, subset = variante_taxe_info == "f" & abs(simule_gain) < 50, weights = weight, na.action = "na.exclude")

p_win <- "^simule_gagnant"
p_acc <- "^tax_acceptance"
p_gj <- "^gj"
p_G <- "gagnant_categorie"

r <- list()
r$predicted_winner_believes_not_lose_table4_col1 <- getc(reg1, p_win)
r$initial_acceptance_believes_not_lose_table4_col1 <- getc(reg1, p_acc)
r$predicted_winner_believes_not_lose_full_sample_table4_col2 <- getc(reg2, p_win)
r$predicted_winner_heterogeneity_table4_col3 <- getc(reg3, p_win)
r$initial_acceptance_heterogeneity_table4_col3 <- getc(reg3, p_acc)
r$yellow_vests_supporter_heterogeneity_table4_col3 <- getc(reg3, p_gj)
r$winner_x_initial_acceptance_table4_col3 <- getc(reg3, c(p_win, p_acc))
r$winner_x_yellow_vests_supporter_table4_col3 <- getc(reg3, c(p_win, p_gj))
r$winner_x_initial_win_belief_table4_col3 <- getc(reg3, c(p_win, p_G))
r$predicted_winner_believes_wins_table4_col4 <- getc(reg4, p_win)
r$n_obs_table4_col1 <- nobs(reg1)

# --- Table 6 col 1: 2SLS, acceptance of targeted tax on believes not lose, p10-p60 subsample ---
ctrl_si_str <- paste(variables_reg_self_interest, collapse = " + ")
s$sub_p1060 <- (s$percentile_revenu <= 60 & s$percentile_revenu >= 10) |
  (s$percentile_revenu_conjoint <= 60 & s$percentile_revenu_conjoint >= 10)
s$sub_p1060[is.na(s$sub_p1060)] <- FALSE
s$non_perdant_cible <- as.numeric(s$gagnant_cible_categorie != "Perdant")
s$nsp0 <- as.numeric(s$taxe_approbation == "NSP")
s$accept_cible <- as.numeric(s$taxe_cible_approbation != "Non")
s_si <- s[s$sub_p1060, ]
iv_si1 <- ivreg(as.formula(paste("accept_cible ~ ", ctrl_si_str, " + cible + nsp0 + tax_acceptance + non_perdant_cible | ",
                                 ctrl_si_str, " + cible + nsp0 + tax_acceptance + traite_cible*traite_cible_conjoint")),
                data = s_si, weights = weight)
r$believes_not_lose_on_acceptance_iv_table6_col1 <- unname(coef(iv_si1)["non_perdant_cible"])

# --- Table 8 col 1: manual two-step 2SLS (weighted), as in tsls1_ee1 / tsls2_ee1 ---
ctrl_ee_str <- paste(variables_reg_ee, collapse = " + ")
tsls1_ee1 <- lm(as.formula(paste("taxe_efficace=='Oui' ~", ctrl_ee_str, " + apres_modifs + info_CC")),
                data = s, weights = weight, na.action = "na.exclude")
s$taxe_efficace.hat <- fitted(tsls1_ee1)
tsls2_ee1 <- lm(as.formula(paste("(taxe_approbation=='Oui') ~", ctrl_ee_str, " + taxe_efficace.hat")),
                data = s, weights = weight)
r$believes_effective_on_approval_iv_table8_col1 <- unname(coef(tsls2_ee1)["taxe_efficace.hat"])

for (nm in names(r)) cat(sprintf("RESULT:%s=%.6f\n", nm, as.numeric(r[[nm]])))