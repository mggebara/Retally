suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/corno_2022_interaction_stereotypes_performance.script-free"
raw <- haven::read_dta(file.path(base_dir, "ForJournals_a/Data/Clean/uctdata_balanced.dta"))
raw <- haven::zap_labels(raw)
raw <- as.data.frame(raw)

cat("Columns:\n"); print(names(raw))

nm <- names(raw)
pick <- function(cands, required = FALSE) {
  for (c in cands) {
    if (c %in% nm) return(c)
  }
  # case-insensitive fallback
  for (c in cands) {
    hit <- nm[tolower(nm) == tolower(c)]
    if (length(hit) > 0) return(hit[1])
  }
  if (required) stop(paste("None of the columns found:", paste(cands, collapse = ", ")))
  NA_character_
}

# ---------------------------------------------------------------
# Keep one row per student: the follow-up round
# ---------------------------------------------------------------
round_var <- pick(c("round", "Round", "wave", "survey_round"))
id_var <- pick(c("nstudent", "id", "studentid"))
if (!is.na(round_var)) {
  cat("Round values:\n"); print(table(raw[[round_var]], useNA = "ifany"))
  fu_val <- max(raw[[round_var]], na.rm = TRUE)
  df <- raw[!is.na(raw[[round_var]]) & raw[[round_var]] == fu_val, ]
} else if (!is.na(id_var) && any(duplicated(raw[[id_var]]))) {
  df <- raw %>% group_by(.data[[id_var]]) %>% slice_tail(n = 1) %>% ungroup() %>% as.data.frame()
} else {
  df <- raw
}
cat("Rows after selecting follow-up:", nrow(df), "\n")

# ---------------------------------------------------------------
# Key variables
# ---------------------------------------------------------------
treat_var <- pick(c("mixracebas", "MixRoom", "mixroom"), required = TRUE)
res_var <- pick(c("Res_base", "res_base", "residence"), required = TRUE)
race_var <- pick(c("Race", "race"))
white_var <- pick(c("white", "White"))
black_var <- pick(c("black", "Black"))
col_var <- pick(c("coloured", "Coloured"))
room_var <- pick(c("roomnum_base", "roomid", "room_id", "room", "roomnum", "roommate_id", "roomm"))
if (is.na(room_var)) {
  cand <- nm[grepl("^room", nm, ignore.case = TRUE)]
  if (length(cand) > 0) room_var <- cand[1]
}
cat("Room cluster variable:", room_var, "\n")
prog_var <- pick(c("program", "Program", "programme", "acadprogram", "Faculty", "faculty"))
cat("Program FE variable:", prog_var, "\n")

race_iat_fu <- pick(c("DscoreraceIAT"), required = TRUE)
race_iat_bl <- pick(c("DscoreraceIATbas"), required = TRUE)
aca_iat_fu <- pick(c("DscoreacaIAT"))
aca_iat_bl <- pick(c("DscoreacaIATbas"))

gpa_var <- pick(c("GPA", "gpa", "GPA2012", "gpa2012", "GPA_2012", "avgGPA", "GPAyr1"))
if (is.na(gpa_var)) {
  cand <- nm[grepl("gpa", nm, ignore.case = TRUE) & !grepl("2013|yr2|fwer", nm, ignore.case = TRUE)]
  if (length(cand) > 0) gpa_var <- cand[1]
}
cat("GPA variable:", gpa_var, "\n")
exams_var <- pick(c("examspassed"), required = TRUE)
cont_var <- pick(c("continue"), required = TRUE)
pca_var <- pick(c("PCAperf"))

# Race indicators
if (!is.na(white_var)) df$is_white <- as.numeric(df[[white_var]] == 1) else df$is_white <- NA
if (!is.na(black_var)) df$is_black <- as.numeric(df[[black_var]] == 1) else df$is_black <- NA
if (!is.na(col_var)) df$is_col <- as.numeric(df[[col_var]] == 1) else df$is_col <- 0
df$is_white[is.na(df$is_white)] <- 0
df$is_black[is.na(df$is_black)] <- 0
df$is_col[is.na(df$is_col)] <- 0
df$is_other <- as.numeric(df$is_white == 0 & df$is_black == 0 & df$is_col == 0)
df$racegrp <- ifelse(df$is_black == 1, "Black", ifelse(df$is_white == 1, "White", "Else"))
df$res_fe <- as.character(df[[res_var]])
df$racegrp_res <- paste(df$racegrp, df$res_fe, sep = "_")
df$treat <- as.numeric(df[[treat_var]])

if (!is.na(room_var)) {
  df$cluster_id <- as.character(df[[room_var]])
} else {
  df$cluster_id <- as.character(seq_len(nrow(df)))
}
if (!is.na(prog_var)) {
  df$prog_fe <- as.character(df[[prog_var]])
  df$prog_fe[is.na(df$prog_fe) | df$prog_fe == ""] <- "missing"
} else {
  df$prog_fe <- "all"
}

# Working sample: non-missing baseline & follow-up race and academic IAT
keep <- !is.na(df[[race_iat_fu]]) & !is.na(df[[race_iat_bl]])
if (!is.na(aca_iat_fu)) keep <- keep & !is.na(df[[aca_iat_fu]])
if (!is.na(aca_iat_bl)) keep <- keep & !is.na(df[[aca_iat_bl]])
df <- df[keep & !is.na(df$treat), ]
cat("Working sample:", nrow(df), "\n")

# ---------------------------------------------------------------
# Controls: own and roommate, mean imputation + missing dummies
# ---------------------------------------------------------------
own_ctrl_cands <- list(
  c("Female", "female"),
  c("Falseuct2012", "falseuct2012"),
  c("durpcabas_nomiss", "durpcabas"),
  c("consbas_nomiss", "consbas"),
  c("Foreign", "Foreign_bas", "foreign"),
  c("privateschool_nomiss", "privateschool")
)
ro_ctrl_cands <- list(
  c("roFalseuct2012", "rofalseuct2012"),
  c("rodurpcabas_nomiss", "rodurpcabas"),
  c("roconsbas_nomiss", "roconsbas"),
  c("roForeign_bas", "roForeign", "roforeign"),
  c("roprivschool_nomiss", "roprivateschool_nomiss", "roprivschool")
)
own_ctrls <- unique(na.omit(sapply(own_ctrl_cands, pick)))
ro_ctrls <- unique(na.omit(sapply(ro_ctrl_cands, pick)))

# Existing missing-value indicator dummies in the data
miss_dummy_cands <- nm[grepl("miss", nm, ignore.case = TRUE) &
                         !grepl("nomiss", nm, ignore.case = TRUE) &
                         !grepl("IAT|fwer|sim|PCA", nm)]
cat("Existing missing dummies:", paste(miss_dummy_cands, collapse = ", "), "\n")

ctrl_vars <- c()
for (v in c(own_ctrls, ro_ctrls)) {
  x <- suppressWarnings(as.numeric(df[[v]]))
  newv <- paste0("c_", v)
  if (any(is.na(x))) {
    m <- mean(x, na.rm = TRUE)
    dv <- paste0("m_", v)
    df[[dv]] <- as.numeric(is.na(x))
    x[is.na(x)] <- m
    ctrl_vars <- c(ctrl_vars, dv)
  }
  df[[newv]] <- x
  ctrl_vars <- c(ctrl_vars, newv)
}
for (v in miss_dummy_cands) {
  x <- suppressWarnings(as.numeric(df[[v]]))
  x[is.na(x)] <- 0
  dv <- paste0("d_", v)
  df[[dv]] <- x
  ctrl_vars <- c(ctrl_vars, dv)
}
# drop constant controls in full sample
ctrl_vars <- ctrl_vars[sapply(ctrl_vars, function(v) length(unique(df[[v]])) > 1)]
cat("Controls:", paste(ctrl_vars, collapse = ", "), "\n")

drop_const <- function(vars, d) vars[sapply(vars, function(v) length(unique(d[[v]])) > 1)]

# ---------------------------------------------------------------
# Outcomes
# ---------------------------------------------------------------
df$y_race_iat <- as.numeric(df[[race_iat_fu]])
df$y_race_iat_bl <- as.numeric(df[[race_iat_bl]])
if (!is.na(gpa_var)) {
  g <- as.numeric(df[[gpa_var]])
  df$y_gpa <- (g - mean(g, na.rm = TRUE)) / sd(g, na.rm = TRUE)
} else {
  df$y_gpa <- NA_real_
}
df$y_exams <- as.numeric(df[[exams_var]])
df$y_cont <- as.numeric(df[[cont_var]])
if (!is.na(pca_var)) {
  df$y_pca <- as.numeric(df[[pca_var]])
} else {
  pc_dat <- df[, c("y_gpa", "y_exams", "y_cont")]
  ok <- complete.cases(pc_dat)
  df$y_pca <- NA_real_
  if (sum(ok) > 10) {
    pc <- prcomp(pc_dat[ok, ], scale. = TRUE)
    s <- pc$x[, 1]
    if (cor(s, pc_dat$y_gpa[ok]) < 0) s <- -s
    df$y_pca[ok] <- s
  }
}

whites <- df[df$is_white == 1, ]
blacks <- df[df$is_black == 1, ]

safe_coef <- function(model, v = "treat") {
  if (is.null(model)) return(NA_real_)
  cf <- coef(model)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}

run_sub_iat <- function(d) {
  cv <- drop_const(ctrl_vars, d)
  f <- as.formula(paste("y_race_iat ~ treat + y_race_iat_bl +",
                        paste(cv, collapse = " + "), "| res_fe"))
  tryCatch(feols(f, data = d, cluster = ~cluster_id), error = function(e) { print(e); NULL })
}

run_sub_acad <- function(d, y) {
  cv <- drop_const(ctrl_vars, d)
  f <- as.formula(paste(y, "~ treat +", paste(cv, collapse = " + "), "| res_fe + prog_fe"))
  tryCatch(feols(f, data = d, cluster = ~cluster_id), error = function(e) { print(e); NULL })
}

run_full_acad <- function(d, y) {
  cv <- drop_const(ctrl_vars, d)
  f <- as.formula(paste(y, "~ treat + is_white + is_col + is_other +",
                        paste(cv, collapse = " + "), "| racegrp_res + prog_fe"))
  tryCatch(feols(f, data = d, cluster = ~cluster_id), error = function(e) { print(e); NULL })
}

# Table 3
m_iat_w <- run_sub_iat(whites)
m_iat_b <- run_sub_iat(blacks)
if (!is.null(m_iat_w)) print(summary(m_iat_w))
if (!is.null(m_iat_b)) print(summary(m_iat_b))

# Table 4
m_gpa_b <- run_sub_acad(blacks, "y_gpa")
m_ex_b <- run_sub_acad(blacks, "y_exams")
m_ct_b <- run_sub_acad(blacks, "y_cont")
m_pc_b <- run_sub_acad(blacks, "y_pca")
m_gpa_w <- run_sub_acad(whites, "y_gpa")
m_gpa_f <- run_full_acad(df, "y_gpa")
m_ex_f <- run_full_acad(df, "y_exams")
m_pc_f <- run_full_acad(df, "y_pca")
for (m in list(m_gpa_b, m_ex_b, m_ct_b, m_pc_b, m_gpa_w, m_gpa_f, m_ex_f, m_pc_f)) {
  if (!is.null(m)) print(coeftable(m)["treat", , drop = FALSE])
}

n_full <- if (!is.null(m_gpa_f)) nobs(m_gpa_f) else nrow(df)

cat(sprintf("RESULT:race_iat_mixed_room_whites_table3_col1=%.6f\n", safe_coef(m_iat_w)))
cat(sprintf("RESULT:race_iat_mixed_room_blacks_table3_col2=%.6f\n", safe_coef(m_iat_b)))
cat(sprintf("RESULT:n_obs_table3_whites=%d\n", as.integer(nrow(whites))))
cat(sprintf("RESULT:n_obs_table3_blacks=%d\n", as.integer(nrow(blacks))))
cat(sprintf("RESULT:gpa_mixed_room_blacks_table4_panelB_col1=%.6f\n", safe_coef(m_gpa_b)))
cat(sprintf("RESULT:exams_passed_mixed_room_blacks_table4_panelB_col2=%.6f\n", safe_coef(m_ex_b)))
cat(sprintf("RESULT:eligible_mixed_room_blacks_table4_panelB_col3=%.6f\n", safe_coef(m_ct_b)))
cat(sprintf("RESULT:performance_index_mixed_room_blacks_table4_panelB_col4=%.6f\n", safe_coef(m_pc_b)))
cat(sprintf("RESULT:gpa_mixed_room_whites_table4_panelA_col1=%.6f\n", safe_coef(m_gpa_w)))
cat(sprintf("RESULT:gpa_mixed_room_full_table4_panelC_col1=%.6f\n", safe_coef(m_gpa_f)))
cat(sprintf("RESULT:exams_passed_mixed_room_full_table4_panelC_col2=%.6f\n", safe_coef(m_ex_f)))
cat(sprintf("RESULT:performance_index_mixed_room_full_table4_panelC_col4=%.6f\n", safe_coef(m_pc_f)))
cat(sprintf("RESULT:n_obs_table4_panelC_cols1_2=%d\n", as.integer(n_full)))