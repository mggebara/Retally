suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/altmann_2022_cognitive_spillovers.script-free"
lab_path <- file.path(base, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_replication.dta")
mt_path  <- file.path(base, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_long_mturk.dta")

raw <- haven::read_dta(lab_path)
cat("Lab data:", nrow(raw), "rows,", ncol(raw), "cols\n")
cat("Columns:", paste(names(raw), collapse = ", "), "\n")

get_labels <- function(x) {
  l <- attr(x, "labels")
  if (is.null(l)) return(NULL)
  l
}
num <- function(x) as.numeric(haven::zap_labels(x))
describe <- function(nm, x) {
  u <- sort(unique(num(x)))
  cat(sprintf("  %s: %d unique; ", nm, length(u)))
  if (length(u) <= 12) cat("values:", paste(u, collapse = ","))
  l <- get_labels(x)
  if (!is.null(l)) cat(" | labels:", paste(paste0(l, "=", names(l)), collapse = "; "))
  cat("\n")
}
for (nm in names(raw)) {
  x <- raw[[nm]]
  if (is.numeric(x) || inherits(x, "haven_labelled")) describe(nm, x)
  else cat(sprintf("  %s: character, %d unique\n", nm, length(unique(x))))
}

nms <- names(raw)
pick <- function(patterns, exclude = NULL) {
  for (p in patterns) {
    hit <- grep(p, nms, value = TRUE, ignore.case = TRUE)
    if (!is.null(exclude)) hit <- hit[!grepl(exclude, hit, ignore.case = TRUE)]
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}

df <- raw

# ---------------- cluster id ----------------
sid <- num(df$subject_id)
cl <- sid
maxper <- max(table(sid))
if (maxper > 20) {
  sess <- pick(c("^session", "session"), exclude = "mean")
  wv <- pick(c("^wave$", "wave"))
  key <- as.character(sid)
  if (!is.na(sess)) key <- paste(key, as.character(df[[sess]]))
  if (!is.na(wv)) key <- paste(key, as.character(df[[wv]]))
  cl <- as.numeric(factor(key))
  cat("subject_id not unique; combined with session/wave. Max per id now:", max(table(cl)), "\n")
}
df$cl <- cl

# ---------------- scarce resources indicator ----------------
scarce_flag <- rep(TRUE, nrow(df))
cand <- grep("load|scarce|resource|cogn|ample", nms, value = TRUE, ignore.case = TRUE)
cand <- cand[!grepl("correct|ability|mean|time|entry", cand, ignore.case = TRUE)]
if (length(cand) > 0) {
  is_bin <- vapply(cand, function(v) { u <- unique(na.omit(num(df[[v]]))); length(u) == 2 }, logical(1))
  cand <- cand[is_bin]
}
cat("Scarce-indicator candidates:", paste(cand, collapse = ", "), "\n")
found_scarce <- FALSE
if (length(cand) > 0) {
  # prefer names with Treatment
  pref <- cand[grepl("treat", cand, ignore.case = TRUE)]
  v <- if (length(pref) > 0) pref[1] else cand[1]
  x <- df[[v]]
  if (is.character(x)) {
    u <- unique(na.omit(x))
    sv <- u[grepl("high|scarce|7|seven", u, ignore.case = TRUE)]
    if (length(sv) == 0) sv <- u[!grepl("low|ample|2|two", u, ignore.case = TRUE)]
    scarce_flag <- x %in% sv[1]
  } else {
    l <- get_labels(x)
    xv <- num(x)
    u <- sort(unique(na.omit(xv)))
    sval <- NA
    if (!is.null(l)) {
      hi <- l[grepl("high|scarce|7|seven|demand", names(l), ignore.case = TRUE)]
      lo <- l[grepl("low|ample|2|two|easy", names(l), ignore.case = TRUE)]
      if (length(hi) > 0) sval <- as.numeric(hi[1])
      else if (length(lo) > 0) sval <- setdiff(u, as.numeric(lo[1]))[1]
    }
    if (is.na(sval)) {
      if (grepl("low|ample", v, ignore.case = TRUE)) sval <- u[1] else sval <- u[2]
    }
    scarce_flag <- !is.na(xv) & xv == sval
  }
  found_scarce <- TRUE
  cat("Using", v, "as scarce indicator; scarce rows:", sum(scarce_flag), "\n")
}

# Fallback: Treatment_Incentives has an "Ample" level; scarce = all non-Ample levels
if (!found_scarce && "Treatment_Incentives" %in% nms) {
  ti_x <- df$Treatment_Incentives
  ti_l <- get_labels(ti_x)
  ti_v <- num(ti_x)
  if (!is.null(ti_l) && any(grepl("ample", names(ti_l), ignore.case = TRUE))) {
    amp <- as.numeric(ti_l[grepl("ample", names(ti_l), ignore.case = TRUE)])
    scarce_flag <- !is.na(ti_v) & !(ti_v %in% amp)
    found_scarce <- TRUE
    cat("Scarce identified as Treatment_Incentives != Ample; scarce rows:", sum(scarce_flag), "\n")
  }
}

# ---------------- environment ----------------
env_raw <- df$Treatment_Environment
int_raw <- df$Treatment_intervention
env_n <- if (is.character(env_raw)) as.numeric(factor(env_raw)) else num(env_raw)
env_lab <- NULL
if (is.character(env_raw)) {
  lv <- levels(factor(env_raw)); env_lab <- setNames(seq_along(lv), lv)
} else env_lab <- get_labels(env_raw)
# keep only labels for values present in data
if (!is.null(env_lab)) env_lab <- env_lab[as.numeric(env_lab) %in% unique(na.omit(env_n))]

# If environment labels encode load as well and no scarce var found
if (!found_scarce && !is.null(env_lab) && any(grepl("scarce", names(env_lab), ignore.case = TRUE))) {
  sv <- as.numeric(env_lab[grepl("scarce", names(env_lab), ignore.case = TRUE)])
  scarce_flag <- env_n %in% sv
  found_scarce <- TRUE
  cat("Scarce identified from environment labels\n")
}

env_cat <- rep(NA_character_, nrow(df))
if (!is.null(env_lab)) {
  for (i in seq_along(env_lab)) {
    nmx <- names(env_lab)[i]; val <- as.numeric(env_lab[i])
    cat_i <- if (grepl("active|forced ch|forced_ch|no default|choice", nmx, ignore.case = TRUE)) "FC"
      else if (grepl("base|endog", nmx, ignore.case = TRUE)) "B"
      else if (grepl("direct|forced|attention", nmx, ignore.case = TRUE)) "DA" else NA
    env_cat[env_n == val] <- cat_i
  }
}
if (any(is.na(env_cat[!is.na(env_n)]))) {
  # fall back: determine baseline via intervention, others by sorted order
  int_n <- num(int_raw)
  u <- sort(unique(na.omit(env_n)))
  env_cat <- rep(NA_character_, nrow(df))
  if (length(u) == 3) {
    bval <- NA
    if (length(unique(na.omit(int_n))) == 2) {
      tb <- table(env_n[int_n == min(int_n, na.rm = TRUE)])
      bval <- as.numeric(names(tb)[which.max(tb)])
    }
    if (is.na(bval)) bval <- u[1]
    rest <- setdiff(u, bval)
    env_cat[env_n == bval] <- "B"
    env_cat[env_n == rest[1]] <- "DA"
    env_cat[env_n == rest[2]] <- "FC"
  }
}
cat("Environment mapping table:\n"); print(table(env_n, env_cat, useNA = "ifany"))

# intervention
int_n <- num(int_raw)
if (length(unique(na.omit(int_n))) == 2) {
  l <- get_labels(int_raw)
  bval <- min(int_n, na.rm = TRUE)
  if (!is.null(l)) {
    b <- l[grepl("base|no int|control|none", names(l), ignore.case = TRUE)]
    if (length(b) > 0) bval <- as.numeric(b[1])
  }
  df$interv <- as.numeric(int_n != bval)
} else {
  df$interv <- as.numeric(env_cat != "B")
}
if (all(!is.na(env_cat))) {
  cat("Intervention vs env cat:\n"); print(table(df$interv, env_cat))
}
df$DA <- as.numeric(env_cat == "DA")
df$FC <- as.numeric(env_cat == "FC")

# ---------------- outcomes ----------------
df$y_dec <- num(df$summation_correct)
df$y_bg  <- num(df$load_correct)
df$y_pay <- num(df$payoff_share)
pv <- pick(c("^passive_choice$", "^passive$", "^default_followed$", "default_choice", "choice_default", "default_adher",
             "chose_default", "stick", "passiv"), exclude = "mean|correct_choice")
cat("Default adherence variable:", pv, "\n")
df$y_def <- if (!is.na(pv)) num(df[[pv]]) else NA_real_
if (!is.na(pv) && max(df$y_def, na.rm = TRUE) > 1) df$y_def <- as.numeric(df$y_def > 0)

# ---------------- controls ----------------
ctrl_terms <- character(0)
add_num <- function(v, newname) {
  if (is.na(v)) return(invisible(NULL))
  df[[newname]] <<- num(df[[v]])
  ctrl_terms <<- c(ctrl_terms, newname)
}
add_fac <- function(v, newname) {
  if (is.na(v)) return(invisible(NULL))
  x <- df[[v]]
  df[[newname]] <<- if (is.character(x)) factor(ifelse(x == "", NA, x)) else factor(num(x))
  ctrl_terms <<- c(ctrl_terms, paste0("factor(", newname, ")"))
}
v_age <- pick(c("^q_age$", "^age$", "_age$", "age"), exclude = "stage|page|percent|average|image|language")
v_gen <- pick(c("^q_gender$", "gender", "female", "sex"))
v_sub <- pick(c("^q_subject$", "subject_of_study", "field", "study"), exclude = "subject_id")
v_abi <- pick(c("^q_abitur_grade$", "abitur", "gpa"))
v_math <- pick(c("^q_math_grade$", "math_grade"), exclude = "cat")
v_ml <- pick(c("^ability_load$"))
v_mt <- pick(c("^ability_task$"))
v_multi <- pick(c("multitask", "multi"))
v_wave <- pick(c("^wave$", "wave", "experiment_part", "^part$"))
cat("Controls found: age=", v_age, " gender=", v_gen, " subject=", v_sub, " abitur=", v_abi,
    " math=", v_math, " abil_load=", v_ml, " abil_task=", v_mt, " multitask=", v_multi,
    " wave=", v_wave, "\n")
add_num(v_age, "c_age")
if (!is.na(v_gen)) {
  if (length(unique(na.omit(num(df[[v_gen]])))) > 2) add_fac(v_gen, "c_gender") else add_num(v_gen, "c_gender")
}
add_fac(v_sub, "c_subject")
add_num(v_abi, "c_abitur")
add_num(v_math, "c_math")
add_num(v_ml, "c_abl")
add_num(v_mt, "c_abt")
add_num(v_multi, "c_multi")
inc <- grep("^Treatment_Incentiv|incentiv|payoff_scheme|scheme", nms, value = TRUE, ignore.case = TRUE)
cat("Incentive vars:", paste(inc, collapse = ", "), "\n")
if (length(inc) == 1) {
  add_fac(inc, "c_inc")
} else if (length(inc) > 1) {
  for (k in seq_along(inc)) add_num(inc[k], paste0("c_inc", k))
}
add_fac(v_wave, "c_wave")

# ---------------- sample ----------------
samp <- df[scarce_flag & !is.na(env_cat) & !is.na(df$interv), ]
cat("Lab sample rows:", nrow(samp), " subjects:", length(unique(samp$cl)), "\n")
# drop constant controls in sample
keep <- vapply(ctrl_terms, function(t) {
  v <- gsub("^factor\\((.*)\\)$", "\\1", t)
  length(unique(na.omit(samp[[v]]))) > 1
}, logical(1))
ctrl_terms <- ctrl_terms[keep]
ctrl_str <- paste(ctrl_terms, collapse = " + ")
cat("Control terms:", ctrl_str, "\n")

safe_coef <- function(fml, data, var) {
  m <- tryCatch(feols(as.formula(fml), data = data, cluster = ~cl), error = function(e) { message(e$message); NULL })
  if (is.null(m)) return(list(b = NA, se = NA, n = NA, g = NA))
  b <- coef(m)[var]; se <- sqrt(diag(vcov(m)))[var]
  list(b = unname(b), se = unname(se), n = nobs(m), g = length(unique(data$cl[obs(m)])))
}

r1 <- safe_coef("y_dec ~ interv", samp, "interv")
r2 <- if (nchar(ctrl_str) > 0) safe_coef(paste("y_dec ~ interv +", ctrl_str), samp, "interv") else r1
r5 <- safe_coef("y_def ~ interv", samp, "interv")
r6 <- if (nchar(ctrl_str) > 0) safe_coef(paste("y_def ~ interv +", ctrl_str), samp, "interv") else r5
r7d <- safe_coef("y_def ~ DA + FC", samp, "DA")
r7f <- safe_coef("y_def ~ DA + FC", samp, "FC")
b1 <- safe_coef("y_bg ~ interv", samp, "interv")
b2 <- if (nchar(ctrl_str) > 0) safe_coef(paste("y_bg ~ interv +", ctrl_str), samp, "interv") else b1
p1 <- safe_coef("y_pay ~ interv", samp, "interv")

cat("N obs in col2 regression:", r2$n, "\n")

# ---------------- online experiment ----------------
mt <- haven::read_dta(mt_path)
cat("MTurk data:", nrow(mt), "rows\n")
for (nm in names(mt)) describe(nm, mt[[nm]])
mt$cl <- num(mt$subject_id)
mt$memory_n <- num(mt$memory)
ti <- num(mt$Treatment_intervention)
lb <- get_labels(mt$Treatment_intervention)
bv <- min(ti, na.rm = TRUE)
if (!is.null(lb)) {
  b <- lb[grepl("base|no int|control|none", names(lb), ignore.case = TRUE)]
  if (length(b) > 0) bv <- as.numeric(b[1])
}
mt$interv <- as.numeric(ti != bv)
mt$age_n <- num(mt$age)
mt$gender_n <- num(mt$gender)
mt$wh <- num(mt$window_height1)
mt$ww <- num(mt$window_width1)
gfml <- if (length(unique(na.omit(mt$gender_n))) > 2) "factor(gender_n)" else "gender_n"
o5 <- safe_coef("memory_n ~ interv", mt, "interv")
o6 <- safe_coef(paste("memory_n ~ interv + age_n +", gfml, "+ wh + ww"), mt, "interv")

out <- function(name, val) cat(sprintf("RESULT:%s=%s\n", name, format(val, digits = 10)))
out("choice_quality_intervention_t2_col1", r1$b)
out("choice_quality_intervention_t2_col2", r2$b)
out("default_adherence_intervention_t2_col5", r5$b)
out("default_adherence_intervention_t2_col6", r6$b)
out("default_adherence_directed_attention_t2_col7", r7d$b)
out("default_adherence_forced_choice_t2_col7", r7f$b)
out("background_quality_intervention_lab_t3_col1", b1$b)
out("background_quality_intervention_lab_t3_col2", b2$b)
out("memory_intervention_online_t3_col5", o5$b)
out("payoff_share_intervention_t4_col1", p1$b)
out("n_obs_lab_tables_2_to_4", r1$n)
out("n_subjects_lab_tables_2_to_4", r1$g)
out("memory_intervention_online_t3_col6", o6$b)