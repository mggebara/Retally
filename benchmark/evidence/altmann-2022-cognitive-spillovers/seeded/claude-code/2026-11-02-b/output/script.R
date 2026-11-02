suppressPackageStartupMessages({library(haven); library(fixest); library(dplyr)})
set.seed(42)
root <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/seeded/2026-11-02-b/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data"
lab <- zap_labels(read_dta(file.path(root, "formatted_data_replication.dta")))
on  <- zap_labels(read_dta(file.path(root, "formatted_data_long_mturk.dta")))

# Lab sample: drop Ample (Treatment_Incentives == 4), as in the do-files
d <- lab %>% filter(Treatment_Incentives != 4) %>%
  mutate(interv = as.numeric(Treatment_intervention != 0),
         env = factor(Treatment_Environment),
         f_inc = factor(Treatment_Incentives), f_wave = factor(original_lab),
         f_gender = factor(q_gender), f_pm1 = factor(perc_multitasking_1_easy),
         f_subj = factor(subject_cat), f_abi = factor(q_abitur_grade_cat),
         f_math = factor(q_math_grade_cat))
cat("Treatment_intervention values:", paste(sort(unique(lab$Treatment_intervention)), collapse=","), "\n")

# $Incentive_control $Wave_control $Ability_control $Controls
ctrl <- "f_inc + f_wave + ability_task*f_wave + ability_load*f_wave + q_age + f_gender + f_pm1 + perc_multitasking_2 + f_subj + f_abi + f_math"
est <- function(y, rhs, data, coefname) {
  m <- feols(as.formula(paste(y, "~", rhs)), data = data, cluster = ~subject_id)
  list(b = unname(coef(m)[coefname]), n = nobs(m), m = m)
}
r <- list()
r$c1 <- est("summation_correct", "interv", d, "interv")
r$c2 <- est("summation_correct", paste("interv +", ctrl), d, "interv")
r$c5 <- est("default_followed", "interv", d, "interv")
r$c6 <- est("default_followed", paste("interv +", ctrl), d, "interv")
m7 <- feols(default_followed ~ i(env, ref = "1"), data = d, cluster = ~subject_id)
r$t3c1 <- est("load_correct", "interv", d, "interv")
r$t3c2 <- est("load_correct", paste("interv +", ctrl), d, "interv")
r$t4c1 <- est("payoff_share", "interv", d, "interv")

o <- on %>% mutate(interv = as.numeric(Treatment_intervention != 0), f_gender = factor(gender))
r$m5 <- est("memory", "interv", o, "interv")
r$m6 <- est("memory", "interv + window_height1 + window_width1 + age + f_gender", o, "interv")

for (k in names(r)) cat(sprintf("%-5s b=%.4f N=%d\n", k, r[[k]]$b, r[[k]]$n))
print(coef(m7))
nsub <- length(unique(d$subject_id[!is.na(d$summation_correct)]))

cat(sprintf("RESULT:choice_quality_intervention_t2_col1=%.6f\n", r$c1$b))
cat(sprintf("RESULT:choice_quality_intervention_t2_col2=%.6f\n", r$c2$b))
cat(sprintf("RESULT:default_adherence_intervention_t2_col5=%.6f\n", r$c5$b))
cat(sprintf("RESULT:default_adherence_intervention_t2_col6=%.6f\n", r$c6$b))
cat(sprintf("RESULT:default_adherence_directed_attention_t2_col7=%.6f\n", unname(coef(m7)["env::2"])))
cat(sprintf("RESULT:default_adherence_forced_choice_t2_col7=%.6f\n", unname(coef(m7)["env::3"])))
cat(sprintf("RESULT:background_quality_intervention_lab_t3_col1=%.6f\n", r$t3c1$b))
cat(sprintf("RESULT:background_quality_intervention_lab_t3_col2=%.6f\n", r$t3c2$b))
cat(sprintf("RESULT:memory_intervention_online_t3_col5=%.6f\n", r$m5$b))
cat(sprintf("RESULT:payoff_share_intervention_t4_col1=%.6f\n", r$t4c1$b))
cat(sprintf("RESULT:n_obs_lab_tables_2_to_4=%d\n", r$c1$n))
cat(sprintf("RESULT:n_subjects_lab_tables_2_to_4=%d\n", nsub))
cat(sprintf("RESULT:memory_intervention_online_t3_col6=%.6f\n", r$m6$b))
