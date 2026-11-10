suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/lopez_2022_patient_demand_prescription_overuse.script-free"
path <- file.path(root, "Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta")
d <- haven::read_dta(path)
d <- as.data.frame(haven::zap_labels(d))
nm <- names(d)
lnm <- tolower(nm)

tonum <- function(x) {
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(as.numeric(x))
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x))
  if (is.character(x)) {
    y <- tolower(trimws(x))
    out <- suppressWarnings(as.numeric(y))
    out[y %in% c("yes", "oui", "y", "true")] <- 1
    out[y %in% c("no", "non", "n", "false")] <- 0
    out[y == ""] <- NA
    return(out)
  }
  suppressWarnings(as.numeric(x))
}

to01 <- function(x) {
  x <- tonum(x)
  v <- sort(unique(x[!is.na(x)]))
  if (length(v) == 2 && all(v == c(1, 2))) x <- ifelse(x == 1, 1, ifelse(x == 2, 0, NA))
  x
}

getv <- function(cands) {
  for (cc in cands) {
    i <- match(tolower(cc), lnm)
    if (!is.na(i)) return(nm[i])
  }
  NULL
}

# Treatment dummies
pvn <- getv(c("patient_voucher", "pv", "treat_pv", "pv_day"))
dvn <- getv(c("doctor_voucher", "dv", "treat_dv", "dv_day"))
pv <- to01(d[[pvn]])
dv <- to01(d[[dvn]])
message("PV var: ", pvn, "  DV var: ", dvn)

# Date
daten <- getv(c("date", "visit_date", "date_clinic", "survey_date"))
datev <- d[[daten]]
datef <- as.character(datev)

# Sample: in-clinic survey patients
base <- !is.na(pv) & !is.na(dv) & !is.na(datef) & datef != ""
message("Base sample (non-missing PV/DV/date): ", sum(base))
if (sum(base) != 2055) {
  found <- FALSE
  pat <- "(clinic|cscom|survey|sample|consent|ill|acute|interview|patient|in_)"
  for (j in which(grepl(pat, lnm))) {
    x <- suppressWarnings(to01(d[[j]]))
    v <- unique(x[!is.na(x)])
    if (length(v) == 2 && all(v %in% c(0, 1))) {
      if (sum(x == 1 & base, na.rm = TRUE) == 2055) {
        base <- base & !is.na(x) & x == 1
        message("Sample restricted using indicator: ", nm[j])
        found <- TRUE
        break
      }
    }
  }
  if (!found) message("No exact 2055 indicator found; using base sample of ", sum(base))
}

# Clinic cluster variable
pick_clinic <- function() {
  cand <- which(grepl("(cscom|clinic|cluster|centre|center)", lnm))
  best <- NULL; bestd <- Inf
  for (j in cand) {
    x <- d[[j]][base]
    u <- length(unique(x[!is.na(x)]))
    if (u >= 50 && u <= 70 && mean(is.na(x)) < 0.05) {
      dd <- abs(u - 60)
      if (dd < bestd) { bestd <- dd; best <- nm[j] }
    }
  }
  if (is.null(best)) {
    for (j in seq_along(nm)) {
      x <- d[[j]][base]
      if (!(is.numeric(x) || is.character(x))) next
      u <- length(unique(x[!is.na(x)]))
      if (u == 60 && mean(is.na(x)) < 0.01 && min(table(x)) >= 5) { best <- nm[j]; break }
    }
  }
  best
}
cln <- pick_clinic()
message("Cluster var: ", ifelse(is.null(cln), "NONE", cln))
clv <- if (!is.null(cln)) as.character(d[[cln]]) else datef

# Voucher used outcome
vun <- getv(c("voucher_used", "used_voucher", "vouchers_used", "usedvoucher", "voucherused"))
if (!is.null(vun)) {
  vused <- to01(d[[vun]])
  vused[is.na(vused) & base] <- 0
} else {
  a <- if ("voucher_used_PV" %in% nm) to01(d[["voucher_used_PV"]]) else rep(NA_real_, nrow(d))
  b <- if ("voucher_used_DV" %in% nm) to01(d[["voucher_used_DV"]]) else rep(NA_real_, nrow(d))
  a[is.na(a)] <- 0; b[is.na(b)] <- 0
  vused <- pmax(a, b)
}
message("Voucher used var: ", ifelse(is.null(vun), "constructed from voucher_used_PV/DV", vun))

# Binary candidate outcome search
nbase <- sum(base)
is_bin <- logical(length(nm)); nonmiss <- integer(length(nm))
for (j in seq_along(nm)) {
  x <- d[[j]]
  if (!(is.numeric(x) || is.logical(x))) next
  xs <- as.numeric(x[base])
  v <- unique(xs[!is.na(xs)])
  if (length(v) == 2 && all(v %in% c(0, 1))) {
    is_bin[j] <- TRUE
    nonmiss[j] <- sum(!is.na(xs))
  }
}

find_outcome <- function(explicit, must, exclude, prefer) {
  e <- getv(explicit)
  if (!is.null(e)) {
    j <- match(e, nm)
    if (is_bin[j]) return(e)
  }
  ok <- is_bin & nonmiss >= 1000
  for (m in must) ok <- ok & grepl(m, lnm)
  ok <- ok & !grepl(exclude, lnm)
  idx <- which(ok)
  if (length(idx) == 0) return(NULL)
  score <- abs(nonmiss[idx] - 2053) + ifelse(grepl(prefer, lnm[idx]), 0, 50) + nchar(nm[idx]) * 0.1
  message("  candidates: ", paste(nm[idx], collapse = ", "))
  nm[idx[which.min(score)]]
}

excl_any <- "(sev|simple|home|_h$|pred|_dv$|_pv$|antibio|rdt|test|quin|inj|act_|_act|iv|mono|cost|price|spent|exp)"
excl_sev <- "(home|_h$|pred|_dv$|_pv$|rdt|test|cost|price|spent|exp|simple)"

message("Any prescribed:")
anyp_n <- find_outcome(c("any_mal_prescribed", "prescribed_any_mal", "rx_any_mal", "any_antimal_prescribed", "prescribed_antimalarial", "rx_antimalarial"),
                       c("(presc|^rx|_rx|rx_)", "(mal|anti|treat)"), excl_any, "any")
message("  -> ", ifelse(is.null(anyp_n), "NONE", anyp_n))
message("Any purchased:")
anyb_n <- find_outcome(c("any_mal_purchased", "purchased_any_mal", "bought_any_mal", "any_antimal_purchased", "purchased_antimalarial", "bought_antimalarial"),
                       c("(purch|bought|buy|obtain|took|paid)", "(mal|anti|treat)"), excl_any, "any")
message("  -> ", ifelse(is.null(anyb_n), "NONE", anyb_n))
message("Severe prescribed:")
sevp_n <- find_outcome(c("sev_mal_prescribed", "prescribed_sev_mal", "rx_sev_mal", "severe_mal_prescribed", "prescribed_severe"),
                       c("(presc|^rx|_rx|rx_)", "sev"), excl_sev, "mal")
message("  -> ", ifelse(is.null(sevp_n), "NONE", sevp_n))
message("Severe purchased:")
sevb_n <- find_outcome(c("sev_mal_purchased", "purchased_sev_mal", "bought_sev_mal", "severe_mal_purchased", "purchased_severe"),
                       c("(purch|bought|buy|obtain|took|paid)", "sev"), excl_sev, "mal")
message("  -> ", ifelse(is.null(sevb_n), "NONE", sevb_n))

# Estimation: y = b0 + bP PV + bD DV + date FE, clustered by clinic
run <- function(y) {
  df <- data.frame(y = y[base], pv = pv[base], dv = dv[base],
                   date = factor(datef[base]), cl = clv[base], stringsAsFactors = FALSE)
  df <- df[!is.na(df$y), ]
  m <- feols(y ~ pv + dv | date, data = df, cluster = ~cl)
  list(bp = unname(coef(m)["pv"]), bd = unname(coef(m)["dv"]),
       sep = unname(sqrt(diag(vcov(m)))["pv"]), sed = unname(sqrt(diag(vcov(m)))["dv"]),
       n = nobs(m))
}

res <- list()
safe_run <- function(y) tryCatch(run(y), error = function(e) { message("ERR: ", conditionMessage(e)); NULL })

r1 <- safe_run(vused)
if (!is.null(r1)) {
  res$voucher_used_patient_voucher_table3_col1 <- r1$bp
  res$voucher_used_doctor_voucher_table3_col1 <- r1$bd
  res$n_obs_table3_col1 <- r1$n
}
if (!is.null(anyp_n)) {
  r2 <- safe_run(to01(d[[anyp_n]]))
  if (!is.null(r2)) {
    res$any_malaria_treatment_prescribed_patient_voucher_table3_col2 <- r2$bp
    res$any_malaria_treatment_prescribed_doctor_voucher_table3_col2 <- r2$bd
    res$n_obs_table3_cols2_5 <- r2$n
  }
}
if (!is.null(anyb_n)) {
  r3 <- safe_run(to01(d[[anyb_n]]))
  if (!is.null(r3)) {
    res$any_malaria_treatment_purchased_patient_voucher_table3_col3 <- r3$bp
    res$any_malaria_treatment_purchased_doctor_voucher_table3_col3 <- r3$bd
    if (is.null(res$n_obs_table3_cols2_5)) res$n_obs_table3_cols2_5 <- r3$n
  }
}
if (!is.null(sevp_n)) {
  r4 <- safe_run(to01(d[[sevp_n]]))
  if (!is.null(r4)) {
    res$severe_malaria_treatment_prescribed_patient_voucher_table3_col4 <- r4$bp
    res$severe_malaria_treatment_prescribed_doctor_voucher_table3_col4 <- r4$bd
  }
}
if (!is.null(sevb_n)) {
  r5 <- safe_run(to01(d[[sevb_n]]))
  if (!is.null(r5)) {
    res$severe_malaria_treatment_purchased_patient_voucher_table3_col5 <- r5$bp
    res$severe_malaria_treatment_purchased_doctor_voucher_table3_col5 <- r5$bd
  }
}

for (k in names(res)) {
  cat(sprintf("RESULT:%s=%s\n", k, format(res[[k]], digits = 6)))
}