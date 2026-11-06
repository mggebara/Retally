suppressPackageStartupMessages({
  library(fixest)
})
set.seed(42)

root <- '<repo>/.cache/datasets/douenne_2022_yellow_vests_carbon_tax.script-free'
rdata <- file.path(root, 'yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData')
load(rdata)
d <- as.data.frame(s)

# ---- convert memisc (S4) item columns to plain R vectors without needing memisc ----
# Any class-based operation (is.factor, inherits, as.vector, `[`) on these S4 objects
# triggers S4 dispatch, which tries to load the missing 'memisc' package.
# .subset() / attr() are non-dispatching, so use them to extract raw values and labels.
get_vl <- function(x) {
  vl <- tryCatch(attr(x, "value.labels", exact = TRUE), error = function(e) NULL)
  if (is.null(vl)) return(NULL)
  vals <- tryCatch(as.numeric(.subset(vl, TRUE)), error = function(e) NULL)
  labs <- tryCatch(as.character(attr(vl, "labels", exact = TRUE)), error = function(e) NULL)
  if (length(vals) && length(labs) == length(vals)) return(list(vals = vals, labs = labs))
  NULL
}
unS4 <- function(x, use_labels = FALSE) {
  if (!isS4(x)) return(x)
  vl <- get_vl(x)
  y <- .subset(x, TRUE)
  names(y) <- NULL
  if (use_labels && !is.null(vl) && is.numeric(y)) {
    ok <- y[!is.na(y)]
    if (length(ok) && all(ok %in% vl$vals)) y <- vl$labs[match(y, vl$vals)]
  }
  y
}
label_vars <- c("tax_acceptance", "taxe_acceptation", "winning_category", "winning_feedback_category",
                "variante_progressivite", "variant_progressivity", "variante_feedback",
                "tax_cible_acceptance", "win_cible_category", "taxe_efficace", "tax_effective", "effective",
                "tax_approval", "taxe_approbation", "gilets_jaunes", "yellow_vests",
                "sexe", "age", "diplome4", "statut_emploi", "csp", "region", "taille_agglo")
label_store <- list()
for (v in names(d)) {
  col <- .subset2(d, v)
  if (isS4(col)) {
    vlx <- tryCatch(get_vl(col), error = function(e) NULL)
    if (!is.null(vlx)) label_store[[v]] <- vlx
    newcol <- tryCatch(unS4(col, use_labels = v %in% label_vars), error = function(e) {
      message("Could not convert column ", v, ": ", conditionMessage(e)); NULL
    })
    if (is.null(newcol)) newcol <- rep(NA, nrow(d))
    d[[v]] <- newcol
  }
}
nm <- names(d)

pick <- function(cands) { for (x in cands) if (x %in% nm) return(x); NA_character_ }
pickre <- function(re) { h <- grep(re, nm, value = TRUE); if (length(h)) h[1] else NA_character_ }
strip <- function(x) {
  if (isS4(x)) x <- unS4(x)
  if (is.factor(x)) x <- as.character(x)
  x <- as.vector(x)
  x
}
# relaxed relabelling: map numeric codes to labels where a label exists
relabel <- function(v) {
  x <- strip(d[[v]])
  vl <- label_store[[v]]
  if (is.null(vl) || !is.numeric(x)) return(x)
  lab <- vl$labs[match(x, vl$vals)]
  out <- ifelse(is.na(lab), as.character(x), lab)
  out[is.na(x)] <- NA
  out
}
has_var <- function(x) length(unique(x[!is.na(x)])) >= 2

to_yes <- function(x) {
  x <- strip(x)
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x > 0))
  y <- tolower(trimws(as.character(x)))
  out <- as.numeric(grepl("^(oui|yes|true|1)", y))
  out[is.na(y) | y == ""] <- NA
  out
}
to_bool <- function(x) {
  x <- strip(x)
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x > 0))
  y <- tolower(trimws(as.character(x)))
  out <- rep(NA_real_, length(y))
  out[grepl("^(true|t|oui|yes|1)$", y)] <- 1
  out[grepl("^(false|f|non|no|0)$", y)] <- 0
  num <- suppressWarnings(as.numeric(y))
  out[is.na(out) & !is.na(num)] <- as.numeric(num[is.na(out) & !is.na(num)] > 0)
  out
}
to_notno <- function(x) {
  x <- strip(x)
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) {
    if (isTRUE(min(x, na.rm = TRUE) < 0)) return(as.numeric(x >= 0))
    return(as.numeric(x > 0))
  }
  y <- tolower(trimws(as.character(x)))
  out <- as.numeric(!grepl("^(non|no)$", y))
  out[is.na(y) | y == ""] <- NA
  out
}
is_lose <- function(x) {
  x <- strip(x)
  if (is.numeric(x)) return(as.numeric(x < 0))
  y <- tolower(as.character(x))
  out <- as.numeric(grepl("perd|los", y))
  out[is.na(y) | y == ""] <- NA
  out
}
is_win <- function(x) {
  x <- strip(x)
  if (is.numeric(x)) return(as.numeric(x > 0))
  y <- tolower(as.character(x))
  out <- as.numeric(grepl("gagn|win", y) & !grepl("perd|los", y))
  out[is.na(y) | y == ""] <- NA
  out
}

safe_coef <- function(m, name) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (name %in% names(cf)) return(unname(cf[name]))
  hit <- grep(name, names(cf), fixed = TRUE, value = TRUE)
  if (length(hit)) return(unname(cf[hit[1]]))
  NA_real_
}

# ---------------- core variables ----------------
gvar <- pick(c("simule_gain", "simulated_gain", "estimated_gain", "gain_simule"))
if (is.na(gvar)) gvar <- pickre("^simule_gain$|^simule_gain")
if (is.na(gvar)) stop(paste("No estimated gain variable; candidates:", paste(grep("gain", nm, value = TRUE), collapse = ",")))
d$gain_est <- as.numeric(strip(d[[gvar]]))
d$winner <- as.numeric(d$gain_est > 0)

wvar <- pick(c("weight", "weights", "poids"))
d$w <- if (!is.na(wvar)) as.numeric(strip(d[[wvar]])) else 1
d$w[is.na(d$w)] <- 1

d$init_accept <- to_notno(d[[pick(c("tax_acceptance", "taxe_acceptation"))]])
d$init_notlose <- 1 - is_lose(d[["winning_category"]])
if (!has_var(d$init_notlose) && "winning_category" %in% nm) d$init_notlose <- 1 - is_lose(relabel("winning_category"))
d$init_cat <- factor(strip(d[["winning_category"]]))
fbcat <- d[["winning_feedback_category"]]
d$after_notlose <- 1 - is_lose(fbcat)
d$after_win <- is_win(fbcat)

# Yellow vests supporter (robust to logical / character "TRUE"/"FALSE" storage)
gj_in <- pick(c("gilets_jaunes_dedans", "yellow_vests_part"))
gj_sup <- pick(c("gilets_jaunes_soutien", "yellow_vests_support"))
yv <- rep(NA_real_, nrow(d))
if (!is.na(gj_in) && !is.na(gj_sup)) {
  a <- to_bool(d[[gj_in]]); b <- to_bool(d[[gj_sup]])
  yv <- as.numeric((a %in% 1) | (b %in% 1))
  yv[is.na(a) & is.na(b)] <- NA
}
if (!has_var(yv)) {
  gj <- pick(c("gilets_jaunes", "yellow_vests"))
  if (!is.na(gj)) {
    x <- strip(d[[gj]])
    if (is.numeric(x)) {
      x2 <- relabel(gj)
      if (is.character(x2) && has_var(as.numeric(grepl("soutien|dedans|support|part", tolower(x2))))) {
        yv <- as.numeric(grepl("soutien|dedans|support|part", tolower(x2)))
      } else yv <- as.numeric(x > 0)
    } else {
      yv <- as.numeric(grepl("soutien|dedans|support|part", tolower(as.character(x))))
    }
  }
}
d$yv_supporter <- yv
message("yv_supporter table: ", paste(capture.output(print(table(d$yv_supporter, useNA = "ifany"))), collapse = " "))

# feedback received
received <- !is.na(strip(fbcat)) & as.character(strip(fbcat)) != ""
vp <- pick(c("variante_progressivite", "variant_progressivity", "variante_feedback"))
if (!is.na(vp)) {
  vpx <- tolower(as.character(strip(d[[vp]])))
  if (any(grepl("fb", vpx, fixed = TRUE), na.rm = TRUE)) {
    received <- received & grepl("fb", vpx, fixed = TRUE)
  } else {
    received <- received & !(vpx %in% c("prog"))
  }
}
received[is.na(received)] <- FALSE

# ---------------- controls ----------------
socio_cands <- c("sexe", "age", "diplome4", "statut_emploi", "csp", "region", "taille_agglo")
income_cands <- c("revenu", "rev_tot")
prep_controls <- function(df, cands) {
  keep <- c()
  for (v in cands) {
    if (!(v %in% names(df))) next
    x <- strip(df[[v]])
    if (mean(is.na(x)) > 0.05) next
    if (length(unique(x[!is.na(x)])) < 2) next
    keep <- c(keep, v)
  }
  keep
}
for (v in c(socio_cands, income_cands)) {
  if (v %in% nm) {
    x <- strip(d[[v]])
    if (is.character(x) || is.logical(x)) d[[v]] <- factor(x) else d[[v]] <- x
  }
}

fit_ols <- function(f, df) {
  tryCatch(feols(f, data = df, weights = ~w, vcov = "iid"), error = function(e) { message(conditionMessage(e)); NULL })
}

# ---------------- Table 4 ----------------
cat(sprintf("SAMPLE:t4_col1:loaded=%d\n", nrow(d)))
d4 <- d[received, ]
cat(sprintf("SAMPLE:t4_col1:received_feedback=%d\n", nrow(d4)))
d41 <- d4[!is.na(d4$gain_est) & abs(d4$gain_est) < 50, ]
cat(sprintf("SAMPLE:t4_col1:abs_gain_lt_50=%d\n", nrow(d41)))

ctrl41 <- prep_controls(d41, c(socio_cands, income_cands))
rhs_base <- c("winner", "init_accept", "gain_est", "I(gain_est^2)", ctrl41)
f1 <- as.formula(paste("after_notlose ~", paste(rhs_base, collapse = " + ")))
m1 <- fit_ols(f1, d41)
cat(sprintf("SAMPLE:t4_col1:estimation=%d\n", if (is.null(m1)) 0L else nobs(m1)))

# col 2 full feedback sample
cat(sprintf("SAMPLE:t4_col2:loaded=%d\n", nrow(d)))
cat(sprintf("SAMPLE:t4_col2:received_feedback=%d\n", nrow(d4)))
ctrl4 <- prep_controls(d4, c(socio_cands, income_cands))
f2 <- as.formula(paste("after_notlose ~", paste(c("winner", "init_accept", "gain_est", "I(gain_est^2)", ctrl4), collapse = " + ")))
m2 <- fit_ols(f2, d4)
cat(sprintf("SAMPLE:t4_col2:estimation=%d\n", if (is.null(m2)) 0L else nobs(m2)))

# col 3 heterogeneity
cat(sprintf("SAMPLE:t4_col3:loaded=%d\n", nrow(d)))
cat(sprintf("SAMPLE:t4_col3:received_feedback=%d\n", nrow(d4)))
cat(sprintf("SAMPLE:t4_col3:abs_gain_lt_50=%d\n", nrow(d41)))
d41$w_x_acc <- d41$winner * d41$init_accept
d41$w_x_yv <- d41$winner * d41$yv_supporter
d41$w_x_G <- d41$winner * d41$init_notlose
rhs3 <- c("winner", "init_accept", "yv_supporter", "init_notlose",
          "w_x_acc", "w_x_yv", "w_x_G", "gain_est", "I(gain_est^2)", "init_cat", ctrl41)
for (v in c("yv_supporter", "init_notlose", "init_cat")) {
  message("T4c3 NA share ", v, ": ", mean(is.na(d41[[v]])))
}
# init_cat is only a control: drop it if it is entirely missing / constant
if (all(is.na(d41$init_cat)) || length(unique(na.omit(as.character(d41$init_cat)))) < 2) rhs3 <- setdiff(rhs3, "init_cat")
f3 <- as.formula(paste("after_notlose ~", paste(rhs3, collapse = " + ")))
m3 <- fit_ols(f3, d41)
if (!is.null(m3)) message("T4c3 coef names: ", paste(names(coef(m3)), collapse = ", "))
cat(sprintf("SAMPLE:t4_col3:estimation=%d\n", if (is.null(m3)) 0L else nobs(m3)))

# col 4 believes wins
cat(sprintf("SAMPLE:t4_col4:loaded=%d\n", nrow(d)))
cat(sprintf("SAMPLE:t4_col4:received_feedback=%d\n", nrow(d4)))
cat(sprintf("SAMPLE:t4_col4:abs_gain_lt_50=%d\n", nrow(d41)))
f4 <- as.formula(paste("after_win ~", paste(rhs_base, collapse = " + ")))
m4 <- fit_ols(f4, d41)
cat(sprintf("SAMPLE:t4_col4:estimation=%d\n", if (is.null(m4)) 0L else nobs(m4)))

# ---------------- Table 6: targeted dividend IV ----------------
m6 <- NULL
tryCatch({
  cible_v <- pick(c("cible", "target_threshold", "variante_cible"))
  d$cible_num <- as.numeric(gsub("[^0-9.]", "", as.character(strip(d[[cible_v]]))))
  pr <- suppressWarnings(as.numeric(strip(d[["percentile_revenu"]])))
  prc <- suppressWarnings(as.numeric(strip(d[["percentile_revenu_conjoint"]])))
  tc <- pick(c("traite_cible", "eligible", "treated_target"))
  tcc <- pick(c("traite_cible_conjoint", "eligible_conjoint"))
  d$elig <- if (!is.na(tc)) to_bool(d[[tc]]) else as.numeric(pr <= d$cible_num)
  d$elig_c <- if (!is.na(tcc)) to_bool(d[[tcc]]) else as.numeric(!is.na(prc) & prc <= d$cible_num)
  d$elig_c[is.na(d$elig_c)] <- 0
  d$elig_x <- d$elig * d$elig_c
  d$pr <- pr
  d$prc <- ifelse(is.na(prc), 0, prc)
  d$single01 <- to_bool(d[[pick(c("single", "seul"))]])

  # acceptance of targeted reform: first candidate with variation
  acc_c <- unique(c(intersect(c("tax_cible_acceptance", "taxe_cible_acceptation"), nm),
                    grep("cible.*(accept|approb)|(accept|approb).*cible", nm, value = TRUE)))
  d$accept_cible <- NA_real_
  for (v in acc_c) {
    a <- to_notno(d[[v]])
    if (!has_var(a)) a <- to_notno(relabel(v))
    if (has_var(a)) { d$accept_cible <- a; message("T6 acceptance var: ", v); break }
  }
  # believes does not lose under targeted reform: first candidate with variation
  nl_c <- unique(c(intersect(c("win_cible_category", "gagnant_cible_categorie", "winning_cible_category"), nm),
                   grep("cible.*(categ|gagn|win)|(categ|gagn|win).*cible", nm, value = TRUE)))
  nl_c <- setdiff(nl_c, acc_c)
  d$notlose_cible <- NA_real_
  for (v in nl_c) {
    message("T6 candidate ", v, " values: ", paste(head(unique(strip(d[[v]])), 10), collapse = "|"))
    nl <- 1 - is_lose(d[[v]])
    if (!has_var(nl)) nl <- 1 - is_lose(relabel(v))
    if (!has_var(nl)) {
      x <- strip(d[[v]])
      if (is.numeric(x) && has_var(x)) {
        # numeric codes without negative values: lowest code = loser
        nl <- as.numeric(x > min(x, na.rm = TRUE))
      }
    }
    if (has_var(nl)) { d$notlose_cible <- nl; message("T6 not-lose var: ", v); break }
  }
  d$cible_f <- factor(d$cible_num)
  cat(sprintf("SAMPLE:t6_col1:loaded=%d\n", nrow(d)))
  d6 <- d[!is.na(d$notlose_cible) & !is.na(d$accept_cible) & !is.na(d$cible_num), ]
  cat(sprintf("SAMPLE:t6_col1:targeted_variant_answered=%d\n", nrow(d6)))
  f6 <- as.formula("accept_cible ~ single01 + init_accept + pr + I(pr^2) + prc + I(prc^2) | cible_f | notlose_cible ~ elig + elig_c + elig_x")
  m6 <- feols(f6, data = d6, weights = ~w, vcov = "iid")
  message("T6 coef names: ", paste(names(coef(m6)), collapse = ", "))
  cat(sprintf("SAMPLE:t6_col1:estimation=%d\n", nobs(m6)))
}, error = function(e) { message("T6: ", conditionMessage(e)); cat("SAMPLE:t6_col1:estimation=0\n") })

# ---------------- Table 8: effectiveness IV ----------------
m8 <- NULL
tryCatch({
  eff <- pick(c("taxe_efficace", "tax_effective", "effective"))
  d$believes_eff <- to_yes(d[[eff]])
  d$approve <- to_yes(d[[pick(c("tax_approval", "taxe_approbation"))]])
  ie <- pick(c("apres_modifs", "info_efficacite", "info_effectiveness"))
  ic <- pick(c("info_CC", "info_cc", "info_climate"))
  d$z_eff <- as.numeric(as.logical(strip(d[[ie]])) | as.numeric(strip(d[[ie]])) > 0)
  icx <- strip(d[[ic]])
  d$z_cc <- if (is.numeric(icx) || is.logical(icx)) as.numeric(icx) else as.numeric(grepl("^(true|1|oui|yes)", tolower(icx)))
  cat(sprintf("SAMPLE:t8_col1:loaded=%d\n", nrow(d)))
  ctrl8 <- prep_controls(d, c(socio_cands, income_cands))
  f8 <- as.formula(paste("approve ~", paste(c("gain_est", ctrl8), collapse = " + "), "| believes_eff ~ z_eff + z_cc"))
  m8 <- feols(f8, data = d, weights = ~w, vcov = "iid")
  cat(sprintf("SAMPLE:t8_col1:estimation=%d\n", nobs(m8)))
}, error = function(e) { message("T8: ", conditionMessage(e)); cat("SAMPLE:t8_col1:estimation=0\n") })

# ---------------- results ----------------
cat(sprintf("RESULT:predicted_winner_believes_not_lose_table4_col1=%.6f\n", safe_coef(m1, "winner")))
cat(sprintf("RESULT:initial_acceptance_believes_not_lose_table4_col1=%.6f\n", safe_coef(m1, "init_accept")))
cat(sprintf("RESULT:predicted_winner_believes_not_lose_full_sample_table4_col2=%.6f\n", safe_coef(m2, "winner")))
cat(sprintf("RESULT:predicted_winner_heterogeneity_table4_col3=%.6f\n", safe_coef(m3, "winner")))
cat(sprintf("RESULT:initial_acceptance_heterogeneity_table4_col3=%.6f\n", safe_coef(m3, "init_accept")))
cat(sprintf("RESULT:yellow_vests_supporter_heterogeneity_table4_col3=%.6f\n", safe_coef(m3, "yv_supporter")))
cat(sprintf("RESULT:winner_x_initial_acceptance_table4_col3=%.6f\n", safe_coef(m3, "w_x_acc")))
cat(sprintf("RESULT:winner_x_yellow_vests_supporter_table4_col3=%.6f\n", safe_coef(m3, "w_x_yv")))
cat(sprintf("RESULT:winner_x_initial_win_belief_table4_col3=%.6f\n", safe_coef(m3, "w_x_G")))
cat(sprintf("RESULT:predicted_winner_believes_wins_table4_col4=%.6f\n", safe_coef(m4, "winner")))
cat(sprintf("RESULT:n_obs_table4_col1=%d\n", if (is.null(m1)) 0L else nobs(m1)))
cat(sprintf("RESULT:believes_not_lose_on_acceptance_iv_table6_col1=%.6f\n", safe_coef(m6, "fit_notlose_cible")))
cat(sprintf("RESULT:believes_effective_on_approval_iv_table8_col1=%.6f\n", safe_coef(m8, "fit_believes_eff")))
