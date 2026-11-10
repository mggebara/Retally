suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/corno_2022_interaction_stereotypes_performance.script-free"
f_bal <- file.path(base_dir, "ForJournals_a/Data/Clean/uctdata_balanced.dta")
f_cln <- file.path(base_dir, "ForJournals_a/Data/Clean/uctdata_clean.dta")

clean_df <- function(d) {
  d <- haven::zap_labels(d)
  d <- haven::zap_formats(d)
  as.data.frame(d, stringsAsFactors = FALSE)
}

raw <- clean_df(haven::read_dta(f_bal))
cat("Balanced file:", nrow(raw), "rows,", ncol(raw), "cols\n")
cat("Columns:", paste(names(raw), collapse = ", "), "\n")

find_var <- function(d, cands) {
  nm <- names(d)
  for (cc in cands) {
    if (cc %in% nm) return(cc)
  }
  low <- tolower(nm)
  for (cc in cands) {
    i <- which(low == tolower(cc))
    if (length(i) > 0) return(nm[i[1]])
  }
  NA_character_
}

id_var <- find_var(raw, c("nstudent", "id", "student_id"))

# ---- Pick follow-up observation per student -------------------------------
round_var <- find_var(raw, c("round", "Round", "wave", "survey_round", "followup", "time"))
dat <- raw
if (!is.na(round_var) && length(unique(na.omit(raw[[round_var]]))) > 1) {
  mx <- max(raw[[round_var]], na.rm = TRUE)
  dat <- raw[!is.na(raw[[round_var]]) & raw[[round_var]] == mx, , drop = FALSE]
  cat("Using round variable", round_var, "= ", mx, "\n")
} else if (!is.na(id_var) && any(duplicated(raw[[id_var]]))) {
  raw$.rowid <- seq_len(nrow(raw))
  ib <- find_var(raw, c("DscoreraceIATbas"))
  ic <- find_var(raw, c("DscoreraceIAT"))
  pick <- raw %>% group_by(.data[[id_var]]) %>%
    mutate(.n = n(),
           .isbase = if (!is.na(ib) && !is.na(ic)) (!is.na(.data[[ic]]) & !is.na(.data[[ib]]) & abs(.data[[ic]] - .data[[ib]]) < 1e-10) else FALSE,
           .nb = sum(.isbase)) %>%
    ungroup()
  keep <- with(pick, ifelse(.n == 1, TRUE, ifelse(.nb == 1, !.isbase, FALSE)))
  pick$.keep <- keep
  pick <- pick %>% group_by(.data[[id_var]]) %>%
    mutate(.keep = if (sum(.keep) == 1) .keep else (.rowid == max(.rowid))) %>% ungroup()
  dat <- as.data.frame(pick[pick$.keep, , drop = FALSE])
  cat("Deduplicated by id (no round var):", nrow(dat), "rows\n")
}
cat("Analysis rows:", nrow(dat), "\n")

# ---- Merge missing variables from clean file if needed -------------------
need_from_clean <- function(vars) {
  miss <- vars[!(vars %in% names(dat))]
  if (length(miss) == 0 || is.na(id_var)) return(invisible(NULL))
  cl <- tryCatch(clean_df(haven::read_dta(f_cln)), error = function(e) NULL)
  if (is.null(cl) || !(id_var %in% names(cl))) return(invisible(NULL))
  miss <- miss[miss %in% names(cl)]
  if (length(miss) == 0) return(invisible(NULL))
  cl2 <- cl[, c(id_var, miss), drop = FALSE]
  cl2 <- cl2 %>% group_by(.data[[id_var]]) %>%
    summarise(across(all_of(miss), ~ { x <- .x[!is.na(.x)]; if (length(x)) x[1] else .x[1] }), .groups = "drop")
  dat <<- left_join(dat, as.data.frame(cl2), by = id_var)
  cat("Merged from clean file:", paste(miss, collapse = ", "), "\n")
}

# ---- Key variables -------------------------------------------------------
treat <- find_var(dat, c("mixracebas", "MixRoom", "mixroom", "mixrace"))
y_race <- find_var(dat, c("DscoreraceIAT_fu", "DscoreraceIAT"))
y_race_b <- find_var(dat, c("DscoreraceIATbas", "DscoreraceIAT_bas"))
y_aca <- find_var(dat, c("DscoreacaIAT_fu", "DscoreacaIAT"))
y_aca_b <- find_var(dat, c("DscoreacaIATbas", "DscoreacaIAT_bas"))
y_exam <- find_var(dat, c("examspassed", "examspassed_fu", "examspassed2012"))
y_cont <- find_var(dat, c("continue", "continue_fu", "continue2012"))
y_pca <- find_var(dat, c("PCAperf", "PCAperf_fu", "pcaperf"))
gpa_c <- grep("^gpa", names(dat), ignore.case = TRUE, value = TRUE)
gpa_c <- gpa_c[!grepl("2013|_miss|missing|yr2|fwer", gpa_c, ignore.case = TRUE)]
y_gpa <- if (length(gpa_c)) gpa_c[1] else NA_character_
if (is.na(y_gpa)) {
  need_from_clean(c("GPA", "GPA2012", "gpa"))
  y_gpa <- find_var(dat, c("GPA2012", "GPA", "gpa", "GPA_fu"))
}
cat("Treatment:", treat, " GPA:", y_gpa, " exams:", y_exam, " continue:", y_cont, " index:", y_pca, "\n")

prog <- find_var(dat, c("regprog", "program", "programme", "prog", "Program", "acadprog", "Faculty"))
if (is.na(prog) || prog == "Faculty") {
  need_from_clean(c("regprog"))
  p2 <- find_var(dat, c("regprog"))
  if (!is.na(p2)) prog <- p2
}
res <- find_var(dat, c("Res_base", "res_base", "residence"))
cat("Program FE:", prog, " Residence:", res, "\n")

room <- find_var(dat, c("roomnum_base", "room_base", "roomid", "room_id", "room", "roomnum", "Room_base", "room_num"))
if (is.na(room)) {
  rc <- grep("room", names(dat), ignore.case = TRUE, value = TRUE)
  rc <- rc[!grepl("mix|same|study|roommate|ro_", rc, ignore.case = TRUE)]
  if (length(rc)) room <- rc[1]
}
if (!is.na(room) && !is.na(res)) {
  dat$.cluster <- paste(dat[[res]], dat[[room]], sep = "_")
  dat$.cluster[is.na(dat[[room]])] <- paste0("single_", which(is.na(dat[[room]])))
} else if (!is.na(id_var)) {
  dat$.cluster <- dat[[id_var]]
} else {
  dat$.cluster <- seq_len(nrow(dat))
}
cat("Cluster var:", room, " n clusters:", length(unique(dat$.cluster)), "\n")

# ---- Race --------------------------------------------------------------
v_white <- find_var(dat, c("white"))
v_black <- find_var(dat, c("black"))
v_col <- find_var(dat, c("coloured"))
v_else <- find_var(dat, c("Else", "else", "other"))
dat$.white <- as.numeric(dat[[v_white]] == 1)
dat$.black <- as.numeric(dat[[v_black]] == 1)
dat$.white[is.na(dat$.white)] <- 0
dat$.black[is.na(dat$.black)] <- 0
dat$.coloured <- if (!is.na(v_col)) as.numeric(dat[[v_col]] %in% 1) else 0
dat$.else <- if (!is.na(v_else)) as.numeric(dat[[v_else]] %in% 1) else 0
dat$.rg <- ifelse(dat$.black == 1, "B", ifelse(dat$.white == 1, "W", "O"))

# ---- Working sample: non-missing Race and Academic IAT ---------------------
ok <- !is.na(dat[[treat]])
if (!is.na(y_race)) ok <- ok & !is.na(dat[[y_race]])
if (!is.na(y_aca)) ok <- ok & !is.na(dat[[y_aca]])
if (!is.na(y_race_b)) ok <- ok & !is.na(dat[[y_race_b]])
if (!is.na(y_aca_b)) ok <- ok & !is.na(dat[[y_aca_b]])
if (sum(ok) >= 400) dat <- dat[ok, , drop = FALSE] else dat <- dat[!is.na(dat[[treat]]), , drop = FALSE]
cat("Working sample:", nrow(dat), " whites:", sum(dat$.white), " blacks:", sum(dat$.black), "\n")

# ---- Controls -----------------------------------------------------------
own_c <- c(
  find_var(dat, c("Female", "female")),
  find_var(dat, c("Falseuct2012", "falseuct2012", "uct2012")),
  find_var(dat, c("durpcabas_nomiss", "durpcabas")),
  find_var(dat, c("consbas_nomiss", "consbas")),
  find_var(dat, c("Foreign", "foreign")),
  find_var(dat, c("privschool_nomiss", "privateschool_nomiss", "privschool", "privateschool"))
)
ro_c <- c(
  find_var(dat, c("roFalseuct2012", "rofalseuct2012")),
  find_var(dat, c("rodurpcabas_nomiss", "rodurpcabas")),
  find_var(dat, c("roconsbas_nomiss", "roconsbas")),
  find_var(dat, c("roForeign", "roforeign")),
  find_var(dat, c("roprivschool_nomiss", "roprivateschool_nomiss", "roprivschool", "roprivateschool"))
)
own_c <- own_c[!is.na(own_c)]
ro_c <- ro_c[!is.na(ro_c)]

miss_d <- grep("(_miss$|_missing$|^miss|^romiss|_miss_)", names(dat), ignore.case = TRUE, value = TRUE)
miss_d <- miss_d[!grepl("IAT|GPA|exam|continue|PCA|fwer|sim", miss_d, ignore.case = TRUE)]
miss_d <- miss_d[sapply(miss_d, function(v) is.numeric(dat[[v]]) && length(unique(na.omit(dat[[v]]))) > 1)]

ctrls <- c(own_c, ro_c)
for (v in ctrls) {
  dat[[v]] <- suppressWarnings(as.numeric(dat[[v]]))
  if (any(is.na(dat[[v]]))) {
    mi <- paste0(v, "_mimp")
    dat[[mi]] <- as.numeric(is.na(dat[[v]]))
    dat[[v]][is.na(dat[[v]])] <- mean(dat[[v]], na.rm = TRUE)
    miss_d <- c(miss_d, mi)
  }
}
for (v in miss_d) dat[[v]][is.na(dat[[v]])] <- 0
miss_d <- unique(miss_d)
cat("Own controls:", paste(own_c, collapse = ","), "\n")
cat("Roommate controls:", paste(ro_c, collapse = ","), "\n")
cat("Missing dummies:", paste(miss_d, collapse = ","), "\n")
all_ctrls <- unique(c(ctrls, miss_d))

# ---- Outcomes prep -----------------------------------------------------
if (!is.na(y_cont)) {
  cv <- dat[[y_cont]]
  u <- sort(unique(na.omit(cv)))
  if (length(u) == 2 && !all(u == c(0, 1))) dat[[y_cont]] <- as.numeric(cv == max(u))
}
if (!is.na(y_gpa)) {
  g <- dat[[y_gpa]]
  if (!(abs(mean(g, na.rm = TRUE)) < 0.15 && abs(sd(g, na.rm = TRUE) - 1) < 0.15)) {
    dat[[y_gpa]] <- (g - mean(g, na.rm = TRUE)) / sd(g, na.rm = TRUE)
  }
}
if (is.na(y_pca) && !is.na(y_gpa) && !is.na(y_exam) && !is.na(y_cont)) {
  cc <- complete.cases(dat[, c(y_gpa, y_exam, y_cont)])
  pc <- prcomp(dat[cc, c(y_gpa, y_exam, y_cont)], scale. = TRUE)
  s <- pc$x[, 1]
  if (cor(s, dat[cc, y_gpa]) < 0) s <- -s
  dat$.pcaperf <- NA_real_
  dat$.pcaperf[cc] <- s
  y_pca <- ".pcaperf"
}

dat$.res <- as.character(dat[[res]])
dat$.prog <- if (!is.na(prog)) as.character(dat[[prog]]) else "1"
dat$.prog[is.na(dat$.prog)] <- "missing"

# ---- Estimation helpers ------------------------------------------------
run_reg <- function(y, d, lag = NULL, ctr, fe) {
  if (is.na(y)) return(NULL)
  rhs <- c(treat, lag, ctr)
  fml <- as.formula(paste0("`", y, "` ~ ", paste0("`", rhs, "`", collapse = " + "), " | ", fe))
  tryCatch(feols(fml, data = d, cluster = ~.cluster), error = function(e) { cat("ERR", y, conditionMessage(e), "\n"); NULL })
}
getb <- function(m) if (is.null(m)) NA_real_ else unname(coef(m)[treat])
getse <- function(m) if (is.null(m)) NA_real_ else unname(sqrt(diag(vcov(m)))[treat])

ctr_t3 <- setdiff(all_ctrls, character(0))
dw <- dat[dat$.white == 1, , drop = FALSE]
db <- dat[dat$.black == 1, , drop = FALSE]

# Table 3
m3w <- run_reg(y_race, dw, y_race_b, ctr_t3, ".res")
m3b <- run_reg(y_race, db, y_race_b, ctr_t3, ".res")
m3wa <- run_reg(y_aca, dw, y_aca_b, ctr_t3, ".res")
m3ba <- run_reg(y_aca, db, y_aca_b, ctr_t3, ".res")

# Table 4 subsamples
fe_sub <- ".res + .prog"
m4b <- lapply(c(y_gpa, y_exam, y_cont, y_pca), function(y) run_reg(y, db, NULL, all_ctrls, fe_sub))
m4w <- run_reg(y_gpa, dw, NULL, all_ctrls, fe_sub)

# Table 4 full sample
ctr_full <- c(".white", ".coloured", ".else", all_ctrls)
fe_full <- ".rg^.res + .prog"
m4f <- lapply(c(y_gpa, y_exam, y_cont, y_pca), function(y) run_reg(y, dat, NULL, ctr_full, fe_full))

for (m in c(list(m3w, m3b), m4b, list(m4w), m4f)) if (!is.null(m)) print(coeftable(m)[treat, , drop = FALSE])

res_out <- c(
  race_iat_mixed_room_whites_table3_col1 = getb(m3w),
  race_iat_mixed_room_whites_table3_col1_se = getse(m3w),
  race_iat_mixed_room_blacks_table3_col2 = getb(m3b),
  race_iat_mixed_room_blacks_table3_col2_se = getse(m3b),
  n_obs_table3_whites = if (!is.null(m3w)) nobs(m3w) else sum(dat$.white),
  n_obs_table3_blacks = if (!is.null(m3b)) nobs(m3b) else sum(dat$.black),
  gpa_mixed_room_blacks_table4_panelB_col1 = getb(m4b[[1]]),
  gpa_mixed_room_blacks_table4_panelB_col1_se = getse(m4b[[1]]),
  exams_passed_mixed_room_blacks_table4_panelB_col2 = getb(m4b[[2]]),
  exams_passed_mixed_room_blacks_table4_panelB_col2_se = getse(m4b[[2]]),
  eligible_mixed_room_blacks_table4_panelB_col3 = getb(m4b[[3]]),
  eligible_mixed_room_blacks_table4_panelB_col3_se = getse(m4b[[3]]),
  performance_index_mixed_room_blacks_table4_panelB_col4 = getb(m4b[[4]]),
  performance_index_mixed_room_blacks_table4_panelB_col4_se = getse(m4b[[4]]),
  gpa_mixed_room_whites_table4_panelA_col1 = getb(m4w),
  gpa_mixed_room_whites_table4_panelA_col1_se = getse(m4w),
  gpa_mixed_room_full_table4_panelC_col1 = getb(m4f[[1]]),
  gpa_mixed_room_full_table4_panelC_col1_se = getse(m4f[[1]]),
  exams_passed_mixed_room_full_table4_panelC_col2 = getb(m4f[[2]]),
  exams_passed_mixed_room_full_table4_panelC_col2_se = getse(m4f[[2]]),
  performance_index_mixed_room_full_table4_panelC_col4 = getb(m4f[[4]]),
  performance_index_mixed_room_full_table4_panelC_col4_se = getse(m4f[[4]]),
  n_obs_table4_panelC_cols1_2 = if (!is.null(m4f[[1]])) nobs(m4f[[1]]) else nrow(dat)
)

for (nm in names(res_out)) cat(sprintf("RESULT:%s=%.6f\n", nm, res_out[[nm]]))
