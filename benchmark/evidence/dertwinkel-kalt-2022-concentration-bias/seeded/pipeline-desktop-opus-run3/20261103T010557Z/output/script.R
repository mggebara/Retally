suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(sandwich)
  library(lmtest)
  library(AER)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias"
csv_path <- file.path(base_dir, "Consumption Experiment", "Stata", "Consumption_Experiment.csv")

df <- suppressWarnings(readr::read_csv(csv_path, show_col_types = FALSE, guess_max = 100000))
df <- as.data.frame(df)

to_num <- function(x) suppressWarnings(as.numeric(as.character(x)))
num_vars <- c("pap_sample", "dispersed", "treatment", "control", "main", "pizza",
              "id_stage2", "avg_id_stage2", "id_stage2_upper",
              "qe_ard", "qe_ard_lower", "qe_ard_upper", "tn", "session", "decision_number")
for (v in intersect(num_vars, names(df))) df[[v]] <- to_num(df[[v]])

# Subject key (to guard against an outcome being repeated across decision rows)
key_vars <- intersect(c("tn", "session", "treatment", "dispersed", "pizza"), names(df))

# Return the estimation sample for outcome y under a logical condition:
# rows with non-missing y; if y is repeated across rows of the same subject,
# keep one row per subject (Stata output implies one obs per subject).
est_sample <- function(data, y, cond, extra = character(0)) {
  d <- data[cond & !is.na(cond), , drop = FALSE]
  d <- d[!is.na(d[[y]]), , drop = FALSE]
  for (e in extra) d <- d[!is.na(d[[e]]), , drop = FALSE]
  if (length(key_vars) > 0 && "tn" %in% key_vars) {
    k <- do.call(paste, c(d[key_vars], sep = "_"))
    if (any(duplicated(k))) d <- d[!duplicated(k), , drop = FALSE]
  }
  d
}

robust_lm <- function(formula, data) {
  m <- lm(formula, data = data)
  V <- sandwich::vcovHC(m, type = "HC1")
  list(model = m, coef = coef(m), se = sqrt(diag(V)), n = nobs(m))
}

out <- list()
emit <- function(name, val) {
  if (length(val) == 0 || is.na(val)) return(invisible(NULL))
  out[[name]] <<- val
  cat(sprintf("RESULT:%s=%.6f\n", name, val))
}

is1 <- function(x) !is.na(x) & x == 1
is0 <- function(x) !is.na(x) & x == 0

main_tr <- is1(df$pap_sample) & is0(df$dispersed) & is1(df$treatment)

# ---------------- Table 2 ----------------
d_lb  <- est_sample(df, "id_stage2", main_tr)
d_mid <- est_sample(df, "avg_id_stage2", main_tr)
d_ub  <- est_sample(df, "id_stage2_upper", main_tr)

r_lb  <- robust_lm(id_stage2 ~ 1, d_lb)
r_mid <- robust_lm(avg_id_stage2 ~ 1, d_mid)
r_ub  <- robust_lm(id_stage2_upper ~ 1, d_ub)

# Tobit, left-censored at -63, right-censored at 63 (as in the do-file)
tob <- AER::tobit(id_stage2 ~ 1, left = -63, right = 63, data = d_lb)
tob_coef <- unname(coef(tob)[1])
tob_se <- unname(sqrt(diag(vcov(tob)))[1])

q_lb  <- est_sample(df, "qe_ard_lower", main_tr)
q_mid <- est_sample(df, "qe_ard", main_tr)
q_ub  <- est_sample(df, "qe_ard_upper", main_tr)

rq_lb  <- robust_lm(qe_ard_lower ~ 1, q_lb)
rq_mid <- robust_lm(qe_ard ~ 1, q_mid)
rq_ub  <- robust_lm(qe_ard_upper ~ 1, q_ub)

emit("abs_concentration_bias_lower_table2_col1", unname(r_lb$coef[1]))
emit("abs_concentration_bias_lower_table2_col1_se", unname(r_lb$se[1]))
emit("abs_concentration_bias_midpoint_table2_col2", unname(r_mid$coef[1]))
emit("abs_concentration_bias_midpoint_table2_col2_se", unname(r_mid$se[1]))
emit("abs_concentration_bias_upper_table2_col3", unname(r_ub$coef[1]))
emit("abs_concentration_bias_upper_table2_col3_se", unname(r_ub$se[1]))
emit("abs_concentration_bias_tobit_table2_col4", tob_coef)
emit("abs_concentration_bias_tobit_table2_col4_se", tob_se)

emit("rel_concentration_bias_lower_table2_col1", unname(rq_lb$coef[1]))
emit("rel_concentration_bias_lower_table2_col1_se", unname(rq_lb$se[1]))
emit("rel_concentration_bias_midpoint_table2_col2", unname(rq_mid$coef[1]))
emit("rel_concentration_bias_midpoint_table2_col2_se", unname(rq_mid$se[1]))
emit("rel_concentration_bias_upper_table2_col3", unname(rq_ub$coef[1]))
emit("rel_concentration_bias_upper_table2_col3_se", unname(rq_ub$se[1]))

emit("n_obs_table2", r_mid$n)

# ---------------- Table 3 ----------------
# Column 1: Mechanism-Treatment vs Main-Treatment
c1 <- est_sample(df, "qe_ard", is1(df$pap_sample) & is1(df$treatment), extra = "main")
t3c1 <- robust_lm(qe_ard ~ main, c1)

# Column 2: Donation-Treatment vs Donation-Control
c2 <- est_sample(df, "qe_ard", is1(df$pap_sample) & is0(df$pizza), extra = "control")
t3c2 <- robust_lm(qe_ard ~ control, c2)

# Column 3: Main-Control vs Main-Treatment
c3 <- est_sample(df, "qe_ard", is1(df$pap_sample) & is1(df$pizza) & is0(df$dispersed),
                 extra = "treatment")
t3c3 <- robust_lm(qe_ard ~ treatment, c3)

# Column 4: Mechanism-Control vs Mechanism-Treatment
c4 <- est_sample(df, "qe_ard", is1(df$pap_sample) & is1(df$pizza) & is1(df$dispersed),
                 extra = "treatment")
t3c4 <- robust_lm(qe_ard ~ treatment, c4)

emit("rel_cb_mechanism_treatment_table3_col1", unname(t3c1$coef["(Intercept)"]))
emit("rel_cb_mechanism_treatment_table3_col1_se", unname(t3c1$se["(Intercept)"]))
emit("diff_main_minus_mechanism_table3_col1", unname(t3c1$coef["main"]))
emit("diff_main_minus_mechanism_table3_col1_se", unname(t3c1$se["main"]))

emit("rel_cb_donation_treatment_table3_col2", unname(t3c2$coef["(Intercept)"]))
emit("rel_cb_donation_treatment_table3_col2_se", unname(t3c2$se["(Intercept)"]))
emit("diff_donation_treatment_minus_control_table3_col2", -unname(t3c2$coef["control"]))
emit("diff_donation_treatment_minus_control_table3_col2_se", unname(t3c2$se["control"]))

emit("rel_cb_main_control_table3_col3", unname(t3c3$coef["(Intercept)"]))
emit("diff_main_treatment_minus_control_table3_col3", unname(t3c3$coef["treatment"]))
emit("diff_main_treatment_minus_control_table3_col3_se", unname(t3c3$se["treatment"]))

emit("rel_cb_mechanism_control_table3_col4", unname(t3c4$coef["(Intercept)"]))
emit("diff_mechanism_treatment_minus_control_table3_col4", unname(t3c4$coef["treatment"]))
emit("diff_mechanism_treatment_minus_control_table3_col4_se", unname(t3c4$se["treatment"]))

emit("n_obs_table3", t3c1$n)
emit("n_obs_table3_col2", t3c2$n)
emit("n_obs_table3_col3", t3c3$n)
emit("n_obs_table3_col4", t3c4$n)