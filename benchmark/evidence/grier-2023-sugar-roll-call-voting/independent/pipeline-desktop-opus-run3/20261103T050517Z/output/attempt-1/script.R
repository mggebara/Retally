suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
  library(sandwich)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"

recode_vote <- function(v) {
  if (inherits(v, "haven_labelled")) {
    labs <- attr(v, "labels")
    vv <- as.numeric(v)
    if (!is.null(labs) && length(labs) > 0) {
      nm <- tolower(names(labs))
      yes_codes <- labs[grepl("aye|yes|yea|^y$|for", nm)]
      no_codes <- labs[grepl("^no|nay|^n$|against", nm)]
      if (length(yes_codes) > 0) {
        out <- ifelse(vv %in% yes_codes, 1, ifelse(is.na(vv), NA, 0))
        if (length(no_codes) > 0) out[!(vv %in% c(yes_codes, no_codes))] <- NA
        return(out)
      }
    }
    v <- vv
  }
  if (is.character(v) || is.factor(v)) {
    s <- tolower(trimws(as.character(v)))
    out <- ifelse(s %in% c("aye", "yes", "yea", "y", "1"), 1,
                  ifelse(s %in% c("no", "nay", "n", "0"), 0, NA))
    return(out)
  }
  v <- as.numeric(v)
  u <- sort(unique(v[!is.na(v)]))
  if (all(u %in% c(0, 1))) return(v)
  if (all(u %in% c(1, 2))) return(ifelse(v == 1, 1, 0))
  # otherwise treat positive as aye, others as no
  ifelse(is.na(v), NA, ifelse(v == 1, 1, 0))
}

prep <- function(path) {
  d <- read_dta(path)
  df <- data.frame(
    vote = recode_vote(d$vote),
    sugcont = as.numeric(zap_labels(d$sugcont)),
    acu = as.numeric(zap_labels(d$ncu)),
    tenure = as.numeric(zap_labels(d$tenure)),
    poverty = as.numeric(zap_labels(d$poverty)),
    bach = as.numeric(zap_labels(d$bach)),
    medincome = as.numeric(zap_labels(d$medincome)),
    over65 = as.numeric(zap_labels(d$over65)),
    agcom = as.numeric(zap_labels(d$agcom)),
    cong = as.numeric(zap_labels(d$cong)),
    state = as.character(as_factor(d$state)),
    district = as.character(zap_labels(d$district)),
    cid = as.character(zap_labels(d$cid)),
    stringsAsFactors = FALSE
  )
  df$distid <- paste(df$state, df$district, sep = "_")
  # if district already unique within each congress, it can be used directly
  if (all(table(paste(df$district, df$cong)) <= 1)) df$distid <- df$district
  df
}

fit_fe <- function(df, fe) {
  vars <- c("vote", "sugcont", "acu", "tenure", "poverty", "bach",
            "medincome", "over65", "agcom", fe)
  d <- df[complete.cases(df[, vars]), vars]
  d$fe_id <- d[[fe]]
  # keep only units observed twice with a change in vote
  d <- d %>% group_by(fe_id) %>%
    filter(n() == 2, length(unique(vote)) == 2) %>% ungroup() %>% as.data.frame()
  fml <- vote ~ sugcont + acu + tenure + poverty + bach + medincome + over65 + agcom | fe_id
  m <- tryCatch(feglm(fml, data = d, family = binomial("logit"), vcov = "hetero"),
                error = function(e) NULL)
  if (!is.null(m)) {
    b <- coef(m)
    return(list(coef = b, n = nobs(m)))
  }
  g <- glm(vote ~ sugcont + acu + tenure + poverty + bach + medincome + over65 +
             agcom + factor(fe_id), data = d, family = binomial("logit"),
           control = glm.control(maxit = 200))
  list(coef = coef(g), n = nobs(g))
}

run_both <- function(path) {
  df <- prep(path)
  dist <- fit_fe(df, "distid")
  # incumbent sample: same member in both congresses
  inc_df <- df %>% filter(!is.na(cid), cid != "") %>%
    group_by(cid) %>% filter(n_distinct(cong) == 2) %>% ungroup() %>% as.data.frame()
  inc <- fit_fe(inc_df, "cid")
  list(dist = dist, inc = inc)
}

out <- function(name, val) cat(sprintf("RESULT:%s=%.8g\n", name, as.numeric(val)))

base <- run_both(file.path(base_dir, "SugarReplicate.dta"))
out("sugar_contributions_district_fe", base$dist$coef["sugcont"])
out("sugar_contributions_incumbent_fe", base$inc$coef["sugcont"])
out("acu_ideology_district_fe", base$dist$coef["acu"])
out("tenure_district_fe", base$dist$coef["tenure"])
out("tenure_incumbent_fe", base$inc$coef["tenure"])

cal <- tryCatch(run_both(file.path(base_dir, "SugarReplicate_iter1.dta")), error = function(e) NULL)
if (!is.null(cal)) {
  out("sugar_contributions_calendar_year_district_fe", cal$dist$coef["sugcont"])
  out("sugar_contributions_calendar_year_incumbent_fe", cal$inc$coef["sugcont"])
}
m12 <- tryCatch(run_both(file.path(base_dir, "SugarReplicate_iter2.dta")), error = function(e) NULL)
if (!is.null(m12)) {
  out("sugar_contributions_12_months_district_fe", m12$dist$coef["sugcont"])
  out("sugar_contributions_12_months_incumbent_fe", m12$inc$coef["sugcont"])
}

out("observations_district_fe", base$dist$n)
out("observations_incumbent_fe", base$inc$n)