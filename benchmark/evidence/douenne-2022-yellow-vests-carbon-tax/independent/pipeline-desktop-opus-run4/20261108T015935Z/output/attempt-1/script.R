suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/douenne_2022_yellow_vests_carbon_tax.script-free"
rdata <- file.path(base, "yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
load(rdata)
d <- s
cat("Rows:", nrow(d), " Cols:", ncol(d), "\n")

nms <- names(d)
pick <- function(cands, pattern = NULL) {
  for (c in cands) if (c %in% nms) return(c)
  if (!is.null(pattern)) {
    g <- grep(pattern, nms, value = TRUE, ignore.case = TRUE)
    if (length(g) > 0) return(g[1])
  }
  NA_character_
}
chr <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::as_factor(x)
  if (is.factor(x)) return(as.character(x))
  if (is.logical(x)) return(ifelse(x, "TRUE", "FALSE"))
  as.character(x)
}
num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- unclass(x)
  if (is.factor(x)) x <- as.character(x)
  suppressWarnings(as.numeric(x))
}
is_yes <- function(x) { v <- tolower(trimws(chr(x))); out <- grepl("^(oui|yes|true|1)$", v); out[is.na(v) | v == ""] <- NA; out }
is_no  <- function(x) { v <- tolower(trimws(chr(x))); out <- grepl("^(non|no|false|0)$", v); out[is.na(v) | v == ""] <- NA; out }
is_loser <- function(x) { v <- tolower(trimws(chr(x))); out <- grepl("perdant|los", v); out[is.na(v) | v == "" | v == "na"] <- NA; out }
is_winner <- function(x) { v <- tolower(trimws(chr(x))); out <- grepl("^gagnant|^win", v); out[is.na(v) | v == "" | v == "na"] <- NA; out }

show_vals <- function(v) {
  if (!is.na(v)) { cat("  ", v, ":\n"); print(head(sort(table(chr(d[[v]]), useNA = "ifany"), decreasing = TRUE), 10)) }
}

# ---------- core variables ----------
v_gain   <- pick(c("simule_gain", "simule_gain_repondant", "gain_simule"), "^simule_gain")
v_fb     <- pick(c("gagnant_feedback_categorie", "winning_feedback_category"), "feedback_categ")
v_init   <- pick(c("gagnant_categorie", "winning_category"), "^gagnant_categ")
v_appr   <- pick(c("taxe_approbation", "tax_approval"), "^taxe_approbation$")
v_accept <- pick(c("tax_acceptance"), NULL)
v_gj     <- pick(c("gilets_jaunes", "Gilets_jaunes", "yellow_vests"), "gilets_jaunes")
v_w      <- pick(c("weight", "poids", "weights"), NULL)
v_eff    <- pick(c("taxe_efficace", "tax_effective"), "taxe_efficace")
v_prog   <- pick(c("progressivite", "progressivity"), "^progressiv")
v_single <- pick(c("single"), NULL)

cat("Detected: gain=", v_gain, " fb=", v_fb, " init=", v_init, " appr=", v_appr,
    " accept=", v_accept, " gj=", v_gj, " w=", v_w, " eff=", v_eff, "\n")
for (v in c(v_fb, v_init, v_appr, v_gj, v_eff)) show_vals(v)

d$gain_hat <- num(d[[v_gain]])
d$gain_hat2 <- d$gain_hat^2
d$winner <- as.numeric(d$gain_hat > 0)
d$fb_notlose <- as.numeric(!is_loser(d[[v_fb]]))
d$fb_wins <- as.numeric(is_winner(d[[v_fb]]))
d$init_notlose <- as.numeric(!is_loser(d[[v_init]]))
if (!is.na(v_accept)) {
  d$accept0 <- num(d[[v_accept]])
  if (all(is.na(d$accept0))) d$accept0 <- as.numeric(is_yes(d[[v_accept]]))
} else {
  d$accept0 <- as.numeric(!is_no(d[[v_appr]]))
}
d$approve0 <- as.numeric(is_yes(d[[v_appr]]))
gjv <- tolower(chr(d[[v_gj]]))
d$yv_supporter <- as.numeric(grepl("soutien|dedans|support|part|est_dans", gjv) & !grepl("oppos|comprend|understand", gjv))
d$yv_supporter[is.na(gjv)] <- NA
cat("YV supporter share:", mean(d$yv_supporter, na.rm = TRUE), "\n")
d$w <- if (!is.na(v_w)) num(d[[v_w]]) else 1
d$w[is.na(d$w)] <- 1

# ---------- controls ----------
ctrl_cands <- c("sexe", "age", "diplome4", "statut_emploi", "csp", "taille_agglo", "region",
                "taille_menage", "nb_14_et_plus", "revenu", "rev_tot", "fume", "actualite", "Gauche_droite")
socio <- character(0)
for (v in ctrl_cands) {
  if (!(v %in% nms)) next
  x <- d[[v]]
  if (mean(is.na(x)) > 0.2) next
  if (is.numeric(x) && !inherits(x, "haven_labelled") && length(unique(x)) > 15) {
    nm <- paste0("c_", v); d[[nm]] <- num(x); socio <- c(socio, nm)
    if (v %in% c("revenu", "rev_tot")) { nm2 <- paste0("c_", v, "_2"); d[[nm2]] <- num(x)^2; socio <- c(socio, nm2) }
  } else {
    f <- chr(x); f[is.na(f)] <- "missing"
    if (length(unique(f)) < 2) next
    nm <- paste0("f_", v); d[[nm]] <- factor(f); socio <- c(socio, nm)
  }
}
motives <- character(0)
if (!is.na(v_eff)) { d$m_eff_notno <- as.numeric(!is_no(d[[v_eff]])); d$m_eff_notno[is.na(d$m_eff_notno)] <- 0; motives <- c(motives, "m_eff_notno") }
if (!is.na(v_prog)) { d$m_prog_notno <- as.numeric(!is_no(d[[v_prog]])); d$m_prog_notno[is.na(d$m_prog_notno)] <- 0; motives <- c(motives, "m_prog_notno") }
cat("Controls:", paste(c(socio, motives), collapse = ", "), "\n")
ctrl_str <- paste(c(socio, motives), collapse = " + ")
if (ctrl_str == "") ctrl_str <- "1"

res <- list()
safe <- function(expr) tryCatch(expr, error = function(e) { cat("ERROR:", conditionMessage(e), "\n"); NULL })
getc <- function(m, nm) { if (is.null(m)) return(NA); cf <- coef(m); if (nm %in% names(cf)) unname(cf[nm]) else NA }

fbs <- d[!is.na(d$fb_notlose) & !is.na(d[[v_fb]]) & !is.na(d$gain_hat), ]
cat("Feedback sample:", nrow(fbs), "\n")
near <- fbs[abs(fbs$gain_hat) < 50, ]
cat("Near-threshold sample:", nrow(near), "\n")

f1 <- as.formula(paste("fb_notlose ~ winner + accept0 + gain_hat + gain_hat2 +", ctrl_str))
m1 <- safe(feols(f1, data = near, weights = ~w))
if (!is.null(m1)) {
  res$predicted_winner_believes_not_lose_table4_col1 <- getc(m1, "winner")
  res$initial_acceptance_believes_not_lose_table4_col1 <- getc(m1, "accept0")
  res$n_obs_table4_col1 <- nobs(m1)
}
m2 <- safe(feols(f1, data = fbs, weights = ~w))
res$predicted_winner_believes_not_lose_full_sample_table4_col2 <- getc(m2, "winner")

f3 <- as.formula(paste("fb_notlose ~ winner + accept0 + yv_supporter + init_notlose + winner:accept0 + winner:yv_supporter + winner:init_notlose + gain_hat + gain_hat2 +", ctrl_str))
m3 <- safe(feols(f3, data = near, weights = ~w))
res$predicted_winner_heterogeneity_table4_col3 <- getc(m3, "winner")
res$initial_acceptance_heterogeneity_table4_col3 <- getc(m3, "accept0")
res$yellow_vests_supporter_heterogeneity_table4_col3 <- getc(m3, "yv_supporter")
res$winner_x_initial_acceptance_table4_col3 <- getc(m3, "winner:accept0")
res$winner_x_yellow_vests_supporter_table4_col3 <- getc(m3, "winner:yv_supporter")
res$winner_x_initial_win_belief_table4_col3 <- getc(m3, "winner:init_notlose")

f4 <- as.formula(paste("fb_wins ~ winner + accept0 + gain_hat + gain_hat2 +", ctrl_str))
m4 <- safe(feols(f4, data = near, weights = ~w))
res$predicted_winner_believes_wins_table4_col4 <- getc(m4, "winner")

# ---------- Table 6: targeted dividend IV ----------
v_tc_app  <- pick(c("taxe_cible_approbation"), "cible_approbation")
v_tc_gain <- pick(c("gagnant_cible_categorie"), "cible_categ")
v_tr      <- pick(c("traite_cible"), "^traite_cible$")
v_trc     <- pick(c("traite_cible_conjoint"), "traite_cible_conj")
v_cible   <- pick(c("cible"), "^cible$")
v_pct     <- pick(c("percentile_revenu"), "^percentile_revenu$")
v_pctc    <- pick(c("percentile_revenu_conjoint"), "percentile_revenu_conj")
cat("T6 vars:", v_tc_app, v_tc_gain, v_tr, v_trc, v_cible, v_pct, v_pctc, "\n")
m6 <- safe({
  d$acc_t <- as.numeric(!is_no(d[[v_tc_app]]))
  d$nl_t <- as.numeric(!is_loser(d[[v_tc_gain]]))
  d$tr1 <- num(d[[v_tr]]); if (all(is.na(d$tr1))) d$tr1 <- as.numeric(is_yes(d[[v_tr]]) | chr(d[[v_tr]]) == "TRUE")
  ex <- c("accept0")
  inst <- "tr1"
  if (!is.na(v_trc)) {
    d$tr2 <- num(d[[v_trc]]); if (all(is.na(d$tr2))) d$tr2 <- as.numeric(chr(d[[v_trc]]) == "TRUE")
    d$tr2[is.na(d$tr2)] <- 0
    d$tr12 <- d$tr1 * d$tr2
    inst <- "tr1 + tr2 + tr12"
  }
  if (!is.na(v_cible)) { d$f_cible <- factor(chr(d[[v_cible]])); ex <- c(ex, "f_cible") }
  if (!is.na(v_single)) { d$single_n <- num(d[[v_single]]); if (all(is.na(d$single_n))) d$single_n <- as.numeric(chr(d[[v_single]]) == "TRUE"); ex <- c(ex, "single_n") }
  if (!is.na(v_pct)) { d$pct <- num(d[[v_pct]]); d$pct2 <- d$pct^2; ex <- c(ex, "pct", "pct2") }
  if (!is.na(v_pctc)) { d$pctc <- num(d[[v_pctc]]); d$pctc[is.na(d$pctc)] <- 0; d$pctc2 <- d$pctc^2; ex <- c(ex, "pctc", "pctc2") }
  ex <- c(ex, socio)
  f6 <- as.formula(paste("acc_t ~", paste(ex, collapse = " + "), "| nl_t ~", inst))
  feols(f6, data = d, weights = ~w)
})
res$believes_not_lose_on_acceptance_iv_table6_col1 <- getc(m6, "fit_nl_t")

# ---------- Table 8: effectiveness IV ----------
v_am  <- pick(c("apres_modifs"), "apres_modif")
v_icc <- pick(c("info_CC"), "^info_cc$")
cat("T8 vars:", v_am, v_icc, "\n")
m8 <- safe({
  d$eff_yes <- as.numeric(is_yes(d[[v_eff]]))
  d$z1 <- num(d[[v_am]]); if (all(is.na(d$z1))) d$z1 <- as.numeric(chr(d[[v_am]]) == "TRUE")
  d$z2 <- num(d[[v_icc]]); if (all(is.na(d$z2))) d$z2 <- as.numeric(chr(d[[v_icc]]) == "TRUE")
  ex8 <- c(socio, setdiff(motives, "m_eff_notno"), "gain_hat")
  f8 <- as.formula(paste("approve0 ~", paste(ex8, collapse = " + "), "| eff_yes ~ z1 + z2"))
  feols(f8, data = d, weights = ~w)
})
res$believes_effective_on_approval_iv_table8_col1 <- getc(m8, "fit_eff_yes")

for (n in names(res)) cat(sprintf("RESULT:%s=%s\n", n, format(res[[n]], digits = 6)))