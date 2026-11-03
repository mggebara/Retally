suppressPackageStartupMessages({
  library(haven)
})
set.seed(42)

base <- "<repo>/.cache/datasets/manekin_2022_effective_for_whom.script-free/Replication/Data"
load(file.path(base, "us_survey_wave1.rdata"))
load(file.path(base, "isr_survey_wave1.rdata"))
load(file.path(base, "us_survey_wave2.rdata"))
load(file.path(base, "isr_survey_wave2.rdata"))

to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::as_factor(x)
  if (is.factor(x)) return(tolower(as.character(x)))
  if (is.logical(x)) return(as.character(as.integer(x)))
  tolower(as.character(x))
}

num01 <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  if (is.factor(x)) {
    s <- tolower(as.character(x))
    lv <- tolower(levels(x))
    if (all(s[!is.na(s)] %in% c("0", "1"))) return(as.numeric(s))
    yes <- grepl("^yes|^1$|true|commit|minority|group|black|racis", s)
    out <- as.numeric(yes)
    out[is.na(s)] <- NA
    if (length(unique(na.omit(out))) < 2) out <- as.numeric(as.integer(x) == 2)
    return(out)
  }
  if (is.logical(x)) return(as.numeric(x))
  if (is.character(x)) {
    s <- tolower(x)
    if (all(s[!is.na(s)] %in% c("0", "1"))) return(as.numeric(s))
    out <- as.numeric(grepl("^yes|true|commit|minority|group|black|racis", s))
    out[is.na(s)] <- NA
    return(out)
  }
  x <- as.numeric(x)
  u <- sort(unique(na.omit(x)))
  if (length(u) == 2 && !all(u == c(0, 1))) x <- as.numeric(x == u[2])
  x
}

# identity dummies: returns list of dummy vectors given patterns; numeric fallback by sorted order
identity_dummies <- function(x, pats) {
  raw <- x
  s <- to_chr(x)
  res <- lapply(pats, function(p) {
    d <- as.numeric(grepl(p, s))
    d[is.na(s)] <- NA
    d
  })
  ok <- all(sapply(res, function(d) sum(d, na.rm = TRUE) > 0))
  if (!ok) {
    v <- raw
    if (inherits(v, "haven_labelled")) v <- haven::zap_labels(v)
    if (is.factor(v)) v <- as.integer(v)
    v <- suppressWarnings(as.numeric(as.character(v)))
    u <- sort(unique(na.omit(v)))
    res <- lapply(seq_along(pats), function(i) as.numeric(v == u[i + 1]))
  }
  names(res) <- names(pats)
  res
}

tactic_dummies <- function(x) {
  s <- to_chr(x)
  f <- factor(s)
  lv <- levels(f)
  b <- grep("march|street", lv)
  if (length(b) == 0) {
    v <- suppressWarnings(as.numeric(lv))
    b <- if (all(!is.na(v))) which.min(v) else 1
  }
  f <- relevel(f, ref = lv[b[1]])
  others <- setdiff(levels(f), lv[b[1]])
  out <- lapply(others, function(l) { d <- as.numeric(s == l); d[is.na(s)] <- NA; d })
  names(out) <- paste0("tac", seq_along(others))
  out
}

get_w <- function(d) {
  if ("weight" %in% names(d)) {
    w <- as.numeric(d$weight)
    w[is.na(w)] <- NA
    return(w)
  }
  rep(1, nrow(d))
}

fit <- function(y, X, w) {
  df <- data.frame(y = as.numeric(y), X, w = w)
  df <- df[complete.cases(df), ]
  rhs <- paste(names(X), collapse = " + ")
  m <- lm(as.formula(paste("y ~", rhs)), data = df, weights = w)
  m
}

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))

# ---------- Study 1 US ----------
d <- us_survey_wave1
idu <- identity_dummies(d$identity_protesters, c(black = "black|tyrone|african"))
tu <- tactic_dummies(d$tactic)
X <- data.frame(black = idu$black, tu)
w <- get_w(d)
m1 <- fit(d$degree_violence, X, w)
m2 <- fit(d$police_action_required, X, w)
out("study1_us_black_perceived_violence", coef(m1)["black"])
out("study1_us_black_police_action", coef(m2)["black"])
out("study1_us_black_perceived_violence_se", sqrt(diag(vcov(m1)))["black"])
out("study1_us_black_police_action_se", sqrt(diag(vcov(m2)))["black"])

# ---------- Study 1 Israel ----------
d <- isr_survey_wave1
idi <- identity_dummies(d$identity_protesters, c(eth = "ethiop", arab = "arab"))
ti <- tactic_dummies(d$tactic)
X <- data.frame(eth = idi$eth, arab = idi$arab, ti)
w <- get_w(d)
m3 <- fit(d$degree_violence, X, w)
m4 <- fit(d$police_action_required, X, w)
out("study1_israel_ethiopian_perceived_violence", coef(m3)["eth"])
out("study1_israel_ethiopian_police_action", coef(m4)["eth"])
out("study1_israel_arab_perceived_violence", coef(m3)["arab"])
out("study1_israel_arab_police_action", coef(m4)["arab"])

# ---------- Study 2 US ----------
d <- us_survey_wave2
X <- data.frame(black = num01(d$black), goal = num01(d$group_goal), commit = num01(d$commitment))
w <- get_w(d)
m5 <- fit(d$degree_violence, X, w)
m6 <- fit(d$police_action_required, X, w)
out("study2_us_black_perceived_violence", coef(m5)["black"])
out("study2_us_black_police_action", coef(m6)["black"])

# ---------- Study 2 Israel (for N) ----------
d2 <- isr_survey_wave2
id2 <- identity_dummies(d2$identity_protesters, c(eth = "ethiop", arab = "arab"))
X2 <- data.frame(eth = id2$eth, arab = id2$arab, goal = num01(d2$group_goal), commit = num01(d2$commitment))
m7 <- fit(d2$degree_violence, X2, get_w(d2))

out("respondents_study1_us", nobs(m1))
out("respondents_study1_israel", nobs(m3))
out("respondents_study2_us", nobs(m5))
out("respondents_study2_israel", nobs(m7))
