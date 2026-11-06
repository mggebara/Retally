suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(survival)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"

load_data <- function(fname) {
  d <- haven::read_dta(file.path(base_dir, fname))
  d <- haven::zap_labels(d)
  d <- as.data.frame(d)
  d
}

prep <- function(d) {
  d$vote <- as.numeric(d$vote)
  # ensure 0/1 coding for "aye"
  uv <- sort(unique(na.omit(d$vote)))
  if (!all(uv %in% c(0, 1))) {
    if (all(uv %in% c(1, 2))) d$vote <- ifelse(d$vote == 1, 1, 0)
    else d$vote <- ifelse(d$vote > 0, 1, 0)
  }
  d$state_key <- as.character(d$state)
  d$dist_key <- paste(d$state_key, as.character(d$district), sep = "_")
  d$cid <- as.character(d$cid)
  d
}

# Regressor: inflation-adjusted sugar contributions. The contribution-window files differ
# only in totalcont, so totalcont is the window-specific contribution measure.
ctrl <- c("ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

fit_clogit <- function(d, contvar, group, sname) {
  vars <- c("vote", contvar, ctrl, group)
  cat(sprintf("SAMPLE:%s:loaded=%d\n", sname, nrow(d)))
  d <- d[!is.na(d$vote), ]
  cat(sprintf("SAMPLE:%s:voted=%d\n", sname, nrow(d)))
  if (group == "cid") {
    d <- d[!is.na(d$cid) & d$cid != "", ]
    tab <- table(d$cid)
    d <- d[d$cid %in% names(tab)[tab == 2], ]
    d <- d[ave(d$cong, d$cid, FUN = function(x) length(unique(x))) == 2, ]
    cat(sprintf("SAMPLE:%s:same_incumbent_both_votes=%d\n", sname, nrow(d)))
  }
  d <- d[complete.cases(d[, vars]), ]
  cat(sprintf("SAMPLE:%s:complete_cases=%d\n", sname, nrow(d)))
  g <- d[[group]]
  nvals <- ave(d$vote, g, FUN = function(x) length(unique(x)))
  ng <- ave(d$vote, g, FUN = length)
  d <- d[nvals == 2 & ng >= 2, ]
  cat(sprintf("SAMPLE:%s:vote_switchers=%d\n", sname, nrow(d)))
  d$grp <- d[[group]]
  fml <- as.formula(paste("vote ~", paste(c(contvar, ctrl), collapse = " + "), "+ strata(grp)"))
  m <- survival::clogit(fml, data = d, method = "exact")
  cat(sprintf("SAMPLE:%s:estimation=%d\n", sname, nrow(d)))
  list(model = m, n = nrow(d))
}

main <- prep(load_data("SugarReplicate.dta"))
cal  <- prep(load_data("SugarReplicate_iter1.dta"))
m12  <- prep(load_data("SugarReplicate_iter2.dta"))

r_d   <- fit_clogit(main, "totalcont", "dist_key", "table1_district_fe")
r_i   <- fit_clogit(main, "totalcont", "cid", "table1_incumbent_fe")
r_cd  <- fit_clogit(cal, "totalcont", "dist_key", "table3_calendar_district_fe")
r_ci  <- fit_clogit(cal, "totalcont", "cid", "table3_calendar_incumbent_fe")
r_md  <- fit_clogit(m12, "totalcont", "dist_key", "table3_12months_district_fe")
r_mi  <- fit_clogit(m12, "totalcont", "cid", "table3_12months_incumbent_fe")

cf <- function(r, v) unname(coef(r$model)[v])

cat(sprintf("RESULT:sugar_contributions_district_fe=%.10g\n", cf(r_d, "totalcont")))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%.10g\n", cf(r_i, "totalcont")))
cat(sprintf("RESULT:acu_ideology_district_fe=%.10g\n", cf(r_d, "ncu")))
cat(sprintf("RESULT:tenure_district_fe=%.10g\n", cf(r_d, "tenure")))
cat(sprintf("RESULT:tenure_incumbent_fe=%.10g\n", cf(r_i, "tenure")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%.10g\n", cf(r_cd, "totalcont")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%.10g\n", cf(r_ci, "totalcont")))
cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%.10g\n", cf(r_md, "totalcont")))
cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%.10g\n", cf(r_mi, "totalcont")))
cat(sprintf("RESULT:observations_district_fe=%d\n", r_d$n))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", r_i$n))
