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
d <- d0
N <- nrow(d)
getnum <- function(cands, default = NA) {
  c <- findcol(cands)
  if (is.null(c)) return(rep(default, N))
  num_of(d[[c]])
}

# ---- Treatment indicators ----
prof <- getnum(c('professionals', 'professionalsfree'), 0)
prof[is.na(prof)] <- 0
ci <- getnum(c('seeincentivecostly', 'incentivecostly'), 0); ci[is.na(ci)] <- 0
cq <- getnum(c('seequalitycostly', 'qualitycostly'), 0); cq[is.na(cq)] <- 0
ci[prof == 1] <- 0; cq[prof == 1] <- 0
cat("Arm flags: ci", sum(ci), " cq", sum(cq), " prof", sum(prof), "\n")

# ---- Robustness arms (high stakes 10x / 100x) are online-appendix only ----
h10 <- getnum(c('Highx10'), 0); h10[is.na(h10)] <- 0
h100 <- getnum(c('Highx100'), 0); h100[is.na(h100)] <- 0
excl_arm <- (h10 == 1 | h100 == 1)
cat("High-stakes robustness arms excluded:", sum(excl_arm), "\n")

# ---- Sample restrictions: attentive + consistent MPL (no multiple switchers) ----
att <- getnum(c('attentionpassed', 'attentive'))
att[is.na(att)] <- 1   # professionals: missing => kept
selfish_raw <- getnum(c('selfish'))
alpha_raw <- getnum(c('alphavaluefinal'))
cat("Non-professionals with missing selfish:", sum(prof == 0 & is.na(selfish_raw)),
    " missing alpha:", sum(prof == 0 & is.na(alpha_raw)), "\n")
# Multiple switchers have no well-defined MPL / selfishness measure (missing);
# professionals did not get the MPL, so they are not affected.
multisw <- (prof == 0) & is.na(selfish_raw)
keep <- (att == 1) & !multisw & !excl_arm
cat("Kept after restrictions:", sum(keep), "\n")

pref <- getnum(c('choicebefore'))
assigned <- getnum(c('getyourchoice'))
notassigned <- 1 - assigned
rec <- getnum(c('recommendincentive'))
nc_col <- findcol(c('noconflict'))
noconf <- if (!is.null(nc_col)) num_of(d[[nc_col]]) else 1 - getnum(c('conflict'))
incB <- getnum(c('incentiveB', 'incentiveb'))

# ---- Design-variation controls (fn. 14): probabilistic payment, left/right position ----
prob <- getnum(c('incentiveshigh', 'probabilistic_incentive'))
left <- getnum(c('incentiveleft'))
probleft <- getnum(c('incentiveshigh_incentiveleft'))
if (all(is.na(probleft))) probleft <- prob * left

df <- data.frame(pref, rec, noconf, assigned, notassigned, prof, ci, cq, incB,
                 prob, left, prob_left = probleft, selfish = selfish_raw)
df <- df[keep, ]
for (v in c('prob', 'left', 'prob_left')) {
  x <- df[[v]]; if (any(is.na(x))) { x[is.na(x)] <- 0; df[[v]] <- x }
}
ctrl <- c('prob', 'left', 'prob_left')
cs <- paste(ctrl, collapse = ' + ')
cat("Controls:", cs, "\n")

fit <- function(f, data) {
  m <- lm(as.formula(f), data = data)
  V <- sandwich::vcovHC(m, type = 'HC1')
  print(lmtest::coeftest(m, vcov. = V))
  m
}
co <- function(m, v) unname(coef(m)[v])

# ---- Table 2 ----
t2 <- df[!is.na(df$pref), ]
m1 <- fit(paste('pref ~ prof + ci + cq +', cs), t2)
t2b <- t2[t2$prof == 0 & !is.na(t2$selfish), ]
cat("selfish summary: mean", mean(t2b$selfish), " sd", sd(t2b$selfish), "\n")
print(summary(t2b$selfish))
# 'selfish' in the cleaned data is the paper's standardized selfishness measure
# (used to build selfishseeincentivecostly etc.); use as provided if already standardized.
if (abs(sd(t2b$selfish) - 1) < 0.25 && abs(mean(t2b$selfish)) < 0.25) {
  t2b$selfz <- t2b$selfish
} else {
  t2b$selfz <- (t2b$selfish - mean(t2b$selfish)) / sd(t2b$selfish)
}
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