suppressPackageStartupMessages({
  library(stats)
})
set.seed(42)

base_dir <- '<repo>/.cache/datasets/manekin_2022_effective_for_whom.script-free'
ddir <- file.path(base_dir, 'Replication', 'Data')

load(file.path(ddir, 'us_survey_wave1.rdata'))
load(file.path(ddir, 'isr_survey_wave1.rdata'))
load(file.path(ddir, 'us_survey_wave2.rdata'))
load(file.path(ddir, 'isr_survey_wave2.rdata'))

lab <- function(x) {
  if (is.factor(x)) return(tolower(as.character(x)))
  if (inherits(x, 'haven_labelled')) {
    labs <- attr(x, 'labels')
    out <- names(labs)[match(as.vector(x), labs)]
    return(tolower(out))
  }
  tolower(as.character(x))
}

describe <- function(name, x) {
  tb <- table(lab(x), useNA = 'ifany')
  cat(sprintf('# %s levels: %s\n', name, paste(sprintf('%s(%d)', names(tb), as.integer(tb)), collapse = ', ')))
}

# Build a 0/1 indicator from a variable, matching a pattern on labels; fall back to
# the k-th level of the factor/sorted unique values when the pattern does not match.
indicator <- function(x, pattern, fallback_k) {
  l <- lab(x)
  hit <- grepl(pattern, l, perl = TRUE)
  if (any(hit, na.rm = TRUE)) {
    out <- as.integer(hit)
  } else {
    lv <- if (is.factor(x)) levels(x) else sort(unique(as.character(x[!is.na(x)])))
    lv <- tolower(lv)
    out <- as.integer(l == lv[fallback_k])
  }
  out[is.na(l)] <- NA_integer_
  out
}

to01 <- function(x, pattern) {
  if (is.numeric(x) && !inherits(x, 'haven_labelled')) {
    u <- sort(unique(x[!is.na(x)]))
    if (all(u %in% c(0, 1))) return(as.integer(x))
    return(as.integer(x == max(u)))
  }
  if (is.logical(x)) return(as.integer(x))
  indicator(x, pattern, 2)
}

numv <- function(x) as.numeric(as.vector(x))

fit <- function(formula, data, w = NULL) {
  if (is.null(w)) lm(formula, data = data) else lm(formula, data = data, weights = w)
}

res <- list()
se <- list()
emit_coef <- function(m, var, name) {
  res[[name]] <<- unname(coef(m)[var])
  se[[name]] <<- unname(sqrt(diag(vcov(m)))[var])
}

## ---------------- Study 1 US ----------------
us1 <- us_survey_wave1
cat(sprintf('SAMPLE:study1_us:loaded=%d\n', nrow(us1)))
describe('us1 identity_protesters', us1$identity_protesters)
describe('us1 tactic', us1$tactic)
us1$black <- indicator(us1$identity_protesters, 'black|afric|tyrone', 2)
us1$traffic <- indicator(us1$tactic, 'traffic|shut|block|road', 2)
us1$destroy <- indicator(us1$tactic, 'destr|damag|propert|police car|violen', 3)
us1$dv <- numv(us1$degree_violence)
us1$pol <- numv(us1$police_action_required)
us1$rec <- numv(us1$recall_violence2)
us1$w <- numv(us1$weight)
if (all(is.na(us1$w))) { cat('DEVIATION: US Study 1 weights missing; unweighted OLS\n'); us1$w <- 1 }

m_us1_dv <- fit(dv ~ black + traffic + destroy, us1, us1$w)
m_us1_rec <- fit(rec ~ black + traffic + destroy, us1, us1$w)
m_us1_pol <- fit(pol ~ black + traffic + destroy, us1, us1$w)
cat(sprintf('SAMPLE:study1_us:estimation=%d\n', nobs(m_us1_dv)))
cat(sprintf('SAMPLE:study1_us_police:estimation=%d\n', nobs(m_us1_pol)))
emit_coef(m_us1_dv, 'black', 'study1_us_black_perceived_violence')
emit_coef(m_us1_rec, 'black', 'study1_us_black_recall_violence')
emit_coef(m_us1_pol, 'black', 'study1_us_black_police_action')
res[['study1_us_intercept_perceived_violence']] <- unname(coef(m_us1_dv)[1])
res[['study1_us_r2_perceived_violence']] <- summary(m_us1_dv)$r.squared

## ---------------- Study 1 Israel ----------------
is1 <- isr_survey_wave1
cat(sprintf('SAMPLE:study1_israel:loaded=%d\n', nrow(is1)))
describe('is1 identity_protesters', is1$identity_protesters)
describe('is1 tactic', is1$tactic)
is1$eth <- indicator(is1$identity_protesters, 'ethio', 2)
is1$arab <- indicator(is1$identity_protesters, 'arab', 3)
is1$traffic <- indicator(is1$tactic, 'traffic|shut|block|road', 2)
is1$destroy <- indicator(is1$tactic, 'destr|damag|propert|garbage|trash|violen', 3)
is1$dv <- numv(is1$degree_violence)
is1$pol <- numv(is1$police_action_required)
is1$rec <- numv(is1$recall_violence2)
is1$w <- numv(is1$weight)
if (all(is.na(is1$w))) { cat('DEVIATION: Israel Study 1 weights missing; unweighted OLS\n'); is1$w <- 1 }

m_is1_dv <- fit(dv ~ eth + arab + traffic + destroy, is1, is1$w)
m_is1_rec <- fit(rec ~ eth + arab + traffic + destroy, is1, is1$w)
m_is1_pol <- fit(pol ~ eth + arab + traffic + destroy, is1, is1$w)
cat(sprintf('SAMPLE:study1_israel:estimation=%d\n', nobs(m_is1_dv)))
cat(sprintf('SAMPLE:study1_israel_police:estimation=%d\n', nobs(m_is1_pol)))
emit_coef(m_is1_dv, 'eth', 'study1_israel_ethiopian_perceived_violence')
emit_coef(m_is1_pol, 'eth', 'study1_israel_ethiopian_police_action')
emit_coef(m_is1_dv, 'arab', 'study1_israel_arab_perceived_violence')
emit_coef(m_is1_pol, 'arab', 'study1_israel_arab_police_action')
emit_coef(m_is1_rec, 'eth', 'study1_israel_ethiopian_recall_violence')
emit_coef(m_is1_rec, 'arab', 'study1_israel_arab_recall_violence')

## ---------------- Study 2 US ----------------
us2 <- us_survey_wave2
cat(sprintf('SAMPLE:study2_us:loaded=%d\n', nrow(us2)))
describe('us2 black', us2$black)
describe('us2 group_goal', us2$group_goal)
describe('us2 commitment', us2$commitment)
us2$blk <- to01(us2$black, 'black|afric|^1$|yes')
us2$goal <- to01(us2$group_goal, 'group|minor|racis|police|^1$|yes')
us2$commit <- to01(us2$commitment, 'commit|nonviol|^1$|yes')
us2$dv <- numv(us2$degree_violence)
us2$pol <- numv(us2$police_action_required)
us2$rec <- numv(us2$recall_violence2)
cat('DEVIATION: no survey weight variable in Study 2 data; unweighted OLS\n')

m_us2_dv <- lm(dv ~ blk + goal + commit, data = us2)
m_us2_rec <- lm(rec ~ blk + goal + commit, data = us2)
m_us2_pol <- lm(pol ~ blk + goal + commit, data = us2)
cat(sprintf('SAMPLE:study2_us:estimation=%d\n', nobs(m_us2_dv)))
cat(sprintf('SAMPLE:study2_us_police:drop_missing_police_action=%d\n', sum(!is.na(us2$pol))))
cat(sprintf('SAMPLE:study2_us_police:estimation=%d\n', nobs(m_us2_pol)))
emit_coef(m_us2_dv, 'blk', 'study2_us_black_perceived_violence')
emit_coef(m_us2_rec, 'blk', 'study2_us_black_recall_violence')
emit_coef(m_us2_pol, 'blk', 'study2_us_black_police_action')
emit_coef(m_us2_dv, 'goal', 'study2_us_group_goal_perceived_violence')
emit_coef(m_us2_dv, 'commit', 'study2_us_commitment_perceived_violence')

## ---------------- Study 2 Israel ----------------
is2 <- isr_survey_wave2
cat(sprintf('SAMPLE:study2_israel:loaded=%d\n', nrow(is2)))
describe('is2 identity_protesters', is2$identity_protesters)
describe('is2 group_goal', is2$group_goal)
describe('is2 commitment', is2$commitment)
is2$eth <- indicator(is2$identity_protesters, 'ethio', 2)
is2$arab <- indicator(is2$identity_protesters, 'arab', 3)
is2$goal <- to01(is2$group_goal, 'group|minor|racis|discrim|police|^1$|yes')
is2$commit <- to01(is2$commitment, 'commit|nonviol|^1$|yes')
is2$dv <- numv(is2$degree_violence)
is2$pol <- numv(is2$police_action_required)
is2$rec <- numv(is2$recall_violence2)

m_is2_dv <- lm(dv ~ eth + arab + goal + commit, data = is2)
m_is2_rec <- lm(rec ~ eth + arab + goal + commit, data = is2)
m_is2_pol <- lm(pol ~ eth + arab + goal + commit, data = is2)
cat(sprintf('SAMPLE:study2_israel:estimation=%d\n', nobs(m_is2_dv)))
cat(sprintf('SAMPLE:study2_israel_police:estimation=%d\n', nobs(m_is2_pol)))
emit_coef(m_is2_dv, 'eth', 'study2_israel_ethiopian_perceived_violence')
emit_coef(m_is2_dv, 'arab', 'study2_israel_arab_perceived_violence')
emit_coef(m_is2_pol, 'eth', 'study2_israel_ethiopian_police_action')
emit_coef(m_is2_pol, 'arab', 'study2_israel_arab_police_action')

## ---------------- Counts ----------------
res[['respondents_study1_us']] <- nobs(m_us1_dv)
res[['respondents_study1_israel']] <- nobs(m_is1_dv)
res[['respondents_study2_us']] <- nobs(m_us2_dv)
res[['respondents_study2_israel']] <- nobs(m_is2_dv)

for (nm in names(res)) {
  v <- res[[nm]]
  if (!is.null(v) && length(v) == 1 && !is.na(v)) cat(sprintf('RESULT:%s=%.6f\n', nm, v))
}
for (nm in names(se)) {
  v <- se[[nm]]
  if (!is.null(v) && length(v) == 1 && !is.na(v)) cat(sprintf('RESULT:%s_se=%.6f\n', nm, v))
}