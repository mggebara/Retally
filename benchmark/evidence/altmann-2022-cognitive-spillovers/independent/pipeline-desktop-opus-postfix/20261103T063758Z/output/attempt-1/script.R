suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/altmann_2022_cognitive_spillovers.script-free"
lab_path <- file.path(base, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_replication.dta")
mt_path  <- file.path(base, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_long_mturk.dta")

raw <- haven::read_dta(lab_path)
df <- as.data.frame(raw)
nm <- names(df)

# keep a label-aware copy of factor-like variables, then numeric versions
lab_text <- function(x) {
  if (inherits(x, "haven_labelled")) as.character(haven::as_factor(x, levels = "labels")) else as.character(x)
}
to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  if (is.character(x)) suppressWarnings(as.numeric(x)) else as.numeric(x)
}

N_TARGET <- 12160
N_SUBJ_TARGET <- 608
ROUNDS <- 20

find_col <- function(patterns, exclude = character(0), data_names = nm) {
  for (p in patterns) {
    hits <- grep(p, data_names, value = TRUE, ignore.case = TRUE)
    if (length(exclude)) hits <- hits[!grepl(paste(exclude, collapse = "|"), hits, ignore.case = TRUE)]
    if (length(hits)) return(hits[1])
  }
  NA_character_
}

# ---------------- subject identifier ----------------
id_candidates <- grep("subject|participant|^id|_id$|^id_|code|player", nm, value = TRUE, ignore.case = TRUE)
id_candidates <- id_candidates[!grepl("q_subject|subject_level|mean", id_candidates, ignore.case = TRUE)]
id_col <- NA_character_
for (cc in id_candidates) {
  nu <- length(unique(df[[cc]]))
  if (abs(nu * ROUNDS - nrow(df)) <= ROUNDS) { id_col <- cc; break }
}
if (is.na(id_col)) {
  for (cc in nm) {
    nu <- length(unique(df[[cc]]))
    if (nu * ROUNDS == nrow(df)) {
      # check each value appears exactly once per round
      tab <- table(df[[cc]])
      if (all(tab == ROUNDS)) { id_col <- cc; break }
    }
  }
}
if (is.na(id_col)) {
  cat("DEVIATION: no subject id column found; constructing id from row blocks of 20 rounds\n")
  df$subj_id_constructed <- rep(seq_len(ceiling(nrow(df) / ROUNDS)), each = ROUNDS)[seq_len(nrow(df))]
  id_col <- "subj_id_constructed"
}
df$sid <- as.character(df[[id_col]])

# ---------------- variables ----------------
df$round_n <- to_num(df[["round"]])
df$treat_int <- to_num(df[["Treatment_intervention"]])
env_txt <- lab_text(df[["Treatment_Environment"]])
df$env_txt <- env_txt

# ---------------- scarce cognitive resources restriction ----------------
load_col <- NA_character_
load_val <- NA
load_pref <- grep("load|scarce|ample|cognitive|digit", nm, value = TRUE, ignore.case = TRUE)
load_pref <- load_pref[!grepl("correct|ability|mean", load_pref, ignore.case = TRUE)]
cands <- unique(c(load_pref, grep("^Treatment", nm, value = TRUE)))
pick_load <- function(cols) {
  for (cc in cols) {
    v <- df[[cc]]
    u <- unique(v[!is.na(v)])
    if (length(u) < 2 || length(u) > 4) next
    for (val in u) {
      n <- sum(!is.na(v) & v == val)
      if (n == N_TARGET) return(list(col = cc, val = val))
    }
  }
  NULL
}
res <- pick_load(cands)
if (is.null(res)) res <- pick_load(nm)
if (!is.null(res)) {
  load_col <- res$col; load_val <- res$val
}

cat(sprintf("SAMPLE:lab:loaded=%d\n", nrow(df)))
lab <- df
if (!is.na(load_col)) {
  lab <- lab[!is.na(lab[[load_col]]) & lab[[load_col]] == load_val, ]
  cat(sprintf("SAMPLE:lab:scarce_cognitive_resources=%d\n", nrow(lab)))
} else {
  cat("DEVIATION: could not identify the scarce/ample load indicator; data assumed to contain scarce subjects only\n")
  cat(sprintf("SAMPLE:lab:scarce_cognitive_resources=%d\n", nrow(lab)))
}
lab <- lab[!is.na(lab$treat_int), ]
cat(sprintf("SAMPLE:lab:three_decision_environments=%d\n", nrow(lab)))
if (nrow(lab) > N_TARGET && any(!is.na(lab$round_n))) {
  # main part has 20 rounds
  rr <- sort(unique(lab$round_n))
  if (length(rr) > ROUNDS) {
    lab <- lab[lab$round_n %in% tail(rr, ROUNDS), ]
  }
}
cat(sprintf("SAMPLE:lab:main_part_rounds=%d\n", nrow(lab)))

# environment indicators
lab$intervention <- lab$treat_int
is_forced <- grepl("forced choice|active|choice", tolower(lab$env_txt)) & !grepl("attention", tolower(lab$env_txt))
lab$forced_choice <- as.integer(lab$intervention == 1 & is_forced)
lab$directed_attention <- as.integer(lab$intervention == 1 & !is_forced)
if (sum(lab$forced_choice) == 0 || sum(lab$directed_attention) == 0) {
  # fallback: numeric coding of environment among intervention subjects
  envn <- to_num(lab[["Treatment_Environment"]])
  ints <- sort(unique(envn[lab$intervention == 1]))
  if (length(ints) == 2) {
    cat("DEVIATION: environment labels not recognised; assuming lower intervention code = Directed Attention\n")
    lab$directed_attention <- as.integer(lab$intervention == 1 & envn == ints[1])
    lab$forced_choice <- as.integer(lab$intervention == 1 & envn == ints[2])
  }
}

# outcomes
lab$choice_correct <- to_num(lab[["summation_correct"]])
lab$bg_correct <- to_num(lab[["load_correct"]])
lab$pshare <- to_num(lab[["payoff_share"]])
def_col <- find_col(c("^passive_choice$", "passive", "default_choice", "chose_default", "choice_default",
                      "stick", "default_adher", "^default$"),
                    exclude = c("default_correct_choice", "mean"))
if (is.na(def_col)) def_col <- find_col(c("default"), exclude = c("default_correct", "mean"))
lab$default_adh <- if (!is.na(def_col)) to_num(lab[[def_col]]) else NA_real_
if (is.na(def_col)) cat("DEVIATION: default adherence variable not found\n")

# controls
age_col  <- find_col(c("^q_age$", "^age$", "age"), exclude = c("page", "stage", "mean", "average", "percent", "language"))
gen_col  <- find_col(c("^q_gender$", "gender", "female", "male"))
subj_col <- find_col(c("^q_subject$"))
gpa_col  <- find_col(c("^q_abitur_grade$", "abitur"))
math_col <- find_col(c("^q_math_grade$"))
multi_col <- find_col(c("multi"))
wave_col <- find_col(c("wave", "^experiment$", "session_wave"))
inc_cols <- grep("^Treatment_Incentive", names(lab), value = TRUE)

ctrl_terms <- character(0)
add_num <- function(col, newname) {
  if (!is.na(col)) { lab[[newname]] <<- to_num(lab[[col]]); ctrl_terms <<- c(ctrl_terms, newname) }
}
add_fac <- function(col, newname) {
  if (!is.na(col)) {
    lab[[newname]] <<- factor(lab_text(lab[[col]]))
    ctrl_terms <<- c(ctrl_terms, newname)
  }
}
add_num(age_col, "c_age")
add_fac(gen_col, "c_gender")
add_fac(subj_col, "c_field")
add_num(gpa_col, "c_gpa")
add_num(math_col, "c_math")
lab$c_abil_load <- to_num(lab[["ability_load"]]); ctrl_terms <- c(ctrl_terms, "c_abil_load")
lab$c_abil_task <- to_num(lab[["ability_task"]]); ctrl_terms <- c(ctrl_terms, "c_abil_task")
add_num(multi_col, "c_multi")
if (length(inc_cols)) {
  if (length(inc_cols) == 1) {
    add_fac(inc_cols[1], "c_incent")
  } else {
    for (i in seq_along(inc_cols)) {
      v <- to_num(lab[[inc_cols[i]]])
      if (length(unique(v[!is.na(v)])) > 1) {
        lab[[paste0("c_inc", i)]] <- v
        ctrl_terms <- c(ctrl_terms, paste0("c_inc", i))
      }
    }
  }
} else cat("DEVIATION: payoff scheme indicators not found\n")
if (!is.na(wave_col)) add_fac(wave_col, "c_wave") else cat("DEVIATION: experiment wave indicator not found\n")
for (cc in c("age","gender","field","gpa","math","multi")) {}
if (is.na(multi_col)) cat("DEVIATION: perceived multitasking ability variable not found\n")
if (is.na(age_col)) cat("DEVIATION: age variable not found\n")

# drop constant controls
ctrl_terms <- ctrl_terms[sapply(ctrl_terms, function(v) length(unique(na.omit(lab[[v]]))) > 1)]
ctrl_str <- paste(ctrl_terms, collapse = " + ")

nsubj <- length(unique(lab$sid))
cat(sprintf("SAMPLE:lab:subjects=%d\n", nsubj))
if (nrow(lab) != N_TARGET) cat(sprintf("DEVIATION: lab sample has %d rows vs %d stated\n", nrow(lab), N_TARGET))

run <- function(fml) feols(as.formula(fml), data = lab, cluster = ~sid)

m1 <- run("choice_correct ~ intervention")
m2 <- run(paste("choice_correct ~ intervention +", ctrl_str))
m5 <- run("default_adh ~ intervention")
m6 <- run(paste("default_adh ~ intervention +", ctrl_str))
m7 <- run("default_adh ~ directed_attention + forced_choice")
b1 <- run("bg_correct ~ intervention")
b2 <- run(paste("bg_correct ~ intervention +", ctrl_str))
p1 <- run("pshare ~ intervention")

cat(sprintf("SAMPLE:t2_choice_col1:estimation=%d\n", nobs(m1)))
cat(sprintf("SAMPLE:t2_choice_col2:estimation=%d\n", nobs(m2)))
cat(sprintf("SAMPLE:t2_default_col5:estimation=%d\n", nobs(m5)))
cat(sprintf("SAMPLE:t2_default_col6:estimation=%d\n", nobs(m6)))
cat(sprintf("SAMPLE:t2_default_col7:estimation=%d\n", nobs(m7)))
cat(sprintf("SAMPLE:t3_lab_col1:estimation=%d\n", nobs(b1)))
cat(sprintf("SAMPLE:t3_lab_col2:estimation=%d\n", nobs(b2)))
cat(sprintf("SAMPLE:t4_col1:estimation=%d\n", nobs(p1)))

# ---------------- online experiment ----------------
mt <- as.data.frame(haven::read_dta(mt_path))
cat(sprintf("SAMPLE:online:loaded=%d\n", nrow(mt)))
mt$mem <- to_num(mt$memory)
mt$treat <- to_num(mt$Treatment_intervention)
mt$sid <- as.character(mt$subject_id)
mt$c_age <- to_num(mt$age)
mt$c_gender <- factor(lab_text(mt$gender))
mt$c_h <- to_num(mt$window_height1)
mt$c_w <- to_num(mt$window_width1)
mx <- max(mt$mem, na.rm = TRUE)
if (mx > 1) {
  cat(sprintf("DEVIATION: memory points exceed 1 (max %g); scaled by the maximum to obtain the fraction of pairs uncovered\n", mx))
  mt$mem_frac <- mt$mem / mx
} else mt$mem_frac <- mt$mem
o5 <- feols(mem_frac ~ treat, data = mt, cluster = ~sid)
o6 <- feols(mem_frac ~ treat + c_age + c_gender + c_h + c_w, data = mt, cluster = ~sid)
cat(sprintf("SAMPLE:online_col5:estimation=%d\n", nobs(o5)))
cat(sprintf("SAMPLE:online_col6:estimation=%d\n", nobs(o6)))

se <- function(m, v) sqrt(diag(vcov(m)))[v]
out <- function(name, m, v) {
  cat(sprintf("RESULT:%s=%.6f\n", name, coef(m)[v]))
  cat(sprintf("RESULT:%s_se=%.6f\n", name, se(m, v)))
}
out("choice_quality_intervention_t2_col1", m1, "intervention")
out("choice_quality_intervention_t2_col2", m2, "intervention")
out("default_adherence_intervention_t2_col5", m5, "intervention")
out("default_adherence_intervention_t2_col6", m6, "intervention")
out("default_adherence_directed_attention_t2_col7", m7, "directed_attention")
out("default_adherence_forced_choice_t2_col7", m7, "forced_choice")
out("background_quality_intervention_lab_t3_col1", b1, "intervention")
out("background_quality_intervention_lab_t3_col2", b2, "intervention")
out("memory_intervention_online_t3_col5", o5, "treat")
out("memory_intervention_online_t3_col6", o6, "treat")
out("payoff_share_intervention_t4_col1", p1, "intervention")
cat(sprintf("RESULT:n_obs_lab_tables_2_to_4=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_subjects_lab_tables_2_to_4=%d\n", length(unique(lab$sid[!is.na(lab$choice_correct)]))))