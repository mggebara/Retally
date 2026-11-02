# Reproduction script for Manekin (2022) "Effective for Whom?": Tables 1-2 headline
# coefficients and sample sizes, estimated by OLS with Study 1 / US Study 2 survey weights.
suppressMessages({
  library(stats)
})
set.seed(42)

base <- "<repo>/.cache/datasets/manekin_2022_effective_for_whom.script-free/Replication/Data"
load(file.path(base, "us_survey_wave1.rdata"))
load(file.path(base, "isr_survey_wave1.rdata"))
load(file.path(base, "us_survey_wave2.rdata"))
load(file.path(base, "isr_survey_wave2.rdata"))

# Convert Stata/SPSS-labelled columns to factors; leave other types unchanged.
to_fac <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::as_factor(x)
  if (is.character(x) || is.logical(x)) x <- factor(x)
  if (!is.factor(x)) x <- factor(x)
  droplevels(x)
}

# Set the regression base category: first level whose name matches the pattern,
# otherwise keep the first (lowest) level.
relevel_pat <- function(f, pat, exclude = NULL) {
  lv <- levels(f)
  cand <- lv[grepl(pat, lv, ignore.case = TRUE)]
  if (!is.null(exclude)) cand <- cand[!grepl(exclude, cand, ignore.case = TRUE)]
  if (length(cand) > 0) f <- relevel(f, ref = cand[1])
  f
}

# Return the coefficient whose name matches the pattern; fall back to a positional index.
get_coef <- function(m, pat, fallback_idx = NULL) {
  cf <- coef(m)
  nm <- names(cf)
  hit <- nm[grepl(pat, nm, ignore.case = TRUE)]
  if (length(hit) > 0) return(unname(cf[hit[1]]))
  if (!is.null(fallback_idx)) return(unname(cf[fallback_idx]))
  NA_real_
}

# Treat a variable as a 0/1 indicator if it has only 0/1 values; otherwise
# convert it to a factor with its first level as the base.
as_dummy_or_fac <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::as_factor(x)
  if (is.numeric(x) && all(na.omit(unique(x)) %in% c(0, 1))) return(x)
  if (is.logical(x)) return(as.numeric(x))
  to_fac(x)
}

# Weighted OLS when the weight vector is present; plain OLS otherwise.
fit <- function(fml, d, w = NULL) {
  if (!is.null(w)) {
    d$.w <- w
    lm(fml, data = d, weights = .w)
  } else lm(fml, data = d)
}

################ Study 1 US: identity + tactic, base white protesters marching ################
us1 <- us_survey_wave1
us1$identity_protesters <- relevel_pat(to_fac(us1$identity_protesters), "white|charlie")
us1$tactic <- relevel_pat(to_fac(us1$tactic), "march|street")
message("US1 identity levels: ", paste(levels(us1$identity_protesters), collapse = " | "))
message("US1 tactic levels: ", paste(levels(us1$tactic), collapse = " | "))
w_us1 <- if ("weight" %in% names(us1)) us1$weight else NULL

m_us1_v <- fit(degree_violence ~ identity_protesters + tactic, us1, w_us1)
m_us1_p <- fit(police_action_required ~ identity_protesters + tactic, us1, w_us1)
b_us1_v <- get_coef(m_us1_v, "identity_protesters.*(black|tyrone)", 2)
b_us1_p <- get_coef(m_us1_p, "identity_protesters.*(black|tyrone)", 2)
n_us1 <- nobs(m_us1_v)

################ Study 1 Israel: identity (Ethiopian, Arab) + tactic ################
is1 <- isr_survey_wave1
is1$identity_protesters <- relevel_pat(to_fac(is1$identity_protesters),
                                       "white|jew|majority|ashk", exclude = "ethio|arab")
is1$tactic <- relevel_pat(to_fac(is1$tactic), "march|street")
message("ISR1 identity levels: ", paste(levels(is1$identity_protesters), collapse = " | "))
message("ISR1 tactic levels: ", paste(levels(is1$tactic), collapse = " | "))
w_is1 <- if ("weight" %in% names(is1)) is1$weight else NULL

m_is1_v <- fit(degree_violence ~ identity_protesters + tactic, is1, w_is1)
m_is1_p <- fit(police_action_required ~ identity_protesters + tactic, is1, w_is1)
b_is1_eth_v <- get_coef(m_is1_v, "identity_protesters.*ethio", 2)
b_is1_eth_p <- get_coef(m_is1_p, "identity_protesters.*ethio", 2)
b_is1_arab_v <- get_coef(m_is1_v, "identity_protesters.*arab", 3)
b_is1_arab_p <- get_coef(m_is1_p, "identity_protesters.*arab", 3)
n_is1 <- nobs(m_is1_v)

################ Study 2 US: black + group goal + commitment ################
us2 <- us_survey_wave2
us2$black <- as_dummy_or_fac(us2$black)
if (is.factor(us2$black)) us2$black <- relevel_pat(us2$black, "white|^0$|no")
us2$group_goal <- as_dummy_or_fac(us2$group_goal)
us2$commitment <- as_dummy_or_fac(us2$commitment)
message("US2 columns: ", paste(names(us2), collapse = ", "))
w_us2 <- if ("weight" %in% names(us2)) us2$weight else NULL

m_us2_v <- fit(degree_violence ~ black + group_goal + commitment, us2, w_us2)
m_us2_p <- fit(police_action_required ~ black + group_goal + commitment, us2, w_us2)
b_us2_v <- get_coef(m_us2_v, "^black", 2)
b_us2_p <- get_coef(m_us2_p, "^black", 2)
n_us2 <- nobs(m_us2_v)

################ Study 2 Israel: identity + group goal + commitment ################
is2 <- isr_survey_wave2
is2$identity_protesters <- relevel_pat(to_fac(is2$identity_protesters),
                                       "white|jew|majority|ashk", exclude = "ethio|arab")
is2$group_goal <- as_dummy_or_fac(is2$group_goal)
is2$commitment <- as_dummy_or_fac(is2$commitment)
message("ISR2 identity levels: ", paste(levels(is2$identity_protesters), collapse = " | "))
w_is2 <- if ("weight" %in% names(is2)) is2$weight else NULL

m_is2_v <- fit(degree_violence ~ identity_protesters + group_goal + commitment, is2, w_is2)
n_is2 <- nobs(m_is2_v)

cat(sprintf("RESULT:study1_us_black_perceived_violence=%.6f\n", b_us1_v))
cat(sprintf("RESULT:study1_us_black_police_action=%.6f\n", b_us1_p))
cat(sprintf("RESULT:study1_israel_ethiopian_perceived_violence=%.6f\n", b_is1_eth_v))
cat(sprintf("RESULT:study1_israel_ethiopian_police_action=%.6f\n", b_is1_eth_p))
cat(sprintf("RESULT:study1_israel_arab_perceived_violence=%.6f\n", b_is1_arab_v))
cat(sprintf("RESULT:study1_israel_arab_police_action=%.6f\n", b_is1_arab_p))
cat(sprintf("RESULT:study2_us_black_perceived_violence=%.6f\n", b_us2_v))
cat(sprintf("RESULT:study2_us_black_police_action=%.6f\n", b_us2_p))
cat(sprintf("RESULT:respondents_study1_us=%d\n", as.integer(n_us1)))
cat(sprintf("RESULT:respondents_study1_israel=%d\n", as.integer(n_is1)))
cat(sprintf("RESULT:respondents_study2_us=%d\n", as.integer(n_us2)))
cat(sprintf("RESULT:respondents_study2_israel=%d\n", as.integer(n_is2)))