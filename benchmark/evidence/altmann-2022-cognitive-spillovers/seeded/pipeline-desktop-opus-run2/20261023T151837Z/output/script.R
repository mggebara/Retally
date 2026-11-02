suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/altmann_2022_cognitive_spillovers"
lab_path <- file.path(base_dir, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_replication.dta")
mturk_path <- file.path(base_dir, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_long_mturk.dta")

to_num <- function(x) {
  x <- haven::zap_labels(x)
  suppressWarnings(as.numeric(x))
}

emit <- function(name, value) {
  if (is.null(value) || length(value) == 0 || is.na(value)) {
    cat(sprintf("RESULT:%s=NA\n", name))
  } else {
    cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(value)))
  }
}

make_indicator <- function(x) {
  x <- to_num(x)
  u <- sort(unique(x[!is.na(x)]))
  if (length(u) == 2) {
    as.numeric(x == u[2])
  } else {
    as.numeric(x > min(u))
  }
}

# ---------------- Lab experiment ----------------
lab <- haven::read_dta(lab_path)
lab <- as.data.frame(lapply(lab, function(v) if (inherits(v, "haven_labelled") || is.numeric(v)) to_num(v) else v),
                     stringsAsFactors = FALSE)

lab$Treatment_Incentives <- to_num(lab$Treatment_Incentives)
lab$Treatment_Environment <- to_num(lab$Treatment_Environment)
lab$intervention <- make_indicator(lab$Treatment_intervention)
lab$directed <- as.numeric(lab$Treatment_Environment == 2)
lab$forced <- as.numeric(lab$Treatment_Environment == 3)

sc <- lab[!is.na(lab$Treatment_Incentives) & lab$Treatment_Incentives != 4, ]

# factor versions for controls (missing values stay NA -> listwise deletion like Stata)
fac <- function(x) factor(x)
sc$f_incent <- fac(sc$Treatment_Incentives)
sc$f_wave <- fac(sc$original_lab)
sc$f_gender <- fac(sc$q_gender)
sc$f_multi1 <- fac(sc$perc_multitasking_1_easy)
sc$f_subj <- fac(sc$subject_cat)
sc$f_abitur <- fac(sc$q_abitur_grade_cat)
sc$f_math <- fac(sc$q_math_grade_cat)

ctrl_rhs <- paste(
  "f_incent + f_wave + ability_task + ability_load + ability_task:f_wave + ability_load:f_wave +",
  "q_age + f_gender + f_multi1 + perc_multitasking_2 + f_subj + f_abitur + f_math"
)

run_reg <- function(dep, rhs, data) {
  fml <- as.formula(paste(dep, "~", rhs))
  tryCatch(feols(fml, data = data, cluster = ~subject_id), error = function(e) {
    message("Regression failed: ", conditionMessage(e))
    NULL
  })
}

getcoef <- function(m, v) {
  if (is.null(m)) return(NA)
  cf <- coef(m)
  if (v %in% names(cf)) cf[[v]] else NA
}

# Table 2 Panel (a): choice quality
m1 <- run_reg("summation_correct", "intervention", sc)
m2 <- run_reg("summation_correct", paste("intervention +", ctrl_rhs), sc)

# Table 2 Panel (b): default adherence
m5 <- run_reg("default_followed", "intervention", sc)
m6 <- run_reg("default_followed", paste("intervention +", ctrl_rhs), sc)
m7 <- run_reg("default_followed", "directed + forced", sc)

# Table 3 lab: background task
t3_1 <- run_reg("load_correct", "intervention", sc)
t3_2 <- run_reg("load_correct", paste("intervention +", ctrl_rhs), sc)

# Table 4: payoff share
t4_1 <- run_reg("payoff_share", "intervention", sc)

# N and clusters from column 1 of Table 2
n_obs <- NA
n_subj <- NA
if (!is.null(m1)) {
  n_obs <- nobs(m1)
  used <- sc[!is.na(sc$summation_correct) & !is.na(sc$intervention) & !is.na(sc$subject_id), ]
  n_subj <- length(unique(used$subject_id))
}

# ---------------- Online experiment ----------------
mt <- haven::read_dta(mturk_path)
mt <- as.data.frame(lapply(mt, function(v) if (inherits(v, "haven_labelled") || is.numeric(v)) to_num(v) else v),
                    stringsAsFactors = FALSE)
mt$intervention <- make_indicator(mt$Treatment_intervention)
mt$f_gender <- factor(mt$gender)

o5 <- run_reg("memory", "intervention", mt)
o6 <- run_reg("memory", "intervention + window_height1 + window_width1 + age + f_gender", mt)

# ---------------- Output ----------------
emit("choice_quality_intervention_t2_col1", getcoef(m1, "intervention"))
emit("choice_quality_intervention_t2_col2", getcoef(m2, "intervention"))
emit("default_adherence_intervention_t2_col5", getcoef(m5, "intervention"))
emit("default_adherence_intervention_t2_col6", getcoef(m6, "intervention"))
emit("default_adherence_directed_attention_t2_col7", getcoef(m7, "directed"))
emit("default_adherence_forced_choice_t2_col7", getcoef(m7, "forced"))
emit("background_quality_intervention_lab_t3_col1", getcoef(t3_1, "intervention"))
emit("background_quality_intervention_lab_t3_col2", getcoef(t3_2, "intervention"))
emit("memory_intervention_online_t3_col5", getcoef(o5, "intervention"))
emit("payoff_share_intervention_t4_col1", getcoef(t4_1, "intervention"))
emit("n_obs_lab_tables_2_to_4", n_obs)
emit("n_subjects_lab_tables_2_to_4", n_subj)
emit("memory_intervention_online_t3_col6", getcoef(o6, "intervention"))