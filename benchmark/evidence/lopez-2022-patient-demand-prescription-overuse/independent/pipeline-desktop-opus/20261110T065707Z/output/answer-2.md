suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_2022_patient_demand_prescription_overuse.script-free"
f <- file.path(base, "Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta")
d <- haven::read_dta(f)
d <- haven::zap_labels(d)
d <- as.data.frame(d)
nm <- names(d)
cat("Rows:", nrow(d), " Cols:", ncol(d), "\n")

show_names <- function(pat) {
  m <- grep(pat, nm, value = TRUE, ignore.case = TRUE)
  cat("Vars matching '", pat, "': ", paste(head(m, 60), collapse = ", "), "\n", sep = "")
  invisible(m)
}
pick <- function(cands, pats = NULL) {
  for (c in cands) if (c %in% nm) return(c)
  if (!is.null(pats)) for (p in pats) {
    m <- grep(p, nm, value = TRUE, ignore.case = TRUE)
    if (length(m) > 0) return(m[1])
  }
  NA_character_
}
num <- function(x) suppressWarnings(as.numeric(x))

# diagnostics for feedback
invisible(show_names("cscom|clinic"))
invisible(show_names("severe"))
invisible(show_names("used"))
invisible(show_names("^patient|^id|_id$|hhid"))

# ---- treatment dummies ----
pv_var <- pick(c("patient_voucher", "PV", "pv"))
dv_var <- pick(c("doctor_voucher", "DV", "dv"))
d$PV <- num(d[[pv_var]])
d$DV <- num(d[[dv_var]])

# ---- clinic id and date ----
cl_var <- pick(c("cscomnum", "cscom", "cscomnum_OS", "clinic", "clinic_id", "CSCom"),
               c("^cscom", "clinic"))
date_var <- pick(c("date", "date_clinic", "visit_date"), c("^date"))
cat("Using PV:", pv_var, " DV:", dv_var, " clinic:", cl_var, " date:", date_var, "\n")
d$clinic <- as.character(d[[cl_var]])
d$datefe <- as.character(d[[date_var]])
cat("Non-missing clinic:", sum(!is.na(d$clinic) & d$clinic != ""),
    " non-missing date:", sum(!is.na(d$datefe) & d$datefe != ""),
    " unique dates:", length(unique(d$datefe)), "\n")

# ---- sample: in-clinic surveyed patients ----
d <- d[!is.na(d$PV) & !is.na(d$DV), ]
cat("After non-missing treatment:", nrow(d), "\n")
samp_var <- pick(c("clinic_survey", "in_clinic", "cscom_survey", "sample_clinic", "clinic_sample"))
if (!is.na(samp_var)) {
  tmp <- d[num(d[[samp_var]]) %in% 1, ]
  if (nrow(tmp) > 1000) d <- tmp
}
# (Removed the de-duplication on 'patient': that variable is not a unique patient id
#  and collapsed the sample to a handful of rows.)
if ("patient" %in% nm) {
  cat("Unique values of 'patient':", length(unique(d$patient)), "\n")
}
okcl <- !is.na(d$clinic) & d$clinic != ""
okdt <- !is.na(d$datefe) & d$datefe != ""
d <- d[okcl, ]
if (sum(okdt[okcl]) > 1000) {
  d <- d[okdt[okcl], ]
} else {
  cat("Date variable mostly missing; using clinic-level date fallback\n")
  d$datefe[is.na(d$datefe) | d$datefe == ""] <- "missing"
}
cat("Sample size after restrictions:", nrow(d), "\n")

# ---- outcomes ----
vu_var <- pick(c("voucher_used", "used_voucher", "vouchers_used", "any_voucher_used"))
if (!is.na(vu_var)) {
  d$y_voucher <- num(d[[vu_var]])
} else {
  a <- if ("voucher_used_PV" %in% nm) num(d$voucher_used_PV) else rep(NA, nrow(d))
  b <- if ("voucher_used_DV" %in% nm) num(d$voucher_used_DV) else rep(NA, nrow(d))
  d$y_voucher <- as.numeric((a %in% 1) | (b %in% 1))
}
d$y_voucher[is.na(d$y_voucher)] <- 0

mk <- function(cands, pats) {
  v <- pick(cands, pats)
  cat("Outcome candidate:", paste(cands[1], collapse = ""), "->", v, "\n")
  if (is.na(v)) return(rep(NA_real_, nrow(d)))
  num(d[[v]])
}
d$y_any_rx  <- mk(c("RXtreat_sev_simple_mal", "rx_any_malaria", "prescribed_any_malaria", "any_mal_rx",
                    "RX_antimalarial", "rx_antimalarial", "prescribed_antimalarial", "RXtreat_mal"),
                  c("rx.*(any|anti)?mal", "presc.*mal", "mal.*presc"))
d$y_any_buy <- mk(c("treat_sev_simple_mal", "purchased_any_malaria", "any_mal_purchased",
                    "bought_antimalarial", "purch_antimalarial", "treat_mal"),
                  c("purch.*mal", "mal.*purch", "bought.*mal"))
d$y_sev_rx  <- mk(c("RXtreat_severe_mal", "rx_severe_malaria", "prescribed_severe_malaria", "severe_mal_rx"),
                  c("rx.*sev", "presc.*sev", "sev.*presc", "sev.*rx"))
d$y_sev_buy <- mk(c("treat_severe_mal", "purchased_severe_malaria", "severe_mal_purchased"),
                  c("purch.*sev", "sev.*purch", "^treat_sev"))

if (all(is.na(d$y_sev_buy)) && all(c("treat_ACT", "treat_quinine") %in% nm)) {
  qi <- if ("quinine_injectable" %in% nm) num(d$quinine_injectable) else num(d$treat_quinine)
  d$y_sev_buy <- as.numeric(qi %in% 1 | (num(d$treat_quinine) %in% 1 & num(d$treat_ACT) %in% 1))
}
if (all(is.na(d$y_any_buy)) && all(c("treat_ACT", "treat_quinine") %in% nm)) {
  d$y_any_buy <- as.numeric(num(d$treat_ACT) %in% 1 | num(d$treat_quinine) %in% 1)
}
for (v in c("y_voucher", "y_any_rx", "y_any_buy", "y_sev_rx", "y_sev_buy")) {
  cat(v, ": non-missing =", sum(!is.na(d[[v]])), " mean =", mean(d[[v]], na.rm = TRUE), "\n")
}

run <- function(y) {
  dd <- d[!is.na(d[[y]]), ]
  m <- feols(as.formula(paste0(y, " ~ PV + DV | datefe")), data = dd, cluster = ~clinic)
  print(summary(m))
  list(bP = unname(coef(m)["PV"]), bD = unname(coef(m)["DV"]), n = nobs(m))
}

safe <- function(y) tryCatch(run(y), error = function(e) { cat("Error", y, ":", conditionMessage(e), "\n"); NULL })
r1 <- safe("y_voucher")
r2 <- safe("y_any_rx")
r3 <- safe("y_any_buy")
r4 <- safe("y_sev_rx")
r5 <- safe("y_sev_buy")

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && !is.na(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
}
emit("voucher_used_patient_voucher_table3_col1", r1$bP)
emit("voucher_used_doctor_voucher_table3_col1", r1$bD)
emit("any_malaria_treatment_prescribed_patient_voucher_table3_col2", r2$bP)
emit("any_malaria_treatment_prescribed_doctor_voucher_table3_col2", r2$bD)
emit("any_malaria_treatment_purchased_patient_voucher_table3_col3", r3$bP)
emit("any_malaria_treatment_purchased_doctor_voucher_table3_col3", r3$bD)
emit("severe_malaria_treatment_prescribed_patient_voucher_table3_col4", r4$bP)
emit("severe_malaria_treatment_prescribed_doctor_voucher_table3_col4", r4$bD)
emit("severe_malaria_treatment_purchased_patient_voucher_table3_col5", r5$bP)
emit("severe_malaria_treatment_purchased_doctor_voucher_table3_col5", r5$bD)
emit("n_obs_table3_col1", r1$n)
emit("n_obs_table3_cols2_5", r2$n)
