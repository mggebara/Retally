suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/altmann_2022_cognitive_spillovers.script-free/ReplicationPackage/EmpiricalAnalysis/original_data"
lab_raw <- read_dta(file.path(root, "formatted_data_replication.dta"))
d <- as.data.frame(lab_raw)

results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) results[[name]] <<- val
}

num <- function(x) suppressWarnings(as.numeric(zap_labels(x)))
labtxt <- function(x) {
  if (inherits(x, "haven_labelled")) as.character(as_factor(x, levels = "default")) else as.character(x)
}
lev <- function(x) { y <- labtxt(x); y[is.na(y)] <- "<NA>"; y }

cat("Rows:", nrow(d), " Cols:", ncol(d), "\n")

d$sid <- as.character(d$subject_id)
ti_all <- num(d$Treatment_intervention)

# Print subject-level tabulations of candidate sample variables
for (v in c("original_lab", "Treatment_Incentives", "Treatment_Incentives_Baseline_sc",
            "Treatment_Incentives_Int_sc", "high_task_difficulty", "Treatment_Environment")) {
  if (v %in% names(d)) {
    cat("---- subject-level", v, "x intervention\n")
    first <- !duplicated(d$sid)
    print(table(lev(d[[v]])[first], ti_all[first], useNA = "ifany"))
  }
}

# ---------------- Sample: subject-level search for N = 608 subjects / 12160 obs ----------------
target_sub <- 608
first <- !duplicated(d$sid)
nsub_all <- sum(first)
excl <- c("load_correct", "load_correct_mean", "ability_load", "ability_task", "summation_correct",
          "summation_correct_mean", "round", "Treatment_intervention", "default_correct_choice",
          "payoff", "payoff_share", "payoff_share_mean", "Attention", "attention_mean",
          "attention_positive_mean", "default_followed", "default_followed_mean",
          "default_followed_correct_mean", "diff_choice_second", "no_attention", "subject_id", "sid",
          "q_age", "raven_score", "q_abitur_grade", "q_math_grade", "q_abitur_year")
cand <- character()
L <- list()
for (v in setdiff(names(d), excl)) {
  x <- lev(d[[v]])
  ux <- unique(x)
  if (length(ux) < 2 || length(ux) > 8) next
  # subject-level constant?
  if (length(unique(paste(d$sid, x))) != nsub_all) next
  cand <- c(cand, v)
  L[[v]] <- x[first]
}
ti_s <- ti_all[first]
pri_score <- function(v) {
  if (grepl("Incentive", v)) return(0)
  if (grepl("original_lab", v)) return(1)
  if (grepl("difficulty", v)) return(2)
  if (grepl("Environment", v)) return(5)
  3
}
conds <- list()
for (v in cand) {
  for (u in unique(L[[v]])) {
    conds[[length(conds) + 1]] <- list(desc = paste0(v, "==", u), s = L[[v]] == u, pri = pri_score(v))
    if (length(unique(L[[v]])) > 2)
      conds[[length(conds) + 1]] <- list(desc = paste0(v, "!=", u), s = L[[v]] != u, pri = pri_score(v))
  }
}
okc <- function(s) sum(s) == target_sub && length(unique(ti_s[s])) == 2 &&
  min(table(ti_s[s])) > 50
hits <- list()
for (c1 in conds) if (okc(c1$s)) hits[[length(hits) + 1]] <- list(desc = c1$desc, s = c1$s, pri = c1$pri, k = 1)
if (!length(hits)) {
  nc <- length(conds)
  for (i in seq_len(nc - 1)) for (j in (i + 1):nc) {
    s <- conds[[i]]$s & conds[[j]]$s
    if (okc(s)) hits[[length(hits) + 1]] <- list(desc = paste(conds[[i]]$desc, "&", conds[[j]]$desc), s = s,
                                                  pri = conds[[i]]$pri + conds[[j]]$pri, k = 2)
    s <- conds[[i]]$s | conds[[j]]$s
    if (okc(s)) hits[[length(hits) + 1]] <- list(desc = paste(conds[[i]]$desc, "|", conds[[j]]$desc), s = s,
                                                  pri = conds[[i]]$pri + conds[[j]]$pri, k = 2)
  }
}
sel <- rep(TRUE, nrow(d))
if (length(hits)) {
  # deduplicate identical selections
  keys <- sapply(hits, function(h) paste(which(h$s), collapse = ","))
  hits <- hits[!duplicated(keys)]
  cat("Candidate sample definitions with 608 subjects:\n")
  for (h in hits) cat("  ", h$desc, "\n")
  o <- order(sapply(hits, `[[`, "k"), sapply(hits, `[[`, "pri"))
  best <- hits[[o[1]]]
  cat("Chosen sample:", best$desc, "\n")
  keep_ids <- d$sid[first][best$s]
  sel <- d$sid %in% keep_ids
  cat("DEVIATION: Sample for Tables 2-4 identified by searching subject-level variables for the definition yielding 608 subjects (", best$desc, ")\n")
} else {
  cat("WARNING: could not identify 608-subject sample; using full sample\n")
}

ds <- d[sel, , drop = FALSE]
cat("Sample rows:", nrow(ds), " subjects:", length(unique(ds$sid)), "\n")

ds$intervention <- num(ds$Treatment_intervention)
if (!all(ds$intervention %in% c(0, 1))) {
  ds$intervention <- as.numeric(ds$intervention != min(ds$intervention, na.rm = TRUE))
}
ds$default_adh <- num(ds$default_followed)
ds$choice_q <- num(ds$summation_correct)
ds$bg_q <- num(ds$load_correct)
ds$pshare <- num(ds$payoff_share)

# ---------------- Environment dummies ----------------
envl <- labtxt(ds$Treatment_Environment)
print(table(envl, ds$intervention, useNA = "ifany"))
ds$directed <- as.numeric(ds$intervention == 1 & grepl("direct", envl, ignore.case = TRUE))
ds$forced <- as.numeric(ds$intervention == 1 & grepl("forced|active", envl, ignore.case = TRUE))

# ---------------- Controls (numeric matrix, safe names) ----------------
ctrl_terms <- character()
k <- 0
add_num <- function(x) {
  x <- as.numeric(x)
  if (all(is.na(x)) || length(unique(na.omit(x))) < 2) return(invisible(NULL))
  if (any(is.na(x))) {
    k <<- k + 1; nm <- paste0("cx", k)
    ds[[nm]] <<- as.numeric(is.na(x)); ctrl_terms <<- c(ctrl_terms, nm)
    x[is.na(x)] <- mean(x, na.rm = TRUE)
  }
  k <<- k + 1; nm <- paste0("cx", k)
  ds[[nm]] <<- x; ctrl_terms <<- c(ctrl_terms, nm)
}
if ("q_age" %in% names(ds)) add_num(num(ds$q_age))
if ("q_gender" %in% names(ds)) {
  g <- labtxt(ds$q_gender); add_num(ifelse(is.na(g), NA, as.numeric(grepl("^female", g, ignore.case = TRUE))))
}
if ("economist" %in% names(ds)) add_num(num(ds$economist))
if ("q_abitur_grade" %in% names(ds)) add_num(num(ds$q_abitur_grade))
if ("q_math_grade" %in% names(ds)) add_num(num(ds$q_math_grade))
if ("ability_load" %in% names(ds)) add_num(num(ds$ability_load))
if ("ability_task" %in% names(ds)) add_num(num(ds$ability_task))
ctrl_str <- if (length(ctrl_terms)) paste(ctrl_terms, collapse = " + ") else "1"
cat("Controls:", ctrl_str, "\n")

run <- function(y, rhs, data, coefname, cl = ~sid) {
  tryCatch({
    f <- as.formula(paste(y, "~", rhs))
    m <- feols(f, data = data, cluster = cl)
    print(summary(m))
    list(b = unname(coef(m)[coefname]), se = unname(sqrt(diag(vcov(m)))[coefname]), n = nobs(m))
  }, error = function(e) { cat("Error in", y, ":", conditionMessage(e), "\n"); NULL })
}

r <- run("choice_q", "intervention", ds, "intervention")
if (!is.null(r)) { emit("choice_quality_intervention_t2_col1", r$b); emit("choice_quality_intervention_t2_col1_se", r$se) }
r <- run("choice_q", paste("intervention +", ctrl_str), ds, "intervention")
if (!is.null(r)) { emit("choice_quality_intervention_t2_col2", r$b); emit("choice_quality_intervention_t2_col2_se", r$se) }

r <- run("default_adh", "intervention", ds, "intervention")
if (!is.null(r)) { emit("default_adherence_intervention_t2_col5", r$b); emit("default_adherence_intervention_t2_col5_se", r$se) }
r <- run("default_adh", paste("intervention +", ctrl_str), ds, "intervention")
if (!is.null(r)) { emit("default_adherence_intervention_t2_col6", r$b); emit("default_adherence_intervention_t2_col6_se", r$se) }
m7 <- tryCatch(feols(default_adh ~ directed + forced, data = ds, cluster = ~sid), error = function(e) NULL)
if (!is.null(m7)) {
  print(summary(m7))
  se7 <- sqrt(diag(vcov(m7)))
  emit("default_adherence_directed_attention_t2_col7", unname(coef(m7)["directed"]))
  emit("default_adherence_directed_attention_t2_col7_se", unname(se7["directed"]))
  emit("default_adherence_forced_choice_t2_col7", unname(coef(m7)["forced"]))
  emit("default_adherence_forced_choice_t2_col7_se", unname(se7["forced"]))
}

r <- run("bg_q", "intervention", ds, "intervention")
if (!is.null(r)) {
  emit("background_quality_intervention_lab_t3_col1", r$b); emit("background_quality_intervention_lab_t3_col1_se", r$se)
  emit("n_obs_lab_tables_2_to_4", r$n)
}
r <- run("bg_q", paste("intervention +", ctrl_str), ds, "intervention")
if (!is.null(r)) { emit("background_quality_intervention_lab_t3_col2", r$b); emit("background_quality_intervention_lab_t3_col2_se", r$se) }

r <- run("pshare", "intervention", ds, "intervention")
if (!is.null(r)) { emit("payoff_share_intervention_t4_col1", r$b); emit("payoff_share_intervention_t4_col1_se", r$se) }

emit("n_subjects_lab_tables_2_to_4", length(unique(ds$sid[!is.na(ds$bg_q) & !is.na(ds$intervention)])))

# ---------------- Online experiment ----------------
tryCatch({
  m <- as.data.frame(read_dta(file.path(root, "formatted_data_long_mturk.dta")))
  m$y <- num(m$memory)
  m$ti <- num(m$Treatment_intervention)
  if (!all(m$ti %in% c(0, 1))) m$ti <- as.numeric(m$ti != min(m$ti, na.rm = TRUE))
  m$sid <- as.character(m$subject_id)
  m$c_age <- num(m$age)
  g <- labtxt(m$gender); g[is.na(g) | g == ""] <- "missing"
  m$c_gender <- factor(g)
  m$c_wh <- num(m$window_height1)
  m$c_ww <- num(m$window_width1)
  r5 <- run("y", "ti", m, "ti")
  if (!is.null(r5)) { emit("memory_intervention_online_t3_col5", r5$b); emit("memory_intervention_online_t3_col5_se", r5$se) }
  r6 <- run("y", "ti + c_age + c_gender + c_wh + c_ww", m, "ti")
  if (!is.null(r6)) { emit("memory_intervention_online_t3_col6", r6$b); emit("memory_intervention_online_t3_col6_se", r6$se) }
}, error = function(e) cat("Online error:", conditionMessage(e), "\n"))

for (k in names(results)) cat(sprintf("RESULT:%s=%.6f\n", k, results[[k]]))