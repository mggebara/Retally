# Independent reproduction: Altmann, Grunewald & Radbruch, "Interventions and Cognitive Spillovers"
# Tables 2-4 (lab) and Table 3 online columns, reconstructed from the paper/claim descriptions.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/independent/2026-10-22-a/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"

## ---- Lab experiment ----
d <- zap_labels(read_dta(paste0(D, "formatted_data_replication.dta")))
# Scarce cognitive resources only: drop the Ample incentive condition (Treatment_Incentives == 4)
s <- d %>% filter(Treatment_Incentives != 4) %>%
  mutate(DA = as.integer(Treatment_Environment == 2),
         FC = as.integer(Treatment_Environment == 3),
         field = factor(subject_cat),
         gpa_cat = factor(q_abitur_grade_cat),   # quartiles of A-level GPA, category 5 = missing
         math_cat = factor(q_math_grade_cat),    # quartiles of last math grade
         scheme = factor(Treatment_Incentives),
         wave = factor(original_lab))

ctrl <- "q_age + q_gender + field + gpa_cat + math_cat + ability_load + ability_task + perc_multitasking_1 + perc_multitasking_2 + scheme + wave"
est <- function(y, rhs, data = s) feols(as.formula(paste(y, "~", rhs)), data = data, cluster = ~subject_id)
cf <- function(m, v = "Treatment_intervention") unname(coef(m)[v])

m1 <- est("summation_correct", "Treatment_intervention")
m2 <- est("summation_correct", paste("Treatment_intervention +", ctrl))
m5 <- est("default_followed", "Treatment_intervention")
m6 <- est("default_followed", paste("Treatment_intervention +", ctrl))
m7 <- est("default_followed", "DA + FC")
b1 <- est("load_correct", "Treatment_intervention")
b2 <- est("load_correct", paste("Treatment_intervention +", ctrl))
p1 <- est("payoff_share", "Treatment_intervention")
for (m in list(m1, m2, m5, m6, m7, b1, b2, p1)) print(coeftable(m)[1:min(3, nrow(coeftable(m))), , drop = FALSE])
cat("nobs:", sapply(list(m1, m2, m5, m6, m7, b1, b2, p1), nobs), "\n")

## ---- Online experiment ----
o <- zap_labels(read_dta(paste0(D, "formatted_data_long_mturk.dta")))
o5 <- feols(memory ~ Treatment_intervention, data = o, cluster = ~subject_id)
o6 <- feols(memory ~ Treatment_intervention + age + factor(gender) + window_height1 + window_width1,
            data = o, cluster = ~subject_id)
print(coeftable(o5)); print(coeftable(o6)[1:2, ]); cat("online nobs:", nobs(o5), nobs(o6), "\n")

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("choice_quality_intervention_t2_col1", cf(m1))
r("choice_quality_intervention_t2_col2", cf(m2))
r("default_adherence_intervention_t2_col5", cf(m5))
r("default_adherence_intervention_t2_col6", cf(m6))
r("default_adherence_directed_attention_t2_col7", cf(m7, "DA"))
r("default_adherence_forced_choice_t2_col7", cf(m7, "FC"))
r("background_quality_intervention_lab_t3_col1", cf(b1))
r("background_quality_intervention_lab_t3_col2", cf(b2))
r("memory_intervention_online_t3_col5", cf(o5))
r("payoff_share_intervention_t4_col1", cf(p1))
r("n_obs_lab_tables_2_to_4", nobs(m1))
r("n_subjects_lab_tables_2_to_4", length(unique(s$subject_id)))
r("memory_intervention_online_t3_col6", cf(o6))
