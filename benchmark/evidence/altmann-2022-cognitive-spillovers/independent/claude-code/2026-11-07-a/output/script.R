# Independent reproduction: Altmann, Grunewald & Radbruch (2022), "Interventions and Cognitive Spillovers"
# Tables 2-4 (lab, scarce resources) and Table 3 online columns 5-6.
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/independent/2026-11-07-a/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"

d <- read_dta(paste0(base, "formatted_data_replication.dta"))
d <- d %>% mutate(
  env = as.character(as_factor(Treatment_Environment)),
  incent = as.character(as_factor(Treatment_Incentives)),
  intervention = as.numeric(zap_labels(Treatment_intervention) != 0),
  directed = as.numeric(grepl("Directed", env)),
  forced = as.numeric(grepl("Forced", env)),
  summation_correct = as.numeric(zap_labels(summation_correct)),
  default_followed = as.numeric(zap_labels(default_followed)),
  load_correct = as.numeric(zap_labels(load_correct)),
  payoff_share = as.numeric(payoff_share),
  female = as.numeric(zap_labels(q_gender)),
  field = factor(zap_labels(subject_cat)),
  gpa_cat = factor(zap_labels(q_abitur_grade_cat)),   # quartiles + missing category
  math_cat = factor(zap_labels(q_math_grade_cat)),
  payscheme = factor(incent),
  wave = factor(zap_labels(original_lab))
)
# Scarce cognitive resources only (drop Ample), all three environments
s <- d %>% filter(incent != "Ample")
cat("Environments:\n"); print(table(s$env, s$intervention))
cat("N =", nrow(s), " subjects =", length(unique(s$subject_id)), "\n")

ctrl <- "q_age + female + field + gpa_cat + math_cat + ability_load + ability_task + perc_multitasking_1 + payscheme + wave"
est <- function(y, rhs, data) feols(as.formula(paste(y, "~", rhs)), data = data, cluster = ~subject_id)

m1 <- est("summation_correct", "intervention", s)
m2 <- est("summation_correct", paste("intervention +", ctrl), s)
m5 <- est("default_followed", "intervention", s)
m6 <- est("default_followed", paste("intervention +", ctrl), s)
m7 <- est("default_followed", "directed + forced", s)
b1 <- est("load_correct", "intervention", s)
b2 <- est("load_correct", paste("intervention +", ctrl), s)
p1 <- est("payoff_share", "intervention", s)
etable(m1, m2, m5, m6, m7, b1, b2, p1, keep = c("intervention", "directed", "forced"))

# Online experiment
o <- read_dta(paste0(base, "formatted_data_long_mturk.dta")) %>% mutate(
  intervention = as.numeric(zap_labels(Treatment_intervention) != 0),
  memory = as.numeric(memory),
  gender = factor(zap_labels(gender))
)
o5 <- feols(memory ~ intervention, data = o, cluster = ~subject_id)
o6 <- feols(memory ~ intervention + age + gender + window_height1 + window_width1, data = o, cluster = ~subject_id)
etable(o5, o6, keep = "intervention")

r <- function(name, v) cat(sprintf("RESULT:%s=%.6f\n", name, v))
r("choice_quality_intervention_t2_col1", coef(m1)["intervention"])
r("choice_quality_intervention_t2_col2", coef(m2)["intervention"])
r("default_adherence_intervention_t2_col5", coef(m5)["intervention"])
r("default_adherence_intervention_t2_col6", coef(m6)["intervention"])
r("default_adherence_directed_attention_t2_col7", coef(m7)["directed"])
r("default_adherence_forced_choice_t2_col7", coef(m7)["forced"])
r("background_quality_intervention_lab_t3_col1", coef(b1)["intervention"])
r("background_quality_intervention_lab_t3_col2", coef(b2)["intervention"])
r("memory_intervention_online_t3_col5", coef(o5)["intervention"])
r("payoff_share_intervention_t4_col1", coef(p1)["intervention"])
r("n_obs_lab_tables_2_to_4", nobs(m1))
r("n_subjects_lab_tables_2_to_4", length(unique(s$subject_id)))
r("memory_intervention_online_t3_col6", coef(o6)["intervention"])
