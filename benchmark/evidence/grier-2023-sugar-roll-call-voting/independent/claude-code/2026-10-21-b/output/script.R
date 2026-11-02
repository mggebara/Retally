# Independent reproduction: Grier, Grier & Mkrtchian (2023), sugar roll-call votes.
# District / incumbent fixed-effects logit (dummy-variable logit, as in Stata `logit ... i.id, robust`).
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(sandwich); library(lmtest)})
D <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/independent/2026-10-21-b/mount/grier_2023_sugar_roll_call_voting"
rd <- function(f) zap_labels(read_dta(file.path(D, f)))
base <- rd("SugarReplicate.dta")        # totalcont: 1 yr before vote -> end of vote's calendar year (widest window)
cal  <- rd("SugarReplicate_iter1.dta")  # totalcont: calendar year of vote
m12  <- rd("SugarReplicate_iter2.dta")  # totalcont: 12 months before vote up to vote date
stopifnot(identical(base$cid, cal$cid), identical(base$cid, m12$cid), identical(base$cong, m12$cong))

# Inflation adjustment: express 2018 (115th Congress) dollars in 2013 dollars, CPI-U annual averages.
cpi2013 <- 232.957; cpi2018 <- 251.107
defl <- ifelse(base$cong == 115, cpi2013 / cpi2018, 1)

d <- base
d$y <- as.numeric(d$vote == "Aye")           # 1 = aye (pro-reform), 0 otherwise (No / Not Voting)
d$c_base <- base$totalcont * defl
d$c_cal  <- cal$totalcont * defl
d$c_m12  <- m12$totalcont * defl

ctrl <- c("ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

fit_fe <- function(dat, cvar, incumbent = FALSE) {
  vars <- c("y", cvar, ctrl, "id", "both")
  dd <- dat[complete.cases(dat[, vars]), vars]
  if (incumbent) dd <- dd[dd$both == 1, ]
  # keep only units observed twice whose vote switched (others are perfectly predicted by their FE)
  g <- dd %>% group_by(id) %>% mutate(n = n(), s = sum(y)) %>% ungroup()
  dd <- as.data.frame(g[g$n == 2 & g$s == 1, ])
  f <- as.formula(paste("y ~", paste(c(cvar, ctrl), collapse = " + "), "+ factor(id)"))
  m <- suppressWarnings(glm(f, data = dd, family = binomial(),
                            control = glm.control(maxit = 100, epsilon = 1e-10)))
  m0 <- glm(y ~ 1, data = dd, family = binomial())
  pr2 <- 1 - as.numeric(logLik(m)) / as.numeric(logLik(m0))
  V <- tryCatch(sandwich::vcovHC(m, type = "HC0"), error = function(e) NULL)
  list(m = m, n = nrow(dd), units = length(unique(dd$id)), pr2 = pr2, V = V)
}

show <- function(lab, r, cvar) {
  cf <- coef(r$m)[c(cvar, ctrl)]
  cat(sprintf("== %s: N=%d units=%d pseudoR2=%.3f converged=%s\n", lab, r$n, r$units, r$pr2, r$m$converged))
  se <- if (!is.null(r$V)) sqrt(diag(r$V))[names(cf)] else rep(NA, length(cf))
  print(round(cbind(coef = cf, robust_se = se, p = 2 * pnorm(-abs(cf / se))), 6))
}

r1 <- fit_fe(d, "c_base");                 show("Table1 col1 district FE", r1, "c_base")
r2 <- fit_fe(d, "c_base", incumbent = TRUE); show("Table1 col2 incumbent FE", r2, "c_base")
r3 <- fit_fe(d, "c_cal");                  show("Table3 calendar-year district FE", r3, "c_cal")
r4 <- fit_fe(d, "c_cal", incumbent = TRUE);  show("Table3 calendar-year incumbent FE", r4, "c_cal")
r5 <- fit_fe(d, "c_m12");                  show("Table3 12-months district FE", r5, "c_m12")
r6 <- fit_fe(d, "c_m12", incumbent = TRUE);  show("Table3 12-months incumbent FE", r6, "c_m12")

cat(sprintf("RESULT:sugar_contributions_district_fe=%.8f\n", coef(r1$m)["c_base"]))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%.8f\n", coef(r2$m)["c_base"]))
cat(sprintf("RESULT:acu_ideology_district_fe=%.6f\n", coef(r1$m)["ncu"]))
cat(sprintf("RESULT:tenure_district_fe=%.6f\n", coef(r1$m)["tenure"]))
cat(sprintf("RESULT:tenure_incumbent_fe=%.6f\n", coef(r2$m)["tenure"]))
cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%.8f\n", coef(r3$m)["c_cal"]))
cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%.8f\n", coef(r4$m)["c_cal"]))
cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%.8f\n", coef(r5$m)["c_m12"]))
cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%.8f\n", coef(r6$m)["c_m12"]))
cat(sprintf("RESULT:observations_district_fe=%d\n", r1$n))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", r2$n))
