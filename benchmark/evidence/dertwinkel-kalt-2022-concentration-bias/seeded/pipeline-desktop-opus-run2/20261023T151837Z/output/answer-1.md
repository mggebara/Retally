suppressPackageStartupMessages({
  library(sandwich)
  library(lmtest)
  library(AER)
  library(survival)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias"
f <- file.path(base_dir, "Consumption Experiment", "Stata", "Consumption_Experiment.csv")
d <- read.csv(f, stringsAsFactors = FALSE, na.strings = c("", ".", "NA"))
names(d) <- tolower(names(d))

num_vars <- c("tn", "session", "pap_sample", "dispersed", "treatment", "control", "main",
              "pizza", "decision_number", "id_stage2", "avg_id_stage2", "id_stage2_upper",
              "qe_ard", "qe_ard_lower", "qe_ard_upper")
for (v in intersect(num_vars, names(d))) {
  if (!is.numeric(d[[v]])) d[[v]] <- suppressWarnings(as.numeric(d[[v]]))
}

# subject identifier (used only to guard against repeated subject-level rows in long data)
if ("session" %in% names(d)) {
  d$.sid <- paste(d$session, d$tn, sep = "_")
} else {
  d$.sid <- as.character(d$tn)
}

eq1 <- function(x) !is.na(x) & x == 1
eq0 <- function(x) !is.na(x) & x == 0

# Keep rows with non-missing outcome (and regressor), as Stata's reg does;
# if the data are long and the subject-level outcome is repeated, keep one row per subject.
prep <- function(sub, vars) {
  ok <- complete.cases(sub[, vars, drop = FALSE])
  sub <- sub[ok, , drop = FALSE]
  if (any(duplicated(sub$.sid))) {
    if ("decision_number" %in% names(sub)) sub <- sub[order(sub$.sid, -sub$decision_number), ]
    sub <- sub[!duplicated(sub$.sid), , drop = FALSE]
  }
  sub
}

ols_const <- function(sub, y) {
  s <- prep(sub, y)
  m <- lm(as.formula(paste(y, "~ 1")), data = s)
  se <- sqrt(diag(vcovHC(m, type = "HC1")))
  list(b = unname(coef(m)[1]), se = unname(se[1]), n = nobs(m))
}

ols_x <- function(sub, y, x) {
  s <- prep(sub, c(y, x))
  m <- lm(as.formula(paste(y, "~", x)), data = s)
  se <- sqrt(diag(vcovHC(m, type = "HC1")))
  list(b0 = unname(coef(m)[1]), b1 = unname(coef(m)[x]),
       se0 = unname(se[1]), se1 = unname(se[x]), n = nobs(m))
}

# ---------------- Table 2: Main-Treatment, PAP sample ----------------
t2 <- d[eq1(d$pap_sample) & eq0(d$dispersed) & eq1(d$treatment), ]

r_lb   <- ols_const(t2, "id_stage2")
r_mid  <- ols_const(t2, "avg_id_stage2")
r_ub   <- ols_const(t2, "id_stage2_upper")
q_lb   <- ols_const(t2, "qe_ard_lower")
q_mid  <- ols_const(t2, "qe_ard")
q_ub   <- ols_const(t2, "qe_ard_upper")

# Tobit: tobit id_stage2, ll(-63) ul(63)
tb <- prep(t2, "id_stage2")
y <- tb$id_stage2
ll <- -63; ul <- 63
if (!any(y >= ul) && any(y == 62)) {
  # DEVIATION: upper-corner subjects appear coded at 62 rather than >= 63; treat 62 as the
  # upper censoring point so that the corner choices are treated as censored.
  ul <- 62
  cat("DEVIATION: no observations at or above 63; using 62 as upper censoring point\n")
}
tobit_fit <- tryCatch({
  m <- AER::tobit(id_stage2 ~ 1, left = ll, right = ul, data = tb)
  list(b = unname(coef(m)[1]), se = unname(sqrt(diag(vcov(m)))[1]))
}, error = function(e) NULL)
if (is.null(tobit_fit)) {
  nll <- function(p) {
    mu <- p[1]; s <- exp(p[2])
    lc <- y <= ll; rc <- y >= ul; un <- !(lc | rc)
    -(sum(dnorm(y[un], mu, s, log = TRUE)) +
        sum(pnorm((ll - mu) / s, log.p = TRUE) * lc) +
        sum(pnorm((ul - mu) / s, lower.tail = FALSE, log.p = TRUE) * rc))
  }
  o <- optim(c(mean(y), log(sd(y))), nll, method = "BFGS", hessian = TRUE)
  tobit_fit <- list(b = o$par[1], se = sqrt(diag(solve(o$hessian)))[1])
}

# ---------------- Table 3 ----------------
# Col 1: Mechanism-Treatment vs Main-Treatment
c1 <- ols_x(d[eq1(d$pap_sample) & eq1(d$treatment), ], "qe_ard", "main")
# Col 2: Donation-Treatment vs Donation-Control
c2 <- ols_x(d[eq1(d$pap_sample) & eq0(d$pizza), ], "qe_ard", "control")
# Col 3: Main-Treatment vs Main-Control
c3 <- ols_x(d[eq1(d$pap_sample) & eq1(d$pizza) & eq0(d$dispersed), ], "qe_ard", "treatment")
# Col 4: Mechanism-Treatment vs Mechanism-Control
c4 <- ols_x(d[eq1(d$pap_sample) & eq1(d$pizza) & eq1(d$dispersed), ], "qe_ard", "treatment")

fmt <- function(x) format(x, digits = 10)

cat("Table 2 N (lb/mid/ub/rel):", r_lb$n, r_mid$n, r_ub$n, q_mid$n, "\n")
cat("Table 3 N (cols 1-4):", c1$n, c2$n, c3$n, c4$n, "\n")

cat(paste0("RESULT:abs_concentration_bias_lower_table2_col1=", fmt(r_lb$b), "\n"))
cat(paste0("RESULT:abs_concentration_bias_midpoint_table2_col2=", fmt(r_mid$b), "\n"))
cat(paste0("RESULT:abs_concentration_bias_midpoint_table2_col2_se=", fmt(r_mid$se), "\n"))
cat(paste0("RESULT:abs_concentration_bias_upper_table2_col3=", fmt(r_ub$b), "\n"))
cat(paste0("RESULT:abs_concentration_bias_tobit_table2_col4=", fmt(tobit_fit$b), "\n"))
cat(paste0("RESULT:abs_concentration_bias_tobit_table2_col4_se=", fmt(tobit_fit$se), "\n"))
cat(paste0("RESULT:rel_concentration_bias_lower_table2_col1=", fmt(q_lb$b), "\n"))
cat(paste0("RESULT:rel_concentration_bias_midpoint_table2_col2=", fmt(q_mid$b), "\n"))
cat(paste0("RESULT:rel_concentration_bias_midpoint_table2_col2_se=", fmt(q_mid$se), "\n"))
cat(paste0("RESULT:rel_concentration_bias_upper_table2_col3=", fmt(q_ub$b), "\n"))
cat(paste0("RESULT:n_obs_table2=", r_mid$n, "\n"))
cat(paste0("RESULT:rel_cb_mechanism_treatment_table3_col1=", fmt(c1$b0), "\n"))
cat(paste0("RESULT:diff_main_minus_mechanism_table3_col1=", fmt(c1$b1), "\n"))
cat(paste0("RESULT:diff_main_minus_mechanism_table3_col1_se=", fmt(c1$se1), "\n"))
cat(paste0("RESULT:rel_cb_donation_treatment_table3_col2=", fmt(c2$b0), "\n"))
cat(paste0("RESULT:diff_donation_treatment_minus_control_table3_col2=", fmt(-c2$b1), "\n"))
cat(paste0("RESULT:diff_donation_treatment_minus_control_table3_col2_se=", fmt(c2$se1), "\n"))
cat(paste0("RESULT:diff_main_treatment_minus_control_table3_col3=", fmt(c3$b1), "\n"))
cat(paste0("RESULT:diff_main_treatment_minus_control_table3_col3_se=", fmt(c3$se1), "\n"))
cat(paste0("RESULT:diff_mechanism_treatment_minus_control_table3_col4=", fmt(c4$b1), "\n"))
cat(paste0("RESULT:diff_mechanism_treatment_minus_control_table3_col4_se=", fmt(c4$se1), "\n"))
cat(paste0("RESULT:n_obs_table3=", c1$n, "\n"))
