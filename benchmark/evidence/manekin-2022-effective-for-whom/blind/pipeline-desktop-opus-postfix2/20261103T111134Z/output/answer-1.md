suppressPackageStartupMessages({
  library(stats)
})
set.seed(42)

base <- '<repo>/.cache/datasets/manekin_2022_effective_for_whom.script-free/Replication/Data'
load(file.path(base, 'us_survey_wave1.rdata'))
load(file.path(base, 'isr_survey_wave1.rdata'))
load(file.path(base, 'us_survey_wave2.rdata'))
load(file.path(base, 'isr_survey_wave2.rdata'))

lab <- function(x) {
  if (is.factor(x)) return(tolower(as.character(x)))
  if (inherits(x, 'haven_labelled')) {
    labs <- attr(x, 'labels')
    v <- as.character(x)
    if (!is.null(labs)) {
      m <- match(unclass(x), labs)
      v[!is.na(m)] <- names(labs)[m[!is.na(m)]]
    }
    return(tolower(v))
  }
  tolower(as.character(x))
}

num <- function(x) {
  if (is.factor(x)) {
    v <- suppressWarnings(as.numeric(as.character(x)))
    if (all(is.na(v[!is.na(x)]))) v <- as.numeric(x)
    return(v)
  }
  as.numeric(unclass(x))
}

# Generic dummy: 1 = treated level
to_dummy <- function(x, pos = NULL, neg = NULL) {
  if (is.logical(x)) return(as.integer(x))
  if (is.numeric(x) && !inherits(x, 'haven_labelled')) {
    u <- sort(unique(x[!is.na(x)]))
    if (length(u) == 2) return(as.integer(x == u[2]))
    return(as.integer(x > 0))
  }
  s <- lab(x)
  out <- rep(NA_integer_, length(s))
  if (!is.null(neg)) {
    isneg <- grepl(neg, s)
    out[isneg] <- 0L
  }
  if (!is.null(pos)) {
    ispos <- grepl(pos, s) & is.na(out)
    out[ispos] <- 1L
  }
  rest <- is.na(out) & !is.na(s)
  if (any(rest)) {
    v <- suppressWarnings(as.numeric(s[rest]))
    if (all(!is.na(v))) {
      out[rest] <- as.integer(v > 0)
    } else if (is.factor(x)) {
      lv <- levels(x)
      out[rest] <- as.integer(as.integer(x[rest]) != 1L)
    } else {
      out[rest] <- 0L
    }
  }
  out
}

pos_yes <- 'yes|commit|^1$|true|minority|group|racis|police|discrim|brutal'
neg_no  <- '^no|none|without|^0$|false|general|layoff|lay off|generic|economic|no commit'

wfun <- function(d) {
  if ('weight' %in% names(d)) {
    w <- num(d$weight)
    w
  } else NULL
}

fit <- function(f, d, w = NULL) {
  if (is.null(w)) lm(f, data = d) else { d$.w <- w; lm(f, data = d, weights = .w) }
}

res <- list()

## ---------------- Study 1 US ----------------
us1 <- us_survey_wave1
cat(sprintf('SAMPLE:study1_us:loaded=%d\n', nrow(us1)))
idl <- lab(us1$identity_protesters)
if (any(grepl('black|tyrone|afric', idl))) {
  us1$black <- as.integer(grepl('black|tyrone|afric', idl))
  us1$black[is.na(us1$identity_protesters)] <- NA
} else {
  us1$black <- to_dummy(us1$identity_protesters)
}
tl <- lab(us1$tactic)
if (any(grepl('traffic|shut|block', tl))) {
  us1$traffic <- as.integer(grepl('traffic|shut|block', tl))
  us1$destroy <- as.integer(grepl('destroy|damag|car|propert|violen|vandal', tl) & !grepl('traffic|shut|block', tl))
  us1$traffic[is.na(us1$tactic)] <- NA; us1$destroy[is.na(us1$tactic)] <- NA
} else {
  tn <- num(us1$tactic); u <- sort(unique(tn[!is.na(tn)]))
  us1$traffic <- as.integer(tn == u[2]); us1$destroy <- as.integer(tn == u[3])
}
us1$degree_violence <- num(us1$degree_violence)
us1$police_action_required <- num(us1$police_action_required)
w_us1 <- wfun(us1)
m_us1_v <- fit(degree_violence ~ black + traffic + destroy, us1, w_us1)
m_us1_p <- fit(police_action_required ~ black + traffic + destroy, us1, w_us1)
cat(sprintf('SAMPLE:study1_us:estimation=%d\n', nobs(m_us1_v)))
cat(sprintf('SAMPLE:study1_us_police:loaded=%d\n', nrow(us1)))
cat(sprintf('SAMPLE:study1_us_police:estimation=%d\n', nobs(m_us1_p)))

## ---------------- Study 1 Israel ----------------
is1 <- isr_survey_wave1
cat(sprintf('SAMPLE:study1_israel:loaded=%d\n', nrow(is1)))
il <- lab(is1$identity_protesters)
if (any(grepl('eth|arab', il))) {
  is1$ethiopian <- as.integer(grepl('eth', il))
  is1$arab <- as.integer(grepl('arab', il))
  is1$ethiopian[is.na(is1$identity_protesters)] <- NA; is1$arab[is.na(is1$identity_protesters)] <- NA
} else {
  inn <- num(is1$identity_protesters); u <- sort(unique(inn[!is.na(inn)]))
  is1$ethiopian <- as.integer(inn == u[2]); is1$arab <- as.integer(inn == u[3])
}
tl <- lab(is1$tactic)
if (any(grepl('traffic|shut|block', tl))) {
  is1$traffic <- as.integer(grepl('traffic|shut|block', tl))
  is1$destroy <- as.integer(grepl('destroy|damag|garbage|trash|can|propert|violen|vandal', tl) & !grepl('traffic|shut|block', tl))
  is1$traffic[is.na(is1$tactic)] <- NA; is1$destroy[is.na(is1$tactic)] <- NA
} else {
  tn <- num(is1$tactic); u <- sort(unique(tn[!is.na(tn)]))
  is1$traffic <- as.integer(tn == u[2]); is1$destroy <- as.integer(tn == u[3])
}
is1$degree_violence <- num(is1$degree_violence)
is1$police_action_required <- num(is1$police_action_required)
w_is1 <- wfun(is1)
m_is1_v <- fit(degree_violence ~ ethiopian + arab + traffic + destroy, is1, w_is1)
m_is1_p <- fit(police_action_required ~ ethiopian + arab + traffic + destroy, is1, w_is1)
cat(sprintf('SAMPLE:study1_israel:estimation=%d\n', nobs(m_is1_v)))
cat(sprintf('SAMPLE:study1_israel_police:loaded=%d\n', nrow(is1)))
cat(sprintf('SAMPLE:study1_israel_police:estimation=%d\n', nobs(m_is1_p)))

## ---------------- Study 2 US ----------------
us2 <- us_survey_wave2
cat(sprintf('SAMPLE:study2_us:loaded=%d\n', nrow(us2)))
if ('black' %in% names(us2)) {
  bl <- lab(us2$black)
  if (any(grepl('black', bl))) us2$blackd <- as.integer(grepl('black', bl)) else us2$blackd <- to_dummy(us2$black)
} else {
  us2$blackd <- as.integer(grepl('black', lab(us2$identity_protesters_fac)))
}
us2$goal <- to_dummy(us2$group_goal, pos = pos_yes, neg = neg_no)
us2$commit <- to_dummy(us2$commitment, pos = pos_yes, neg = neg_no)
us2$degree_violence <- num(us2$degree_violence)
us2$police_action_required <- num(us2$police_action_required)
m_us2_v <- lm(degree_violence ~ blackd + goal + commit, data = us2)
m_us2_p <- lm(police_action_required ~ blackd + goal + commit, data = us2)
cat(sprintf('SAMPLE:study2_us:estimation=%d\n', nobs(m_us2_v)))
cat(sprintf('SAMPLE:study2_us_police:loaded=%d\n', nrow(us2)))
cat(sprintf('SAMPLE:study2_us_police:estimation=%d\n', nobs(m_us2_p)))

## ---------------- Study 2 Israel ----------------
is2 <- isr_survey_wave2
cat(sprintf('SAMPLE:study2_israel:loaded=%d\n', nrow(is2)))
il <- lab(is2$identity_protesters)
if (any(grepl('eth|arab', il))) {
  is2$ethiopian <- as.integer(grepl('eth', il))
  is2$arab <- as.integer(grepl('arab', il))
} else {
  inn <- num(is2$identity_protesters); u <- sort(unique(inn[!is.na(inn)]))
  is2$ethiopian <- as.integer(inn == u[2]); is2$arab <- as.integer(inn == u[3])
}
is2$goal <- to_dummy(is2$group_goal, pos = pos_yes, neg = neg_no)
is2$commit <- to_dummy(is2$commitment, pos = pos_yes, neg = neg_no)
is2$degree_violence <- num(is2$degree_violence)
m_is2_v <- lm(degree_violence ~ ethiopian + arab + goal + commit, data = is2)
cat(sprintf('SAMPLE:study2_israel:estimation=%d\n', nobs(m_is2_v)))

## ---------------- Results ----------------
out <- function(name, val) cat(sprintf('RESULT:%s=%.6f\n', name, val))
out('study1_us_black_perceived_violence', coef(m_us1_v)['black'])
out('study1_us_black_police_action', coef(m_us1_p)['black'])
out('study1_israel_ethiopian_perceived_violence', coef(m_is1_v)['ethiopian'])
out('study1_israel_ethiopian_police_action', coef(m_is1_p)['ethiopian'])
out('study1_israel_arab_perceived_violence', coef(m_is1_v)['arab'])
out('study1_israel_arab_police_action', coef(m_is1_p)['arab'])
out('study2_us_black_perceived_violence', coef(m_us2_v)['blackd'])
out('study2_us_black_police_action', coef(m_us2_p)['blackd'])
cat(sprintf('RESULT:respondents_study1_us=%d\n', nobs(m_us1_v)))
cat(sprintf('RESULT:respondents_study1_israel=%d\n', nobs(m_is1_v)))
cat(sprintf('RESULT:respondents_study2_us=%d\n', nobs(m_us2_v)))
cat(sprintf('RESULT:respondents_study2_israel=%d\n', nobs(m_is2_v)))
