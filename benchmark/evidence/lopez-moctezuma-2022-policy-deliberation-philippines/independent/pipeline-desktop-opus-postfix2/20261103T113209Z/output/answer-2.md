suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- '<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines.script-free'
load(file.path(base, 'data_agg.RData'))     # data.all
load(file.path(base, 'survey_raw.RData'))   # survey_raw

# ---------------- helpers ----------------
unlab <- function(x) {
  if (inherits(x, 'haven_labelled')) x <- haven::as_factor(x)
  x
}
to01 <- function(x) {
  x <- unlab(x)
  if (is.logical(x)) return(as.numeric(x))
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) {
    lx <- tolower(trimws(x))
    out <- rep(NA_real_, length(lx))
    num <- suppressWarnings(as.numeric(lx))
    out[!is.na(num) & num %in% c(0, 1)] <- num[!is.na(num) & num %in% c(0, 1)]
    out[lx %in% c('yes', 'y', 'true', 'treatment', 'treated', 'voted', 'female')] <- 1
    out[lx %in% c('no', 'n', 'false', 'control', 'did not vote', 'male')] <- 0
    out[is.na(out) & grepl('^treat', lx)] <- 1
    out[is.na(out) & grepl('^control', lx)] <- 0
    return(out)
  }
  x <- as.numeric(x)
  vals <- sort(unique(x[!is.na(x)]))
  if (all(vals %in% c(0, 1))) return(x)
  if (all(vals %in% c(1, 2))) return(as.numeric(x == 1))
  x[!(x %in% c(0, 1))] <- NA
  x
}
to_num <- function(x) {
  x <- unlab(x)
  if (is.factor(x)) {
    n <- suppressWarnings(as.numeric(as.character(x)))
    if (mean(is.na(n[!is.na(x)])) < 0.5) return(n)
    return(as.numeric(x))
  }
  if (is.character(x)) {
    n <- suppressWarnings(as.numeric(x))
    if (mean(is.na(n[!is.na(x) & x != ''])) < 0.5) return(n)
    return(as.numeric(factor(x)))
  }
  as.numeric(x)
}
pct <- function(x) { x <- as.numeric(x); if (max(abs(x), na.rm = TRUE) <= 1) x * 100 else x }
norm <- function(x) gsub('[^a-z0-9]', '', tolower(as.character(unlab(x))))

# Party identification (Akbayan = the party with 18 barangays in the aggregate data)
pt_agg <- unlab(data.all$partytreat)
if (is.factor(pt_agg)) pt_agg <- as.character(pt_agg)
if (is.character(pt_agg) && any(grepl('akb', tolower(pt_agg)))) {
  akb_code_fun <- function(v) { v <- unlab(v); grepl('akb', tolower(as.character(v))) }
} else {
  tab <- table(pt_agg)
  akb_code <- names(tab)[which.min(abs(as.numeric(tab) - 18))]
  akb_code_fun <- function(v) { v <- unlab(v); as.character(v) == akb_code }
}

# ---------------- Barangay level (Table 1) ----------------
agg <- data.all
cat(sprintf('SAMPLE:barangay_all:loaded=%d\n', nrow(agg)))
agg$Z <- to01(agg$assignment)
agg$T <- to01(agg$treatment)
agg$city_f <- as.character(unlab(agg$city))
agg$akb <- akb_code_fun(agg$partytreat)
agg$turnout <- pct(agg$turnout.party)
agg$sh_akb <- pct(agg$share.akbayan)
agg$sh_uml <- pct(agg$share.umalabka)
if ('share.treated' %in% names(agg)) {
  agg$vote_overall <- pct(agg$share.treated)
} else {
  agg$vote_overall <- ifelse(agg$akb, agg$sh_akb, agg$sh_uml)
}
# sanity: if share.treated inconsistent with party shares, rebuild
alt <- ifelse(agg$akb, agg$sh_akb, agg$sh_uml)
if (isTRUE(mean(abs(agg$vote_overall - alt), na.rm = TRUE) > 0.5)) agg$vote_overall <- alt

perm_p <- function(df, yvar, B = 2000) {
  f <- as.formula(paste0(yvar, ' ~ Z | city_f'))
  obs <- coef(feols(f, data = df))['Z']
  cities <- df$city_f
  stats <- replicate(B, {
    d <- df
    d$Z <- ave(d$Z, cities, FUN = function(z) z[sample.int(length(z))])
    coef(feols(f, data = d))['Z']
  })
  mean(abs(stats) >= abs(obs) - 1e-12)
}

run_bar <- function(df, yvar, name) {
  m <- feols(as.formula(paste0(yvar, ' ~ Z | city_f')), data = df)
  iv <- tryCatch(feols(as.formula(paste0(yvar, ' ~ 1 | city_f | T ~ Z')), data = df), error = function(e) NULL)
  list(m = m, iv = iv, p = perm_p(df, yvar), cm = mean(df[[yvar]][df$Z == 0], na.rm = TRUE))
}

r1 <- run_bar(agg, 'turnout', 'turnout')
cat(sprintf('SAMPLE:barangay_all:estimation=%d\n', nobs(r1$m)))
r2 <- run_bar(agg, 'vote_overall', 'vote_overall')
agg_a <- agg[agg$akb, ]
cat(sprintf('SAMPLE:barangay_akbayan:loaded=%d\n', nrow(agg)))
cat(sprintf('SAMPLE:barangay_akbayan:akbayan_municipalities=%d\n', nrow(agg_a)))
r3 <- run_bar(agg_a, 'sh_akb', 'akb')
cat(sprintf('SAMPLE:barangay_akbayan:estimation=%d\n', nobs(r3$m)))
agg_u <- agg[!agg$akb, ]
cat(sprintf('SAMPLE:barangay_umalabka:loaded=%d\n', nrow(agg)))
cat(sprintf('SAMPLE:barangay_umalabka:umalabka_municipalities=%d\n', nrow(agg_u)))
r4 <- run_bar(agg_u, 'sh_uml', 'uml')
cat(sprintf('SAMPLE:barangay_umalabka:estimation=%d\n', nobs(r4$m)))

# ---------------- Individual level ----------------
sv <- survey_raw
sv$Z <- to01(sv$assignment)
sv$T <- to01(sv$treatment)
sv$city_f <- as.character(unlab(sv$city))
sv$brgy_f <- paste(norm(sv$city), norm(sv$barangay), sep = '_')
sv$akb <- akb_code_fun(sv$partytreat)
sv$turn <- to01(if ('turnout_pl' %in% names(sv)) sv$turnout_pl else sv$turnout_all)
sv$v_akb <- to01(sv$vote.akbayan)
sv$v_uml <- to01(sv$vote.umalabka)
sv$v_all <- to01(sv$vote)
if (mean(is.na(sv$v_all)) > 0.9 || all(is.na(sv$v_all))) sv$v_all <- ifelse(sv$akb, sv$v_akb, sv$v_uml)
sv$att <- to01(sv$attendance)

# Attendance weights: actual attendance proportion (att.prop) vs. survey self-reported share
agg_w <- data.frame(key = paste(norm(data.all$city), norm(data.all$barangay), sep = '_'),
                    bkey = norm(data.all$barangay),
                    p = as.numeric(data.all$att.prop))
if (max(agg_w$p, na.rm = TRUE) > 1) agg_w$p <- agg_w$p / 100
sv$p_actual <- agg_w$p[match(sv$brgy_f, agg_w$key)]
miss <- is.na(sv$p_actual)
sv$p_actual[miss] <- agg_w$p[match(norm(sv$barangay[miss]), agg_w$bkey)]
sv <- sv %>% group_by(brgy_f) %>%
  mutate(s_survey = mean(att, na.rm = TRUE)) %>% ungroup() %>% as.data.frame()
sv$w <- 1
ok <- !is.na(sv$p_actual) & !is.na(sv$att) & !is.na(sv$s_survey) & sv$s_survey > 0 & sv$s_survey < 1
sv$w[ok & sv$att == 1] <- (sv$p_actual / sv$s_survey)[ok & sv$att == 1]
sv$w[ok & sv$att == 0] <- ((1 - sv$p_actual) / (1 - sv$s_survey))[ok & sv$att == 0]
sv$w[!is.finite(sv$w) | sv$w <= 0] <- 1
if (any(is.na(sv$p_actual))) cat('DEVIATION: some survey barangays could not be matched to attendance sheets; weight set to 1\n')

excl <- grepl('imus|pateros|santamaria|stamaria', norm(sv$city))

# Unweighted vote outcomes (Table F.1)
cat(sprintf('SAMPLE:indiv_vote_overall:loaded=%d\n', nrow(sv)))
s1 <- sv[!is.na(sv$turn), ]
cat(sprintf('SAMPLE:indiv_vote_overall:valid_turnout_response=%d\n', nrow(s1)))
s1 <- s1[!excl[!is.na(sv$turn)], ]
cat(sprintf('SAMPLE:indiv_vote_overall:exclude_imus_pateros_santamaria=%d\n', nrow(s1)))
s1v <- s1[s1$turn == 1, ]
cat(sprintf('SAMPLE:indiv_vote_overall:turned_out=%d\n', nrow(s1v)))
s1v$y <- 100 * s1v$v_all
mF2 <- feols(y ~ Z | city_f, data = s1v, cluster = ~brgy_f)
cat(sprintf('SAMPLE:indiv_vote_overall:estimation=%d\n', nobs(mF2)))

s1a <- s1v[s1v$akb, ]
cat(sprintf('SAMPLE:indiv_vote_akbayan:loaded=%d\n', nrow(sv)))
cat(sprintf('SAMPLE:indiv_vote_akbayan:valid_turnout_response=%d\n', sum(!is.na(sv$turn))))
cat(sprintf('SAMPLE:indiv_vote_akbayan:exclude_imus_pateros_santamaria=%d\n', nrow(s1)))
cat(sprintf('SAMPLE:indiv_vote_akbayan:turned_out=%d\n', nrow(s1v)))
cat(sprintf('SAMPLE:indiv_vote_akbayan:akbayan_municipalities=%d\n', nrow(s1a)))
s1a$y <- 100 * s1a$v_akb
mF3 <- feols(y ~ Z | city_f, data = s1a, cluster = ~brgy_f)
cat(sprintf('SAMPLE:indiv_vote_akbayan:estimation=%d\n', nobs(mF3)))

# ---------------- Anderson indices (Tables C.3, C.4) ----------------
# Item coding: use underlying codes, drop don't-know/refused, orient so higher = more agreement
to_item <- function(x0) {
  labs <- attr(x0, 'labels')
  if (is.factor(x0) || is.character(x0)) {
    lx <- tolower(trimws(as.character(x0)))
    sc <- rep(NA_real_, length(lx))
    sc[grepl('agree', lx)] <- 4
    sc[grepl('strongly agree|completely agree|very much agree', lx)] <- 5
    sc[grepl('disagree', lx)] <- 2
    sc[grepl('strongly disagree|completely disagree', lx)] <- 1
    sc[grepl('neither|neutral|undecided', lx)] <- 3
    if (mean(!is.na(sc[!is.na(lx) & lx != ''])) > 0.5) return(sc)
    return(to_num(x0))
  }
  v <- as.numeric(if (inherits(x0, 'haven_labelled')) haven::zap_labels(x0) else x0)
  if (!is.null(labs)) {
    nm <- tolower(names(labs))
    dk <- as.numeric(labs[grepl("know|refus|no answer|n/a|not sure|no opinion|^dk|^na$", nm)])
    v[v %in% dk] <- NA
    ag <- as.numeric(labs[grepl('agree', nm) & !grepl('disagree', nm) & !(as.numeric(labs) %in% dk)])
    di <- as.numeric(labs[grepl('disagree', nm) & !(as.numeric(labs) %in% dk)])
    if (length(ag) && length(di) && mean(ag) < mean(di)) v <- -v
  } else {
    v[v %in% c(8, 9, 88, 98, 99, 888, 998, 999) | v < 0] <- NA
  }
  v
}

anderson <- function(df, items) {
  Zm <- sapply(items, function(v) {
    x <- to_item(df[[v]])
    mu <- mean(x[df$Z == 0], na.rm = TRUE); s <- sd(x[df$Z == 0], na.rm = TRUE)
    (x - mu) / s
  })
  Zm <- as.matrix(Zm)
  S <- cov(Zm, use = 'pairwise.complete.obs')
  Si <- tryCatch(solve(S), error = function(e) MASS::ginv(S))
  wts <- rowSums(Si)
  idx <- apply(Zm, 1, function(r) {
    okk <- !is.na(r)
    if (!any(okk)) return(NA_real_)
    sum(wts[okk] * r[okk]) / sum(wts[okk])
  })
  mu <- mean(idx[df$Z == 0], na.rm = TRUE); s <- sd(idx[df$Z == 0], na.rm = TRUE)
  (idx - mu) / s
}
pov_items <- c('poverty', 'gap', 'cct', 'corruption')
gen_items <- c('femhouse', 'fempol', 'equality', 'discrimination', 'harassment')

run_index <- function(party_akb, items, sname) {
  cat(sprintf('SAMPLE:%s:loaded=%d\n', sname, nrow(sv)))
  d <- sv[!excl, ]
  cat(sprintf('SAMPLE:%s:exclude_imus_pateros_santamaria=%d\n', sname, nrow(d)))
  d <- d[d$akb == party_akb, ]
  cat(sprintf('SAMPLE:%s:party_municipalities=%d\n', sname, nrow(d)))
  d$idx <- anderson(d, items)
  m <- feols(idx ~ Z | city_f, data = d, weights = ~w, cluster = ~brgy_f)
  cat(sprintf('SAMPLE:%s:estimation=%d\n', sname, nobs(m)))
  m
}
mC3a <- run_index(TRUE,  pov_items, 'poverty_index_akbayan')
mC3u <- run_index(FALSE, pov_items, 'poverty_index_umalabka')
mC4a <- run_index(TRUE,  gen_items, 'gender_index_akbayan')
mC4u <- run_index(FALSE, gen_items, 'gender_index_umalabka')

# ---------------- Results ----------------
out <- function(n, v) cat(sprintf('RESULT:%s=%.6f\n', n, as.numeric(v)))
out('itt_turnout_barangay_table1_col1', coef(r1$m)['Z'])
out('itt_vote_overall_barangay_table1_col2', coef(r2$m)['Z'])
out('itt_vote_akbayan_barangay_table1_col3', coef(r3$m)['Z'])
out('itt_vote_umalabka_barangay_table1_col4', coef(r4$m)['Z'])
out('perm_p_turnout_barangay_table1_col1', r1$p)
out('perm_p_vote_overall_barangay_table1_col2', r2$p)
out('perm_p_vote_akbayan_barangay_table1_col3', r3$p)
out('perm_p_vote_umalabka_barangay_table1_col4', r4$p)
out('control_mean_turnout_table1_col1', r1$cm)
out('control_mean_vote_overall_table1_col2', r2$cm)
out('control_mean_vote_akbayan_table1_col3', r3$cm)
out('control_mean_vote_umalabka_table1_col4', r4$cm)
for (pr in list(list('turnout', r1), list('vote_overall', r2), list('vote_akbayan', r3), list('vote_umalabka', r4))) {
  if (!is.null(pr[[2]]$iv)) out(paste0('cace_', pr[[1]], '_barangay_table1'), coef(pr[[2]]$iv)['fit_T'])
}
out('n_obs_barangay_table1_cols1_2', nobs(r1$m))
out('n_obs_barangay_akbayan_table1_col3', nobs(r3$m))
out('n_obs_barangay_umalabka_table1_col4', nobs(r4$m))
out('itt_poverty_index_akbayan_tableC3', coef(mC3a)['Z'])
out('itt_poverty_index_umalabka_tableC3', coef(mC3u)['Z'])
out('itt_gender_index_akbayan_tableC4', coef(mC4a)['Z'])
out('itt_gender_index_umalabka_tableC4', coef(mC4u)['Z'])
out('se_poverty_index_akbayan_tableC3', se(mC3a)['Z'])
out('se_poverty_index_umalabka_tableC3', se(mC3u)['Z'])
out('se_gender_index_akbayan_tableC4', se(mC4a)['Z'])
out('se_gender_index_umalabka_tableC4', se(mC4u)['Z'])
out('itt_vote_overall_unweighted_tableF1_col2', coef(mF2)['Z'])
out('itt_vote_akbayan_unweighted_tableF1_col3', coef(mF3)['Z'])
