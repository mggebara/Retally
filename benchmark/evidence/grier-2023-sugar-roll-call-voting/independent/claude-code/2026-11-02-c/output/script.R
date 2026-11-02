# Independent reproduction: Grier, Grier & Mkrtchian (2023 APSR), sugar roll-call voting.
# Logit of "aye" (pro-reform) on inflation-adjusted sugar contributions + controls,
# with district (or incumbent) fixed effects as dummies, on the vote-switching sample,
# robust (sandwich) standard errors.
suppressPackageStartupMessages({library(haven); library(dplyr); library(sandwich); library(lmtest)})
set.seed(42)
p <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/independent/2026-11-02-c/mount/grier_2023_sugar_roll_call_voting/"
# Baseline window (1 yr before vote through end of calendar year) = SugarReplicate.dta
# (largest totals); iter1 = calendar-year window; iter2 = 12 months up to the vote.
files <- c(base = "SugarReplicate.dta", cal = "SugarReplicate_iter1.dta", m12 = "SugarReplicate_iter2.dta")

ctrls <- c("ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

prep <- function(f) {
  d <- zap_labels(read_dta(paste0(p, f)))
  d$aye <- as.integer(d$vote == "Aye")
  d
}

fit_fe <- function(d, fe) {
  d <- d[complete.cases(d[, c("aye", "totalcont", ctrls, fe)]), ]
  # keep units observed twice whose outcome switched
  g <- d %>% group_by(.data[[fe]]) %>% mutate(n = n(), s = sum(aye)) %>% ungroup()
  g <- g[g$n == 2 & g$s == 1, ]
  g$fe <- factor(g[[fe]])
  fml <- as.formula(paste("aye ~ totalcont +", paste(ctrls, collapse = " + "), "+ fe"))
  m <- glm(fml, data = g, family = binomial(), control = glm.control(maxit = 200, epsilon = 1e-12))
  V <- vcovHC(m, type = "HC0") * nrow(g) / (nrow(g) - 1)
  ct <- coeftest(m, vcov. = V)
  m0 <- glm(aye ~ 1, data = g, family = binomial())
  list(m = m, ct = ct, n = nobs(m), units = nlevels(g$fe),
       r2 = 1 - as.numeric(logLik(m)) / as.numeric(logLik(m0)))
}

res <- list()
for (w in names(files)) {
  d <- prep(files[[w]])
  # district FE: district identifier = id (state_no + district number)
  rd <- fit_fe(d, "id")
  # incumbent FE: members who voted on both amendments (both == 1), same member
  di <- d[!is.na(d$both) & d$both == 1, ]
  di$inc <- paste(di$id, sep = "_")
  ri <- fit_fe(di, "inc")
  res[[w]] <- list(d = rd, i = ri)
  cat("==== window:", w, "\n")
  cat("District FE: N =", rd$n, " units =", rd$units, " pseudoR2 =", round(rd$r2, 3), "\n")
  print(rd$ct[c("totalcont", ctrls, "(Intercept)"), ])
  cat("Incumbent FE: N =", ri$n, " units =", ri$units, " pseudoR2 =", round(ri$r2, 3), "\n")
  print(ri$ct[c("totalcont", ctrls, "(Intercept)"), ])
}

b <- function(r, v) unname(coef(r$m)[v])
cat(sprintf("RESULT:sugar_contributions_district_fe=%.8f\n", b(res$base$d, "totalcont")))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%.8f\n", b(res$base$i, "totalcont")))
cat(sprintf("RESULT:acu_ideology_district_fe=%.6f\n", b(res$base$d, "ncu")))
cat(sprintf("RESULT:tenure_district_fe=%.6f\n", b(res$base$d, "tenure")))
cat(sprintf("RESULT:tenure_incumbent_fe=%.6f\n", b(res$base$i, "tenure")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%.8f\n", b(res$cal$d, "totalcont")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%.8f\n", b(res$cal$i, "totalcont")))
cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%.8f\n", b(res$m12$d, "totalcont")))
cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%.8f\n", b(res$m12$i, "totalcont")))
cat(sprintf("RESULT:observations_district_fe=%d\n", res$base$d$n))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", res$base$i$n))
