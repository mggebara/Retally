suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/corno_2022_interaction_stereotypes_performance"
data_path <- file.path(base_dir, "ForJournals_a/Data/Clean/uctdata_balanced.dta")

df <- haven::read_dta(data_path)
df <- haven::zap_labels(df)
df <- as.data.frame(df)

# Convert any remaining labelled / character numerics
for (v in names(df)) {
  if (inherits(df[[v]], "haven_labelled")) df[[v]] <- as.numeric(df[[v]])
}

# ---- Control lists (from 1_main_tables.do) ----
controls <- c("white", "coloured", "Else", "Female", "Falseuct2012", "missfalse",
              "Foreign", "foreign_missing", "privateschool_nomiss", "privateschool_miss",
              "durpcabas_nomiss", "durpcabas_miss", "consbas_nomiss", "consbas_miss")
controls_subsample <- c("Female", "Falseuct2012", "missfalse", "Foreign", "foreign_missing",
                        "privateschool_nomiss", "privateschool_miss", "durpcabas_nomiss",
                        "durpcabas_miss", "consbas_nomiss", "consbas_miss")
rocontrols <- c("roFalseuct2012", "missrofalse", "roForeign_bas", "roforeign_missingbas",
                "roprivschool_nomiss", "roprivschool_miss", "rodurpcabas_nomiss",
                "rodurpcabas_miss", "roconsbas_nomiss", "roconsbas_miss")

# Try to locate the roommate consumption missing-indicator under an alternative name
if (!("roconsbas_miss" %in% names(df))) {
  cand <- grep("^ro.*cons.*miss", names(df), value = TRUE, ignore.case = TRUE)
  cand <- setdiff(cand, "roconsbas_nomiss")
  if (length(cand) > 0) {
    cat("Note: using", cand[1], "as roommate consumption missing indicator\n")
    rocontrols[rocontrols == "roconsbas_miss"] <- cand[1]
  }
}

keep_existing <- function(vars) {
  miss <- setdiff(vars, names(df))
  if (length(miss) > 0) {
    cat("Note: variables not found in data and dropped:", paste(miss, collapse = ", "), "\n")
  }
  intersect(vars, names(df))
}
controls <- keep_existing(controls)
controls_subsample <- keep_existing(controls_subsample)
rocontrols <- keep_existing(rocontrols)

# Paper's stated controls (eq. 2): gender, admission score, wealth, consumption,
# non-South-African dummy (own and roommate). Private-school is not listed, so
# the academic-performance regressions use the paper's stated control set.
priv <- c("privateschool_nomiss", "privateschool_miss", "roprivschool_nomiss", "roprivschool_miss")
controls_t4 <- setdiff(controls, priv)
controls_subsample_t4 <- setdiff(controls_subsample, priv)
rocontrols_t4 <- setdiff(rocontrols, priv)

# ---- Panel id for lags (xtset individual round) ----
id_var <- if ("individual" %in% names(df)) "individual" else "nstudent"

make_lag <- function(v) {
  lagname <- paste0("L_", v)
  r1 <- df[!is.na(df$round) & df$round == 1, c(id_var, v)]
  r1 <- r1[!duplicated(r1[[id_var]]), ]
  df[[lagname]] <<- NA_real_
  idx <- !is.na(df$round) & df$round == 2
  m <- match(df[[id_var]][idx], r1[[id_var]])
  df[[lagname]][idx] <<- r1[[v]][m]
  lagname
}

L_race <- make_lag("DscoreraceIAT")
L_aca  <- make_lag("DscoreacaIAT")

# FE variables as factors (Stata i. dummies)
for (fv in c("Res_base", "blackRes", "whiteRes", "regprogram")) {
  if (fv %in% names(df)) df[[paste0("fe_", fv)]] <- ifelse(is.na(df[[fv]]), NA, as.character(df[[fv]]))
}

bq <- function(x) paste0("`", x, "`")

run_reg <- function(y, rhs, fes, sub) {
  d <- df[sub, , drop = FALSE]
  fes <- paste0("fe_", fes)
  fml <- as.formula(paste0(bq(y), " ~ ", paste(bq(rhs), collapse = " + "),
                           " | ", paste(fes, collapse = " + ")))
  feols(fml, data = d, cluster = ~roomnum_base, fixef.rm = "none", warn = FALSE, notes = FALSE)
}

safe <- function(expr) tryCatch(expr, error = function(e) { cat("Error:", conditionMessage(e), "\n"); NULL })

get_b <- function(m) if (is.null(m)) NA_real_ else unname(coef(m)["mixracebas"])
get_n <- function(m) if (is.null(m)) NA_real_ else nobs(m)

r2 <- !is.na(df$round) & df$round == 2
is_white <- r2 & !is.na(df$white) & df$white == 1
is_black <- r2 & !is.na(df$black) & df$black == 1

# ---- Table 3: Race IAT ----
m_t3_w <- safe(run_reg("DscoreraceIAT", c("mixracebas", L_race, controls_subsample, rocontrols),
                       c("Res_base"), is_white))
m_t3_b <- safe(run_reg("DscoreraceIAT", c("mixracebas", L_race, controls_subsample, rocontrols),
                       c("Res_base"), is_black))

# ---- Table 4: academic performance ----
t4_sub <- function(y, sub) safe(run_reg(y, c("mixracebas", controls_subsample_t4, rocontrols_t4),
                                        c("Res_base", "regprogram"), sub))
t4_full <- function(y) safe(run_reg(y, c("mixracebas", controls_t4, rocontrols_t4),
                                    c("blackRes", "whiteRes", "Res_base", "regprogram"), r2))

m_gpa_b   <- t4_sub("GPA", is_black)
m_exam_b  <- t4_sub("examspassed", is_black)
m_cont_b  <- t4_sub("continue", is_black)
m_perf_b  <- t4_sub("PCAperf", is_black)
m_gpa_w   <- t4_sub("GPA", is_white)
m_gpa_f   <- t4_full("GPA")
m_exam_f  <- t4_full("examspassed")
m_perf_f  <- t4_full("PCAperf")

out <- function(name, val) cat(sprintf("RESULT:%s=%s\n", name, format(val, digits = 10)))

out("race_iat_mixed_room_whites_table3_col1", get_b(m_t3_w))
out("race_iat_mixed_room_blacks_table3_col2", get_b(m_t3_b))
out("n_obs_table3_whites", get_n(m_t3_w))
out("n_obs_table3_blacks", get_n(m_t3_b))
out("gpa_mixed_room_blacks_table4_panelB_col1", get_b(m_gpa_b))
out("exams_passed_mixed_room_blacks_table4_panelB_col2", get_b(m_exam_b))
out("eligible_mixed_room_blacks_table4_panelB_col3", get_b(m_cont_b))
out("performance_index_mixed_room_blacks_table4_panelB_col4", get_b(m_perf_b))
out("gpa_mixed_room_whites_table4_panelA_col1", get_b(m_gpa_w))
out("gpa_mixed_room_full_table4_panelC_col1", get_b(m_gpa_f))
out("exams_passed_mixed_room_full_table4_panelC_col2", get_b(m_exam_f))
out("performance_index_mixed_room_full_table4_panelC_col4", get_b(m_perf_f))
out("n_obs_table4_panelC_cols1_2", get_n(m_gpa_f))
