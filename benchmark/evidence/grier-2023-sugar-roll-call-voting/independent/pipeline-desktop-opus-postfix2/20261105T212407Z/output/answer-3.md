suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(sandwich)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"

# Baseline window (about 18 months) is in SugarReplicate.dta (largest totalcont mean);
# the two 12-month windows are in the _iter files (calendar year = iter1, pre-vote 12 months = iter2).
files <- list(
  baseline = file.path(base_dir, "SugarReplicate.dta"),
  calendar = file.path(base_dir, "SugarReplicate_iter1.dta"),
  months12 = file.path(base_dir, "SugarReplicate_iter2.dta")
)

controls <- c("ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

# Paper: DV is 1 for an "aye" vote on the reform amendment and 0 OTHERWISE
# (so "No", "Not Voting" and "No Vote" are all coded 0).
to_vote01 <- function(x) {
  if (is.numeric(x)) {
    v <- as.numeric(x)
    out <- ifelse(is.na(v), NA_real_, ifelse(v == 1, 1, 0))
    return(out)
  }
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_real_, length(s))
  ok <- !is.na(s) & s != ""
  yes <- c("1", "yea", "yes", "y", "aye", "for", "pro", "true", "t")
  out[ok] <- ifelse(s[ok] %in% yes, 1, 0)
  out
}

to_num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  s <- gsub("[$, ]", "", as.character(x))
  suppressWarnings(as.numeric(s))
}

prep <- function(path) {
  d <- haven::read_dta(path)
  raw_vote <- d$vote
  d <- haven::zap_labels(d)
  d <- as.data.frame(d)
  if (!is.numeric(d$vote)) {
    cat("# vote variable values:", paste(head(unique(as.character(d$vote)), 20), collapse = " | "), "\n")
  }
  d$distid <- paste(as.character(d$state), as.character(d$district), sep = "_")
  d$incid <- as.character(d$cid)
  if (haven::is.labelled(raw_vote)) {
    d$vote <- to_vote01(as.character(haven::as_factor(raw_vote, levels = "labels")))
  } else {
    d$vote <- to_vote01(d$vote)
  }
  d$sugar <- to_num(d$totalcont)
  for (v in controls) d[[v]] <- to_num(d[[v]])
  d
}

# Keep only groups in which the outcome varies (all others are perfectly
# predicted by their fixed effect and are dropped by Stata's logit)
switchers <- function(d, g) {
  d %>% group_by(.data[[g]]) %>%
    filter(n() == 2, n_distinct(vote) == 2) %>% ungroup() %>% as.data.frame()
}

# The paper reports a constant and a pseudo R2, i.e. a logit with fixed-effect
# dummies (Stata: logit vote ... i.fe, robust), not a conditional logit.
fit_fe_logit <- function(d, g) {
  d$fe <- factor(d[[g]])
  fml <- as.formula(paste0("vote ~ sugar + ", paste(controls, collapse = " + "), " + fe"))
  suppressWarnings(glm(fml, data = d, family = binomial(link = "logit"),
                       control = glm.control(maxit = 200, epsilon = 1e-10)))
}

build_sample <- function(path, name, g, same_incumbent = FALSE) {
  d <- prep(path)
  cat(sprintf("SAMPLE:%s:loaded=%d\n", name, nrow(d)))
  d <- d[!is.na(d$vote), ]
  cat(sprintf("SAMPLE:%s:vote_coded=%d\n", name, nrow(d)))
  if (same_incumbent) {
    d <- d %>% group_by(incid) %>% filter(n() == 2, n_distinct(cong) == 2) %>%
      ungroup() %>% as.data.frame()
    cat(sprintf("SAMPLE:%s:same_incumbent_both_votes=%d\n", name, nrow(d)))
  }
  d <- d[complete.cases(d[, c("vote", "sugar", controls, g)]), ]
  cat(sprintf("SAMPLE:%s:complete_cases=%d\n", name, nrow(d)))
  d <- switchers(d, g)
  cat(sprintf("SAMPLE:%s:vote_changed=%d\n", name, nrow(d)))
  m <- fit_fe_logit(d, g)
  n_est <- as.integer(nobs(m))
  cat(sprintf("SAMPLE:%s:estimation=%d\n", name, n_est))
  list(model = m, n = n_est, data = d)
}

res <- list()
res$t1_dist <- build_sample(files$baseline, "table1_district_fe", "distid")
res$t1_inc  <- build_sample(files$baseline, "table1_incumbent_fe", "incid", same_incumbent = TRUE)
res$cal_dist <- build_sample(files$calendar, "table3_calendar_district_fe", "distid")
res$cal_inc  <- build_sample(files$calendar, "table3_calendar_incumbent_fe", "incid", same_incumbent = TRUE)
res$m12_dist <- build_sample(files$months12, "table3_12months_district_fe", "distid")
res$m12_inc  <- build_sample(files$months12, "table3_12months_incumbent_fe", "incid", same_incumbent = TRUE)

if (res$t1_dist$n != 186) cat(sprintf("DEVIATION: district FE sample has %d observations, paper reports 186\n", res$t1_dist$n))
if (res$t1_inc$n != 106) cat(sprintf("DEVIATION: incumbent FE sample has %d observations, paper reports 106\n", res$t1_inc$n))

cf <- function(r, v) unname(coef(r$model)[v])

for (nm in names(res)) {
  m <- res[[nm]]$model
  se <- tryCatch(sqrt(diag(sandwich::vcovHC(m, type = "HC0"))), error = function(e) sqrt(diag(vcov(m))))
  pr2 <- 1 - m$deviance / m$null.deviance
  cat(sprintf("# %s: sugar coef=%.6f robust se=%.6f pseudoR2(within sample)=%.3f\n",
              nm, coef(m)["sugar"], se["sugar"], pr2))
}

cat(sprintf("RESULT:sugar_contributions_district_fe=%.8f\n", cf(res$t1_dist, "sugar")))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%.8f\n", cf(res$t1_inc, "sugar")))
cat(sprintf("RESULT:acu_ideology_district_fe=%.6f\n", cf(res$t1_dist, "ncu")))
cat(sprintf("RESULT:tenure_district_fe=%.6f\n", cf(res$t1_dist, "tenure")))
cat(sprintf("RESULT:tenure_incumbent_fe=%.6f\n", cf(res$t1_inc, "tenure")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%.8f\n", cf(res$cal_dist, "sugar")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%.8f\n", cf(res$cal_inc, "sugar")))
cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%.8f\n", cf(res$m12_dist, "sugar")))
cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%.8f\n", cf(res$m12_inc, "sugar")))
cat(sprintf("RESULT:observations_district_fe=%d\n", res$t1_dist$n))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", res$t1_inc$n))
