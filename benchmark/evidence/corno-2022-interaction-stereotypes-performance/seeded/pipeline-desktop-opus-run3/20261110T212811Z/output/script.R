suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/corno_2022_interaction_stereotypes_performance"
data_file <- file.path(base_dir, "ForJournals_a", "Data", "Clean", "uctdata_balanced.dta")

d <- haven::read_dta(data_file)
d <- haven::zap_labels(d)
d <- haven::zap_formats(d)
d <- as.data.frame(d)

cat("Loaded uctdata_balanced:", nrow(d), "rows,", ncol(d), "cols\n")

# ---------------------------------------------------------------
# Panel identifier (Stata: xtset individual round)
# ---------------------------------------------------------------
id_var <- if ("individual" %in% names(d)) "individual" else "nstudent"
cat("Panel id variable:", id_var, "\n")
d$pid <- d[[id_var]]
d$round <- as.numeric(d$round)

# Lag operator: value of the same individual at round - 1
make_lag <- function(df, v) {
  key_cur <- paste(df$pid, df$round, sep = "_")
  key_prev <- paste(df$pid, df$round - 1, sep = "_")
  vals <- df[[v]]
  idx <- match(key_prev, key_cur)
  out <- vals[idx]
  out
}
d$L_DscoreraceIAT <- make_lag(d, "DscoreraceIAT")
d$L_DscoreacaIAT <- make_lag(d, "DscoreacaIAT")

# ---------------------------------------------------------------
# Recover the roommate consumption missing-value indicator
# (roconsbas_miss), which is part of the roommate controls but is
# not stored under that name in the data file.
# ---------------------------------------------------------------
cat("Roommate-related variables in data:", paste(grep("^ro", names(d), value = TRUE), collapse = ", "), "\n")
if (!"roconsbas_miss" %in% names(d)) {
  cand <- setdiff(grep("^roconsbas.*miss|^rocons.*miss", names(d), value = TRUE), "roconsbas_nomiss")
  if (length(cand) > 0) {
    d$roconsbas_miss <- as.numeric(d[[cand[1]]])
    cat(sprintf("DEVIATION: roconsbas_miss not found; used variable '%s' as roommate consumption missing indicator\n", cand[1]))
  } else if ("roconsbas" %in% names(d)) {
    d$roconsbas_miss <- as.numeric(is.na(d$roconsbas))
    cat("DEVIATION: roconsbas_miss constructed as is.na(roconsbas)\n")
  } else if ("roconsbas_nomiss" %in% names(d)) {
    x <- d$roconsbas_nomiss
    tab <- table(signif(x, 10))
    top <- as.numeric(names(tab)[which.max(tab)])
    cat(sprintf("Most frequent roconsbas_nomiss value: %s (count %d)\n", format(top), max(tab)))
    if (max(tab) >= 4) {
      d$roconsbas_miss <- as.numeric(!is.na(x) & abs(x - top) < 1e-6 * max(1, abs(top)))
      cat(sprintf("DEVIATION: roconsbas_miss missing from data; reconstructed as indicator that roconsbas_nomiss equals the mean-imputed value (%d rows flagged)\n",
                  sum(d$roconsbas_miss, na.rm = TRUE)))
    }
  }
}

# ---------------------------------------------------------------
# Control lists (from 1_main_tables.do)
# ---------------------------------------------------------------
controls_full <- c("white", "coloured", "Else", "Female", "Falseuct2012", "missfalse",
                   "Foreign", "foreign_missing", "privateschool_nomiss", "privateschool_miss",
                   "durpcabas_nomiss", "durpcabas_miss", "consbas_nomiss", "consbas_miss")
controls_sub <- c("Female", "Falseuct2012", "missfalse", "Foreign", "foreign_missing",
                  "privateschool_nomiss", "privateschool_miss", "durpcabas_nomiss",
                  "durpcabas_miss", "consbas_nomiss", "consbas_miss")
rocontrols <- c("roFalseuct2012", "missrofalse", "roForeign_bas", "roforeign_missingbas",
                "roprivschool_nomiss", "roprivschool_miss", "rodurpcabas_nomiss",
                "rodurpcabas_miss", "roconsbas_nomiss", "roconsbas_miss")

keep_present <- function(vars) {
  miss <- setdiff(vars, names(d))
  if (length(miss) > 0) cat("WARNING: variables not found in data (dropped):", paste(miss, collapse = ", "), "\n")
  intersect(vars, names(d))
}
controls_full <- keep_present(controls_full)
controls_sub <- keep_present(controls_sub)
rocontrols <- keep_present(rocontrols)

# Fixed-effect variables as factors (Stata i.Res_base, i.blackRes, i.whiteRes, i.regprogram)
for (v in c("Res_base", "blackRes", "whiteRes", "regprogram")) {
  if (v %in% names(d)) {
    d[[paste0(v, "_f")]] <- ifelse(is.na(d[[v]]), NA, as.character(d[[v]]))
  } else {
    cat("WARNING: FE variable not found:", v, "\n")
  }
}

for (v in c("white", "black", "mixracebas", "roomnum_base")) {
  if (!v %in% names(d)) cat("WARNING: key variable missing:", v, "\n")
}

d2 <- d[d$round == 2 & !is.na(d$round), ]
d2_white <- d2[!is.na(d2$white) & d2$white == 1, ]
d2_black <- d2[!is.na(d2$black) & d2$black == 1, ]
cat("Round 2 rows:", nrow(d2), " whites:", nrow(d2_white), " blacks:", nrow(d2_black), "\n")

# ---------------------------------------------------------------
# Estimation helper
# ---------------------------------------------------------------
bq <- function(x) paste0("`", x, "`")

run_reg <- function(data, y, rhs, fes, label) {
  rhs_str <- paste(bq(rhs), collapse = " + ")
  fe_str <- paste(fes, collapse = " + ")
  fml <- as.formula(paste0(bq(y), " ~ ", rhs_str, " | ", fe_str))
  res <- tryCatch({
    m <- feols(fml, data = data, cluster = ~roomnum_base, fixef.rm = "none", warn = FALSE, notes = FALSE)
    b <- unname(coef(m)["mixracebas"])
    se <- unname(sqrt(diag(vcov(m)))["mixracebas"])
    n <- nobs(m)
    cat(sprintf("[%s] beta(mixracebas)=%.4f se=%.4f N=%d\n", label, b, se, n))
    list(b = b, se = se, n = n)
  }, error = function(e) {
    cat(sprintf("[%s] ERROR: %s\n", label, conditionMessage(e)))
    list(b = NA_real_, se = NA_real_, n = NA_integer_)
  })
  res
}

# ---------------------------------------------------------------
# Table 3: Race IAT, whites and blacks
# reg DscoreraceIAT mixracebas L.DscoreraceIAT controls_subsample rocontrols i.Res_base
#     if round==2 & white==1, cluster(roomnum_base)
# ---------------------------------------------------------------
t3_w <- run_reg(d2_white, "DscoreraceIAT",
                c("mixracebas", "L_DscoreraceIAT", controls_sub, rocontrols),
                c("Res_base_f"), "T3 race IAT whites")
t3_b <- run_reg(d2_black, "DscoreraceIAT",
                c("mixracebas", "L_DscoreraceIAT", controls_sub, rocontrols),
                c("Res_base_f"), "T3 race IAT blacks")
# Academic IAT (for reference on sample sizes)
t3_w_aca <- run_reg(d2_white, "DscoreacaIAT",
                    c("mixracebas", "L_DscoreacaIAT", controls_sub, rocontrols),
                    c("Res_base_f"), "T3 academic IAT whites")
t3_b_aca <- run_reg(d2_black, "DscoreacaIAT",
                    c("mixracebas", "L_DscoreacaIAT", controls_sub, rocontrols),
                    c("Res_base_f"), "T3 academic IAT blacks")

# ---------------------------------------------------------------
# Table 4: academic performance
# Subsamples: controls_subsample rocontrols i.Res_base i.regprogram
# Full: controls rocontrols i.blackRes i.whiteRes i.Res_base i.regprogram
# ---------------------------------------------------------------
t4 <- list()
for (y in c("GPA", "examspassed", "continue", "PCAperf")) {
  if (!y %in% names(d2)) {
    cat("WARNING: outcome not found:", y, "\n")
    t4[[paste0(y, "_w")]] <- list(b = NA, se = NA, n = NA)
    t4[[paste0(y, "_b")]] <- list(b = NA, se = NA, n = NA)
    t4[[paste0(y, "_f")]] <- list(b = NA, se = NA, n = NA)
    next
  }
  t4[[paste0(y, "_w")]] <- run_reg(d2_white, y, c("mixracebas", controls_sub, rocontrols),
                                   c("Res_base_f", "regprogram_f"), paste("T4", y, "whites"))
  t4[[paste0(y, "_b")]] <- run_reg(d2_black, y, c("mixracebas", controls_sub, rocontrols),
                                   c("Res_base_f", "regprogram_f"), paste("T4", y, "blacks"))
  t4[[paste0(y, "_f")]] <- run_reg(d2, y, c("mixracebas", controls_full, rocontrols),
                                   c("blackRes_f", "whiteRes_f", "Res_base_f", "regprogram_f"),
                                   paste("T4", y, "full"))
}

# ---------------------------------------------------------------
# Output
# ---------------------------------------------------------------
fmt <- function(x) ifelse(is.na(x), "NA", format(signif(x, 8), scientific = FALSE))

cat(sprintf("RESULT:race_iat_mixed_room_whites_table3_col1=%s\n", fmt(t3_w$b)))
cat(sprintf("RESULT:race_iat_mixed_room_blacks_table3_col2=%s\n", fmt(t3_b$b)))
cat(sprintf("RESULT:n_obs_table3_whites=%s\n", fmt(t3_w$n)))
cat(sprintf("RESULT:n_obs_table3_blacks=%s\n", fmt(t3_b$n)))
cat(sprintf("RESULT:gpa_mixed_room_blacks_table4_panelB_col1=%s\n", fmt(t4$GPA_b$b)))
cat(sprintf("RESULT:exams_passed_mixed_room_blacks_table4_panelB_col2=%s\n", fmt(t4$examspassed_b$b)))
cat(sprintf("RESULT:eligible_mixed_room_blacks_table4_panelB_col3=%s\n", fmt(t4$continue_b$b)))
cat(sprintf("RESULT:performance_index_mixed_room_blacks_table4_panelB_col4=%s\n", fmt(t4$PCAperf_b$b)))
cat(sprintf("RESULT:gpa_mixed_room_whites_table4_panelA_col1=%s\n", fmt(t4$GPA_w$b)))
cat(sprintf("RESULT:gpa_mixed_room_full_table4_panelC_col1=%s\n", fmt(t4$GPA_f$b)))
cat(sprintf("RESULT:exams_passed_mixed_room_full_table4_panelC_col2=%s\n", fmt(t4$examspassed_f$b)))
cat(sprintf("RESULT:performance_index_mixed_room_full_table4_panelC_col4=%s\n", fmt(t4$PCAperf_f$b)))
cat(sprintf("RESULT:n_obs_table4_panelC_cols1_2=%s\n", fmt(t4$GPA_f$n)))