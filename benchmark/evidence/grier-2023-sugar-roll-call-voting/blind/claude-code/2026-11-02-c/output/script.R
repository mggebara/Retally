# Retally blind independent reproduction: Grier, Grier & Mkrtchian (2023, APSR)
# "Campaign Contributions and Roll-Call Voting in the U.S. House: The Case of the Sugar Industry"
# Table 1 (district FE and incumbent FE logits) and Table 3 (alternative contribution windows).
suppressPackageStartupMessages({ library(haven); library(dplyr); library(sandwich) })
set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-11-02-c/mount/grier_2023_sugar_roll_call_voting/"

# Window -> file mapping.
#  SugarReplicate.dta       : baseline window (one year before the vote through the end of the vote's calendar year);
#                             its totalcont weakly exceeds the other two files' for >99% of rows, so it is the widest window.
#  SugarReplicate_iter1.dta : 12 months before the vote up to the vote date (6/20/12-6/20/13, 5/17/17-5/17/18)
#  SugarReplicate_iter2.dta : calendar year of the vote (2013, 2018)
#  The iter1/iter2 assignment is inferred from timing: iter1 holds more 113th-Congress money than iter2 (consistent with
#  iter1 containing the late-2012 election season) and less 115th-Congress money (iter2 contains the late-2018 season).
files <- c(base = "SugarReplicate.dta", m12 = "SugarReplicate_iter1.dta", cal = "SugarReplicate_iter2.dta")

# CPI-U annual averages (BLS, 1982-84=100): 2013 = 232.957, 2018 = 251.107.  Contributions are expressed in 2018 dollars.
cpi <- c(`113` = 232.957, `115` = 251.107)

prep <- function(f) {
  x <- read_dta(paste0(d, f))
  x %>% mutate(
    y = as.integer(vote == "Aye"),                       # 1 = aye (against sugar), 0 otherwise (No / Not Voting)
    realcont = totalcont * cpi["115"] / cpi[as.character(cong)],
    district_id = as.integer(id)                          # state x district identifier
  )
}

ctrl <- c("ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

fit_fe <- function(x, incumbent = FALSE) {
  s <- x
  if (incumbent) s <- s %>% filter(both == 1)             # same member in the district for both votes
  s <- s[complete.cases(s[, c("y", "realcont", ctrl, "district_id")]), ]
  # fixed-effects logit with unit dummies: units without within-unit variation in y (or with one obs) are
  # perfectly predicted and dropped (as Stata's logit does), leaving the vote-switching districts/incumbents.
  s <- s %>% group_by(district_id) %>% filter(n() == 2, n_distinct(y) == 2) %>% ungroup()
  fml <- as.formula(paste("y ~ realcont +", paste(ctrl, collapse = " + "), "+ factor(district_id)"))
  m <- glm(fml, data = s, family = binomial(), control = glm.control(maxit = 200, epsilon = 1e-12))
  V <- vcovHC(m, type = "HC0") * nrow(s) / (nrow(s) - 1)  # Stata-style robust VCE
  se <- sqrt(diag(V))
  m0 <- glm(y ~ 1, data = s, family = binomial())
  list(m = m, se = se, n = nrow(s), units = n_distinct(s$district_id),
       r2 = 1 - as.numeric(logLik(m)) / as.numeric(logLik(m0)))
}

show <- function(lbl, r) {
  b <- coef(r$m)[c("realcont", ctrl, "(Intercept)")]; se <- r$se[names(b)]
  p <- 2 * pnorm(-abs(b / se))
  cat("\n==", lbl, ": N =", r$n, " units =", r$units, " pseudo R2 =", round(r$r2, 3), " converged =", r$m$converged, "\n")
  print(round(cbind(coef = b, robust_se = se, p = p), 6))
}

dat <- lapply(files, prep)
res <- list()
for (w in names(files)) {
  res[[paste0(w, "_d")]] <- fit_fe(dat[[w]], incumbent = FALSE)
  res[[paste0(w, "_i")]] <- fit_fe(dat[[w]], incumbent = TRUE)
  show(paste(w, "district FE"), res[[paste0(w, "_d")]])
  show(paste(w, "incumbent FE"), res[[paste0(w, "_i")]])
}

cf <- function(k, v) unname(coef(res[[k]]$m)[v])
fmt <- function(z) formatC(z, digits = 10, format = "g")
cat("\n")
cat("RESULT:sugar_contributions_district_fe=", fmt(cf("base_d", "realcont")), "\n", sep = "")
cat("RESULT:sugar_contributions_incumbent_fe=", fmt(cf("base_i", "realcont")), "\n", sep = "")
cat("RESULT:acu_ideology_district_fe=", fmt(cf("base_d", "ncu")), "\n", sep = "")
cat("RESULT:tenure_district_fe=", fmt(cf("base_d", "tenure")), "\n", sep = "")
cat("RESULT:tenure_incumbent_fe=", fmt(cf("base_i", "tenure")), "\n", sep = "")
cat("RESULT:sugar_contributions_calendar_year_district_fe=", fmt(cf("cal_d", "realcont")), "\n", sep = "")
cat("RESULT:sugar_contributions_calendar_year_incumbent_fe=", fmt(cf("cal_i", "realcont")), "\n", sep = "")
cat("RESULT:sugar_contributions_12_months_district_fe=", fmt(cf("m12_d", "realcont")), "\n", sep = "")
cat("RESULT:sugar_contributions_12_months_incumbent_fe=", fmt(cf("m12_i", "realcont")), "\n", sep = "")
cat("RESULT:observations_district_fe=", res$base_d$n, "\n", sep = "")
cat("RESULT:observations_incumbent_fe=", res$base_i$n, "\n", sep = "")
cat("DEVIATION: contributions deflated by the author of this script to 2018 dollars with CPI-U annual averages (the data hold nominal totals); iter1/iter2 window mapping inferred from contribution timing.\n")
