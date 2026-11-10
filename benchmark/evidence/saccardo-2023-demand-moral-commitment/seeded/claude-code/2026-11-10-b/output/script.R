suppressPackageStartupMessages({library(haven); library(sandwich)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-b/mount/saccardo_2023_demand_moral_commitment"
d <- as.data.frame(zap_labels(read_dta(file.path(base, "Data/Clean Data/choice_experiments.dta"))))
cat("rows loaded:", nrow(d), "\n")
# As pre-registered (analysis.do): drop non-professional participants with missing alpha
d <- d[!(d$study != 1 & is.na(d$alphavaluefinal)), ]
cat("rows after alpha drop:", nrow(d), "\n")
main <- d[d$Highx10 == 0 & d$Highx100 == 0, ]
cat("main sample:", nrow(main), "\n")

cov2 <- c("professionalsfree","seeincentivecostly","seequalitycostly","wave2","wave3",
          "professionalscloudresearch","incentiveshigh","incentiveleft",
          "incentiveshigh_incentiveleft","age","female")
# OLS with HC3 robust SEs (Stata: reg ..., vce(hc3)); lm drops NA rows and
# aliased (collinear) regressors as Stata does
fit <- function(y, x, data) {
  f <- as.formula(paste(y, "~", paste(x, collapse = " + ")))
  m <- lm(f, data = data)
  V <- vcovHC(m, type = "HC3")
  list(b = coef(m), se = sqrt(diag(V))[names(coef(m))], n = nobs(m))
}
pr <- function(lbl, m, vars) for (v in vars) cat(sprintf("%s %s: b=%.4f se=%.4f\n", lbl, v, m$b[v], m$se[v]))

# Table 2: preference to see incentive first
t2c1 <- fit("choicebefore", cov2, main)
t2c2 <- fit("choicebefore", c(cov2, "stdalpha"), main[main$professionals == 0, ])
t2c3 <- fit("choicebefore", c(cov2, "stdalpha", "selfishseeincentivecostly", "selfishseequalitycostly"), main)
pr("T2c1", t2c1, c("seeincentivecostly","seequalitycostly","professionalsfree")); cat("N", t2c1$n, "\n")
pr("T2c2", t2c2, "stdalpha"); cat("N", t2c2$n, "\n")
pr("T2c3", t2c3, c("stdalpha","selfishseeincentivecostly","selfishseequalitycostly")); cat("N", t2c3$n, "\n")

# Table 3: recommendations by preference and assignment
x3 <- c("choicebefore","choicebeforenoconflict","noconflict","incentiveB", cov2)
t3c1 <- fit("recommendincentive", x3, main[main$getyourchoice == 1, ])
t3c2 <- fit("recommendincentive", x3, main[main$getyourchoice == 0, ])
t3c3 <- fit("recommendincentive", c("choicebefore","choicebeforenoconflict","noconflict","notgetyourchoice",
          "choicebeforenotgetyourchoice","notgetyourchoicenoconflict","incentiveB", cov2), main)
pr("T3c1", t3c1, "choicebefore"); cat("N", t3c1$n, "\n")
pr("T3c2", t3c2, "choicebefore"); cat("N", t3c2$n, "\n")
pr("T3c3", t3c3, "choicebeforenotgetyourchoice"); cat("N", t3c3$n, "\n")

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
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
