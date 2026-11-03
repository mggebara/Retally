suppressPackageStartupMessages({
  library(haven)
})
set.seed(42)

base <- '<repo>/.cache/datasets/manekin_2022_effective_for_whom.script-free/Replication/Data'
load(file.path(base, 'us_survey_wave1.rdata'))
load(file.path(base, 'isr_survey_wave1.rdata'))
load(file.path(base, 'us_survey_wave2.rdata'))
load(file.path(base, 'isr_survey_wave2.rdata'))

as_chr <- function(x) {
  if (inherits(x, 'haven_labelled')) x <- haven::as_factor(x)
  tolower(trimws(as.character(x)))
}
to_num <- function(x) {
  if (inherits(x, 'haven_labelled')) x <- zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  suppressWarnings(as.numeric(x))
}

# Generic binary dummy: 1 = "treated" level
to_dummy <- function(x, pos_pattern = NULL, neg_pattern = NULL) {
  if (is.logical(x)) return(as.numeric(x))
  if (inherits(x, 'haven_labelled')) {
    v <- as.numeric(zap_labels(x))
    if (all(v %in% c(0, 1, NA))) return(v)
    x <- haven::as_factor(x)
  }
  if (is.numeric(x)) {
    u <- sort(unique(x[!is.na(x)]))
    if (all(u %in% c(0, 1))) return(as.numeric(x))
    return(as.numeric(x == max(u)))
  }
  s <- as_chr(x)
  num <- suppressWarnings(as.numeric(s))
  if (all(is.na(s) | !is.na(num))) {
    u <- sort(unique(num[!is.na(num)]))
    return(as.numeric(num == max(u)))
  }
  out <- rep(NA_real_, length(s))
  if (!is.null(neg_pattern)) {
    neg <- grepl(neg_pattern, s)
    out[!is.na(s)] <- ifelse(neg[!is.na(s)], 0, 1)
    if (!is.null(pos_pattern)) {
      pos <- grepl(pos_pattern, s)
      out[!is.na(s) & !neg & !pos] <- NA
    }
    if (any(!is.na(out)) && length(unique(out[!is.na(out)])) == 2) return(out)
  }
  if (!is.null(pos_pattern)) {
    out <- ifelse(is.na(s), NA, as.numeric(grepl(pos_pattern, s)))
    if (length(unique(out[!is.na(out)])) == 2) return(out)
  }
  lv <- if (is.factor(x)) levels(droplevels(x)) else sort(unique(s[!is.na(s)]))
  lv <- tolower(lv)
  as.numeric(s == lv[length(lv)])
}

# Tactic coding: returns list(traffic, destroy)
tactic_dummies <- function(x) {
  s <- as_chr(x)
  num <- suppressWarnings(as.numeric(s))
  if (all(is.na(s) | !is.na(num))) {
    u <- sort(unique(num[!is.na(num)]))
    return(list(traffic = as.numeric(num == u[2]), destroy = as.numeric(num == u[3])))
  }
  destroy <- grepl('destroy|damag|propert|police car|garbage|violen|smash|burn', s)
  traffic <- grepl('traffic|shut|block|disrupt|road', s) & !destroy
  list(traffic = ifelse(is.na(s), NA, as.numeric(traffic)),
       destroy = ifelse(is.na(s), NA, as.numeric(destroy)))
}

get_weight <- function(df) {
  if ('weight' %in% names(df)) {
    w <- to_num(df$weight)
    return(w)
  }
  rep(1, nrow(df))
}

fit <- function(formula, df, w = NULL) {
  if (is.null(w)) lm(formula, data = df) else lm(formula, data = df, weights = w)
}

## ---------------- Study 1 US ----------------
us1 <- us_survey_wave1
cat(sprintf('SAMPLE:study1_us:loaded=%d\n', nrow(us1)))
id1 <- as_chr(us1$identity_protesters)
num_id1 <- suppressWarnings(as.numeric(id1))
if (all(is.na(id1) | !is.na(num_id1))) {
  us1$black_p <- as.numeric(num_id1 == max(num_id1, na.rm = TRUE))
} else {
  us1$black_p <- ifelse(is.na(id1), NA, as.numeric(grepl('black|tyrone|african', id1)))
}
td <- tactic_dummies(us1$tactic)
us1$traffic <- td$traffic
us1$destroy <- td$destroy
us1$degree_violence <- to_num(us1$degree_violence)
us1$police_action_required <- to_num(us1$police_action_required)
us1$w <- get_weight(us1)
if (all(is.na(us1$w))) us1$w <- 1

m_us1_v <- fit(degree_violence ~ black_p + traffic + destroy, us1, us1$w)
m_us1_p <- fit(police_action_required ~ black_p + traffic + destroy, us1, us1$w)
cat(sprintf('SAMPLE:study1_us:estimation=%d\n', nobs(m_us1_v)))
cat(sprintf('SAMPLE:study1_us_police:loaded=%d\n', nrow(us1)))
cat(sprintf('SAMPLE:study1_us_police:estimation=%d\n', nobs(m_us1_p)))

## ---------------- Study 1 Israel ----------------
is1 <- isr_survey_wave1
cat(sprintf('SAMPLE:study1_israel:loaded=%d\n', nrow(is1)))
idi <- as_chr(is1$identity_protesters)
num_idi <- suppressWarnings(as.numeric(idi))
if (all(is.na(idi) | !is.na(num_idi))) {
  u <- sort(unique(num_idi[!is.na(num_idi)]))
  # assume 1 = white, 2 = Ethiopian, 3 = Arab
  is1$eth_p <- as.numeric(num_idi == u[2])
  is1$arab_p <- as.numeric(num_idi == u[3])
} else {
  is1$eth_p <- ifelse(is.na(idi), NA, as.numeric(grepl('ethiop', idi)))
  is1$arab_p <- ifelse(is.na(idi), NA, as.numeric(grepl('arab', idi)))
}
td <- tactic_dummies(is1$tactic)
is1$traffic <- td$traffic
is1$destroy <- td$destroy
is1$degree_violence <- to_num(is1$degree_violence)
is1$police_action_required <- to_num(is1$police_action_required)
is1$w <- get_weight(is1)
if (all(is.na(is1$w))) is1$w <- 1

m_is1_v <- fit(degree_violence ~ eth_p + arab_p + traffic + destroy, is1, is1$w)
m_is1_p <- fit(police_action_required ~ eth_p + arab_p + traffic + destroy, is1, is1$w)
cat(sprintf('SAMPLE:study1_israel:estimation=%d\n', nobs(m_is1_v)))
cat(sprintf('SAMPLE:study1_israel_police:loaded=%d\n', nrow(is1)))
cat(sprintf('SAMPLE:study1_israel_police:estimation=%d\n', nobs(m_is1_p)))

## ---------------- Study 2 US ----------------
us2 <- us_survey_wave2
cat(sprintf('SAMPLE:study2_us:loaded=%d\n', nrow(us2)))
us2$black_p <- to_dummy(us2$black, pos_pattern = 'black|yes|^1$', neg_pattern = 'white|^no$|^0$')
us2$goal <- to_dummy(us2$group_goal, pos_pattern = 'minor|group|racis|police|brutal|yes|^1$',
                     neg_pattern = 'general|layoff|^no$|^0$')
us2$commit <- to_dummy(us2$commitment, pos_pattern = 'yes|commit|nonviol|^1$',
                       neg_pattern = '^no|without|none|^0$')
us2$degree_violence <- to_num(us2$degree_violence)
us2$police_action_required <- to_num(us2$police_action_required)

m_us2_v <- lm(degree_violence ~ black_p + goal + commit, data = us2)
m_us2_p <- lm(police_action_required ~ black_p + goal + commit, data = us2)
cat(sprintf('SAMPLE:study2_us:estimation=%d\n', nobs(m_us2_v)))
cat(sprintf('SAMPLE:study2_us_police:loaded=%d\n', nrow(us2)))
cat(sprintf('SAMPLE:study2_us_police:estimation=%d\n', nobs(m_us2_p)))

## ---------------- Study 2 Israel ----------------
is2 <- isr_survey_wave2
cat(sprintf('SAMPLE:study2_israel:loaded=%d\n', nrow(is2)))
id2 <- as_chr(is2$identity_protesters)
num_id2 <- suppressWarnings(as.numeric(id2))
if (all(is.na(id2) | !is.na(num_id2))) {
  u <- sort(unique(num_id2[!is.na(num_id2)]))
  is2$eth_p <- as.numeric(num_id2 == u[2])
  is2$arab_p <- as.numeric(num_id2 == u[3])
} else {
  is2$eth_p <- ifelse(is.na(id2), NA, as.numeric(grepl('ethiop', id2)))
  is2$arab_p <- ifelse(is.na(id2), NA, as.numeric(grepl('arab', id2)))
}
is2$goal <- to_dummy(is2$group_goal, pos_pattern = 'minor|group|racis|police|brutal|discrim|yes|^1$',
                     neg_pattern = 'general|layoff|^no$|^0$')
is2$commit <- to_dummy(is2$commitment, pos_pattern = 'yes|commit|nonviol|^1$',
                       neg_pattern = '^no|without|none|^0$')
is2$degree_violence <- to_num(is2$degree_violence)
m_is2_v <- lm(degree_violence ~ eth_p + arab_p + goal + commit, data = is2)
cat(sprintf('SAMPLE:study2_israel:estimation=%d\n', nobs(m_is2_v)))

## ---------------- Results ----------------
out <- function(name, val) cat(sprintf('RESULT:%s=%.6f\n', name, as.numeric(val)))
outi <- function(name, val) cat(sprintf('RESULT:%s=%d\n', name, as.integer(val)))

out('study1_us_black_perceived_violence', coef(m_us1_v)['black_p'])
out('study1_us_black_police_action', coef(m_us1_p)['black_p'])
out('study1_israel_ethiopian_perceived_violence', coef(m_is1_v)['eth_p'])
out('study1_israel_ethiopian_police_action', coef(m_is1_p)['eth_p'])
out('study1_israel_arab_perceived_violence', coef(m_is1_v)['arab_p'])
out('study1_israel_arab_police_action', coef(m_is1_p)['arab_p'])
out('study2_us_black_perceived_violence', coef(m_us2_v)['black_p'])
out('study2_us_black_police_action', coef(m_us2_p)['black_p'])
outi('respondents_study1_us', nobs(m_us1_v))
outi('respondents_study1_israel', nobs(m_is1_v))
outi('respondents_study2_us', nobs(m_us2_v))
outi('respondents_study2_israel', nobs(m_is2_v))
