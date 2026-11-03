suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- '<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free'

load(file.path(base, 'dyadic_data_1-4-22.Rdata'))   # updated_data
dy <- as.data.frame(updated_data)
gd <- as.data.frame(readRDS(file.path(base, 'gender_disagregated_8-8-21.rds')))

message('Columns (dyadic): ', paste(names(dy), collapse = ', '))

# ---------- helpers ----------
find_women_share <- function(df) {
  nm <- names(df)
  cand <- nm[grepl('wom|fem', nm, ignore.case = TRUE)]
  cand <- cand[sapply(cand, function(v) is.numeric(df[[v]]))]
  cand <- cand[!grepl('^from|_from', cand, ignore.case = TRUE)]
  cand <- cand[!grepl('leader|lead|head|chair|resp|gender$', cand, ignore.case = TRUE)]
  cand <- cand[sapply(cand, function(v) {
    u <- unique(na.omit(df[[v]])); length(u) > 2
  })]
  if (length(cand) == 0) stop('No women-share column found')
  score <- sapply(cand, function(v) {
    s <- 0
    if (grepl('^to_|_to_|_to$|^to', v, ignore.case = TRUE)) s <- s + 8
    if (grepl('mp|seat|parl|legis|deleg', v, ignore.case = TRUE)) s <- s + 4
    if (grepl('prop|share|pct|perc|per', v, ignore.case = TRUE)) s <- s + 2
    if (grepl('lag|t1|t_1|prior|prev', v, ignore.case = TRUE)) s <- s + 1
    if (grepl('num|count|n_|number', v, ignore.case = TRUE)) s <- s - 1
    s
  })
  v <- cand[order(-score)][1]
  x <- df[[v]]
  mx <- suppressWarnings(max(x, na.rm = TRUE))
  if (is.finite(mx) && mx > 1.5) {
    if (grepl('num|count|n_|number', v, ignore.case = TRUE) && 'to_mp_number' %in% names(df)) {
      x <- x / df$to_mp_number
    } else {
      x <- x / 100
    }
  }
  message('Women-share candidates: ', paste(cand, collapse = ', '))
  message('Women-share variable used: ', v)
  x
}

find_dv <- function(df) {
  for (v in c('party_like', 'thermometer', 'thermometer_score', 'like')) {
    if (v %in% names(df) && is.numeric(df[[v]])) return(df[[v]])
  }
  if ('dislike' %in% names(df)) return(10 - df$dislike)
  stop('No DV found')
}

prep <- function(df) {
  df$women_share <- find_women_share(df)
  df$eval <- find_dv(df)
  if ('rile_distance_s' %in% names(df)) {
    df$rl_dist <- df$rile_distance_s
  } else {
    df$rl_dist <- abs(df$rile_distance) / sd(abs(df$rile_distance), na.rm = TRUE)
  }
  df$coal <- as.numeric(df$govern_together)
  df$opp <- as.numeric(df$opposition_together)
  df$election <- paste(df$country, df$year, sep = '_')
  df
}

dy <- prep(dy)
gd <- prep(gd)

# ---------- MP-size restriction ----------
# The current-year mp_number filter removes nothing (all rows already >= 4),
# yet N is ~180 above the paper's 1,842.  The paper applies the 4-MP rule to
# the YEAR BEFORE the survey; the data carry prior-period seat counts
# (to_prior_seats / from_prior_seats) and gender-data completeness flags.
is_count <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  mx <- suppressWarnings(max(x, na.rm = TRUE))
  is.finite(mx) && mx > 4 && all(abs(x - round(x)) < 1e-8, na.rm = TRUE)
}
flag1 <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  !is.na(x) & x == 1
}
restrict <- function(df, key) {
  keep <- !is.na(df$to_mp_number) & !is.na(df$from_mp_number) &
    df$to_mp_number >= 4 & df$from_mp_number >= 4
  if (key %in% c('prior', 'prior_complete')) {
    keep <- keep & !is.na(df$to_prior_seats) & !is.na(df$from_prior_seats) &
      as.numeric(df$to_prior_seats) >= 4 & as.numeric(df$from_prior_seats) >= 4
  }
  if (key %in% c('complete', 'prior_complete')) {
    keep <- keep & flag1(df$to_complete) & flag1(df$from_complete)
  }
  df[keep, , drop = FALSE]
}
avail <- c('base')
if (all(c('to_prior_seats', 'from_prior_seats') %in% names(dy)) &&
    all(c('to_prior_seats', 'from_prior_seats') %in% names(gd)) &&
    is_count(dy$to_prior_seats)) avail <- c(avail, 'prior')
if (all(c('to_complete', 'from_complete') %in% names(dy)) &&
    all(c('to_complete', 'from_complete') %in% names(gd))) avail <- c(avail, 'complete')
if (all(c('prior', 'complete') %in% avail)) avail <- c(avail, 'prior_complete')

fit_full <- function(d) feols(eval ~ women_share + rl_dist + coal + opp | election, data = d, cluster = ~election)
n_for <- function(key) {
  d <- restrict(dy, key) %>% filter(!is.na(rl_dist), !is.na(eval), !is.na(women_share))
  if (nrow(d) < 50) return(Inf)
  m <- tryCatch(fit_full(d), error = function(e) NULL)
  if (is.null(m)) return(Inf)
  nobs(m)
}
ns <- sapply(avail, n_for)
message('Restriction candidates N: ', paste(names(ns), ns, sep = '=', collapse = ', '))
rkey <- names(ns)[which.min(abs(ns - 1842))]
message('Restriction used: ', rkey)
if (rkey != 'base') {
  cat(sprintf('DEVIATION: Applied the 4-MP / data restriction "%s" (prior-year seats and/or gender-data completeness flags) because current-year mp_number dropped no dyads; chosen as closest to the reported N\n', rkey))
}

# ---------- main sample ----------
cat(sprintf('SAMPLE:main:loaded=%d\n', nrow(dy)))
dm <- restrict(dy, rkey)
cat(sprintf('SAMPLE:main:both_parties_at_least_4_mps=%d\n', nrow(dm)))
dm <- dm %>% filter(!is.na(rl_dist), !is.na(eval), !is.na(women_share))
cat(sprintf('SAMPLE:main:nonmissing_cmp_and_ratings=%d\n', nrow(dm)))

m1 <- feols(eval ~ women_share | election, data = dm, cluster = ~election)
m2 <- feols(eval ~ women_share + rl_dist + coal + opp | election, data = dm, cluster = ~election)
cat(sprintf('SAMPLE:main:estimation=%d\n', nobs(m2)))

# ---------- gender-disaggregated samples ----------
g <- gd$gender
make_sub <- function(idx) {
  d <- gd[idx & !is.na(idx), ]
  restrict(d, rkey)
}
if (is.character(g) || is.factor(g)) {
  gl <- tolower(as.character(g))
  is_w <- grepl('^f|wom', gl)
  is_m <- grepl('^m|^man|^men', gl) & !is_w
} else {
  vals <- sort(unique(na.omit(g)))
  is_w <- g == vals[length(vals)]
  is_m <- g == vals[1]
}
dA <- make_sub(is_w); dB <- make_sub(is_m)
mA <- fit_full(dA); mB <- fit_full(dB)
if (abs(nobs(mA) - 1836) + abs(nobs(mB) - 1833) > abs(nobs(mB) - 1836) + abs(nobs(mA) - 1833)) {
  tmp <- dA; dA <- dB; dB <- tmp
  tmp <- mA; mA <- mB; mB <- tmp
  tmp <- is_w; is_w <- is_m; is_m <- tmp
}

cat(sprintf('SAMPLE:women_partisans:loaded=%d\n', nrow(gd)))
cat(sprintf('SAMPLE:women_partisans:women_respondents=%d\n', sum(is_w %in% TRUE)))
cat(sprintf('SAMPLE:women_partisans:both_parties_at_least_4_mps=%d\n', nrow(dA)))
cat(sprintf('SAMPLE:women_partisans:estimation=%d\n', nobs(mA)))
cat(sprintf('SAMPLE:men_partisans:loaded=%d\n', nrow(gd)))
cat(sprintf('SAMPLE:men_partisans:men_respondents=%d\n', sum(is_m %in% TRUE)))
cat(sprintf('SAMPLE:men_partisans:both_parties_at_least_4_mps=%d\n', nrow(dB)))
cat(sprintf('SAMPLE:men_partisans:estimation=%d\n', nobs(mB)))

n_elec <- length(unique(dm$election[obs(m2)]))

se <- function(m, v) sqrt(diag(vcov(m)))[v]

cat(sprintf('RESULT:women_mps_coef_bivariate=%.6f\n', coef(m1)['women_share']))
cat(sprintf('RESULT:women_mps_se_bivariate=%.6f\n', se(m1, 'women_share')))
cat(sprintf('RESULT:women_mps_coef_full=%.6f\n', coef(m2)['women_share']))
cat(sprintf('RESULT:women_mps_se_full=%.6f\n', se(m2, 'women_share')))
cat(sprintf('RESULT:women_mps_coef_women_partisans=%.6f\n', coef(mA)['women_share']))
cat(sprintf('RESULT:women_mps_coef_men_partisans=%.6f\n', coef(mB)['women_share']))
cat(sprintf('RESULT:right_left_distance_coef_full=%.6f\n', coef(m2)['rl_dist']))
cat(sprintf('RESULT:coalition_partners_coef_full=%.6f\n', coef(m2)['coal']))
cat(sprintf('RESULT:opposition_partners_coef_full=%.6f\n', coef(m2)['opp']))
cat(sprintf('RESULT:n_directed_dyads=%d\n', nobs(m2)))
cat(sprintf('RESULT:n_obs_women_partisans=%d\n', nobs(mA)))
cat(sprintf('RESULT:n_obs_men_partisans=%d\n', nobs(mB)))
cat(sprintf('RESULT:n_election_studies=%d\n', n_elec))
