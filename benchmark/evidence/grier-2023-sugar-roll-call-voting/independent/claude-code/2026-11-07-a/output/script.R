# Independent reproduction: Grier, Grier & Mkrtchian (2023), sugar contributions and roll-call voting.
# Fixed-effects logit (LSDV: logit with district / incumbent dummies, as implied by the reported
# constant and pseudo R2), robust (HC1-type) standard errors.
suppressMessages({library(haven); library(dplyr); library(sandwich); library(survival)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/independent/2026-11-07-a/mount/grier_2023_sugar_roll_call_voting"

# CPI-U annual averages (BLS): used to express contributions in 2018 dollars
cpi <- c(`113` = 232.957, `115` = 251.107)

prep <- function(f) {
  d <- zap_labels(read_dta(file.path(D, f)))
  d$y <- as.integer(d$vote == "Aye")          # 1 = aye (pro-reform), 0 otherwise
  d$realcont <- d$totalcont * cpi["115"] / cpi[as.character(d$cong)]
  d
}

ctrl <- "realcont + ncu + tenure + poverty + bach + medincome + over65 + agcom"

fit_fe <- function(d, grp) {
  d <- d[complete.cases(d[, c("y","realcont","ncu","tenure","poverty","bach","medincome","over65","agcom")]), ]
  d$g <- d[[grp]]
  # keep groups with two observations and a switched vote (others are perfectly predicted by the FE)
  keep <- d %>% group_by(g) %>% summarise(n = n(), m = mean(y)) %>% filter(n == 2, m == 0.5) %>% pull(g)
  s <- d[d$g %in% keep, ]
  m <- glm(as.formula(paste("y ~", ctrl, "+ factor(g)")), family = binomial, data = s,
           control = glm.control(maxit = 200, epsilon = 1e-12))
  V <- vcovHC(m, type = "HC0") * nrow(s) / (nrow(s) - 1)
  se <- sqrt(diag(V))[names(coef(m))]
  m0 <- glm(y ~ 1, family = binomial, data = s)
  cl <- clogit(as.formula(paste("y ~", ctrl, "+ strata(g)")), data = s)
  list(m = m, se = se, n = nrow(s), ngrp = length(keep), pr2 = 1 - as.numeric(logLik(m)) / as.numeric(logLik(m0)), cl = cl, s = s)
}

show <- function(r, lab) {
  cat("\n====", lab, " N =", r$n, " groups =", r$ngrp, " pseudo R2 =", round(r$pr2, 3), "\n")
  v <- c("realcont","ncu","tenure","poverty","bach","medincome","over65","agcom","(Intercept)")
  b <- coef(r$m)[v]; z <- b / r$se[v]
  print(round(cbind(coef = b, se = r$se[v], p = 2 * pnorm(-abs(z))), 6))
  cat("conditional-logit (clogit) coefficients for comparison:\n"); print(round(coef(r$cl), 6))
}

base <- prep("SugarReplicate.dta")        # baseline window: 1 yr before vote to end of vote's calendar year
cal  <- prep("SugarReplicate_iter1.dta")  # assumed: calendar year of vote
m12  <- prep("SugarReplicate_iter2.dta")  # assumed: 12 months before vote up to vote date

# incumbent sample: districts whose member served for both votes (data flag `both` == 1 in both rows);
# with one member per district-pair, the district dummy is the incumbent dummy.
inc_prep <- function(d) {
  ok <- d %>% group_by(id) %>% summarise(n = n(), b = all(both %in% 1)) %>% filter(n == 2, b) %>% pull(id)
  d[d$id %in% ok, ]
}
x <- inc_prep(base) %>% group_by(id) %>% filter(n_distinct(cid) > 1 | n_distinct(name) > 1)
cat("both==1 districts with differing cid/name across votes:\n"); print(as.data.frame(x[, c("id","cong","cid","name","vote")]))

r1 <- fit_fe(base, "id");            show(r1, "Table 1 district FE")
r2 <- fit_fe(inc_prep(base), "id");  show(r2, "Table 1 incumbent FE")
r3 <- fit_fe(cal, "id");             show(r3, "Table 3 calendar-year district FE")
r4 <- fit_fe(inc_prep(cal), "id");   show(r4, "Table 3 calendar-year incumbent FE")
r5 <- fit_fe(m12, "id");             show(r5, "Table 3 12-month district FE")
r6 <- fit_fe(inc_prep(m12), "id");   show(r6, "Table 3 12-month incumbent FE")

cat("\nSwitch directions, district sample (2013 aye -> 2018 no):\n")
print(table(r1$s %>% group_by(g) %>% summarise(d = paste(y[cong == 113], y[cong == 115])) %>% pull(d)))

out <- function(n, v) cat(sprintf("RESULT:%s=%.10g\n", n, v))
out("sugar_contributions_district_fe", coef(r1$m)["realcont"])
out("sugar_contributions_incumbent_fe", coef(r2$m)["realcont"])
out("acu_ideology_district_fe", coef(r1$m)["ncu"])
out("tenure_district_fe", coef(r1$m)["tenure"])
out("tenure_incumbent_fe", coef(r2$m)["tenure"])
out("sugar_contributions_calendar_year_district_fe", coef(r3$m)["realcont"])
out("sugar_contributions_calendar_year_incumbent_fe", coef(r4$m)["realcont"])
out("sugar_contributions_12_months_district_fe", coef(r5$m)["realcont"])
out("sugar_contributions_12_months_incumbent_fe", coef(r6$m)["realcont"])
out("observations_district_fe", r1$n)
out("observations_incumbent_fe", r2$n)
