suppressPackageStartupMessages({
  library(readr)
  library(sandwich)
  library(lmtest)
  library(AER)
  library(survival)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias"
csv_path <- file.path(base_dir, "Consumption Experiment", "Stata", "Consumption_Experiment.csv")

df <- readr::read_csv(csv_path, na = c("", "NA", "."), show_col_types = FALSE,
                      guess_max = 100000)
df <- as.data.frame(df)
names(df) <- tolower(names(df))

num_vars <- c("tn", "session", "pap_sample", "dispersed", "treatment", "control", "main",
              "pizza", "decision_number", "utility_point", "indifference_point",
              "id_stage2", "avg_id_stage2", "id_stage2_upper",
              "qe_ard", "qe_ard_lower", "qe_ard_upper")
for (v in intersect(num_vars, names(df))) {
  if (!is.numeric(df[[v]])) {
    x <- df[[v]]
    if (is.logical(x)) {
      df[[v]] <- as.numeric(x)
    } else {
      xs <- tolower(trimws(as.character(x)))
      xs[xs == "true"] <- "1"
      xs[xs == "false"] <- "0"
      df[[v]] <- suppressWarnings(as.numeric(xs))
    }
  }
}

eq <- function(v, val) !is.na(v) & v == val

# Keep rows with non-missing model variables (Stata listwise deletion); if the
# long-format file repeats subject-level values over several rows, keep one row
# per subject.
prep <- function(d, vars) {
  d <- d[stats::complete.cases(d[, vars, drop = FALSE]), , drop = FALSE]
  key_vars <- intersect(c("session", "tn"), names(d))
  if (length(key_vars) > 0) {
    key <- do.call(paste, c(d[, key_vars, drop = FALSE], sep = "_"))
    if (length(unique(key)) < nrow(d)) {
      cat("Note: de-duplicating to one row per subject (", nrow(d), "->",
          length(unique(key)), ")\n")
      d <- d[!duplicated(key), , drop = FALSE]
    }
  }
  d
}

ols_robust <- function(d, y, x = NULL) {
  vars <- c(y, x)
  d <- prep(d, vars)
  f <- if (is.null(x)) as.formula(paste(y, "~ 1")) else as.formula(paste(y, "~", paste(x, collapse = " + ")))
  m <- lm(f, data = d)
  V <- sandwich::vcovHC(m, type = "HC1")
  list(coef = coef(m), se = sqrt(diag(V)), n = nobs(m), model = m)
}

# ---------------- Table 2 ----------------
s2 <- df[eq(df$pap_sample, 1) & eq(df$dispersed, 0) & eq(df$treatment, 1), , drop = FALSE]

t2_abs_lower <- ols_robust(s2, "id_stage2")
t2_abs_mid   <- ols_robust(s2, "avg_id_stage2")
t2_abs_upper <- ols_robust(s2, "id_stage2_upper")

t2_rel_lower <- ols_robust(s2, "qe_ard_lower")
t2_rel_mid   <- ols_robust(s2, "qe_ard")
t2_rel_upper <- ols_robust(s2, "qe_ard_upper")

# Tobit: tobit id_stage2, ll(-63) ul(63)
s2_tob <- prep(s2, "id_stage2")
tobit_coef <- NA_real_
tobit_se <- NA_real_
tob <- tryCatch(AER::tobit(id_stage2 ~ 1, left = -63, right = 63, data = s2_tob),
                error = function(e) NULL)
if (!is.null(tob)) {
  tobit_coef <- unname(coef(tob)["(Intercept)"])
  tobit_se <- unname(sqrt(diag(vcov(tob)))["(Intercept)"])
} else {
  y <- s2_tob$id_stage2
  lo <- ifelse(y <= -63, NA, y)
  hi <- ifelse(y >= 63, NA, y)
  lo[y >= 63] <- 63
  hi[y <= -63] <- -63
  sr <- survival::survreg(survival::Surv(lo, hi, type = "interval2") ~ 1, dist = "gaussian")
  tobit_coef <- unname(coef(sr)[1])
  tobit_se <- unname(sqrt(diag(vcov(sr)))[1])
}

cat("Table 2 N (lower/mid/upper abs):", t2_abs_lower$n, t2_abs_mid$n, t2_abs_upper$n, "\n")
cat("Table 2 abs lower:", t2_abs_lower$coef, " upper:", t2_abs_upper$coef, "\n")
cat("Censored obs (>=63):", sum(s2_tob$id_stage2 >= 63), " (<=-63):", sum(s2_tob$id_stage2 <= -63), "\n")

# ---------------- Table 3 ----------------
# Col 1: reg qe_ard main if pap_sample == 1 & treatment == 1, r
s31 <- df[eq(df$pap_sample, 1) & eq(df$treatment, 1), , drop = FALSE]
t3c1 <- ols_robust(s31, "qe_ard", "main")

# Col 2: reg qe_ard control if pap_sample == 1 & pizza == 0, r
s32 <- df[eq(df$pap_sample, 1) & eq(df$pizza, 0), , drop = FALSE]
t3c2 <- ols_robust(s32, "qe_ard", "control")

# Col 3: reg qe_ard treatment if pap_sample == 1 & pizza == 1 & dispersed == 0, r
s33 <- df[eq(df$pap_sample, 1) & eq(df$pizza, 1) & eq(df$dispersed, 0), , drop = FALSE]
t3c3 <- ols_robust(s33, "qe_ard", "treatment")

# Col 4: reg qe_ard treatment if pap_sample == 1 & pizza == 1 & dispersed == 1, r
s34 <- df[eq(df$pap_sample, 1) & eq(df$pizza, 1) & eq(df$dispersed, 1), , drop = FALSE]
t3c4 <- ols_robust(s34, "qe_ard", "treatment")

cat("Table 3 N:", t3c1$n, t3c2$n, t3c3$n, t3c4$n, "\n")

fmt <- function(x) format(x, digits = 10, scientific = FALSE)
out <- function(name, val) cat(paste0("RESULT:", name, "=", fmt(val), "\n"))

out("abs_concentration_bias_midpoint_table2_col2", unname(t2_abs_mid$coef["(Intercept)"]))
out("abs_concentration_bias_midpoint_table2_col2_se", unname(t2_abs_mid$se["(Intercept)"]))
out("abs_concentration_bias_tobit_table2_col4", tobit_coef)
out("abs_concentration_bias_tobit_table2_col4_se", tobit_se)
out("rel_concentration_bias_lower_table2_col1", unname(t2_rel_lower$coef["(Intercept)"]))
out("rel_concentration_bias_lower_table2_col1_se", unname(t2_rel_lower$se["(Intercept)"]))
out("rel_concentration_bias_midpoint_table2_col2", unname(t2_rel_mid$coef["(Intercept)"]))
out("rel_concentration_bias_midpoint_table2_col2_se", unname(t2_rel_mid$se["(Intercept)"]))
out("rel_concentration_bias_upper_table2_col3", unname(t2_rel_upper$coef["(Intercept)"]))
out("rel_concentration_bias_upper_table2_col3_se", unname(t2_rel_upper$se["(Intercept)"]))
out("n_obs_table2", t2_abs_mid$n)

out("rel_cb_mechanism_treatment_table3_col1", unname(t3c1$coef["(Intercept)"]))
out("rel_cb_mechanism_treatment_table3_col1_se", unname(t3c1$se["(Intercept)"]))
out("diff_main_minus_mechanism_table3_col1", unname(t3c1$coef["main"]))
out("diff_main_minus_mechanism_table3_col1_se", unname(t3c1$se["main"]))
out("rel_cb_donation_treatment_table3_col2", unname(t3c2$coef["(Intercept)"]))
out("rel_cb_donation_treatment_table3_col2_se", unname(t3c2$se["(Intercept)"]))
out("diff_donation_treatment_minus_control_table3_col2", -unname(t3c2$coef["control"]))
out("diff_donation_treatment_minus_control_table3_col2_se", unname(t3c2$se["control"]))
out("diff_main_treatment_minus_control_table3_col3", unname(t3c3$coef["treatment"]))
out("diff_main_treatment_minus_control_table3_col3_se", unname(t3c3$se["treatment"]))
out("diff_mechanism_treatment_minus_control_table3_col4", unname(t3c4$coef["treatment"]))
out("diff_mechanism_treatment_minus_control_table3_col4_se", unname(t3c4$se["treatment"]))
out("n_obs_table3", t3c1$n)