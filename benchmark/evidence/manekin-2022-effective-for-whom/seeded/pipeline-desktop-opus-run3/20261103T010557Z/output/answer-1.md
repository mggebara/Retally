set.seed(42)

base_dir <- "<repo>/.cache/datasets/manekin_2022_effective_for_whom"
data_dir <- file.path(base_dir, "Replication", "Data")

load(file.path(data_dir, "us_survey_wave1.rdata"))
load(file.path(data_dir, "isr_survey_wave1.rdata"))
load(file.path(data_dir, "us_survey_wave2.rdata"))
load(file.path(data_dir, "isr_survey_wave2.rdata"))

# Make a factor with the majority / "march" baseline as reference level,
# mirroring how lm() treats the authors' variables.
to_factor <- function(x, base_pattern = NULL) {
  if (is.factor(x)) {
    f <- droplevels(x)
  } else if (is.numeric(x) || is.logical(x)) {
    f <- factor(as.numeric(x))
  } else {
    f <- factor(as.character(x))
    if (!is.null(base_pattern)) {
      hit <- grep(base_pattern, levels(f), ignore.case = TRUE, value = TRUE)
      if (length(hit) > 0) f <- relevel(f, ref = hit[1])
    }
  }
  f
}

find_coef <- function(model, prefix, pattern = NULL, idx = NULL) {
  cf <- coef(model)
  nm <- names(cf)
  cand <- nm[startsWith(nm, prefix)]
  if (!is.null(pattern)) {
    hit <- cand[grepl(pattern, cand, ignore.case = TRUE)]
    if (length(hit) > 0) return(hit[1])
  }
  if (!is.null(idx) && length(cand) >= idx) return(cand[idx])
  if (length(cand) > 0) return(cand[1])
  NA_character_
}

get_est <- function(model, term) {
  s <- summary(model)$coefficients
  c(est = unname(s[term, "Estimate"]), se = unname(s[term, "Std. Error"]))
}

emit <- function(name, value) {
  cat(sprintf("RESULT:%s=%s\n", name, format(value, digits = 10)))
}

## ---------------- Table 1, Panel A: US Study 1 (weighted OLS) ----------------
us1 <- us_survey_wave1
us1$identity_protesters <- to_factor(us1$identity_protesters, "white")
us1$tactic <- to_factor(us1$tactic, "march")

us1_degv   <- lm(degree_violence ~ identity_protesters + tactic, data = us1, weights = weight)
us1_police <- lm(police_action_required ~ identity_protesters + tactic, data = us1, weights = weight)

t_black_us1 <- find_coef(us1_degv, "identity_protesters", "black", 1)
b1 <- get_est(us1_degv, t_black_us1)
b2 <- get_est(us1_police, t_black_us1)

## ---------------- Table 1, Panel B: Israel Study 1 (weighted OLS) ----------------
isr1 <- isr_survey_wave1
isr1$identity_protesters <- to_factor(isr1$identity_protesters, "white|jew")
isr1$tactic <- to_factor(isr1$tactic, "march")

isr1_degv   <- lm(degree_violence ~ identity_protesters + tactic, data = isr1, weights = weight)
isr1_police <- lm(police_action_required ~ identity_protesters + tactic, data = isr1, weights = weight)

t_eth <- find_coef(isr1_degv, "identity_protesters", "eth", 1)
t_arab <- find_coef(isr1_degv, "identity_protesters", "arab", 2)

e1 <- get_est(isr1_degv, t_eth)
e2 <- get_est(isr1_police, t_eth)
a1 <- get_est(isr1_degv, t_arab)
a2 <- get_est(isr1_police, t_arab)

## ---------------- Table 2, Panel A: US Study 2 (unweighted OLS) ----------------
us2 <- us_survey_wave2
us2_degv   <- lm(degree_violence ~ black + group_goal + commitment, data = us2)
us2_recall <- lm(recall_violence2 ~ black + group_goal + commitment, data = us2)
us2_police <- lm(police_action_required ~ black + group_goal + commitment, data = us2)

t_black_us2 <- find_coef(us2_degv, "black")
c1 <- get_est(us2_degv, t_black_us2)
c2 <- get_est(us2_police, t_black_us2)

## ---------------- Table 2, Panel B: Israel Study 2 (unweighted OLS) ----------------
isr2 <- isr_survey_wave2
isr2_degv <- lm(degree_violence ~ identity_protesters + group_goal + commitment, data = isr2)

## ---------------- Output ----------------
emit("study1_us_black_perceived_violence", b1["est"])
emit("study1_us_black_perceived_violence_se", b1["se"])
emit("study1_us_black_police_action", b2["est"])
emit("study1_us_black_police_action_se", b2["se"])

emit("study1_israel_ethiopian_perceived_violence", e1["est"])
emit("study1_israel_ethiopian_perceived_violence_se", e1["se"])
emit("study1_israel_ethiopian_police_action", e2["est"])
emit("study1_israel_ethiopian_police_action_se", e2["se"])
emit("study1_israel_arab_perceived_violence", a1["est"])
emit("study1_israel_arab_perceived_violence_se", a1["se"])
emit("study1_israel_arab_police_action", a2["est"])
emit("study1_israel_arab_police_action_se", a2["se"])

emit("study2_us_black_perceived_violence", c1["est"])
emit("study2_us_black_perceived_violence_se", c1["se"])
emit("study2_us_black_police_action", c2["est"])
emit("study2_us_black_police_action_se", c2["se"])

emit("respondents_study1_us", nobs(us1_degv))
emit("respondents_study1_israel", nobs(isr1_degv))
emit("respondents_study2_us", nobs(us2_degv))
emit("respondents_study2_israel", nobs(isr2_degv))
