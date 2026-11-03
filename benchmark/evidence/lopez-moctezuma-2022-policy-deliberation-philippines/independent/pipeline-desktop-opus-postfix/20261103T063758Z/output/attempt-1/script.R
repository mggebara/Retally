suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base_dir <- '<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines.script-free'
load(file.path(base_dir, 'data_agg.RData'))     # data.all
load(file.path(base_dir, 'survey_raw.RData'))   # survey_raw

# ---------------- helpers ----------------
strip_lab <- function(x) {
  if (inherits(x, 'haven_labelled')) x <- as.vector(unclass(x))
  x
}
to_num <- function(x) {
  x <- strip_lab(x)
  if (is.factor(x)) {
    v <- suppressWarnings(as.numeric(as.character(x)))
    if (all(is.na(v[!is.na(x)]))) v <- as.numeric(as.integer(x))
    return(v)
  }
  if (is.character(x)) {
    v <- suppressWarnings(as.numeric(x))
    if (all(is.na(v[!is.na(x) & x != '']))) v <- as.numeric(as.integer(factor(x)))
    return(v)
  }
  as.numeric(x)
}
to01 <- function(x) {
  x <- strip_lab(x)
  if (is.logical(x)) return(as.numeric(x))
  if (is.factor(x) || is.character(x)) {
    l <- tolower(trimws(as.character(x)))
    out <- rep(NA_real_, length(l))
    out[l %in% c('yes', '1', 'true', 'y', 'voted', 'treated', 'treatment')] <- 1
    out[l %in% c('no', '0', 'false', 'n', 'did not vote', 'not voted', 'control', '2')] <- 0
    return(out)
  }
  x <- as.numeric(x)
  vals <- sort(unique(x[!is.na(x)]))
  if (length(vals) == 0) return(x)
  if (all(vals %in% c(0, 1))) return(x)
  if (all(vals %in% c(1, 2))) return(ifelse(is.na(x), NA, ifelse(x == 1, 1, 0)))
  ifelse(x %in% c(0, 1), x, NA)
}
to_pct <- function(x) {
  x <- to_num(x)
  if (max(x, na.rm = TRUE) <= 1.0001) x <- 100 * x
  x
}
norm_name <- function(x) gsub('[^a-z0-9]', '', tolower(as.character(strip_lab(x))))

# within-city permutation of an assignment vector
perm_within <- function(z, grp) {
  out <- z
  for (g in unique(grp)) {
    idx <- which(grp == g)
    if (length(idx) > 1) out[idx] <- z[idx][sample.int(length(idx))]
  }
  out
}
# coefficient on z after within-group demeaning (OLS with group FE)
fe_coef <- function(y, z, grp, w = NULL) {
  if (is.null(w)) w <- rep(1, length(y))
  ok <- !is.na(y) & !is.na(z) & !is.na(w)
  y <- y[ok]; z <- z[ok]; grp <- grp[ok]; w <- w[ok]
  my <- ave(y * w, grp, FUN = sum) / ave(w, grp, FUN = sum)
  mz <- ave(z * w, grp, FUN = sum) / ave(w, grp, FUN = sum)
  yd <- y - my; zd <- z - mz
  den <- sum(w * zd^2)
  if (den == 0) return(NA_real_)
  sum(w * zd * yd) / den
}

# ======================================================================
# BARANGAY LEVEL (Table 1)
# ======================================================================
ag <- as.data.frame(data.all)
cat(sprintf('SAMPLE:barangay_all:loaded=%d\n', nrow(ag)))

ag$Z <- to01(ag$assignment)
ag$T <- to01(ag$treatment)
ag$cityf <- as.character(strip_lab(ag$city))

# turnout (% of registered voters)
if ('turnout.party' %in% names(ag)) {
  ag$turnout <- to_num(ag$turnout.party)
  if (max(ag$turnout, na.rm = TRUE) <= 1.0001) ag$turnout <- 100 * ag$turnout
  if (max(ag$turnout, na.rm = TRUE) > 100 && all(c('vote.num.party', 'reg.num') %in% names(ag)))
    ag$turnout <- 100 * to_num(ag$vote.num.party) / to_num(ag$reg.num)
} else {
  ag$turnout <- 100 * to_num(ag$vote.num.party) / to_num(ag$reg.num)
}
ag$sh_akb <- to_pct(ag$share.akbayan)
ag$sh_uma <- to_pct(ag$share.umalabka)
ag$sh_trt <- if ('share.treated' %in% names(ag)) to_pct(ag$share.treated) else NA_real_

# identify party list assigned to each municipality
pt <- strip_lab(ag$partytreat)
if ((is.character(pt) || is.factor(pt)) && any(grepl('akb', tolower(as.character(pt))))) {
  ag$akb <- as.integer(grepl('akb', tolower(as.character(pt))))
} else if (!all(is.na(ag$sh_trt))) {
  ag$akb <- as.integer(abs(ag$sh_trt - ag$sh_akb) <= abs(ag$sh_trt - ag$sh_uma))
} else {
  ag$akb <- as.integer(to_num(pt) == min(to_num(pt), na.rm = TRUE))
}
# make akb constant within city (majority)
ag$akb <- as.integer(ave(ag$akb, ag$cityf, FUN = mean) >= 0.5)
if (all(is.na(ag$sh_trt))) ag$sh_trt <- ifelse(ag$akb == 1, ag$sh_akb, ag$sh_uma)
akb_codes <- unique(as.character(pt[ag$akb == 1]))
uma_codes <- unique(as.character(pt[ag$akb == 0]))

cat(sprintf('SAMPLE:barangay_all:estimation=%d\n', sum(!is.na(ag$turnout) & !is.na(ag$Z))))
ag_akb <- ag[ag$akb == 1, ]
ag_uma <- ag[ag$akb == 0, ]
cat(sprintf('SAMPLE:barangay_akbayan:loaded=%d\n', nrow(ag)))
cat(sprintf('SAMPLE:barangay_akbayan:akbayan_municipalities=%d\n', nrow(ag_akb)))
cat(sprintf('SAMPLE:barangay_umalabka:loaded=%d\n', nrow(ag)))
cat(sprintf('SAMPLE:barangay_umalabka:umalabka_municipalities=%d\n', nrow(ag_uma)))

m1 <- feols(turnout ~ Z | cityf, data = ag)
m2 <- feols(sh_trt ~ Z | cityf, data = ag)
m3 <- feols(sh_akb ~ Z | cityf, data = ag_akb)
m4 <- feols(sh_uma ~ Z | cityf, data = ag_uma)
cat(sprintf('SAMPLE:barangay_akbayan:estimation=%d\n', nobs(m3)))
cat(sprintf('SAMPLE:barangay_umalabka:estimation=%d\n', nobs(m4)))
if (nobs(m1) != 39) cat(sprintf('DEVIATION: barangay sample has %d rows, paper reports 39\n', nobs(m1)))
if (nobs(m3) != 18) cat(sprintf('DEVIATION: Akbayan barangay sample has %d rows, paper reports 18\n', nobs(m3)))
if (nobs(m4) != 21) cat(sprintf('DEVIATION: Umalab Ka barangay sample has %d rows, paper reports 21\n', nobs(m4)))

# CACE (IV)
iv1 <- feols(turnout ~ 1 | cityf | T ~ Z, data = ag)
iv2 <- feols(sh_trt ~ 1 | cityf | T ~ Z, data = ag)
iv3 <- feols(sh_akb ~ 1 | cityf | T ~ Z, data = ag_akb)
iv4 <- feols(sh_uma ~ 1 | cityf | T ~ Z, data = ag_uma)

# permutation p-values (within-municipality re-randomisation)
perm_p <- function(y, z, grp, nperm = 5000) {
  obs <- fe_coef(y, z, grp)
  null <- replicate(nperm, fe_coef(y, perm_within(z, grp), grp))
  mean(abs(null) >= abs(obs) - 1e-12, na.rm = TRUE)
}
p1 <- perm_p(ag$turnout, ag$Z, ag$cityf)
p2 <- perm_p(ag$sh_trt, ag$Z, ag$cityf)
p3 <- perm_p(ag_akb$sh_akb, ag_akb$Z, ag_akb$cityf)
p4 <- perm_p(ag_uma$sh_uma, ag_uma$Z, ag_uma$cityf)

cm <- function(y, z) mean(y[z == 0], na.rm = TRUE)

# ======================================================================
# INDIVIDUAL LEVEL
# ======================================================================
sv <- as.data.frame(survey_raw)
cat(sprintf('SAMPLE:individual:loaded=%d\n', nrow(sv)))
sv$cityf <- as.character(strip_lab(sv$city))
sv$brgy <- as.character(strip_lab(sv$barangay))
sv$Z <- to01(sv$assignment)
sv$T <- to01(sv$treatment)

# party list of the municipality
spt <- as.character(strip_lab(sv$partytreat))
if (any(grepl('akb', tolower(spt)))) {
  sv$akb <- as.integer(grepl('akb', tolower(spt)))
} else if (length(intersect(akb_codes, spt)) > 0) {
  sv$akb <- as.integer(spt %in% akb_codes)
} else {
  akb_cities <- norm_name(ag$cityf[ag$akb == 1])
  sv$akb <- as.integer(norm_name(sv$cityf) %in% akb_cities)
}
sv$akb <- as.integer(ave(sv$akb, sv$cityf, FUN = function(v) mean(v, na.rm = TRUE)) >= 0.5)

# turnout & vote
sv$turn <- to01(if ('turnout_pl' %in% names(sv)) sv$turnout_pl else sv$turnout_all)
va <- to01(sv$vote.akbayan); vu <- to01(sv$vote.umalabka)
sv$vote_trt <- ifelse(sv$akb == 1, va, vu)
if (all(is.na(sv$vote_trt)) && 'vote' %in% names(sv)) sv$vote_trt <- to01(sv$vote)

# restriction 1: valid turnout response
sv1 <- sv[!is.na(sv$turn), ]
cat(sprintf('SAMPLE:individual:valid_turnout=%d\n', nrow(sv1)))
# restriction 2: drop municipalities without both treatment and control survey barangays
excl <- grepl('imus|pateros|santa ?maria|sta\\.? ?maria', tolower(sv1$cityf))
sv2 <- sv1[!excl, ]
cat(sprintf('SAMPLE:individual:exclude_imus_pateros_santamaria=%d\n', nrow(sv2)))
if (nrow(sv1) == 1082) {
  cat('DEVIATION: the stated N=1,082 matches the sample before excluding Imus/Pateros/Santa Maria; those municipalities have no within-city variation in assignment and do not affect the FE estimates\n')
}

# ---------- attendance weights (correct oversampling of meeting attendees) ----------
sv2$att <- to01(sv2$attendance)
ag$bkey <- norm_name(ag$barangay)
attp <- to_num(ag$att.prop)
if (max(attp, na.rm = TRUE) > 1.0001) attp <- attp / 100
pop_att <- setNames(attp, ag$bkey)
sv2$bkey <- norm_name(sv2$brgy)
sv2$w <- 1
for (b in unique(sv2$bkey[sv2$Z == 1])) {
  idx <- which(sv2$bkey == b)
  ps <- mean(sv2$att[idx], na.rm = TRUE)
  pp <- if (b %in% names(pop_att)) pop_att[[b]] else NA
  if (is.na(pp) || is.na(ps) || ps <= 0 || ps >= 1) next
  a <- sv2$att[idx]
  sv2$w[idx] <- ifelse(is.na(a), 1, ifelse(a == 1, pp / ps, (1 - pp) / (1 - ps)))
}

# ---------- unweighted vote choice (Table F.1) ----------
vt <- sv2[sv2$turn == 1 & !is.na(sv2$vote_trt), ]
vt$vote100 <- 100 * vt$vote_trt
vt_akb <- vt[vt$akb == 1, ]
cat(sprintf('SAMPLE:indiv_vote_overall:loaded=%d\n', nrow(sv)))
cat(sprintf('SAMPLE:indiv_vote_overall:valid_turnout=%d\n', nrow(sv1)))
cat(sprintf('SAMPLE:indiv_vote_overall:exclude_imus_pateros_santamaria=%d\n', nrow(sv2)))
cat(sprintf('SAMPLE:indiv_vote_overall:turned_out=%d\n', sum(sv2$turn == 1)))
f1_2 <- feols(vote100 ~ Z | cityf, data = vt, cluster = ~brgy)
cat(sprintf('SAMPLE:indiv_vote_overall:estimation=%d\n', nobs(f1_2)))
cat(sprintf('SAMPLE:indiv_vote_akbayan:loaded=%d\n', nrow(sv)))
cat(sprintf('SAMPLE:indiv_vote_akbayan:valid_turnout=%d\n', nrow(sv1)))
cat(sprintf('SAMPLE:indiv_vote_akbayan:exclude_imus_pateros_santamaria=%d\n', nrow(sv2)))
cat(sprintf('SAMPLE:indiv_vote_akbayan:turned_out=%d\n', sum(sv2$turn == 1)))
cat(sprintf('SAMPLE:indiv_vote_akbayan:akbayan_municipalities=%d\n', sum(sv2$turn == 1 & sv2$akb == 1)))
f1_3 <- feols(vote100 ~ Z | cityf, data = vt_akb, cluster = ~brgy)
cat(sprintf('SAMPLE:indiv_vote_akbayan:estimation=%d\n', nobs(f1_3)))

# barangay-level permutation for individual ITTs
perm_p_ind <- function(d, yvar, nperm = 1000) {
  obs <- fe_coef(d[[yvar]], d$Z, d$cityf)
  bt <- unique(d[, c('brgy', 'cityf', 'Z')])
  null <- replicate(nperm, {
    zp <- perm_within(bt$Z, bt$cityf)
    zi <- zp[match(d$brgy, bt$brgy)]
    fe_coef(d[[yvar]], zi, d$cityf)
  })
  mean(abs(null) >= abs(obs) - 1e-12, na.rm = TRUE)
}
pf2 <- perm_p_ind(vt, 'vote100')
pf3 <- perm_p_ind(vt_akb, 'vote100')

# ---------- Anderson (2008) summary indices ----------
# Mechanism outcomes are survey attitude items: use all respondents in municipalities
# with both treatment and control survey barangays (not only valid-turnout respondents)
svm <- sv[!grepl('imus|pateros|santa ?maria|sta\\.? ?maria', tolower(sv$cityf)), ]
svm$att <- to01(svm$attendance)
svm$bkey <- norm_name(svm$brgy)
svm$w <- 1
for (b in unique(svm$bkey[!is.na(svm$Z) & svm$Z == 1])) {
  idx <- which(svm$bkey == b)
  ps <- mean(svm$att[idx], na.rm = TRUE)
  pp <- if (b %in% names(pop_att)) pop_att[[b]] else NA
  if (is.na(pp) || is.na(ps) || ps <= 0 || ps >= 1) next
  a <- svm$att[idx]
  svm$w[idx] <- ifelse(is.na(a), 1, ifelse(a == 1, pp / ps, (1 - pp) / (1 - ps)))
}
cat('DEVIATION: mechanism indices estimated on all survey respondents (outside Imus/Pateros/Santa Maria), not only those with a valid turnout response\n')

clean_item <- function(x) {
  x <- to_num(x)
  sm <- x[!is.na(x) & x < 8]
  if (length(sm) > 0 && mean(x >= 8, na.rm = TRUE) < 0.3 && max(sm) <= 7) x[!is.na(x) & x >= 8] <- NA
  x
}
anderson_index <- function(d, items) {
  X <- as.matrix(sapply(items, function(v) clean_item(d[[v]])))
  ctrl <- !is.na(d$Z) & d$Z == 0
  Zs <- X
  for (j in seq_len(ncol(X))) {
    mu <- mean(X[ctrl, j], na.rm = TRUE); s <- sd(X[ctrl, j], na.rm = TRUE)
    Zs[, j] <- (X[, j] - mu) / s
  }
  # orient items so that positive = more agreement with the index direction:
  # flip any item negatively correlated with the sum of the others
  if (ncol(Zs) > 1) {
    for (j in seq_len(ncol(Zs))) {
      rest <- rowSums(Zs[, -j, drop = FALSE], na.rm = TRUE)
      cr <- suppressWarnings(cor(Zs[, j], rest, use = 'pairwise.complete.obs'))
      if (!is.na(cr) && cr < 0) {
        Zs[, j] <- -Zs[, j]
        cat(sprintf('DEVIATION: item %s reverse-oriented (negatively correlated with other index items)\n', items[j]))
      }
    }
  }
  S <- cov(Zs, use = 'pairwise.complete.obs')
  Sinv <- tryCatch(solve(S), error = function(e) MASS::ginv(S))
  wts <- rowSums(Sinv)
  idx <- apply(Zs, 1, function(r) {
    ok <- !is.na(r)
    if (!any(ok)) return(NA_real_)
    sum(wts[ok] * r[ok]) / sum(wts[ok])
  })
  (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
}
pov_items <- intersect(c('poverty', 'gap', 'cct', 'corruption'), names(svm))
gen_cand <- c('femrep', 'femhouse', 'fempol', 'equality', 'discrimination', 'harassment')
gen_items <- intersect(gen_cand, names(svm))
extra_gen <- setdiff(grep('^fem|equal|discrim|harass', names(svm), value = TRUE, ignore.case = TRUE), gen_items)
extra_gen <- extra_gen[sapply(extra_gen, function(v) { x <- suppressWarnings(to_num(svm[[v]])); sum(!is.na(x)) > 100 && length(unique(x[!is.na(x)])) > 1 && length(unique(x[!is.na(x)])) <= 12 })]
if (length(gen_items) < 6 && length(extra_gen) > 0) gen_items <- c(gen_items, head(extra_gen, 6 - length(gen_items)))
cat(sprintf('DEVIATION: gender index items used: %s\n', paste(gen_items, collapse = ',')))

run_index <- function(party_flag, items, label) {
  d <- svm[svm$akb == party_flag, ]
  d$idx <- anderson_index(d, items)
  cat(sprintf('SAMPLE:%s:loaded=%d\n', label, nrow(sv)))
  cat(sprintf('SAMPLE:%s:exclude_imus_pateros_santamaria=%d\n', label, nrow(svm)))
  cat(sprintf('SAMPLE:%s:party_municipalities=%d\n', label, nrow(d)))
  m <- feols(idx ~ Z | cityf, data = d, weights = ~w, cluster = ~brgy)
  cat(sprintf('SAMPLE:%s:estimation=%d\n', label, nobs(m)))
  m
}
mpa <- run_index(1, pov_items, 'poverty_index_akbayan')
mpu <- run_index(0, pov_items, 'poverty_index_umalabka')
mga <- run_index(1, gen_items, 'gender_index_akbayan')
mgu <- run_index(0, gen_items, 'gender_index_umalabka')

# ======================================================================
# RESULTS
# ======================================================================
r <- function(name, val) cat(sprintf('RESULT:%s=%.6f\n', name, val))
r('itt_turnout_barangay_table1_col1', coef(m1)['Z'])
r('itt_vote_overall_barangay_table1_col2', coef(m2)['Z'])
r('itt_vote_akbayan_barangay_table1_col3', coef(m3)['Z'])
r('itt_vote_umalabka_barangay_table1_col4', coef(m4)['Z'])
r('n_obs_barangay_table1_cols1_2', nobs(m1))
r('n_obs_barangay_akbayan_table1_col3', nobs(m3))
r('n_obs_barangay_umalabka_table1_col4', nobs(m4))
r('perm_p_turnout_barangay_table1_col1', p1)
r('perm_p_vote_overall_barangay_table1_col2', p2)
r('perm_p_vote_akbayan_barangay_table1_col3', p3)
r('perm_p_vote_umalabka_barangay_table1_col4', p4)
r('control_mean_turnout_barangay', cm(ag$turnout, ag$Z))
r('control_mean_vote_overall_barangay', cm(ag$sh_trt, ag$Z))
r('control_mean_vote_akbayan_barangay', cm(ag_akb$sh_akb, ag_akb$Z))
r('control_mean_vote_umalabka_barangay', cm(ag_uma$sh_uma, ag_uma$Z))
r('r2_turnout_barangay_table1_col1', r2(m1, 'r2'))
r('r2_vote_overall_barangay_table1_col2', r2(m2, 'r2'))
r('r2_vote_akbayan_barangay_table1_col3', r2(m3, 'r2'))
r('r2_vote_umalabka_barangay_table1_col4', r2(m4, 'r2'))
r('cace_turnout_barangay_table1_col1', coef(iv1)['fit_T'])
r('cace_vote_overall_barangay_table1_col2', coef(iv2)['fit_T'])
r('cace_vote_akbayan_barangay_table1_col3', coef(iv3)['fit_T'])
r('cace_vote_umalabka_barangay_table1_col4', coef(iv4)['fit_T'])
r('itt_poverty_index_akbayan_tableC3', coef(mpa)['Z'])
r('itt_poverty_index_akbayan_tableC3_se', sqrt(diag(vcov(mpa)))['Z'])
r('itt_poverty_index_umalabka_tableC3', coef(mpu)['Z'])
r('itt_poverty_index_umalabka_tableC3_se', sqrt(diag(vcov(mpu)))['Z'])
r('itt_gender_index_akbayan_tableC4', coef(mga)['Z'])
r('itt_gender_index_akbayan_tableC4_se', sqrt(diag(vcov(mga)))['Z'])
r('itt_gender_index_umalabka_tableC4', coef(mgu)['Z'])
r('itt_gender_index_umalabka_tableC4_se', sqrt(diag(vcov(mgu)))['Z'])
r('itt_vote_overall_unweighted_tableF1_col2', coef(f1_2)['Z'])
r('perm_p_vote_overall_unweighted_tableF1_col2', pf2)
r('itt_vote_akbayan_unweighted_tableF1_col3', coef(f1_3)['Z'])
r('perm_p_vote_akbayan_unweighted_tableF1_col3', pf3)