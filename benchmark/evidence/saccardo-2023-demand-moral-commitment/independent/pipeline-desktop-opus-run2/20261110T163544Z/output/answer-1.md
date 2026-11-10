suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base <- '<repo>/.cache/datasets/saccardo_2023_demand_moral_commitment.script-free'
d0 <- haven::read_dta(file.path(base, 'Data/Clean Data/choice_experiments.dta'))
nm <- names(d0)
cat("N rows:", nrow(d0), "\n")
cat("Columns:", paste(nm, collapse = ", "), "\n")

lab_of <- function(x) {
  if (inherits(x, 'haven_labelled')) as.character(haven::as_factor(x, levels = 'labels'))
  else as.character(x)
}
num_of <- function(x) {
  if (inherits(x, 'haven_labelled')) x <- haven::zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) suppressWarnings(as.numeric(x)) else as.numeric(x)
}
findcol <- function(cands) {
  lo <- tolower(nm)
  for (c in cands) {
    i <- which(lo == tolower(c))
    if (length(i)) return(nm[i[1]])
  }
  NULL
}
showtab <- function(v) {
  if (!is.null(v) && v %in% nm) {
    cat("---- table of", v, "----\n")
    print(table(lab_of(d0[[v]]), useNA = 'ifany'))
  }
}
for (v in c('treatment', 'sample', 'study', 'condition', 'wave', 'choice', 'choicebefore',
            'getyourchoice', 'professionals', 'professionalsfree', 'qualitycostly',
            'probabilistic_incentive', 'incentiveshigh', 'commission', 'conflict',
            'attentionpassed', 'inconsistentid', 'gender', 'incentivedesign')) showtab(findcol(v))

d <- d0
N <- nrow(d)
getnum <- function(cands, default = NA) {
  c <- findcol(cands)
  if (is.null(c)) return(rep(default, N))
  num_of(d[[c]])
}
getlab <- function(cands) {
  c <- findcol(cands)
  if (is.null(c)) return(rep("", N))
  x <- lab_of(d[[c]]); x[is.na(x)] <- ""; x
}

lab_trt <- tolower(paste(getlab('treatment'), getlab('sample'), getlab('study')))

# ---- Treatment indicators ----
profcol <- findcol(c('professionals', 'professionalsfree'))
prof <- if (!is.null(profcol)) num_of(d[[profcol]]) else as.numeric(grepl('prof', lab_trt))
prof[is.na(prof)] <- 0
prof <- as.numeric(prof == 1 | grepl('prof', lab_trt))

cq_col <- findcol(c('qualitycostly', 'costlyquality', 'afterCostly', 'assessqualitycostly'))
cq <- if (!is.null(cq_col)) num_of(d[[cq_col]]) else
  as.numeric(grepl('cost', lab_trt) & grepl('quality|after', lab_trt))
cq[is.na(cq)] <- 0
ci_col <- findcol(c('incentivecostly', 'costlyincentive', 'seeincentivefirstcostly',
                    'incentivefirstcostly', 'beforecostly', 'getbeforecostly'))
ci <- if (!is.null(ci_col)) num_of(d[[ci_col]]) else
  as.numeric(grepl('cost', lab_trt) & !grepl('quality|after', lab_trt) & cq == 0)
ci[is.na(ci)] <- 0
ci[cq == 1] <- 0
ci[prof == 1] <- 0; cq[prof == 1] <- 0

excl_arm <- grepl('stake|replic|determin|10x|100x|fold|tenfold|hundred', lab_trt)
cat("Excluded (robustness arms by label):", sum(excl_arm), "\n")

# ---- Sample restrictions ----
att <- getnum(c('attentionpassed', 'attentive'))
att[is.na(att)] <- 1
inc <- getnum(c('inconsistentid', 'inconsistent', 'multipleswitcher', 'multiswitch'))
inc[is.na(inc)] <- 0
keep <- (att == 1) & (inc == 0) & !excl_arm
cat("Kept after restrictions:", sum(keep), "\n")

# ---- Outcome: prefers see incentive first ----
prefcol <- findcol(c('choicebefore', 'choice'))
pref <- num_of(d[[prefcol]])
if (!all(na.omit(pref) %in% c(0, 1))) {
  pl <- tolower(lab_of(d[[prefcol]]))
  pref <- ifelse(is.na(pl), NA, as.numeric(grepl('incentive|before|commission', pl)))
}
cat("Preference var:", prefcol, "\n"); print(table(pref, useNA = 'ifany'))

assigned <- getnum(c('getyourchoice'))
notassigned <- 1 - assigned

rec <- getnum(c('recommendincentive'))
nc_col <- findcol(c('noconflict'))
noconf <- if (!is.null(nc_col)) num_of(d[[nc_col]]) else 1 - getnum(c('conflict'))

ib_col <- findcol(c('incentiveb', 'incentive_b', 'commissionb'))
if (!is.null(ib_col)) {
  incB <- num_of(d[[ib_col]])
} else {
  cl <- tolower(getlab(c('commission')))
  if (any(grepl('b', cl))) incB <- as.numeric(grepl('(^|[^a-z])b($|[^a-z])|product b', cl))
  else incB <- getnum(c('commission'))
}
print(table(incB, useNA = 'ifany'))

# ---- Controls ----
glab <- tolower(getlab(c('gender', 'female', 'sex')))
female <- ifelse(glab == "", NA, as.numeric(grepl('^f|female|woman', glab)))
if (all(is.na(female)) || length(unique(na.omit(female))) < 2) {
  female <- getnum(c('female', 'gender'))
}
age <- getnum(c('age'))
wave <- getlab(c('wave'))
wave[wave == "" | is.na(wave)] <- "none"
prob <- getnum(c('probabilistic_incentive', 'incentiveshigh', 'incentivedesign'))
left <- getnum(c('incentiveleft', 'incentive_left', 'incentiveonleft', 'left', 'positionleft'))
probleft_existing <- getnum(c('incentiveshigh_incentiveleft'))

df <- data.frame(pref, rec, noconf, assigned, notassigned, prof, ci, cq, incB,
                 female, age, wave = factor(wave), prob, left, probleft_existing,
                 selfish = getnum(c('selfish')))
df <- df[keep, ]

fix_missing <- function(df, v) {
  x <- df[[v]]
  if (all(is.na(x))) return(list(df = df, used = character(0)))
  if (mean(is.na(x)) > 0.02) {
    mv <- paste0(v, '_miss')
    df[[mv]] <- as.numeric(is.na(x))
    x[is.na(x)] <- mean(x, na.rm = TRUE)
    df[[v]] <- x
    return(list(df = df, used = c(v, mv)))
  }
  list(df = df, used = v)
}
ctrl <- character(0)
for (v in c('female', 'age', 'prob', 'left')) {
  r <- fix_missing(df, v); df <- r$df; ctrl <- c(ctrl, r$used)
}
if ('prob' %in% ctrl && 'left' %in% ctrl) {
  df$prob_left <- df$prob * df$left; ctrl <- c(ctrl, 'prob_left')
} else if (!all(is.na(df$probleft_existing))) {
  r <- fix_missing(df, 'probleft_existing'); df <- r$df; ctrl <- c(ctrl, r$used)
}
if (length(unique(df$wave)) > 1) ctrl <- c(ctrl, 'wave')
cat("Controls:", paste(ctrl, collapse = ", "), "\n")
cat("Arm counts in kept sample: prof", sum(df$prof), " incentive-costly", sum(df$ci),
    " quality-costly", sum(df$cq), " free", sum(df$prof == 0 & df$ci == 0 & df$cq == 0), "\n")

cs <- paste(ctrl, collapse = ' + ')
fit <- function(f, data) {
  m <- lm(as.formula(f), data = data)
  V <- sandwich::vcovHC(m, type = 'HC3')
  print(lmtest::coeftest(m, vcov. = V))
  m
}
co <- function(m, v) unname(coef(m)[v])

# ---- Table 2 ----
t2 <- df[!is.na(df$pref), ]
m1 <- fit(paste('pref ~ prof + ci + cq +', cs), t2)
t2b <- t2[t2$prof == 0 & !is.na(t2$selfish), ]
t2b$selfz <- (t2b$selfish - mean(t2b$selfish)) / sd(t2b$selfish)
m2 <- fit(paste('pref ~ ci + cq + selfz +', cs), t2b)
m3 <- fit(paste('pref ~ ci + cq + selfz + ci:selfz + cq:selfz +', cs), t2b)

# ---- Table 3 ----
t3 <- df[!is.na(df$rec) & !is.na(df$pref) & !is.na(df$assigned), ]
rhs3 <- paste('pref + noconf + pref:noconf + prof + ci + cq + incB +', cs)
m4 <- fit(paste('rec ~', rhs3), t3[t3$assigned == 1, ])
m5 <- fit(paste('rec ~', rhs3), t3[t3$assigned == 0, ])
m6 <- fit(paste('rec ~', rhs3, '+ notassigned + pref:notassigned + noconf:notassigned'), t3)

pi <- names(coef(m6))[grepl('pref', names(coef(m6))) & grepl('notassigned', names(coef(m6)))]

cat(sprintf('RESULT:see_incentive_first_costly_table2_col1=%.6f\n', co(m1, 'ci')))
cat(sprintf('RESULT:assess_quality_first_costly_table2_col1=%.6f\n', co(m1, 'cq')))
cat(sprintf('RESULT:choice_free_professionals_table2_col1=%.6f\n', co(m1, 'prof')))
cat(sprintf('RESULT:selfishness_table2_col2=%.6f\n', co(m2, 'selfz')))
cat(sprintf('RESULT:selfishness_table2_col3=%.6f\n', co(m3, 'selfz')))
cat(sprintf('RESULT:see_incentive_first_costly_x_selfishness_table2_col3=%.6f\n', co(m3, 'ci:selfz')))
cat(sprintf('RESULT:see_quality_first_costly_x_selfishness_table2_col3=%.6f\n', co(m3, 'cq:selfz')))
cat(sprintf('RESULT:n_obs_table2_col1=%d\n', nobs(m1)))
cat(sprintf('RESULT:n_obs_table2_cols2_3=%d\n', nobs(m2)))
cat(sprintf('RESULT:prefer_see_incentive_first_assigned_table3_col1=%.6f\n', co(m4, 'pref')))
cat(sprintf('RESULT:prefer_see_incentive_first_not_assigned_table3_col2=%.6f\n', co(m5, 'pref')))
cat(sprintf('RESULT:prefer_see_incentive_first_x_not_assigned_table3_col3=%.6f\n', co(m6, pi[1])))
cat(sprintf('RESULT:n_obs_table3_col1=%d\n', nobs(m4)))
