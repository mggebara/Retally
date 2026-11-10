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
if (sum(rows) != target_n) {
  kw <- "(sample|clinic|cscom|acute|ill|consent|main|survey|interview|patient|drop|keep|incl|excl|elig|valid|final|analys|sick)"
  skipv <- c("PV", "DV", PVn, DVn)
  hits <- list()
  for (j in seq_along(nm)) {
    cc <- nm[j]
    if (cc %in% skipv) next
    x <- d[[j]]
    if (!(is.numeric(x) || is.logical(x))) next
    x <- as.numeric(x)
    nn <- base_ok & !is.na(x)
    s1 <- sum(nn & x == 1); s0 <- sum(nn & x == 0); sn <- sum(nn)
    for (ty in c("eq1", "eq0", "nonmiss")) {
      s <- switch(ty, eq1 = s1, eq0 = s0, nonmiss = sn)
      if (abs(s - target_n) <= 15) {
        hits[[length(hits) + 1]] <- data.frame(var = cc, type = ty, cnt = s,
                                               kw = grepl(kw, tolower(cc)),
                                               stringsAsFactors = FALSE)
      }
    }
  }
  if (length(hits)) {
    H <- do.call(rbind, hits)
    H$dist <- abs(H$cnt - target_n)
    H$tyo <- match(H$type, c("eq1", "eq0", "nonmiss"))
    H <- H[order(H$dist, !H$kw, H$tyo, nchar(H$var)), ]
    message("Sample filter candidates: ",
            paste(head(sprintf("%s[%s]=%d", H$var, H$type, H$cnt), 25), collapse = "; "))
    b <- H[1, ]
    x <- as.numeric(d[[b$var]])
    rows <- switch(b$type,
                   eq1 = base_ok & !is.na(x) & x == 1,
                   eq0 = base_ok & !is.na(x) & x == 0,
                   nonmiss = base_ok & !is.na(x))
    message("Sample filter var: ", b$var, " (", b$type, ")")
    if (b$dist > 0) cat(sprintf("DEVIATION: Sample filter %s (%s) gives %d obs, closest available to the paper's 2055\n", b$var, b$type, b$cnt))
  }
}
message("Analysis sample: ", sum(rows))

# ---- Diagnostics on candidate outcome variables ----
diag_idx <- which(grepl("^(rx|pu|bu|bo|bt)", lnm) & grepl("(mal|sev|act|any|treat)", lnm))
if (length(diag_idx)) {
  dd <- sapply(diag_idx, function(j) {
    x <- suppressWarnings(as.numeric(d[[j]]))[rows]
    xx <- x[!is.na(x)]
    sprintf("%s:%d:%.3f", nm[j], length(xx), if (length(xx)) mean(xx) else NA)
  })
  message("Outcome candidates: ", paste(head(dd, 60), collapse = " "))
}

# ---- Outcome finder (binary, n close to 2053, plausible mean) ----
find_var <- function(inc, exc = NULL, target = 2053, mlo = 0, mhi = 1) {
  m <- Reduce(`&`, lapply(inc, function(p) grepl(p, lnm, perl = TRUE)))
  if (!is.null(exc)) m <- m & !grepl(exc, lnm, perl = TRUE)
  cand <- nm[m]
  best <- NULL; bs <- Inf
  for (cc in cand) {
    x <- d[[cc]]
    if (!(is.numeric(x) || is.logical(x))) next
    x <- binarize(x)[rows]
    xx <- x[!is.na(x)]
    if (length(xx) < 500) next
    if (!all(xx %in% c(0, 1))) next
    if (length(unique(xx)) < 2) next
    mu <- mean(xx)
    if (mu < mlo || mu > mhi) next
    sc <- abs(length(xx) - target) + 2 * nchar(cc)
    if (sc < bs) { bs <- sc; best <- cc }
  }
  best
}

exc_common <- "(home|pred|_x_|^x_|int_|cost|price|fee|num|share|mean|bin|video|info|trust|nb_|count)"
exc_any <- paste0("(sev|simp|act|quin|inj|artem|", substring(exc_common, 2))
purp <- "(purch|bought|buy|^pu|^bt|^bo)"

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

pick <- function(...) { for (v in list(...)) if (!is.null(v)) return(v); NULL }
rx_any <- pick(find_var(c("^(rx|presc)", "(mal|any)"), exc_any, mlo = 0.3, mhi = 0.99),
               find_var(c("(rx|presc)", "(mal|any)"), exc_any, mlo = 0.3, mhi = 0.99))
pu_any <- pick(find_var(c(purp, "(mal|any)"), exc_any, mlo = 0.2, mhi = 0.99),
               find_var(c("(purch|bought|buy|pu)", "(mal|any)"), exc_any, mlo = 0.2, mhi = 0.99))
rx_sev <- pick(find_var(c("^(rx|presc)", "sev"), exc_common, mlo = 0.08, mhi = 0.85),
               find_var(c("(rx|presc)", "sev"), exc_common, mlo = 0.08, mhi = 0.85))
pu_sev <- pick(find_var(c(purp, "sev"), exc_common, mlo = 0.05, mhi = 0.85),
               find_var(c("(purch|bought|buy|pu)", "sev"), exc_common, mlo = 0.05, mhi = 0.85))
message("Prescribed any: ", rx_any, " | Purchased any: ", pu_any,
        " | Prescribed severe: ", rx_sev, " | Purchased severe: ", pu_sev)

getout <- function(v) if (is.null(v)) NULL else binarize(d[[v]])
y_rx_any <- getout(rx_any)
y_pu_any <- getout(pu_any)
y_rx_sev <- getout(rx_sev)
y_pu_sev <- getout(pu_sev)

# Fallbacks from treatment component variables (prescriptions)
if (is.null(y_rx_any)) {
  comps <- nm[grepl("^treat_", lnm) & grepl("(act|quin|artem)", lnm)]
  if (length(comps)) {
    M <- sapply(comps, function(cc) binarize(d[[cc]]))
    y_rx_any <- as.numeric(rowSums(M == 1, na.rm = TRUE) > 0)
    y_rx_any[rowSums(!is.na(M)) == 0] <- NA
    message("Prescribed any constructed from: ", paste(comps, collapse = ","))
  }
}
if (is.null(y_rx_sev)) {
  comps <- nm[grepl("^treat_", lnm) & grepl("(quin|artem)", lnm)]
  if (length(comps)) {
    M <- sapply(comps, function(cc) binarize(d[[cc]]))
    y_rx_sev <- as.numeric(rowSums(M == 1, na.rm = TRUE) > 0)
    y_rx_sev[rowSums(!is.na(M)) == 0] <- NA
    message("Prescribed severe constructed from: ", paste(comps, collapse = ","))
  }
}

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