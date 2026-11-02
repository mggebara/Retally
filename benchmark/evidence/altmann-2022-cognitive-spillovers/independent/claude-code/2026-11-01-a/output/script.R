suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/independent/2026-11-01-a/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"

## ---- Lab experiment ----
d <- read_dta(paste0(base, "formatted_data_replication.dta")) %>% zap_labels()
# Scarce cognitive resources = payoff schemes 10/20/40 (Treatment_Incentives 4 = Ample)
lab <- d %>% filter(Treatment_Incentives != 4) %>%
  mutate(intervention = as.numeric(Treatment_intervention),
         directed = as.numeric(Treatment_Environment == 2),
         forced   = as.numeric(Treatment_Environment == 3))

ctrl <- "+ q_age + q_gender + i(subject_cat) + i(q_abitur_grade_cat) + i(q_math_grade_cat) + ability_load + ability_task + perc_multitasking_1 + perc_multitasking_2 + i(Treatment_Incentives) + original_lab"

est <- function(f, data) feols(as.formula(f), data = data, cluster = ~subject_id)
cf <- function(m, v) unname(coef(m)[v])

m1 <- est("summation_correct ~ intervention", lab)
m2 <- est(paste("summation_correct ~ intervention", ctrl), lab)
m5 <- est("default_followed ~ intervention", lab)
m6 <- est(paste("default_followed ~ intervention", ctrl), lab)
m7 <- est("default_followed ~ directed + forced", lab)
b1 <- est("load_correct ~ intervention", lab)
b2 <- est(paste("load_correct ~ intervention", ctrl), lab)
p1 <- est("payoff_share ~ intervention", lab)

for (m in list(m1, m2, m5, m6, m7, b1, b2, p1)) print(summary(m))

## ---- Online experiment ----
o <- read_dta(paste0(base, "formatted_data_long_mturk.dta")) %>% zap_labels() %>%
  mutate(intervention = as.numeric(Treatment_intervention))
o5 <- est("memory ~ intervention", o)
o6 <- est("memory ~ intervention + age + i(gender) + window_height1 + window_width1", o)
print(summary(o5)); print(summary(o6))

res <- c(
  choice_quality_intervention_t2_col1 = cf(m1, "intervention"),
  choice_quality_intervention_t2_col2 = cf(m2, "intervention"),
  default_adherence_intervention_t2_col5 = cf(m5, "intervention"),
  default_adherence_intervention_t2_col6 = cf(m6, "intervention"),
  default_adherence_directed_attention_t2_col7 = cf(m7, "directed"),
  default_adherence_forced_choice_t2_col7 = cf(m7, "forced"),
  background_quality_intervention_lab_t3_col1 = cf(b1, "intervention"),
  background_quality_intervention_lab_t3_col2 = cf(b2, "intervention"),
  memory_intervention_online_t3_col5 = cf(o5, "intervention"),
  payoff_share_intervention_t4_col1 = cf(p1, "intervention"),
  n_obs_lab_tables_2_to_4 = nobs(m1),
  n_subjects_lab_tables_2_to_4 = length(unique(lab$subject_id)),
  memory_intervention_online_t3_col6 = cf(o6, "intervention")
)
cat("N obs col2 (controls):", nobs(m2), "\n")
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
