suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_2022_patient_demand_prescription_overuse.script-free"
fpath <- file.path(base, "Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta")
d <- haven::read_dta(fpath)
d <- haven::zap_labels(d)
d <- as.data.frame(d)
nm <- names(d)
cat("Rows:", nrow(d), " Cols:", ncol(d), "\n")

num <- function(x) {
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(as.numeric(x))
  suppressWarnings(as.numeric(x))
}
is_bin <- function(x) {
  x <- num(x)
  v <- unique(x[!is.na(x)])
  length(v) == 2 && all(v %in% c(0, 1))
}

# ---------------- Sample: in-clinic survey patients ----------------
keep <- rep(TRUE, nrow(d))
if ("patient" %in% nm && is_bin(d$patient)) {
  s <- sum(num(d$patient) == 1, na.rm = TRUE)
  cat("patient==1 count:", s, "\n")
  if (s > 1000) keep <- num(d$patient) %in% 1
}
# treatment indicators
pv_name <- if ("patient_voucher" %in% nm) "patient_voucher" else grep("^patient_?voucher$|^PV$", nm, value = TRUE, ignore.case = TRUE)[1]
dv_name <- if ("doctor_voucher" %in% nm) "doctor_voucher" else grep("^doctor_?voucher$|^DV$", nm, value = TRUE, ignore.case = TRUE)[1]
cat("Treatment vars:", pv_name, dv_name, "\n")
d$PV <- num(d[[pv_name]])
d$DV <- num(d[[dv_name]])
keep <- keep & !is.na(d$PV) & !is.na(d$DV)

# date
date_name <- if ("date" %in% nm) "date" else grep("date", nm, value = TRUE, ignore.case = TRUE)[1]
d$datef <- as.character(d[[date_name]])
keep <- keep & !is.na(d$datef) & d$datef != ""

# clinic id
clin_cands <- unique(c(intersect(c("cscom", "cscomnum", "cscom_id", "cscomid", "cscom_num", "cscomnum_OS",
                                   "clinic", "clinic_id", "clinicid", "CSCom", "cscomID"), nm),
                       grep("cscom|clinic", nm, value = TRUE, ignore.case = TRUE)))
clin_name <- NA
best <- Inf
for (v in clin_cands) {
  x <- d[[v]][keep]
  if (is.list(x)) next
  nu <- length(unique(x[!is.na(x) & as.character(x) != ""]))
  miss <- mean(is.na(x) | as.character(x) == "")
  if (nu >= 40 && nu <= 80 && miss < 0.05) {
    sc <- abs(nu - 60) + 100 * miss
    if (sc < best) { best <- sc; clin_name <- v }
  }
}
cat("Clinic var:", clin_name, "\n")
d$clinic <- as.character(d[[clin_name]])
keep <- keep & !is.na(d$clinic) & d$clinic != ""

ds <- d[keep, ]
cat("Analysis sample (in-clinic patients):", nrow(ds), "\n")
cat("Clinics:", length(unique(ds$clinic)), " Dates:", length(unique(ds$datef)), "\n")
cat("PV share:", mean(ds$PV), " DV share:", mean(ds$DV), "\n")

# ---------------- Outcome search helpers ----------------
find_bin <- function(includes, exclude = NULL, data = ds, minfrac = 0.5) {
  cand <- nm
  for (p in includes) cand <- cand[grepl(p, cand, ignore.case = TRUE)]
  if (!is.null(exclude)) cand <- cand[!grepl(exclude, cand, ignore.case = TRUE)]
  ok <- character(0)
  for (v in cand) {
    x <- data[[v]]
    if (is.list(x)) next
    xn <- num(x)
    if (sum(!is.na(xn)) >= minfrac * nrow(data) && is_bin(xn)) ok <- c(ok, v)
  }
  if (length(ok) == 0) return(NA_character_)
  ok[order(nchar(ok))][1]
}

cat("\nCandidate outcome-related names:\n")
print(head(grep("vouch|mal|rx|presc|purch|sev|quin|inject", nm, value = TRUE, ignore.case = TRUE), 300))

# ---------------- Voucher used ----------------
vu_direct <- intersect(c("used_voucher", "voucher_used", "usedvoucher", "voucher_use", "RXvoucher_used", "vouchers_used"), nm)
vu_name <- NA
for (v in vu_direct) {
  if (is_bin(ds[[v]]) && sum(!is.na(num(ds[[v]]))) > 0.8 * nrow(ds)) { vu_name <- v; break }
}
if (!is.na(vu_name)) {
  ds$y_vu <- num(ds[[vu_name]])
  cat("Voucher-use var:", vu_name, "\n")
} else if (all(c("voucher_used_PV", "voucher_used_DV") %in% nm)) {
  ds$y_vu <- as.numeric((num(ds$voucher_used_PV) %in% 1) | (num(ds$voucher_used_DV) %in% 1))
  cat("Voucher-use constructed from administrative voucher_used_PV / voucher_used_DV\n")
} else {
  v <- find_bin(list("vouch", "use"), exclude = "home|_h$")
  ds$y_vu <- if (!is.na(v)) num(ds[[v]]) else NA
  cat("Voucher-use var (search):", v, "\n")
}

excl_any <- "sev|simp|act|home|_h$|pred|test|rdt|pos|neg|_dv$|_pv$|vouch|ctrl|control|know|hist|past|prev|before|bl_|base"
excl_sev <- "simp|home|_h$|pred|test|rdt|pos|neg|_dv$|_pv$|vouch|ctrl|control|know|hist|past|prev|before|bl_|base|symp"

any_rx <- intersect(c("RXtreat_mal", "RX_any_mal", "RXany_mal", "RX_mal", "RXmal", "RXmalaria", "prescribed_any_mal",
                      "RXantimalarial", "any_mal_RX", "rx_any_mal", "RXtreat_any"), nm)[1]
if (is.na(any_rx)) any_rx <- find_bin(list("rx|presc", "mal"), exclude = excl_any)
if (is.na(any_rx)) any_rx <- find_bin(list("^treat|^rx", "any"), exclude = excl_any)

any_pu <- intersect(c("purch_treat_mal", "purch_any_mal", "PURCHtreat_mal", "purchased_any_mal", "purch_mal",
                      "bought_mal", "PURtreat_mal", "purch_malaria"), nm)[1]
if (is.na(any_pu)) any_pu <- find_bin(list("purch|bought|buy|^pur|_pur", "mal"), exclude = excl_any)
if (is.na(any_pu)) any_pu <- find_bin(list("purch|bought|buy|^pur|_pur", "any"), exclude = excl_any)

sev_rx <- intersect(c("RXtreat_sev", "RX_sev_mal", "RXsev_mal", "RXsevere", "RX_severe", "prescribed_severe",
                      "RXtreat_severe"), nm)[1]
if (is.na(sev_rx)) sev_rx <- find_bin(list("rx|presc", "sev"), exclude = excl_sev)
if (is.na(sev_rx)) sev_rx <- find_bin(list("^treat", "sev"), exclude = excl_sev)

sev_pu <- intersect(c("purch_treat_sev", "purch_sev_mal", "PURCHtreat_sev", "purch_severe", "purchased_severe",
                      "bought_sev"), nm)[1]
if (is.na(sev_pu)) sev_pu <- find_bin(list("purch|bought|buy|^pur|_pur", "sev"), exclude = excl_sev)

cat("Outcome vars: any_rx =", any_rx, "| any_purch =", any_pu, "| sev_rx =", sev_rx, "| sev_purch =", sev_pu, "\n")

getv <- function(v) if (is.na(v)) rep(NA_real_, nrow(ds)) else num(ds[[v]])
ds$y_anyrx <- getv(any_rx)
ds$y_anypu <- getv(any_pu)
ds$y_sevrx <- getv(sev_rx)
ds$y_sevpu <- getv(sev_pu)

# ---------------- Regressions ----------------
# NOTE: glmnet is not available, so post-double-selection lasso controls are not added;
# baseline specification (voucher dummies + date fixed effects, clinic-clustered SEs) is used.
run <- function(y) {
  if (all(is.na(ds[[y]]))) return(NULL)
  f <- as.formula(paste0(y, " ~ PV + DV | datef"))
  tryCatch(feols(f, data = ds, cluster = ~clinic), error = function(e) { print(e); NULL })
}
co <- function(m, v) if (is.null(m)) NA else unname(coef(m)[v])

m1 <- run("y_vu"); m2 <- run("y_anyrx"); m3 <- run("y_anypu"); m4 <- run("y_sevrx"); m5 <- run("y_sevpu")
for (m in list(m1, m2, m3, m4, m5)) if (!is.null(m)) print(summary(m))

n1 <- if (is.null(m1)) nrow(ds) else nobs(m1)
n2 <- if (!is.null(m2)) nobs(m2) else if (!is.null(m3)) nobs(m3) else NA

cat(sprintf("RESULT:voucher_used_patient_voucher_table3_col1=%.6f\n", co(m1, "PV")))
cat(sprintf("RESULT:voucher_used_doctor_voucher_table3_col1=%.6f\n", co(m1, "DV")))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_patient_voucher_table3_col2=%.6f\n", co(m2, "PV")))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_doctor_voucher_table3_col2=%.6f\n", co(m2, "DV")))
cat(sprintf("RESULT:any_malaria_treatment_purchased_patient_voucher_table3_col3=%.6f\n", co(m3, "PV")))
cat(sprintf("RESULT:any_malaria_treatment_purchased_doctor_voucher_table3_col3=%.6f\n", co(m3, "DV")))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_patient_voucher_table3_col4=%.6f\n", co(m4, "PV")))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_doctor_voucher_table3_col4=%.6f\n", co(m4, "DV")))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_patient_voucher_table3_col5=%.6f\n", co(m5, "PV")))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_doctor_voucher_table3_col5=%.6f\n", co(m5, "DV")))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", as.integer(n1)))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%d\n", as.integer(n2)))
