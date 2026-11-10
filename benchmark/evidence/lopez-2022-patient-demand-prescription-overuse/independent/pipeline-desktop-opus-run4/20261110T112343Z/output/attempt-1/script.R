suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_2022_patient_demand_prescription_overuse.script-free"
path <- file.path(base, "Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta")
d <- haven::read_dta(path)
d <- haven::zap_labels(d)
d <- as.data.frame(d)
nm <- names(d)
lnm <- tolower(nm)
cat("# rows:", nrow(d), " cols:", ncol(d), "\n")

show <- function(rx) {
  m <- nm[grepl(rx, lnm)]
  cat("# vars matching", rx, ":", paste(head(m, 80), collapse = ", "), "\n")
}
show("presc|^rx|_rx")
show("purch|bought|buy")
show("sev")
show("voucher")
show("cscom|clinic")
show("info|video|^pi$|^pi_|_pi$")
show("treat_severe_mal|treat_sev_simple_mal")

num <- function(x) {
  if (is.character(x)) {
    y <- tolower(trimws(x))
    out <- suppressWarnings(as.numeric(y))
    out[y %in% c("yes", "oui", "true")] <- 1
    out[y %in% c("no", "non", "false")] <- 0
    return(out)
  }
  suppressWarnings(as.numeric(x))
}

getv <- function(v) if (!is.na(v) && v %in% nm) num(d[[v]]) else rep(NA_real_, nrow(d))
first_exact <- function(cands) {
  for (e in cands) {
    i <- which(lnm == tolower(e))
    if (length(i)) return(nm[i[1]])
  }
  NA_character_
}

# ---- Treatment indicators ----
pv_name <- first_exact(c("patient_voucher", "pv", "tmt_pv", "patientvoucher"))
dv_name <- first_exact(c("doctor_voucher", "dv", "tmt_dv", "doctorvoucher"))
cat("# PV var:", pv_name, " DV var:", dv_name, "\n")
pv <- getv(pv_name)
dv <- getv(dv_name)

# ---- Date ----
date_name <- first_exact(c("date", "visit_date", "date_clinic", "survey_date"))
cat("# date var:", date_name, "\n")
date_v <- if (!is.na(date_name)) as.character(d[[date_name]]) else rep(NA_character_, nrow(d))
date_v[date_v == "" ] <- NA

# ---- Clinic id ----
base_ok <- !is.na(pv) & !is.na(dv) & !is.na(date_v)
clin_cands <- unique(c(
  nm[lnm %in% c("cscom", "cscomnum", "cscom_id", "clinic", "clinic_id", "cscomnum_os", "cscom_num")],
  nm[grepl("cscom|clinic", lnm)]
))
clinic_name <- NA_character_
for (v in clin_cands) {
  x <- d[[v]][base_ok]
  k <- length(unique(x[!is.na(x) & as.character(x) != ""]))
  if (k >= 50 && k <= 70 && mean(!is.na(x)) > 0.95) { clinic_name <- v; break }
}
if (is.na(clinic_name)) {
  for (v in clin_cands) {
    x <- d[[v]][base_ok]
    k <- length(unique(x[!is.na(x)]))
    if (k >= 20 && k <= 200) { clinic_name <- v; break }
  }
}
cat("# clinic var:", clinic_name, "\n")
clinic_v <- if (!is.na(clinic_name)) as.character(d[[clinic_name]]) else rep(NA_character_, nrow(d))
clinic_v[clinic_v == ""] <- NA

# ---- In-clinic survey sample ----
samp <- base_ok & !is.na(clinic_v)
cat("# base sample size:", sum(samp), "\n")
for (sv in c("patient", "clinic_survey", "in_clinic", "acutely_ill", "acute", "main_sample", "sample")) {
  v <- first_exact(sv)
  if (!is.na(v)) {
    x <- num(d[[v]])
    u <- unique(x[!is.na(x)])
    if (length(u) > 0 && all(u %in% c(0, 1))) {
      s2 <- samp & !is.na(x) & x == 1
      cat("# sample flag", v, "->", sum(s2), "\n")
      if (sum(samp) > 2060 && sum(s2) >= 1950 && sum(s2) <= 2200) { samp <- s2; break }
    }
  }
}

# ---- Exclude non-voucher-experiment days (e.g. Patient Information days) ----
# The voucher analysis sample is 2,055 patients on Control/PV/DV days. Extra
# rows in the file are patients seen on days outside the 6 voucher-experiment
# days (all have PV = DV = 0). Find the indicator that separates them.
target_n <- 2055
nsamp0 <- sum(samp)
excl_target <- nsamp0 - target_n
if (excl_target > 30) {
  pv_s <- pv[samp]; dv_s <- dv[samp]
  pat <- "info|video|^pi$|^pi_|_pi$|^pi[0-9]|tmt|treat|arm|sample|day|exper|sched"
  best <- NULL
  masks <- list()
  for (v in nm) {
    x <- d[[v]]
    if (is.list(x)) next
    x <- x[samp]
    xc <- as.character(x)
    xc[!is.na(xc) & trimws(xc) == ""] <- NA
    opts <- list()
    nna <- sum(is.na(xc))
    if (abs(nna - excl_target) <= 25) opts[["<NA>"]] <- is.na(xc)
    u <- unique(xc[!is.na(xc)])
    if (length(u) >= 1 && length(u) <= 10) {
      for (val in u) {
        e <- !is.na(xc) & xc == val
        if (abs(sum(e) - excl_target) <= 25) opts[[paste0("=", val)]] <- e
      }
    }
    for (k in names(opts)) {
      e <- opts[[k]]
      if (sum(e) > 0 && all(pv_s[e] == 0 & dv_s[e] == 0)) {
        key <- paste0(v, "|", k)
        masks[[key]] <- e
        best <- rbind(best, data.frame(key = key, v = v, val = k,
                                       gap = abs(sum(e) - excl_target),
                                       pm = grepl(pat, tolower(v)),
                                       len = nchar(v), stringsAsFactors = FALSE))
      }
    }
  }
  if (!is.null(best) && nrow(best)) {
    best <- best[order(-best$pm, best$gap, best$len), , drop = FALSE]
    cat("# exclusion candidates:\n")
    print(head(best, 15))
    e <- masks[[best$key[1]]]
    idx <- which(samp)
    samp[idx[e]] <- FALSE
    cat("# excluding rows with", best$v[1], best$val[1], "(", sum(e), "rows ) -> sample", sum(samp), "\n")
  } else {
    cat("# no exclusion indicator found\n")
  }
}
nsamp <- sum(samp)
cat("# analysis sample size:", nsamp, "\n")

# ---- Outcome picker ----
pick <- function(label, exact = character(0), all_rx = character(0), excl = NULL, prefer = NULL) {
  cand <- character(0)
  for (e in exact) { i <- which(lnm == tolower(e)); if (length(i)) cand <- c(cand, nm[i[1]]) }
  if (length(all_rx)) {
    ok <- rep(TRUE, length(nm))
    for (r in all_rx) ok <- ok & grepl(r, lnm)
    if (!is.null(excl)) ok <- ok & !grepl(excl, lnm)
    cand <- unique(c(cand, nm[ok]))
  }
  cat("# candidates for", label, ":", paste(head(cand, 40), collapse = ", "), "\n")
  if (!length(cand)) return(NA_character_)
  info <- do.call(rbind, lapply(cand, function(v) {
    x <- num(d[[v]][samp])
    nn <- sum(!is.na(x))
    u <- unique(x[!is.na(x)])
    data.frame(v = v, nn = nn,
               bin = (nn > 0 && all(u %in% c(0, 1)) && length(u) == 2),
               ex = tolower(v) %in% tolower(exact),
               pref = if (is.null(prefer)) 0 else as.numeric(grepl(prefer, tolower(v))),
               len = nchar(v), stringsAsFactors = FALSE)
  }))
  info <- info[info$bin & info$nn >= 0.6 * nsamp, , drop = FALSE]
  if (!nrow(info)) return(NA_character_)
  info <- info[order(-info$ex, -info$pref, -info$nn, info$len), , drop = FALSE]
  cat("# chosen for", label, ":", info$v[1], "(n =", info$nn[1], ")\n")
  info$v[1]
}

# Purchase analog of an RX (prescription) variable: same core name, no RX prefix
find_nonrx <- function(label, core) {
  ok <- grepl(core, lnm, fixed = TRUE) & !grepl("^rx", lnm) &
    !grepl("voucher|_alt|correct|pred|overtreat", lnm)
  cand <- nm[ok]
  cand2 <- cand[!grepl("_h$", tolower(cand))]
  if (length(cand2)) cand <- cand2
  cat("# non-RX candidates for", label, ":", paste(cand, collapse = ", "), "\n")
  if (!length(cand)) return(NA_character_)
  keep <- sapply(cand, function(v) {
    x <- num(d[[v]][samp]); u <- unique(x[!is.na(x)])
    length(u) == 2 && all(u %in% c(0, 1)) && sum(!is.na(x)) >= 0.5 * nsamp
  })
  cand <- cand[keep]
  if (!length(cand)) return(NA_character_)
  cand <- cand[order(nchar(cand))]
  cat("# chosen for", label, ":", cand[1], "\n")
  cand[1]
}

excl_common <- "home|_hs|pred|_pv$|_dv$|cost|price|spend|exp_|_exp|amount|num|share|mean|ctrl|control"

any_presc_name <- pick("any prescribed",
  exact = c("rx_any", "rxany", "presc_any", "prescribed_any", "any_presc", "any_prescribed",
            "rx_any_mal", "rx_anymal", "presc_any_mal", "presc_anymal", "rx_malaria", "presc_malaria",
            "prescribed_malaria", "any_mal_rx", "anymal_rx", "rx_antimalarial", "presc_antimalarial",
            "RXtreat_any", "RX_any_malaria", "prescribed_antimalarial"),
  all_rx = c("presc|^rx|_rx"), excl = paste0("sev|simple|act|ab|antibio|", excl_common),
  prefer = "any|mal")

any_purch_name <- find_nonrx("any purchased", "treat_sev_simple_mal")
if (is.na(any_purch_name)) any_purch_name <- find_nonrx("any purchased", "treat_any_mal")
if (is.na(any_purch_name)) {
  any_purch_name <- pick("any purchased",
    exact = c("purch_any", "purchased_any", "any_purch", "any_purchased", "bought_any", "purch_any_mal",
              "purch_anymal", "purch_malaria", "purchased_malaria", "any_mal_purch", "anymal_purch",
              "purch_antimalarial", "bought_antimalarial", "purchased_antimalarial"),
    all_rx = c("purch|bought|buy"), excl = paste0("sev|simple|act|ab|antibio|", excl_common),
    prefer = "any|mal")
}
sev_presc_name <- pick("severe prescribed",
  exact = c("rx_sev", "rxsev", "presc_sev", "prescribed_sev", "rx_severe", "presc_severe",
            "prescribed_severe", "sev_presc", "severe_presc", "sev_rx", "severe_rx"),
  all_rx = c("presc|^rx|_rx", "sev"), excl = excl_common, prefer = "mal")
sev_purch_name <- find_nonrx("severe purchased", "treat_severe_mal")
if (is.na(sev_purch_name)) {
  sev_purch_name <- pick("severe purchased",
    exact = c("purch_sev", "purchased_sev", "purch_severe", "purchased_severe", "bought_sev",
              "bought_severe", "sev_purch", "severe_purch"),
    all_rx = c("purch|bought|buy", "sev"), excl = excl_common, prefer = "mal")
}

# Fallback: any = simple OR severe
if (is.na(any_presc_name) && !is.na(sev_presc_name)) {
  simp <- pick("simple prescribed", all_rx = c("presc|^rx|_rx", "simple|act"), excl = paste0("sev|", excl_common))
  if (!is.na(simp)) {
    d$any_presc_constructed <- pmax(num(d[[simp]]), num(d[[sev_presc_name]]))
    nm <- names(d); lnm <- tolower(nm); any_presc_name <- "any_presc_constructed"
  }
}
if (is.na(any_purch_name) && !is.na(sev_purch_name)) {
  simp <- pick("simple purchased", all_rx = c("purch|bought|buy", "simple|act"), excl = paste0("sev|", excl_common))
  if (!is.na(simp)) {
    d$any_purch_constructed <- pmax(num(d[[simp]]), num(d[[sev_purch_name]]))
    nm <- names(d); lnm <- tolower(nm); any_purch_name <- "any_purch_constructed"
  }
}

# ---- Voucher used (administrative) ----
vu_name <- first_exact(c("used_voucher", "voucher_used", "usedvoucher", "voucherused", "voucher_use"))
if (!is.na(vu_name)) {
  vu <- num(d[[vu_name]])
  vu[is.na(vu) & samp] <- 0
  cat("# voucher used var:", vu_name, "\n")
} else {
  vpv <- getv(first_exact("voucher_used_PV"))
  vdv <- getv(first_exact("voucher_used_DV"))
  vpv[is.na(vpv)] <- 0
  vdv[is.na(vdv)] <- 0
  vpv <- as.numeric(vpv == 1)
  vdv <- as.numeric(vdv == 1)
  vu <- ifelse(pv == 1, vpv, ifelse(dv == 1, vdv, 0))
  cat("# voucher used constructed from voucher_used_PV / voucher_used_DV\n")
}

# Treatment outcomes are missing for patients with no prescription / no
# purchase (survey skip pattern); the paper's N (2,053) implies these are 0.
fill0 <- function(y, label) {
  if (is.null(y)) return(NULL)
  sh <- mean(is.na(y[samp]))
  if (sh > 0.03) {
    cat("DEVIATION: Set missing", label, "to 0 for in-sample patients (", round(100 * sh, 1),
        "% missing, treated as skip-pattern zeros to match paper N)\n")
    y[samp & is.na(y)] <- 0
  }
  y
}

# ---- Estimation: y = bP*PV + bD*DV + date FE, clinic-clustered SE ----
est <- function(y) {
  df <- data.frame(y = y[samp], pv = pv[samp], dv = dv[samp],
                   date_fe = factor(date_v[samp]), clinic = clinic_v[samp])
  df <- df[!is.na(df$y), , drop = FALSE]
  m <- tryCatch(feols(y ~ pv + dv | date_fe, data = df, cluster = ~clinic),
                error = function(e) { cat("# estimation error:", conditionMessage(e), "\n"); NULL })
  m
}

res <- list()
emit <- function(m, stub) {
  if (is.null(m)) return(invisible(NULL))
  b <- coef(m); s <- sqrt(diag(vcov(m)))
  res[[paste0(stub$p)]] <<- b["pv"]
  res[[paste0(stub$d)]] <<- b["dv"]
  cat("# ", stub$p, " b=", b["pv"], " se=", s["pv"], "; ", stub$d, " b=", b["dv"], " se=", s["dv"],
      " N=", nobs(m), "\n", sep = "")
}

m1 <- est(vu)
emit(m1, list(p = "voucher_used_patient_voucher_table3_col1", d = "voucher_used_doctor_voucher_table3_col1"))

m2 <- if (!is.na(any_presc_name)) est(fill0(num(d[[any_presc_name]]), "any prescribed")) else NULL
emit(m2, list(p = "any_malaria_treatment_prescribed_patient_voucher_table3_col2",
              d = "any_malaria_treatment_prescribed_doctor_voucher_table3_col2"))
m3 <- if (!is.na(any_purch_name)) est(fill0(num(d[[any_purch_name]]), "any purchased")) else NULL
emit(m3, list(p = "any_malaria_treatment_purchased_patient_voucher_table3_col3",
              d = "any_malaria_treatment_purchased_doctor_voucher_table3_col3"))
m4 <- if (!is.na(sev_presc_name)) est(fill0(num(d[[sev_presc_name]]), "severe prescribed")) else NULL
emit(m4, list(p = "severe_malaria_treatment_prescribed_patient_voucher_table3_col4",
              d = "severe_malaria_treatment_prescribed_doctor_voucher_table3_col4"))
m5 <- if (!is.na(sev_purch_name)) est(fill0(num(d[[sev_purch_name]]), "severe purchased")) else NULL
emit(m5, list(p = "severe_malaria_treatment_purchased_patient_voucher_table3_col5",
              d = "severe_malaria_treatment_purchased_doctor_voucher_table3_col5"))

if (!is.null(m1)) res[["n_obs_table3_col1"]] <- nobs(m1)
n25 <- NULL
for (m in list(m4, m5, m3, m2)) if (!is.null(m)) { n25 <- nobs(m); break }
if (!is.null(n25)) res[["n_obs_table3_cols2_5"]] <- n25

for (k in names(res)) {
  v <- as.numeric(res[[k]])
  if (length(v) == 1 && is.finite(v)) cat(sprintf("RESULT:%s=%.6f\n", k, v))
}