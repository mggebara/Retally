suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/altmann_2022_cognitive_spillovers.script-free"
lab_path <- file.path(base, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_replication.dta")
mt_path  <- file.path(base, "ReplicationPackage/EmpiricalAnalysis/original_data/formatted_data_long_mturk.dta")

results <- list()
put <- function(name, val) {
  if (is.null(val) || length(val) == 0) val <- NA
  results[[name]] <<- as.numeric(val)[1]
}

to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  suppressWarnings(as.numeric(x))
}
lab_chr <- function(x) {
  if (inherits(x, "haven_labelled")) as.character(as_factor(x, levels = "labels")) else as.character(x)
}

d <- read_dta(lab_path)
nm <- names(d)
cat("Lab columns:\n"); print(nm)
for (v in nm) {
  if (inherits(d[[v]], "haven_labelled")) {
    lb <- attr(d[[v]], "labels")
    cat(v, "labels:", paste(names(lb), lb, sep = "=", collapse = "; "), "\n")
  }
}

## ---------- Decision environment ----------
env_raw <- tolower(lab_chr(d$Treatment_Environment))
cat("Environment values:\n"); print(table(env_raw, useNA = "ifany"))
env <- rep(NA_character_, nrow(d))
env[grepl("base", env_raw)] <- "Baseline"
env[grepl("direct|attention", env_raw) & is.na(env)] <- "Directed"
env[grepl("forc|active", env_raw) & is.na(env)] <- "Forced"
if (all(is.na(env))) {
  # numeric coding fallback: 0/1 Baseline, then Directed, Forced in order
  ev <- to_num(d$Treatment_Environment)
  u <- sort(unique(ev[!is.na(ev)]))
  if (length(u) >= 3) {
    env[ev == u[1]] <- "Baseline"; env[ev == u[2]] <- "Directed"; env[ev == u[3]] <- "Forced"
  }
}
d$env <- env

## ---------- Intervention ----------
if ("Treatment_intervention" %in% nm) {
  d$interv <- to_num(d$Treatment_intervention)
} else {
  d$interv <- ifelse(is.na(d$env), NA, as.numeric(d$env != "Baseline"))
}
cat("Intervention x env:\n"); print(table(d$env, d$interv, useNA = "ifany"))

## ---------- Scarce cognitive resources sample ----------
load_cands <- nm[grepl("load|scarce|resource|cognitive|digit", nm, ignore.case = TRUE) &
                   !nm %in% c("load_correct", "ability_load") &
                   !grepl("correct|ability", nm, ignore.case = TRUE)]
cat("Load candidates:", paste(load_cands, collapse = ", "), "\n")
scarce <- rep(NA, nrow(d))
found_load <- FALSE
for (v in load_cands) {
  x <- d[[v]]
  xl <- tolower(lab_chr(x))
  xn <- to_num(x)
  ux <- unique(xn[!is.na(xn)])
  if (inherits(x, "haven_labelled") && any(grepl("high|scarce|7", xl))) {
    scarce <- grepl("high|scarce|7", xl); found_load <- TRUE; cat("Scarce from", v, "(labels)\n"); break
  }
  if (is.character(x) && any(grepl("high|scarce", xl))) {
    scarce <- grepl("high|scarce", xl); found_load <- TRUE; cat("Scarce from", v, "(strings)\n"); break
  }
  if (length(ux) == 2 && all(sort(ux) == c(0, 1))) {
    if (grepl("low|ample", v, ignore.case = TRUE)) scarce <- xn == 0 else scarce <- xn == 1
    found_load <- TRUE; cat("Scarce from", v, "(0/1)\n"); break
  }
  if (length(ux) == 2 && all(sort(ux) == c(2, 7))) {
    scarce <- xn == 7; found_load <- TRUE; cat("Scarce from", v, "(2/7)\n"); break
  }
}
if (!found_load) {
  cat("No load variable identified; using all rows with non-missing intervention and environment\n")
  scarce <- rep(TRUE, nrow(d))
}
d$scarce <- scarce

s <- d %>% filter(scarce %in% TRUE, !is.na(interv), !is.na(env))
cat("Sample rows:", nrow(s), " subjects:", length(unique(s$subject_id)), "\n")

## ---------- Outcomes ----------
s$dec_correct <- to_num(s$summation_correct)
s$bg_correct  <- to_num(s$load_correct)
s$pshare      <- to_num(s$payoff_share)
pass_cands <- nm[grepl("passive|default_choice|chose_default|default_chosen|choice_default|default_adher|adherence", nm, ignore.case = TRUE)]
if (length(pass_cands) == 0)
  pass_cands <- nm[grepl("default", nm, ignore.case = TRUE) & !grepl("default_correct", nm, ignore.case = TRUE)]
cat("Passive candidates:", paste(pass_cands, collapse = ", "), "\n")
s$passive <- if (length(pass_cands) > 0) to_num(s[[pass_cands[1]]]) else NA_real_
if (!is.null(s$pshare) && max(s$pshare, na.rm = TRUE) > 1.5) s$pshare <- s$pshare / 100

s$directed <- as.numeric(s$env == "Directed")
s$forced   <- as.numeric(s$env == "Forced")

## ---------- Controls ----------
first_match <- function(pats) {
  for (p in pats) { m <- nm[grepl(p, nm, ignore.case = TRUE)]; if (length(m) > 0) return(m[1]) }
  NULL
}
ctrl_terms <- c()
add_num <- function(v) { if (!is.null(v) && v %in% names(s)) { s[[paste0("c_", v)]] <<- to_num(s[[v]]); ctrl_terms <<- c(ctrl_terms, paste0("c_", v)) } }
add_fac <- function(v) { if (!is.null(v) && v %in% names(s)) { s[[paste0("f_", v)]] <<- factor(lab_chr(s[[v]])); ctrl_terms <<- c(ctrl_terms, paste0("f_", v)) } }

add_num(first_match(c("^q_age$", "^age$", "age")))
add_fac(first_match(c("^q_gender$", "gender")))
v_subj <- first_match(c("^q_subject$"))
if (!is.null(v_subj) && length(unique(s[[v_subj]])) <= 40) add_fac(v_subj) else add_num(first_match(c("^economist$")))
add_num(first_match(c("^q_abitur_grade$", "abitur")))
add_num(first_match(c("^q_math_grade$")))
add_num("ability_load")
add_num("ability_task")
add_num(first_match(c("multi")))
inc_vars <- nm[grepl("incentive|payoff_scheme|scheme", nm, ignore.case = TRUE)]
for (v in inc_vars) {
  if (length(unique(na.omit(s[[v]]))) > 2) add_fac(v) else add_num(v)
}
wave_v <- first_match(c("wave", "^experiment$", "replication", "^study$"))
if (!is.null(wave_v)) add_fac(wave_v)
# drop constant controls
ctrl_terms <- ctrl_terms[sapply(ctrl_terms, function(v) length(unique(na.omit(s[[v]]))) > 1)]
cat("Controls used:", paste(ctrl_terms, collapse = ", "), "\n")
ctrl_str <- if (length(ctrl_terms) > 0) paste("+", paste(ctrl_terms, collapse = " + ")) else ""

run <- function(y, rhs, coefname, data = s) {
  out <- tryCatch({
    m <- feols(as.formula(paste(y, "~", rhs)), data = data, cluster = ~subject_id)
    print(summary(m))
    list(b = unname(coef(m)[coefname]), n = nobs(m))
  }, error = function(e) { cat("Error:", conditionMessage(e), "\n"); list(b = NA, n = NA) })
  out
}

r1 <- run("dec_correct", "interv", "interv")
put("choice_quality_intervention_t2_col1", r1$b)
r2 <- run("dec_correct", paste("interv", ctrl_str), "interv")
put("choice_quality_intervention_t2_col2", r2$b)
r5 <- run("passive", "interv", "interv")
put("default_adherence_intervention_t2_col5", r5$b)
r6 <- run("passive", paste("interv", ctrl_str), "interv")
put("default_adherence_intervention_t2_col6", r6$b)
r7 <- tryCatch({
  m <- feols(passive ~ directed + forced, data = s, cluster = ~subject_id); print(summary(m)); coef(m)
}, error = function(e) c(directed = NA, forced = NA))
put("default_adherence_directed_attention_t2_col7", r7["directed"])
put("default_adherence_forced_choice_t2_col7", r7["forced"])
b1 <- run("bg_correct", "interv", "interv")
put("background_quality_intervention_lab_t3_col1", b1$b)
b2 <- run("bg_correct", paste("interv", ctrl_str), "interv")
put("background_quality_intervention_lab_t3_col2", b2$b)
p1 <- run("pshare", "interv", "interv")
put("payoff_share_intervention_t4_col1", p1$b)

put("n_obs_lab_tables_2_to_4", if (!is.na(r1$n)) r1$n else nrow(s))
put("n_subjects_lab_tables_2_to_4", length(unique(s$subject_id[!is.na(s$dec_correct)])))

## ---------- Online experiment ----------
mt <- tryCatch(read_dta(mt_path), error = function(e) NULL)
if (!is.null(mt)) {
  cat("MTurk columns:\n"); print(names(mt))
  mt$mem <- to_num(mt$memory)
  if (max(mt$mem, na.rm = TRUE) > 1.5) cat("Note: memory variable exceeds 1; using as is\n")
  mt$interv <- to_num(mt$Treatment_intervention)
  mt$age_c <- to_num(mt$age)
  mt$gender_f <- factor(lab_chr(mt$gender))
  mt$wh <- to_num(mt$window_height1)
  mt$ww <- to_num(mt$window_width1)
  o5 <- run("mem", "interv", "interv", data = mt)
  put("memory_intervention_online_t3_col5", o5$b)
  o6 <- run("mem", "interv + age_c + gender_f + wh + ww", "interv", data = mt)
  put("memory_intervention_online_t3_col6", o6$b)
} else {
  put("memory_intervention_online_t3_col5", NA)
  put("memory_intervention_online_t3_col6", NA)
}

order_names <- c("choice_quality_intervention_t2_col1", "choice_quality_intervention_t2_col2",
                 "default_adherence_intervention_t2_col5", "default_adherence_intervention_t2_col6",
                 "default_adherence_directed_attention_t2_col7", "default_adherence_forced_choice_t2_col7",
                 "background_quality_intervention_lab_t3_col1", "background_quality_intervention_lab_t3_col2",
                 "memory_intervention_online_t3_col5", "payoff_share_intervention_t4_col1",
                 "n_obs_lab_tables_2_to_4", "n_subjects_lab_tables_2_to_4",
                 "memory_intervention_online_t3_col6")
for (n in order_names) {
  v <- results[[n]]
  if (is.null(v)) v <- NA
  cat(sprintf("RESULT:%s=%s\n", n, format(v, digits = 10)))
}
