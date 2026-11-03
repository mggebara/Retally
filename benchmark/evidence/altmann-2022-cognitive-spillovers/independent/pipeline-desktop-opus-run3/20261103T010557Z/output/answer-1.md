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
cat("Columns:", paste(nm, collapse = ", "), "\n")

# ---------------- subject id ----------------
rnd <- if ("round" %in% nm) num(d$round) else NULL
valid_id <- function(x) {
  if (is.null(rnd)) return(FALSE)
  if (any(is.na(x))) return(FALSE)
  nu <- length(unique(x))
  if (nu < nrow(d) / 40 || nu > nrow(d) / 5) return(FALSE)
  !any(duplicated(data.frame(a = as.character(x), b = rnd)))
}
id <- NULL
id_pat <- "^(subject_?id|participant_?id|id|id_?subject|id_?participant|subject|participant|participant_?code|code|subj_?id|player_?id|uid|pid|subjectid|id_subj|subj|vp|vpn)$"
for (c in grep(id_pat, nm, ignore.case = TRUE, value = TRUE)) {
  if (valid_id(d[[c]])) { id <- as.character(d[[c]]); cat("ID column:", c, "\n"); break }
}
if (is.null(id)) {
  for (c in grep("id|subj|partic|code", nm, ignore.case = TRUE, value = TRUE)) {
    if (valid_id(d[[c]])) { id <- as.character(d[[c]]); cat("ID column (loose):", c, "\n"); break }
  }
}
if (is.null(id)) {
  sess <- grep("session", nm, ignore.case = TRUE, value = TRUE)
  ins <- grep("id_in_session|in_session", nm, ignore.case = TRUE, value = TRUE)
  if (length(sess) > 0 && length(ins) > 0) {
    cand <- paste(as.character(d[[sess[1]]]), as.character(d[[ins[1]]]), sep = "_")
    if (valid_id(cand)) { id <- cand; cat("ID from session x id_in_session\n") }
  }
}
if (is.null(id)) {
  for (c in nm) {
    if (c == "round") next
    x <- d[[c]]
    if (valid_id(x) && length(unique(x)) == nrow(d) / length(unique(rnd))) {
      id <- as.character(x); cat("ID column (inferred):", c, "\n"); break
    }
  }
}
if (is.null(id)) {
  cat("ID constructed from round blocks\n")
  r0 <- min(rnd, na.rm = TRUE)
  id <- as.character(cumsum(rnd == r0))
}
d$.id <- id
cat("Subjects in lab data:", length(unique(d$.id)), "\n")

# ---------------- scarce sample ----------------
target_subj <- 608
subj_first <- !duplicated(d$.id)
subj_const <- function(x) {
  xc <- as.character(x)
  all(tapply(xc, d$.id, function(v) length(unique(v))) == 1)
}
scarce_idx <- NULL
ti_raw <- if ("Treatment_intervention" %in% nm) num(d$Treatment_intervention) else NULL
if (!is.null(ti_raw) && any(is.na(ti_raw))) {
  nsub <- length(unique(d$.id[!is.na(ti_raw)]))
  if (nsub == target_subj) { scarce_idx <- !is.na(ti_raw); cat("Scarce sample = non-missing Treatment_intervention\n") }
}
search_cols <- function(cols) {
  best <- NULL
  for (c in cols) {
    x <- d[[c]]
    xs <- labc(x)
    if (length(unique(xs[subj_first])) < 2 || length(unique(xs[subj_first])) > 4) next
    if (!subj_const(xs)) next
    tb <- table(xs[subj_first], useNA = "no")
    hit <- names(tb)[tb == target_subj]
    if (length(hit) > 0) {
      cat("Scarce indicator:", c, "level", hit[1], "\n")
      return(!is.na(xs) & xs == hit[1])
    }
  }
  NULL
}
excl <- c(".id", "round", "Treatment_Environment", "Treatment_intervention", "load_correct",
          "load_correct_mean", "ability_load", "raven_score_median", "raven_score_quartiles",
          "economist", "q_gender")
if (is.null(scarce_idx)) {
  pat_cols <- setdiff(grep("load|scarc|ample|digit|cogn|resourc|high|low|condition|treat", nm,
                           ignore.case = TRUE, value = TRUE), excl)
  scarce_idx <- search_cols(pat_cols)
}
if (is.null(scarce_idx)) {
  other <- setdiff(nm, c(excl, grep("^q_|raven|ability|_mean$|payoff|correct|attention", nm,
                                    ignore.case = TRUE, value = TRUE)))
  scarce_idx <- search_cols(other)
}
if (is.null(scarce_idx)) {
  pat_cols <- setdiff(grep("load|scarc|ample", nm, ignore.case = TRUE, value = TRUE), excl)
  for (c in pat_cols) {
    xs <- labc(d[[c]])
    if (!subj_const(xs)) next
    lv <- unique(xs[subj_first])
    if (length(lv) != 2) next
    tb <- table(xs[subj_first])
    hl <- grep("scarc|high|7|seven", names(tb), ignore.case = TRUE, value = TRUE)
    pick <- if (length(hl) > 0) hl[1] else names(tb)[which.min(abs(tb - target_subj))]
    cat("Scarce indicator (approx):", c, "level", pick, "\n")
    scarce_idx <- !is.na(xs) & xs == pick
    break
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
if (is.null(ti_raw)) {
  ti <- NULL
} else {
  ti <- num(s$Treatment_intervention)
}

# outcome: passive choice / default adherence
passive_var <- NULL
pc <- c("passive_choice", "passive", "default_choice", "choice_default", "chose_default",
        "default_chosen", "default_adherence", "default_outcome", "outcome_default", "passivity")
for (c in pc) if (c %in% nm) { passive_var <- c; break }
if (is.null(passive_var)) {
  g <- grep("passiv", nm, ignore.case = TRUE, value = TRUE)
  g <- g[!grepl("_mean$", g)]
  if (length(g) > 0) passive_var <- g[1]
}
if (is.null(passive_var)) {
  g <- grep("default", nm, ignore.case = TRUE, value = TRUE)
  g <- g[!grepl("correct|_mean$", g, ignore.case = TRUE)]
  for (c in g) { v <- num(d[[c]]); if (all(v[!is.na(v)] %in% c(0, 1))) { passive_var <- c; break } }
}
if (!is.null(passive_var)) {
  s$passive <- num(s[[passive_var]])
  cat("Passive-choice variable:", passive_var, "\n")
} else {
  chc <- grep("^choice$|^decision$|chosen", nm, ignore.case = TRUE, value = TRUE)
  dfc <- grep("^default$|default_option|default_position", nm, ignore.case = TRUE, value = TRUE)
  if (length(chc) > 0 && length(dfc) > 0) {
    s$passive <- as.numeric(as.character(s[[chc[1]]]) == as.character(s[[dfc[1]]]))
    cat("Passive constructed from", chc[1], "and", dfc[1], "\n")
  } else {
    s$passive <- NA_real_
    cat("WARNING: no passive-choice variable found\n")
  }
}

lv <- unique(env)
base_lv <- lv[grepl("baseline|endog", lv)]
dir_lv  <- lv[grepl("direct|forced.?att", lv)]
fc_lv   <- lv[grepl("active|forced.?ch|no.?default|choice", lv) & !grepl("direct|forced.?att|baseline|endog", lv)]
if (!is.null(ti)) {
  m0 <- tapply(ti, env, mean, na.rm = TRUE)
  if (length(base_lv) != 1) base_lv <- names(m0)[which.min(m0)]
}
if (length(base_lv) != 1) base_lv <- sort(lv)[1]
rest <- setdiff(lv, base_lv)
if (length(dir_lv) != 1 || length(fc_lv) != 1 || dir_lv == fc_lv) {
  if (length(rest) == 2) {
    mp <- tapply(s$passive, env, mean, na.rm = TRUE)[rest]
    if (all(is.finite(mp))) {
      fc_lv <- names(mp)[which.min(mp)]; dir_lv <- names(mp)[which.max(mp)]
    } else {
      if (length(dir_lv) == 1 && dir_lv %in% rest) fc_lv <- setdiff(rest, dir_lv)
      else if (length(fc_lv) == 1 && fc_lv %in% rest) dir_lv <- setdiff(rest, fc_lv)
      else { dir_lv <- rest[1]; fc_lv <- rest[2] }
    }
  }
}
cat("Baseline:", base_lv, "| Directed:", dir_lv, "| Forced choice:", fc_lv, "\n")
s$directed <- as.numeric(env == dir_lv)
s$forced <- as.numeric(env == fc_lv)
if (is.null(ti) || all(is.na(ti))) {
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
wave_c <- grep("wave", nm, ignore.case = TRUE, value = TRUE)
k <- 0
for (c in wave_c) { k <- k + 1; add_fac(c, paste0("c_wave", k), maxlev = 10) }
cat("Controls:", paste(ctrl_terms, collapse = " + "), "\n")
cat("  from:", paste(c(age_c, gen_c, fld_c, gpa_c, math_c, mt_c, inc_cols, wave_c), collapse = ", "), "\n")
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
  cat("\nOnline data:", nrow(o), "rows; cols:", paste(names(o), collapse = ", "), "\n")
  o$mem <- num(o$memory)
  cat("memory summary:\n"); print(summary(o$mem))
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
  if (!is.null(o5)) print(summary(o5)$coeftable)
  if (!is.null(o6)) print(summary(o6)$coeftable["intervention", , drop = FALSE])
  emit("memory_intervention_online_t3_col5", getc(o5, "intervention"))
  emit("memory_intervention_online_t3_col6", getc(o6, "intervention"))
}

cat("\n")
for (n in names(results)) cat(sprintf("RESULT:%s=%.6f\n", n, results[[n]]))
