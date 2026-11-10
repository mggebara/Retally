suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/saccardo_2023_demand_moral_commitment"
f <- file.path(base_dir, "Data", "Clean Data", "choice_experiments.dta")

d <- haven::read_dta(f)
d <- haven::zap_labels(d)
d <- as.data.frame(d)

# Resolve variable names case-insensitively
getv <- function(df, name) {
  if (name %in% names(df)) return(df[[name]])
  idx <- which(tolower(names(df)) == tolower(name))
  if (length(idx) >= 1) return(df[[idx[1]]])
  stop(paste("Variable not found:", name))
}

needed <- c("study", "alphavaluefinal", "Highx10", "Highx100", "professionals",
            "choicebefore", "professionalsfree", "seeincentivecostly", "seequalitycostly",
            "wave2", "wave3", "professionalscloudresearch", "incentiveshigh", "incentiveleft",
            "incentiveshigh_incentiveleft", "age", "female", "stdalpha",
            "selfishseeincentivecostly", "selfishseequalitycostly",
            "recommendincentive", "choicebeforenoconflict", "noconflict", "incentiveB",
            "getyourchoice", "notgetyourchoice", "choicebeforenotgetyourchoice",
            "notgetyourchoicenoconflict")

dd <- data.frame(row.names = seq_len(nrow(d)))
for (v in needed) dd[[v]] <- as.numeric(getv(d, v))

# As pre-registered: drop MTurk participants with inconsistent alpha (keep professionals, study==1)
dd <- dd[(dd$study == 1 & !is.na(dd$study)) | !is.na(dd$alphavaluefinal), ]

# Exclude high-stakes arms
dd <- dd[dd$Highx10 == 0 & dd$Highx100 == 0, ]

covariates2 <- c("professionalsfree", "seeincentivecostly", "seequalitycostly", "wave2", "wave3",
                 "professionalscloudresearch", "incentiveshigh", "incentiveleft",
                 "incentiveshigh_incentiveleft", "age", "female")

# OLS with HC3 robust SEs, dropping constant/collinear regressors as Stata does
fit_hc3 <- function(data, y, xs) {
  sub <- data[, c(y, xs)]
  sub <- sub[complete.cases(sub), ]
  keep <- xs[sapply(xs, function(x) length(unique(sub[[x]])) > 1)]
  fml <- as.formula(paste(y, "~", paste(keep, collapse = " + ")))
  m <- lm(fml, data = sub)
  if (any(is.na(coef(m)))) {
    keep <- setdiff(keep, names(coef(m))[is.na(coef(m))])
    fml <- as.formula(paste(y, "~", paste(keep, collapse = " + ")))
    m <- lm(fml, data = sub)
  }
  V <- sandwich::vcovHC(m, type = "HC3")
  list(model = m, vcov = V, n = nobs(m))
}

# ---------------- TABLE 2 ----------------
t2c1 <- fit_hc3(dd, "choicebefore", covariates2)
t2c2 <- fit_hc3(dd[dd$professionals == 0, ], "choicebefore", c(covariates2, "stdalpha"))
t2c3 <- fit_hc3(dd, "choicebefore",
                c(covariates2, "stdalpha", "selfishseeincentivecostly", "selfishseequalitycostly"))

# ---------------- TABLE 3 ----------------
t3_x <- c("choicebefore", "choicebeforenoconflict", "noconflict", "incentiveB", covariates2)
t3c1 <- fit_hc3(dd[dd$getyourchoice == 1, ], "recommendincentive", t3_x)
t3c2 <- fit_hc3(dd[dd$getyourchoice == 0, ], "recommendincentive", t3_x)
t3c3 <- fit_hc3(dd, "recommendincentive",
                c("choicebefore", "choicebeforenoconflict", "noconflict", "notgetyourchoice",
                  "choicebeforenotgetyourchoice", "notgetyourchoicenoconflict", "incentiveB",
                  covariates2))

cf <- function(fit, v) unname(coef(fit$model)[v])
se <- function(fit, v) unname(sqrt(diag(fit$vcov))[v])

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))

out("see_incentive_first_costly_table2_col1", cf(t2c1, "seeincentivecostly"))
out("assess_quality_first_costly_table2_col1", cf(t2c1, "seequalitycostly"))
out("choice_free_professionals_table2_col1", cf(t2c1, "professionalsfree"))
out("selfishness_table2_col2", cf(t2c2, "stdalpha"))
out("selfishness_table2_col3", cf(t2c3, "stdalpha"))
out("see_incentive_first_costly_x_selfishness_table2_col3", cf(t2c3, "selfishseeincentivecostly"))
out("see_quality_first_costly_x_selfishness_table2_col3", cf(t2c3, "selfishseequalitycostly"))
cat(sprintf("RESULT:n_obs_table2_col1=%d\n", as.integer(t2c1$n)))
cat(sprintf("RESULT:n_obs_table2_cols2_3=%d\n", as.integer(t2c2$n)))
out("prefer_see_incentive_first_assigned_table3_col1", cf(t3c1, "choicebefore"))
out("prefer_see_incentive_first_not_assigned_table3_col2", cf(t3c2, "choicebefore"))
out("prefer_see_incentive_first_x_not_assigned_table3_col3", cf(t3c3, "choicebeforenotgetyourchoice"))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", as.integer(t3c1$n)))
