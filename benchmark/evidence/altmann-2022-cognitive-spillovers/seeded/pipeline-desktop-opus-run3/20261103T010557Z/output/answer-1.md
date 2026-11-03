suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/altmann_2022_cognitive_spillovers"
lab_path <- file.path(base_dir, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_replication.dta")
mturk_path <- file.path(base_dir, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_long_mturk.dta")

to_num <- function(x) as.numeric(haven::zap_labels(x))

emit <- function(name, value) {
  if (is.null(value) || length(value) == 0 || is.na(value)) {
    cat(sprintf("RESULT:%s=NA\n", name))
  } else {
    cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(value)))
  }
}

get_coef <- function(model, var) {
  if (is.null(model)) return(NA_real_)
  cf <- coef(model)
  if (var %in% names(cf)) unname(cf[var]) else NA_real_
}

safe_feols <- function(fml, data) {
  tryCatch(
    feols(fml, data = data, vcov = ~subject_id),
    error = function(e) {
      message("Model failed: ", deparse(fml), " -- ", conditionMessage(e))
      NULL
    }
  )
}

# ---------------------------------------------------------------
# Lab experiment
# ---------------------------------------------------------------
lab <- haven::read_dta(lab_path)
lab <- as.data.frame(lab)

num_vars <- c("Treatment_Incentives", "Treatment_intervention", "Treatment_Environment",
              "summation_correct", "default_followed", "load_correct", "payoff_share",
              "subject_id", "original_lab", "q_age", "q_gender", "perc_multitasking_1_easy",
              "perc_multitasking_2", "subject_cat", "q_abitur_grade_cat", "q_math_grade_cat",
              "ability_task", "ability_load")
for (v in intersect(num_vars, names(lab))) lab[[v]] <- to_num(lab[[v]])

scarce <- lab[!is.na(lab$Treatment_Incentives) & lab$Treatment_Incentives != 4, ]
scarce$directed <- as.numeric(scarce$Treatment_Environment == 2)
scarce$forced   <- as.numeric(scarce$Treatment_Environment == 3)

# Global controls (as in master.do)
ctrl <- paste(
  "factor(Treatment_Incentives)",                 # Incentive_control
  "factor(original_lab)",                          # Wave_control
  "ability_task * factor(original_lab)",           # Ability_control
  "ability_load * factor(original_lab)",
  "q_age", "factor(q_gender)", "factor(perc_multitasking_1_easy)", "perc_multitasking_2",
  "factor(subject_cat)", "factor(q_abitur_grade_cat)", "factor(q_math_grade_cat)",
  sep = " + "
)

mk <- function(y, rhs) as.formula(paste(y, "~", rhs))

# Table 2, Panel (a): choice quality
t2_c1 <- safe_feols(mk("summation_correct", "Treatment_intervention"), scarce)
t2_c2 <- safe_feols(mk("summation_correct", paste("Treatment_intervention +", ctrl)), scarce)

# Table 2, Panel (b): default adherence
t2_c5 <- safe_feols(mk("default_followed", "Treatment_intervention"), scarce)
t2_c6 <- safe_feols(mk("default_followed", paste("Treatment_intervention +", ctrl)), scarce)
t2_c7 <- safe_feols(mk("default_followed", "directed + forced"), scarce)

# Table 3, lab: background task quality
t3_c1 <- safe_feols(mk("load_correct", "Treatment_intervention"), scarce)
t3_c2 <- safe_feols(mk("load_correct", paste("Treatment_intervention +", ctrl)), scarce)

# Table 4: payoff share
t4_c1 <- safe_feols(mk("payoff_share", "Treatment_intervention"), scarce)

# ---------------------------------------------------------------
# Online experiment (MTurk)
# ---------------------------------------------------------------
mt <- as.data.frame(haven::read_dta(mturk_path))
for (v in intersect(c("memory", "Treatment_intervention", "subject_id", "age", "gender",
                      "window_height1", "window_width1"), names(mt))) {
  mt[[v]] <- to_num(mt[[v]])
}

t3_c5 <- safe_feols(memory ~ Treatment_intervention, mt)
t3_c6 <- safe_feols(memory ~ Treatment_intervention + window_height1 + window_width1 + age + factor(gender), mt)

# ---------------------------------------------------------------
# Output
# ---------------------------------------------------------------
emit("choice_quality_intervention_t2_col1", get_coef(t2_c1, "Treatment_intervention"))
emit("choice_quality_intervention_t2_col2", get_coef(t2_c2, "Treatment_intervention"))
emit("default_adherence_intervention_t2_col5", get_coef(t2_c5, "Treatment_intervention"))
emit("default_adherence_intervention_t2_col6", get_coef(t2_c6, "Treatment_intervention"))
emit("default_adherence_directed_attention_t2_col7", get_coef(t2_c7, "directed"))
emit("default_adherence_forced_choice_t2_col7", get_coef(t2_c7, "forced"))
emit("background_quality_intervention_lab_t3_col1", get_coef(t3_c1, "Treatment_intervention"))
emit("background_quality_intervention_lab_t3_col2", get_coef(t3_c2, "Treatment_intervention"))
emit("memory_intervention_online_t3_col5", get_coef(t3_c5, "Treatment_intervention"))
emit("payoff_share_intervention_t4_col1", get_coef(t4_c1, "Treatment_intervention"))

n_obs <- if (!is.null(t2_c1)) nobs(t2_c1) else NA_real_
n_subj <- if (!is.null(t2_c1)) {
  length(unique(scarce$subject_id[!is.na(scarce$summation_correct) & !is.na(scarce$Treatment_intervention)]))
} else NA_real_
emit("n_obs_lab_tables_2_to_4", n_obs)
emit("n_subjects_lab_tables_2_to_4", n_subj)

emit("memory_intervention_online_t3_col6", get_coef(t3_c6, "Treatment_intervention"))
