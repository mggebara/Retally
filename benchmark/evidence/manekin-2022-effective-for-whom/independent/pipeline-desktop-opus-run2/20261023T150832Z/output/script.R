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
  tolower(trimws(as.character(x)))
}

to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  suppressWarnings(as.numeric(x))
}

# Indicator for a category matched by a regex on labels
pat_dummy <- function(x, pattern) {
  s <- to_chr(x)
  out <- as.integer(grepl(pattern, s))
  out[is.na(x)] <- NA
  out
}

# Binarize a two-valued treatment; neg = regex for the baseline value
binarize <- function(x, neg, pos = NULL) {
  if (is.logical(x)) return(as.integer(x))
  s <- to_chr(x)
  ux <- unique(s[!is.na(s)])
  if (length(ux) == 2) {
    nm <- grepl(neg, ux)
    if (sum(nm) == 1) return(ifelse(is.na(s), NA_integer_, as.integer(s != ux[nm])))
    if (!is.null(pos)) {
      pm <- grepl(pos, ux)
      if (sum(pm) == 1) return(ifelse(is.na(s), NA_integer_, as.integer(s == ux[pm])))
    }
    num <- suppressWarnings(as.numeric(ux))
    if (all(!is.na(num))) return(ifelse(is.na(s), NA_integer_, as.integer(s == ux[which.max(num)])))
    if (is.factor(x)) {
      lv <- tolower(levels(x))
      return(ifelse(is.na(s), NA_integer_, as.integer(s == lv[length(lv)])))
    }
    return(ifelse(is.na(s), NA_integer_, as.integer(s == sort(ux)[2])))
  }
  n <- to_num(x)
  as.integer(n == max(n, na.rm = TRUE))
}

get_w <- function(d) {
  if ("weight" %in% names(d)) {
    w <- to_num(d$weight)
    if (all(!is.na(w)) && all(w > 0)) return(w)
  }
  NULL
}

fit <- function(f, d, w) {
  if (is.null(w)) lm(f, data = d) else { d$.w <- w; lm(f, data = d, weights = .w) }
}

# ---------------- Study 1 US ----------------
us1 <- us_survey_wave1
id_s <- to_chr(us1$identity_protesters)
if (any(grepl("black", id_s))) {
  us1$black <- pat_dummy(us1$identity_protesters, "black")
} else {
  us1$black <- binarize(us1$identity_protesters, "white|^0$")
}
tac <- us1$tactic
us1$traffic <- pat_dummy(tac, "traffic|shut|block")
us1$destroy <- pat_dummy(tac, "destroy|police car|damag|car")
if (all(us1$traffic == 0, na.rm = TRUE) || all(us1$destroy == 0, na.rm = TRUE)) {
  tn <- to_num(tac); lv <- sort(unique(tn))
  us1$traffic <- as.integer(tn == lv[2]); us1$destroy <- as.integer(tn == lv[3])
}
for (v in c("degree_violence", "police_action_required")) us1[[v]] <- to_num(us1[[v]])
w_us1 <- get_w(us1)
m_us1_dv <- fit(degree_violence ~ black + traffic + destroy, us1, w_us1)
m_us1_pa <- fit(police_action_required ~ black + traffic + destroy, us1, w_us1)

# ---------------- Study 1 Israel ----------------
is1 <- isr_survey_wave1
is1$ethiopian <- pat_dummy(is1$identity_protesters, "ethiop")
is1$arab <- pat_dummy(is1$identity_protesters, "arab")
if (all(is1$ethiopian == 0, na.rm = TRUE) || all(is1$arab == 0, na.rm = TRUE)) {
  tn <- to_num(is1$identity_protesters); lv <- sort(unique(tn))
  is1$ethiopian <- as.integer(tn == lv[2]); is1$arab <- as.integer(tn == lv[3])
}
tac <- is1$tactic
is1$traffic <- pat_dummy(tac, "traffic|shut|block")
is1$destroy <- pat_dummy(tac, "destroy|garbage|trash|damag|can")
if (all(is1$traffic == 0, na.rm = TRUE) || all(is1$destroy == 0, na.rm = TRUE)) {
  tn <- to_num(tac); lv <- sort(unique(tn))
  is1$traffic <- as.integer(tn == lv[2]); is1$destroy <- as.integer(tn == lv[3])
}
for (v in c("degree_violence", "police_action_required")) is1[[v]] <- to_num(is1[[v]])
w_is1 <- get_w(is1)
m_is1_dv <- fit(degree_violence ~ ethiopian + arab + traffic + destroy, is1, w_is1)
m_is1_pa <- fit(police_action_required ~ ethiopian + arab + traffic + destroy, is1, w_is1)

# ---------------- Study 2 US ----------------
us2 <- us_survey_wave2
us2$black_d <- binarize(us2$black, "white|^0$|^no|false", "black|^1$|yes|true")
us2$goal_d <- binarize(us2$group_goal, "general|generic|layoff|econom|^no|^0$|false|control",
                       "minor|group|racial|prejud|brutal|discrim|yes|^1$|true")
us2$commit_d <- binarize(us2$commitment, "^no|none|without|absent|control|^0$|false",
                         "yes|commit|^1$|true")
for (v in c("degree_violence", "police_action_required")) us2[[v]] <- to_num(us2[[v]])
w_us2 <- get_w(us2)
m_us2_dv <- fit(degree_violence ~ black_d + goal_d + commit_d, us2, w_us2)
m_us2_pa <- fit(police_action_required ~ black_d + goal_d + commit_d, us2, w_us2)

# ---------------- Study 2 Israel (sample size) ----------------
is2 <- isr_survey_wave2

cat(sprintf("RESULT:study1_us_black_perceived_violence=%.6f\n", coef(m_us1_dv)["black"]))
cat(sprintf("RESULT:study1_us_black_police_action=%.6f\n", coef(m_us1_pa)["black"]))
cat(sprintf("RESULT:study1_israel_ethiopian_perceived_violence=%.6f\n", coef(m_is1_dv)["ethiopian"]))
cat(sprintf("RESULT:study1_israel_ethiopian_police_action=%.6f\n", coef(m_is1_pa)["ethiopian"]))
cat(sprintf("RESULT:study1_israel_arab_perceived_violence=%.6f\n", coef(m_is1_dv)["arab"]))
cat(sprintf("RESULT:study1_israel_arab_police_action=%.6f\n", coef(m_is1_pa)["arab"]))
cat(sprintf("RESULT:study2_us_black_perceived_violence=%.6f\n", coef(m_us2_dv)["black_d"]))
cat(sprintf("RESULT:study2_us_black_police_action=%.6f\n", coef(m_us2_pa)["black_d"]))
cat(sprintf("RESULT:respondents_study1_us=%d\n", nrow(us1)))
cat(sprintf("RESULT:respondents_study1_israel=%d\n", nrow(is1)))
cat(sprintf("RESULT:respondents_study2_us=%d\n", nrow(us2)))
cat(sprintf("RESULT:respondents_study2_israel=%d\n", nrow(is2)))