# Independent reproduction: Saccardo & Serra-Garcia (2023, AER), Tables 2 and 3
suppressMessages({library(haven); library(dplyr); library(sandwich); library(lmtest)})
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-a/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/choice_experiments.dta")
d <- zap_labels(d)

# Main Choice treatments (Table 1): Choice Free--Professionals, Choice Free (AMT),
# Incentive First Costly, Quality First Costly.  Drop the High Stakes robustness
# treatments; AMT advisors must give consistent MPL responses (attentive/consistent
# sample, per preregistration) -- inconsistent ones have no selfishness measure.
m <- d %>% filter(Highx10 == 0, Highx100 == 0) %>%
  filter(professionalsfree == 1 | !is.na(stdalpha)) %>%
  filter(!is.na(age), !is.na(female))
cat("Treatment counts:\n"); print(table(m$treatment))

m$wave <- factor(m$wave)
ctrl <- "female + age + wave + probabilistic_incentive + incentiveleft + incentiveshigh_incentiveleft"

fit <- function(f, data) {
  r <- lm(as.formula(f), data = data)
  ct <- coeftest(r, vcov = vcovHC(r, type = "HC3"))
  print(ct); cat("N =", nobs(r), " R2 =", summary(r)$r.squared, "\n\n")
  list(b = coef(r), n = nobs(r))
}

# Table 2
t2c1 <- fit(paste("choicebefore ~ professionalsfree + seeincentivecostly + seequalitycostly +", ctrl), m)
amt <- m %>% filter(professionalsfree == 0)
t2c2 <- fit(paste("choicebefore ~ seeincentivecostly + seequalitycostly + stdalpha +", ctrl), amt)
t2c3 <- fit(paste("choicebefore ~ seeincentivecostly + seequalitycostly + stdalpha + selfishseeincentivecostly + selfishseequalitycostly +", ctrl), amt)

# Table 3
rhs3 <- paste("choicebefore + noconflict + choicebeforenoconflict + professionalsfree + seeincentivecostly + seequalitycostly + incentiveB +", ctrl)
t3c1 <- fit(paste("recommendincentive ~", rhs3), m %>% filter(getyourchoice == 1))
t3c2 <- fit(paste("recommendincentive ~", rhs3), m %>% filter(getyourchoice == 0))
t3c3 <- fit(paste("recommendincentive ~ notgetyourchoice + choicebeforenotgetyourchoice + notgetyourchoicenoconflict +", rhs3), m)

# Diagnostics: how the Professionals coefficient depends on the design controls
pv <- function(lab, f) {
  x <- lm(as.formula(f), data = m); se <- sqrt(diag(vcovHC(x, type = "HC3")))
  cat(sprintf("VARIANT %-45s prof=%.4f (%.4f) R2=%.4f\n", lab, coef(x)["professionalsfree"], se["professionalsfree"], summary(x)$r.squared))
}
b <- "choicebefore ~ professionalsfree + seeincentivecostly + seequalitycostly + female + age"
pv("A incentiveshigh instead of probabilistic", paste(b, "+ wave + incentiveshigh + incentiveleft + incentiveshigh_incentiveleft"))
pv("B year dummies", paste(b, "+ factor(year) + probabilistic_incentive + incentiveleft + incentiveshigh_incentiveleft"))
pv("C no probabilistic", paste(b, "+ wave + incentiveleft + incentiveshigh_incentiveleft"))
pv("D wave2 wave3 only (no prof wave)", paste(b, "+ wave2 + wave3 + probabilistic_incentive + incentiveleft + incentiveshigh_incentiveleft"))
pv("E year + incentiveshigh", paste(b, "+ factor(year) + incentiveshigh + incentiveleft + incentiveshigh_incentiveleft"))
pv("F no design controls", paste(b, "+ wave"))
pv("G wave only incl prob", paste(b, "+ wave + probabilistic_incentive"))
cat("incentiveleft by treatment:\n"); print(table(m$treatment, m$incentiveleft))

r <- function(nm, v)cat(sprintf("RESULT:%s=%.6f\n", nm, v))
r("see_incentive_first_costly_table2_col1", t2c1$b["seeincentivecostly"])
r("assess_quality_first_costly_table2_col1", t2c1$b["seequalitycostly"])
r("choice_free_professionals_table2_col1", t2c1$b["professionalsfree"])
r("selfishness_table2_col2", t2c2$b["stdalpha"])
r("selfishness_table2_col3", t2c3$b["stdalpha"])
r("see_incentive_first_costly_x_selfishness_table2_col3", t2c3$b["selfishseeincentivecostly"])
r("see_quality_first_costly_x_selfishness_table2_col3", t2c3$b["selfishseequalitycostly"])
r("n_obs_table2_col1", t2c1$n)
r("n_obs_table2_cols2_3", t2c2$n)
r("prefer_see_incentive_first_assigned_table3_col1", t3c1$b["choicebefore"])
r("prefer_see_incentive_first_not_assigned_table3_col2", t3c2$b["choicebefore"])
r("prefer_see_incentive_first_x_not_assigned_table3_col3", t3c3$b["choicebeforenotgetyourchoice"])
r("n_obs_table3_col1", t3c1$n)
