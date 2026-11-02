suppressPackageStartupMessages({
  library(stats)
})
set.seed(42)

base <- "<repo>/.cache/datasets/manekin_2022_effective_for_whom.script-free/Replication/Data"
load(file.path(base, "us_survey_wave1.rdata"))
load(file.path(base, "isr_survey_wave1.rdata"))
load(file.path(base, "us_survey_wave2.rdata"))
load(file.path(base, "isr_survey_wave2.rdata"))

to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) {
    lab <- attr(x, "labels")
    if (!is.null(lab)) {
      out <- names(lab)[match(as.numeric(x), as.numeric(lab))]
      return(tolower(trimws(out)))
    }
  }
  tolower(trimws(as.character(x)))
}

num <- function(x) {
  if (is.factor(x)) {
    v <- suppressWarnings(as.numeric(as.character(x)))
    if (all(is.na(v[!is.na(x)]))) v <- as.numeric(x)
    return(v)
  }
  as.numeric(unclass(x))
}

# dummy for a level matching a pattern; numeric fallback
make_dummy <- function(x, pattern, numeric_code = NULL) {
  ch <- to_chr(x)
  hit <- grepl(pattern, ch)
  if (any(hit, na.rm = TRUE)) {
    d <- as.numeric(hit)
    d[is.na(ch)] <- NA
    return(d)
  }
  v <- suppressWarnings(as.numeric(ch))
  if (!is.null(numeric_code)) return(as.numeric(v == numeric_code))
  u <- sort(unique(v[!is.na(v)]))
  as.numeric(v == max(u))
}

# binary indicator variable (already a treatment indicator)
binary <- function(x, pattern = NULL) {
  ch <- to_chr(x)
  v <- suppressWarnings(as.numeric(ch))
  if (sum(!is.na(v)) > 0 && sum(!is.na(v)) >= sum(!is.na(ch))) {
    u <- sort(unique(v[!is.na(v)]))
    if (length(u) == 2 && !all(u == c(0, 1))) return(as.numeric(v == max(u)))
    return(v)
  }
  if (ch[1] %in% c("true", "false") || all(ch[!is.na(ch)] %in% c("true", "false"))) {
    return(as.numeric(ch == "true"))
  }
  if (!is.null(pattern)) {
    neg <- grepl("^no|^non|none|without|general|generic|layoff", ch)
    pos <- grepl(pattern, ch) & !neg
    d <- as.numeric(pos)
    d[is.na(ch)] <- NA
    return(d)
  }
  f <- factor(ch)
  as.numeric(f == levels(f)[length(levels(f))])
}

tactic_factor <- function(x) {
  ch <- to_chr(x)
  f <- factor(ch)
  lv <- levels(f)
  m <- grep("march|street", lv)
  if (length(m) >= 1) f <- relevel(f, ref = lv[m[1]])
  f
}

get_w <- function(d) {
  if ("weight" %in% names(d)) {
    w <- as.numeric(d$weight)
    w[is.na(w)] <- 1
    w
  } else rep(1, nrow(d))
}

# ---------------- Study 1 US ----------------
us1 <- us_survey_wave1
us1$black_d <- make_dummy(us1$identity_protesters, "black|afr")
us1$tactic_f <- tactic_factor(us1$tactic)
us1$w <- get_w(us1)
us1$dv <- num(us1$degree_violence)
us1$pa <- num(us1$police_action_required)

m1a <- lm(dv ~ black_d + tactic_f, data = us1, weights = w)
m1b <- lm(pa ~ black_d + tactic_f, data = us1, weights = w)

# ---------------- Study 1 Israel ----------------
is1 <- isr_survey_wave1
is1$eth_d <- make_dummy(is1$identity_protesters, "eth", numeric_code = 2)
is1$arab_d <- make_dummy(is1$identity_protesters, "arab", numeric_code = 3)
is1$tactic_f <- tactic_factor(is1$tactic)
is1$w <- get_w(is1)
is1$dv <- num(is1$degree_violence)
is1$pa <- num(is1$police_action_required)

m2a <- lm(dv ~ eth_d + arab_d + tactic_f, data = is1, weights = w)
m2b <- lm(pa ~ eth_d + arab_d + tactic_f, data = is1, weights = w)

# ---------------- Study 2 US ----------------
us2 <- us_survey_wave2
us2$black_d <- binary(us2$black, "black")
us2$goal_d <- binary(us2$group_goal, "group|race|prejud|minor|police")
us2$comm_d <- binary(us2$commitment, "commit|nonviol")
us2$dv <- num(us2$degree_violence)
us2$pa <- num(us2$police_action_required)
us2$w <- get_w(us2)

m3a <- lm(dv ~ black_d + goal_d + comm_d, data = us2, weights = w)
m3b <- lm(pa ~ black_d + goal_d + comm_d, data = us2, weights = w)

# ---------------- Study 2 Israel ----------------
is2 <- isr_survey_wave2
is2$eth_d <- make_dummy(is2$identity_protesters, "eth", numeric_code = 2)
is2$arab_d <- make_dummy(is2$identity_protesters, "arab", numeric_code = 3)
is2$goal_d <- binary(is2$group_goal, "group|race|prejud|minor|discrim|police")
is2$comm_d <- binary(is2$commitment, "commit|nonviol")
is2$dv <- num(is2$degree_violence)
is2$w <- get_w(is2)
m4a <- tryCatch(lm(dv ~ eth_d + arab_d + goal_d + comm_d, data = is2, weights = w),
                error = function(e) NULL)
n_is2 <- if (!is.null(m4a)) nobs(m4a) else nrow(is2)

cf <- function(m, v) unname(coef(m)[v])

cat(sprintf("RESULT:study1_us_black_perceived_violence=%.6f\n", cf(m1a, "black_d")))
cat(sprintf("RESULT:study1_us_black_police_action=%.6f\n", cf(m1b, "black_d")))
cat(sprintf("RESULT:study1_israel_ethiopian_perceived_violence=%.6f\n", cf(m2a, "eth_d")))
cat(sprintf("RESULT:study1_israel_ethiopian_police_action=%.6f\n", cf(m2b, "eth_d")))
cat(sprintf("RESULT:study1_israel_arab_perceived_violence=%.6f\n", cf(m2a, "arab_d")))
cat(sprintf("RESULT:study1_israel_arab_police_action=%.6f\n", cf(m2b, "arab_d")))
cat(sprintf("RESULT:study2_us_black_perceived_violence=%.6f\n", cf(m3a, "black_d")))
cat(sprintf("RESULT:study2_us_black_police_action=%.6f\n", cf(m3b, "black_d")))
cat(sprintf("RESULT:respondents_study1_us=%d\n", as.integer(nobs(m1a))))
cat(sprintf("RESULT:respondents_study1_israel=%d\n", as.integer(nobs(m2a))))
cat(sprintf("RESULT:respondents_study2_us=%d\n", as.integer(nobs(m3a))))
cat(sprintf("RESULT:respondents_study2_israel=%d\n", as.integer(n_is2)))