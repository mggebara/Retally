# Retally independent/blind reproduction: Grier, Grier & Mkrtchian (2023 APSR)
# Table 1 (district FE and incumbent FE logits) and Table 3 (alternative contribution windows).
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(sandwich); library(survival)})

d <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-11-01-a/mount/grier_2023_sugar_roll_call_voting"
# Per the Read Me, the three .dta files are identical except for the author-aggregated sugar
# contributions (totalcont) over the three windows described in the text.
#   SugarReplicate.dta       : baseline, one year before the vote through end of the vote's calendar year
#                              (verified: it is >= the iter2 window for 99.5% of rows)
#   SugarReplicate_iter1.dta : assumed calendar year of the vote (1/1/13-12/31/13, 1/1/18-12/31/18)
#   SugarReplicate_iter2.dta : assumed 12 months before the vote up to the vote date
#   (iter1/iter2 assignment follows the order the windows are described in the text and in Table 3;
#    the data alone do not pin it down unambiguously.)
files <- c(base = "SugarReplicate.dta", cal = "SugarReplicate_iter1.dta", m12 = "SugarReplicate_iter2.dta")

# Contributions in the data are nominal (integer, mostly multiples of $500).  Inflation-adjust to
# 2018 dollars with CPI-U (all urban consumers, U.S. city average) annual averages.
cpi <- c(`113` = 232.957, `115` = 251.107)   # 2013, 2018

prep <- function(f) {
  a <- read_dta(file.path(d, f))
  a <- as.data.frame(zap_labels(a))
  a$y <- as.integer(a$vote == "Aye")           # 1 = aye (for reform), 0 otherwise
  a$sug_real <- a$totalcont * cpi["115"] / cpi[as.character(a$cong)]
  a$fe_id <- factor(a$id)
  a
}

ctrls <- "ncu + tenure + poverty + bach + medincome + over65 + agcom"
fml <- as.formula(paste("y ~ sug_real +", ctrls, "+ fe_id"))
vars <- c("y", "sug_real", "ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom", "id", "both")

samples <- function(a) {
  a <- a[complete.cases(a[, vars]), ]
  sw <- a %>% group_by(id) %>% summarise(n = n(), s = n_distinct(y), b = all(both == 1)) %>%
    filter(n == 2, s == 2)
  dist <- a[a$id %in% sw$id, ]
  inc  <- a[a$id %in% sw$id[sw$b], ]           # same incumbent in the district for both votes
  list(dist = droplevels(dist), inc = droplevels(inc))
}

fit <- function(df) {
  m <- glm(fml, data = df, family = binomial("logit"), control = glm.control(maxit = 200, epsilon = 1e-12))
  n <- nobs(m)
  V <- sandwich(m) * n / (n - 1)               # Stata-style robust VCE for ML logit
  b <- coef(m); se <- sqrt(diag(V))
  p <- 2 * pnorm(-abs(b / se))
  ll0 <- sum(dbinom(df$y, 1, mean(df$y), log = TRUE))
  pr2 <- 1 - as.numeric(logLik(m)) / ll0
  list(m = m, b = b, se = se, p = p, n = n, pr2 = pr2, ngroups = nlevels(df$fe_id))
}

show <- function(r, label) {
  k <- c("sug_real", "ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom", "(Intercept)")
  cat("\n==", label, ": N =", r$n, " groups =", r$ngroups, " pseudo R2 =", round(r$pr2, 3), "converged =", r$m$converged, "\n")
  print(data.frame(coef = signif(r$b[k], 5), robust_se = signif(r$se[k], 4), p = round(r$p[k], 4)))
}

res <- list()
for (w in names(files)) {
  s <- samples(prep(files[w]))
  res[[paste0(w, "_dist")]] <- fit(s$dist)
  res[[paste0(w, "_inc")]]  <- fit(s$inc)
  show(res[[paste0(w, "_dist")]], paste(w, "district FE"))
  show(res[[paste0(w, "_inc")]],  paste(w, "incumbent FE"))
}

# Side check (not scored): conditional (fixed-effects) logit on the baseline samples.
s0 <- samples(prep(files["base"]))
for (nm in c("dist", "inc")) {
  cl <- clogit(as.formula(paste("y ~ sug_real +", ctrls, "+ strata(id)")), data = s0[[nm]])
  cat("\nconditional logit (side check),", nm, ": sugar coef =", signif(coef(cl)["sug_real"], 5), "\n")
}

cat("\n")
cat(sprintf("RESULT:sugar_contributions_district_fe=%.10g\n", res$base_dist$b["sug_real"]))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%.10g\n", res$base_inc$b["sug_real"]))
cat(sprintf("RESULT:acu_ideology_district_fe=%.10g\n", res$base_dist$b["ncu"]))
cat(sprintf("RESULT:tenure_district_fe=%.10g\n", res$base_dist$b["tenure"]))
cat(sprintf("RESULT:tenure_incumbent_fe=%.10g\n", res$base_inc$b["tenure"]))
cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%.10g\n", res$cal_dist$b["sug_real"]))
cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%.10g\n", res$cal_inc$b["sug_real"]))
cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%.10g\n", res$m12_dist$b["sug_real"]))
cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%.10g\n", res$m12_inc$b["sug_real"]))
cat(sprintf("RESULT:observations_district_fe=%d\n", res$base_dist$n))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", res$base_inc$n))
