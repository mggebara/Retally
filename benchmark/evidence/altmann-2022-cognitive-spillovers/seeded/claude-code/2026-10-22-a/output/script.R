suppressPackageStartupMessages({library(haven); library(fixest)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/seeded/2026-10-22-a/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data"

# ---- Lab experiment: drop Ample (Treatment_Incentives == 4), as in the do-files ----
lab <- as.data.frame(zap_labels(read_dta(file.path(base, "formatted_data_replication.dta"))))
lab <- lab[!is.na(lab$Treatment_Incentives) & lab$Treatment_Incentives != 4, ]
for (v in c("Treatment_intervention", "Treatment_Environment", "Treatment_Incentives", "original_lab",
            "q_gender", "perc_multitasking_1_easy", "subject_cat", "q_abitur_grade_cat", "q_math_grade_cat"))
  lab[[paste0("f_", v)]] <- factor(lab[[v]])
lab$f_Treatment_Environment <- relevel(lab$f_Treatment_Environment, ref = "1")
lab$f_Treatment_intervention <- relevel(lab$f_Treatment_intervention, ref = "0")

# $Incentive_control $Wave_control $Ability_control $Controls from master.do
ctrl <- paste("f_Treatment_Incentives + f_original_lab + (ability_task + ability_load) * f_original_lab +",
              "q_age + f_q_gender + f_perc_multitasking_1_easy + perc_multitasking_2 + f_subject_cat +",
              "f_q_abitur_grade_cat + f_q_math_grade_cat")
est <- function(y, x, controls = FALSE, d = lab) {
  rhs <- if (controls) paste(x, "+", ctrl) else x
  feols(as.formula(paste(y, "~", rhs)), data = d, cluster = ~subject_id)
}
co <- function(m, nm) unname(coef(m)[nm])
out <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
nclust <- function(m, d) length(unique(d$subject_id[obs(m)]))

m1 <- est("summation_correct", "f_Treatment_intervention")          # T2 col1
m2 <- est("summation_correct", "f_Treatment_intervention", TRUE)    # T2 col2
m5 <- est("default_followed", "f_Treatment_intervention")           # T2 col5
m6 <- est("default_followed", "f_Treatment_intervention", TRUE)     # T2 col6
m7 <- est("default_followed", "f_Treatment_Environment")            # T2 col7
b1 <- est("load_correct", "f_Treatment_intervention")               # T3 col1
b2 <- est("load_correct", "f_Treatment_intervention", TRUE)         # T3 col2
p1 <- est("payoff_share", "f_Treatment_intervention")               # T4 col1

# ---- Online (MTurk) experiment ----
mt <- as.data.frame(zap_labels(read_dta(file.path(base, "formatted_data_long_mturk.dta"))))
mt$f_Treatment_intervention <- relevel(factor(mt$Treatment_intervention), ref = "0")
mt$f_gender <- factor(mt$gender)
o5 <- feols(memory ~ f_Treatment_intervention, data = mt, cluster = ~subject_id)
o6 <- feols(memory ~ f_Treatment_intervention + window_height1 + window_width1 + age + f_gender,
            data = mt, cluster = ~subject_id)

for (nm in c("m1", "m2", "m5", "m6", "m7", "b1", "b2", "p1")) {
  m <- get(nm); cat("#", nm, "nobs", nobs(m), "clusters", nclust(m, lab), "\n")
}
cat("# online nobs", nobs(o5), nobs(o6), "\n")

ti <- "f_Treatment_intervention1"
out("choice_quality_intervention_t2_col1", co(m1, ti))
out("choice_quality_intervention_t2_col2", co(m2, ti))
out("default_adherence_intervention_t2_col5", co(m5, ti))
out("default_adherence_intervention_t2_col6", co(m6, ti))
out("default_adherence_directed_attention_t2_col7", co(m7, "f_Treatment_Environment2"))
out("default_adherence_forced_choice_t2_col7", co(m7, "f_Treatment_Environment3"))
out("background_quality_intervention_lab_t3_col1", co(b1, ti))
out("background_quality_intervention_lab_t3_col2", co(b2, ti))
out("memory_intervention_online_t3_col5", co(o5, ti))
out("payoff_share_intervention_t4_col1", co(p1, ti))
out("n_obs_lab_tables_2_to_4", nobs(m1))
out("n_subjects_lab_tables_2_to_4", nclust(m1, lab))
out("memory_intervention_online_t3_col6", co(o6, ti))
