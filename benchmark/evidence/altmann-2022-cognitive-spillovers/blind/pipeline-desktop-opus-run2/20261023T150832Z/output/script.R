suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/altmann_2022_cognitive_spillovers.script-free/ReplicationPackage/EmpiricalAnalysis/original_data/"
d <- read_dta(file.path(base_dir, "formatted_data_replication.dta"))
d <- as.data.frame(d)
nm <- names(d)
cat("Columns:", paste(nm, collapse = ", "), "\n")

lab_of <- function(x) {
  if (inherits(x, "haven_labelled")) as.character(as_factor(x, levels = "labels")) else as.character(x)
}
has_labels <- function(x) !is.null(attr(x, "labels"))
num_of <- function(x) as.numeric(zap_labels(x))

for (v in nm) {
  if (has_labels(d[[v]])) {
    labs <- attr(d[[v]], "labels")
    cat("Labels of", v, ":", paste(paste0(labs, "=", names(labs)), collapse = "; "), "\n")
  }
}

# ---------------- subject id ----------------
sid_col <- NULL
for (c in c("subject_id", "participant_id", "participant_code", "participant__code", "id_subject",
            "subject", "Subject", "id", "ID", "participant", "code", "player_id", "unique_id", "subj")) {
  if (c %in% nm) { sid_col <- c; break }
}
if (is.null(sid_col)) {
  cc <- nm[grepl("subj|partic|^id|_id$|code", nm, ignore.case = TRUE) & !grepl("q_subject", nm)]
  for (c in cc) {
    tb <- table(d[[c]])
    if (length(tb) > 100 && length(tb) >= nrow(d) / 40) { sid_col <- c; break }
  }
}
if (is.null(sid_col)) {
  for (c in nm) {
    tb <- table(d[[c]])
    if (length(tb) == nrow(d) / 20 && all(tb == 20)) { sid_col <- c; break }
  }
}
cat("Subject id column:", sid_col, "\n")
d$sid <- as.character(lab_of(d[[sid_col]]))

# ---------------- scarce indicator ----------------
scarce <- NULL
# 1) any labelled column whose labels mention scarce/ample
for (v in nm) {
  if (v %in% c("load_correct", "ability_load")) next
  if (has_labels(d[[v]])) {
    labs <- tolower(names(attr(d[[v]], "labels")))
    if (any(grepl("scarce|ample", labs))) {
      l <- tolower(lab_of(d[[v]]))
      if (any(grepl("ample", l)) && any(grepl("scarce", l))) {
        scarce <- grepl("scarce", l)
        cat("Scarce from labels of", v, "\n")
        break
      }
    }
  }
}
# 2) columns named after load / resources
if (is.null(scarce)) {
  cand <- nm[grepl("scarc|ample|resourc|cognitive|load_treat|treatment_load|high_load|^load$|loadtreat|low_load|digit|^high_load|load_condition|load_level",
                   nm, ignore.case = TRUE)]
  cand <- setdiff(cand, c("load_correct", "ability_load"))
  for (v in cand) {
    x <- d[[v]]
    l <- tolower(lab_of(x))
    if (any(grepl("scarce|high", l)) && any(grepl("ample|low", l))) {
      scarce <- grepl("scarce|high", l); cat("Scarce from", v, "(labels)\n"); break
    }
    xn <- suppressWarnings(num_of(x))
    u <- sort(unique(xn[!is.na(xn)]))
    if (length(u) == 2) {
      if (grepl("ample|low", v, ignore.case = TRUE)) scarce <- xn == min(u) else scarce <- xn == max(u)
      cat("Scarce from", v, "(binary)\n"); break
    }
  }
}
# 3) Environment labels mentioning high/low
if (is.null(scarce) && "Treatment_Environment" %in% nm) {
  l <- tolower(lab_of(d$Treatment_Environment))
  if (any(grepl("high|scarce", l)) && any(grepl("low|ample", l))) {
    scarce <- grepl("high|scarce", l); cat("Scarce from Treatment_Environment\n")
  }
}
# 4) Intervention missing for ample subjects
if (is.null(scarce) && "Treatment_intervention" %in% nm) {
  ti <- num_of(d$Treatment_intervention)
  if (any(is.na(ti)) && any(!is.na(ti))) { scarce <- !is.na(ti); cat("Scarce = non-missing Treatment_intervention\n") }
}
if (is.null(scarce)) {
  scarce <- rep(TRUE, nrow(d))
  cat("DEVIATION: could not identify scarce indicator; using all observations\n")
}
scarce[is.na(scarce)] <- FALSE
cat("Scarce rows:", sum(scarce), "of", nrow(d), "\n")

# ---------------- environment ----------------
env_raw <- d$Treatment_Environment
env_l <- tolower(lab_of(env_raw))
cat("Environment values:\n"); print(table(env_l, scarce, useNA = "ifany"))
is_base <- grepl("base", env_l)
is_dir <- grepl("direct|attention", env_l) & !grepl("choice|active", env_l) & !is_base
is_forced <- grepl("choice|active", env_l) & !is_base
if (!(any(is_base) && any(is_dir) && any(is_forced))) {
  en <- num_of(env_raw)
  u <- sort(unique(en[!is.na(en)]))
  cat("DEVIATION: environment labels not recognised; mapping sorted codes to Baseline/Directed/Forced\n")
  is_base <- en == u[1]; is_dir <- en == u[2]; is_forced <- en == u[3]
}
d$directed <- as.numeric(is_dir)
d$forced <- as.numeric(is_forced)
d$env_ok <- (is_base | is_dir | is_forced) & !is.na(env_raw)

# intervention
interv_env <- as.numeric(is_dir | is_forced)
if ("Treatment_intervention" %in% nm) {
  ti <- num_of(d$Treatment_intervention)
  u <- sort(unique(ti[scarce & !is.na(ti)]))
  if (length(u) == 2 && all(u %in% c(0, 1))) {
    d$interv <- ti
    agree <- mean(ti[scarce & d$env_ok] == interv_env[scarce & d$env_ok], na.rm = TRUE)
    cat("Agreement Treatment_intervention vs environment:", agree, "\n")
    if (agree < 0.99) d$interv <- interv_env
  } else d$interv <- interv_env
} else d$interv <- interv_env

# ---------------- outcomes ----------------
d$quality <- num_of(d$summation_correct)
d$background <- num_of(d$load_correct)
d$pshare <- num_of(d$payoff_share)

def_col <- NULL
for (c in c("default_choice", "passive_choice", "chose_default", "choice_default", "default_adherence",
            "passive", "Passive", "passivity", "default", "Default", "default_chosen", "stick_default",
            "choice_is_default", "default_option")) {
  if (c %in% nm) { def_col <- c; break }
}
if (is.null(def_col)) {
  cc <- nm[grepl("passiv|adher|default", nm, ignore.case = TRUE) &
             !grepl("correct|incorrect|wrong|treatment", nm, ignore.case = TRUE)]
  for (c in cc) {
    x <- num_of(d[[c]]); u <- unique(x[!is.na(x)])
    if (length(u) == 2 && all(u %in% c(0, 1))) { def_col <- c; break }
  }
}
if (!is.null(def_col)) {
  d$def_adh <- num_of(d[[def_col]])
} else if (all(c("default_correct_choice", "default_incorrect_choice") %in% nm)) {
  a <- num_of(d$default_correct_choice); b <- num_of(d$default_incorrect_choice)
  d$def_adh <- ifelse(!is.na(a), a, b); def_col <- "default_correct_choice+default_incorrect_choice"
} else {
  cc <- nm[grepl("passiv|adher|default", nm, ignore.case = TRUE)]
  def_col <- cc[1]
  d$def_adh <- num_of(d[[def_col]])
  cat("DEVIATION: default adherence variable uncertain\n")
}
cat("Default adherence column:", def_col, "\n")

# ---------------- controls ----------------
ctrl_terms <- c()
pick <- function(pats) {
  for (p in pats) {
    m <- nm[grepl(p, nm, ignore.case = TRUE)]
    if (length(m) > 0) return(m[1])
  }
  NULL
}
age_c <- pick(c("^q_age$", "^age$", "(^|_)age($|_)"))
gen_c <- pick(c("^q_gender$", "gender", "female", "^male$"))
fld_c <- pick(c("^q_subject$", "field", "study"))
abi_c <- pick(c("^q_abitur_grade$", "abitur", "gpa"))
mat_c <- pick(c("^q_math_grade$", "math_grade"))
abl_c <- if ("ability_load" %in% nm) "ability_load" else NULL
abt_c <- if ("ability_task" %in% nm) "ability_task" else NULL
mul_c <- pick(c("multi"))
inc_c <- if ("Treatment_Incentives" %in% nm) "Treatment_Incentives" else pick(c("incentive", "payoff_scheme"))
wav_c <- pick(c("wave"))
cat("Controls found: age=", age_c, " gender=", gen_c, " field=", fld_c, " abitur=", abi_c,
    " math=", mat_c, " ab_load=", abl_c, " ab_task=", abt_c, " multitask=", mul_c,
    " incentives=", inc_c, " wave=", wav_c, "\n")

S <- d[scarce & d$env_ok, , drop = FALSE]
cat("Scarce sample: rows", nrow(S), " subjects", length(unique(S$sid)), "\n")

add_num <- function(col, newname) {
  if (is.null(col)) return(NULL)
  x <- num_of(S[[col]])
  if (length(unique(x[!is.na(x)])) < 2) return(NULL)
  S[[newname]] <<- x
  newname
}
add_fac <- function(col, newname) {
  if (is.null(col)) return(NULL)
  x <- lab_of(S[[col]])
  if (length(unique(x[!is.na(x)])) < 2) return(NULL)
  S[[newname]] <<- factor(x)
  paste0("factor(", newname, ")")
}
ctrl_terms <- c(ctrl_terms, add_num(age_c, "c_age"))
ctrl_terms <- c(ctrl_terms, add_fac(gen_c, "c_gender"))
if (!is.null(fld_c)) {
  nlev <- length(unique(S[[fld_c]][!is.na(S[[fld_c]])]))
  if (nlev > 40 && "economist" %in% nm) ctrl_terms <- c(ctrl_terms, add_num("economist", "c_econ"))
  else ctrl_terms <- c(ctrl_terms, add_fac(fld_c, "c_field"))
} else if ("economist" %in% nm) ctrl_terms <- c(ctrl_terms, add_num("economist", "c_econ"))
ctrl_terms <- c(ctrl_terms, add_num(abi_c, "c_abitur"))
ctrl_terms <- c(ctrl_terms, add_num(mat_c, "c_math"))
ctrl_terms <- c(ctrl_terms, add_num(abl_c, "c_abload"))
ctrl_terms <- c(ctrl_terms, add_num(abt_c, "c_abtask"))
ctrl_terms <- c(ctrl_terms, add_num(mul_c, "c_multi"))
ctrl_terms <- c(ctrl_terms, add_fac(inc_c, "c_incent"))
ctrl_terms <- c(ctrl_terms, add_fac(wav_c, "c_wave"))
ctrl_str <- paste(ctrl_terms, collapse = " + ")
cat("Control formula:", ctrl_str, "\n")

run <- function(y, rhs, data) {
  f <- as.formula(paste(y, "~", rhs))
  feols(f, data = data, cluster = ~sid)
}
getc <- function(m, v) unname(coef(m)[v])

m1 <- run("quality", "interv", S)
m2 <- run("quality", paste("interv +", ctrl_str), S)
m5 <- run("def_adh", "interv", S)
m6 <- run("def_adh", paste("interv +", ctrl_str), S)
m7 <- run("def_adh", "directed + forced", S)
b1 <- run("background", "interv", S)
b2 <- run("background", paste("interv +", ctrl_str), S)
p1 <- run("pshare", "interv", S)

for (m in list(m1, m2, m5, m6, m7, b1, b2, p1)) print(summary(m))

n_obs <- nobs(m1)
n_subj <- length(unique(S$sid[!is.na(S$quality) & !is.na(S$interv)]))

# ---------------- online experiment ----------------
o <- as.data.frame(read_dta(file.path(base_dir, "formatted_data_long_mturk.dta")))
o$mem <- num_of(o$memory)
o$interv <- num_of(o$Treatment_intervention)
o$sid <- as.character(lab_of(o$subject_id))
o$c_age <- num_of(o$age)
o$c_gender <- factor(lab_of(o$gender))
o$c_h <- num_of(o$window_height1)
o$c_w <- num_of(o$window_width1)
cat("Online memory summary:\n"); print(summary(o$mem))
o5 <- feols(mem ~ interv, data = o, cluster = ~sid)
o6 <- feols(mem ~ interv + c_age + c_gender + c_h + c_w, data = o, cluster = ~sid)
print(summary(o5)); print(summary(o6))

cat(sprintf("RESULT:choice_quality_intervention_t2_col1=%.6f\n", getc(m1, "interv")))
cat(sprintf("RESULT:choice_quality_intervention_t2_col2=%.6f\n", getc(m2, "interv")))
cat(sprintf("RESULT:default_adherence_intervention_t2_col5=%.6f\n", getc(m5, "interv")))
cat(sprintf("RESULT:default_adherence_intervention_t2_col6=%.6f\n", getc(m6, "interv")))
cat(sprintf("RESULT:default_adherence_directed_attention_t2_col7=%.6f\n", getc(m7, "directed")))
cat(sprintf("RESULT:default_adherence_forced_choice_t2_col7=%.6f\n", getc(m7, "forced")))
cat(sprintf("RESULT:background_quality_intervention_lab_t3_col1=%.6f\n", getc(b1, "interv")))
cat(sprintf("RESULT:background_quality_intervention_lab_t3_col2=%.6f\n", getc(b2, "interv")))
cat(sprintf("RESULT:memory_intervention_online_t3_col5=%.6f\n", getc(o5, "interv")))
cat(sprintf("RESULT:payoff_share_intervention_t4_col1=%.6f\n", getc(p1, "interv")))
cat(sprintf("RESULT:n_obs_lab_tables_2_to_4=%d\n", as.integer(n_obs)))
cat(sprintf("RESULT:n_subjects_lab_tables_2_to_4=%d\n", as.integer(n_subj)))
cat(sprintf("RESULT:memory_intervention_online_t3_col6=%.6f\n", getc(o6, "interv")))