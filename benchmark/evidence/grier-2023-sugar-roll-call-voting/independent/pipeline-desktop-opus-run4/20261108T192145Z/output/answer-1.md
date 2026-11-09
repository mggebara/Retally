suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free"

# ---------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------
to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  suppressWarnings(as.numeric(x))
}

recode_vote <- function(v, period) {
  # Returns 1 = aye (reform, against sugar), 0 = no, NA = not voting
  out <- rep(NA_real_, length(v))
  if (inherits(v, "haven_labelled")) {
    labs <- attr(v, "labels")
    vv <- as.numeric(zap_labels(v))
    if (!is.null(labs) && length(labs) > 0) {
      lab_names <- tolower(names(labs))
      aye_vals <- labs[grepl("aye|yea|yes|for", lab_names)]
      no_vals  <- labs[grepl("^no|nay|against", lab_names)]
      if (length(aye_vals) > 0 && length(no_vals) > 0) {
        out[vv %in% as.numeric(aye_vals)] <- 1
        out[vv %in% as.numeric(no_vals)] <- 0
        return(out)
      }
    }
    v <- vv
  }
  if (is.character(v) || is.factor(v)) {
    s <- tolower(trimws(as.character(v)))
    out[s %in% c("aye", "yea", "yes", "y", "1")] <- 1
    out[s %in% c("no", "nay", "n", "0")] <- 0
    return(out)
  }
  vv <- as.numeric(v)
  out[vv %in% c(0, 1)] <- vv[vv %in% c(0, 1)]
  # Orientation check: 2013 aye = 206, no = 221; 2018 aye = 137, no = 278.
  # The second vote (2018) has a clear "no" majority; if the 1s are the
  # majority there, the coding is reversed.
  p2 <- sort(unique(period[!is.na(period)]))
  if (length(p2) >= 2) {
    later <- period == p2[length(p2)]
    ones <- sum(out[later] == 1, na.rm = TRUE)
    zeros <- sum(out[later] == 0, na.rm = TRUE)
    if (ones > zeros) out <- 1 - out
  }
  out
}

prep_data <- function(path) {
  d <- read_dta(path)
  d <- as.data.frame(d)
  period <- to_num(d$cong)
  d$period <- period
  d$aye <- recode_vote(d$vote, period)

  num_vars <- c("sugcont", "ncu", "tenure", "poverty", "bach",
                "medincome", "over65", "agcom", "dwn")
  for (v in num_vars) if (v %in% names(d)) d[[v]] <- to_num(d[[v]])

  # District identifier: use `id` if it identifies a district across the two votes,
  # otherwise state x district number.
  id_num <- d$id
  tab_id <- table(id_num[!is.na(id_num)])
  if (length(tab_id) > 0 && max(tab_id) <= 2 && length(tab_id) >= 400 && length(tab_id) <= 440) {
    d$dist_key <- as.character(id_num)
  } else {
    st <- if ("state_no" %in% names(d)) as.character(to_num(d$state_no)) else as.character(d$state)
    d$dist_key <- paste(st, as.character(to_num(d$district)), sep = "_")
  }

  # Incumbent identifier: CRP candidate id, falling back to name
  cid <- as.character(d$cid)
  cid[is.na(cid) | trimws(cid) == ""] <- NA
  nm <- as.character(d$name)
  d$inc_key <- ifelse(is.na(cid), ifelse(is.na(nm) | trimws(nm) == "", NA, paste0("N_", trimws(tolower(nm)))), cid)
  d
}

ctrl <- "ncu + tenure + poverty + bach + medincome + over65 + agcom"
fml_d <- as.formula(paste("aye ~ sugcont +", ctrl, "| dist_key"))
fml_i <- as.formula(paste("aye ~ sugcont +", ctrl, "| inc_key"))

est_district <- function(d) {
  dd <- d %>%
    filter(!is.na(aye), !is.na(sugcont), !is.na(ncu), !is.na(tenure),
           !is.na(poverty), !is.na(bach), !is.na(medincome), !is.na(over65),
           !is.na(agcom), !is.na(dist_key))
  # keep districts with both votes that switched
  sw <- dd %>% group_by(dist_key) %>%
    summarise(n = n(), s = sum(aye), .groups = "drop") %>%
    filter(n == 2, s == 1)
  dd <- dd %>% filter(dist_key %in% sw$dist_key)
  feglm(fml_d, data = dd, family = binomial("logit"), vcov = "hetero")
}

est_incumbent <- function(d) {
  dd <- d %>%
    filter(!is.na(aye), !is.na(sugcont), !is.na(ncu), !is.na(tenure),
           !is.na(poverty), !is.na(bach), !is.na(medincome), !is.na(over65),
           !is.na(agcom), !is.na(inc_key), !is.na(dist_key))
  # same incumbent in the same district, voting on both amendments, and switching
  sw <- dd %>% group_by(inc_key) %>%
    summarise(n = n(), s = sum(aye), nd = n_distinct(dist_key),
              np = n_distinct(period), .groups = "drop") %>%
    filter(n == 2, np == 2, s == 1)
  dd <- dd %>% filter(inc_key %in% sw$inc_key)
  feglm(fml_i, data = dd, family = binomial("logit"), vcov = "hetero")
}

safe <- function(expr) tryCatch(expr, error = function(e) { message("Error: ", conditionMessage(e)); NULL })

get_coef <- function(m, v) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}

# ---------------------------------------------------------------
# Main window (Table 1)
# ---------------------------------------------------------------
d_main <- prep_data(file.path(base_dir, "SugarReplicate.dta"))
message("Vote tabulation by period (aye coding):")
print(table(d_main$period, d_main$aye, useNA = "ifany"))

m_d <- safe(est_district(d_main))
m_i <- safe(est_incumbent(d_main))
if (!is.null(m_d)) print(summary(m_d))
if (!is.null(m_i)) print(summary(m_i))

# ---------------------------------------------------------------
# Alternative windows (Table 3)
# iter1: calendar-year window; iter2: 12 months before the vote
# ---------------------------------------------------------------
d_cal <- safe(prep_data(file.path(base_dir, "SugarReplicate_iter1.dta")))
d_12m <- safe(prep_data(file.path(base_dir, "SugarReplicate_iter2.dta")))

if (!is.null(d_cal) && !is.null(d_12m)) {
  message("Mean sugcont: main=", mean(d_main$sugcont, na.rm = TRUE),
          " iter1=", mean(d_cal$sugcont, na.rm = TRUE),
          " iter2=", mean(d_12m$sugcont, na.rm = TRUE))
}

m_cal_d <- if (!is.null(d_cal)) safe(est_district(d_cal)) else NULL
m_cal_i <- if (!is.null(d_cal)) safe(est_incumbent(d_cal)) else NULL
m_12m_d <- if (!is.null(d_12m)) safe(est_district(d_12m)) else NULL
m_12m_i <- if (!is.null(d_12m)) safe(est_incumbent(d_12m)) else NULL

# ---------------------------------------------------------------
# Output
# ---------------------------------------------------------------
fmt <- function(x) format(x, digits = 8, scientific = FALSE)

cat("RESULT:sugar_contributions_district_fe=", fmt(get_coef(m_d, "sugcont")), "\n", sep = "")
cat("RESULT:sugar_contributions_incumbent_fe=", fmt(get_coef(m_i, "sugcont")), "\n", sep = "")
cat("RESULT:acu_ideology_district_fe=", fmt(get_coef(m_d, "ncu")), "\n", sep = "")
cat("RESULT:tenure_district_fe=", fmt(get_coef(m_d, "tenure")), "\n", sep = "")
cat("RESULT:tenure_incumbent_fe=", fmt(get_coef(m_i, "tenure")), "\n", sep = "")
cat("RESULT:sugar_contributions_calendar_year_district_fe=", fmt(get_coef(m_cal_d, "sugcont")), "\n", sep = "")
cat("RESULT:sugar_contributions_calendar_year_incumbent_fe=", fmt(get_coef(m_cal_i, "sugcont")), "\n", sep = "")
cat("RESULT:sugar_contributions_12_months_district_fe=", fmt(get_coef(m_12m_d, "sugcont")), "\n", sep = "")
cat("RESULT:sugar_contributions_12_months_incumbent_fe=", fmt(get_coef(m_12m_i, "sugcont")), "\n", sep = "")
cat("RESULT:observations_district_fe=", if (is.null(m_d)) NA else nobs(m_d), "\n", sep = "")
cat("RESULT:observations_incumbent_fe=", if (is.null(m_i)) NA else nobs(m_i), "\n", sep = "")
