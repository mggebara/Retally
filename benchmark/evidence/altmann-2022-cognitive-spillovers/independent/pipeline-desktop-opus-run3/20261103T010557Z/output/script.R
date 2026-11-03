suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

root <- "<repo>/.cache/datasets/altmann_2022_cognitive_spillovers.script-free"
lab_path <- file.path(root, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_replication.dta")
mt_path  <- file.path(root, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_long_mturk.dta")

num <- function(x) suppressWarnings(as.numeric(haven::zap_labels(x)))
labc <- function(x) {
  if (haven::is.labelled(x)) as.character(haven::as_factor(x, levels = "default")) else as.character(x)
}

results <- list()
emit <- function(name, value) {
  if (!is.null(value) && length(value) == 1 && is.finite(value)) results[[name]] <<- value
}

d <- haven::read_dta(lab_path)
d <- as.data.frame(d)
nm <- names(d)
cat("Lab data:", nrow(d), "rows,", ncol(d), "cols\n")

d$.id <- as.character(d$subject_id)
cat("Subjects in lab data:", length(unique(d$.id)), "\n")
rnd <- num(d$round)

# ---------------- scarce sample ----------------
# The paper's Tables 2-4 use the Scarce (high cognitive load, 7-digit) subjects:
# 608 subjects x 20 rounds = 12160 subject-rounds.
target_subj <- 608
subj_first <- !duplicated(d$.id)
nsubj <- function(idx) length(unique(d$.id[idx]))

scarce_idx <- NULL
if ("high_task_difficulty" %in% nm) {
  h <- num(d$high_task_difficulty)
  cat("high_task_difficulty table (rows):\n"); print(table(labc(d$high_task_difficulty), useNA = "ifany"))
  hm <- tapply(h, d$.id, mean, na.rm = TRUE)
  hs <- names(hm)[is.finite(hm) & hm > 0.5]
  cand <- d$.id %in% hs
  cat("Subjects with high_task_difficulty = 1:", nsubj(cand), "\n")
  if (abs(nsubj(cand) - target_subj) <= 20) {
    scarce_idx <- cand
    cat("Scarce sample = high_task_difficulty == 1\n")
  }
}

# Fallback: search subject-constant columns (single levels, level unions, pairwise intersections)
if (is.null(scarce_idx)) {
  const_cols <- c()
  for (c in setdiff(nm, c(".id", "round", "subject_id"))) {
    xs <- labc(d[[c]]); xs[is.na(xs)] <- "NA"
    nl <- length(unique(xs))
    if (nl < 2 || nl > 6) next
    if (all(tapply(xs, d$.id, function(v) length(unique(v))) == 1)) const_cols <- c(const_cols, c)
  }
  cat("Subject-constant candidate columns:", paste(const_cols, collapse = ", "), "\n")
  conds <- list()
  for (c in const_cols) {
    xs <- labc(d[[c]]); xs[is.na(xs)] <- "NA"
    lv <- sort(unique(xs))
    for (k in 1:(length(lv) - 1)) {
      for (cb in combn(lv, k, simplify = FALSE)) {
        conds[[length(conds) + 1]] <- list(desc = paste0(c, " in {", paste(cb, collapse = ","), "}"),
                                           idx = xs %in% cb)
      }
    }
  }
  hits <- Filter(function(z) nsubj(z$idx) == target_subj, conds)
  if (length(hits) == 0) {
    for (i in seq_along(conds)) for (j in seq_along(conds)) {
      if (j <= i) next
      ii <- conds[[i]]$idx & conds[[j]]$idx
      if (nsubj(ii) == target_subj) {
        hits[[length(hits) + 1]] <- list(desc = paste(conds[[i]]$desc, "&", conds[[j]]$desc), idx = ii)
      }
    }
  }
  if (length(hits) > 0) {
    cat("Candidate samples with", target_subj, "subjects:\n")
    for (hh in hits) cat("  ", hh$desc, "\n")
    pri <- sapply(hits, function(z) if (grepl("difficulty|load|scarc", z$desc, ignore.case = TRUE)) 0 else 1)
    pick <- hits[[order(pri)[1]]]
    scarce_idx <- pick$idx
    cat("DEVIATION: Scarce sample identified by subject count match:", pick$desc, "\n")
  }
}
if (is.null(scarce_idx)) {
  cat("WARNING: no scarce indicator found; using all rows\n")
  scarce_idx <- rep(TRUE, nrow(d))
}
s <- d[scarce_idx, , drop = FALSE]
cat("Scarce sample:", nrow(s), "rows,", length(unique(s$.id)), "subjects\n")

# ---------------- environment ----------------
env <- tolower(labc(s$Treatment_Environment))
cat("Environment levels:\n"); print(table(env, useNA = "ifany"))
ti <- num(s$Treatment_intervention)

s$passive <- num(s$default_followed)

lv <- unique(env)
base_lv <- lv[grepl("baseline", lv)]
dir_lv  <- lv[grepl("direct", lv)]
fc_lv   <- lv[grepl("forced|active", lv) & !grepl("direct|baseline", lv)]
cat("Baseline:", base_lv, "| Directed:", dir_lv, "| Forced choice:", fc_lv, "\n")
s$directed <- as.numeric(env == dir_lv)
s$forced <- as.numeric(env == fc_lv)
if (all(is.na(ti))) {
  s$intervention <- as.numeric(env != base_lv)
} else {
  s$intervention <- ti
}

s$dec_correct <- num(s$summation_correct)
s$bg_correct <- num(s$load_correct)
s$pshare <- if ("payoff_share" %in% nm) num(s$payoff_share) else NA_real_
if (all(s$pshare[!is.na(s$pshare)] <= 100) && max(s$pshare, na.rm = TRUE) > 1.5) s$pshare <- s$pshare / 100

# ---------------- controls ----------------
ctrl_terms <- character(0)
add_num <- function(src, newname) {
  v <- num(s[[src]])
  if (all(is.na(v)) || length(unique(v[!is.na(v)])) < 2) return(invisible(NULL))
  if (any(is.na(v))) {
    s[[paste0(newname, "_miss")]] <<- as.numeric(is.na(v))
    v[is.na(v)] <- mean(v, na.rm = TRUE)
    ctrl_terms <<- c(ctrl_terms, paste0(newname, "_miss"))
  }
  s[[newname]] <<- v
  ctrl_terms <<- c(ctrl_terms, newname)
}
add_fac <- function(src, newname, maxlev = 60) {
  v <- labc(s[[src]])
  v[is.na(v) | v == ""] <- "missing"
  if (length(unique(v)) < 2 || length(unique(v)) > maxlev) return(invisible(NULL))
  s[[newname]] <<- factor(v)
  ctrl_terms <<- c(ctrl_terms, newname)
}
first_match <- function(pats) {
  for (p in pats) { g <- grep(p, nm, ignore.case = TRUE, value = TRUE); if (length(g) > 0) return(g[1]) }
  NULL
}
age_c <- first_match(c("^q_age$", "^age$", "(^|_)age($|_)"))
if (!is.null(age_c)) add_num(age_c, "c_age")
gen_c <- first_match(c("^q_gender$", "gender", "female", "^male$|sex"))
if (!is.null(gen_c)) add_fac(gen_c, "c_gender")
fld_c <- first_match(c("^q_subject$", "field|study|major"))
if (!is.null(fld_c)) add_fac(fld_c, "c_field")
gpa_c <- first_match(c("^q_abitur_grade$", "abitur|gpa"))
if (!is.null(gpa_c)) add_num(gpa_c, "c_gpa")
math_c <- first_match(c("^q_math_grade$", "math_grade"))
if (!is.null(math_c)) add_num(math_c, "c_math")
if ("ability_load" %in% nm) add_num("ability_load", "c_abl")
if ("ability_task" %in% nm) add_num("ability_task", "c_abt")
mt_c <- first_match(c("multi"))
if (!is.null(mt_c)) add_num(mt_c, "c_multi")
inc_cols <- grep("incentiv|scheme|payoff_treat|piece", nm, ignore.case = TRUE, value = TRUE)
inc_cols <- setdiff(inc_cols, "payoff_share")
k <- 0
for (c in inc_cols) { k <- k + 1; add_fac(c, paste0("c_inc", k), maxlev = 10) }
cat("Controls:", paste(ctrl_terms, collapse = " + "), "\n")
ctrl_str <- if (length(ctrl_terms) > 0) paste(ctrl_terms, collapse = " + ") else "1"

fit <- function(fml) {
  tryCatch({
    m <- feols(as.formula(fml), data = s, cluster = ~.id, warn = FALSE, notes = FALSE)
    print(summary(m)$coeftable[intersect(c("intervention", "directed", "forced"), names(coef(m))), , drop = FALSE])
    m
  }, error = function(e) { cat("Error in", fml, ":", conditionMessage(e), "\n"); NULL })
}
getc <- function(m, v) if (is.null(m) || !(v %in% names(coef(m)))) NA_real_ else unname(coef(m)[v])

cat("\n--- Table 2 (a) col1 ---\n"); m1 <- fit("dec_correct ~ intervention")
cat("\n--- Table 2 (a) col2 ---\n"); m2 <- fit(paste("dec_correct ~ intervention +", ctrl_str))
cat("\n--- Table 2 (b) col5 ---\n"); m5 <- fit("passive ~ intervention")
cat("\n--- Table 2 (b) col6 ---\n"); m6 <- fit(paste("passive ~ intervention +", ctrl_str))
cat("\n--- Table 2 (b) col7 ---\n"); m7 <- fit("passive ~ directed + forced")
cat("\n--- Table 3 col1 ---\n"); t31 <- fit("bg_correct ~ intervention")
cat("\n--- Table 3 col2 ---\n"); t32 <- fit(paste("bg_correct ~ intervention +", ctrl_str))
cat("\n--- Table 4 col1 ---\n"); t41 <- fit("pshare ~ intervention")

emit("choice_quality_intervention_t2_col1", getc(m1, "intervention"))
emit("choice_quality_intervention_t2_col2", getc(m2, "intervention"))
emit("default_adherence_intervention_t2_col5", getc(m5, "intervention"))
emit("default_adherence_intervention_t2_col6", getc(m6, "intervention"))
emit("default_adherence_directed_attention_t2_col7", getc(m7, "directed"))
emit("default_adherence_forced_choice_t2_col7", getc(m7, "forced"))
emit("background_quality_intervention_lab_t3_col1", getc(t31, "intervention"))
emit("background_quality_intervention_lab_t3_col2", getc(t32, "intervention"))
emit("payoff_share_intervention_t4_col1", getc(t41, "intervention"))
if (!is.null(m1)) {
  emit("n_obs_lab_tables_2_to_4", nobs(m1))
  used <- obs(m1)
  emit("n_subjects_lab_tables_2_to_4", length(unique(s$.id[used])))
} else {
  emit("n_obs_lab_tables_2_to_4", nrow(s))
  emit("n_subjects_lab_tables_2_to_4", length(unique(s$.id)))
}

# ---------------- online experiment ----------------
o <- tryCatch(as.data.frame(haven::read_dta(mt_path)), error = function(e) NULL)
if (!is.null(o)) {
  o$mem <- num(o$memory)
  o$intervention <- num(o$Treatment_intervention)
  o$sid <- as.character(o$subject_id)
  o$age_c <- num(o$age)
  o$gender_c <- factor(labc(o$gender))
  o$wh <- num(o$window_height1)
  o$ww <- num(o$window_width1)
  for (v in c("age_c", "wh", "ww")) {
    if (any(is.na(o[[v]]))) {
      o[[paste0(v, "_miss")]] <- as.numeric(is.na(o[[v]]))
      o[[v]][is.na(o[[v]])] <- mean(o[[v]], na.rm = TRUE)
    }
  }
  oc <- c("age_c", "gender_c", "wh", "ww", grep("_miss$", names(o), value = TRUE))
  o5 <- tryCatch(feols(mem ~ intervention, data = o, cluster = ~sid, notes = FALSE),
                 error = function(e) { cat("online col5 error:", conditionMessage(e), "\n"); NULL })
  o6 <- tryCatch(feols(as.formula(paste("mem ~ intervention +", paste(oc, collapse = " + "))),
                       data = o, cluster = ~sid, notes = FALSE),
                 error = function(e) { cat("online col6 error:", conditionMessage(e), "\n"); NULL })
  emit("memory_intervention_online_t3_col5", getc(o5, "intervention"))
  emit("memory_intervention_online_t3_col6", getc(o6, "intervention"))
}

cat("\n")
for (n in names(results)) cat(sprintf("RESULT:%s=%.6f\n", n, results[[n]]))