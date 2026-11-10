suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/lopez_2022_patient_demand_prescription_overuse.script-free"
fpath <- file.path(root, "Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta")

d <- haven::read_dta(fpath)
d <- as.data.frame(haven::zap_labels(d))
nm <- names(d)
lnm <- tolower(nm)
message("Rows: ", nrow(d), " Cols: ", ncol(d))

getv <- function(cands) {
  for (cc in cands) {
    i <- which(lnm == tolower(cc))
    if (length(i)) return(nm[i[1]])
  }
  NULL
}
tonum <- function(x) {
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(as.numeric(x))
  if (is.numeric(x) || is.logical(x)) return(as.numeric(x))
  suppressWarnings(as.numeric(as.character(x)))
}
binarize <- function(x) {
  x <- tonum(x)
  xx <- unique(x[!is.na(x)])
  if (length(xx) && all(xx %in% c(1, 2)) && !all(xx %in% c(0, 1))) x <- ifelse(is.na(x), NA, ifelse(x == 1, 1, 0))
  x
}

# ---- Treatment indicators ----
PVn <- getv(c("patient_voucher", "pv", "pv_day", "patientvoucher"))
DVn <- getv(c("doctor_voucher", "dv", "dv_day", "doctorvoucher"))
message("PV var: ", PVn, " DV var: ", DVn)
d$PV <- binarize(d[[PVn]])
d$DV <- binarize(d[[DVn]])
d$PV[is.na(d$PV) & !is.na(d$DV)] <- 0
d$DV[is.na(d$DV) & !is.na(d$PV)] <- 0

# ---- Clinic identifier ----
clin <- getv(c("cscomnum", "cscom", "cscom_id", "cscomid", "cscom_num", "cscomnum_os",
               "clinic", "clinic_id", "clinicid", "clinic_num"))
if (is.null(clin)) {
  for (cc in nm[grepl("(cscom|clinic)", lnm)]) {
    x <- d[[cc]]
    k <- length(unique(x[!is.na(x)]))
    if (k >= 50 && k <= 70) { clin <- cc; break }
  }
}
message("Clinic var: ", clin)
d$clinic_id <- as.character(d[[clin]])
d$clinic_id[d$clinic_id == ""] <- NA

# ---- Date fixed effects ----
dvar <- getv(c("date", "date_cscom", "survey_date", "visit_date", "date_clinic"))
message("Date var: ", dvar)
dx <- d[[dvar]]
if (inherits(dx, "POSIXt")) dx <- as.Date(dx)
d$date_fe <- as.character(dx)
d$date_fe[d$date_fe == ""] <- NA

# ---- Sample: in-clinic survey patients (paper: 2,055 acutely ill patients) ----
target_n <- 2055
base_ok <- !is.na(d$PV) & !is.na(d$DV) & !is.na(d$clinic_id) & !is.na(d$date_fe)
rows <- base_ok
message("Base sample: ", sum(rows))
dm <- getv("dropme")
if (!is.null(dm)) {
  x <- as.numeric(d[[dm]])
  rows <- base_ok & !is.na(x) & x == 0
  message("Sample filter var: dropme (eq0)")
}
message("Analysis sample: ", sum(rows))

# ---- Outcome finder by exact suffix (any prefix other than RX = purchase) ----
pick_suffix <- function(suffix, prefix_re, exclude_re = NULL, target = 2053) {
  m <- grepl(paste0(suffix, "$"), lnm) & grepl(prefix_re, lnm, perl = TRUE)
  if (!is.null(exclude_re)) m <- m & !grepl(exclude_re, lnm, perl = TRUE)
  cand <- nm[m]
  info <- sapply(cand, function(cc) {
    x <- suppressWarnings(binarize(d[[cc]]))[rows]
    xx <- x[!is.na(x)]
    sprintf("%s:%d:%.3f", cc, length(xx), if (length(xx)) mean(xx) else NA)
  })
  if (length(info)) message("Candidates for ", suffix, " [", prefix_re, "]: ", paste(info, collapse = " "))
  best <- NULL; bs <- Inf
  for (cc in cand) {
    x <- d[[cc]]
    if (!(is.numeric(x) || is.logical(x))) next
    x <- binarize(x)[rows]
    xx <- x[!is.na(x)]
    if (length(xx) < 500) next
    if (!all(xx %in% c(0, 1))) next
    if (length(unique(xx)) < 2) next
    sc <- abs(length(xx) - target) + 2 * nchar(cc)
    if (sc < bs) { bs <- sc; best <- cc }
  }
  best
}

# Diagnostic: list all variables ending in the treatment suffixes
allsfx <- nm[grepl("(treat_sev_simple_mal|treat_severe_mal|treat_simple_mal)$", lnm)]
message("All treatment-suffix vars: ", paste(allsfx, collapse = " "))

excl_purch <- "(^rx|home|hh_|_h_|^h_|pred|rdt)"
rx_any <- pick_suffix("treat_sev_simple_mal", "^rx")
rx_sev <- pick_suffix("treat_severe_mal", "^rx")
pu_any <- pick_suffix("treat_sev_simple_mal", ".", excl_purch)
pu_sev <- pick_suffix("treat_severe_mal", ".", excl_purch)
message("Prescribed any: ", rx_any, " | Purchased any: ", pu_any,
        " | Prescribed severe: ", rx_sev, " | Purchased severe: ", pu_sev)

# Voucher used
vu <- getv(c("used_voucher", "voucher_used", "voucherused", "usedvoucher", "voucher_use", "any_voucher_used"))
if (!is.null(vu)) {
  y_vouch <- binarize(d[[vu]])
  y_vouch[is.na(y_vouch)] <- 0
  message("Voucher used var: ", vu)
} else {
  pvu <- if (!is.null(getv("voucher_used_PV"))) binarize(d[[getv("voucher_used_PV")]]) else rep(0, nrow(d))
  dvu <- if (!is.null(getv("voucher_used_DV"))) binarize(d[[getv("voucher_used_DV")]]) else rep(0, nrow(d))
  pvu[is.na(pvu)] <- 0; dvu[is.na(dvu)] <- 0
  y_vouch <- pmax(pvu, dvu)
  message("Voucher used constructed from voucher_used_PV / voucher_used_DV")
}

getout <- function(v) if (is.null(v)) NULL else binarize(d[[v]])
y_rx_any <- getout(rx_any)
y_pu_any <- getout(pu_any)
y_rx_sev <- getout(rx_sev)
y_pu_sev <- getout(pu_sev)

# ---- Regressions: y = bP*PV + bD*DV + date FE, SE clustered by clinic ----
run <- function(y) {
  if (is.null(y)) return(NULL)
  tryCatch({
    df <- d[rows, c("PV", "DV", "date_fe", "clinic_id")]
    df$y <- y[rows]
    df <- df[!is.na(df$y), ]
    m <- feols(y ~ PV + DV | date_fe, data = df, cluster = ~clinic_id)
    print(summary(m))
    list(b = coef(m), se = sqrt(diag(vcov(m))), n = nobs(m))
  }, error = function(e) { message("Regression error: ", conditionMessage(e)); NULL })
}

r1 <- run(y_vouch)
r2 <- run(y_rx_any)
r3 <- run(y_pu_any)
r4 <- run(y_rx_sev)
r5 <- run(y_pu_sev)

out <- function(name, val) {
  v <- if (is.null(val) || length(val) == 0 || is.na(val)) NA else as.numeric(val)
  cat(sprintf("RESULT:%s=%s\n", name, ifelse(is.na(v), "NA", format(v, digits = 8))))
}
g <- function(r, k) if (is.null(r)) NA else unname(r$b[k])

out("voucher_used_patient_voucher_table3_col1", g(r1, "PV"))
out("voucher_used_doctor_voucher_table3_col1", g(r1, "DV"))
out("any_malaria_treatment_prescribed_patient_voucher_table3_col2", g(r2, "PV"))
out("any_malaria_treatment_prescribed_doctor_voucher_table3_col2", g(r2, "DV"))
out("any_malaria_treatment_purchased_patient_voucher_table3_col3", g(r3, "PV"))
out("any_malaria_treatment_purchased_doctor_voucher_table3_col3", g(r3, "DV"))
out("severe_malaria_treatment_prescribed_patient_voucher_table3_col4", g(r4, "PV"))
out("severe_malaria_treatment_prescribed_doctor_voucher_table3_col4", g(r4, "DV"))
out("severe_malaria_treatment_purchased_patient_voucher_table3_col5", g(r5, "PV"))
out("severe_malaria_treatment_purchased_doctor_voucher_table3_col5", g(r5, "DV"))
out("n_obs_table3_col1", if (is.null(r1)) NA else r1$n)
n25 <- NA
for (r in list(r2, r3, r4, r5)) if (!is.null(r)) { n25 <- r$n; break }
out("n_obs_table3_cols2_5", n25)
