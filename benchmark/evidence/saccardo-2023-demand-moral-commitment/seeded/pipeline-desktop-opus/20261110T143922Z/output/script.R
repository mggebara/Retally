suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
})

set.seed(42)

base <- "<repo>/.cache/datasets/saccardo_2023_demand_moral_commitment"
d <- haven::read_dta(file.path(base, "Data/Clean Data/choice_experiments.dta"))
d <- as.data.frame(haven::zap_labels(d))

# As pre-registered: drop non-professionals with inconsistent MPL (missing alpha)
d <- d[!(d$study != 1 & is.na(d$alphavaluefinal)), ]

# Main sample excludes high-stakes arms
d <- d[d$Highx10 == 0 & d$Highx100 == 0, ]

covariates2 <- c("professionalsfree", "seeincentivecostly", "seequalitycostly",
                 "wave2", "wave3", "professionalscloudresearch", "incentiveshigh",
                 "incentiveleft", "incentiveshigh_incentiveleft", "age", "female")

# OLS with Stata-like handling: listwise deletion, drop collinear regressors, HC3 SEs
run_reg <- function(data, y, xs) {
  vars <- unique(c(y, xs))
  sub <- data[, vars, drop = FALSE]
  for (v in vars) sub[[v]] <- as.numeric(sub[[v]])
  sub <- sub[complete.cases(sub), , drop = FALSE]
  X <- cbind("(Intercept)" = 1, as.matrix(sub[, xs, drop = FALSE]))
  # drop collinear columns (as Stata does)
  q <- qr(X)
  keep <- q$pivot[seq_len(q$rank)]
  keep <- sort(keep)
  X <- X[, keep, drop = FALSE]
  yv <- sub[[y]]
  fit <- lm.fit(X, yv)
  b <- fit$coefficients
  names(b) <- colnames(X)
  m <- lm(yv ~ X - 1)
  names(m$coefficients) <- colnames(X)
  se <- tryCatch({
    V <- sandwich::vcovHC(m, type = "HC3")
    s <- sqrt(diag(V)); names(s) <- colnames(X); s
  }, error = function(e) setNames(rep(NA_real_, length(b)), colnames(X)))
  list(b = b, se = se, n = nrow(X))
}

getb <- function(r, v) if (v %in% names(r$b)) unname(r$b[v]) else NA_real_
gets <- function(r, v) if (v %in% names(r$se)) unname(r$se[v]) else NA_real_

# ---------------- Table 2 ----------------
t2c1 <- run_reg(d, "choicebefore", covariates2)
t2c2 <- run_reg(d[d$professionals == 0, ], "choicebefore", c(covariates2, "stdalpha"))
t2c3 <- run_reg(d, "choicebefore",
                c(covariates2, "stdalpha", "selfishseeincentivecostly", "selfishseequalitycostly"))

# ---------------- Table 3 ----------------
t3x <- c("choicebefore", "choicebeforenoconflict", "noconflict", "incentiveB", covariates2)
t3c1 <- run_reg(d[d$getyourchoice == 1, ], "recommendincentive", t3x)
t3c2 <- run_reg(d[d$getyourchoice == 0, ], "recommendincentive", t3x)
t3c3x <- c("choicebefore", "choicebeforenoconflict", "noconflict", "notgetyourchoice",
           "choicebeforenotgetyourchoice", "notgetyourchoicenoconflict", "incentiveB", covariates2)
t3c3 <- run_reg(d, "recommendincentive", t3c3x)

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))

out("see_incentive_first_costly_table2_col1", getb(t2c1, "seeincentivecostly"))
out("assess_quality_first_costly_table2_col1", getb(t2c1, "seequalitycostly"))
out("choice_free_professionals_table2_col1", getb(t2c1, "professionalsfree"))
out("selfishness_table2_col2", getb(t2c2, "stdalpha"))
out("selfishness_table2_col3", getb(t2c3, "stdalpha"))
out("see_incentive_first_costly_x_selfishness_table2_col3", getb(t2c3, "selfishseeincentivecostly"))
out("see_quality_first_costly_x_selfishness_table2_col3", getb(t2c3, "selfishseequalitycostly"))
out("n_obs_table2_col1", t2c1$n)
out("n_obs_table2_cols2_3", t2c2$n)
out("prefer_see_incentive_first_assigned_table3_col1", getb(t3c1, "choicebefore"))
out("prefer_see_incentive_first_not_assigned_table3_col2", getb(t3c2, "choicebefore"))
out("prefer_see_incentive_first_x_not_assigned_table3_col3", getb(t3c3, "choicebeforenotgetyourchoice"))
out("n_obs_table3_col1", t3c1$n)