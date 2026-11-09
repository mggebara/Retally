suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/altmann_2022_cognitive_spillovers.script-free/ReplicationPackage/EmpiricalAnalysis/original_data"
lab <- haven::read_dta(file.path(base, "formatted_data_replication.dta"))
mt  <- haven::read_dta(file.path(base, "formatted_data_long_mturk.dta"))

cat("Lab columns:\n"); print(names(lab))
cat("MTurk columns:\n"); print(names(mt))

find_col <- function(df, patterns, exclude = character(0)) {
  nms <- names(df)
  for (p in patterns) {
    hit <- nms[grepl(p, nms, ignore.case = TRUE)]
    if (length(exclude)) hit <- setdiff(hit, exclude)
    if (length(hit)) return(hit[1])
  }
  NA_character_
}

to_num <- function(x) as.numeric(haven::zap_labels(x))

lab <- as.data.frame(lab)
mt  <- as.data.frame(mt)

# ---------------- Sample restriction: scarce cognitive resources ----------------
cand_load <- names(lab)[grepl("^Treatment_", names(lab)) &
                          grepl("load|cogn|resour|scarc", names(lab), ignore.case = TRUE)]
cand_load <- setdiff(cand_load, c("Treatment_Environment", "Treatment_intervention"))
if (length(cand_load) > 0) {
  lc <- cand_load[1]
  cat("Resource treatment column:", lc, "\n")
  lv <- haven::as_factor(lab[[lc]])
  print(table(lv, useNA = "ifany"))
  labs_chr <- tolower(as.character(lv))
  if (any(grepl("scarc|high", labs_chr))) {
    lab <- lab[grepl("scarc|high", labs_chr), ]
  } else if (length(unique(na.omit(to_num(lab[[lc]])))) == 2) {
    lab <- lab[to_num(lab[[lc]]) == 1, ]
  }
} else {
  cat("No resource-condition column found; assuming data contains only the scarce condition.\n")
}

# ---------------- Treatment variables ----------------
lab$intervention <- to_num(lab$Treatment_intervention)
env_f <- haven::as_factor(lab$Treatment_Environment)
cat("Environment table:\n"); print(table(env_f, lab$intervention, useNA = "ifany"))
env_chr <- tolower(as.character(env_f))
env_cat <- ifelse(grepl("base|endogen", env_chr), "baseline",
           ifelse(grepl("direct|attention", env_chr), "directed",
           ifelse(grepl("choice|forc|activ", env_chr), "forced", NA)))
if (all(is.na(env_cat))) {
  ev <- to_num(lab$Treatment_Environment)
  u <- sort(unique(na.omit(ev)))
  env_cat <- c("baseline", "directed", "forced")[match(ev, u)]
}
lab$directed <- as.numeric(env_cat == "directed")
lab$forced   <- as.numeric(env_cat == "forced")
cat("Environment classification:\n"); print(table(env_cat, lab$intervention, useNA = "ifany"))

# ---------------- Outcomes ----------------
quality_col <- find_col(lab, c("^summation_correct$", "task_correct", "decision.*correct", "^correct$"))
default_col <- find_col(lab, c("^passive_choice$", "passive", "default_choice", "default_chosen", "chose_default", "default_adher"))
load_col    <- find_col(lab, c("^load_correct$", "memory_correct", "background.*correct"))
pshare_col  <- find_col(lab, c("^payoff_share$"))
cat("Outcome columns:", quality_col, default_col, load_col, pshare_col, "\n")

lab$y_quality <- to_num(lab[[quality_col]])
lab$y_default <- to_num(lab[[default_col]])
lab$y_load    <- to_num(lab[[load_col]])
lab$y_pshare  <- to_num(lab[[pshare_col]])

# ---------------- Controls ----------------
ctrl <- c()
age_col <- find_col(lab, c("^q_age$", "age"), exclude = c("payoff", "Attention", "attention_mean"))
if (!is.na(age_col) && !grepl("attention|payoff|average", age_col, ignore.case = TRUE)) {
  lab$c_age <- to_num(lab[[age_col]]); ctrl <- c(ctrl, "c_age")
}
if ("q_gender" %in% names(lab)) { lab$c_gender <- factor(to_num(lab$q_gender)); ctrl <- c(ctrl, "c_gender") }
if ("q_subject" %in% names(lab)) {
  lab$c_field <- factor(as.character(haven::as_factor(lab$q_subject))); ctrl <- c(ctrl, "c_field")
} else if ("economist" %in% names(lab)) {
  lab$c_field <- to_num(lab$economist); ctrl <- c(ctrl, "c_field")
}
if ("q_abitur_grade" %in% names(lab)) { lab$c_gpa <- to_num(lab$q_abitur_grade); ctrl <- c(ctrl, "c_gpa") }
if ("q_math_grade" %in% names(lab)) { lab$c_math <- to_num(lab$q_math_grade); ctrl <- c(ctrl, "c_math") }
if ("ability_task" %in% names(lab)) { lab$c_abtask <- to_num(lab$ability_task); ctrl <- c(ctrl, "c_abtask") }
if ("ability_load" %in% names(lab)) { lab$c_abload <- to_num(lab$ability_load); ctrl <- c(ctrl, "c_abload") }
mult_col <- find_col(lab, c("multi"))
if (!is.na(mult_col)) { lab$c_multi <- to_num(lab[[mult_col]]); ctrl <- c(ctrl, "c_multi") }
inc_cols <- names(lab)[grepl("Incentive|payoff_scheme|scheme", names(lab), ignore.case = TRUE)]
k <- 0
for (ic in inc_cols) {
  v <- to_num(lab[[ic]])
  if (length(unique(na.omit(v))) >= 2) {
    k <- k + 1; nm <- paste0("c_inc", k)
    lab[[nm]] <- factor(v); ctrl <- c(ctrl, nm)
  }
}
wave_col <- find_col(lab, c("wave", "experiment", "session_type"))
if (!is.na(wave_col)) {
  v <- to_num(lab[[wave_col]])
  if (length(unique(na.omit(v))) >= 2) { lab$c_wave <- factor(v); ctrl <- c(ctrl, "c_wave") }
}
cat("Control variables used:", paste(ctrl, collapse = ", "), "\n")
cat("Source columns: age=", age_col, " multitask=", mult_col, " incentives=", paste(inc_cols, collapse = ";"),
    " wave=", wave_col, "\n")

ctrl_str <- if (length(ctrl)) paste("+", paste(ctrl, collapse = " + ")) else ""

lab$cl <- lab$subject_id

est <- function(fml, data) feols(as.formula(fml), data = data, cluster = ~cl)

m1 <- est("y_quality ~ intervention", lab)
m2 <- est(paste("y_quality ~ intervention", ctrl_str), lab)
m5 <- est("y_default ~ intervention", lab)
m6 <- est(paste("y_default ~ intervention", ctrl_str), lab)
m7 <- est("y_default ~ directed + forced", lab)
t3_1 <- est("y_load ~ intervention", lab)
t3_2 <- est(paste("y_load ~ intervention", ctrl_str), lab)
t4_1 <- est("y_pshare ~ intervention", lab)

for (m in list(m1, m2, m5, m6, m7, t3_1, t3_2, t4_1)) print(summary(m))

n_obs <- nobs(m1)
n_subj <- length(unique(lab$cl[!is.na(lab$y_quality) & !is.na(lab$intervention)]))

# ---------------- Online experiment ----------------
mt$intervention <- to_num(mt$Treatment_intervention)
mt$memory_y <- to_num(mt$memory)
if (max(mt$memory_y, na.rm = TRUE) > 1) {
  cat("Note: memory variable exceeds 1; summary:\n"); print(summary(mt$memory_y))
}
mt$age_c <- to_num(mt$age)
mt$gender_c <- factor(to_num(mt$gender))
mt$win_w <- to_num(mt$window_width1)
mt$win_h <- to_num(mt$window_height1)
mt$cl <- mt$subject_id
o5 <- feols(memory_y ~ intervention, data = mt, cluster = ~cl)
o6 <- feols(memory_y ~ intervention + age_c + gender_c + win_w + win_h, data = mt, cluster = ~cl)
print(summary(o5)); print(summary(o6))

out <- function(name, val) cat(sprintf("RESULT:%s=%.10g\n", name, val))
out("choice_quality_intervention_t2_col1", coef(m1)["intervention"])
out("choice_quality_intervention_t2_col2", coef(m2)["intervention"])
out("default_adherence_intervention_t2_col5", coef(m5)["intervention"])
out("default_adherence_intervention_t2_col6", coef(m6)["intervention"])
out("default_adherence_directed_attention_t2_col7", coef(m7)["directed"])
out("default_adherence_forced_choice_t2_col7", coef(m7)["forced"])
out("background_quality_intervention_lab_t3_col1", coef(t3_1)["intervention"])
out("background_quality_intervention_lab_t3_col2", coef(t3_2)["intervention"])
out("memory_intervention_online_t3_col5", coef(o5)["intervention"])
out("payoff_share_intervention_t4_col1", coef(t4_1)["intervention"])
out("n_obs_lab_tables_2_to_4", n_obs)
out("n_subjects_lab_tables_2_to_4", n_subj)
out("memory_intervention_online_t3_col6", coef(o6)["intervention"])
