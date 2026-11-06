suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- '<repo>/.cache/datasets/douenne_2022_yellow_vests_carbon_tax.script-free'
rdata <- file.path(base, 'yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData')
load(rdata)
df <- as.data.frame(s)

# ---------------- strip memisc (S4) classes, which cannot be resolved without the memisc package ----------------
strip_col <- function(v) {
  s4 <- isS4(v)
  cls <- tryCatch(class(v), error = function(e) 'unknown')
  pkg <- attr(cls, 'package')
  memisc_like <- any(cls %in% c('item', 'integer.item', 'double.item', 'character.item', 'data.set',
                                'value.labels', 'unknown')) ||
    !is.null(attr(v, 'value.labels')) || !is.null(attr(v, 'measurement')) || !is.null(attr(v, 'annotation'))
  if (!s4 && is.null(pkg) && !memisc_like) return(v)
  labs <- NULL
  vl <- attr(v, 'value.labels')
  if (!is.null(vl)) {
    vals <- attr(vl, 'values')
    nmv <- vl
    attributes(nmv) <- NULL
    if (isS4(nmv)) nmv <- tryCatch(asS4(nmv, FALSE, FALSE), error = function(e) nmv)
    if (!is.null(vals) && length(vals) == length(nmv)) {
      attributes(vals) <- NULL
      labs <- vals
      names(labs) <- as.character(nmv)
    }
  }
  if (is.null(labs)) {
    lb2 <- attr(v, 'labels')
    if (!is.null(lb2)) labs <- lb2
  }
  lev <- attr(v, 'levels')
  attributes(v) <- NULL
  if (isS4(v)) v <- tryCatch(asS4(v, FALSE, FALSE), error = function(e) v)
  if (!is.null(lev) && is.numeric(v)) {
    v <- factor(lev[v], levels = lev)
  } else if (!is.null(labs) && is.numeric(v) && is.numeric(labs)) {
    attr(v, 'labels') <- labs
  }
  v
}
for (nm in names(df)) df[[nm]] <- strip_col(df[[nm]])

cat(sprintf('SAMPLE:all:loaded=%d\n', nrow(df)))

# ---------------- helpers ----------------
pick <- function(d, cands) {
  for (cc in cands) if (cc %in% names(d)) return(cc)
  NA_character_
}
lab_chr <- function(x) {
  if (is.factor(x)) return(as.character(x))
  if (inherits(x, 'labelled') || !is.null(attr(x, 'labels'))) {
    lb <- attr(x, 'labels')
    if (!is.null(lb) && is.numeric(x)) {
      out <- names(lb)[match(as.numeric(x), as.numeric(lb))]
      out[is.na(out)] <- as.character(x[is.na(out)])
      return(out)
    }
  }
  as.character(x)
}
num_or_na <- function(x) suppressWarnings(as.numeric(as.character(x)))
is_yes <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  n <- num_or_na(x)
  if (is.numeric(x) && !is.factor(x)) return(ifelse(is.na(x), NA, as.numeric(x > 0)))
  ch <- tolower(trimws(lab_chr(x)))
  out <- ifelse(is.na(ch) | ch == '' | ch == 'na', NA,
                as.numeric(ch %in% c('oui', 'yes', 'true', '1')))
  if (all(is.na(out) | out == 0) && sum(!is.na(n)) > 0) out <- ifelse(is.na(n), NA, as.numeric(n > 0))
  out
}
is_not_no <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x) && !is.factor(x)) return(ifelse(is.na(x), NA, as.numeric(x >= 0)))
  ch <- tolower(trimws(lab_chr(x)))
  ifelse(is.na(ch) | ch == '' | ch == 'na', NA, as.numeric(!(ch %in% c('non', 'no', 'false', '-1'))))
}
not_lose <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x) && !is.factor(x)) return(ifelse(is.na(x), NA, as.numeric(x >= 0)))
  ch <- tolower(trimws(lab_chr(x)))
  ifelse(is.na(ch) | ch == '' | ch == 'na', NA,
         as.numeric(!grepl('perdant|lose|loser|^-1$', ch)))
}
wins <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x) && !is.factor(x)) return(ifelse(is.na(x), NA, as.numeric(x > 0)))
  ch <- tolower(trimws(lab_chr(x)))
  ifelse(is.na(ch) | ch == '' | ch == 'na', NA,
         as.numeric(grepl('gagnant|win|^1$', ch) & !grepl('perdant|lose|non', ch)))
}
# robust binary conversion: keeps 0/1 numerics, maps logical, yes/no strings, TRUE/FALSE strings
to_binary <- function(x) {
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x) && !is.factor(x)) {
    u <- unique(x[!is.na(x)])
    if (all(u %in% c(0, 1))) return(as.numeric(x))
    return(ifelse(is.na(x), NA, as.numeric(x > 0)))
  }
  ch <- tolower(trimws(lab_chr(x)))
  out <- rep(NA_real_, length(ch))
  out[ch %in% c('true', 'oui', 'yes', '1', 't')] <- 1
  out[ch %in% c('false', 'non', 'no', '0', 'f')] <- 0
  out
}
nvar <- function(v) length(unique(v[!is.na(v)]))
present_controls <- function(d, cands) {
  out <- c()
  for (cc in cands) {
    if (!(cc %in% names(d))) next
    v <- d[[cc]]
    if (length(unique(v[!is.na(v)])) < 2) next
    if (mean(is.na(v)) > 0.2) next
    out <- c(out, cc)
  }
  unique(out)
}
prep_controls <- function(d, ctrls) {
  for (cc in ctrls) {
    v <- d[[cc]]
    if (is.character(v) || is.factor(v) || !is.null(attr(v, 'labels'))) {
      if (!is.null(attr(v, 'labels')) && is.numeric(v) && length(unique(v)) > 12) {
        d[[cc]] <- as.numeric(v)
      } else {
        d[[cc]] <- factor(lab_chr(v))
      }
    } else if (is.logical(v)) {
      d[[cc]] <- as.numeric(v)
    } else {
      d[[cc]] <- as.numeric(v)
    }
  }
  d
}
bq <- function(v) paste0('`', v, '`')
getcoef <- function(m, nm) {
  if (is.null(m)) return(NA)
  cf <- coef(m)
  if (nm %in% names(cf)) return(unname(cf[nm]))
  hit <- grep(nm, names(cf), fixed = TRUE)
  if (length(hit) > 0) return(unname(cf[hit[1]]))
  NA
}
emit <- function(name, val) cat(sprintf('RESULT:%s=%s\n', name, ifelse(is.na(val), 'NA', format(round(val, 6), scientific = FALSE))))

# ---------------- weights ----------------
wvar <- pick(df, c('weight', 'weight_s', 'poids'))
if (is.na(wvar)) { df$w__ <- 1 } else { df$w__ <- as.numeric(df[[wvar]]); df$w__[is.na(df$w__)] <- 1 }

# ---------------- key variables ----------------
gain_var <- pick(df, c('simule_gain', 'gain', 'simule_gain_menage'))
cat(sprintf('NOTE:estimated_gain_var=%s\n', gain_var))
df$gain_hat <- as.numeric(df[[gain_var]])
pw_var <- pick(df, c('simule_gagnant'))
df$pred_winner <- NA_real_
if (!is.na(pw_var)) {
  cat(sprintf('NOTE:simule_gagnant class=%s values=%s\n', paste(class(df[[pw_var]]), collapse = '/'),
              paste(head(unique(lab_chr(df[[pw_var]])), 6), collapse = '|')))
  df$pred_winner <- to_binary(df[[pw_var]])
}
if (nvar(df$pred_winner) < 2) {
  cat('DEVIATION: simule_gagnant did not convert to a varying 0/1 indicator; predicted winner defined as simule_gain > 0\n')
  df$pred_winner <- as.numeric(df$gain_hat > 0)
}
cat(sprintf('NOTE:pred_winner mean=%.4f\n', mean(df$pred_winner, na.rm = TRUE)))
df$gain_hat2 <- df$gain_hat^2

# initial belief (G) and post-feedback belief
init_belief_var <- pick(df, c('gagnant_categorie', 'winning_category'))
fb_belief_var <- pick(df, c('gagnant_feedback_categorie', 'winning_feedback_category'))
cat(sprintf('NOTE:initial_belief_var=%s; feedback_belief_var=%s\n', init_belief_var, fb_belief_var))
df$G_init <- not_lose(df[[init_belief_var]])
df$fb_not_lose <- not_lose(df[[fb_belief_var]])
df$fb_wins <- wins(df[[fb_belief_var]])
df$init_cat <- factor(lab_chr(df[[init_belief_var]]))

# initial acceptance (not "No") and approval ("Yes")
acc_var <- pick(df, c('tax_acceptance', 'taxe_acceptation'))
app_var <- pick(df, c('tax_approval', 'taxe_approbation'))
df$init_accept <- is_not_no(df[[acc_var]])
df$init_approve <- is_yes(df[[app_var]])

# Yellow Vests supporter
gj_var <- pick(df, c('gilets_jaunes'))
if ('gilets_jaunes_soutient' %in% names(df) || 'gilets_jaunes_dedans' %in% names(df)) {
  a <- if ('gilets_jaunes_soutient' %in% names(df)) as.logical(df$gilets_jaunes_soutient) %in% TRUE else FALSE
  b <- if ('gilets_jaunes_dedans' %in% names(df)) as.logical(df$gilets_jaunes_dedans) %in% TRUE else FALSE
  df$yv_support <- as.numeric(a | b)
} else if (!is.na(gj_var)) {
  v <- df[[gj_var]]
  if (is.numeric(v) && is.null(attr(v, 'labels'))) df$yv_support <- as.numeric(v >= 1)
  else df$yv_support <- as.numeric(grepl('soutien|dedans|support|part', tolower(lab_chr(v))))
} else df$yv_support <- NA

# ---------------- controls ----------------
income_ctrl <- present_controls(df, c('revenu', 'rev_tot', 'Revenu', 'Revenu_conjoint', 'Revenu2', 'Revenu_conjoint2'))
demo_ctrl <- present_controls(df, c('sexe', 'age', 'statut_emploi', 'csp', 'diplome', 'taille_agglo', 'region',
                                    'taille_menage', 'nb_14_et_plus', 'nb_adultes', 'surface', 'chauffage', 'fuel_1'))
motive_ctrl <- present_controls(df, c('taxe_efficace', 'progressivite', 'Gauche_droite', 'interet_politique',
                                      'ecologiste', 'conservateur', 'liberal', 'humaniste', 'patriote', 'apolitique'))
df <- prep_controls(df, c(income_ctrl, demo_ctrl, motive_ctrl))
ctrl_all <- c(income_ctrl, demo_ctrl, motive_ctrl)
cat(sprintf('NOTE:controls=%s\n', paste(ctrl_all, collapse = ',')))

# ---------------- Table 4 samples ----------------
fb <- df[!is.na(df$fb_not_lose), ]
cat(sprintf('SAMPLE:table4_col2:loaded=%d\n', nrow(df)))
cat(sprintf('SAMPLE:table4_col2:received_feedback=%d\n', nrow(fb)))
if (nrow(fb) != 1968) cat(sprintf('DEVIATION: feedback sample has %d rows vs 1968 stated in paper\n', nrow(fb)))
fb50 <- fb[!is.na(fb$gain_hat) & abs(fb$gain_hat) < 50, ]
cat(sprintf('SAMPLE:table4_col1:loaded=%d\n', nrow(df)))
cat(sprintf('SAMPLE:table4_col1:received_feedback=%d\n', nrow(fb)))
cat(sprintf('SAMPLE:table4_col1:abs_gain_below_50=%d\n', nrow(fb50)))

rhs_base <- c('pred_winner', 'init_accept', 'gain_hat', 'gain_hat2', bq(ctrl_all))
fit_lm <- function(lhs, rhs, data) {
  f <- as.formula(paste(lhs, '~', paste(rhs, collapse = ' + ')))
  tryCatch(feols(f, data = data, weights = ~w__, vcov = 'hetero'),
           error = function(e) { cat('NOTE:error ', conditionMessage(e), '\n'); NULL })
}
m1 <- fit_lm('fb_not_lose', rhs_base, fb50)
m2 <- fit_lm('fb_not_lose', rhs_base, fb)
rhs3 <- c('pred_winner', 'init_accept', 'yv_support', 'G_init',
          'pred_winner:init_accept', 'pred_winner:yv_support', 'pred_winner:G_init',
          'gain_hat', 'gain_hat2', bq(ctrl_all))
m3 <- fit_lm('fb_not_lose', rhs3, fb50)
m4 <- fit_lm('fb_wins', rhs_base, fb50)
if (!is.null(m3)) cat(sprintf('NOTE:m3 coefs=%s\n', paste(head(names(coef(m3)), 12), collapse = ',')))
if (!is.null(m1)) cat(sprintf('SAMPLE:table4_col1:estimation=%d\n', nobs(m1)))
if (!is.null(m2)) cat(sprintf('SAMPLE:table4_col2:estimation=%d\n', nobs(m2)))
cat(sprintf('SAMPLE:table4_col3:loaded=%d\nSAMPLE:table4_col3:received_feedback=%d\nSAMPLE:table4_col3:abs_gain_below_50=%d\n', nrow(df), nrow(fb), nrow(fb50)))
if (!is.null(m3)) cat(sprintf('SAMPLE:table4_col3:estimation=%d\n', nobs(m3)))
cat(sprintf('SAMPLE:table4_col4:loaded=%d\nSAMPLE:table4_col4:received_feedback=%d\nSAMPLE:table4_col4:abs_gain_below_50=%d\n', nrow(df), nrow(fb), nrow(fb50)))
if (!is.null(m4)) cat(sprintf('SAMPLE:table4_col4:estimation=%d\n', nobs(m4)))
if (!is.null(m1) && nobs(m1) != 757) cat(sprintf('DEVIATION: Table 4 col 1 N=%d vs 757 stated\n', nobs(m1)))

# ---------------- Table 6: targeted dividend IV ----------------
m6 <- NULL
tc_acc_var <- pick(df, c('tax_cible_acceptance', 'taxe_cible_acceptation'))
tc_bel_var <- pick(df, c('win_cible_category', 'gagnant_cible_categorie'))
el1 <- pick(df, c('traite_cible', 'eligible_cible', 'cible_eligible'))
el2 <- pick(df, c('traite_cible_conjoint', 'eligible_cible_conjoint'))
cible_var <- pick(df, c('cible', 'variante_cible'))
cat(sprintf('NOTE:table6_vars acc=%s belief=%s el1=%s el2=%s cible=%s\n', tc_acc_var, tc_bel_var, el1, el2, cible_var))
d6 <- df
if (!is.na(tc_acc_var) && !is.na(tc_bel_var)) {
  av <- d6[[tc_acc_var]]
  cat(sprintf('NOTE:table6 acc class=%s values=%s\n', paste(class(av), collapse = '/'),
              paste(head(unique(lab_chr(av)), 8), collapse = '|')))
  bv <- d6[[tc_bel_var]]
  cat(sprintf('NOTE:table6 belief class=%s values=%s\n', paste(class(bv), collapse = '/'),
              paste(head(unique(lab_chr(bv)), 8), collapse = '|')))
  # acceptance: if already a 0/1 (or logical) indicator use it directly, otherwise "not No"
  if (is.numeric(av) && !is.factor(av) && all(unique(av[!is.na(av)]) %in% c(0, 1))) {
    d6$acc_cible <- as.numeric(av)
  } else {
    d6$acc_cible <- is_not_no(av)
  }
  if (nvar(d6$acc_cible) < 2) {
    alt <- pick(d6, c('taxe_cible_approbation', 'tax_cible_approval'))
    if (!is.na(alt)) {
      ch <- tolower(trimws(lab_chr(d6[[alt]])))
      d6$acc_cible <- ifelse(is.na(ch) | ch == '' | ch == 'na', NA, as.numeric(ch != 'non'))
      cat(sprintf('DEVIATION: targeted acceptance rebuilt from %s != Non\n', alt))
    }
  }
  if (is.numeric(bv) && !is.factor(bv) && all(unique(bv[!is.na(bv)]) %in% c(0, 1))) {
    d6$bel_cible <- as.numeric(bv)
  } else {
    d6$bel_cible <- not_lose(bv)
  }
  if (is.na(el1)) {
    pr <- num_or_na(d6$percentile_revenu); prc <- num_or_na(d6$percentile_revenu_conjoint)
    thr <- num_or_na(gsub('[^0-9]', '', lab_chr(d6[[cible_var]])))
    d6$el1 <- as.numeric(pr <= thr); d6$el2 <- as.numeric(prc <= thr)
    cat('DEVIATION: eligibility reconstructed from percentile_revenu and assigned threshold\n')
  } else {
    d6$el1 <- to_binary(d6[[el1]]); d6$el1[is.na(d6$el1)] <- 0
    d6$el2 <- if (!is.na(el2)) to_binary(d6[[el2]]) else 0
  }
  d6$el2[is.na(d6$el2)] <- 0
  d6$el12 <- d6$el1 * d6$el2
  d6$single_ <- if ('single' %in% names(d6)) to_binary(d6$single) else as.numeric(num_or_na(d6$nb_adultes) == 1)
  d6$single_[is.na(d6$single_)] <- 0
  d6$cible_fe <- factor(lab_chr(d6[[cible_var]]))
  d6$pr <- num_or_na(d6$percentile_revenu)
  d6$prc <- num_or_na(d6$percentile_revenu_conjoint); d6$prc[is.na(d6$prc)] <- 0
  cc6 <- !is.na(d6$acc_cible) & !is.na(d6$bel_cible) & !is.na(d6$pr) & !is.na(d6$init_accept)
  cat(sprintf('NOTE:table6 complete=%d acc_var=%d bel_var=%d el1_mean=%.3f\n', sum(cc6),
              nvar(d6$acc_cible[cc6]), nvar(d6$bel_cible[cc6]), mean(d6$el1)))
  cat(sprintf('SAMPLE:table6_col1:loaded=%d\n', nrow(d6)))
  cat('DEVIATION: Table 6 income-percentile window not stated; using all respondents with percentile polynomials as controls\n')
  ctrl6 <- c('single_', 'init_accept', 'pr', 'I(pr^2)', 'I(pr^3)', 'prc', 'I(prc^2)', 'I(prc^3)',
             'single_:pr', 'single_:I(pr^2)', 'single_:I(pr^3)')
  f6 <- as.formula(paste('acc_cible ~', paste(ctrl6, collapse = ' + '), '| cible_fe | bel_cible ~ el1 + el2 + el12'))
  m6 <- tryCatch(feols(f6, data = d6, weights = ~w__, vcov = 'hetero'),
                 error = function(e) { cat('NOTE:error6 ', conditionMessage(e), '\n'); NULL })
  if (is.null(m6) || is.na(getcoef(m6, 'fit_bel_cible'))) {
    cat('DEVIATION: Table 6 fallback specification without threshold fixed effects\n')
    f6b <- as.formula(paste('acc_cible ~', paste(ctrl6, collapse = ' + '), '| bel_cible ~ el1 + el2 + el12'))
    m6 <- tryCatch(feols(f6b, data = d6, weights = ~w__, vcov = 'hetero'),
                   error = function(e) { cat('NOTE:error6b ', conditionMessage(e), '\n'); NULL })
  }
  if (!is.null(m6)) cat(sprintf('NOTE:m6 coefs=%s\n', paste(names(coef(m6)), collapse = ',')))
  if (!is.null(m6)) cat(sprintf('SAMPLE:table6_col1:estimation=%d\n', nobs(m6)))
} else cat('DEVIATION: Table 6 variables not found\n')

# ---------------- Table 8: effectiveness IV ----------------
m8 <- NULL
eff_var <- pick(df, c('taxe_efficace', 'tax_effective'))
sci_var <- pick(df, c('apres_modifs', 'info_efficacite', 'info_effective', 'info_scientists'))
cc_var <- pick(df, c('info_CC', 'info_cc'))
pm_var <- pick(df, c('info_PM', 'info_pm'))
cat(sprintf('NOTE:table8_vars eff=%s sci=%s cc=%s\n', eff_var, sci_var, cc_var))
if (!is.na(eff_var) && !is.na(sci_var) && !is.na(cc_var)) {
  d8 <- df
  d8$eff_yes <- is_yes(d8[[eff_var]])
  d8$z_sci <- as.numeric(as.logical(d8[[sci_var]]) %in% TRUE)
  d8$z_cc <- as.numeric(as.logical(d8[[cc_var]]) %in% TRUE)
  ctrl8 <- setdiff(ctrl_all, eff_var)
  extra8 <- c('gain_hat', 'init_cat')
  if (!is.na(pm_var)) { d8$z_pm <- as.numeric(as.logical(d8[[pm_var]]) %in% TRUE); extra8 <- c(extra8, 'z_pm') }
  cat(sprintf('SAMPLE:table8_col1:loaded=%d\n', nrow(d8)))
  f8 <- as.formula(paste('init_approve ~', paste(c(extra8, bq(ctrl8)), collapse = ' + '), '| eff_yes ~ z_sci + z_cc'))
  m8 <- tryCatch(feols(f8, data = d8, weights = ~w__, vcov = 'hetero'),
                 error = function(e) { cat('NOTE:error8 ', conditionMessage(e), '\n'); NULL })
  if (!is.null(m8)) cat(sprintf('SAMPLE:table8_col1:estimation=%d\n', nobs(m8)))
  if (!is.null(m8) && nobs(m8) != 3002) cat(sprintf('DEVIATION: Table 8 N=%d vs 3002\n', nobs(m8)))
} else cat('DEVIATION: Table 8 variables not found\n')

# ---------------- results ----------------
emit('predicted_winner_believes_not_lose_table4_col1', getcoef(m1, 'pred_winner'))
emit('initial_acceptance_believes_not_lose_table4_col1', getcoef(m1, 'init_accept'))
emit('predicted_winner_believes_not_lose_full_sample_table4_col2', getcoef(m2, 'pred_winner'))
emit('predicted_winner_heterogeneity_table4_col3', getcoef(m3, 'pred_winner'))
emit('initial_acceptance_heterogeneity_table4_col3', getcoef(m3, 'init_accept'))
emit('yellow_vests_supporter_heterogeneity_table4_col3', getcoef(m3, 'yv_support'))
emit('winner_x_initial_acceptance_table4_col3', getcoef(m3, 'pred_winner:init_accept'))
emit('winner_x_yellow_vests_supporter_table4_col3', getcoef(m3, 'pred_winner:yv_support'))
emit('winner_x_initial_win_belief_table4_col3', getcoef(m3, 'pred_winner:G_init'))
emit('predicted_winner_believes_wins_table4_col4', getcoef(m4, 'pred_winner'))
emit('n_obs_table4_col1', if (is.null(m1)) NA else nobs(m1))
emit('believes_not_lose_on_acceptance_iv_table6_col1', getcoef(m6, 'fit_bel_cible'))
emit('believes_effective_on_approval_iv_table8_col1', getcoef(m8, 'fit_eff_yes'))