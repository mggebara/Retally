# Altmann, Grunewald & Radbruch (2022) "Interventions and Cognitive Spillovers"
# Independent blind reproduction of Tables 2-4 (lab) and Table 3 online columns.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/blind/2026-10-22-a/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"

# ---------------- Lab experiment ----------------
d <- read_dta(paste0(D, "formatted_data_replication.dta"))
d <- d %>% mutate(
  incent   = as.character(as_factor(Treatment_Incentives)),
  env      = as.character(as_factor(Treatment_Environment)),
  interv   = as.numeric(Treatment_intervention),
  directed = as.numeric(grepl("Directed", env)),
  forced   = as.numeric(grepl("Forced", env)),
  correct_dt = as.numeric(summation_correct),
  correct_bt = as.numeric(load_correct),
  default_f  = as.numeric(default_followed),
  female   = as.numeric(q_gender),
  wave     = factor(as.numeric(original_lab)),
  scheme   = factor(incent),
  field    = factor(as.numeric(subject_cat)),
  gpa_cat  = factor(q_abitur_grade_cat),
  math_cat = factor(q_math_grade_cat)
)
# Sample: scarce cognitive resources (7-digit numbers) = all non-Ample incentive cells,
# all three decision environments, all 20 main-part rounds.
s <- d %>% filter(incent != "Ample")
cat("Environment x intervention in scarce sample:\n"); print(table(s$env, s$interv))
cat("Scheme x wave:\n"); print(table(s$scheme, s$wave))
cat("Mean default adherence by environment:\n"); print(tapply(s$default_f, s$env, mean))

ctrl <- "q_age + female + field + gpa_cat + math_cat + ability_load + ability_task + perc_multitasking_1 + scheme + wave"
est <- function(y, x, controls = FALSE, data = s) {
  f <- as.formula(paste(y, "~", x, if (controls) paste("+", ctrl) else ""))
  m <- feols(f, data = data, cluster = ~subject_id)
  print(summary(m)$coeftable[1:min(3, nrow(coeftable(m))), , drop = FALSE])
  m
}
m1 <- est("correct_dt", "interv")
m2 <- est("correct_dt", "interv", TRUE)
m5 <- est("default_f", "interv")
m6 <- est("default_f", "interv", TRUE)
m7 <- est("default_f", "directed + forced")
b1 <- est("correct_bt", "interv")
b2 <- est("correct_bt", "interv", TRUE)
p1 <- est("payoff_share", "interv")
cat("nobs:", nobs(m1), nobs(m2), nobs(m5), nobs(m6), nobs(m7), nobs(b1), nobs(b2), nobs(p1), "\n")

# ---------------- Online experiment ----------------
o <- read_dta(paste0(D, "formatted_data_long_mturk.dta"))
o <- o %>% mutate(interv = as.numeric(Treatment_intervention),
                  gender_f = factor(as.numeric(gender)))
o5 <- feols(memory ~ interv, data = o, cluster = ~subject_id)
o6 <- feols(memory ~ interv + age + gender_f + window_height1 + window_width1, data = o, cluster = ~subject_id)
print(coeftable(o5)); print(coeftable(o6)[1:2, ])
cat("online nobs:", nobs(o5), nobs(o6), " subjects:", length(unique(o$subject_id)), "\n")

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("choice_quality_intervention_t2_col1", coef(m1)["interv"])
r("choice_quality_intervention_t2_col2", coef(m2)["interv"])
r("default_adherence_intervention_t2_col5", coef(m5)["interv"])
r("default_adherence_intervention_t2_col6", coef(m6)["interv"])
r("default_adherence_directed_attention_t2_col7", coef(m7)["directed"])
r("default_adherence_forced_choice_t2_col7", coef(m7)["forced"])
r("background_quality_intervention_lab_t3_col1", coef(b1)["interv"])
r("background_quality_intervention_lab_t3_col2", coef(b2)["interv"])
r("memory_intervention_online_t3_col5", coef(o5)["interv"])
r("payoff_share_intervention_t4_col1", coef(p1)["interv"])
cat(sprintf("RESULT:n_obs_lab_tables_2_to_4=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_subjects_lab_tables_2_to_4=%d\n", length(unique(s$subject_id))))
r("memory_intervention_online_t3_col6", coef(o6)["interv"])
