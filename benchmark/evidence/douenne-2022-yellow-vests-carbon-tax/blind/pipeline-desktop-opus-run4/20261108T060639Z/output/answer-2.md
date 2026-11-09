suppressPackageStartupMessages({
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/douenne_2022_yellow_vests_carbon_tax.script-free"
rdata <- file.path(root, "yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
load(rdata)
s <- as.data.frame(s)

# ---- strip memisc (S4) item classes without loading memisc ----
lab_map <- list()
strip_s4 <- function(x) {
  if (isS4(x)) x <- asS4(x, FALSE, FALSE)
  x
}
clean_col <- function(x, nmx) {
  cl <- attr(x, "class")
  pk <- if (!is.null(cl)) attr(cl, "package") else NULL
  if (!isS4(x) && is.null(pk)) return(x)
  y <- strip_s4(x)
  vl <- attr(y, "value.labels")
  if (!is.null(vl)) {
    tryCatch({
      vl2 <- strip_s4(vl)
      vals <- attr(vl2, "values")
      if (!is.null(vals)) { vals <- strip_s4(vals); attributes(vals) <- NULL }
      attributes(vl2) <- NULL
      lab_map[[nmx]] <<- paste0(vals, "=", vl2)
    }, error = function(e) NULL)
  }
  attributes(y) <- NULL
  if (is.list(y) || length(y) != nrow(s)) y <- rep(NA, nrow(s))
  y
}
for (i in seq_along(s)) {
  nmi <- names(s)[i]
  s[[i]] <- tryCatch(clean_col(s[[i]], nmi), error = function(e) {
    y <- tryCatch({ z <- asS4(s[[i]], FALSE, FALSE); attributes(z) <- NULL; z },
                  error = function(e2) rep(NA, nrow(s)))
    if (length(y) != nrow(s)) y <- rep(NA, nrow(s))
    y
  })
}
cat("DIAG memisc-stripped columns with labels:", length(lab_map), "\n")
nm <- names(s)
cat("Rows in s:", nrow(s), " columns:", length(nm), "\n")

# ---------------- helpers ----------------
show_cols <- function(rx) {
  h <- grep(rx, nm, value = TRUE, ignore.case = TRUE)
  cat("DIAG cols ~", rx, ":", paste(head(h, 60), collapse = ", "), "\n")
}
for (rx in c("gagn|win", "simul|gain", "cible|target", "approb|approv|accept",
             "gilet|yellow", "efficac|effectiv", "info|modif", "variant",
             "revenu|income", "weight|poids", "traite|treat", "single|conjoint|partner"))
  show_cols(rx)

pick <- function(cands, rx = NULL, avoid_numeric = FALSE) {
  for (c in cands) if (c %in% nm) {
    if (!avoid_numeric || !is.numeric(s[[c]])) return(c)
  }
  for (c in cands) if (c %in% nm) return(c)
  if (!is.null(rx)) {
    h <- grep(rx, nm, value = TRUE, ignore.case = TRUE)
    if (length(h)) return(h[1])
  }
  NA_character_
}

as_chr <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::as_factor(x)
  tolower(trimws(as.character(x)))
}

# "No" answer (for acceptance = not No)
is_no <- function(x) {
  if (is.numeric(x) && !inherits(x, "haven_labelled")) { out <- x < 0; return(out) }
  if (is.logical(x)) return(!x)
  v <- as_chr(x)
  out <- v %in% c("non", "no", "false")
  out[is.na(v) | v == ""] <- NA
  out
}
is_yes <- function(x) {
  if (is.numeric(x) && !inherits(x, "haven_labelled")) { out <- x > 0; return(out) }
  if (is.logical(x)) return(x)
  v <- as_chr(x)
  out <- v %in% c("oui", "yes", "true")
  out[is.na(v) | v == ""] <- NA
  out
}
is_loser <- function(x) {
  if (is.numeric(x) && !inherits(x, "haven_labelled")) return(x < 0)
  v <- as_chr(x)
  out <- grepl("perdant|los", v)
  out[is.na(v) | v == ""] <- NA
  out
}
is_winner <- function(x) {
  if (is.numeric(x) && !inherits(x, "haven_labelled")) return(x > 0)
  v <- as_chr(x)
  out <- grepl("gagnant|win", v) & !grepl("non|not|un", v)
  out[is.na(v) | v == ""] <- NA
  out
}
is_yv_supporter <- function(x) {
  if (is.numeric(x) && !inherits(x, "haven_labelled")) return(!is.na(x) & x >= 1)
  v <- as_chr(x)
  out <- grepl("soutient|dedans|support|part|member|inside", v)
  out[is.na(v)] <- FALSE
  out
}

clean_ctrl <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::as_factor(x)
  if (is.character(x) || is.factor(x) || is.logical(x)) {
    x <- as.character(x); x[is.na(x) | x == ""] <- "missing"; return(factor(x))
  }
  x <- as.numeric(x)
  if (all(is.na(x))) return(rep(0, length(x)))
  x[is.na(x)] <- mean(x, na.rm = TRUE)
  x
}

num01 <- function(x) as.numeric(x)

fmt <- function(x) if (is.null(x) || length(x) == 0 || is.na(x)) "NA" else format(unname(x), digits = 10)
results <- list()
setres <- function(name, val) results[[name]] <<- val

# ---------------- variables ----------------
v_w        <- pick(c("weight", "poids", "weights"))
w          <- if (!is.na(v_w)) as.numeric(s[[v_w]]) else rep(1, nrow(s))
w[is.na(w)] <- 1

v_gain     <- pick(c("simule_gain", "simulated_gain", "estimated_gain", "gain_simule", "simulated_net_gain"),
                   "simul.*gain|estim.*gain")
v_pwin     <- pick(c("simule_gagnant", "simulated_winner", "predicted_winner", "simule_gagnant_feedback"),
                   "simul.*(gagn|win)|predict.*win")
v_init_cat <- pick(c("winning_category", "gagnant_categorie"))
v_fb_cat   <- pick(c("winning_feedback_category", "gagnant_feedback_categorie"))
v_approb   <- pick(c("taxe_approbation", "tax_approval", "approval_tax", "tax_approbation", "initial_tax_approval"),
                   "^tax.*approv|^taxe_approb")
v_yv       <- pick(c("gilets_jaunes", "yellow_vests", "Gilets_jaunes", "yellow_vest"), "gilet|yellow", avoid_numeric = TRUE)
v_eff      <- pick(c("taxe_efficace", "tax_effective", "effective_tax", "tax_efficacy", "effectiveness"), "efficac|effective")
v_prog     <- pick(c("progressivite", "progressivity", "tax_progressivity", "progressive"), "progressiv")
v_rev      <- pick(c("revenu", "income", "Revenu"))
v_revc     <- pick(c("revenu_conjoint", "rev_conjoint", "income_partner", "spouse_income", "partner_income", "income_spouse"))
v_single   <- pick(c("single", "seul", "celibataire"))

cat("DIAG picked: weight=", v_w, " gain=", v_gain, " pwin=", v_pwin, " init_cat=", v_init_cat,
    " fb_cat=", v_fb_cat, " approb=", v_approb, " yv=", v_yv, " eff=", v_eff, " prog=", v_prog,
    " rev=", v_rev, " revc=", v_revc, " single=", v_single, "\n")
for (v in c(v_init_cat, v_fb_cat, v_approb, v_yv, v_eff, v_pwin)) if (!is.na(v)) {
  cat("DIAG table", v, ":\n"); print(table(s[[v]], useNA = "ifany"))
  if (!is.null(lab_map[[v]])) cat("DIAG labels", v, ":", paste(lab_map[[v]], collapse = "; "), "\n")
}

gain <- if (!is.na(v_gain)) as.numeric(s[[v_gain]]) else rep(NA_real_, nrow(s))
pwin <- if (!is.na(v_pwin)) num01(as.numeric(s[[v_pwin]] > 0 | s[[v_pwin]] == TRUE)) else as.numeric(gain > 0)
if (!is.na(v_pwin) && is.numeric(s[[v_pwin]])) pwin <- as.numeric(s[[v_pwin]] > 0)

init_accept  <- if (!is.na(v_approb)) num01(!is_no(s[[v_approb]])) else rep(NA_real_, nrow(s))
init_approve <- if (!is.na(v_approb)) num01(is_yes(s[[v_approb]])) else rep(NA_real_, nrow(s))
yv_sup       <- if (!is.na(v_yv)) num01(is_yv_supporter(s[[v_yv]])) else rep(0, nrow(s))
init_notlose <- if (!is.na(v_init_cat)) num01(!is_loser(s[[v_init_cat]])) else rep(NA_real_, nrow(s))
init_catf    <- if (!is.na(v_init_cat)) clean_ctrl(s[[v_init_cat]]) else factor(rep("x", nrow(s)))
fb_raw       <- if (!is.na(v_fb_cat)) s[[v_fb_cat]] else rep(NA, nrow(s))
fb_notlose   <- num01(!is_loser(fb_raw))
fb_wins      <- num01(is_winner(fb_raw))
feedback     <- !is.na(fb_raw) & as_chr(fb_raw) != ""

rev  <- if (!is.na(v_rev)) clean_ctrl(s[[v_rev]]) else rep(0, nrow(s))
revc <- if (!is.na(v_revc)) clean_ctrl(s[[v_revc]]) else rep(0, nrow(s))
if (!is.numeric(rev)) rev <- rep(0, nrow(s))
if (!is.numeric(revc)) revc <- rep(0, nrow(s))
single <- if (!is.na(v_single)) clean_ctrl(s[[v_single]]) else rep(0, nrow(s))

# socio-demographic controls
demo_cands <- list(c("sexe", "sex", "gender"), c("age"), c("diplome4", "diplome", "education"),
                   c("csp"), c("statut_emploi"), c("taille_agglo", "town_size"), c("region"),
                   c("taille_menage", "household_size"), c("nb_14_et_plus"), c("fume"), c("actualite"))
demo_vars <- unique(na.omit(sapply(demo_cands, function(cc) pick(cc))))
cat("DIAG demo controls:", paste(demo_vars, collapse = ", "), "\n")

d <- data.frame(w = w, gain = gain / 100, gain2 = (gain / 100)^2, pwin = pwin,
                init_accept = init_accept, init_approve = init_approve, yv_sup = yv_sup,
                init_notlose = init_notlose, init_catf = init_catf,
                fb_notlose = fb_notlose, fb_wins = fb_wins, feedback = feedback,
                rev = rev / 1000, rev2 = (rev / 1000)^2, revc = revc / 1000, revc2 = (revc / 1000)^2,
                single = single)
ctrl_names <- c()
for (i in seq_along(demo_vars)) {
  cn <- paste0("demo", i); d[[cn]] <- clean_ctrl(s[[demo_vars[i]]]); ctrl_names <- c(ctrl_names, cn)
}
motive_names <- c()
if (!is.na(v_eff))  { d$mot_eff  <- clean_ctrl(s[[v_eff]]);  motive_names <- c(motive_names, "mot_eff") }
if (!is.na(v_prog)) { d$mot_prog <- clean_ctrl(s[[v_prog]]); motive_names <- c(motive_names, "mot_prog") }

income_ctrls <- c("rev", "rev2", "revc", "revc2", "single")
base_ctrls4  <- c("gain", "gain2", income_ctrls, ctrl_names, motive_names)

wfit <- function(fml, data) {
  feols(as.formula(fml), data = data, weights = ~w, vcov = "iid", warn = FALSE, notes = FALSE)
}
getc <- function(m, nmv) { cf <- coef(m); if (nmv %in% names(cf)) cf[[nmv]] else NA_real_ }

# ---------------- Table 4 ----------------
d$sub50 <- d$feedback & !is.na(d$gain) & abs(gain) < 50
cat("DIAG feedback N =", sum(d$feedback), " within 50 N =", sum(d$sub50, na.rm = TRUE), "\n")

rhs1 <- paste(c("pwin", "init_accept", base_ctrls4), collapse = " + ")
tryCatch({
  m1 <- wfit(paste("fb_notlose ~", rhs1), d[which(d$sub50), ])
  setres("predicted_winner_believes_not_lose_table4_col1", getc(m1, "pwin"))
  setres("initial_acceptance_believes_not_lose_table4_col1", getc(m1, "init_accept"))
  setres("n_obs_table4_col1", nobs(m1))
}, error = function(e) cat("ERR col1:", conditionMessage(e), "\n"))

tryCatch({
  m2 <- wfit(paste("fb_notlose ~", rhs1), d[which(d$feedback), ])
  setres("predicted_winner_believes_not_lose_full_sample_table4_col2", getc(m2, "pwin"))
}, error = function(e) cat("ERR col2:", conditionMessage(e), "\n"))

tryCatch({
  rhs3 <- paste(c("pwin", "init_accept", "yv_sup", "init_notlose",
                  "pwin:init_accept", "pwin:yv_sup", "pwin:init_notlose",
                  "init_catf", base_ctrls4), collapse = " + ")
  m3 <- wfit(paste("fb_notlose ~", rhs3), d[which(d$sub50), ])
  cf <- coef(m3)
  gi <- function(a, b) { k <- c(paste0(a, ":", b), paste0(b, ":", a)); k <- k[k %in% names(cf)]; if (length(k)) cf[[k[1]]] else NA_real_ }
  setres("predicted_winner_heterogeneity_table4_col3", getc(m3, "pwin"))
  setres("initial_acceptance_heterogeneity_table4_col3", getc(m3, "init_accept"))
  setres("yellow_vests_supporter_heterogeneity_table4_col3", getc(m3, "yv_sup"))
  setres("winner_x_initial_acceptance_table4_col3", gi("pwin", "init_accept"))
  setres("winner_x_yellow_vests_supporter_table4_col3", gi("pwin", "yv_sup"))
  setres("winner_x_initial_win_belief_table4_col3", gi("pwin", "init_notlose"))
}, error = function(e) cat("ERR col3:", conditionMessage(e), "\n"))

tryCatch({
  m4 <- wfit(paste("fb_wins ~", rhs1), d[which(d$sub50), ])
  setres("predicted_winner_believes_wins_table4_col4", getc(m4, "pwin"))
}, error = function(e) cat("ERR col4:", conditionMessage(e), "\n"))

# ---------------- Table 6: targeted dividend fuzzy RDD / IV ----------------
v_tapp  <- pick(c("taxe_cible_approbation", "targeted_tax_approval", "tax_target_approval", "target_tax_approval",
                  "tax_targeted_approval"), "cible.*approb|target.*approv")
v_tcat  <- pick(c("gagnant_cible_categorie", "winning_target_category", "winning_targeted_category",
                  "target_winning_category"), "cible.*categ|target.*categ")
v_t1    <- pick(c("traite_cible", "treated_target", "target_treated", "treated_targeted", "eligible_target"),
                "^traite_cible$|treat.*target$|target.*treat")
v_t2    <- pick(c("traite_cible_conjoint", "treated_target_partner", "treated_target_spouse", "target_treated_partner",
                  "treated_targeted_partner"), "traite_cible_conj|treat.*target.*(partner|spouse|conj)")
v_cible <- pick(c("cible", "target", "targeted_percentile", "target_percentile"), "^cible$|^target$")
cat("DIAG T6: approval=", v_tapp, " cat=", v_tcat, " t1=", v_t1, " t2=", v_t2, " cible=", v_cible, "\n")
for (v in c(v_tapp, v_tcat, v_t1, v_t2, v_cible)) if (!is.na(v)) {
  cat("DIAG table", v, ":\n"); print(table(s[[v]], useNA = "ifany"))
}

tryCatch({
  d$t_accept  <- num01(!is_no(s[[v_tapp]]))
  d$t_notlose <- num01(!is_loser(s[[v_tcat]]))
  t1 <- as.numeric(s[[v_t1]]); if (all(is.na(t1))) t1 <- num01(is_yes(s[[v_t1]]))
  t2 <- if (!is.na(v_t2)) as.numeric(s[[v_t2]]) else rep(0, nrow(s))
  t1[is.na(t1)] <- 0; t2[is.na(t2)] <- 0
  d$t1 <- t1; d$t2 <- t2; d$t12 <- t1 * t2
  d$cible_f <- if (!is.na(v_cible)) clean_ctrl(as.character(s[[v_cible]])) else factor(rep("x", nrow(s)))
  ctr6 <- c("cible_f", "single", "init_accept", "gain", "gain2", income_ctrls[1:4], ctrl_names, motive_names)
  ctr6 <- unique(ctr6)
  dd <- d[!is.na(d$t_accept) & !is.na(d$t_notlose) & !is.na(d$init_accept), ]
  insts <- if (!is.na(v_t2)) "t1 + t2 + t12" else "t1"
  f6 <- paste("t_accept ~", paste(ctr6, collapse = " + "), "| t_notlose ~", insts)
  m6 <- wfit(f6, dd)
  setres("believes_not_lose_on_acceptance_iv_table6_col1", getc(m6, "fit_t_notlose"))
  cat("DIAG T6 N =", nobs(m6), "\n")
}, error = function(e) cat("ERR T6:", conditionMessage(e), "\n"))

# ---------------- Table 8: effectiveness IV ----------------
v_ieff <- pick(c("apres_modifs", "info_efficacite", "info_effectiveness", "info_effective", "after_modifs",
                 "info_tax_effective", "effectiveness_info"), "apres_modif|info.*effic|info.*effect")
v_icc  <- pick(c("info_CC", "info_cc", "info_climate", "info_climate_change"), "^info_cc$|info.*climat")
cat("DIAG T8: info_eff=", v_ieff, " info_cc=", v_icc, "\n")
for (v in c(v_ieff, v_icc)) if (!is.na(v)) { cat("DIAG table", v, ":\n"); print(table(s[[v]], useNA = "ifany")) }

tryCatch({
  tobin <- function(x) {
    if (is.logical(x)) return(as.numeric(x))
    if (is.numeric(x)) return(as.numeric(x > 0))
    num01(is_yes(x) | as_chr(x) %in% c("1", "true"))
  }
  d$z_eff <- tobin(s[[v_ieff]]); d$z_cc <- tobin(s[[v_icc]])
  d$z_eff[is.na(d$z_eff)] <- 0; d$z_cc[is.na(d$z_cc)] <- 0
  d$eff_yes <- num01(is_yes(s[[v_eff]]))
  ctr8 <- c(ctrl_names, if ("mot_prog" %in% names(d)) "mot_prog", income_ctrls, "gain", "gain2")
  dd <- d[!is.na(d$init_approve) & !is.na(d$eff_yes), ]
  f8 <- paste("init_approve ~", paste(ctr8, collapse = " + "), "| eff_yes ~ z_eff + z_cc")
  m8 <- wfit(f8, dd)
  setres("believes_effective_on_approval_iv_table8_col1", getc(m8, "fit_eff_yes"))
  cat("DIAG T8 N =", nobs(m8), "\n")
}, error = function(e) cat("ERR T8:", conditionMessage(e), "\n"))

# ---------------- output ----------------
out_names <- c("predicted_winner_believes_not_lose_table4_col1",
               "initial_acceptance_believes_not_lose_table4_col1",
               "predicted_winner_believes_not_lose_full_sample_table4_col2",
               "predicted_winner_heterogeneity_table4_col3",
               "initial_acceptance_heterogeneity_table4_col3",
               "yellow_vests_supporter_heterogeneity_table4_col3",
               "winner_x_initial_acceptance_table4_col3",
               "winner_x_yellow_vests_supporter_table4_col3",
               "winner_x_initial_win_belief_table4_col3",
               "predicted_winner_believes_wins_table4_col4",
               "n_obs_table4_col1",
               "believes_not_lose_on_acceptance_iv_table6_col1",
               "believes_effective_on_approval_iv_table8_col1")
for (n in out_names) cat(paste0("RESULT:", n, "=", fmt(results[[n]]), "\n"))
