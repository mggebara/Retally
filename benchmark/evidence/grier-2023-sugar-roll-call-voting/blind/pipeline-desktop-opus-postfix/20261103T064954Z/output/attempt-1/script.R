suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(survival)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"

load_file <- function(fn) {
  d <- haven::read_dta(file.path(base_dir, fn))
  d <- haven::zap_labels(d)
  d <- as.data.frame(d)
  d
}

df0  <- load_file("SugarReplicate.dta")
dfi1 <- load_file("SugarReplicate_iter1.dta")
dfi2 <- load_file("SugarReplicate_iter2.dta")

num <- function(x) suppressWarnings(as.numeric(x))

prep <- function(d) {
  d$vote_raw <- d$vote
  v <- num(d$vote)
  if (all(is.na(v)) && is.character(d$vote)) {
    s <- tolower(trimws(d$vote))
    v <- ifelse(s %in% c("aye", "yea", "yes", "y"), 1,
                ifelse(s %in% c("no", "nay", "n", "not voting", "present", "nv"), 0, NA))
  }
  # outcome: 1 = aye, 0 otherwise
  d$y <- ifelse(is.na(v), NA, ifelse(v == 1, 1, 0))
  for (nm in c("sugcont", "totalcont", "ncu", "tenure", "poverty", "bach",
               "medincome", "over65", "agcom", "cong", "both")) {
    if (nm %in% names(d)) d[[nm]] <- num(d[[nm]])
  }
  # district key: state + district number
  d$dist_key <- paste(as.character(d$state), as.character(d$district), sep = "_")
  if (max(table(d$dist_key)) > 2 && "id" %in% names(d)) {
    d$dist_key <- as.character(d$id)
  }
  d$inc_key <- as.character(d$cid)
  d
}

df0  <- prep(df0)
dfi1 <- prep(dfi1)
dfi2 <- prep(dfi2)

# Deflator: if totalcont in the baseline file is the nominal version of sugcont,
# recover the per-Congress real/nominal ratio and apply it to alternative windows.
deflate_ratio <- function(d) {
  ok <- !is.na(d$totalcont) & !is.na(d$sugcont) & d$totalcont > 0 & d$sugcont > 0
  if (sum(ok) < 10) return(NULL)
  r <- d$sugcont[ok] / d$totalcont[ok]
  cg <- d$cong[ok]
  out <- tapply(r, cg, median)
  sds <- tapply(r, cg, sd)
  if (all(is.finite(sds)) && all(sds / out < 0.02)) return(out)
  NULL
}
ratio <- deflate_ratio(df0)

make_alt <- function(d) {
  if (!is.null(ratio)) {
    rr <- ratio[as.character(d$cong)]
    rr[is.na(rr)] <- 1
    d$contrib <- d$totalcont * as.numeric(rr)
  } else {
    d$contrib <- d$totalcont
  }
  d
}

df0$contrib  <- df0$sugcont
dfi1 <- make_alt(dfi1)   # calendar-year window (1/1-12/31 of vote year)
dfi2 <- make_alt(dfi2)   # 12 months before each vote

controls <- c("ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

switchers <- function(d, key) {
  g <- d %>% group_by(.data[[key]]) %>%
    mutate(.n = n(), .sd = length(unique(y))) %>% ungroup()
  g <- as.data.frame(g)
  g[g$.n == 2 & g$.sd == 2, , drop = FALSE]
}

run_clogit <- function(d, key, sname, inc = FALSE, print_sample = TRUE) {
  if (print_sample) cat(sprintf("SAMPLE:%s:loaded=%d\n", sname, nrow(d)))
  d <- d[!is.na(d$y), , drop = FALSE]
  if (print_sample) cat(sprintf("SAMPLE:%s:nonmissing_vote=%d\n", sname, nrow(d)))
  if (inc) {
    if ("both" %in% names(d) && any(d$both == 1, na.rm = TRUE)) {
      d <- d[!is.na(d$both) & d$both == 1, , drop = FALSE]
    }
    cnt <- table(d$inc_key)
    d <- d[d$inc_key %in% names(cnt)[cnt == 2], , drop = FALSE]
    if (print_sample) cat(sprintf("SAMPLE:%s:same_incumbent_both_votes=%d\n", sname, nrow(d)))
  }
  vars <- c("y", "contrib", controls, key)
  d <- d[complete.cases(d[, vars]), , drop = FALSE]
  if (print_sample) cat(sprintf("SAMPLE:%s:complete_cases=%d\n", sname, nrow(d)))
  d <- switchers(d, key)
  if (print_sample) cat(sprintf("SAMPLE:%s:vote_switchers=%d\n", sname, nrow(d)))
  d$.strata <- as.integer(factor(d[[key]]))
  f <- as.formula(paste("y ~ contrib +", paste(controls, collapse = " + "),
                        "+ strata(.strata)"))
  m <- survival::clogit(f, data = d, method = "exact", robust = TRUE,
                        cluster = d$.strata)
  nobs_used <- nrow(d)
  if (print_sample) cat(sprintf("SAMPLE:%s:estimation=%d\n", sname, nobs_used))
  list(model = m, n = nobs_used)
}

m_d  <- run_clogit(df0,  "dist_key", "table1_district_fe")
m_i  <- run_clogit(df0,  "inc_key",  "table1_incumbent_fe", inc = TRUE)
m_cd <- run_clogit(dfi1, "dist_key", "table3_calyear_district_fe")
m_ci <- run_clogit(dfi1, "inc_key",  "table3_calyear_incumbent_fe", inc = TRUE)
m_td <- run_clogit(dfi2, "dist_key", "table3_12months_district_fe")
m_ti <- run_clogit(dfi2, "inc_key",  "table3_12months_incumbent_fe", inc = TRUE)

cf <- function(r, v) unname(coef(r$model)[v])

cat(sprintf("RESULT:sugar_contributions_district_fe=%.10g\n", cf(m_d, "contrib")))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%.10g\n", cf(m_i, "contrib")))
cat(sprintf("RESULT:acu_ideology_district_fe=%.10g\n", cf(m_d, "ncu")))
cat(sprintf("RESULT:tenure_district_fe=%.10g\n", cf(m_d, "tenure")))
cat(sprintf("RESULT:tenure_incumbent_fe=%.10g\n", cf(m_i, "tenure")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%.10g\n", cf(m_cd, "contrib")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%.10g\n", cf(m_ci, "contrib")))
cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%.10g\n", cf(m_td, "contrib")))
cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%.10g\n", cf(m_ti, "contrib")))
cat(sprintf("RESULT:observations_district_fe=%d\n", m_d$n))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", m_i$n))