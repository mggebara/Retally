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
message("Columns: ", paste(names(raw), collapse = ", "))

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
is_directed <- grepl("direct|forced.?att|attention", env_low) & !grepl("baseline|endog", env_low)
is_forced <- grepl("forced.?choice|active", env_low) | (grepl("forced", env_low) & !grepl("att", env_low))
is_forced <- is_forced & !is_directed
is_base <- grepl("baseline|endog", env_low) & !is_directed & !is_forced
# Fallback via numeric codes 1/2/3 if string matching failed
if (sum(is_directed) == 0 || sum(is_forced) == 0 || sum(is_base) == 0) {
  envn <- to_num(raw$Treatment_Environment)
  u <- sort(unique(envn[!is.na(envn)]))
  message("Falling back to numeric environment codes: ", paste(u, collapse = ","))
  is_base <- envn == u[1]; is_directed <- envn == u[2]; is_forced <- envn == u[3]
  is_base[is.na(is_base)] <- FALSE; is_directed[is.na(is_directed)] <- FALSE; is_forced[is.na(is_forced)] <- FALSE
}
raw$directed <- as.integer(is_directed)
raw$forced <- as.integer(is_forced)
raw$baseline_env <- as.integer(is_base)

interv <- to_num(raw$Treatment_intervention)
if (all(is.na(interv))) interv <- ifelse(is_directed | is_forced, 1, ifelse(is_base, 0, NA))
raw$intervention <- interv

# ---------- Sample: scarce resources, three environments ----------
target_n <- 12160
in_env <- (is_base | is_directed | is_forced) & !is.na(raw$intervention)
sample_idx <- NULL
if (sum(in_env) == target_n) sample_idx <- in_env
if (is.null(sample_idx)) {
  cand <- nm[grepl("load|scarce|resource|cogn|ample|high|difficult", nm, ignore.case = TRUE) &
               !(nm %in% c("load_correct", "ability_load"))]
  best <- NULL; best_diff <- Inf
  for (cc in cand) {
    v <- to_num(raw[[cc]])
    uv <- unique(v[!is.na(v)])
    if (length(uv) != 2) next
    for (val in uv) {
      idx <- in_env & !is.na(v) & v == val
      dd <- abs(sum(idx) - target_n)
      message(sprintf("Candidate %s == %s: %d rows", cc, val, sum(idx)))
      # Prefer exact match; among ties prefer the larger value (scarce = 1)
      if (dd < best_diff || (dd == best_diff && !is.null(best) && val > best$val)) {
        best_diff <- dd; best <- list(col = cc, val = val, idx = idx)
      }
    }
  }
  if (!is.null(best)) {
    message("Using sample restriction ", best$col, " == ", best$val, " (", sum(best$idx), " rows)")
    sample_idx <- best$idx
  } else {
    sample_idx <- in_env
  }
}
d <- raw[sample_idx, , drop = FALSE]
message("Analysis sample: ", nrow(d), " rows, ", length(unique(d$subject_id)), " subjects")

# ---------- Outcomes ----------
d$choice_correct <- to_num(d$summation_correct)
d$bg_correct <- to_num(d$load_correct)
d$pshare <- to_num(d$payoff_share)

def_col <- find_col(c("^passive_choice$", "^passive", "default_adher", "^default_choice$",
                      "chose_default", "choice_default", "^default$", "passiv"),
                    exclude = c("default_correct_choice"))
if (is.na(def_col)) {
  def_col <- find_col(c("default"), exclude = c("default_correct_choice"))
}
message("Default adherence column: ", def_col)
d$def_adh <- if (!is.na(def_col)) to_num(d[[def_col]]) else NA_real_
if (all(is.na(d$def_adh))) message("No default adherence variable found")
# If coded in percent, rescale
if (isTRUE(max(d$def_adh, na.rm = TRUE) > 1)) d$def_adh <- d$def_adh / 100
if (isTRUE(max(d$choice_correct, na.rm = TRUE) > 1)) d$choice_correct <- d$choice_correct / 100
if (isTRUE(max(d$bg_correct, na.rm = TRUE) > 1)) d$bg_correct <- d$bg_correct / 100
if (isTRUE(max(d$pshare, na.rm = TRUE) > 1.5)) d$pshare <- d$pshare / 100

# ---------- Controls ----------
nm <- names(d)
ctrl_specs <- list()
age_c <- find_col(c("^q_age$", "^age$", "age"), exclude = c("payoff", "Attention"))
if (!is.na(age_c) && !grepl("average|stage|percent", age_c, ignore.case = TRUE)) ctrl_specs$age <- list(col = age_c, fac = FALSE)
if ("q_gender" %in% nm) ctrl_specs$gender <- list(col = "q_gender", fac = TRUE)
if ("q_subject" %in% nm) ctrl_specs$subject <- list(col = "q_subject", fac = TRUE)
if ("q_abitur_grade" %in% nm) ctrl_specs$gpa <- list(col = "q_abitur_grade", fac = FALSE)
if ("q_math_grade" %in% nm) ctrl_specs$math <- list(col = "q_math_grade", fac = FALSE)
if ("ability_task" %in% nm) ctrl_specs$abt <- list(col = "ability_task", fac = FALSE)
if ("ability_load" %in% nm) ctrl_specs$abl <- list(col = "ability_load", fac = FALSE)
mt_c <- find_col(c("multitask", "multi"))
if (!is.na(mt_c)) ctrl_specs$multi <- list(col = mt_c, fac = FALSE)
inc_c <- nm[grepl("^Treatment_Incentive|incentive|payoff_scheme|scheme", nm, ignore.case = TRUE)]
for (ic in inc_c) ctrl_specs[[paste0("inc_", ic)]] <- list(col = ic, fac = TRUE)
wave_c <- find_col(c("wave", "experiment_part", "^study$"))
if (!is.na(wave_c)) ctrl_specs$wave <- list(col = wave_c, fac = TRUE)
message("Controls: ", paste(sapply(ctrl_specs, `[[`, "col"), collapse = ", "))

ctrl_terms <- character(0)
for (k in names(ctrl_specs)) {
  cc <- ctrl_specs[[k]]$col
  newn <- paste0("c_", make.names(k))
  if (ctrl_specs[[k]]$fac) {
    v <- to_chr(d[[cc]])
    if (length(unique(v[!is.na(v)])) < 2) next
    d[[newn]] <- factor(v)
    ctrl_terms <- c(ctrl_terms, paste0("i(", newn, ")"))
  } else {
    v <- to_num(d[[cc]])
    if (length(unique(v[!is.na(v)])) < 2) next
    d[[newn]] <- v
    ctrl_terms <- c(ctrl_terms, newn)
  }
}
# factor terms via plain inclusion (feols handles factors)
ctrl_rhs <- gsub("^i\\((.*)\\)$", "\\1", ctrl_terms)

run <- function(y, rhs, data, coefname) {
  f <- as.formula(paste(y, "~", paste(rhs, collapse = " + ")))
  m <- tryCatch(feols(f, data = data, cluster = ~subject_id), error = function(e) { message(e$message); NULL })
  if (is.null(m)) return(list(b = NA, m = NULL))
  message(sprintf("%s ~ %s : N=%d", y, coefname, nobs(m)))
  list(b = unname(coef(m)[coefname]), se = unname(sqrt(diag(vcov(m)))[coefname]), m = m)
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