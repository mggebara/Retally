suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(sandwich)
  library(lmtest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/saccardo_2023_demand_moral_commitment"
df <- haven::read_dta(file.path(base_dir, "Data/Clean Data/choice_experiments.dta"))
df <- haven::zap_labels(df)
df <- as.data.frame(df)

# As pre-registered: drop non-professional participants with inconsistent MPL (alpha missing)
df <- df[!(df$study != 1 & is.na(df$alphavaluefinal)), ]

# Helper: Stata-like equality (missing never equals a number)
eq <- function(x, v) !is.na(x) & x == v

# Ensure needed constructed variables exist (reconstruct if absent)
if (!"professionalsfree" %in% names(df)) df$professionalsfree <- as.numeric(eq(df$professionals, 1))
if (!"seeincentivecostly" %in% names(df)) df$seeincentivecostly <- as.numeric(df$condition == "PayBefore")
if (!"seequalitycostly" %in% names(df)) df$seequalitycostly <- as.numeric(df$condition == "PayAfter")
if (!"incentiveshigh_incentiveleft" %in% names(df)) df$incentiveshigh_incentiveleft <- df$incentiveshigh * df$incentiveleft
if (!"selfishseeincentivecostly" %in% names(df)) df$selfishseeincentivecostly <- df$stdalpha * df$incentivecostly
if (!"selfishseequalitycostly" %in% names(df)) df$selfishseequalitycostly <- df$stdalpha * df$qualitycostly
if (!"noconflict" %in% names(df)) df$noconflict <- 1 - df$conflict
if (!"choicebeforenoconflict" %in% names(df)) df$choicebeforenoconflict <- df$choicebefore * (1 - df$conflict)
if (!"getyourchoice" %in% names(df)) {
  df$getyourchoice <- as.numeric((eq(df$choicebefore, 1) & eq(df$getbefore, 1)) |
                                   (eq(df$choicebefore, 0) & eq(df$getbefore, 0)))
}
if (!"notgetyourchoice" %in% names(df)) df$notgetyourchoice <- 1 - df$getyourchoice
if (!"notgetyourchoicenoconflict" %in% names(df)) df$notgetyourchoicenoconflict <- (1 - df$getyourchoice) * (1 - df$conflict)
if (!"choicebeforenotgetyourchoice" %in% names(df)) df$choicebeforenotgetyourchoice <- df$notgetyourchoice * df$choicebefore

covariates2 <- c("professionalsfree", "seeincentivecostly", "seequalitycostly", "wave2", "wave3",
                 "professionalscloudresearch", "incentiveshigh", "incentiveleft",
                 "incentiveshigh_incentiveleft", "age", "female")

main_sample <- eq(df$Highx10, 0) & eq(df$Highx100, 0)

fit_hc3 <- function(dv, rhs, data) {
  vars <- c(dv, rhs)
  d <- data[complete.cases(data[, vars]), vars]
  f <- as.formula(paste(dv, "~", paste(rhs, collapse = " + ")))
  m <- lm(f, data = d)
  v <- tryCatch(sandwich::vcovHC(m, type = "HC3"), error = function(e) NULL)
  list(model = m, vcov = v, n = nobs(m))
}

getc <- function(fit, name) {
  b <- coef(fit$model)[name]
  if (is.null(b) || is.na(b)) return(NA_real_)
  unname(b)
}

# ---------------- TABLE 2 ----------------
d2 <- df[main_sample, ]

t2c1 <- fit_hc3("choicebefore", covariates2, d2)
d2b <- d2[eq(d2$professionals, 0), ]
t2c2 <- fit_hc3("choicebefore", c(covariates2, "stdalpha"), d2b)
t2c3 <- fit_hc3("choicebefore", c(covariates2, "stdalpha", "selfishseeincentivecostly",
                                  "selfishseequalitycostly"), d2)

# ---------------- TABLE 3 ----------------
rhs3 <- c("choicebefore", "choicebeforenoconflict", "noconflict", "incentiveB", covariates2)
d3a <- df[main_sample & eq(df$getyourchoice, 1), ]
d3b <- df[main_sample & eq(df$getyourchoice, 0), ]
t3c1 <- fit_hc3("recommendincentive", rhs3, d3a)
t3c2 <- fit_hc3("recommendincentive", rhs3, d3b)
rhs3c <- c("choicebefore", "choicebeforenoconflict", "noconflict", "notgetyourchoice",
           "choicebeforenotgetyourchoice", "notgetyourchoicenoconflict", "incentiveB", covariates2)
t3c3 <- fit_hc3("recommendincentive", rhs3c, df[main_sample, ])

fmt <- function(x) format(x, digits = 10, scientific = FALSE)

cat(paste0("RESULT:see_incentive_first_costly_table2_col1=", fmt(getc(t2c1, "seeincentivecostly")), "\n"))
cat(paste0("RESULT:assess_quality_first_costly_table2_col1=", fmt(getc(t2c1, "seequalitycostly")), "\n"))
cat(paste0("RESULT:choice_free_professionals_table2_col1=", fmt(getc(t2c1, "professionalsfree")), "\n"))
cat(paste0("RESULT:selfishness_table2_col2=", fmt(getc(t2c2, "stdalpha")), "\n"))
cat(paste0("RESULT:selfishness_table2_col3=", fmt(getc(t2c3, "stdalpha")), "\n"))
cat(paste0("RESULT:see_incentive_first_costly_x_selfishness_table2_col3=", fmt(getc(t2c3, "selfishseeincentivecostly")), "\n"))
cat(paste0("RESULT:see_quality_first_costly_x_selfishness_table2_col3=", fmt(getc(t2c3, "selfishseequalitycostly")), "\n"))
cat(paste0("RESULT:n_obs_table2_col1=", t2c1$n, "\n"))
cat(paste0("RESULT:n_obs_table2_cols2_3=", t2c2$n, "\n"))
cat(paste0("RESULT:prefer_see_incentive_first_assigned_table3_col1=", fmt(getc(t3c1, "choicebefore")), "\n"))
cat(paste0("RESULT:prefer_see_incentive_first_not_assigned_table3_col2=", fmt(getc(t3c2, "choicebefore")), "\n"))
cat(paste0("RESULT:prefer_see_incentive_first_x_not_assigned_table3_col3=", fmt(getc(t3c3, "choicebeforenotgetyourchoice")), "\n"))
cat(paste0("RESULT:n_obs_table3_col1=", t3c1$n, "\n"))