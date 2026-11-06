suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/altmann_2022_cognitive_spillovers.script-free"
lab_path <- file.path(base, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_replication.dta")
mt_path  <- file.path(base, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_long_mturk.dta")

lab_raw <- read_dta(lab_path)
nm <- names(lab_raw)

# helper: get label of a column
var_label_of <- function(df, v) {
  l <- attr(df[[v]], "label")
  if (is.null(l)) "" else as.character(l)
}
labs <- vapply(nm, function(v) var_label_of(lab_raw, v), character(1))
find_col <- function(patterns, exclude = character(0), in_labels = TRUE) {
  for (p in patterns) {
    hit <- nm[grepl(p, nm, ignore.case = TRUE)]
    if (in_labels) hit <- union(hit, nm[grepl(p, labs, ignore.case = TRUE)])
    hit <- setdiff(hit, exclude)
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}
to_num <- function(x) as.numeric(zap_labels(x))
fac_lab <- function(x) {
  if (inherits(x, "haven_labelled")) as.character(as_factor(x, levels = "labels")) else as.character(x)
}

lab <- lab_raw
cat(sprintf("SAMPLE:lab:loaded=%d\n", nrow(lab)))

# ---------- Identify the cognitive-resource (scarce) condition ----------
load_col <- NA_character_
for (cand in nm) {
  if (cand %in% c("load_correct", "ability_load")) next
  lv <- tolower(paste(c(cand, labs[cand], fac_lab(unique(lab[[cand]]))), collapse = " "))
  if (grepl("scarce|high[_ ]?load|cognitive load|treatment_load|load treatment|ample|low[_ ]?load", lv) &&
      !grepl("incentive", tolower(cand)) && length(unique(na.omit(lab[[cand]]))) == 2) {
    load_col <- cand; break
  }
}
if (!is.na(load_col)) {
  v <- lab[[load_col]]
  vl <- tolower(fac_lab(v))
  if (any(grepl("scarce|high", vl))) {
    is_scarce <- grepl("scarce|high", vl)
  } else if (grepl("ample|low", tolower(paste(load_col, labs[load_col])))) {
    is_scarce <- to_num(v) == 0
  } else {
    is_scarce <- to_num(v) == 1
  }
  lab <- lab[!is.na(is_scarce) & is_scarce, ]
}
cat(sprintf("SAMPLE:lab:scarce_cognitive_resources=%d\n", nrow(lab)))

# ---------- Decision environments ----------
env_raw <- lab$Treatment_Environment
env_txt <- tolower(fac_lab(env_raw))
env <- case_when(
  grepl("base|endogen", env_txt) ~ "Baseline",
  grepl("direct|forced att|forced_att", env_txt) ~ "Directed",
  grepl("forced|active", env_txt) ~ "Forced",
  TRUE ~ NA_character_
)
if (all(is.na(env))) {
  ev <- to_num(env_raw)
  u <- sort(unique(na.omit(ev)))
  env <- c("Baseline", "Directed", "Forced")[match(ev, u)]
}
lab$env <- env
lab <- lab[!is.na(lab$env), ]
cat(sprintf("SAMPLE:lab:three_decision_environments=%d\n", nrow(lab)))

lab$intervention <- to_num(lab$Treatment_intervention)
if (all(is.na(lab$intervention))) lab$intervention <- as.numeric(lab$env != "Baseline")
lab$intervention[is.na(lab$intervention)] <- as.numeric(lab$env[is.na(lab$intervention)] != "Baseline")
lab$directed <- as.numeric(lab$env == "Directed")
lab$forced   <- as.numeric(lab$env == "Forced")

# main part rounds only (20 rounds)
lab$round_n <- to_num(lab$round)
if (length(unique(na.omit(lab$round_n))) > 20) {
  lab <- lab[lab$round_n %in% sort(unique(lab$round_n), decreasing = TRUE)[1:20], ]
}
cat(sprintf("SAMPLE:lab:main_part_rounds=%d\n", nrow(lab)))

# ---------- Outcomes ----------
lab$choice_quality <- to_num(lab$summation_correct)
lab$background_quality <- to_num(lab$load_correct)
lab$payoff_share_v <- to_num(lab$payoff_share)

def_col <- find_col(c("^passive", "passive_choice", "stick.*default", "default_adher", "default_choice$",
                      "choice_default", "chose_default", "default_chosen", "^default$", "stick to default",
                      "default option", "coincides with default"),
                    exclude = c("default_correct_choice"))
if (!is.na(def_col)) {
  lab$default_adh <- to_num(lab[[def_col]])
} else {
  lab$default_adh <- NA_real_
}

# ---------- Controls ----------
age_col   <- find_col(c("^q_age$", "^age$", "q_age", "\\bage\\b"))
gend_col  <- if ("q_gender" %in% nm) "q_gender" else find_col(c("gender", "female"))
subj_col  <- if ("q_subject" %in% nm) "q_subject" else find_col(c("field of study", "subject of study"))
gpa_col   <- if ("q_abitur_grade" %in% nm) "q_abitur_grade" else find_col(c("abitur", "gpa"))
math_col  <- if ("q_math_grade" %in% nm) "q_math_grade" else find_col(c("math_grade"))
multi_col <- find_col(c("multitask", "multi_task", "multi-task"))
wave_col  <- find_col(c("wave", "experiment_wave", "^experiment$"))
inc_cols  <- nm[grepl("^Treatment_Incentive", nm)]
inc_col   <- find_col(c("payoff_scheme", "incentive_scheme", "^Treatment_Incentives$", "Treatment_Incentive"))

lab$c_age   <- if (!is.na(age_col)) to_num(lab[[age_col]]) else 0
lab$c_gend  <- if (!is.na(gend_col)) factor(to_num(lab[[gend_col]])) else factor(0)
lab$c_subj  <- if (!is.na(subj_col)) factor(fac_lab(lab[[subj_col]])) else factor(0)
lab$c_gpa   <- if (!is.na(gpa_col)) to_num(lab[[gpa_col]]) else 0
lab$c_math  <- if (!is.na(math_col)) to_num(lab[[math_col]]) else 0
lab$c_abl   <- to_num(lab$ability_load)
lab$c_abt   <- to_num(lab$ability_task)
lab$c_multi <- if (!is.na(multi_col)) to_num(lab[[multi_col]]) else 0
lab$c_wave  <- if (!is.na(wave_col)) factor(to_num(lab[[wave_col]])) else factor(0)
# payoff scheme: combine all incentive indicators into one factor
if (length(inc_cols) > 0) {
  lab$c_inc <- factor(do.call(paste, c(lapply(inc_cols, function(v) to_num(lab[[v]])), sep = "_")))
} else {
  lab$c_inc <- factor(0)
}

ctrl_terms <- c("c_age", "c_gend", "c_subj", "c_gpa", "c_math", "c_abl", "c_abt", "c_multi", "c_inc", "c_wave")
keep_ctrl <- ctrl_terms[vapply(ctrl_terms, function(v) {
  x <- lab[[v]]; length(unique(na.omit(x))) > 1
}, logical(1))]
ctrl_rhs <- paste(keep_ctrl, collapse = " + ")

lab$subject_id_n <- to_num(lab$subject_id)

est <- function(y, rhs, data, sname) {
  f <- as.formula(paste(y, "~", rhs))
  m <- feols(f, data = data, cluster = ~subject_id_n)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", sname, nobs(m)))
  m
}

m1 <- est("choice_quality", "intervention", lab, "t2_col1")
m2 <- est("choice_quality", paste("intervention +", ctrl_rhs), lab, "t2_col2")
m5 <- est("default_adh", "intervention", lab, "t2_col5")
m6 <- est("default_adh", paste("intervention +", ctrl_rhs), lab, "t2_col6")
m7 <- est("default_adh", "directed + forced", lab, "t2_col7")
t3_1 <- est("background_quality", "intervention", lab, "t3_col1")
t3_2 <- est("background_quality", paste("intervention +", ctrl_rhs), lab, "t3_col2")
t4_1 <- est("payoff_share_v", "intervention", lab, "t4_col1")

n_obs_lab <- nobs(m1)
n_subj_lab <- length(unique(lab$subject_id_n[!is.na(lab$choice_quality)]))

# ---------- Online experiment ----------
mt <- read_dta(mt_path)
cat(sprintf("SAMPLE:online:loaded=%d\n", nrow(mt)))
mt$memory_v <- to_num(mt$memory)
if (max(mt$memory_v, na.rm = TRUE) > 1) {
  # points = pairs uncovered; convert to fraction if a total is implied
  mx <- max(mt$memory_v, na.rm = TRUE)
  mt$memory_v <- mt$memory_v / mx
}
mt$intervention <- to_num(mt$Treatment_intervention)
mt$age_v <- to_num(mt$age)
mt$gender_v <- factor(to_num(mt$gender))
mt$wh <- to_num(mt$window_height1)
mt$ww <- to_num(mt$window_width1)
mt$subject_id_n <- to_num(mt$subject_id)
o5 <- feols(memory_v ~ intervention, data = mt, cluster = ~subject_id_n)
cat(sprintf("SAMPLE:online_col5:estimation=%d\n", nobs(o5)))
o6 <- feols(memory_v ~ intervention + age_v + gender_v + wh + ww, data = mt, cluster = ~subject_id_n)
cat(sprintf("SAMPLE:online_col6:estimation=%d\n", nobs(o6)))

g <- function(m, v) unname(coef(m)[v])
se <- function(m, v) unname(sqrt(diag(vcov(m)))[v])

out <- list(
  choice_quality_intervention_t2_col1 = g(m1, "intervention"),
  choice_quality_intervention_t2_col2 = g(m2, "intervention"),
  default_adherence_intervention_t2_col5 = g(m5, "intervention"),
  default_adherence_intervention_t2_col6 = g(m6, "intervention"),
  default_adherence_directed_attention_t2_col7 = g(m7, "directed"),
  default_adherence_forced_choice_t2_col7 = g(m7, "forced"),
  background_quality_intervention_lab_t3_col1 = g(t3_1, "intervention"),
  background_quality_intervention_lab_t3_col2 = g(t3_2, "intervention"),
  memory_intervention_online_t3_col5 = g(o5, "intervention"),
  payoff_share_intervention_t4_col1 = g(t4_1, "intervention"),
  n_obs_lab_tables_2_to_4 = n_obs_lab,
  n_subjects_lab_tables_2_to_4 = n_subj_lab,
  memory_intervention_online_t3_col6 = g(o6, "intervention")
)
for (k in names(out)) cat(sprintf("RESULT:%s=%.6f\n", k, out[[k]]))
