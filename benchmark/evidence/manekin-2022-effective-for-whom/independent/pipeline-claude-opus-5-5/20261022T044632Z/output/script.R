# Reproduction of Manekin (2022), "Effective for Whom?", Tables 1 and 2.
# OLS of each outcome on the treatment dummies, with no controls and no fixed effects.
# Study 1 is weighted by the survey weight. Study 2 uses a weight column only if
# the data file has one.
suppressPackageStartupMessages({
  library(haven)
})
set.seed(42)

base_path <- "<repo>/.cache/datasets/manekin_2022_effective_for_whom.script-free/Replication/Data"
load(file.path(base_path, "us_survey_wave1.rdata"))
load(file.path(base_path, "isr_survey_wave1.rdata"))
load(file.path(base_path, "us_survey_wave2.rdata"))
load(file.path(base_path, "isr_survey_wave2.rdata"))

# Convert any coding (labelled, logical, character, numeric) to a factor
to_fac <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::as_factor(x)
  if (is.logical(x)) x <- as.integer(x)
  factor(x)
}

# Put the level matching `pat` first, so it becomes the regression base
relev <- function(f, pat) {
  lv <- levels(f)
  m <- grep(pat, lv, ignore.case = TRUE, perl = TRUE)
  if (length(m) > 0) f <- relevel(f, ref = lv[m[1]])
  f
}

# Dummy treatment variable: use 0/1 numerics directly; otherwise build a factor
make_dummy <- function(x, base_pat) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  if (is.logical(x)) x <- as.integer(x)
  if (is.numeric(x) && all(na.omit(unique(x)) %in% c(0, 1))) return(as.numeric(x))
  relev(to_fac(x), base_pat)
}

# Find the coefficient whose level label matches `pat`.
# If no label matches, fall back to the `fallback_idx`-th coefficient for that variable.
get_coef <- function(mod, prefix, pat, fallback_idx = 1) {
  cf <- coef(mod)
  nm <- names(cf)
  cand <- nm[startsWith(nm, prefix)]
  if (length(cand) == 0) return(NA)
  lvl <- substring(cand, nchar(prefix) + 1)
  m <- grep(pat, lvl, ignore.case = TRUE, perl = TRUE)
  if (length(m) > 0) return(unname(cf[cand[m[1]]]))
  if (length(cand) >= fallback_idx) return(unname(cf[cand[fallback_idx]]))
  NA
}

# Return a usable weight vector, or NULL if no weight column is available
get_w <- function(d) {
  if ("weight" %in% names(d)) {
    w <- as.numeric(d$weight)
    if (all(is.na(w))) return(NULL)
    return(w)
  }
  NULL
}

# Weighted OLS when weights are available, plain OLS otherwise
fit <- function(formula, d) {
  w <- get_w(d)
  if (is.null(w)) {
    lm(formula, data = d)
  } else {
    d$.w <- w
    lm(formula, data = d, weights = .w)
  }
}

# Clean outcomes: drop haven labels and coerce to numeric
clean_y <- function(d) {
  for (v in c("degree_violence", "police_action_required", "recall_violence2")) {
    if (v %in% names(d)) d[[v]] <- as.numeric(haven::zap_labels(d[[v]]))
  }
  d
}

# ---------------- Study 1 US ----------------
# Base: white protesters marching in the streets
d <- clean_y(us_survey_wave1)
d$ident <- make_dummy(d$identity_protesters, "white|charlie|majority|^0$")
d$tact <- relev(to_fac(d$tactic), "march|street")
m1 <- fit(degree_violence ~ ident + tact, d)
m2 <- fit(police_action_required ~ ident + tact, d)
if (is.numeric(d$ident)) {
  s1_us_v <- unname(coef(m1)["ident"])
  s1_us_p <- unname(coef(m2)["ident"])
} else {
  s1_us_v <- get_coef(m1, "ident", "black|tyrone|minority|^1$")
  s1_us_p <- get_coef(m2, "ident", "black|tyrone|minority|^1$")
}
n_s1_us <- nobs(m1)

# ---------------- Study 1 Israel ----------------
# Base: white Jewish protesters marching in the streets
d <- clean_y(isr_survey_wave1)
d$ident <- relev(to_fac(d$identity_protesters), "white|ashk|majority")
d$tact <- relev(to_fac(d$tactic), "march|street")
m3 <- fit(degree_violence ~ ident + tact, d)
m4 <- fit(police_action_required ~ ident + tact, d)
s1_is_eth_v <- get_coef(m3, "ident", "eth", 1)
s1_is_eth_p <- get_coef(m4, "ident", "eth", 1)
s1_is_arab_v <- get_coef(m3, "ident", "arab", 2)
s1_is_arab_p <- get_coef(m4, "ident", "arab", 2)
n_s1_is <- nobs(m3)

# ---------------- Study 2 US ----------------
# Base: white protesters, generic goal, no commitment to nonviolence
d <- clean_y(us_survey_wave2)
d$blk <- make_dummy(d$black, "white|^0$|no")
d$cmt <- make_dummy(d$commitment, "^0$|no")
d$gg <- make_dummy(d$group_goal, "^0$|no|general|layoff")
m5 <- fit(degree_violence ~ blk + gg + cmt, d)
m6 <- fit(police_action_required ~ blk + gg + cmt, d)
if (is.numeric(d$blk)) {
  s2_us_v <- unname(coef(m5)["blk"])
  s2_us_p <- unname(coef(m6)["blk"])
} else {
  s2_us_v <- get_coef(m5, "blk", "black|yes|^1$")
  s2_us_p <- get_coef(m6, "blk", "black|yes|^1$")
}
n_s2_us <- nobs(m5)

# ---------------- Study 2 Israel ----------------
d <- clean_y(isr_survey_wave2)
d$ident <- relev(to_fac(d$identity_protesters), "white|ashk|majority")
d$cmt <- make_dummy(d$commitment, "^0$|no")
d$gg <- make_dummy(d$group_goal, "^0$|no|general|layoff")
m7 <- fit(degree_violence ~ ident + gg + cmt, d)
n_s2_is <- nobs(m7)

# ---------------- Output ----------------
out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
out("study1_us_black_perceived_violence", s1_us_v)
out("study1_us_black_police_action", s1_us_p)
out("study1_israel_ethiopian_perceived_violence", s1_is_eth_v)
out("study1_israel_ethiopian_police_action", s1_is_eth_p)
out("study1_israel_arab_perceived_violence", s1_is_arab_v)
out("study1_israel_arab_police_action", s1_is_arab_p)
out("study2_us_black_perceived_violence", s2_us_v)
out("study2_us_black_police_action", s2_us_p)
out("respondents_study1_us", n_s1_us)
out("respondents_study1_israel", n_s1_is)
out("respondents_study2_us", n_s2_us)
out("respondents_study2_israel", n_s2_is)