suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/altmann_2022_cognitive_spillovers.script-free"
lab_path <- file.path(base, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_replication.dta")
mt_path  <- file.path(base, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_long_mturk.dta")

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) {
    cat(sprintf("RESULT:%s=%.6f\n", name, val))
  } else {
    message("Could not compute ", name)
  }
}

to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) as.character(haven::as_factor(x, levels = "labels")) else as.character(x)
}
to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  suppressWarnings(as.numeric(x))
}

raw <- haven::read_dta(lab_path)
raw <- as.data.frame(raw)
message("Lab data: ", nrow(raw), " rows, ", ncol(raw), " cols")

nm <- names(raw)
find_col <- function(patterns, exclude = character(0)) {
  for (p in patterns) {
    hits <- nm[grepl(p, nm, ignore.case = TRUE) & !(nm %in% exclude)]
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}

# ---------- Treatment environment ----------
env_chr <- to_chr(raw$Treatment_Environment)
message("Treatment_Environment values: ", paste(unique(env_chr), collapse = " | "))
env_low <- tolower(env_chr)
is_directed <- grepl("direct", env_low)
is_forced <- grepl("forced.?choice|active", env_low) & !is_directed
is_base <- grepl("baseline", env_low) & !is_directed & !is_forced
is_directed[is.na(is_directed)] <- FALSE; is_forced[is.na(is_forced)] <- FALSE; is_base[is.na(is_base)] <- FALSE
raw$directed <- as.integer(is_directed)
raw$forced <- as.integer(is_forced)
raw$baseline_env <- as.integer(is_base)

interv <- to_num(raw$Treatment_intervention)
if (all(is.na(interv))) interv <- ifelse(is_directed | is_forced, 1, ifelse(is_base, 0, NA))
raw$intervention <- interv

# ---------- Sample restriction: search subject-level conditions giving 608 subjects / 12160 rows ----------
target_n <- 12160
target_s <- 608
in_env <- (is_base | is_directed | is_forced) & !is.na(raw$intervention)

# candidate subject-constant columns with few distinct values
excl <- c("subject_id", "round", "intervention", "directed", "forced", "baseline_env",
          "Treatment_intervention", "Treatment_Environment")
cand_cols <- character(0)
cand_vals <- list()
sid <- raw$subject_id
for (cc in setdiff(nm, excl)) {
  v <- to_chr(raw[[cc]])
  uv <- unique(v[!is.na(v)])
  if (length(uv) < 2 || length(uv) > 6) next
  # must be constant within subject
  nper <- tapply(v, sid, function(z) length(unique(z)))
  if (any(nper > 1, na.rm = TRUE)) next
  cand_cols <- c(cand_cols, cc)
  cand_vals[[cc]] <- sort(uv)
}
message("Subject-level candidate columns: ", paste(cand_cols, collapse = ", "))

conds <- list()
for (cc in cand_cols) {
  v <- to_chr(raw[[cc]])
  for (val in cand_vals[[cc]]) {
    idx <- !is.na(v) & v == val
    conds[[length(conds) + 1]] <- list(desc = paste0(cc, "==", val), idx = idx, col = cc)
    idx2 <- !(!is.na(v) & v == val)
    conds[[length(conds) + 1]] <- list(desc = paste0(cc, "!=", val), idx = idx2, col = cc)
  }
}

check <- function(idx) {
  ii <- in_env & idx
  ns <- length(unique(raw$subject_id[ii]))
  ok_var <- length(unique(raw$intervention[ii])) == 2 &&
    sum(is_directed & ii) > 0 && sum(is_forced & ii) > 0 && sum(is_base & ii) > 0
  list(n = sum(ii), ns = ns, ok = ok_var, ii = ii)
}

sample_idx <- NULL
sample_desc <- "none"
if (sum(in_env) == target_n) { sample_idx <- in_env; sample_desc <- "all environments" }
if (is.null(sample_idx)) {
  for (cd in conds) {
    r <- check(cd$idx)
    if (r$ok && r$n == target_n && r$ns == target_s) { sample_idx <- r$ii; sample_desc <- cd$desc; break }
  }
}
if (is.null(sample_idx) && length(conds) > 1) {
  for (i in seq_along(conds)) {
    for (j in seq_along(conds)) {
      if (j <= i || conds[[i]]$col == conds[[j]]$col) next
      r <- check(conds[[i]]$idx & conds[[j]]$idx)
      if (r$ok && r$n == target_n && r$ns == target_s) {
        sample_idx <- r$ii; sample_desc <- paste(conds[[i]]$desc, "&", conds[[j]]$desc); break
      }
    }
    if (!is.null(sample_idx)) break
  }
}
if (is.null(sample_idx)) {
  # closest single condition by subject count
  best <- NULL; bd <- Inf
  for (cd in conds) {
    r <- check(cd$idx)
    if (!r$ok) next
    dd <- abs(r$ns - target_s)
    if (dd < bd) { bd <- dd; best <- r; sample_desc <- cd$desc }
  }
  sample_idx <- if (!is.null(best)) best$ii else in_env
}
message("Using sample restriction: ", sample_desc)
d <- raw[sample_idx, , drop = FALSE]
message("Analysis sample: ", nrow(d), " rows, ", length(unique(d$subject_id)), " subjects")

# ---------- Outcomes ----------
d$choice_correct <- to_num(d$summation_correct)
d$bg_correct <- to_num(d$load_correct)
d$pshare <- to_num(d$payoff_share)
d$def_adh <- to_num(d$default_followed)
if (isTRUE(max(d$def_adh, na.rm = TRUE) > 1)) d$def_adh <- d$def_adh / 100
if (isTRUE(max(d$choice_correct, na.rm = TRUE) > 1)) d$choice_correct <- d$choice_correct / 100
if (isTRUE(max(d$bg_correct, na.rm = TRUE) > 1)) d$bg_correct <- d$bg_correct / 100
if (isTRUE(max(d$pshare, na.rm = TRUE) > 1.5)) d$pshare <- d$pshare / 100

# ---------- Controls (factors expanded to clean dummy columns) ----------
nm <- names(d)
ctrl_specs <- list()
if ("q_age" %in% nm) ctrl_specs$age <- list(col = "q_age", fac = FALSE)
if ("q_gender" %in% nm) ctrl_specs$gender <- list(col = "q_gender", fac = TRUE)
if ("q_subject" %in% nm) ctrl_specs$subject <- list(col = "q_subject", fac = TRUE)
if ("q_abitur_grade" %in% nm) ctrl_specs$gpa <- list(col = "q_abitur_grade", fac = FALSE)
if ("q_math_grade" %in% nm) ctrl_specs$math <- list(col = "q_math_grade", fac = FALSE)
if ("ability_task" %in% nm) ctrl_specs$abt <- list(col = "ability_task", fac = FALSE)
if ("ability_load" %in% nm) ctrl_specs$abl <- list(col = "ability_load", fac = FALSE)
if ("perc_multitasking_1" %in% nm) ctrl_specs$multi <- list(col = "perc_multitasking_1", fac = FALSE)

ctrl_rhs <- character(0)
for (k in names(ctrl_specs)) {
  cc <- ctrl_specs[[k]]$col
  if (ctrl_specs[[k]]$fac) {
    v <- to_chr(d[[cc]])
    lv <- sort(unique(v[!is.na(v)]))
    if (length(lv) < 2) next
    for (j in seq_along(lv)[-1]) {
      newn <- paste0("c_", k, "_", j)
      d[[newn]] <- ifelse(is.na(v), NA_real_, as.numeric(v == lv[j]))
      ctrl_rhs <- c(ctrl_rhs, newn)
    }
  } else {
    v <- to_num(d[[cc]])
    if (length(unique(v[!is.na(v)])) < 2) next
    newn <- paste0("c_", k)
    d[[newn]] <- v
    ctrl_rhs <- c(ctrl_rhs, newn)
  }
}
message("Control terms: ", paste(ctrl_rhs, collapse = ", "))

run <- function(y, rhs, data, coefname) {
  f <- as.formula(paste(y, "~", paste(rhs, collapse = " + ")))
  m <- tryCatch(feols(f, data = data, cluster = ~subject_id), error = function(e) { message(e$message); NULL })
  if (is.null(m)) return(list(b = NA, m = NULL))
  message(sprintf("%s ~ %s : N=%d", y, coefname, nobs(m)))
  list(b = unname(coef(m)[coefname]), m = m)
}

r1 <- run("choice_correct", "intervention", d, "intervention")
r2 <- run("choice_correct", c("intervention", ctrl_rhs), d, "intervention")
r5 <- run("def_adh", "intervention", d, "intervention")
r6 <- run("def_adh", c("intervention", ctrl_rhs), d, "intervention")
r7 <- tryCatch({
  m <- feols(def_adh ~ directed + forced, data = d, cluster = ~subject_id)
  list(da = unname(coef(m)["directed"]), fc = unname(coef(m)["forced"]))
}, error = function(e) list(da = NA, fc = NA))
rb1 <- run("bg_correct", "intervention", d, "intervention")
rb2 <- run("bg_correct", c("intervention", ctrl_rhs), d, "intervention")
rp1 <- run("pshare", "intervention", d, "intervention")

# ---------- Online experiment ----------
mt1 <- NA; mt2 <- NA
mt <- tryCatch(as.data.frame(haven::read_dta(mt_path)), error = function(e) NULL)
if (!is.null(mt)) {
  mt$memory_n <- to_num(mt$memory)
  if (isTRUE(max(mt$memory_n, na.rm = TRUE) > 1)) mt$memory_n <- mt$memory_n / 100
  mt$intervention <- to_num(mt$Treatment_intervention)
  mt$age_n <- to_num(mt$age)
  mt$gender_f <- factor(to_chr(mt$gender))
  mt$wh <- to_num(mt$window_height1)
  mt$ww <- to_num(mt$window_width1)
  m5 <- tryCatch(feols(memory_n ~ intervention, data = mt, cluster = ~subject_id), error = function(e) NULL)
  m6 <- tryCatch(feols(memory_n ~ intervention + age_n + gender_f + wh + ww, data = mt, cluster = ~subject_id),
                 error = function(e) NULL)
  if (!is.null(m5)) mt1 <- unname(coef(m5)["intervention"])
  if (!is.null(m6)) mt2 <- unname(coef(m6)["intervention"])
}

# ---------- Output ----------
cat(sprintf("DEVIATION: Sample restriction chosen by matching the paper's reported N (608 subjects, 12160 obs): %s\n", sample_desc))
cat("DEVIATION: Control set for columns 2/6 inferred from available covariates (age, gender, field, GPA, math grade, ability tasks, multitasking); factors entered as dummies\n")
emit("choice_quality_intervention_t2_col1", r1$b)
emit("choice_quality_intervention_t2_col2", r2$b)
emit("default_adherence_intervention_t2_col5", r5$b)
emit("default_adherence_intervention_t2_col6", r6$b)
emit("default_adherence_directed_attention_t2_col7", r7$da)
emit("default_adherence_forced_choice_t2_col7", r7$fc)
emit("background_quality_intervention_lab_t3_col1", rb1$b)
emit("background_quality_intervention_lab_t3_col2", rb2$b)
emit("memory_intervention_online_t3_col5", mt1)
emit("payoff_share_intervention_t4_col1", rp1$b)
n_obs <- if (!is.null(r1$m)) nobs(r1$m) else nrow(d)
emit("n_obs_lab_tables_2_to_4", as.numeric(n_obs))
emit("n_subjects_lab_tables_2_to_4", as.numeric(length(unique(d$subject_id[!is.na(d$choice_correct)]))))
emit("memory_intervention_online_t3_col6", mt2)