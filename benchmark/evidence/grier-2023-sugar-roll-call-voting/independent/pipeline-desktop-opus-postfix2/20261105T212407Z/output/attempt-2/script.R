suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(survival)
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

# Robust conversion of the vote variable: it may be stored as a string
# (e.g. "Yea"/"Nay", "Y"/"N", "Aye"/"No") rather than 0/1.
to_vote01 <- function(x) {
  if (is.numeric(x)) {
    v <- as.numeric(x)
    v[!(v %in% c(0, 1))] <- NA
    return(v)
  }
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_real_, length(s))
  yes <- c("1", "yea", "yes", "y", "aye", "for", "pro", "true", "t")
  no  <- c("0", "nay", "no", "n", "against", "con", "false", "f")
  out[s %in% yes] <- 1
  out[s %in% no]  <- 0
  # fall back to numeric parsing for anything else that looks numeric
  rest <- is.na(out) & !is.na(s) & s != ""
  if (any(rest)) {
    num <- suppressWarnings(as.numeric(s[rest]))
    num[!(num %in% c(0, 1))] <- NA
    out[rest] <- num
  }
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
  d$vote <- to_vote01(d$vote)
  # If numeric coding failed (e.g. labelled values other than 0/1), try the value labels
  if (all(is.na(d$vote)) && haven::is.labelled(raw_vote)) {
    d$vote <- to_vote01(as.character(haven::as_factor(raw_vote, levels = "labels")))
  }
  d$sugar <- to_num(d$totalcont)
  for (v in controls) d[[v]] <- to_num(d[[v]])
  d
}

# Keep only strata in which the outcome varies (the only units identifying a conditional logit)
switchers <- function(d, g) {
  d %>% group_by(.data[[g]]) %>%
    filter(n() == 2, n_distinct(vote) == 2) %>% ungroup() %>% as.data.frame()
}

fit_clogit <- function(d, g) {
  fml <- as.formula(paste0("vote ~ sugar + ", paste(controls, collapse = " + "),
                           " + strata(", g, ")"))
  m <- tryCatch(
    survival::clogit(fml, data = d, method = "exact", robust = TRUE),
    error = function(e) survival::clogit(fml, data = d, method = "exact")
  )
  m
}

build_sample <- function(path, name, g, same_incumbent = FALSE) {
  d <- prep(path)
  cat(sprintf("SAMPLE:%s:loaded=%d\n", name, nrow(d)))
  d <- d[!is.na(d$vote) & d$vote %in% c(0, 1), ]
  cat(sprintf("SAMPLE:%s:voted_on_amendment=%d\n", name, nrow(d)))
  if (same_incumbent) {
    d <- d %>% group_by(incid) %>% filter(n() == 2, n_distinct(cong) == 2) %>%
      ungroup() %>% as.data.frame()
    cat(sprintf("SAMPLE:%s:same_incumbent_both_votes=%d\n", name, nrow(d)))
  }
  d <- d[complete.cases(d[, c("vote", "sugar", controls, g)]), ]
  cat(sprintf("SAMPLE:%s:complete_cases=%d\n", name, nrow(d)))
  d <- switchers(d, g)
  cat(sprintf("SAMPLE:%s:vote_changed=%d\n", name, nrow(d)))
  m <- fit_clogit(d, g)
  n_est <- tryCatch(m$n, error = function(e) nrow(d))
  if (is.null(n_est)) n_est <- nrow(d)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", name, as.integer(n_est)))
  list(model = m, n = as.integer(n_est), data = d)
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
  se <- sqrt(diag(vcov(m)))
  cat(sprintf("# %s: sugar coef=%.6f se=%.6f\n", nm, coef(m)["sugar"], se["sugar"]))
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