# Independent reproduction: Altmann, Grunewald & Radbruch, "Interventions and Cognitive Spillovers"
# Tables 2-4 (lab) and Table 3 online columns, from the paper/claim descriptions only.
suppressMessages({library(haven); library(fixest)})
set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/independent/2026-11-02-c/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"

lab <- as.data.frame(zap_labels(read_dta(paste0(d, "formatted_data_replication.dta"))))
# Sample: scarce cognitive resources (drop the Ample incentive condition), Baseline / Directed Attention / Forced Choice
lab <- subset(lab, Treatment_Incentives != 4 & Treatment_Environment %in% 1:3)
lab$directed <- as.integer(lab$Treatment_Environment == 2)
lab$forced   <- as.integer(lab$Treatment_Environment == 3)
cat("N lab:", nrow(lab), " subjects:", length(unique(lab$subject_id)), "\n")
print(aggregate(cbind(summation_correct, default_followed, load_correct, payoff_share) ~ Treatment_Environment, lab, mean))
cat("NA in controls:\n")
print(colSums(is.na(lab[, c("q_age","q_gender","subject_cat","q_abitur_grade","q_abitur_grade_cat","q_math_grade","q_math_grade_cat",
                           "ability_load","ability_task","perc_multitasking_1","perc_multitasking_2","Treatment_Incentives","original_lab")])))

# Controls: age, gender, field of study, high-school GPA (category incl. missing), last math grade,
# ability in background and decision tasks, perceived multitasking, payoff scheme and wave indicators
ctrl <- "q_age + q_gender + i(subject_cat) + i(q_abitur_grade_cat) + i(q_math_grade_cat) + ability_load + ability_task + perc_multitasking_1 + perc_multitasking_2 + i(Treatment_Incentives) + original_lab"

est <- function(y, rhs, data, cl = ~subject_id) {
  m <- feols(as.formula(paste(y, "~", rhs)), data = data, cluster = cl)
  print(summary(m)$coeftable[1:min(3, length(coef(m))), , drop = FALSE]); cat("nobs:", nobs(m), "\n")
  m
}
m1 <- est("summation_correct", "Treatment_intervention", lab)
m2 <- est("summation_correct", paste("Treatment_intervention +", ctrl), lab)
m5 <- est("default_followed", "Treatment_intervention", lab)
m6 <- est("default_followed", paste("Treatment_intervention +", ctrl), lab)
m7 <- est("default_followed", "directed + forced", lab)
b1 <- est("load_correct", "Treatment_intervention", lab)
b2 <- est("load_correct", paste("Treatment_intervention +", ctrl), lab)
p1 <- est("payoff_share", "Treatment_intervention", lab)

on <- as.data.frame(zap_labels(read_dta(paste0(d, "formatted_data_long_mturk.dta"))))
cat("N online:", nrow(on), " subjects:", length(unique(on$subject_id)), "\n")
o5 <- est("memory", "Treatment_intervention", on)
o6 <- est("memory", "Treatment_intervention + age + i(gender) + window_height1 + window_width1", on)

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("choice_quality_intervention_t2_col1", coef(m1)["Treatment_intervention"])
r("choice_quality_intervention_t2_col2", coef(m2)["Treatment_intervention"])
r("default_adherence_intervention_t2_col5", coef(m5)["Treatment_intervention"])
r("default_adherence_intervention_t2_col6", coef(m6)["Treatment_intervention"])
r("default_adherence_directed_attention_t2_col7", coef(m7)["directed"])
r("default_adherence_forced_choice_t2_col7", coef(m7)["forced"])
r("background_quality_intervention_lab_t3_col1", coef(b1)["Treatment_intervention"])
r("background_quality_intervention_lab_t3_col2", coef(b2)["Treatment_intervention"])
r("memory_intervention_online_t3_col5", coef(o5)["Treatment_intervention"])
r("payoff_share_intervention_t4_col1", coef(p1)["Treatment_intervention"])
r("n_obs_lab_tables_2_to_4", nobs(m1))
r("n_subjects_lab_tables_2_to_4", length(unique(lab$subject_id[!is.na(lab$summation_correct)])))
r("memory_intervention_online_t3_col6", coef(o6)["Treatment_intervention"])
