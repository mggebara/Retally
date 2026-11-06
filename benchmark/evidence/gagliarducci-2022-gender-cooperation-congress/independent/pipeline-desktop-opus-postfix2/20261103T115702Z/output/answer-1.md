suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- '<repo>/.cache/datasets/gagliarducci_2022_gender_cooperation_congress.script-free'
path <- file.path(root, '3 replication package/Data/AnalysisData/bills_analysis_101-111_replication.csv')
df <- as.data.frame(read_csv(path, show_col_types = FALSE, guess_max = 100000))
nm <- names(df)

tonum <- function(x) suppressWarnings(as.numeric(as.character(x)))
to01 <- function(x) {
  if (is.numeric(x) || is.logical(x)) return(as.numeric(x))
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_real_, length(s))
  out[s %in% c('1', 'yes', 'true', 'female', 'y')] <- 1
  out[s %in% c('0', 'no', 'false', 'male', 'n')] <- 0
  num <- suppressWarnings(as.numeric(s))
  out[is.na(out) & !is.na(num)] <- num[is.na(out) & !is.na(num)]
  out
}
findcol <- function(patterns, exclude = NULL) {
  for (p in patterns) {
    h <- nm[grepl(p, nm, ignore.case = TRUE)]
    if (!is.null(exclude)) h <- h[!grepl(exclude, h, ignore.case = TRUE)]
    if (length(h)) return(h[1])
  }
  NA_character_
}

cat(sprintf('SAMPLE:main:loaded=%d\n', nrow(df)))

# ---------------- basic variables ----------------
df$v2 <- tonum(df$v2)
df$female <- to01(df$sponsor_female)
party_raw <- df$sponsor_party
if (is.numeric(party_raw)) {
  df$dem <- as.numeric(party_raw == 100)
  df$rep <- as.numeric(party_raw == 200)
} else {
  s <- tolower(trimws(as.character(party_raw)))
  df$dem <- as.numeric(grepl('^dem|^d$|^100$', s))
  df$rep <- as.numeric(grepl('^rep|^r$|^200$', s))
}
df$cl <- paste(df$v2, df$sponsor_state_abbrev, df$sponsor_district, df$sponsor_term_served, sep = '_')
df$minor_f <- as.character(df$minor)

# Sample restrictions: Congresses 101-111, public bills only
df <- df[!is.na(df$v2) & df$v2 >= 101 & df$v2 <= 111, ]
cat(sprintf('SAMPLE:main:congress_101_111=%d\n', nrow(df)))
if ('private' %in% nm) {
  pv <- to01(df$private)
  df <- df[is.na(pv) | pv == 0, ]
}
cat(sprintf('SAMPLE:main:public_bills=%d\n', nrow(df)))

# Outcomes
df$ncosp <- tonum(df$numb_cosponsors)
if ('pct_cosponsors_opposite' %in% nm) {
  df$pctopp <- tonum(df$pct_cosponsors_opposite)
  if (max(df$pctopp, na.rm = TRUE) <= 1.0001) df$pctopp <- 100 * df$pctopp
} else {
  df$pctopp <- 100 * tonum(df$numb_cosponsors_opposite) / (df$ncosp + 1)
}

# Committee of referral dummies
comm <- nm[grepl('^house_', nm)]
comm_keep <- c()
for (cc in comm) {
  x <- to01(df[[cc]]); x[is.na(x)] <- 0
  if (length(unique(x)) > 1) { df[[cc]] <- x; comm_keep <- c(comm_keep, cc) }
}

# Sponsor characteristics
df$age <- tonum(df$sponsor_age)
df$tenure <- tonum(df$sponsor_tenure_run)
rk <- findcol(c('rookie'), exclude = 'cosponsor')
df$rookie <- if (!is.na(rk)) to01(df[[rk]]) else as.numeric(df$tenure == 1)
comc <- if ('comc' %in% nm) tonum(df$comc) else 0
comr <- if ('comr' %in% nm) tonum(df$comr) else 0
comc[is.na(comc)] <- 0; comr[is.na(comr)] <- 0
df$leader <- as.numeric(comc > 0 | comr > 0)
df$ivy <- if ('ivycoll' %in% nm) to01(df$ivycoll) else NA
df$blk <- to01(df$black)
df$born <- if ('borninstate' %in% nm) to01(df$borninstate) else NA
occs <- nm[grepl('^occ[0-9]+$', nm)]
for (o in occs) df[[o]] <- to01(df[[o]])
occs_use <- if (length(occs) > 1) occs[-1] else occs
df <- df %>% group_by(cl) %>% mutate(nbills = n()) %>% ungroup() %>% as.data.frame()
spons_vars <- c('age', 'tenure', 'rookie', 'leader', 'ivy', 'blk', occs_use, 'nbills')
if (!all(is.na(df$born))) spons_vars <- c(spons_vars, 'born') else cat('DEVIATION: born-in-state variable not found\n')
if (all(is.na(df$ivy))) { spons_vars <- setdiff(spons_vars, 'ivy'); cat('DEVIATION: Ivy League variable not found\n') }

# District characteristics
ab <- toupper(as.character(df$sponsor_state_abbrev))
reg <- as.character(state.region[match(ab, state.abb)])
reg[ab == 'DC'] <- 'South'
df$reg_ne <- as.numeric(reg == 'Northeast')
df$reg_mw <- as.numeric(reg == 'North Central')
df$reg_s  <- as.numeric(reg == 'South')
df$d_black <- tonum(df$pct_black)
df$d_urban <- tonum(df$pct_urban)
df$d_forb  <- tonum(df$pct_for_born)
distr_vars <- c('reg_ne', 'reg_mw', 'reg_s', 'd_black', 'd_urban', 'd_forb')
c65 <- findcol(c('pct_65', 'over65', '65plus', 'pct_old', 'age65', 'pct_elder', '65'), exclude = 'cosp')
if (!is.na(c65)) { df$d_65 <- tonum(df[[c65]]); distr_vars <- c(distr_vars, 'd_65') } else cat('DEVIATION: % over 65 not found in data\n')
cinc <- findcol(c('medinc', 'median_inc', 'income'), exclude = 'cosp')
if (!is.na(cinc)) {
  x <- tonum(df[[cinc]])
  df$d_linc <- if (grepl('log|ln', cinc, ignore.case = TRUE) || max(x, na.rm = TRUE) < 30) x else log(x)
  distr_vars <- c(distr_vars, 'd_linc')
} else cat('DEVIATION: median income not found in data\n')
cden <- findcol(c('popdens', 'density'), exclude = 'cosp')
if (!is.na(cden)) {
  x <- tonum(df[[cden]])
  df$d_lden <- if (grepl('log|ln', cden, ignore.case = TRUE)) x else log(pmax(x, 1e-6))
  distr_vars <- c(distr_vars, 'd_lden')
} else cat('DEVIATION: population density not found in data\n')

# ---------------- helpers ----------------
mkf <- function(y, rhs, fe) as.formula(paste0(y, ' ~ ', paste(rhs, collapse = ' + '), ' | ', fe))
getb <- function(m) unname(coef(m)['female'])

ols_full <- function(d, y, pooled) {
  rhs <- c('female', comm_keep, spons_vars, distr_vars)
  if (pooled) rhs <- c(rhs, 'rep')
  feols(mkf(y, rhs, 'v2 + minor_f'), data = d, cluster = ~cl)
}

ps_weights <- function(d, vars) {
  s <- d[!duplicated(d$cl), c('cl', 'female', vars)]
  s <- s[complete.cases(s), ]
  keep <- vars[sapply(vars, function(v) length(unique(s[[v]])) > 1)]
  fit <- glm(as.formula(paste('female ~', paste(keep, collapse = ' + '))), family = binomial(), data = s)
  p <- predict(fit, newdata = s, type = 'response')
  p <- pmin(pmax(p, 1e-4), 1 - 1e-4)
  w <- ifelse(s$female == 1, 1 / p, 1 / (1 - p))
  w[match(d$cl, s$cl)]
}

ipw_reg <- function(d, y, w) {
  d$w <- w
  d <- d[!is.na(d$w), ]
  feols(mkf(y, c('female', comm_keep), 'v2 + minor_f'), data = d, weights = ~w, cluster = ~cl)
}

# RD variables
df$mv <- tonum(df$MV1_female)
mv_scale <- if (max(abs(df$mv), na.rm = TRUE) > 1.5) 1 else 0.01
df$femXmv <- df$female * df$mv
df$mixed <- to01(df$mixed_gender_election)
df$mv_elected <- abs(tonum(df$MV1_democrat))

rd_reg <- function(d, y, h, ipw, nmS) {
  r <- d[!is.na(d$mixed) & d$mixed == 1 & !is.na(d$mv), ]
  cat(sprintf('SAMPLE:%s:mixed_gender_election=%d\n', nmS, nrow(r)))
  r <- r[abs(r$mv) <= h * mv_scale, ]
  cat(sprintf('SAMPLE:%s:within_bandwidth=%d\n', nmS, nrow(r)))
  if (!ipw) {
    m <- feols(mkf(y, c('female', 'mv', 'femXmv'), 'v2'), data = r, cluster = ~cl)
  } else {
    r$w <- ps_weights(r, distr_vars)
    r <- r[!is.na(r$w), ]
    m <- feols(mkf(y, c('female', 'mv', 'femXmv', comm_keep), 'v2 + minor_f'), data = r, weights = ~w, cluster = ~cl)
  }
  cat(sprintf('SAMPLE:%s:estimation=%d\n', nmS, nobs(m)))
  m
}

dem_d <- df[df$dem == 1, ]
rep_d <- df[df$rep == 1, ]

# ---------------- Panel A: number of cosponsors ----------------
cat(sprintf('SAMPLE:A_all_ols:loaded=%d\n', nrow(df)))
mA_all <- ols_full(df, 'ncosp', TRUE)
cat(sprintf('SAMPLE:A_all_ols:estimation=%d\n', nobs(mA_all)))

cat(sprintf('SAMPLE:A_rep_ols:republican_sponsor=%d\n', nrow(rep_d)))
mA_rep <- ols_full(rep_d, 'ncosp', FALSE)
cat(sprintf('SAMPLE:A_rep_ols:estimation=%d\n', nobs(mA_rep)))

cat(sprintf('SAMPLE:A_rep_rd_ipw:republican_sponsor=%d\n', nrow(rep_d)))
mA_rep_rd <- rd_reg(rep_d, 'ncosp', 13, TRUE, 'A_rep_rd_ipw')

cat(sprintf('SAMPLE:A_rep_ipw_sponsor:republican_sponsor=%d\n', nrow(rep_d)))
wA5 <- ps_weights(rep_d, c(distr_vars, 'mv_elected', spons_vars))
mA_rep_ipw5 <- ipw_reg(rep_d, 'ncosp', wA5)
cat(sprintf('SAMPLE:A_rep_ipw_sponsor:estimation=%d\n', nobs(mA_rep_ipw5)))

# ---------------- Panel B: percent opposite party ----------------
cat(sprintf('SAMPLE:B_dem_ols:democratic_sponsor=%d\n', nrow(dem_d)))
mB_dem <- ols_full(dem_d, 'pctopp', FALSE)
cat(sprintf('SAMPLE:B_dem_ols:estimation=%d\n', nobs(mB_dem)))

cat(sprintf('SAMPLE:B_dem_rd:democratic_sponsor=%d\n', nrow(dem_d)))
mB_dem_rd <- rd_reg(dem_d, 'pctopp', 24, FALSE, 'B_dem_rd')

cat(sprintf('SAMPLE:B_dem_ipw_sponsor:democratic_sponsor=%d\n', nrow(dem_d)))
wB5 <- ps_weights(dem_d, c(distr_vars, 'mv_elected', spons_vars))
mB_dem_ipw5 <- ipw_reg(dem_d, 'pctopp', wB5)
cat(sprintf('SAMPLE:B_dem_ipw_sponsor:estimation=%d\n', nobs(mB_dem_ipw5)))

cat(sprintf('SAMPLE:B_rep_ols:republican_sponsor=%d\n', nrow(rep_d)))
mB_rep <- ols_full(rep_d, 'pctopp', FALSE)
cat(sprintf('SAMPLE:B_rep_ols:estimation=%d\n', nobs(mB_rep)))

cat(sprintf('SAMPLE:B_rep_ipw_district:republican_sponsor=%d\n', nrow(rep_d)))
wB4 <- ps_weights(rep_d, c(distr_vars, 'mv_elected'))
mB_rep_ipw4 <- ipw_reg(rep_d, 'pctopp', wB4)
cat(sprintf('SAMPLE:B_rep_ipw_district:estimation=%d\n', nobs(mB_rep_ipw4)))

# ---------------- Results ----------------
ncl <- function(m, d) {
  used <- d$cl[obs(m)]
  length(unique(used))
}

cat(sprintf('RESULT:female_sponsor_ncosponsors_all_ols=%.6f\n', getb(mA_all)))
cat(sprintf('RESULT:female_sponsor_ncosponsors_rep_ols=%.6f\n', getb(mA_rep)))
cat(sprintf('RESULT:female_sponsor_ncosponsors_rep_rd_ipw=%.6f\n', getb(mA_rep_rd)))
cat(sprintf('RESULT:female_sponsor_ncosponsors_rep_ipw_sponsor=%.6f\n', getb(mA_rep_ipw5)))
cat(sprintf('RESULT:female_sponsor_pct_opposite_dem_ols=%.6f\n', getb(mB_dem)))
cat(sprintf('RESULT:female_sponsor_pct_opposite_dem_rd=%.6f\n', getb(mB_dem_rd)))
cat(sprintf('RESULT:female_sponsor_pct_opposite_dem_ipw_sponsor=%.6f\n', getb(mB_dem_ipw5)))
cat(sprintf('RESULT:female_sponsor_pct_opposite_rep_ols=%.6f\n', getb(mB_rep)))
cat(sprintf('RESULT:female_sponsor_pct_opposite_rep_ipw_district=%.6f\n', getb(mB_rep_ipw4)))
cat(sprintf('RESULT:n_bills_ncosponsors_all_ols=%d\n', nobs(mA_all)))
cat(sprintf('RESULT:n_sponsor_terms_ncosponsors_all_ols=%d\n', ncl(mA_all, df)))
cat(sprintf('RESULT:n_bills_pct_opposite_dem_ols=%d\n', nobs(mB_dem)))
cat(sprintf('RESULT:n_bills_pct_opposite_rep_ols=%d\n', nobs(mB_rep)))
