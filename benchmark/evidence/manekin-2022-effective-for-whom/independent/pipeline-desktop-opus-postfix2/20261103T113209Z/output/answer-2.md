suppressPackageStartupMessages({
  library(stats)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/manekin_2022_effective_for_whom.script-free"
load(file.path(base_dir, "Replication/Data/us_survey_wave1.rdata"))
load(file.path(base_dir, "Replication/Data/isr_survey_wave1.rdata"))
load(file.path(base_dir, "Replication/Data/us_survey_wave2.rdata"))
load(file.path(base_dir, "Replication/Data/isr_survey_wave2.rdata"))

lev_str <- function(x) {
  if (is.factor(x)) levels(x) else sort(unique(as.character(x[!is.na(x)])))
}

# Build a factor with a chosen base level identified by regex (fallback: first level)
make_factor <- function(x, base_pattern, exclude_pattern = NULL) {
  if (haven_like <- inherits(x, "haven_labelled")) {
    x <- haven::as_factor(x)
  }
  f <- if (is.factor(x)) droplevels(x) else factor(x)
  lv <- levels(f)
  cand <- grepl(base_pattern, tolower(lv))
  if (!is.null(exclude_pattern)) cand <- cand & !grepl(exclude_pattern, tolower(lv))
  base <- if (any(cand)) lv[which(cand)[1]] else lv[1]
  relevel(f, ref = base)
}

# Convert a two-valued indicator (numeric, logical, factor, character) to 0/1
to_dummy <- function(x, yes_pattern) {
  if (inherits(x, "haven_labelled")) x <- haven::as_factor(x)
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) {
    u <- sort(unique(x[!is.na(x)]))
    if (all(u %in% c(0, 1))) return(as.numeric(x))
    return(as.numeric(x == max(u)))
  }
  s <- tolower(as.character(x))
  u <- sort(unique(s[!is.na(s)]))
  if (all(u %in% c("0", "1"))) return(as.numeric(s))
  yes <- grepl(yes_pattern, u) & !grepl("^no\\b|^no$|not |^none|general|layoff|no commit|without", u)
  if (sum(yes) == 1) return(as.numeric(s == u[yes]))
  # fallback: second level = 1
  f <- if (is.factor(x)) droplevels(x) else factor(x)
  as.numeric(as.integer(f) == 2)
}

get_coef <- function(m, pattern) {
  cf <- coef(m)
  nm <- names(cf)
  idx <- which(grepl(pattern, tolower(nm)))
  if (length(idx) == 0) return(c(NA_real_, NA_real_))
  se <- sqrt(diag(vcov(m)))
  c(unname(cf[idx[1]]), unname(se[nm[idx[1]]]))
}

# Try a label-based pattern first; fall back to the numeric-coded term name
get_coef2 <- function(m, pattern, fallback_pattern) {
  b <- get_coef(m, pattern)
  if (is.na(b[1])) b <- get_coef(m, fallback_pattern)
  b
}

emit <- list()
add <- function(name, val) emit[[name]] <<- val

# ---------------- Study 1 US ----------------
us1 <- us_survey_wave1
cat("NOTE: us1 identity levels:", paste(lev_str(us1$identity_protesters), collapse = " | "), "\n")
cat("NOTE: us1 tactic levels:", paste(lev_str(us1$tactic), collapse = " | "), "\n")
cat(sprintf("SAMPLE:study1_us:loaded=%d\n", nrow(us1)))
us1$identity_f <- make_factor(us1$identity_protesters, "white|charlie|majority", "black|tyrone")
us1$tactic_f <- make_factor(us1$tactic, "march|street|walk")
us1$w <- as.numeric(us1$weight)
use_w_us1 <- !any(is.na(us1$w))
if (!use_w_us1) cat("DEVIATION: missing survey weights in US Study 1; estimating unweighted\n")

fit1 <- function(df, y, use_w, rhs) {
  f <- as.formula(paste(y, "~", rhs))
  if (use_w) lm(f, data = df, weights = w) else lm(f, data = df)
}

m_us1_v <- fit1(us1, "degree_violence", use_w_us1, "identity_f + tactic_f")
m_us1_p <- fit1(us1, "police_action_required", use_w_us1, "identity_f + tactic_f")
cat(sprintf("SAMPLE:study1_us:estimation=%d\n", nobs(m_us1_v)))
cat(sprintf("SAMPLE:study1_us_police:loaded=%d\n", nrow(us1)))
cat(sprintf("SAMPLE:study1_us_police:estimation=%d\n", nobs(m_us1_p)))
b <- get_coef(m_us1_v, "black|tyrone|identity_f")
add("study1_us_black_perceived_violence", b[1]); add("study1_us_black_perceived_violence_se", b[2])
b <- get_coef(m_us1_p, "black|tyrone|identity_f")
add("study1_us_black_police_action", b[1]); add("study1_us_black_police_action_se", b[2])
add("respondents_study1_us", nobs(m_us1_v))

# ---------------- Study 1 Israel ----------------
is1 <- isr_survey_wave1
cat("NOTE: isr1 identity levels:", paste(lev_str(is1$identity_protesters), collapse = " | "), "\n")
cat("NOTE: isr1 tactic levels:", paste(lev_str(is1$tactic), collapse = " | "), "\n")
if (!is.null(attr(is1$identity_protesters, "labels"))) {
  cat("NOTE: isr1 identity labels:", paste(names(attr(is1$identity_protesters, "labels")), attr(is1$identity_protesters, "labels"), sep = "=", collapse = " | "), "\n")
}
cat(sprintf("SAMPLE:study1_israel:loaded=%d\n", nrow(is1)))
is1$identity_f <- make_factor(is1$identity_protesters, "white|majority|ashkenaz|jew", "ethiop|arab")
is1$tactic_f <- make_factor(is1$tactic, "march|street|walk")
is1$w <- as.numeric(is1$weight)
use_w_is1 <- !any(is.na(is1$w))
if (!use_w_is1) cat("DEVIATION: missing survey weights in Israel Study 1; estimating unweighted\n")

m_is1_v <- fit1(is1, "degree_violence", use_w_is1, "identity_f + tactic_f")
m_is1_p <- fit1(is1, "police_action_required", use_w_is1, "identity_f + tactic_f")
cat("NOTE: isr1 model terms:", paste(names(coef(m_is1_v)), collapse = " | "), "\n")
cat("NOTE: identity coded 0 = Ashkenazi Jewish (reference), 1 = Ethiopian Jewish, 2 = Arab (numeric coding, labels absent)\n")
cat(sprintf("SAMPLE:study1_israel:estimation=%d\n", nobs(m_is1_v)))
cat(sprintf("SAMPLE:study1_israel_police:loaded=%d\n", nrow(is1)))
cat(sprintf("SAMPLE:study1_israel_police:estimation=%d\n", nobs(m_is1_p)))
b <- get_coef2(m_is1_v, "identity_f.*ethiop", "^identity_f1$")
add("study1_israel_ethiopian_perceived_violence", b[1]); add("study1_israel_ethiopian_perceived_violence_se", b[2])
b <- get_coef2(m_is1_p, "identity_f.*ethiop", "^identity_f1$")
add("study1_israel_ethiopian_police_action", b[1]); add("study1_israel_ethiopian_police_action_se", b[2])
b <- get_coef2(m_is1_v, "identity_f.*arab", "^identity_f2$")
add("study1_israel_arab_perceived_violence", b[1]); add("study1_israel_arab_perceived_violence_se", b[2])
b <- get_coef2(m_is1_p, "identity_f.*arab", "^identity_f2$")
add("study1_israel_arab_police_action", b[1]); add("study1_israel_arab_police_action_se", b[2])
add("respondents_study1_israel", nobs(m_is1_v))

# ---------------- Study 2 US ----------------
us2 <- us_survey_wave2
cat(sprintf("SAMPLE:study2_us:loaded=%d\n", nrow(us2)))
us2$black_d <- to_dummy(us2$black, "black|tyrone|^1$|yes")
us2$goal_d <- to_dummy(us2$group_goal, "group|minority|racis|police|brutal|yes")
us2$commit_d <- to_dummy(us2$commitment, "commit|yes|nonviol")
m_us2_v <- lm(degree_violence ~ black_d + goal_d + commit_d, data = us2)
m_us2_p <- lm(police_action_required ~ black_d + goal_d + commit_d, data = us2)
cat(sprintf("SAMPLE:study2_us:estimation=%d\n", nobs(m_us2_v)))
cat(sprintf("SAMPLE:study2_us_police:loaded=%d\n", nrow(us2)))
cat(sprintf("SAMPLE:study2_us_police:drop_missing_outcome=%d\n", sum(!is.na(us2$police_action_required))))
cat(sprintf("SAMPLE:study2_us_police:estimation=%d\n", nobs(m_us2_p)))
b <- get_coef(m_us2_v, "^black_d$")
add("study2_us_black_perceived_violence", b[1]); add("study2_us_black_perceived_violence_se", b[2])
b <- get_coef(m_us2_p, "^black_d$")
add("study2_us_black_police_action", b[1]); add("study2_us_black_police_action_se", b[2])
add("study2_us_minority_goal_perceived_violence", get_coef(m_us2_v, "^goal_d$")[1])
add("study2_us_commitment_perceived_violence", get_coef(m_us2_v, "^commit_d$")[1])
add("respondents_study2_us", nobs(m_us2_v))

# ---------------- Study 2 Israel ----------------
is2 <- isr_survey_wave2
cat("NOTE: isr2 identity levels:", paste(lev_str(is2$identity_protesters), collapse = " | "), "\n")
cat(sprintf("SAMPLE:study2_israel:loaded=%d\n", nrow(is2)))
is2$identity_f <- make_factor(is2$identity_protesters, "white|majority|ashkenaz|jew", "ethiop|arab")
is2$goal_d <- to_dummy(is2$group_goal, "group|minority|racis|discrim|police|brutal|yes")
is2$commit_d <- to_dummy(is2$commitment, "commit|yes|nonviol")
m_is2_v <- lm(degree_violence ~ identity_f + goal_d + commit_d, data = is2)
cat("NOTE: isr2 model terms:", paste(names(coef(m_is2_v)), collapse = " | "), "\n")
cat(sprintf("SAMPLE:study2_israel:estimation=%d\n", nobs(m_is2_v)))
add("study2_israel_ethiopian_perceived_violence", get_coef2(m_is2_v, "identity_f.*ethiop", "^identity_f1$")[1])
add("study2_israel_arab_perceived_violence", get_coef2(m_is2_v, "identity_f.*arab", "^identity_f2$")[1])
add("respondents_study2_israel", nobs(m_is2_v))

for (nm in names(emit)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, as.numeric(emit[[nm]])))
}
