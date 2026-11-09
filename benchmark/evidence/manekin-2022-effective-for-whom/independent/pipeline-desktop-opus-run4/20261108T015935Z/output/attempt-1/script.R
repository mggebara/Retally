suppressPackageStartupMessages({
  library(stats)
})
set.seed(42)

base <- "<repo>/.cache/datasets/manekin_2022_effective_for_whom.script-free/Replication/Data"
load(file.path(base, "us_survey_wave1.rdata"))
load(file.path(base, "isr_survey_wave1.rdata"))
load(file.path(base, "us_survey_wave2.rdata"))
load(file.path(base, "isr_survey_wave2.rdata"))

us1 <- as.data.frame(us_survey_wave1)
is1 <- as.data.frame(isr_survey_wave1)
us2 <- as.data.frame(us_survey_wave2)
is2 <- as.data.frame(isr_survey_wave2)

strip <- function(x) {
  if (inherits(x, "haven_labelled")) {
    labs <- attr(x, "labels")
    if (!is.null(labs)) {
      out <- names(labs)[match(as.numeric(x), as.numeric(labs))]
      return(out)
    }
    return(as.numeric(x))
  }
  x
}

num <- function(x) {
  x <- strip(x)
  if (is.factor(x) || is.character(x)) {
    v <- suppressWarnings(as.numeric(as.character(x)))
    if (sum(!is.na(v)) >= 0.5 * sum(!is.na(x))) return(v)
    return(as.numeric(as.factor(x)) - 1)
  }
  as.numeric(x)
}

describe <- function(nm, x) {
  x <- strip(x)
  cat("# ", nm, " class=", paste(class(x), collapse = ","), "\n", sep = "")
  print(table(x, useNA = "ifany"))
}

# match a category variable to a regex; for numeric codes use fallback code values
cat_dummy <- function(x, pattern, numeric_code = NULL) {
  x <- strip(x)
  if (is.factor(x) || is.character(x)) {
    s <- tolower(as.character(x))
    d <- as.numeric(grepl(pattern, s))
    d[is.na(s)] <- NA
    return(d)
  }
  v <- as.numeric(x)
  d <- as.numeric(v %in% numeric_code)
  d[is.na(v)] <- NA
  d
}

# binary treatment indicator (yes/1 = treated)
bin_dummy <- function(x, pattern) {
  x <- strip(x)
  if (is.logical(x)) return(as.numeric(x))
  if (is.factor(x) || is.character(x)) {
    s <- tolower(as.character(x))
    v <- suppressWarnings(as.numeric(s))
    if (all(is.na(v) == is.na(s))) {
      return(as.numeric(v == max(v, na.rm = TRUE)))
    }
    d <- as.numeric(grepl(pattern, s) & !grepl("^no|^not|non-?commit|no commit|generic|general|layoff", s))
    if (length(unique(d[!is.na(s)])) < 2) {
      lv <- if (is.factor(x)) levels(droplevels(x)) else sort(unique(s))
      d <- as.numeric(as.character(x) == lv[length(lv)])
    }
    d[is.na(s)] <- NA
    return(d)
  }
  v <- as.numeric(x)
  as.numeric(v == max(v, na.rm = TRUE))
}

get_w <- function(df) {
  if ("weight" %in% names(df)) {
    w <- as.numeric(strip(df$weight))
    if (sum(!is.na(w)) > 0) {
      w[is.na(w)] <- NA
      return(w)
    }
  }
  rep(1, nrow(df))
}

fit <- function(df, dv, rhs, w) {
  d <- df
  d$.y <- num(df[[dv]])
  d$.w <- w
  f <- as.formula(paste(".y ~", paste(rhs, collapse = " + ")))
  m <- lm(f, data = d, weights = .w)
  cat("## ", dv, " N=", nobs(m), "\n", sep = "")
  print(round(summary(m)$coefficients, 4))
  m
}

# ---------------- Study 1 US ----------------
describe("us1 identity", us1$identity_protesters)
describe("us1 tactic", us1$tactic)
us1$black <- cat_dummy(us1$identity_protesters, "black|african|tyrone", numeric_code = 1)
us1$traffic <- cat_dummy(us1$tactic, "traffic|shut|block", numeric_code = 2)
us1$destroy <- cat_dummy(us1$tactic, "destroy|police car|damage|violent", numeric_code = 3)
if (is.numeric(strip(us1$tactic)) && min(as.numeric(strip(us1$tactic)), na.rm = TRUE) == 0) {
  v <- as.numeric(strip(us1$tactic)); us1$traffic <- as.numeric(v == 1); us1$destroy <- as.numeric(v == 2)
}
w_us1 <- get_w(us1)
rhs1us <- c("black", "traffic", "destroy")
m_us1_v <- fit(us1, "degree_violence", rhs1us, w_us1)
m_us1_p <- fit(us1, "police_action_required", rhs1us, w_us1)

# ---------------- Study 1 Israel ----------------
describe("is1 identity", is1$identity_protesters)
describe("is1 tactic", is1$tactic)
is1$ethiopian <- cat_dummy(is1$identity_protesters, "ethiop", numeric_code = 2)
is1$arab <- cat_dummy(is1$identity_protesters, "arab", numeric_code = 3)
is1$traffic <- cat_dummy(is1$tactic, "traffic|shut|block", numeric_code = 2)
is1$destroy <- cat_dummy(is1$tactic, "destroy|garbage|damage|violent", numeric_code = 3)
if (is.numeric(strip(is1$identity_protesters)) && min(as.numeric(strip(is1$identity_protesters)), na.rm = TRUE) == 0) {
  v <- as.numeric(strip(is1$identity_protesters)); is1$ethiopian <- as.numeric(v == 1); is1$arab <- as.numeric(v == 2)
}
if (is.numeric(strip(is1$tactic)) && min(as.numeric(strip(is1$tactic)), na.rm = TRUE) == 0) {
  v <- as.numeric(strip(is1$tactic)); is1$traffic <- as.numeric(v == 1); is1$destroy <- as.numeric(v == 2)
}
w_is1 <- get_w(is1)
rhs1is <- c("ethiopian", "arab", "traffic", "destroy")
m_is1_v <- fit(is1, "degree_violence", rhs1is, w_is1)
m_is1_p <- fit(is1, "police_action_required", rhs1is, w_is1)

# ---------------- Study 2 US ----------------
if ("black" %in% names(us2)) {
  describe("us2 black", us2$black)
  us2$black_d <- bin_dummy(us2$black, "black|1|yes")
} else {
  us2$black_d <- cat_dummy(us2$identity_protesters_fac, "black", numeric_code = 1)
}
describe("us2 commitment", us2$commitment)
describe("us2 group_goal", us2$group_goal)
us2$commit_d <- bin_dummy(us2$commitment, "commit|yes|nonviol")
us2$goal_d <- bin_dummy(us2$group_goal, "minority|group|racial|police|prejudice|yes")
w_us2 <- get_w(us2)
rhs2us <- c("black_d", "goal_d", "commit_d")
m_us2_v <- fit(us2, "degree_violence", rhs2us, w_us2)
m_us2_p <- fit(us2, "police_action_required", rhs2us, w_us2)

# ---------------- Study 2 Israel (counts only) ----------------
n_is2 <- nrow(is2)

g <- function(m, v) unname(coef(m)[v])

cat(sprintf("RESULT:study1_us_black_perceived_violence=%.6f\n", g(m_us1_v, "black")))
cat(sprintf("RESULT:study1_us_black_police_action=%.6f\n", g(m_us1_p, "black")))
cat(sprintf("RESULT:study1_israel_ethiopian_perceived_violence=%.6f\n", g(m_is1_v, "ethiopian")))
cat(sprintf("RESULT:study1_israel_ethiopian_police_action=%.6f\n", g(m_is1_p, "ethiopian")))
cat(sprintf("RESULT:study1_israel_arab_perceived_violence=%.6f\n", g(m_is1_v, "arab")))
cat(sprintf("RESULT:study1_israel_arab_police_action=%.6f\n", g(m_is1_p, "arab")))
cat(sprintf("RESULT:study2_us_black_perceived_violence=%.6f\n", g(m_us2_v, "black_d")))
cat(sprintf("RESULT:study2_us_black_police_action=%.6f\n", g(m_us2_p, "black_d")))
cat(sprintf("RESULT:respondents_study1_us=%d\n", nrow(us1)))
cat(sprintf("RESULT:respondents_study1_israel=%d\n", nrow(is1)))
cat(sprintf("RESULT:respondents_study2_us=%d\n", nrow(us2)))
cat(sprintf("RESULT:respondents_study2_israel=%d\n", n_is2))