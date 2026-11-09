suppressPackageStartupMessages({
  library(haven)
})
set.seed(42)

base <- "<repo>/.cache/datasets/manekin_2022_effective_for_whom.script-free/Replication/Data"
load(file.path(base, "us_survey_wave1.rdata"))
load(file.path(base, "us_survey_wave2.rdata"))
load(file.path(base, "isr_survey_wave1.rdata"))
load(file.path(base, "isr_survey_wave2.rdata"))

lab <- function(x) {
  if (inherits(x, "haven_labelled")) return(as.character(haven::as_factor(x)))
  if (is.factor(x)) return(as.character(x))
  as.character(x)
}
num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  if (is.factor(x)) {
    v <- suppressWarnings(as.numeric(as.character(x)))
    if (all(is.na(v[!is.na(x)]))) return(NULL)
    return(v)
  }
  if (is.character(x)) {
    v <- suppressWarnings(as.numeric(x))
    if (all(is.na(v[!is.na(x)]))) return(NULL)
    return(v)
  }
  as.numeric(x)
}
yvar <- function(x) { v <- num(x); if (is.null(v)) stop("non-numeric outcome"); v }

# dummy from a pattern on labels; fallback to numeric code
dummy <- function(x, pattern, code) {
  l <- lab(x)
  if (any(grepl(pattern, l, ignore.case = TRUE))) {
    d <- as.numeric(grepl(pattern, l, ignore.case = TRUE))
    d[is.na(x)] <- NA
    return(d)
  }
  v <- num(x)
  as.numeric(v == code)
}

cat("US wave1 identity:\n"); print(table(lab(us_survey_wave1$identity_protesters), useNA = "ifany"))
cat("US wave1 tactic:\n"); print(table(lab(us_survey_wave1$tactic), useNA = "ifany"))
cat("ISR wave1 identity:\n"); print(table(lab(isr_survey_wave1$identity_protesters), useNA = "ifany"))
cat("ISR wave1 tactic:\n"); print(table(lab(isr_survey_wave1$tactic), useNA = "ifany"))
cat("US wave2 black/goal/commit:\n")
print(table(lab(us_survey_wave2$black), useNA = "ifany"))
print(table(lab(us_survey_wave2$group_goal), useNA = "ifany"))
print(table(lab(us_survey_wave2$commitment), useNA = "ifany"))
cat("ISR wave2 identity/goal/commit:\n")
print(table(lab(isr_survey_wave2$identity_protesters), useNA = "ifany"))
print(table(lab(isr_survey_wave2$group_goal), useNA = "ifany"))
print(table(lab(isr_survey_wave2$commitment), useNA = "ifany"))

# ---------------- Study 1 US ----------------
u1 <- data.frame(
  dv = yvar(us_survey_wave1$degree_violence),
  pa = yvar(us_survey_wave1$police_action_required),
  black = dummy(us_survey_wave1$identity_protesters, "black|african", 2),
  traffic = dummy(us_survey_wave1$tactic, "traffic", 2),
  destroy = dummy(us_survey_wave1$tactic, "destroy|police car|property|damage", 3),
  w = num(us_survey_wave1$weight)
)
if (all(is.na(u1$w))) u1$w <- 1
u1$w[is.na(u1$w)] <- NA
m_u1_dv <- lm(dv ~ black + traffic + destroy, data = u1, weights = w)
m_u1_pa <- lm(pa ~ black + traffic + destroy, data = u1, weights = w)
print(summary(m_u1_dv)$coefficients); print(summary(m_u1_pa)$coefficients)

# ---------------- Study 1 Israel ----------------
i1 <- data.frame(
  dv = yvar(isr_survey_wave1$degree_violence),
  pa = yvar(isr_survey_wave1$police_action_required),
  eth = dummy(isr_survey_wave1$identity_protesters, "ethiop", 2),
  arab = dummy(isr_survey_wave1$identity_protesters, "arab", 3),
  traffic = dummy(isr_survey_wave1$tactic, "traffic", 2),
  destroy = dummy(isr_survey_wave1$tactic, "destroy|garbage|trash|damage", 3),
  w = num(isr_survey_wave1$weight)
)
if (all(is.na(i1$w))) i1$w <- 1
m_i1_dv <- lm(dv ~ eth + arab + traffic + destroy, data = i1, weights = w)
m_i1_pa <- lm(pa ~ eth + arab + traffic + destroy, data = i1, weights = w)
print(summary(m_i1_dv)$coefficients); print(summary(m_i1_pa)$coefficients)

# ---------------- Study 2 US ----------------
u2 <- data.frame(
  dv = yvar(us_survey_wave2$degree_violence),
  pa = yvar(us_survey_wave2$police_action_required),
  black = dummy(us_survey_wave2$black, "^black$|african", 1),
  goal = dummy(us_survey_wave2$group_goal, "racial|police|prejudice|group|minority", 1),
  commit = dummy(us_survey_wave2$commitment, "^commit|nonviolen|^yes", 1)
)
m_u2_dv <- lm(dv ~ black + goal + commit, data = u2)
m_u2_pa <- lm(pa ~ black + goal + commit, data = u2)
print(summary(m_u2_dv)$coefficients); print(summary(m_u2_pa)$coefficients)

# ---------------- Study 2 Israel ----------------
i2 <- data.frame(
  dv = yvar(isr_survey_wave2$degree_violence),
  id = factor(lab(isr_survey_wave2$identity_protesters)),
  goal = factor(lab(isr_survey_wave2$group_goal)),
  commit = factor(lab(isr_survey_wave2$commitment))
)
m_i2_dv <- lm(dv ~ id + goal + commit, data = i2)
print(summary(m_i2_dv)$coefficients)

cat(sprintf("RESULT:study1_us_black_perceived_violence=%.6f\n", coef(m_u1_dv)["black"]))
cat(sprintf("RESULT:study1_us_black_police_action=%.6f\n", coef(m_u1_pa)["black"]))
cat(sprintf("RESULT:study1_israel_ethiopian_perceived_violence=%.6f\n", coef(m_i1_dv)["eth"]))
cat(sprintf("RESULT:study1_israel_ethiopian_police_action=%.6f\n", coef(m_i1_pa)["eth"]))
cat(sprintf("RESULT:study1_israel_arab_perceived_violence=%.6f\n", coef(m_i1_dv)["arab"]))
cat(sprintf("RESULT:study1_israel_arab_police_action=%.6f\n", coef(m_i1_pa)["arab"]))
cat(sprintf("RESULT:study2_us_black_perceived_violence=%.6f\n", coef(m_u2_dv)["black"]))
cat(sprintf("RESULT:study2_us_black_police_action=%.6f\n", coef(m_u2_pa)["black"]))
cat(sprintf("RESULT:respondents_study1_us=%d\n", as.integer(nobs(m_u1_dv))))
cat(sprintf("RESULT:respondents_study1_israel=%d\n", as.integer(nobs(m_i1_dv))))
cat(sprintf("RESULT:respondents_study2_us=%d\n", as.integer(nobs(m_u2_dv))))
cat(sprintf("RESULT:respondents_study2_israel=%d\n", as.integer(nobs(m_i2_dv))))
