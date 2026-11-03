suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
  library(AER)
  library(survival)
})
set.seed(42)

base <- '<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias.script-free'
df <- read_csv(file.path(base, 'Consumption Experiment/Stata/Consumption_Experiment.csv'),
               show_col_types = FALSE, guess_max = 10000)
n_loaded <- nrow(df)
message('Columns: ', paste(names(df), collapse = ', '))

num <- function(v) suppressWarnings(as.numeric(v))
firstnn <- function(x) { y <- x[!is.na(x)]; if (length(y)) y[1] else x[1] }
is01 <- function(v) { v <- num(v); u <- unique(v[!is.na(v)]); length(u) > 0 && all(u %in% c(0, 1)) }

# ---------------- subject identifier ----------------
if ('session' %in% names(df)) {
  df$sid <- paste(df$session, df$tn, sep = '_')
} else {
  df$sid <- as.character(df$tn)
}
if (!'decision_number' %in% names(df)) df$decision_number <- ave(seq_len(nrow(df)), df$sid, FUN = seq_along)
df$decision_number <- num(df$decision_number)

# balanced-corner exclusion computed from raw rows (fallback if pap_sample missing)
df <- df %>% group_by(sid) %>% mutate(.maxdec = max(decision_number, na.rm = TRUE)) %>% ungroup()
corner_var <- if ('corner' %in% names(df)) 'corner' else if ('chose_corner' %in% names(df)) 'chose_corner' else NA
if (!is.na(corner_var)) {
  bc <- df %>% group_by(sid) %>%
    summarise(.bal_corner = any(num(.data[[corner_var]])[decision_number < .maxdec] %in% 1, na.rm = TRUE),
              .groups = 'drop')
} else {
  bc <- data.frame(sid = unique(df$sid), .bal_corner = FALSE)
}

# ---------------- collapse to subject level ----------------
idvars <- setdiff(grep('^id_stage2', names(df), value = TRUE), 'avg_id_stage2')
qevars <- grep('^qe_rad', names(df), value = TRUE)
keyvars <- intersect(c('tn', 'session', 'treatment', 'main', 'pizza', 'control', 'dispersed',
                       'pap_sample', 'chose_corner', idvars, qevars), names(df))
subj <- df %>% arrange(sid, desc(decision_number)) %>% group_by(sid) %>%
  summarise(across(all_of(keyvars), firstnn), .groups = 'drop') %>%
  left_join(bc, by = 'sid')
n_subj <- nrow(subj)
message('Subjects: ', n_subj)

# ---------------- conditions ----------------
if ('treatment' %in% names(subj) && is.character(subj$treatment) && all(is.na(num(subj$treatment[!is.na(subj$treatment)])))) {
  message('treatment values: ', paste(unique(subj$treatment), collapse = ' | '))
  tr <- tolower(subj$treatment)
  is_ctrl <- grepl('control', tr)
  is_don <- grepl('donat|charit', tr)
  is_mech <- grepl('mech', tr) & !is_don
} else {
  if ('control' %in% names(subj) && is01(subj$control)) {
    is_ctrl <- num(subj$control) == 1
  } else if ('treatment' %in% names(subj) && is01(subj$treatment)) {
    is_ctrl <- num(subj$treatment) == 0
  } else if ('dispersed' %in% names(subj) && is01(subj$dispersed)) {
    is_ctrl <- num(subj$dispersed) == 0
  } else {
    is_ctrl <- rep(FALSE, n_subj)
  }
  is_don <- if ('pizza' %in% names(subj) && is01(subj$pizza)) num(subj$pizza) == 0 else rep(FALSE, n_subj)
  is_mech <- if ('main' %in% names(subj) && is01(subj$main)) (num(subj$main) == 0 & !is_don) else rep(FALSE, n_subj)
}
is_ctrl[is.na(is_ctrl)] <- FALSE; is_don[is.na(is_don)] <- FALSE; is_mech[is.na(is_mech)] <- FALSE
subj$cond <- case_when(is_don & !is_ctrl ~ 'DT', is_don & is_ctrl ~ 'DC',
                       is_mech & !is_ctrl ~ 'MechT', is_mech & is_ctrl ~ 'MechC',
                       !is_ctrl ~ 'MT', TRUE ~ 'MC')

if ('pap_sample' %in% names(subj)) {
  subj$keep <- num(subj$pap_sample) %in% 1
} else {
  cat('DEVIATION: pap_sample not found; exclusion computed from corner choices in balanced trade-offs\n')
  subj$keep <- !subj$.bal_corner
}
message(paste(capture.output(print(table(subj$cond, subj$keep))), collapse = '\n'))

# ---------------- measures ----------------
mt_idx <- subj$cond == 'MT' & subj$keep
for (v in c(idvars, qevars)) subj[[v]] <- num(subj[[v]])

build_bounds <- function(vars, is_abs) {
  if (length(vars) == 0) return(NULL)
  low_named <- grep('lower', vars, value = TRUE)
  up_named <- grep('upper', vars, value = TRUE)
  mid_named <- setdiff(vars, c(low_named, up_named))
  if (length(low_named) && length(up_named) && length(mid_named)) {
    cand <- c(low_named[1], mid_named[1], up_named[1])
    m <- sapply(cand, function(v) mean(subj[[v]][mt_idx], na.rm = TRUE))
    cand <- cand[order(m)]
    return(list(lower = subj[[cand[1]]], mid = subj[[cand[2]]], upper = subj[[cand[3]]]))
  }
  if (length(vars) >= 3) {
    m <- sapply(vars, function(v) mean(subj[[v]][mt_idx], na.rm = TRUE))
    cand <- vars[order(m)]
    return(list(lower = subj[[cand[1]]], mid = subj[[cand[2]]], upper = subj[[cand[length(cand)]]]))
  }
  if (length(low_named) && length(up_named)) {
    lo <- subj[[low_named[1]]]; up <- subj[[up_named[1]]]
    return(list(lower = lo, mid = (lo + up) / 2, upper = up))
  }
  if (length(up_named) && length(mid_named)) {
    a <- subj[[mid_named[1]]]; up <- subj[[up_named[1]]]
    a_is_lower <- if (is_abs) max(a, na.rm = TRUE) <= 62 else
      mean(a[mt_idx], na.rm = TRUE) < 0.5 * (mean(up[mt_idx], na.rm = TRUE) + mean(a[mt_idx], na.rm = TRUE)) - 1e-9 &&
      FALSE
    if (is_abs && a_is_lower) return(list(lower = a, mid = (a + up) / 2, upper = up))
    return(list(lower = 2 * a - up, mid = a, upper = up))
  }
  if (length(low_named) && length(mid_named)) {
    lo <- subj[[low_named[1]]]; a <- subj[[mid_named[1]]]
    return(list(lower = lo, mid = a, upper = 2 * a - lo))
  }
  a <- subj[[vars[1]]]
  list(lower = a, mid = a, upper = a)
}

dabs <- build_bounds(idvars, TRUE)
drel <- build_bounds(qevars, FALSE)

e_vec <- c(129, 132, 143, 115, 121, 117, 135, 127)
if (is.null(drel) && !is.null(dabs)) {
  cat('DEVIATION: relative measure variables not found; computing d_rel from balanced indifference points\n')
  xw <- df %>% filter(decision_number >= 1, decision_number <= 8) %>%
    group_by(sid, decision_number) %>% summarise(x = firstnn(num(indifference_point)), .groups = 'drop')
  denom <- xw %>% mutate(inv = 1 / (e_vec[decision_number] + x)) %>% group_by(sid) %>%
    summarise(minv = mean(inv), .groups = 'drop')
  mi <- denom$minv[match(subj$sid, denom$sid)]
  drel <- list(lower = dabs$lower * mi, mid = dabs$mid * mi, upper = dabs$upper * mi)
}
# scale check (percent vs share)
if (!is.null(drel) && abs(mean(drel$mid[mt_idx], na.rm = TRUE)) > 2) {
  drel <- lapply(drel, function(z) z / 100)
}

subj$d_lower <- dabs$lower; subj$d_mid <- dabs$mid; subj$d_upper <- dabs$upper
subj$rel_lower <- drel$lower; subj$rel_mid <- drel$mid; subj$rel_upper <- drel$upper

# ---------------- Table 2 ----------------
res <- c()
t2 <- subj %>% filter(cond == 'MT')
n_t2_cond <- nrow(t2)
t2 <- t2 %>% filter(keep)
n_t2_keep <- nrow(t2)
if (n_t2_keep != 100) cat(sprintf('DEVIATION: Main-Treatment main sample has %d subjects, paper states 100\n', n_t2_keep))

m_dmid <- feols(d_mid ~ 1, data = t2, vcov = 'hetero')
m_dlow <- feols(d_lower ~ 1, data = t2, vcov = 'hetero')
m_dup <- feols(d_upper ~ 1, data = t2, vcov = 'hetero')
m_rlow <- feols(rel_lower ~ 1, data = t2, vcov = 'hetero')
m_rmid <- feols(rel_mid ~ 1, data = t2, vcov = 'hetero')
m_rup <- feols(rel_upper ~ 1, data = t2, vcov = 'hetero')

tob_coef <- NA; tob_se <- NA; tob_n <- NA
tob <- tryCatch(AER::tobit(d_lower ~ 1, left = -63, right = 62, data = t2), error = function(e) NULL)
if (!is.null(tob)) {
  tob_coef <- unname(coef(tob)[1]); tob_se <- unname(sqrt(diag(vcov(tob)))[1]); tob_n <- nobs(tob)
} else {
  lo <- ifelse(t2$d_lower <= -63, NA, t2$d_lower); hi <- ifelse(t2$d_lower >= 62, NA, t2$d_lower)
  sr <- survreg(Surv(lo, hi, type = 'interval2') ~ 1, dist = 'gaussian')
  tob_coef <- unname(coef(sr)[1]); tob_se <- unname(sqrt(diag(vcov(sr)))[1]); tob_n <- nrow(t2)
}

cat(sprintf('SAMPLE:table2_main_treatment:loaded=%d\n', n_loaded))
cat(sprintf('SAMPLE:table2_main_treatment:collapse_to_subjects=%d\n', n_subj))
cat(sprintf('SAMPLE:table2_main_treatment:main_treatment_condition=%d\n', n_t2_cond))
cat(sprintf('SAMPLE:table2_main_treatment:exclude_corner_in_balanced_tradeoffs=%d\n', n_t2_keep))
cat(sprintf('SAMPLE:table2_main_treatment:estimation=%d\n', nobs(m_rmid)))
cat(sprintf('SAMPLE:table2_tobit:loaded=%d\n', n_loaded))
cat(sprintf('SAMPLE:table2_tobit:collapse_to_subjects=%d\n', n_subj))
cat(sprintf('SAMPLE:table2_tobit:main_treatment_condition=%d\n', n_t2_cond))
cat(sprintf('SAMPLE:table2_tobit:exclude_corner_in_balanced_tradeoffs=%d\n', n_t2_keep))
cat(sprintf('SAMPLE:table2_tobit:estimation=%d\n', as.integer(tob_n)))

se <- function(m, k) unname(sqrt(diag(vcov(m)))[k])
res['abs_concentration_bias_midpoint_table2_col2'] <- unname(coef(m_dmid)[1])
res['abs_concentration_bias_midpoint_table2_col2_se'] <- se(m_dmid, 1)
res['abs_concentration_bias_lower_table2_col1'] <- unname(coef(m_dlow)[1])
res['abs_concentration_bias_upper_table2_col3'] <- unname(coef(m_dup)[1])
res['abs_concentration_bias_tobit_table2_col4'] <- tob_coef
res['abs_concentration_bias_tobit_table2_col4_se'] <- tob_se
res['rel_concentration_bias_lower_table2_col1'] <- unname(coef(m_rlow)[1])
res['rel_concentration_bias_lower_table2_col1_se'] <- se(m_rlow, 1)
res['rel_concentration_bias_midpoint_table2_col2'] <- unname(coef(m_rmid)[1])
res['rel_concentration_bias_midpoint_table2_col2_se'] <- se(m_rmid, 1)
res['rel_concentration_bias_upper_table2_col3'] <- unname(coef(m_rup)[1])
res['rel_concentration_bias_upper_table2_col3_se'] <- se(m_rup, 1)
res['n_obs_table2'] <- nobs(m_rmid)

# ---------------- Table 3 ----------------
run_t3 <- function(name, treat_cond, base_cond, colnum) {
  s <- subj %>% filter(cond %in% c(treat_cond, base_cond))
  n_cond <- nrow(s)
  s <- s %>% filter(keep)
  n_keep <- nrow(s)
  if (n_keep != 200) cat(sprintf('DEVIATION: Table 3 column %d sample has %d subjects, paper states 200\n', colnum, n_keep))
  s$D <- as.integer(s$cond == treat_cond)
  m <- feols(rel_mid ~ D, data = s, vcov = 'hetero')
  cat(sprintf('SAMPLE:%s:loaded=%d\n', name, n_loaded))
  cat(sprintf('SAMPLE:%s:collapse_to_subjects=%d\n', name, n_subj))
  cat(sprintf('SAMPLE:%s:two_conditions=%d\n', name, n_cond))
  cat(sprintf('SAMPLE:%s:exclude_corner_in_balanced_tradeoffs=%d\n', name, n_keep))
  cat(sprintf('SAMPLE:%s:estimation=%d\n', name, nobs(m)))
  m
}
m31 <- run_t3('table3_col1_main_vs_mechanism', 'MT', 'MechT', 1)
m32 <- run_t3('table3_col2_donation', 'DT', 'DC', 2)
m33 <- run_t3('table3_col3_main', 'MT', 'MC', 3)
m34 <- run_t3('table3_col4_mechanism', 'MechT', 'MechC', 4)

res['rel_cb_mechanism_treatment_table3_col1'] <- unname(coef(m31)['(Intercept)'])
res['rel_cb_mechanism_treatment_table3_col1_se'] <- se(m31, '(Intercept)')
res['diff_main_minus_mechanism_table3_col1'] <- unname(coef(m31)['D'])
res['diff_main_minus_mechanism_table3_col1_se'] <- se(m31, 'D')
res['rel_cb_donation_treatment_table3_col2'] <- unname(coef(m32)['(Intercept)'] + coef(m32)['D'])
res['rel_cb_donation_control_table3_col2'] <- unname(coef(m32)['(Intercept)'])
res['diff_donation_treatment_minus_control_table3_col2'] <- unname(coef(m32)['D'])
res['diff_donation_treatment_minus_control_table3_col2_se'] <- se(m32, 'D')
res['rel_cb_main_control_table3_col3'] <- unname(coef(m33)['(Intercept)'])
res['diff_main_treatment_minus_control_table3_col3'] <- unname(coef(m33)['D'])
res['diff_main_treatment_minus_control_table3_col3_se'] <- se(m33, 'D')
res['rel_cb_mechanism_control_table3_col4'] <- unname(coef(m34)['(Intercept)'])
res['diff_mechanism_treatment_minus_control_table3_col4'] <- unname(coef(m34)['D'])
res['diff_mechanism_treatment_minus_control_table3_col4_se'] <- se(m34, 'D')
res['n_obs_table3'] <- nobs(m31)

for (k in names(res)) cat(sprintf('RESULT:%s=%.6f\n', k, res[[k]]))
