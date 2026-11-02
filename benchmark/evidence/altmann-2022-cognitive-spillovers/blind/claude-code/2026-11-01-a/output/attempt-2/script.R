# Retally: altmann-2022-cognitive-spillovers, blind independent reproduction (run 2026-11-01-a)
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
base <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/blind/2026-11-01-a/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"

# ---------------- Lab experiment ----------------
d <- read_dta(paste0(base, "formatted_data_replication.dta"))
d <- d %>% mutate(
  incentive = as.character(as_factor(Treatment_Incentives)),
  env = as.character(as_factor(Treatment_Environment)),
  intervention = as.numeric(Treatment_intervention),
  directed = as.numeric(grepl("Directed", env)),
  forced = as.numeric(grepl("Forced", env)),
  choice_quality = as.numeric(summation_correct),
  default_adh = as.numeric(default_followed),
  bg_correct = as.numeric(load_correct),
  payoff_share = as.numeric(payoff_share),
  female = as.numeric(q_gender),
  field = factor(as.numeric(subject_cat)),
  gpa_cat = factor(q_abitur_grade_cat),       # quartiles + category for missing A-level GPA
  math_cat = factor(q_math_grade_cat),
  wave = factor(as.numeric(original_lab)),
  scheme = factor(incentive)
)
# Sample: scarce cognitive resources (seven-digit background task) in Baseline, Directed Attention, Forced Choice
lab <- d %>% filter(incentive != "Ample")
cat("Lab sample: N =", nrow(lab), " subjects =", n_distinct(lab$subject_id), "\n")
print(table(lab$env, lab$intervention))

ctrl <- "q_age + female + field + gpa_cat + math_cat + ability_load + ability_task + perc_multitasking_1 + scheme + wave"
cl <- ~subject_id
est <- function(y, rhs, data = lab) feols(as.formula(paste(y, "~", rhs)), data = data, cluster = cl)

m1 <- est("choice_quality", "intervention")
m2 <- est("choice_quality", paste("intervention +", ctrl))
m5 <- est("default_adh", "intervention")
m6 <- est("default_adh", paste("intervention +", ctrl))
m7 <- est("default_adh", "directed + forced")
t3c1 <- est("bg_correct", "intervention")
t3c2 <- est("bg_correct", paste("intervention +", ctrl))
t4c1 <- est("payoff_share", "intervention")
for (m in list(m1, m2, m5, m6, m7, t3c1, t3c2, t4c1)) print(coeftable(m)[1:3, , drop = FALSE])
cat("nobs:", sapply(list(m1, m2, m5, m6, m7, t3c1, t3c2, t4c1), nobs), "\n")

# ---------------- Online experiment ----------------
o <- read_dta(paste0(base, "formatted_data_long_mturk.dta"))
o <- o %>% mutate(intervention = as.numeric(Treatment_intervention),
                  memory = as.numeric(memory),
                  gender = factor(as.numeric(gender)),
                  sid = as.numeric(subject_id))
o5 <- feols(memory ~ intervention, data = o, cluster = ~sid)
o6 <- feols(memory ~ intervention + age + gender + window_height1 + window_width1, data = o, cluster = ~sid)
print(coeftable(o5)); print(coeftable(o6)[1:2, ])
cat("online nobs:", nobs(o5), nobs(o6), " subjects:", n_distinct(o$sid), "\n")

cat("DEVIATION: GPA and last math grade entered as quartile indicators (GPA with a missing-category), perceived multitasking as the 5-point Likert item; online screen size as window height and width.\n")

r <- function(name, v) cat(sprintf("RESULT:%s=%.6f\n", name, v))
r("choice_quality_intervention_t2_col1", coef(m1)["intervention"])
r("choice_quality_intervention_t2_col2", coef(m2)["intervention"])
r("default_adherence_intervention_t2_col5", coef(m5)["intervention"])
r("default_adherence_intervention_t2_col6", coef(m6)["intervention"])
r("default_adherence_directed_attention_t2_col7", coef(m7)["directed"])
r("default_adherence_forced_choice_t2_col7", coef(m7)["forced"])
r("background_quality_intervention_lab_t3_col1", coef(t3c1)["intervention"])
r("background_quality_intervention_lab_t3_col2", coef(t3c2)["intervention"])
r("memory_intervention_online_t3_col5", coef(o5)["intervention"])
r("payoff_share_intervention_t4_col1", coef(t4c1)["intervention"])
cat(sprintf("RESULT:n_obs_lab_tables_2_to_4=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_subjects_lab_tables_2_to_4=%d\n", n_distinct(lab$subject_id)))
r("memory_intervention_online_t3_col6", coef(o6)["intervention"])
