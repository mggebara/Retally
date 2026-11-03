suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"
d0 <- read_dta(file.path(base_dir, "SugarReplicate.dta"))
d1 <- read_dta(file.path(base_dir, "SugarReplicate_iter1.dta"))
d2 <- read_dta(file.path(base_dir, "SugarReplicate_iter2.dta"))

strip <- function(df) {
  df <- as.data.frame(zap_labels(df))
  df
}
d0 <- strip(d0); d1 <- strip(d1); d2 <- strip(d2)

# Contribution measures. The three files share 26 identical columns (same row order);
# only totalcont differs. SugarReplicate.dta: baseline window (~18 months, largest mean);
# iter1: calendar-year window; iter2: 12 months before the vote.
d0$cont_base <- as.numeric(d0$totalcont)
d0$cont_cal  <- as.numeric(d1$totalcont)
d0$cont_12m  <- as.numeric(d2$totalcont)
cat(sprintf("DIAG: mean totalcont base=%.2f cal=%.2f 12m=%.2f sugcont=%.2f\n",
            mean(d0$cont_base, na.rm = TRUE), mean(d0$cont_cal, na.rm = TRUE),
            mean(d0$cont_12m, na.rm = TRUE), mean(as.numeric(d0$sugcont), na.rm = TRUE)))

# Vote coding: 1 = aye on reform amendment, 0 = no, missing otherwise
v <- d0$vote
if (is.character(v)) {
  vv <- tolower(trimws(v))
  d0$vote <- ifelse(vv %in% c("aye", "yes", "yea", "y", "1"), 1,
                    ifelse(vv %in% c("no", "nay", "n", "0"), 0, NA))
} else {
  v <- as.numeric(v)
  uv <- sort(unique(v[!is.na(v)]))
  cat(sprintf("DIAG: vote values = %s\n", paste(uv, collapse = ",")))
  if (!all(uv %in% c(0, 1))) {
    # assume 1 = aye, anything else in {0,2} etc = no
    d0$vote <- ifelse(v == 1, 1, ifelse(is.na(v), NA, 0))
  } else {
    d0$vote <- v
  }
}
# Paper: DV is 1 for an "aye" vote on the reform amendment and 0 otherwise.
# Members recorded as not voting are therefore coded 0 rather than dropped.
cat(sprintf("DIAG: non-voting rows recoded to 0 = %d\n", sum(is.na(d0$vote))))
d0$vote[is.na(d0$vote)] <- 0

# Identifiers
d0$cong <- as.numeric(d0$cong)
d0$dist_key <- paste(as.character(d0$state), as.character(d0$district), sep = "_")
cid <- as.character(d0$cid)
cid[is.na(cid) | cid == ""] <- paste0("NAME_", as.character(d0$name[is.na(cid) | cid == ""]))
d0$inc_key <- cid

controls <- c("ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")
for (v in controls) d0[[v]] <- as.numeric(d0[[v]])

fit_fe <- function(d, xvar, fe) {
  d$x_cont <- d[[xvar]]
  fml <- as.formula(paste0("vote ~ x_cont + ", paste(controls, collapse = " + "), " | ", fe))
  m <- tryCatch(feglm(fml, data = d, family = binomial("logit"), vcov = "hetero"),
                error = function(e) NULL)
  if (is.null(m)) {
    fml2 <- as.formula(paste0("vote ~ x_cont + ", paste(controls, collapse = " + "),
                              " + factor(", fe, ")"))
    m <- glm(fml2, data = d, family = binomial("logit"))
  }
  m
}
get_coef <- function(m) unname(coef(m)["x_cont"])
get_coef_v <- function(m, v) unname(coef(m)[v])

build_district <- function(d, xvar, name) {
  cat(sprintf("SAMPLE:%s:loaded=%d\n", name, nrow(d)))
  s <- d[!is.na(d$vote), ]
  cat(sprintf("SAMPLE:%s:voted=%d\n", name, nrow(s)))
  s <- s[complete.cases(s[, c(xvar, controls)]), ]
  cat(sprintf("SAMPLE:%s:nonmissing_covariates=%d\n", name, nrow(s)))
  s <- s %>% group_by(dist_key) %>%
    filter(n() == 2, n_distinct(cong) == 2, n_distinct(vote) == 2) %>% ungroup() %>% as.data.frame()
  cat(sprintf("SAMPLE:%s:vote_switching_districts=%d\n", name, nrow(s)))
  s
}
build_incumbent <- function(d, xvar, name) {
  cat(sprintf("SAMPLE:%s:loaded=%d\n", name, nrow(d)))
  s <- d[!is.na(d$vote), ]
  cat(sprintf("SAMPLE:%s:voted=%d\n", name, nrow(s)))
  s <- s[complete.cases(s[, c(xvar, controls)]), ]
  cat(sprintf("SAMPLE:%s:nonmissing_covariates=%d\n", name, nrow(s)))
  s <- s %>% group_by(inc_key) %>%
    filter(n_distinct(cong) == 2) %>% ungroup() %>% as.data.frame()
  cat(sprintf("SAMPLE:%s:same_incumbent_both_votes=%d\n", name, nrow(s)))
  s <- s %>% group_by(inc_key) %>%
    filter(n() == 2, n_distinct(vote) == 2) %>% ungroup() %>% as.data.frame()
  cat(sprintf("SAMPLE:%s:vote_switching_incumbents=%d\n", name, nrow(s)))
  s
}

res <- list()

# Table 1 col 1: district FE
s_d <- build_district(d0, "cont_base", "table1_district_fe")
# Stata's -logit ... i.district, robust- estimates the district intercepts as explicit
# dummies with likelihood-based IRLS convergence. With the quasi-separated Ag Committee
# term, the stopping point matters for the finite-iteration estimates, so mirror that
# unconditional dummy-variable logit (stats::glm, default IRLS stopping rule) here.
fit_dummy_logit <- function(d, xvar, fe) {
  d$x_cont <- d[[xvar]]
  fml <- as.formula(paste0("vote ~ x_cont + ", paste(controls, collapse = " + "),
                           " + factor(", fe, ")"))
  suppressWarnings(glm(fml, data = d, family = binomial("logit"),
                       control = glm.control(epsilon = 1e-7, maxit = 25)))
}
m_d <- fit_dummy_logit(s_d, "cont_base", "dist_key")
cat("DEVIATION: Table 1 col 1 estimated as dummy-variable logit via stats::glm (Stata logit i.district analogue, epsilon=1e-7) instead of fixest::feglm; point estimates only, robust SEs not used for any RESULT\n")
cat(sprintf("SAMPLE:table1_district_fe:estimation=%d\n", nobs(m_d)))
if (nobs(m_d) != 186) cat(sprintf("DEVIATION: district FE sample has %d obs vs 186 in paper\n", nobs(m_d)))

# Table 1 col 2: incumbent FE
s_i <- build_incumbent(d0, "cont_base", "table1_incumbent_fe")
m_i <- fit_fe(s_i, "cont_base", "inc_key")
cat(sprintf("SAMPLE:table1_incumbent_fe:estimation=%d\n", nobs(m_i)))
if (nobs(m_i) != 106) cat(sprintf("DEVIATION: incumbent FE sample has %d obs vs 106 in paper\n", nobs(m_i)))

# Table 3: calendar-year windows
s_dc <- build_district(d0, "cont_cal", "table3_calendar_district_fe")
m_dc <- fit_fe(s_dc, "cont_cal", "dist_key")
cat(sprintf("SAMPLE:table3_calendar_district_fe:estimation=%d\n", nobs(m_dc)))
s_ic <- build_incumbent(d0, "cont_cal", "table3_calendar_incumbent_fe")
m_ic <- fit_fe(s_ic, "cont_cal", "inc_key")
cat(sprintf("SAMPLE:table3_calendar_incumbent_fe:estimation=%d\n", nobs(m_ic)))

# Table 3: 12 months before vote
s_d12 <- build_district(d0, "cont_12m", "table3_12m_district_fe")
m_d12 <- fit_fe(s_d12, "cont_12m", "dist_key")
cat(sprintf("SAMPLE:table3_12m_district_fe:estimation=%d\n", nobs(m_d12)))
s_i12 <- build_incumbent(d0, "cont_12m", "table3_12m_incumbent_fe")
m_i12 <- fit_fe(s_i12, "cont_12m", "inc_key")
cat(sprintf("SAMPLE:table3_12m_incumbent_fe:estimation=%d\n", nobs(m_i12)))

print(summary(m_d))
print(summary(m_i))

fmt <- function(x) format(x, digits = 8, scientific = FALSE)
cat(sprintf("RESULT:sugar_contributions_district_fe=%s\n", fmt(get_coef(m_d))))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%s\n", fmt(get_coef(m_i))))
cat(sprintf("RESULT:acu_ideology_district_fe=%s\n", fmt(get_coef_v(m_d, "ncu"))))
cat(sprintf("RESULT:tenure_district_fe=%s\n", fmt(get_coef_v(m_d, "tenure"))))
cat(sprintf("RESULT:tenure_incumbent_fe=%s\n", fmt(get_coef_v(m_i, "tenure"))))
cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%s\n", fmt(get_coef(m_dc))))
cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%s\n", fmt(get_coef(m_ic))))
cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%s\n", fmt(get_coef(m_d12))))
cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%s\n", fmt(get_coef(m_i12))))
cat(sprintf("RESULT:observations_district_fe=%d\n", as.integer(nobs(m_d))))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", as.integer(nobs(m_i))))