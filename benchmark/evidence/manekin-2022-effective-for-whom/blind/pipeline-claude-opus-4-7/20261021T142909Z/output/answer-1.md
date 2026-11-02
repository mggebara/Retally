#!/usr/bin/env Rscript

set.seed(42)

suppressPackageStartupMessages({
  library(dplyr)
})

base <- "<repo>/.cache/datasets/manekin_2022_effective_for_whom.script-free/Replication/Data"

load(file.path(base, "us_survey_wave1.rdata"))
load(file.path(base, "isr_survey_wave1.rdata"))
load(file.path(base, "us_survey_wave2.rdata"))
load(file.path(base, "isr_survey_wave2.rdata"))

# ---- Study 1 US ----
d <- us_survey_wave1
cat("US wave1 identity levels:", paste(unique(as.character(d$identity_protesters)), collapse="|"), "\n")
cat("US wave1 tactic levels:", paste(unique(as.character(d$tactic)), collapse="|"), "\n")

d$identity_protesters <- as.factor(d$identity_protesters)
d$tactic <- as.factor(d$tactic)

# Set baseline: white, march
if ("white" %in% levels(d$identity_protesters)) {
  d$identity_protesters <- relevel(d$identity_protesters, ref = "white")
}
tactic_levels <- levels(d$tactic)
march_lvl <- tactic_levels[grep("march", tactic_levels, ignore.case = TRUE)][1]
if (!is.na(march_lvl)) d$tactic <- relevel(d$tactic, ref = march_lvl)

w <- if ("weight" %in% names(d)) d$weight else rep(1, nrow(d))

m1_viol <- lm(degree_violence ~ identity_protesters + tactic, data = d, weights = w)
m1_pol  <- lm(police_action_required ~ identity_protesters + tactic, data = d, weights = w)

# Find black coefficient
cf1v <- coef(m1_viol)
cf1p <- coef(m1_pol)
black_name_v <- names(cf1v)[grep("black", names(cf1v), ignore.case = TRUE)][1]
black_name_p <- names(cf1p)[grep("black", names(cf1p), ignore.case = TRUE)][1]

study1_us_black_perceived_violence <- unname(cf1v[black_name_v])
study1_us_black_police_action <- unname(cf1p[black_name_p])
n_study1_us <- nobs(m1_viol)

# ---- Study 1 Israel ----
d2 <- isr_survey_wave1
cat("ISR wave1 identity levels:", paste(unique(as.character(d2$identity_protesters)), collapse="|"), "\n")
cat("ISR wave1 tactic levels:", paste(unique(as.character(d2$tactic)), collapse="|"), "\n")

d2$identity_protesters <- as.factor(d2$identity_protesters)
d2$tactic <- as.factor(d2$tactic)

id_lvls <- levels(d2$identity_protesters)
white_lvl <- id_lvls[grep("white|jew", id_lvls, ignore.case = TRUE)]
# Prefer "white" exactly
if ("white" %in% id_lvls) {
  d2$identity_protesters <- relevel(d2$identity_protesters, ref = "white")
} else if (length(white_lvl) > 0) {
  # pick the one that's majority (white jews)
  wl <- white_lvl[grep("white", white_lvl, ignore.case = TRUE)]
  if (length(wl) > 0) d2$identity_protesters <- relevel(d2$identity_protesters, ref = wl[1])
}

tl2 <- levels(d2$tactic)
march2 <- tl2[grep("march", tl2, ignore.case = TRUE)][1]
if (!is.na(march2)) d2$tactic <- relevel(d2$tactic, ref = march2)

w2 <- if ("weight" %in% names(d2)) {
  ww <- d2$weight
  if (all(is.na(ww))) rep(1, nrow(d2)) else ww
} else rep(1, nrow(d2))

m2_viol <- lm(degree_violence ~ identity_protesters + tactic, data = d2, weights = w2)
m2_pol  <- lm(police_action_required ~ identity_protesters + tactic, data = d2, weights = w2)

cf2v <- coef(m2_viol); cf2p <- coef(m2_pol)
eth_name_v <- names(cf2v)[grep("ethiop", names(cf2v), ignore.case = TRUE)][1]
eth_name_p <- names(cf2p)[grep("ethiop", names(cf2p), ignore.case = TRUE)][1]
arab_name_v <- names(cf2v)[grep("arab", names(cf2v), ignore.case = TRUE)][1]
arab_name_p <- names(cf2p)[grep("arab", names(cf2p), ignore.case = TRUE)][1]

study1_israel_ethiopian_perceived_violence <- unname(cf2v[eth_name_v])
study1_israel_ethiopian_police_action <- unname(cf2p[eth_name_p])
study1_israel_arab_perceived_violence <- unname(cf2v[arab_name_v])
study1_israel_arab_police_action <- unname(cf2p[arab_name_p])
n_study1_israel <- nobs(m2_viol)

# ---- Study 2 US ----
d3 <- us_survey_wave2
# black is already a variable
if (!"black" %in% names(d3) && "identity_protesters_fac" %in% names(d3)) {
  d3$black <- as.integer(grepl("black", as.character(d3$identity_protesters_fac), ignore.case = TRUE))
}

m3_viol <- lm(degree_violence ~ black + group_goal + commitment, data = d3)
m3_pol  <- lm(police_action_required ~ black + group_goal + commitment, data = d3)

study2_us_black_perceived_violence <- unname(coef(m3_viol)["black"])
study2_us_black_police_action <- unname(coef(m3_pol)["black"])
n_study2_us <- nobs(m3_viol)

# ---- Study 2 Israel sample size ----
d4 <- isr_survey_wave2
m4 <- lm(degree_violence ~ identity_protesters + group_goal + commitment, data = d4)
n_study2_israel <- nobs(m4)

# ---- Output ----
cat(sprintf("RESULT:study1_us_black_perceived_violence=%.6f\n", study1_us_black_perceived_violence))
cat(sprintf("RESULT:study1_us_black_police_action=%.6f\n", study1_us_black_police_action))
cat(sprintf("RESULT:study1_israel_ethiopian_perceived_violence=%.6f\n", study1_israel_ethiopian_perceived_violence))
cat(sprintf("RESULT:study1_israel_ethiopian_police_action=%.6f\n", study1_israel_ethiopian_police_action))
cat(sprintf("RESULT:study1_israel_arab_perceived_violence=%.6f\n", study1_israel_arab_perceived_violence))
cat(sprintf("RESULT:study1_israel_arab_police_action=%.6f\n", study1_israel_arab_police_action))
cat(sprintf("RESULT:study2_us_black_perceived_violence=%.6f\n", study2_us_black_perceived_violence))
cat(sprintf("RESULT:study2_us_black_police_action=%.6f\n", study2_us_black_police_action))
cat(sprintf("RESULT:respondents_study1_us=%d\n", n_study1_us))
cat(sprintf("RESULT:respondents_study1_israel=%d\n", n_study1_israel))
cat(sprintf("RESULT:respondents_study2_us=%d\n", n_study2_us))
cat(sprintf("RESULT:respondents_study2_israel=%d\n", n_study2_israel))