suppressPackageStartupMessages({
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/douenne_2022_yellow_vests_carbon_tax.script-free"
rdata <- file.path(base, "yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
load(rdata)

s <- as.data.frame(s)
nm <- names(s)
cat("N rows:", nrow(s), "\n")

pick <- function(cands) {
  x <- cands[cands %in% nm]
  if (length(x)) x[1] else NA_character_
}
grepn <- function(p) nm[grepl(p, nm, ignore.case = TRUE)]
lowc <- function(x) { y <- tolower(trimws(as.character(x))); y[y %in% c("", "na")] <- NA; y }
flag <- function(x, pat) { y <- lowc(x); out <- as.numeric(grepl(pat, y)); out[is.na(y)] <- NA; out }
is_loser  <- function(x) flag(x, "perd|los")
is_winner <- function(x) flag(x, "^gagn|^win")
is_yes    <- function(x) { if (is.numeric(x) || is.logical(x)) return(as.numeric(x > 0)); flag(x, "^oui|^yes") }
is_no     <- function(x) { if (is.numeric(x) || is.logical(x)) return(as.numeric(x <= 0)); flag(x, "^non$|^no$|^non |^no ") }
is_nsp    <- function(x) flag(x, "^nsp|^pnr|ne sais|know")
to01 <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x > 0))
  y <- lowc(x)
  out <- as.numeric(y %in% c("true", "oui", "yes", "1", "t"))
  out[is.na(y)] <- NA
  out
}

for (p in c("simul", "gagn", "winning", "approb", "accept", "gilets", "cible", "efficac", "modif", "info_", "percentile", "weight", "feedback")) {
  cat(p, ":", paste(head(grepn(p), 30), collapse = ", "), "\n")
}

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
}

# ---------------- core variables ----------------
wname <- pick(c("weight", "poids", "weights"))
s$w_ <- if (!is.na(wname)) as.numeric(s[[wname]]) else 1
s$w_[is.na(s$w_)] <- 0

gname <- pick(c("simule_gain", "simulated_gain", "Simule_gain", "estimated_gain", "gain_simule"))
if (is.na(gname)) { g2 <- grepn("^simule_gain"); if (length(g2)) gname <- g2[1] }
cat("gain var:", gname, "\n")
s$sg <- as.numeric(s[[gname]])
s$sg2 <- s$sg^2

wn <- pick(c("simule_gagnant", "simulated_winner", "predicted_winner"))
if (!is.na(wn)) s$pwin <- to01(s[[wn]]) else s$pwin <- as.numeric(s$sg > 0)
s$pwin[is.na(s$pwin) & !is.na(s$sg)] <- as.numeric(s$sg[is.na(s$pwin) & !is.na(s$sg)] > 0)

fb <- s$winning_feedback_category
s$y_notlose <- 1 - is_loser(fb)
s$y_win <- is_winner(fb)
s$has_fb <- !is.na(lowc(fb))

ini <- s$winning_category
s$G <- 1 - is_loser(ini)
s$G_win <- is_winner(ini)

appr <- pick(c("taxe_approbation", "tax_approval_cat", "approbation_taxe"))
cat("approval var:", appr, "\n")
acc <- pick(c("tax_acceptance", "taxe_acceptation"))
if (!is.na(acc)) {
  s$acc0 <- to01(s[[acc]])
} else {
  s$acc0 <- 1 - is_no(s[[appr]])
}
s$nsp0 <- if (!is.na(appr)) is_nsp(s[[appr]]) else 0
s$appr0 <- if (!is.na(appr)) is_yes(s[[appr]]) else NA

gj <- pick(c("gilets_jaunes", "Gilets_jaunes", "yellow_vests"))
if (!is.na(gj)) {
  x <- s[[gj]]
  if (is.numeric(x)) s$yv <- as.numeric(x >= 1) else s$yv <- flag(x, "soutien|dedans|support|part|est_")
} else {
  g3 <- grepn("gilets_jaunes_(soutien|dedans)")
  s$yv <- if (length(g3)) as.numeric(rowSums(sapply(g3, function(v) to01(s[[v]])), na.rm = TRUE) > 0) else 0
}
cat("YV share:", mean(s$yv, na.rm = TRUE), "\n")

# ---------------- controls ----------------
valid_terms <- function(v) {
  v <- unique(v[!is.na(v)])
  v[sapply(v, function(t) tryCatch({
    av <- all.vars(str2lang(t)); length(av) > 0 && all(av %in% nm)
  }, error = function(e) FALSE))]
}
ctrl <- character(0)
for (o in c("variables_reg_self_interest", "variables_demo")) {
  if (exists(o) && is.character(get(o))) ctrl <- c(ctrl, get(o))
}
if (!length(ctrl)) {
  ctrl <- c("sexe", "age", "csp", "diplome", "taille_agglo", "region", "statut_emploi",
            "taille_menage", "nb_14_et_plus", "revenu", "rev_tot", "revenu_conjoint")
}
ctrl <- c(ctrl, "revenu", "rev_tot", "single", "hausse_depenses_par_uc")
ctrl <- valid_terms(ctrl)
# remove anything that duplicates key regressors / outcomes
bad <- c(gname, wn, appr, acc, gj, "winning_category", "winning_feedback_category", "gain",
         "taxe_efficace", "taxe_cible_approbation", "gagnant_cible_categorie")
ctrl <- ctrl[!sapply(ctrl, function(t) any(all.vars(str2lang(t)) %in% bad))]
cat("controls:", paste(ctrl, collapse = " + "), "\n")
cstr <- if (length(ctrl)) paste("+", paste(ctrl, collapse = " + ")) else ""

fit <- function(f, d) feols(as.formula(f), data = d, weights = ~w_, vcov = "hetero", warn = FALSE, notes = FALSE)
gc <- function(m, v) { cf <- coef(m); if (v %in% names(cf)) unname(cf[v]) else NA }

d_fb <- s[s$has_fb & !is.na(s$sg), ]
d1 <- d_fb[abs(d_fb$sg) < 50, ]
cat("feedback n:", nrow(d_fb), " |gain|<50 n:", nrow(d1), "\n")

base_rhs <- paste("pwin + acc0 + nsp0 + sg + sg2", cstr)

# Col 1
tryCatch({
  m1 <- fit(paste("y_notlose ~", base_rhs), d1)
  print(coeftable(m1)[1:5, ])
  emit("predicted_winner_believes_not_lose_table4_col1", gc(m1, "pwin"))
  emit("initial_acceptance_believes_not_lose_table4_col1", gc(m1, "acc0"))
  emit("n_obs_table4_col1", nobs(m1))
}, error = function(e) cat("col1 error:", conditionMessage(e), "\n"))

# Col 2
tryCatch({
  m2 <- fit(paste("y_notlose ~", base_rhs), d_fb)
  emit("predicted_winner_believes_not_lose_full_sample_table4_col2", gc(m2, "pwin"))
}, error = function(e) cat("col2 error:", conditionMessage(e), "\n"))

# Col 3
tryCatch({
  d1$pw_acc <- d1$pwin * d1$acc0
  d1$pw_yv <- d1$pwin * d1$yv
  d1$pw_G <- d1$pwin * d1$G
  m3 <- fit(paste("y_notlose ~ pwin + acc0 + yv + G + pw_acc + pw_yv + pw_G + G_win + nsp0 + sg + sg2", cstr), d1)
  print(coeftable(m3)[1:8, ])
  emit("predicted_winner_heterogeneity_table4_col3", gc(m3, "pwin"))
  emit("initial_acceptance_heterogeneity_table4_col3", gc(m3, "acc0"))
  emit("yellow_vests_supporter_heterogeneity_table4_col3", gc(m3, "yv"))
  emit("winner_x_initial_acceptance_table4_col3", gc(m3, "pw_acc"))
  emit("winner_x_yellow_vests_supporter_table4_col3", gc(m3, "pw_yv"))
  emit("winner_x_initial_win_belief_table4_col3", gc(m3, "pw_G"))
}, error = function(e) cat("col3 error:", conditionMessage(e), "\n"))

# Col 4
tryCatch({
  m4 <- fit(paste("y_win ~", base_rhs), d1)
  emit("predicted_winner_believes_wins_table4_col4", gc(m4, "pwin"))
}, error = function(e) cat("col4 error:", conditionMessage(e), "\n"))

# ---------------- Table 6: targeted dividend IV ----------------
tryCatch({
  ta <- pick(c("taxe_cible_approbation", "targeted_tax_approval"))
  gb <- pick(c("gagnant_cible_categorie", "winning_targeted_category"))
  cat("targeted vars:", ta, gb, "\n")
  s$acc_t <- 1 - is_no(s[[ta]])
  s$nl_t <- 1 - is_loser(s[[gb]])
  cib <- pick(c("cible", "target_percentile"))
  s$cible_f <- if (!is.na(cib)) as.character(s[[cib]]) else "x"
  tr1 <- pick(c("traite_cible", "treated_targeted"))
  tr2 <- pick(c("traite_cible_conjoint", "treated_targeted_spouse"))
  thr <- c("20" = 780, "30" = 1140, "40" = 1430, "50" = 1670)
  cnum <- suppressWarnings(as.numeric(gsub("[^0-9]", "", s$cible_f)))
  thv <- thr[as.character(cnum)]
  if (!is.na(tr1)) s$t1 <- to01(s[[tr1]]) else s$t1 <- as.numeric(as.numeric(s$revenu) < thv)
  if (!is.na(tr2)) s$t2 <- to01(s[[tr2]]) else {
    rc <- pick(c("revenu_conjoint"))
    s$t2 <- if (!is.na(rc)) as.numeric(as.numeric(s[[rc]]) < thv) else 0
  }
  s$t2[is.na(s$t2)] <- 0
  s$t12 <- s$t1 * s$t2
  pr <- pick(c("percentile_revenu")); prc <- pick(c("percentile_revenu_conjoint"))
  d6 <- s[!is.na(s$acc_t) & !is.na(s$nl_t) & !is.na(s$t1), ]
  if (!is.na(pr)) {
    p1 <- as.numeric(d6[[pr]]); p2 <- if (!is.na(prc)) as.numeric(d6[[prc]]) else rep(NA, nrow(d6))
    keep <- (p1 <= 60 & p1 >= 10) | (!is.na(p2) & p2 <= 60 & p2 >= 10)
    keep[is.na(keep)] <- FALSE
    d6 <- d6[keep, ]
  }
  extra <- valid_terms(c(pr, prc))
  rhs6 <- paste("factor(cible_f) + single + acc0 + nsp0", if (length(extra)) paste("+", paste(extra, collapse = " + ")) else "", cstr)
  m6 <- feols(as.formula(paste("acc_t ~", rhs6, "| nl_t ~ t1 + t2 + t12")), data = d6,
              weights = ~w_, vcov = "hetero", warn = FALSE, notes = FALSE)
  cat("Table6 n:", nobs(m6), "\n")
  emit("believes_not_lose_on_acceptance_iv_table6_col1", gc(m6, "fit_nl_t"))
}, error = function(e) cat("table6 error:", conditionMessage(e), "\n"))

# ---------------- Table 8: effectiveness IV ----------------
tryCatch({
  te <- pick(c("taxe_efficace", "tax_effective"))
  s$eff <- is_yes(s[[te]])
  am <- pick(c("apres_modifs", "info_scientists", "info_efficacite"))
  ic <- pick(c("info_CC", "info_cc"))
  s$z1 <- to01(s[[am]])
  s$z2 <- if (!is.na(ic)) to01(s[[ic]]) else 0
  d8 <- s[!is.na(s$appr0) & !is.na(s$eff), ]
  m8 <- feols(as.formula(paste("appr0 ~ sg + sg2", cstr, "| eff ~ z1 + z2")), data = d8,
              weights = ~w_, vcov = "hetero", warn = FALSE, notes = FALSE)
  cat("Table8 n:", nobs(m8), "\n")
  emit("believes_effective_on_approval_iv_table8_col1", gc(m8, "fit_eff"))
}, error = function(e) cat("table8 error:", conditionMessage(e), "\n"))
