# Grier, Grier & Mkrtchian (2023 APSR): sugar contributions and roll-call voting.
# Independent, blind reproduction of Table 1 (cols 1-2) and Table 3.
suppressMessages({library(haven); library(dplyr); library(sandwich); library(lmtest); library(survival)})
set.seed(42)
D <- "/Users/matthew/dev/Retally/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-10-21-b/mount/grier_2023_sugar_roll_call_voting"

# The three .dta files differ only in `totalcont`, the author-aggregated sugar-industry
# contributions for the three time windows (Read Me).  Identified from the data:
#  SugarReplicate.dta       : largest totals (window = 12 months before vote through end of vote year; baseline)
#  SugarReplicate_iter1.dta : calendar year of the vote (e.g. Hern, who first got money after the
#                             May 2018 vote, has money here and in baseline but not in iter2)
#  SugarReplicate_iter2.dta : 12 months before the vote up to the vote date
files <- c(base = "SugarReplicate.dta", cal = "SugarReplicate_iter1.dta", m12 = "SugarReplicate_iter2.dta")

# Inflation adjustment: totalcont is nominal (round dollar amounts in both years).
# Convert 2013 dollars to 2018 dollars with the CPI-U annual averages (2013 = 232.957, 2018 = 251.107).
cpi <- c(`113` = 232.957, `115` = 251.107)

prep <- function(f) {
  d <- zap_labels(read_dta(file.path(D, f)))
  d$aye <- as.integer(d$vote == "Aye")                     # 1 = aye, 0 otherwise (No, Not Voting, No Vote)
  d$realcont <- d$totalcont * cpi["115"] / cpi[as.character(d$cong)]
  d
}

ctrl <- c("realcont", "ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

fit_fe <- function(d, incumbent = FALSE) {
  d <- d[complete.cases(d[, c("aye", ctrl, "id")]), ]
  if (incumbent) d <- d[!is.na(d$both) & d$both == 1, ]    # same member in the district for both votes
  g <- d %>% group_by(id) %>% summarise(n = n(), s = sum(aye), .groups = "drop")
  keep <- g$id[g$n == 2 & g$s == 1]                        # vote switchers: only they identify the FE logit
  d <- d[d$id %in% keep, ]
  fml <- as.formula(paste("aye ~", paste(ctrl, collapse = " + "), "+ factor(id)"))
  m <- glm(fml, data = d, family = binomial("logit"),
           control = glm.control(epsilon = 1e-12, maxit = 200))
  V <- vcovHC(m, type = "HC1")
  ct <- coeftest(m, vcov. = V)
  list(m = m, ct = ct, n = nobs(m), ng = length(keep), d = d)
}

show <- function(r, lab) {
  cat("\n====", lab, "  N =", r$n, " groups =", r$ng, " converged =", r$m$converged, "\n")
  print(r$ct[c("(Intercept)", ctrl), ], digits = 6)
  ll1 <- as.numeric(logLik(r$m)); ll0 <- as.numeric(logLik(glm(aye ~ 1, data = r$d, family = binomial)))
  cat("McFadden pseudo R2:", 1 - ll1 / ll0, "\n")
}

dat <- lapply(files, prep)
res <- list()
for (w in names(files)) {
  res[[paste0(w, "_d")]] <- fit_fe(dat[[w]], FALSE)
  res[[paste0(w, "_i")]] <- fit_fe(dat[[w]], TRUE)
  show(res[[paste0(w, "_d")]], paste(w, "district FE logit"))
  show(res[[paste0(w, "_i")]], paste(w, "incumbent FE logit"))
}

# Diagnostic only (not reported): conditional (fixed-effects) logit on the same samples.
cat("\nDiagnostic: conditional logit, baseline window\n")
for (k in c("base_d", "base_i")) {
  cl <- clogit(as.formula(paste("aye ~", paste(ctrl, collapse = " + "), "+ strata(id)")), data = res[[k]]$d)
  print(coef(cl))
}

b <- function(k, v) unname(coef(res[[k]]$m)[v])
cat("\n")
cat(sprintf("RESULT:sugar_contributions_district_fe=%.10g\n", b("base_d", "realcont")))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%.10g\n", b("base_i", "realcont")))
cat(sprintf("RESULT:acu_ideology_district_fe=%.10g\n", b("base_d", "ncu")))
cat(sprintf("RESULT:tenure_district_fe=%.10g\n", b("base_d", "tenure")))
cat(sprintf("RESULT:tenure_incumbent_fe=%.10g\n", b("base_i", "tenure")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%.10g\n", b("cal_d", "realcont")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%.10g\n", b("cal_i", "realcont")))
cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%.10g\n", b("m12_d", "realcont")))
cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%.10g\n", b("m12_i", "realcont")))
cat(sprintf("RESULT:observations_district_fe=%d\n", res[["base_d"]]$n))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", res[["base_i"]]$n))
cat("DEVIATION: inflation adjustment uses CPI-U annual averages to express 2013 contributions in 2018 dollars; the paper does not state the deflator or base year.\n")
cat("DEVIATION: district/incumbent fixed effects estimated as an unconditional logit with group dummies (the paper's table reports a constant), restricted to vote-switching groups.\n")
