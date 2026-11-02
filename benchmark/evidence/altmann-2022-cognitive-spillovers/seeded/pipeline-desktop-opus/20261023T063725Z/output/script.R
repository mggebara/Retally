suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/altmann_2022_cognitive_spillovers"
lab_path <- file.path(base_dir, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_replication.dta")
mturk_path <- file.path(base_dir, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_long_mturk.dta")

to_plain <- function(df) {
  df <- haven::zap_labels(df)
  df <- haven::zap_missing(df)
  for (v in names(df)) {
    if (inherits(df[[v]], "haven_labelled")) df[[v]] <- as.vector(df[[v]])
  }
  as.data.frame(df)
}

results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) {
    results[[name]] <<- val
  }
}

get_coef <- function(m, name) {
  cf <- coef(m)
  if (name %in% names(cf)) return(unname(cf[name]))
  NA_real_
}

# ---------------- Lab experiment ----------------
lab <- to_plain(haven::read_dta(lab_path))

# Scarce cognitive resources only (Treatment_Incentives != 4)
lab_s <- lab[!is.na(lab$Treatment_Incentives) & lab$Treatment_Incentives != 4, ]

# Treatment indicators (Baseline = reference)
int_base <- min(lab_s$Treatment_intervention, na.rm = TRUE)
lab_s$d_int <- as.numeric(lab_s$Treatment_intervention != int_base)
lab_s$d_int[is.na(lab_s$Treatment_intervention)] <- NA
lab_s$d_dir <- as.numeric(lab_s$Treatment_Environment == 2)
lab_s$d_forced <- as.numeric(lab_s$Treatment_Environment == 3)
lab_s$d_dir[is.na(lab_s$Treatment_Environment)] <- NA
lab_s$d_forced[is.na(lab_s$Treatment_Environment)] <- NA

# Factor versions of controls
fac_vars <- c("Treatment_Incentives", "original_lab", "q_gender", "perc_multitasking_1_easy",
              "subject_cat", "q_abitur_grade_cat", "q_math_grade_cat")
for (v in fac_vars) {
  if (v %in% names(lab_s)) lab_s[[paste0("f_", v)]] <- factor(lab_s[[v]])
}
lab_s$ol_num <- as.numeric(lab_s$original_lab)

ctrl_terms <- c(
  "f_Treatment_Incentives",                 # Incentive_control
  "f_original_lab",                         # Wave_control
  "ability_task", "ability_load",           # Ability_control main effects
  "ability_task:f_original_lab", "ability_load:f_original_lab",
  "q_age", "f_q_gender", "f_perc_multitasking_1_easy", "perc_multitasking_2",
  "f_subject_cat", "f_q_abitur_grade_cat", "f_q_math_grade_cat"
)
ctrl_str <- paste(ctrl_terms, collapse = " + ")

run_lab <- function(dep, rhs, controls = FALSE) {
  f <- if (controls) paste(dep, "~", rhs, "+", ctrl_str) else paste(dep, "~", rhs)
  tryCatch(
    feols(as.formula(f), data = lab_s, cluster = ~subject_id),
    error = function(e) { message("Model failed: ", f, " -- ", conditionMessage(e)); NULL }
  )
}

# Table 2 Panel (a): choice quality
m1 <- run_lab("summation_correct", "d_int", FALSE)
m2 <- run_lab("summation_correct", "d_int", TRUE)
if (!is.null(m1)) emit("choice_quality_intervention_t2_col1", get_coef(m1, "d_int"))
if (!is.null(m2)) emit("choice_quality_intervention_t2_col2", get_coef(m2, "d_int"))

# Table 2 Panel (b): default adherence
m5 <- run_lab("default_followed", "d_int", FALSE)
m6 <- run_lab("default_followed", "d_int", TRUE)
m7 <- run_lab("default_followed", "d_dir + d_forced", FALSE)
if (!is.null(m5)) emit("default_adherence_intervention_t2_col5", get_coef(m5, "d_int"))
if (!is.null(m6)) emit("default_adherence_intervention_t2_col6", get_coef(m6, "d_int"))
if (!is.null(m7)) {
  emit("default_adherence_directed_attention_t2_col7", get_coef(m7, "d_dir"))
  emit("default_adherence_forced_choice_t2_col7", get_coef(m7, "d_forced"))
}

# Table 3 lab: background task quality
b1 <- run_lab("load_correct", "d_int", FALSE)
b2 <- run_lab("load_correct", "d_int", TRUE)
if (!is.null(b1)) emit("background_quality_intervention_lab_t3_col1", get_coef(b1, "d_int"))
if (!is.null(b2)) emit("background_quality_intervention_lab_t3_col2", get_coef(b2, "d_int"))

# Table 4: payoff share
p1 <- run_lab("payoff_share", "d_int", FALSE)
if (!is.null(p1)) emit("payoff_share_intervention_t4_col1", get_coef(p1, "d_int"))

# N and number of subjects (Table 2 col 1 sample)
if (!is.null(m1)) {
  emit("n_obs_lab_tables_2_to_4", as.numeric(nobs(m1)))
  used <- obs(m1)
  emit("n_subjects_lab_tables_2_to_4", as.numeric(length(unique(lab_s$subject_id[used]))))
}

# ---------------- Online experiment ----------------
mt <- tryCatch(to_plain(haven::read_dta(mturk_path)), error = function(e) NULL)
if (!is.null(mt)) {
  ib <- min(mt$Treatment_intervention, na.rm = TRUE)
  mt$d_int <- as.numeric(mt$Treatment_intervention != ib)
  mt$d_int[is.na(mt$Treatment_intervention)] <- NA
  mt$f_gender <- factor(mt$gender)
  o5 <- tryCatch(feols(memory ~ d_int, data = mt, cluster = ~subject_id),
                 error = function(e) NULL)
  o6 <- tryCatch(feols(memory ~ d_int + window_height1 + window_width1 + age + f_gender,
                       data = mt, cluster = ~subject_id),
                 error = function(e) NULL)
  if (!is.null(o5)) emit("memory_intervention_online_t3_col5", get_coef(o5, "d_int"))
  if (!is.null(o6)) emit("memory_intervention_online_t3_col6", get_coef(o6, "d_int"))
}

for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
}