# Altmann, Grunewald & Radbruch, "Interventions and Cognitive Spillovers"
# Independent, blind reproduction of Tables 2-4 (lab) and Table 3 cols 5-6 (online).
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/blind/2026-11-07-a/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"

## ---------------- Lab experiment ----------------
d <- read_dta(paste0(D, "formatted_data_replication.dta")) %>% zap_labels()
cat("Treatment_Incentives x Treatment_Environment (subject-rounds):\n")
print(table(d$Treatment_Incentives, d$Treatment_Environment))

# Scarce cognitive resources only: drop the Ample condition (Treatment_Incentives == 4)
lab <- d %>% filter(Treatment_Incentives != 4) %>%
  mutate(directed = as.integer(Treatment_Environment == 2),
         forced   = as.integer(Treatment_Environment == 3),
         scheme   = factor(Treatment_Incentives),
         wave     = factor(original_lab),
         field    = factor(subject_cat),
         gpa_cat  = factor(q_abitur_grade_cat),   # quartiles + missing category (keeps N constant)
         math_cat = factor(q_math_grade_cat))
cat("Lab sample: obs =", nrow(lab), " subjects =", n_distinct(lab$subject_id), "\n")
cat("Mean default_followed by environment:\n"); print(tapply(lab$default_followed, lab$Treatment_Environment, mean))

ctrl <- "q_age + q_gender + field + gpa_cat + math_cat + ability_load + ability_task + perc_multitasking_1 + scheme + wave"
est <- function(dep, rhs, data) feols(as.formula(paste(dep, "~", rhs)), data = data, cluster = ~subject_id)

t2c1 <- est("summation_correct", "Treatment_intervention", lab)
t2c2 <- est("summation_correct", paste("Treatment_intervention +", ctrl), lab)
t2c5 <- est("default_followed", "Treatment_intervention", lab)
t2c6 <- est("default_followed", paste("Treatment_intervention +", ctrl), lab)
t2c7 <- est("default_followed", "directed + forced", lab)
t3c1 <- est("load_correct", "Treatment_intervention", lab)
t3c2 <- est("load_correct", paste("Treatment_intervention +", ctrl), lab)
t4c1 <- est("payoff_share", "Treatment_intervention", lab)
etable(t2c1, t2c2, t2c5, t2c6, t2c7, t3c1, t3c2, t4c1, se.below = TRUE)
nobs_all <- sapply(list(t2c1, t2c2, t2c5, t2c6, t2c7, t3c1, t3c2, t4c1), nobs)
cat("N per lab column:", nobs_all, "\n")

## ---------------- Online experiment ----------------
m <- read_dta(paste0(D, "formatted_data_long_mturk.dta")) %>% zap_labels() %>%
  mutate(gender_f = factor(gender))
cat("Online sample: obs =", nrow(m), " subjects =", n_distinct(m$subject_id), "\n")
t3c5 <- feols(memory ~ Treatment_intervention, data = m, cluster = ~subject_id)
t3c6 <- feols(memory ~ Treatment_intervention + age + gender_f + window_height1 + window_width1,
              data = m, cluster = ~subject_id)
etable(t3c5, t3c6, se.below = TRUE)

## ---------------- Results ----------------
b <- function(mod, v) unname(coef(mod)[v])
out <- c(
  choice_quality_intervention_t2_col1 = b(t2c1, "Treatment_intervention"),
  choice_quality_intervention_t2_col2 = b(t2c2, "Treatment_intervention"),
  default_adherence_intervention_t2_col5 = b(t2c5, "Treatment_intervention"),
  default_adherence_intervention_t2_col6 = b(t2c6, "Treatment_intervention"),
  default_adherence_directed_attention_t2_col7 = b(t2c7, "directed"),
  default_adherence_forced_choice_t2_col7 = b(t2c7, "forced"),
  background_quality_intervention_lab_t3_col1 = b(t3c1, "Treatment_intervention"),
  background_quality_intervention_lab_t3_col2 = b(t3c2, "Treatment_intervention"),
  memory_intervention_online_t3_col5 = b(t3c5, "Treatment_intervention"),
  payoff_share_intervention_t4_col1 = b(t4c1, "Treatment_intervention"),
  n_obs_lab_tables_2_to_4 = nobs(t2c1),
  n_subjects_lab_tables_2_to_4 = n_distinct(lab$subject_id),
  memory_intervention_online_t3_col6 = b(t3c6, "Treatment_intervention")
)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
