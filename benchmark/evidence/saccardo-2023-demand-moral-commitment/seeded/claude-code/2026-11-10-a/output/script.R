# Saccardo & Serra-Garcia (2023) -- Tables 2 and 3, following Code/analysis.do
suppressPackageStartupMessages({library(haven); library(sandwich)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/seeded/2026-11-10-a/mount/saccardo_2023_demand_moral_commitment"
d <- as.data.frame(zap_labels(read_dta(file.path(base, "Data/Clean Data/choice_experiments.dta"))))
cat("rows loaded:", nrow(d), "\n")
# As pre-registered: drop non-professional participants with missing alpha
d <- d[!(d$study != 1 & is.na(d$alphavaluefinal)), ]
cat("rows after drop:", nrow(d), "\n")

cov2 <- c("professionalsfree","seeincentivecostly","seequalitycostly","wave2","wave3",
          "professionalscloudresearch","incentiveshigh","incentiveleft",
          "incentiveshigh_incentiveleft","age","female")
# Stata `if Highx10==0 & Highx100==0`: missing is not ==0
main <- d[d$Highx10 %in% 0 & d$Highx100 %in% 0, ]

fit <- function(y, x, data) {
  f <- as.formula(paste(y, "~", paste(x, collapse = " + ")))
  m <- lm(f, data = data)
  se <- sqrt(diag(vcovHC(m, type = "HC3")))
  b <- coef(m)
  print(round(cbind(b = b, se = se[names(b)]), 4))
  cat("N =", nobs(m), "\n")
  list(b = b, n = nobs(m))
}

cat("\n== Table 2 col 1 ==\n"); t1 <- fit("choicebefore", cov2, main)
cat("\n== Table 2 col 2 ==\n"); t2 <- fit("choicebefore", c(cov2, "stdalpha"), main[main$professionals %in% 0, ])
cat("\n== Table 2 col 3 ==\n"); t3 <- fit("choicebefore", c(cov2, "stdalpha","selfishseeincentivecostly","selfishseequalitycostly"), main)

x3 <- c("choicebefore","choicebeforenoconflict","noconflict","incentiveB", cov2)
cat("\n== Table 3 col 1 ==\n"); r1 <- fit("recommendincentive", x3, main[main$getyourchoice %in% 1, ])
cat("\n== Table 3 col 2 ==\n"); r2 <- fit("recommendincentive", x3, main[main$getyourchoice %in% 0, ])
cat("\n== Table 3 col 3 ==\n"); r3 <- fit("recommendincentive",
  c("choicebefore","choicebeforenoconflict","noconflict","notgetyourchoice",
    "choicebeforenotgetyourchoice","notgetyourchoicenoconflict","incentiveB", cov2), main)

out <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
out("see_incentive_first_costly_table2_col1", t1$b["seeincentivecostly"])
out("assess_quality_first_costly_table2_col1", t1$b["seequalitycostly"])
out("choice_free_professionals_table2_col1", t1$b["professionalsfree"])
out("selfishness_table2_col2", t2$b["stdalpha"])
out("selfishness_table2_col3", t3$b["stdalpha"])
out("see_incentive_first_costly_x_selfishness_table2_col3", t3$b["selfishseeincentivecostly"])
out("see_quality_first_costly_x_selfishness_table2_col3", t3$b["selfishseequalitycostly"])
out("n_obs_table2_col1", t1$n)
out("n_obs_table2_cols2_3", t2$n)
out("prefer_see_incentive_first_assigned_table3_col1", r1$b["choicebefore"])
out("prefer_see_incentive_first_not_assigned_table3_col2", r2$b["choicebefore"])
out("prefer_see_incentive_first_x_not_assigned_table3_col3", r3$b["choicebeforenotgetyourchoice"])
out("n_obs_table3_col1", r1$n)
