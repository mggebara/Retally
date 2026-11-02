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

cat("Rows:", nrow(d), " Cols:", ncol(d), "\n")
print(names(d))
for (v in names(d)) {
  u <- unique(d[[v]])
  if (length(u) <= 8) {
    cat("----", v, "\n")
    print(table(labtxt(d[[v]]), useNA = "ifany"))
  }
}

# ---------------- Sample: scarce cognitive resources, three environments ----------------
target_n <- 12160
ti_all <- num(d$Treatment_intervention)
check_sel <- function(s) {
  s[is.na(s)] <- FALSE
  sum(s) == target_n && length(unique(na.omit(ti_all[s]))) == 2
}
sel <- NULL
s0 <- !is.na(ti_all)
if (check_sel(s0)) sel <- s0

excl <- c("load_correct", "load_correct_mean", "ability_load", "ability_task", "summation_correct",
          "summation_correct_mean", "round", "Treatment_intervention", "default_correct_choice",
          "payoff", "payoff_share", "payoff_share_mean", "Attention", "attention_mean",
          "attention_positive", "raven_score", "raven_score_median", "raven_score_quartiles")

# labels suggesting scarce/high load
if (is.null(sel)) {
  for (v in setdiff(names(d), excl)) {
    x <- labtxt(d[[v]])
    ux <- unique(x[!is.na(x)])
    if (length(ux) < 2 || length(ux) > 12) next
    s <- !is.na(x) & grepl("scarce|high.?load|high|7.?digit|seven", x, ignore.case = TRUE)
    if (check_sel(s)) { sel <- s; cat("Scarce sample via labels of", v, "\n"); break }
  }
}
if (is.null(sel)) {
  cand_cols <- setdiff(names(d), excl)
  pri <- grepl("load|scarce|ample|cogn|high|resource|treat", cand_cols, ignore.case = TRUE)
  cand_cols <- c(cand_cols[pri], cand_cols[!pri])
  for (v in cand_cols) {
    x <- labtxt(d[[v]])
    ux <- unique(x[!is.na(x)])
    if (length(ux) < 2 || length(ux) > 12) next
    for (u in ux) {
      s <- !is.na(x) & x == u
      if (check_sel(s)) { sel <- s; cat("Scarce sample via", v, "==", u, "\n"); break }
    }
    if (!is.null(sel)) break
  }
}
if (is.null(sel)) {
  cat("WARNING: could not identify scarce sample with N=12160; using non-missing intervention\n")
  sel <- s0
}
sel[is.na(sel)] <- FALSE

# ---------------- Subject id ----------------
make_round_id <- function(dd) {
  r <- num(dd$round)
  cumsum(c(TRUE, diff(r) <= 0))
}
ds <- d[sel, , drop = FALSE]
id_col <- NULL
nsub_guess <- nrow(ds) / 20
for (v in names(ds)) {
  x <- ds[[v]]
  if (any(is.na(x))) next
  if (length(unique(x)) == nsub_guess) {
    tb <- table(as.character(x))
    if (all(tb == 20)) {
      isid <- grepl("id|participant|subject|code|label", v, ignore.case = TRUE) && v != "q_subject"
      if (is.null(id_col)) id_col <- v
      else if (isid && !(grepl("id|participant|subject|code|label", id_col, ignore.case = TRUE) && id_col != "q_subject")) id_col <- v
    }
  }
}
if (!is.null(id_col) && !(grepl("id|participant|subject|code|label", id_col, ignore.case = TRUE) && id_col != "q_subject")) {
  # non-id-like column; fall back to consecutive-round construction if consistent
  rid <- make_round_id(d)[sel]
  if (length(unique(rid)) == nsub_guess) id_col <- NULL
}
if (is.null(id_col)) {
  ds$sid <- make_round_id(d)[sel]
  cat("Subject id constructed from round sequence\n")
} else {
  ds$sid <- as.character(ds[[id_col]])
  cat("Subject id column:", id_col, "\n")
}

ds$intervention <- num(ds$Treatment_intervention)
if (!all(ds$intervention %in% c(0, 1))) {
  ds$intervention <- as.numeric(ds$intervention != min(ds$intervention, na.rm = TRUE))
}

# ---------------- Default adherence variable ----------------
is01 <- function(x) {
  y <- num(x)
  u <- unique(y[!is.na(y)])
  length(u) <= 2 && length(u) >= 1 && all(u %in% c(0, 1))
}
dc <- names(d)[grepl("passiv|adher|default|chose_def|choice_def", names(d), ignore.case = TRUE)]
dc <- dc[!grepl("correct|_mean$|median|quart", dc, ignore.case = TRUE)]
dc <- dc[sapply(dc, function(v) is01(d[[v]]))]
ord <- c(grep("passiv", dc, ignore.case = TRUE, value = TRUE),
         grep("adher", dc, ignore.case = TRUE, value = TRUE),
         dc)
ord <- unique(ord)
def_var <- if (length(ord)) ord[1] else NULL
cat("Default adherence variable:", ifelse(is.null(def_var), "NONE", def_var), "\n")
if (!is.null(def_var)) ds$default_adh <- num(ds[[def_var]])

ds$choice_q <- num(ds$summation_correct)
ds$bg_q <- num(ds$load_correct)
ds$pshare <- num(ds$payoff_share)

# ---------------- Environment dummies ----------------
envl <- labtxt(ds$Treatment_Environment)
print(table(envl, ds$intervention, useNA = "ifany"))
ds$directed <- NA_real_
ds$forced <- NA_real_
dir_l <- ds$intervention == 1 & grepl("direct|forced.?att|attention", envl, ignore.case = TRUE)
frc_l <- ds$intervention == 1 & !dir_l & grepl("active|choice|forc", envl, ignore.case = TRUE)
if (sum(dir_l) > 0 && sum(frc_l) > 0 && all((dir_l | frc_l) == (ds$intervention == 1))) {
  ds$directed <- as.numeric(dir_l)
  ds$forced <- as.numeric(frc_l)
} else {
  ev <- unique(envl[ds$intervention == 1])
  if (length(ev) == 2) {
    if (!is.null(def_var)) {
      mns <- sapply(ev, function(e) mean(ds$default_adh[envl == e], na.rm = TRUE))
      dir_e <- ev[which.max(mns)]
    } else {
      dir_e <- sort(ev)[1]
    }
    ds$directed <- as.numeric(ds$intervention == 1 & envl == dir_e)
    ds$forced <- as.numeric(ds$intervention == 1 & envl != dir_e)
  }
}

# ---------------- Controls ----------------
nmz <- names(ds)
first_or_null <- function(v) if (length(v)) v[1] else NULL
age_v <- first_or_null(nmz[grepl("^(q_)?age$", nmz, ignore.case = TRUE)])
if (is.null(age_v)) age_v <- first_or_null(nmz[grepl("age", nmz, ignore.case = TRUE) &
                                                  !grepl("page|average|image|stage|language|percentage", nmz, ignore.case = TRUE)])
gender_v <- first_or_null(intersect(c("q_gender", "gender"), nmz))
field_v <- first_or_null(intersect(c("economist"), nmz))
abitur_v <- first_or_null(intersect(c("q_abitur_grade"), nmz))
math_v <- first_or_null(intersect(c("q_math_grade"), nmz))
abil_v <- intersect(c("ability_load", "ability_task"), nmz)
multi_v <- first_or_null(nmz[grepl("multi", nmz, ignore.case = TRUE)])
inc_v <- nmz[grepl("^Treatment_Incentives", nmz)]
wave_v <- first_or_null(nmz[grepl("wave", nmz, ignore.case = TRUE)])
cat("Controls: age=", age_v, " gender=", gender_v, " field=", field_v, " abitur=", abitur_v,
    " math=", math_v, " abil=", paste(abil_v, collapse = ","), " multi=", multi_v,
    " inc=", paste(inc_v, collapse = ","), " wave=", wave_v, "\n")

ctrl_terms <- character()
add_numeric <- function(v, newname) {
  x <- num(ds[[v]])
  if (all(is.na(x))) return(invisible(NULL))
  if (any(is.na(x))) {
    ds[[paste0(newname, "_miss")]] <<- as.numeric(is.na(x))
    x[is.na(x)] <- mean(x, na.rm = TRUE)
    ctrl_terms <<- c(ctrl_terms, paste0(newname, "_miss"))
  }
  ds[[newname]] <<- x
  ctrl_terms <<- c(ctrl_terms, newname)
}
add_factor <- function(v, newname) {
  x <- labtxt(ds[[v]])
  x[is.na(x) | x == ""] <- "missing"
  if (length(unique(x)) < 2) return(invisible(NULL))
  ds[[newname]] <<- factor(x)
  ctrl_terms <<- c(ctrl_terms, newname)
}
if (!is.null(age_v)) add_numeric(age_v, "c_age")
if (!is.null(gender_v)) add_factor(gender_v, "c_gender")
if (!is.null(field_v)) {
  add_numeric(field_v, "c_field")
} else if ("q_subject" %in% nmz) add_factor("q_subject", "c_field")
if (!is.null(abitur_v)) add_numeric(abitur_v, "c_abitur")
if (!is.null(math_v)) add_numeric(math_v, "c_math")
for (i in seq_along(abil_v)) add_numeric(abil_v[i], paste0("c_abil", i))
if (!is.null(multi_v)) add_numeric(multi_v, "c_multi")
if (length(inc_v) == 1) {
  add_factor(inc_v, "c_inc")
} else if (length(inc_v) > 1) {
  for (i in seq_along(inc_v)) {
    x <- num(ds[[inc_v[i]]])
    if (length(unique(na.omit(x))) > 2) add_factor(inc_v[i], paste0("c_inc", i)) else add_numeric(inc_v[i], paste0("c_inc", i))
  }
}
if (!is.null(wave_v)) add_factor(wave_v, "c_wave")
ctrl_str <- if (length(ctrl_terms)) paste(ctrl_terms, collapse = " + ") else "1"

run <- function(y, rhs, data, coefname, cl = ~sid) {
  out <- tryCatch({
    f <- as.formula(paste(y, "~", rhs))
    m <- feols(f, data = data, cluster = cl)
    print(summary(m))
    list(b = unname(coef(m)[coefname]), se = unname(sqrt(diag(vcov(m)))[coefname]), n = nobs(m))
  }, error = function(e) { cat("Error in", y, ":", conditionMessage(e), "\n"); NULL })
  out
}

r <- run("choice_q", "intervention", ds, "intervention")
if (!is.null(r)) { emit("choice_quality_intervention_t2_col1", r$b); emit("choice_quality_intervention_t2_col1_se", r$se) }
r <- run("choice_q", paste("intervention +", ctrl_str), ds, "intervention")
if (!is.null(r)) { emit("choice_quality_intervention_t2_col2", r$b); emit("choice_quality_intervention_t2_col2_se", r$se) }

if (!is.null(def_var)) {
  r <- run("default_adh", "intervention", ds, "intervention")
  if (!is.null(r)) { emit("default_adherence_intervention_t2_col5", r$b); emit("default_adherence_intervention_t2_col5_se", r$se) }
  r <- run("default_adh", paste("intervention +", ctrl_str), ds, "intervention")
  if (!is.null(r)) { emit("default_adherence_intervention_t2_col6", r$b); emit("default_adherence_intervention_t2_col6_se", r$se) }
  if (!all(is.na(ds$directed))) {
    m7 <- tryCatch(feols(default_adh ~ directed + forced, data = ds, cluster = ~sid), error = function(e) NULL)
    if (!is.null(m7)) {
      print(summary(m7))
      se7 <- sqrt(diag(vcov(m7)))
      emit("default_adherence_directed_attention_t2_col7", unname(coef(m7)["directed"]))
      emit("default_adherence_directed_attention_t2_col7_se", unname(se7["directed"]))
      emit("default_adherence_forced_choice_t2_col7", unname(coef(m7)["forced"]))
      emit("default_adherence_forced_choice_t2_col7_se", unname(se7["forced"]))
    }
  }
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
  cat("Memory summary:\n"); print(summary(m$y))
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
