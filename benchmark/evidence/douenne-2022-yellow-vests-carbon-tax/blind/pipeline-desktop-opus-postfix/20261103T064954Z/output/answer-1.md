suppressPackageStartupMessages({
  library(fixest)
  library(stats)
})
set.seed(42)

base <- "<repo>/.cache/datasets/douenne_2022_yellow_vests_carbon_tax.script-free"
rdata <- file.path(base, "yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
env <- new.env()
load(rdata, envir = env)
s <- env$s
s <- as.data.frame(s)

# ---------- helpers ----------
pick <- function(cands) {
  for (c in cands) if (c %in% names(s)) return(c)
  NA_character_
}
chr <- function(x) {
  if (is.factor(x)) return(as.character(x))
  if (inherits(x, "labelled")) x <- unclass(x)
  if (is.logical(x)) return(ifelse(is.na(x), NA, ifelse(x, "TRUE", "FALSE")))
  as.character(x)
}
num <- function(x) {
  if (is.factor(x)) return(suppressWarnings(as.numeric(as.character(x))))
  if (inherits(x, "labelled")) x <- unclass(x)
  if (is.logical(x)) return(as.numeric(x))
  suppressWarnings(as.numeric(x))
}
# 1 if belief is not "lose"
not_lose <- function(x) {
  x <- chr(x)
  out <- ifelse(is.na(x) | x == "" , NA, ifelse(grepl("perdant|lose|loser|losing", x, ignore.case = TRUE), 0, 1))
  out
}
wins <- function(x) {
  x <- chr(x)
  ifelse(is.na(x) | x == "", NA, ifelse(grepl("^gagnant|win|winner|winning", x, ignore.case = TRUE) &
                                          !grepl("non|not|un", x, ignore.case = TRUE), 1, 0))
}
yes01 <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x) && !inherits(x, "labelled")) return(as.numeric(x > 0))
  xc <- chr(x)
  n <- suppressWarnings(as.numeric(xc))
  if (all(is.na(xc) | !is.na(n))) return(as.numeric(n > 0))
  ifelse(is.na(xc), NA, as.numeric(grepl("^oui|^yes|^true", xc, ignore.case = TRUE)))
}
not_no01 <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x) && !inherits(x, "labelled")) return(as.numeric(x > 0))
  xc <- chr(x)
  n <- suppressWarnings(as.numeric(xc))
  if (all(is.na(xc) | !is.na(n))) return(as.numeric(n > 0))
  ifelse(is.na(xc), NA, as.numeric(!grepl("^non|^no$|^no |^false", xc, ignore.case = TRUE)))
}
safe_coef <- function(m, nm) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (nm %in% names(cf)) return(unname(cf[nm]))
  hit <- grep(nm, names(cf), fixed = TRUE)
  if (length(hit)) return(unname(cf[hit[1]]))
  NA_real_
}

# ---------- constructed variables ----------
d <- s
w_col <- pick(c("weight", "poids"))
d$w <- if (!is.na(w_col)) num(s[[w_col]]) else 1
d$w[is.na(d$w)] <- 1

gain_col <- pick(c("simule_gain", "simulated_gain", "estimated_gain", "gain_simule"))
d$g_hat <- num(s[[gain_col]])
d$g_hat2 <- d$g_hat^2

pw_col <- pick(c("simule_gagnant", "predicted_winner", "simulated_winner"))
d$predicted_winner <- if (!is.na(pw_col)) yes01(s[[pw_col]]) else as.numeric(d$g_hat > 0)

fb_col <- pick(c("gagnant_feedback_categorie", "winning_feedback_category"))
d$believes_not_lose_fb <- not_lose(s[[fb_col]])
d$believes_wins_fb <- wins(s[[fb_col]])

init_col <- pick(c("gagnant_categorie", "winning_category"))
d$initial_not_lose <- not_lose(s[[init_col]])
d$initial_cat <- factor(chr(s[[init_col]]))

acc_col <- pick(c("taxe_acceptation", "tax_acceptance"))
d$initial_acceptance <- not_no01(s[[acc_col]])
appr_col <- pick(c("taxe_approbation", "tax_approval"))
d$initial_approval <- yes01(s[[appr_col]])

# Yellow vests supporter: part of or supports the movement
if (all(c("gilets_jaunes_soutien", "gilets_jaunes_dedans") %in% names(s))) {
  d$yv_supporter <- as.numeric(yes01(s$gilets_jaunes_soutien) == 1 | yes01(s$gilets_jaunes_dedans) == 1)
} else if (!is.na(pick(c("gilets_jaunes")))) {
  gj <- chr(s$gilets_jaunes)
  d$yv_supporter <- ifelse(is.na(gj), NA, as.numeric(grepl("soutien|dedans|support|part", gj, ignore.case = TRUE)))
} else if (!is.na(pick(c("Gilets_jaunes")))) {
  gj <- num(s$Gilets_jaunes)
  d$yv_supporter <- as.numeric(gj >= 1)
} else {
  d$yv_supporter <- NA_real_
}

# feedback received: customized win/lose feedback (feedback only or feedback + progressivity)
vti_col <- pick(c("variante_taxe_info", "variant_tax_info"))
if (!is.na(vti_col)) {
  v <- chr(s[[vti_col]])
  d$got_feedback <- as.numeric(!is.na(v) & grepl("f", v, ignore.case = TRUE))
} else {
  d$got_feedback <- as.numeric(!is.na(d$believes_not_lose_fb))
}

# ---------- controls ----------
ctrl_cands <- c("single", "revenu", "rev_tot", "sexe", "age", "diplome4", "csp", "taille_agglo",
                "region", "statut_emploi", "nb_14_et_plus", "nb_adultes",
                "hausse_depenses_par_uc", "fioul", "gaz", "Gauche_droite")
ctrl <- intersect(ctrl_cands, names(s))
# avoid duplicate age encodings
ctrl_terms <- c()
for (v in ctrl) {
  x <- s[[v]]
  if (is.factor(x) || is.character(x) || (is.logical(x) && FALSE)) {
    nm <- paste0("c_", v)
    d[[nm]] <- factor(chr(x))
    if (nlevels(d[[nm]]) > 1 && nlevels(d[[nm]]) < 60) ctrl_terms <- c(ctrl_terms, nm)
  } else {
    nm <- paste0("c_", v)
    d[[nm]] <- num(x)
    if (sum(!is.na(d[[nm]])) > 0 && sd(d[[nm]], na.rm = TRUE) > 0) ctrl_terms <- c(ctrl_terms, nm)
  }
}
if ("c_revenu" %in% ctrl_terms) { d$c_revenu2 <- d$c_revenu^2; ctrl_terms <- c(ctrl_terms, "c_revenu2") }
# drop control rows missing -> set numeric NA to mean & factor NA to level to keep sample
for (nm in ctrl_terms) {
  if (is.factor(d[[nm]])) {
    if (any(is.na(d[[nm]]))) d[[nm]] <- addNA(d[[nm]])
  } else {
    if (any(is.na(d[[nm]]))) d[[nm]][is.na(d[[nm]])] <- mean(d[[nm]], na.rm = TRUE)
  }
}
ctrl_str <- if (length(ctrl_terms)) paste(ctrl_terms, collapse = " + ") else "1"

fit_lm <- function(fml, data) {
  tryCatch(feols(as.formula(fml), data = data, weights = ~w, vcov = "hetero"),
           error = function(e) { message("ERR: ", conditionMessage(e)); NULL })
}

# ---------- Table 4 ----------
cat(sprintf("SAMPLE:table4_col1:loaded=%d\n", nrow(d)))
t4 <- d[d$got_feedback == 1, ]
cat(sprintf("SAMPLE:table4_col1:received_feedback=%d\n", nrow(t4)))
t4 <- t4[!is.na(t4$believes_not_lose_fb), ]
cat(sprintf("SAMPLE:table4_col1:answered_feedback_belief=%d\n", nrow(t4)))
t4a <- t4[!is.na(t4$g_hat) & abs(t4$g_hat) < 50, ]
cat(sprintf("SAMPLE:table4_col1:abs_gain_below_50=%d\n", nrow(t4a)))

f1 <- paste("believes_not_lose_fb ~ predicted_winner + initial_acceptance + g_hat + g_hat2 +", ctrl_str)
m1 <- fit_lm(f1, t4a)
cat(sprintf("SAMPLE:table4_col1:estimation=%d\n", if (is.null(m1)) 0L else nobs(m1)))

cat(sprintf("SAMPLE:table4_col2:loaded=%d\n", nrow(d)))
cat(sprintf("SAMPLE:table4_col2:received_feedback=%d\n", sum(d$got_feedback == 1)))
cat(sprintf("SAMPLE:table4_col2:answered_feedback_belief=%d\n", nrow(t4)))
m2 <- fit_lm(f1, t4)
cat(sprintf("SAMPLE:table4_col2:estimation=%d\n", if (is.null(m2)) 0L else nobs(m2)))

f3 <- paste("believes_not_lose_fb ~ predicted_winner + initial_acceptance + yv_supporter + initial_not_lose +",
            "predicted_winner:initial_acceptance + predicted_winner:yv_supporter + predicted_winner:initial_not_lose +",
            "initial_cat + g_hat + g_hat2 +", ctrl_str)
cat(sprintf("SAMPLE:table4_col3:loaded=%d\n", nrow(d)))
cat(sprintf("SAMPLE:table4_col3:received_feedback=%d\n", sum(d$got_feedback == 1)))
cat(sprintf("SAMPLE:table4_col3:abs_gain_below_50=%d\n", nrow(t4a)))
m3 <- fit_lm(f3, t4a)
cat(sprintf("SAMPLE:table4_col3:estimation=%d\n", if (is.null(m3)) 0L else nobs(m3)))

t4w <- t4a[!is.na(t4a$believes_wins_fb), ]
f4 <- paste("believes_wins_fb ~ predicted_winner + initial_acceptance + g_hat + g_hat2 +", ctrl_str)
cat(sprintf("SAMPLE:table4_col4:loaded=%d\n", nrow(d)))
cat(sprintf("SAMPLE:table4_col4:received_feedback=%d\n", sum(d$got_feedback == 1)))
cat(sprintf("SAMPLE:table4_col4:abs_gain_below_50=%d\n", nrow(t4w)))
m4 <- fit_lm(f4, t4w)
cat(sprintf("SAMPLE:table4_col4:estimation=%d\n", if (is.null(m4)) 0L else nobs(m4)))

int_coef <- function(m, a, b) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  for (nm in c(paste0(a, ":", b), paste0(b, ":", a))) if (nm %in% names(cf)) return(unname(cf[nm]))
  NA_real_
}

# ---------- Table 6: targeted dividend IV ----------
cible_col <- pick(c("cible", "target_threshold", "seuil_cible"))
tc_col <- pick(c("traite_cible", "eligible_cible", "treated_target"))
tcc_col <- pick(c("traite_cible_conjoint", "eligible_cible_conjoint", "treated_target_spouse"))
tca_col <- pick(c("taxe_cible_acceptation", "tax_cible_acceptance"))
wc_col <- pick(c("gagnant_cible_categorie", "win_cible_category"))
pr_col <- pick(c("percentile_revenu"))
prc_col <- pick(c("percentile_revenu_conjoint"))

d$cible <- if (!is.na(cible_col)) num(s[[cible_col]]) else NA_real_
d$pr <- if (!is.na(pr_col)) num(s[[pr_col]]) else NA_real_
d$prc <- if (!is.na(prc_col)) num(s[[prc_col]]) else NA_real_
d$tc <- if (!is.na(tc_col)) yes01(s[[tc_col]]) else as.numeric(d$pr <= d$cible)
d$tcc <- if (!is.na(tcc_col)) yes01(s[[tcc_col]]) else as.numeric(!is.na(d$prc) & d$prc <= d$cible)
d$tcc[is.na(d$tcc)] <- 0
d$tc_x_tcc <- d$tc * d$tcc
d$acc_target <- not_no01(s[[tca_col]])
d$notlose_target <- not_lose(s[[wc_col]])
d$prc0 <- ifelse(is.na(d$prc), 0, d$prc)
d$pr2 <- d$pr^2; d$pr3 <- d$pr^3
d$prc2 <- d$prc0^2; d$prc3 <- d$prc0^3
d$single_ind <- if ("single" %in% names(s)) yes01(s$single) else as.numeric(num(s$nb_adultes) == 1)

cat(sprintf("SAMPLE:table6_col1:loaded=%d\n", nrow(d)))
t6 <- d[!is.na(d$cible), ]
cat(sprintf("SAMPLE:table6_col1:assigned_target_threshold=%d\n", nrow(t6)))
t6 <- t6[!is.na(t6$acc_target) & !is.na(t6$notlose_target) & !is.na(t6$tc) & !is.na(t6$pr), ]
cat(sprintf("SAMPLE:table6_col1:nonmissing_outcome_belief_instruments=%d\n", nrow(t6)))
f6 <- paste("acc_target ~ factor(cible) + single_ind + initial_acceptance + pr + pr2 + pr3 + prc0 + prc2 + prc3 +",
            ctrl_str, "| notlose_target ~ tc + tcc + tc_x_tcc")
m6 <- tryCatch(feols(as.formula(f6), data = t6, weights = ~w, vcov = "hetero"),
               error = function(e) { message("ERR6: ", conditionMessage(e)); NULL })
cat(sprintf("SAMPLE:table6_col1:estimation=%d\n", if (is.null(m6)) 0L else nobs(m6)))
b6 <- if (is.null(m6)) NA_real_ else safe_coef(m6, "fit_notlose_target")

# ---------- Table 8: effectiveness IV ----------
eff_col <- pick(c("taxe_efficace", "tax_effective", "effective"))
d$believes_effective <- yes01(s[[eff_col]])
am_col <- pick(c("apres_modifs", "info_scientists", "scientists_agree"))
cc_col <- pick(c("info_CC", "info_climate"))
d$z_sci <- yes01(s[[am_col]])
d$z_cc <- yes01(s[[cc_col]])

cat(sprintf("SAMPLE:table8_col1:loaded=%d\n", nrow(d)))
t8 <- d[!is.na(d$initial_approval) & !is.na(d$believes_effective) & !is.na(d$z_sci) & !is.na(d$z_cc), ]
cat(sprintf("SAMPLE:table8_col1:nonmissing_outcome_belief_instruments=%d\n", nrow(t8)))
t8$g_hat[is.na(t8$g_hat)] <- 0; t8$g_hat2 <- t8$g_hat^2
f8 <- paste("initial_approval ~ g_hat + g_hat2 + initial_not_lose +", ctrl_str,
            "| believes_effective ~ z_sci + z_cc")
m8 <- tryCatch(feols(as.formula(f8), data = t8, weights = ~w, vcov = "hetero"),
               error = function(e) { message("ERR8: ", conditionMessage(e)); NULL })
cat(sprintf("SAMPLE:table8_col1:estimation=%d\n", if (is.null(m8)) 0L else nobs(m8)))
b8 <- if (is.null(m8)) NA_real_ else safe_coef(m8, "fit_believes_effective")

# ---------- results ----------
out <- function(nm, v) cat(sprintf("RESULT:%s=%s\n", nm, ifelse(is.na(v), "NA", format(v, digits = 6))))
out("predicted_winner_believes_not_lose_table4_col1", safe_coef(m1, "predicted_winner"))
out("initial_acceptance_believes_not_lose_table4_col1", safe_coef(m1, "initial_acceptance"))
out("predicted_winner_believes_not_lose_full_sample_table4_col2", safe_coef(m2, "predicted_winner"))
out("predicted_winner_heterogeneity_table4_col3", if (is.null(m3)) NA else unname(coef(m3)["predicted_winner"]))
out("initial_acceptance_heterogeneity_table4_col3", if (is.null(m3)) NA else unname(coef(m3)["initial_acceptance"]))
out("yellow_vests_supporter_heterogeneity_table4_col3", if (is.null(m3)) NA else unname(coef(m3)["yv_supporter"]))
out("winner_x_initial_acceptance_table4_col3", int_coef(m3, "predicted_winner", "initial_acceptance"))
out("winner_x_yellow_vests_supporter_table4_col3", int_coef(m3, "predicted_winner", "yv_supporter"))
out("winner_x_initial_win_belief_table4_col3", int_coef(m3, "predicted_winner", "initial_not_lose"))
out("predicted_winner_believes_wins_table4_col4", safe_coef(m4, "predicted_winner"))
out("n_obs_table4_col1", if (is.null(m1)) nrow(t4a) else nobs(m1))
out("believes_not_lose_on_acceptance_iv_table6_col1", b6)
out("believes_effective_on_approval_iv_table8_col1", b8)
