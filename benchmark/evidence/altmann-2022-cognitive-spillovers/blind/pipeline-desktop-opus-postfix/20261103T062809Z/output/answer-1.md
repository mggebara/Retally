suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/altmann_2022_cognitive_spillovers.script-free"
lab_path <- file.path(base, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_replication.dta")
mt_path  <- file.path(base, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_long_mturk.dta")

get_label <- function(x) {
  l <- attr(x, "label")
  if (is.null(l)) "" else as.character(l)
}
lab_txt <- function(x) {
  if (inherits(x, "haven_labelled")) as.character(haven::as_factor(x, levels = "both")) else as.character(x)
}
find_col <- function(df, patterns, exclude = character(0), use_labels = TRUE) {
  nms <- names(df)
  for (p in patterns) {
    hit <- nms[grepl(p, nms, ignore.case = TRUE)]
    hit <- setdiff(hit, exclude)
    if (length(hit) > 0) return(hit[1])
  }
  if (use_labels) {
    labs <- vapply(df, get_label, character(1))
    for (p in patterns) {
      hit <- nms[grepl(p, labs, ignore.case = TRUE)]
      hit <- setdiff(hit, exclude)
      if (length(hit) > 0) return(hit[1])
    }
  }
  NA_character_
}
safe_coef <- function(m, v) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}
safe_fit <- function(fml, data, cl) {
  tryCatch(feols(fml, data = data, cluster = cl, warn = FALSE, notes = FALSE),
           error = function(e) { message("Estimation failed: ", conditionMessage(e)); NULL })
}
num <- function(x) suppressWarnings(as.numeric(haven::zap_labels(x)))

# ---------------------------------------------------------------- lab data
lab <- haven::read_dta(lab_path)
cat(sprintf("SAMPLE:lab:loaded=%d\n", nrow(lab)))

# Restriction 1: scarce cognitive resources (7-digit background number)
load_col <- find_col(lab,
  c("^Treatment_Load", "^Treatment_load", "^Treatment_Cognitive", "^Treatment_Scarc",
    "^high_load$", "^scarce", "^Treatment_Resource", "cognitive_load", "^load_treat", "^Treatment_High"),
  exclude = c("load_correct", "ability_load", "high_task_difficulty"), use_labels = FALSE)
if (is.na(load_col)) {
  labs <- vapply(lab, get_label, character(1))
  cand <- names(lab)[grepl("scarce|high load|cognitive load|load treatment", labs, ignore.case = TRUE)]
  cand <- setdiff(cand, c("load_correct", "ability_load", "high_task_difficulty"))
  if (length(cand) > 0) load_col <- cand[1]
}
if (!is.na(load_col) && length(unique(na.omit(num(lab[[load_col]])))) == 2) {
  lt <- tolower(lab_txt(lab[[load_col]]))
  vals <- num(lab[[load_col]])
  if (any(grepl("scarce|high|7", lt))) {
    keep <- grepl("scarce|high|7", lt) & !grepl("ample|low", lt)
  } else {
    keep <- vals == max(vals, na.rm = TRUE)
  }
  keep[is.na(keep)] <- FALSE
  lab <- lab[keep, ]
}
cat(sprintf("SAMPLE:lab:scarce_resources=%d\n", nrow(lab)))

# Restriction 2: three decision environments (Baseline, Directed Attention, Forced Choice)
env_txt <- tolower(lab_txt(lab$Treatment_Environment))
is_fc  <- grepl("forced choice|active", env_txt)
is_da  <- grepl("direct|forced attention|attention", env_txt) & !is_fc
is_bl  <- grepl("baseline|endogenous", env_txt) & !is_fc & !is_da
# Fallback if labels are not informative
if (sum(is_fc) == 0 && sum(is_da) == 0) {
  ev <- num(lab$Treatment_Environment)
  u <- sort(unique(na.omit(ev)))
  is_bl <- ev == u[1]; is_da <- ev == u[min(2, length(u))]; is_fc <- ev == u[min(3, length(u))]
  is_bl[is.na(is_bl)] <- FALSE; is_da[is.na(is_da)] <- FALSE; is_fc[is.na(is_fc)] <- FALSE
}
lab <- lab[is_bl | is_da | is_fc, ]
is_fc <- is_fc[is_bl | is_da | is_fc]
env_txt <- tolower(lab_txt(lab$Treatment_Environment))
is_fc  <- grepl("forced choice|active", env_txt)
is_da  <- grepl("direct|forced attention|attention", env_txt) & !is_fc
cat(sprintf("SAMPLE:lab:three_environments=%d\n", nrow(lab)))

lab$directed <- as.numeric(is_da)
lab$forced   <- as.numeric(is_fc)
ti <- num(lab$Treatment_intervention)
lab$intervention <- if (all(is.na(ti))) as.numeric(is_da | is_fc) else ti

# Restriction 3: main-part rounds (20 rounds)
lab$round_n <- num(lab$round)
if (length(unique(na.omit(lab$round_n))) > 20) {
  lab <- lab[lab$round_n %in% sort(unique(na.omit(lab$round_n)))[seq_len(20)], ]
}
cat(sprintf("SAMPLE:lab:main_part_rounds=%d\n", nrow(lab)))

lab$subject_id <- num(lab$subject_id)
lab$choice_correct <- num(lab$summation_correct)
lab$background_correct <- num(lab$load_correct)
lab$payoff_share_n <- num(lab$payoff_share)

# Default adherence indicator
def_col <- find_col(lab,
  c("^passive_choice$", "^default_choice$", "^stick_default", "^choice_default", "^chose_default",
    "^default_chosen", "^default_adher", "^passiv", "default_option", "^stick", "^default$",
    "^choice_is_default", "default_selected"),
  exclude = c("default_correct_choice"), use_labels = FALSE)
if (is.na(def_col)) {
  labs <- vapply(lab, get_label, character(1))
  cand <- names(lab)[grepl("default", labs, ignore.case = TRUE) &
                       grepl("stick|chos|choice|adher|passiv|select", labs, ignore.case = TRUE)]
  cand <- setdiff(cand, c("default_correct_choice", "Treatment_Environment"))
  if (length(cand) > 0) def_col <- cand[1]
}
lab$default_adh <- if (!is.na(def_col)) num(lab[[def_col]]) else NA_real_

# Controls
ctrl_specs <- list(
  age      = list(p = c("^q_age$", "^age$", "age"), fac = FALSE),
  gender   = list(p = c("^q_gender$", "gender", "female"), fac = TRUE),
  field    = list(p = c("^q_subject$", "field", "study"), fac = TRUE),
  gpa      = list(p = c("^q_abitur_grade$", "abitur", "gpa"), fac = FALSE),
  math     = list(p = c("^q_math_grade$"), fac = FALSE),
  ab_load  = list(p = c("^ability_load$"), fac = FALSE),
  ab_task  = list(p = c("^ability_task$"), fac = FALSE),
  multi    = list(p = c("multitask", "multi_task", "multi"), fac = FALSE),
  wave     = list(p = c("wave"), fac = TRUE)
)
ctrl_terms <- character(0)
for (nm in names(ctrl_specs)) {
  col <- find_col(lab, ctrl_specs[[nm]]$p,
                  exclude = c("Treatment_Environment", "Treatment_intervention", "subject_id"))
  if (!is.na(col)) {
    v <- if (ctrl_specs[[nm]]$fac) as.character(num(lab[[col]])) else num(lab[[col]])
    if (ctrl_specs[[nm]]$fac && all(is.na(num(lab[[col]])))) v <- as.character(lab[[col]])
    newn <- paste0("c_", nm)
    lab[[newn]] <- v
    if (length(unique(na.omit(v))) > 1) {
      ctrl_terms <- c(ctrl_terms, if (ctrl_specs[[nm]]$fac) paste0("factor(", newn, ")") else newn)
    }
  }
}
# Payoff-scheme indicators
inc_cols <- grep("^Treatment_Incentive|incentive|payoff_scheme", names(lab), value = TRUE, ignore.case = TRUE)
for (i in seq_along(inc_cols)) {
  newn <- paste0("c_inc", i)
  lab[[newn]] <- num(lab[[inc_cols[i]]])
  if (length(unique(na.omit(lab[[newn]]))) > 1) {
    if (length(unique(na.omit(lab[[newn]]))) > 2) {
      ctrl_terms <- c(ctrl_terms, paste0("factor(", newn, ")"))
    } else ctrl_terms <- c(ctrl_terms, newn)
  }
}
ctrl_str <- if (length(ctrl_terms) > 0) paste(ctrl_terms, collapse = " + ") else "1"

lab <- as.data.frame(lab)
cl <- ~subject_id

m_cq1 <- safe_fit(choice_correct ~ intervention, lab, cl)
m_cq2 <- safe_fit(as.formula(paste("choice_correct ~ intervention +", ctrl_str)), lab, cl)
m_da5 <- if (all(is.na(lab$default_adh))) NULL else safe_fit(default_adh ~ intervention, lab, cl)
m_da6 <- if (all(is.na(lab$default_adh))) NULL else safe_fit(as.formula(paste("default_adh ~ intervention +", ctrl_str)), lab, cl)
m_da7 <- if (all(is.na(lab$default_adh))) NULL else safe_fit(default_adh ~ directed + forced, lab, cl)
m_bq1 <- safe_fit(background_correct ~ intervention, lab, cl)
m_bq2 <- safe_fit(as.formula(paste("background_correct ~ intervention +", ctrl_str)), lab, cl)
m_ps1 <- safe_fit(payoff_share_n ~ intervention, lab, cl)

cat(sprintf("SAMPLE:table2_choice_col1:estimation=%d\n", if (is.null(m_cq1)) 0L else nobs(m_cq1)))
cat(sprintf("SAMPLE:table2_choice_col2:estimation=%d\n", if (is.null(m_cq2)) 0L else nobs(m_cq2)))
cat(sprintf("SAMPLE:table2_default_col5:estimation=%d\n", if (is.null(m_da5)) 0L else nobs(m_da5)))
cat(sprintf("SAMPLE:table2_default_col6:estimation=%d\n", if (is.null(m_da6)) 0L else nobs(m_da6)))
cat(sprintf("SAMPLE:table2_default_col7:estimation=%d\n", if (is.null(m_da7)) 0L else nobs(m_da7)))
cat(sprintf("SAMPLE:table3_lab_col1:estimation=%d\n", if (is.null(m_bq1)) 0L else nobs(m_bq1)))
cat(sprintf("SAMPLE:table3_lab_col2:estimation=%d\n", if (is.null(m_bq2)) 0L else nobs(m_bq2)))
cat(sprintf("SAMPLE:table4_col1:estimation=%d\n", if (is.null(m_ps1)) 0L else nobs(m_ps1)))

n_obs_lab <- if (!is.null(m_cq1)) nobs(m_cq1) else nrow(lab)
n_subj_lab <- if (!is.null(m_cq1)) {
  length(unique(lab$subject_id[!is.na(lab$choice_correct) & !is.na(lab$intervention)]))
} else length(unique(lab$subject_id))

# ---------------------------------------------------------------- online data
mt <- haven::read_dta(mt_path)
cat(sprintf("SAMPLE:online:loaded=%d\n", nrow(mt)))
mt <- as.data.frame(mt)
mt$subject_id <- num(mt$subject_id)
mt$intervention <- num(mt$Treatment_intervention)
mem <- num(mt$memory)
mt$memory_frac <- if (max(mem, na.rm = TRUE) <= 1) mem else mem / max(mem, na.rm = TRUE)
mt$age_n <- num(mt$age)
mt$gender_n <- num(mt$gender)
mt$win_h <- num(mt$window_height1)
mt$win_w <- num(mt$window_width1)

m_on5 <- safe_fit(memory_frac ~ intervention, mt, ~subject_id)
m_on6 <- safe_fit(memory_frac ~ intervention + age_n + gender_n + win_h + win_w, mt, ~subject_id)
cat(sprintf("SAMPLE:online_col5:estimation=%d\n", if (is.null(m_on5)) 0L else nobs(m_on5)))
cat(sprintf("SAMPLE:online_col6:estimation=%d\n", if (is.null(m_on6)) 0L else nobs(m_on6)))

# ---------------------------------------------------------------- results
out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))
out("choice_quality_intervention_t2_col1", safe_coef(m_cq1, "intervention"))
out("choice_quality_intervention_t2_col2", safe_coef(m_cq2, "intervention"))
out("default_adherence_intervention_t2_col5", safe_coef(m_da5, "intervention"))
out("default_adherence_intervention_t2_col6", safe_coef(m_da6, "intervention"))
out("default_adherence_directed_attention_t2_col7", safe_coef(m_da7, "directed"))
out("default_adherence_forced_choice_t2_col7", safe_coef(m_da7, "forced"))
out("background_quality_intervention_lab_t3_col1", safe_coef(m_bq1, "intervention"))
out("background_quality_intervention_lab_t3_col2", safe_coef(m_bq2, "intervention"))
out("memory_intervention_online_t3_col5", safe_coef(m_on5, "intervention"))
out("payoff_share_intervention_t4_col1", safe_coef(m_ps1, "intervention"))
cat(sprintf("RESULT:n_obs_lab_tables_2_to_4=%d\n", as.integer(n_obs_lab)))
cat(sprintf("RESULT:n_subjects_lab_tables_2_to_4=%d\n", as.integer(n_subj_lab)))
out("memory_intervention_online_t3_col6", safe_coef(m_on6, "intervention"))
