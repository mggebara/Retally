suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/altmann_2022_cognitive_spillovers.script-free"
lab_path <- file.path(base, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_replication.dta")
mt_path  <- file.path(base, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_long_mturk.dta")

lab <- haven::read_dta(lab_path)
mt  <- haven::read_dta(mt_path)

cat("Lab columns:\n"); print(names(lab))
cat("MTurk columns:\n"); print(names(mt))

num <- function(x) as.numeric(haven::zap_labels(x))
lab_chr <- function(x) {
  if (haven::is.labelled(x)) as.character(haven::as_factor(x)) else as.character(x)
}
to01 <- function(x) {
  v <- num(x)
  u <- sort(unique(v[!is.na(v)]))
  if (length(u) == 2 && !all(u %in% c(0, 1))) v <- as.numeric(v == max(u))
  v
}

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) {
    cat(sprintf("RESULT:%s=NA\n", name))
  } else {
    cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
  }
}

nm <- names(lab)
find_col <- function(patterns, cols = nm, exclude = character(0)) {
  for (p in patterns) {
    hit <- cols[grepl(p, cols, ignore.case = TRUE)]
    hit <- setdiff(hit, exclude)
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}

# ---------------- Lab sample: original lab experiment (608 subjects x 20 rounds) ----------------
lab$intervention <- to01(lab$Treatment_intervention)
cat("Treatment_intervention table:\n"); print(table(lab$Treatment_intervention, useNA = "ifany"))
cat("Treatment_Environment table:\n"); print(table(lab_chr(lab$Treatment_Environment), useNA = "ifany"))
if ("original_lab" %in% nm) {
  cat("original_lab table:\n"); print(table(lab_chr(lab$original_lab), useNA = "ifany"))
}
if ("Treatment_Incentives" %in% nm) {
  cat("Treatment_Incentives table:\n"); print(table(lab_chr(lab$Treatment_Incentives), useNA = "ifany"))
}

target_n <- 12160
cands <- list()
cands[["all_nonNA_intervention"]] <- !is.na(lab$intervention)
# The data file pools the original lab experiment with a later (incentive) replication;
# the paper's Tables 2-4 use the original lab sample only.
samp_cols <- nm[grepl("^original_lab$|Treatment_Incentives", nm, ignore.case = TRUE)]
for (lc in samp_cols) {
  v <- lab[[lc]]
  vals <- unique(lab_chr(v)); vals <- vals[!is.na(vals)]
  if (length(vals) >= 2 && length(vals) <= 6) {
    for (vv in vals) {
      cands[[paste0(lc, "==", vv)]] <- (lab_chr(v) == vv) & !is.na(lab$intervention) & !is.na(v)
    }
  }
}
load_cols <- nm[grepl("load|scarce|cognitive|resource|ample|digit", nm, ignore.case = TRUE)]
load_cols <- setdiff(load_cols, c("load_correct", "ability_load", "load_correct_mean"))
for (lc in load_cols) {
  v <- lab[[lc]]
  vals <- unique(lab_chr(v)); vals <- vals[!is.na(vals)]
  if (length(vals) >= 2 && length(vals) <= 6) {
    for (vv in vals) {
      cands[[paste0(lc, "==", vv)]] <- (lab_chr(v) == vv) & !is.na(lab$intervention) & !is.na(v)
    }
  }
}
sizes <- sapply(cands, function(s) sum(s, na.rm = TRUE))
cat("Candidate sample sizes:\n"); print(sizes)
exact <- which(sizes == target_n)
if (length(exact) > 0) {
  lbls <- names(sizes)[exact]
  pref <- grep("^original_lab", lbls)
  if (length(pref) == 0) pref <- grep("Incentives", lbls)
  pick <- if (length(pref) > 0) lbls[pref[1]] else lbls[1]
} else {
  pick <- names(sizes)[which.min(abs(sizes - target_n))]
}
cat("Chosen sample restriction:", pick, "\n")
d <- lab[which(cands[[pick]]), ]
if (length(exact) == 0) {
  cat("DEVIATION: could not identify a sample of exactly 12160 subject-rounds; used closest candidate.\n")
}

env <- tolower(lab_chr(d$Treatment_Environment))
d$directed <- as.numeric(grepl("direct", env))
d$forced   <- as.numeric(grepl("forc|active", env))
d$cl <- num(d$subject_id)

# outcomes
d$y_dec <- num(d$summation_correct)
d$y_bg  <- num(d$load_correct)
d$y_pay <- num(d$payoff_share)

def_col <- find_col(c("^passive_choice$", "^default_choice$", "^default_adherence$", "^choice_default$",
                      "^chose_default$", "^default_followed$", "passive", "default_adh", "chose_default",
                      "choice_default", "default_choice"),
                    exclude = c("default_correct_choice"))
if (is.na(def_col)) {
  hits <- nm[grepl("default", nm, ignore.case = TRUE)]
  hits <- setdiff(hits, "default_correct_choice")
  def_col <- if (length(hits) > 0) hits[1] else NA_character_
}
cat("Default adherence column:", def_col, "\n")
d$y_def <- if (!is.na(def_col)) num(d[[def_col]]) else NA_real_
if (!is.na(def_col) && max(d$y_def, na.rm = TRUE) > 1) d$y_def <- d$y_def / 100

# ---------------- Controls ----------------
ctrl_terms <- character(0)
add_num <- function(col, name) {
  if (!is.na(col)) { d[[name]] <<- num(d[[col]]); ctrl_terms <<- c(ctrl_terms, name) }
}
add_fac <- function(col, name) {
  if (!is.na(col)) { d[[name]] <<- factor(lab_chr(d[[col]])); ctrl_terms <<- c(ctrl_terms, name) }
}
age_col    <- find_col(c("^q_age$", "^age$", "age"), exclude = c("q_math_grade", "q_math_grade_cat", "page"))
gender_col <- find_col(c("^q_gender$", "gender"))
subj_col   <- find_col(c("^q_subject$", "field", "study"))
abitur_col <- find_col(c("^q_abitur_grade$", "abitur", "gpa"))
math_col   <- find_col(c("^q_math_grade$"))
multi_col  <- find_col(c("multitask", "multi"))
abl_load   <- find_col(c("^ability_load$"))
abl_task   <- find_col(c("^ability_task$"))
inc_cols   <- nm[grepl("incentive|payoff_scheme|scheme", nm, ignore.case = TRUE)]
wave_col   <- find_col(c("wave", "experiment_part", "^experiment$", "replication", "second_exp"))
cat("Controls found: age=", age_col, " gender=", gender_col, " subject=", subj_col,
    " abitur=", abitur_col, " math=", math_col, " multi=", multi_col,
    " incentives=", paste(inc_cols, collapse = ","), " wave=", wave_col, "\n")

add_num(age_col, "c_age")
add_fac(gender_col, "c_gender")
add_fac(subj_col, "c_subject")
add_num(abitur_col, "c_abitur")
add_num(math_col, "c_math")
add_num(abl_load, "c_abl_load")
add_num(abl_task, "c_abl_task")
add_num(multi_col, "c_multi")
if (length(inc_cols) > 0) {
  inc_key <- apply(sapply(inc_cols, function(cc) lab_chr(d[[cc]])), 1, paste, collapse = "_")
  d$c_incent <- factor(inc_key)
  if (nlevels(d$c_incent) > 1) ctrl_terms <- c(ctrl_terms, "c_incent")
}
add_fac(wave_col, "c_wave")
# drop constant controls
ctrl_terms <- ctrl_terms[sapply(ctrl_terms, function(v) length(unique(d[[v]][!is.na(d[[v]])])) > 1)]
cat("Control terms used:", paste(ctrl_terms, collapse = ", "), "\n")
ctrl_str <- if (length(ctrl_terms) > 0) paste("+", paste(ctrl_terms, collapse = " + ")) else ""

run <- function(y, rhs, data = d, var = "intervention") {
  f <- as.formula(paste(y, "~", rhs))
  m <- tryCatch(feols(f, data = data, cluster = ~cl), error = function(e) { print(e); NULL })
  if (is.null(m)) return(list(b = NA, se = NA, n = NA, m = NULL))
  list(b = coef(m)[var], se = sqrt(diag(vcov(m)))[var], n = nobs(m), m = m)
}

t2c1 <- run("y_dec", "intervention")
t2c2 <- run("y_dec", paste("intervention", ctrl_str))
t2c5 <- run("y_def", "intervention")
t2c6 <- run("y_def", paste("intervention", ctrl_str))
t2c7d <- run("y_def", "directed + forced", var = "directed")
t2c7f <- run("y_def", "directed + forced", var = "forced")
t3c1 <- run("y_bg", "intervention")
t3c2 <- run("y_bg", paste("intervention", ctrl_str))
t4c1 <- run("y_pay", "intervention")

if (!is.null(t2c1$m)) print(summary(t2c1$m))
if (!is.null(t2c2$m)) cat("N with controls:", t2c2$n, "\n")

# ---------------- Online experiment ----------------
mt$intervention <- to01(mt$Treatment_intervention)
mt$cl <- num(mt$subject_id)
mt$y_mem <- num(mt$memory)
if (max(mt$y_mem, na.rm = TRUE) > 1.0001) {
  cat("Note: memory variable exceeds 1; values summarised:\n"); print(summary(mt$y_mem))
}
mt$c_age <- num(mt$age)
mt$c_gender <- factor(lab_chr(mt$gender))
mt$c_wh <- num(mt$window_height1)
mt$c_ww <- num(mt$window_width1)
o5 <- tryCatch(feols(y_mem ~ intervention, data = mt, cluster = ~cl), error = function(e) NULL)
o6 <- tryCatch(feols(y_mem ~ intervention + c_age + c_gender + c_wh + c_ww, data = mt, cluster = ~cl),
               error = function(e) NULL)

# ---------------- Output ----------------
emit("choice_quality_intervention_t2_col1", t2c1$b)
emit("choice_quality_intervention_t2_col1_se", t2c1$se)
emit("choice_quality_intervention_t2_col2", t2c2$b)
emit("choice_quality_intervention_t2_col2_se", t2c2$se)
emit("default_adherence_intervention_t2_col5", t2c5$b)
emit("default_adherence_intervention_t2_col5_se", t2c5$se)
emit("default_adherence_intervention_t2_col6", t2c6$b)
emit("default_adherence_intervention_t2_col6_se", t2c6$se)
emit("default_adherence_directed_attention_t2_col7", t2c7d$b)
emit("default_adherence_directed_attention_t2_col7_se", t2c7d$se)
emit("default_adherence_forced_choice_t2_col7", t2c7f$b)
emit("default_adherence_forced_choice_t2_col7_se", t2c7f$se)
emit("background_quality_intervention_lab_t3_col1", t3c1$b)
emit("background_quality_intervention_lab_t3_col1_se", t3c1$se)
emit("background_quality_intervention_lab_t3_col2", t3c2$b)
emit("background_quality_intervention_lab_t3_col2_se", t3c2$se)
emit("memory_intervention_online_t3_col5", if (!is.null(o5)) coef(o5)["intervention"] else NA)
emit("memory_intervention_online_t3_col5_se", if (!is.null(o5)) sqrt(diag(vcov(o5)))["intervention"] else NA)
emit("memory_intervention_online_t3_col6", if (!is.null(o6)) coef(o6)["intervention"] else NA)
emit("memory_intervention_online_t3_col6_se", if (!is.null(o6)) sqrt(diag(vcov(o6)))["intervention"] else NA)
emit("payoff_share_intervention_t4_col1", t4c1$b)
emit("payoff_share_intervention_t4_col1_se", t4c1$se)
emit("n_obs_lab_tables_2_to_4", if (!is.na(t2c1$n)) t2c1$n else nrow(d))
emit("n_subjects_lab_tables_2_to_4", length(unique(d$cl[!is.na(d$y_dec)])))