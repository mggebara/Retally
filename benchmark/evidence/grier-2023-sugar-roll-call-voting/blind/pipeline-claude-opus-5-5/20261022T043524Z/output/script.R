# Conditional (fixed-effects) logit reproduction of Grier et al. (2023), Tables 1 and 3.
# Mapping assumptions for the alternative contribution windows:
#   SugarReplicate.dta       -> main window (1 year before vote through end of vote year)
#   SugarReplicate_iter1.dta -> calendar-year window (1/1-12/31 of each vote year)
#   SugarReplicate_iter2.dta -> 12 months up to each vote date
# The file names do not identify the windows, so this mapping is a guess.
# If it is wrong, the calendar_year and 12_months results swap.

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(survival)
  library(sandwich)
})
set.seed(42)

base <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"

# Load a .dta file, strip Stata labels, and build the analysis variables.
load_data <- function(f) {
  d <- haven::read_dta(file.path(base, f))
  d <- haven::zap_labels(d)
  d <- as.data.frame(d)

  # Recode the vote to 1 = "aye" (reform), 0 = otherwise.
  if (is.character(d$vote)) {
    v <- tolower(trimws(d$vote))
    d$vote <- ifelse(v %in% c("aye", "yes", "yea", "1", "y"), 1,
                     ifelse(v %in% c("no", "nay", "0", "n"), 0, NA))
  } else {
    d$vote <- as.numeric(d$vote)
    uv <- sort(unique(na.omit(d$vote)))
    if (!all(uv %in% c(0, 1))) {
      # Assume the larger code is "aye".
      d$vote <- ifelse(is.na(d$vote), NA, as.numeric(d$vote == max(uv)))
    }
  }

  # Unique district identifier: state x district number.
  d$distid <- paste(as.character(d$state), as.character(d$district), sep = "_")

  # Incumbent identifier: CRP candidate id, falling back to name if missing.
  cidc <- as.character(d$cid)
  cidc[is.na(cidc) | trimws(cidc) == ""] <- NA
  if (all(is.na(cidc))) cidc <- as.character(d$name)
  d$incid <- cidc

  # Force numeric types for the regressors.
  numv <- c("sugcont", "ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")
  for (v in numv) d[[v]] <- as.numeric(d[[v]])
  d
}

ctrl <- c("ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

# Conditional logit with strata `sv`, keeping only strata with exactly
# two observations and a vote change (the units that identify the model).
fit_clogit <- function(d, sv) {
  vars <- c("vote", "sugcont", ctrl, sv)
  dd <- d[complete.cases(d[, vars]), vars]
  dd$strat <- dd[[sv]]
  dd <- dd %>%
    group_by(strat) %>%
    filter(n() == 2, length(unique(vote)) == 2) %>%
    ungroup() %>%
    as.data.frame()

  fml <- as.formula(paste("vote ~ sugcont +", paste(ctrl, collapse = " + "),
                          "+ strata(strat)"))
  m <- clogit(fml, data = dd, method = "exact")
  list(model = m, nobs = nrow(dd), ngroups = length(unique(dd$strat)))
}

safe_coef <- function(res, v) {
  if (is.null(res)) return(NA)
  unname(coef(res$model)[v])
}

# Run both fixed-effects specifications; return NULL on failure instead of stopping.
run_all <- function(d) {
  r_d <- tryCatch(fit_clogit(d, "distid"), error = function(e) {
    message("District FE failed: ", conditionMessage(e))
    NULL
  })
  r_i <- tryCatch(fit_clogit(d, "incid"), error = function(e) {
    message("Incumbent FE failed: ", conditionMessage(e))
    NULL
  })
  list(dist = r_d, inc = r_i)
}

# ---- Main window (Table 1) ----
d0 <- load_data("SugarReplicate.dta")
main <- run_all(d0)
if (!is.null(main$dist)) print(summary(main$dist$model))
if (!is.null(main$inc)) print(summary(main$inc$model))

# ---- Alternative contribution windows (Table 3) ----
alt1 <- tryCatch(run_all(load_data("SugarReplicate_iter1.dta")),
                 error = function(e) list(dist = NULL, inc = NULL))
alt2 <- tryCatch(run_all(load_data("SugarReplicate_iter2.dta")),
                 error = function(e) list(dist = NULL, inc = NULL))

# ---- Output ----
cat(sprintf("RESULT:sugar_contributions_district_fe=%.10g\n", safe_coef(main$dist, "sugcont")))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%.10g\n", safe_coef(main$inc, "sugcont")))
cat(sprintf("RESULT:acu_ideology_district_fe=%.10g\n", safe_coef(main$dist, "ncu")))
cat(sprintf("RESULT:tenure_district_fe=%.10g\n", safe_coef(main$dist, "tenure")))
cat(sprintf("RESULT:tenure_incumbent_fe=%.10g\n", safe_coef(main$inc, "tenure")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%.10g\n", safe_coef(alt1$dist, "sugcont")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%.10g\n", safe_coef(alt1$inc, "sugcont")))
cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%.10g\n", safe_coef(alt2$dist, "sugcont")))
cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%.10g\n", safe_coef(alt2$inc, "sugcont")))
cat(sprintf("RESULT:observations_district_fe=%d\n",
            if (is.null(main$dist)) NA_integer_ else as.integer(main$dist$nobs)))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n",
            if (is.null(main$inc)) NA_integer_ else as.integer(main$inc$nobs)))