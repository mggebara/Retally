suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/corno_2022_interaction_stereotypes_performance"
dta_path <- file.path(base_dir, "ForJournals_a/Data/Clean/uctdata_balanced.dta")

df <- haven::read_dta(dta_path)
df <- haven::zap_labels(df)
df <- as.data.frame(df)
for (v in names(df)) {
  if (inherits(df[[v]], "haven_labelled")) df[[v]] <- as.numeric(df[[v]])
}

# ---- Panel identifier and lag (Stata: xtset individual round; L.var) ----
id_var <- if ("individual" %in% names(df)) "individual" else if ("nstudent" %in% names(df)) "nstudent" else NA
if (is.na(id_var)) stop("No individual identifier found")
df$.pid <- df[[id_var]]

make_lag <- function(d, var) {
  base <- d[d$round == 1 & !is.na(d$.pid), c(".pid", var)]
  base <- base[!duplicated(base$.pid), ]
  names(base)[2] <- "lagval"
  m <- match(d$.pid, base$.pid)
  out <- base$lagval[m]
  out[d$round != 1 + 1] <- NA  # lag only defined for round 2 (round 1 has no predecessor)
  out
}
df$L_DscoreraceIAT <- make_lag(df, "DscoreraceIAT")
df$L_DscoreacaIAT <- make_lag(df, "DscoreacaIAT")

# ---- Reconstruct missing roommate consumption missing-indicator ----
# The do-file's roommate control list includes roconsbas_miss, which is not in the
# cleaned dataset. Omitting it changes the specification (all other own/roommate
# controls carry their missing-value dummies), so rebuild it.
if (!("roconsbas_miss" %in% names(df))) {
  cand <- grep("^rocons.*miss", names(df), value = TRUE, ignore.case = TRUE)
  cand <- setdiff(cand, c("roconsbas_nomiss"))
  built <- FALSE
  if (length(cand) > 0) {
    df$roconsbas_miss <- as.numeric(df[[cand[1]]])
    message("roconsbas_miss taken from ", cand[1])
    built <- TRUE
  }
  if (!built && all(c("roomnum_base", "consbas_miss") %in% names(df))) {
    # roommate = other student with the same baseline room number
    pr <- df[!is.na(df$roomnum_base) & !is.na(df$.pid), c(".pid", "roomnum_base", "consbas_miss")]
    pr <- pr[!duplicated(pr$.pid), ]
    rm_val <- rep(NA_real_, nrow(df))
    for (i in seq_len(nrow(df))) {
      if (is.na(df$roomnum_base[i])) next
      o <- pr[pr$roomnum_base == df$roomnum_base[i] & pr$.pid != df$.pid[i], "consbas_miss"]
      o <- o[!is.na(o)]
      if (length(o) > 0) rm_val[i] <- o[1]
    }
    df$roconsbas_miss <- rm_val
    built <- TRUE
  }
  if ("roconsbas_nomiss" %in% names(df)) {
    # For roommates not found in the data: mean-imputed value identifies missingness
    x <- df$roconsbas_nomiss
    tb <- table(round(x, 6))
    modal <- as.numeric(names(tb)[which.max(tb)])
    imp_flag <- as.numeric(!is.na(x) & abs(x - modal) < 1e-5 & max(tb) >= 3)
    if (!built) df$roconsbas_miss <- imp_flag
    else df$roconsbas_miss[is.na(df$roconsbas_miss)] <- imp_flag[is.na(df$roconsbas_miss)]
  }
  if ("roconsbas_miss" %in% names(df)) {
    df$roconsbas_miss[is.na(df$roconsbas_miss)] <- 0
    message("Constructed roconsbas_miss; mean = ", mean(df$roconsbas_miss))
    cat("DEVIATION: roconsbas_miss (roommate consumption missing dummy) absent from data; reconstructed from roommate's consbas_miss / mean-imputed roconsbas_nomiss\n")
  }
}

# ---- Control lists (from 1_main_tables.do) ----
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
  miss <- setdiff(vars, names(df))
  if (length(miss) > 0) message("WARNING: variables not found, dropped: ", paste(miss, collapse = ", "))
  intersect(vars, names(df))
}
controls_full <- keep_present(controls_full)
controls_sub <- keep_present(controls_sub)
rocontrols <- keep_present(rocontrols)

# Factor FE variables
for (v in c("Res_base", "blackRes", "whiteRes", "regprogram")) {
  if (v %in% names(df)) df[[paste0("f_", v)]] <- factor(df[[v]])
}

run_reg <- function(dep, rhs, fe, data) {
  fml <- as.formula(paste0(dep, " ~ ", paste(rhs, collapse = " + "), " | ", paste(fe, collapse = " + ")))
  tryCatch(
    feols(fml, data = data, cluster = ~roomnum_base, fixef.rm = "none", warn = FALSE, notes = FALSE),
    error = function(e) { message("Regression failed for ", dep, ": ", conditionMessage(e)); NULL }
  )
}

get_coef <- function(m, v = "mixracebas") {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (v %in% names(cf)) unname(cf[v]) else NA_real_
}
get_se <- function(m, v = "mixracebas") {
  if (is.null(m)) return(NA_real_)
  s <- tryCatch(sqrt(diag(vcov(m))), error = function(e) NULL)
  if (!is.null(s) && v %in% names(s)) unname(s[v]) else NA_real_
}
get_n <- function(m) if (is.null(m)) NA_real_ else nobs(m)

r2 <- df[df$round == 2, ]
r2w <- r2[!is.na(r2$white) & r2$white == 1, ]
r2b <- r2[!is.na(r2$black) & r2$black == 1, ]

# ---- Table 3: Race IAT ----
m_t3_w <- run_reg("DscoreraceIAT", c("mixracebas", "L_DscoreraceIAT", controls_sub, rocontrols),
                  c("f_Res_base"), r2w)
m_t3_b <- run_reg("DscoreraceIAT", c("mixracebas", "L_DscoreraceIAT", controls_sub, rocontrols),
                  c("f_Res_base"), r2b)
# Academic IAT (for N in columns 3/4 consistency check)
m_t3_w_aca <- run_reg("DscoreacaIAT", c("mixracebas", "L_DscoreacaIAT", controls_sub, rocontrols),
                      c("f_Res_base"), r2w)
m_t3_b_aca <- run_reg("DscoreacaIAT", c("mixracebas", "L_DscoreacaIAT", controls_sub, rocontrols),
                      c("f_Res_base"), r2b)

# ---- Table 4: academic performance ----
outcomes4 <- c("GPA", "examspassed", "continue", "PCAperf")
t4 <- list()
for (y in outcomes4) {
  t4[[paste0(y, "_w")]] <- run_reg(y, c("mixracebas", controls_sub, rocontrols),
                                   c("f_Res_base", "f_regprogram"), r2w)
  t4[[paste0(y, "_b")]] <- run_reg(y, c("mixracebas", controls_sub, rocontrols),
                                   c("f_Res_base", "f_regprogram"), r2b)
  t4[[paste0(y, "_f")]] <- run_reg(y, c("mixracebas", controls_full, rocontrols),
                                   c("f_blackRes", "f_whiteRes", "f_Res_base", "f_regprogram"), r2)
}

# Diagnostics
message(sprintf("Table3 white race: b=%.4f se=%.4f N=%s", get_coef(m_t3_w), get_se(m_t3_w), get_n(m_t3_w)))
message(sprintf("Table3 black race: b=%.4f se=%.4f N=%s", get_coef(m_t3_b), get_se(m_t3_b), get_n(m_t3_b)))
message(sprintf("Table3 white aca: b=%.4f N=%s", get_coef(m_t3_w_aca), get_n(m_t3_w_aca)))
message(sprintf("Table3 black aca: b=%.4f N=%s", get_coef(m_t3_b_aca), get_n(m_t3_b_aca)))
for (nm in names(t4)) {
  message(sprintf("Table4 %s: b=%.4f se=%.4f N=%s", nm, get_coef(t4[[nm]]), get_se(t4[[nm]]), get_n(t4[[nm]])))
}

fmt <- function(x) if (is.na(x)) "NA" else format(x, digits = 10)

cat(paste0("RESULT:race_iat_mixed_room_whites_table3_col1=", fmt(get_coef(m_t3_w)), "\n"))
cat(paste0("RESULT:race_iat_mixed_room_blacks_table3_col2=", fmt(get_coef(m_t3_b)), "\n"))
cat(paste0("RESULT:n_obs_table3_whites=", fmt(get_n(m_t3_w)), "\n"))
cat(paste0("RESULT:n_obs_table3_blacks=", fmt(get_n(m_t3_b)), "\n"))
cat(paste0("RESULT:gpa_mixed_room_blacks_table4_panelB_col1=", fmt(get_coef(t4[["GPA_b"]])), "\n"))
cat(paste0("RESULT:exams_passed_mixed_room_blacks_table4_panelB_col2=", fmt(get_coef(t4[["examspassed_b"]])), "\n"))
cat(paste0("RESULT:eligible_mixed_room_blacks_table4_panelB_col3=", fmt(get_coef(t4[["continue_b"]])), "\n"))
cat(paste0("RESULT:performance_index_mixed_room_blacks_table4_panelB_col4=", fmt(get_coef(t4[["PCAperf_b"]])), "\n"))
cat(paste0("RESULT:gpa_mixed_room_whites_table4_panelA_col1=", fmt(get_coef(t4[["GPA_w"]])), "\n"))
cat(paste0("RESULT:gpa_mixed_room_full_table4_panelC_col1=", fmt(get_coef(t4[["GPA_f"]])), "\n"))
cat(paste0("RESULT:exams_passed_mixed_room_full_table4_panelC_col2=", fmt(get_coef(t4[["examspassed_f"]])), "\n"))
cat(paste0("RESULT:performance_index_mixed_room_full_table4_panelC_col4=", fmt(get_coef(t4[["PCAperf_f"]])), "\n"))
cat(paste0("RESULT:n_obs_table4_panelC_cols1_2=", fmt(get_n(t4[["GPA_f"]])), "\n"))
