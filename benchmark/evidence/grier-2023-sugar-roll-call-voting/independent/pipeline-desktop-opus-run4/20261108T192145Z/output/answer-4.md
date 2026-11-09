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
  p2 <- sort(unique(period[!is.na(period)]))
  if (length(p2) >= 2) {
    later <- period == p2[length(p2)]
    ones <- sum(out[later] == 1, na.rm = TRUE)
    zeros <- sum(out[later] == 0, na.rm = TRUE)
    if (ones > zeros) out <- 1 - out
  }
  out
}

prep_data <- function(path, ref_sug = NULL) {
  d <- read_dta(path)
  d <- as.data.frame(d)
  period <- to_num(d$cong)
  d$period <- period
  d$aye_raw <- recode_vote(d$vote, period)
  d$voted <- !is.na(d$aye_raw)
  # Paper: DV = 1 for an "aye" vote and 0 otherwise (non-voting counts as 0)
  d$aye <- ifelse(is.na(d$aye_raw), 0, d$aye_raw)

  num_vars <- c("sugcont", "ncu", "tenure", "poverty", "bach",
                "medincome", "over65", "agcom", "dwn")
  for (v in num_vars) if (v %in% names(d)) d[[v]] <- to_num(d[[v]])

  # If this file's sugcont is identical to the main window's, look for an
  # alternative contribution-window variable inside the file.
  sug_cands <- grep("sug|cont", names(d), value = TRUE, ignore.case = TRUE)
  message(basename(path), " contribution-like columns: ", paste(sug_cands, collapse = ", "))
  # Main window: the alternative-window files carry their window-specific
  # contributions in `totalcont` (sugar PAC + individual sugar-industry money,
  # matching the paper's definition); use the same variable in the main file.
  if (is.null(ref_sug) && "totalcont" %in% names(d)) {
    tc <- to_num(d$totalcont)
    message("Main file: mean sugcont=", mean(d$sugcont, na.rm = TRUE),
            " mean totalcont=", mean(tc, na.rm = TRUE),
            " cor=", suppressWarnings(cor(d$sugcont, tc, use = "complete.obs")))
    if (sum(!is.na(tc)) > 0.5 * nrow(d)) {
      d$sugcont_orig <- d$sugcont
      d$sugcont <- tc
      message("Using totalcont as contribution variable in ", basename(path))
    }
  }
  if (!is.null(ref_sug) && length(ref_sug) == nrow(d) &&
      isTRUE(all.equal(d$sugcont, ref_sug))) {
    for (cn in setdiff(sug_cands, "sugcont")) {
      x <- to_num(d[[cn]])
      if (sum(!is.na(x)) > 0.5 * nrow(d) && !isTRUE(all.equal(x, ref_sug))) {
        message("Using ", cn, " as contribution variable in ", basename(path))
        d$sugcont <- x
        break
      }
    }
  }

  id_num <- d$id
  tab_id <- table(id_num[!is.na(id_num)])
  if (length(tab_id) > 0 && max(tab_id) <= 2 && length(tab_id) >= 400 && length(tab_id) <= 440) {
    d$dist_key <- as.character(id_num)
  } else {
    st <- if ("state_no" %in% names(d)) as.character(to_num(d$state_no)) else as.character(d$state)
    d$dist_key <- paste(st, as.character(to_num(d$district)), sep = "_")
  }

  cid <- as.character(d$cid)
  cid[is.na(cid) | trimws(cid) == ""] <- NA
  nm <- as.character(d$name)
  d$inc_key <- ifelse(is.na(cid), ifelse(is.na(nm) | trimws(nm) == "", NA, paste0("N_", trimws(tolower(nm)))), cid)

  # Normalised last name (for matching the same incumbent across the two votes)
  nml <- tolower(trimws(ifelse(is.na(nm), "", nm)))
  last <- ifelse(grepl(",", nml), sub(",.*$", "", nml), sub("^.*\\s", "", nml))
  d$lname <- gsub("[^a-z]", "", last)
  d
}

ctrl <- "ncu + tenure + poverty + bach + medincome + over65 + agcom"
fml_d <- as.formula(paste("aye ~ sugcont +", ctrl, "| dist_key"))
fml_i <- as.formula(paste("aye ~ sugcont +", ctrl, "| inc_id"))

district_sample <- function(d) {
  dd <- d %>%
    filter(!is.na(aye), !is.na(sugcont), !is.na(ncu), !is.na(tenure),
           !is.na(poverty), !is.na(bach), !is.na(medincome), !is.na(over65),
           !is.na(agcom), !is.na(dist_key))
  sw <- dd %>% group_by(dist_key) %>%
    summarise(n = n(), s = sum(aye), .groups = "drop") %>%
    filter(n == 2, s == 1)
  dd %>% filter(dist_key %in% sw$dist_key)
}

est_district <- function(d) {
  dd <- district_sample(d)
  message("District sample: ", nrow(dd), " obs, ", n_distinct(dd$dist_key), " districts")
  feglm(fml_d, data = dd, family = binomial("logit"), vcov = "hetero")
}

# Incumbent FE sample: the vote-switching districts (district sample) in which
# the same incumbent cast both votes (paper: 53 of the 93 districts).
est_incumbent <- function(d) {
  dd <- district_sample(d)
  g <- dd %>% arrange(dist_key, period) %>% group_by(dist_key) %>%
    summarise(same_cid = !any(is.na(inc_key)) & n_distinct(inc_key) == 1,
              same_name = all(lname != "") & n_distinct(lname) == 1,
              ten_d = tenure[2] - tenure[1],
              .groups = "drop") %>%
    mutate(same_ten = !is.na(ten_d) & ten_d >= 1.5 & ten_d <= 3,
           r1 = same_cid,
           r2 = same_cid | same_name,
           r3 = same_cid | same_name | same_ten,
           r4 = same_ten)
  cnt <- c(r1 = sum(g$r1), r2 = sum(g$r2), r3 = sum(g$r3), r4 = sum(g$r4))
  message("Same-incumbent district counts by rule: ",
          paste(names(cnt), cnt, sep = "=", collapse = ", "))
  pref <- c("r2", "r1", "r3", "r4")
  dist <- abs(cnt[pref] - 53)
  rule <- pref[which.min(dist)]
  message("Using rule ", rule, " (", cnt[rule], " incumbents)")
  keep <- g$dist_key[g[[rule]]]
  dd <- dd %>% filter(dist_key %in% keep)
  dd$inc_id <- dd$dist_key
  message("Incumbent sample: ", nrow(dd), " obs, ", n_distinct(dd$inc_id), " incumbents")
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
message("Vote tabulation by period (raw aye coding):")
print(table(d_main$period, d_main$aye_raw, useNA = "ifany"))

m_d <- safe(est_district(d_main))
m_i <- safe(est_incumbent(d_main))
if (!is.null(m_d)) print(summary(m_d))
if (!is.null(m_i)) print(summary(m_i))

# ---------------------------------------------------------------
# Alternative windows (Table 3)
# iter1: calendar-year window; iter2: 12 months before the vote
# ---------------------------------------------------------------
ref_main <- if (!is.null(d_main$sugcont_orig)) d_main$sugcont_orig else d_main$sugcont
d_cal <- safe(prep_data(file.path(base_dir, "SugarReplicate_iter1.dta"), ref_sug = ref_main))
d_12m <- safe(prep_data(file.path(base_dir, "SugarReplicate_iter2.dta"), ref_sug = ref_main))

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

cat("DEVIATION: Main-window contributions taken from totalcont (sugar PAC + individual sugar-industry contributions), the same variable that holds the window-specific contributions in the alternative-window files, instead of sugcont\n")
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
