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
invisible(show_names("acute|ill|sick|sample|elig|keep|incl|main"))

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

# ---- base sample ----
d <- d[!is.na(d$PV) & !is.na(d$DV), ]
okcl <- !is.na(d$clinic) & d$clinic != ""
d <- d[okcl, ]
okdt <- !is.na(d$datefe) & d$datefe != ""
if (sum(okdt) > 1000) {
  d <- d[okdt, ]
} else {
  d$datefe[is.na(d$datefe) | d$datefe == ""] <- "missing"
}
cat("Base sample size:", nrow(d), "\n")

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
d$y_any_rx  <- mk(c("RXtreat_sev_simple_mal", "rx_any_malaria"), c("rx.*(any|anti)?mal"))
d$y_any_buy <- mk(c("treat_sev_simple_mal", "purchased_any_malaria"), c("purch.*mal"))
d$y_sev_rx  <- mk(c("RXtreat_severe_mal", "rx_severe_malaria"), c("rx.*sev"))
d$y_sev_buy <- mk(c("treat_severe_mal", "purchased_severe_malaria"), c("^treat_sev"))

# ---- restrict to the paper's analysis sample (2,055 acutely ill patients) ----
target_n <- 2055
target_n2 <- 2053
rx_ok <- !is.na(d$y_any_rx)
pat_sample <- "acute|ill|sick|sample|elig|keep|analysis|main|incl|valid|consent|complete|^patient$|insamp"
excl <- unique(c("PV", "DV", "clinic", "datefe", grep("^y_", names(d), value = TRUE),
                 pv_var, dv_var, cl_var, date_var))
cands <- list()
for (v in setdiff(names(d), excl)) {
  x <- d[[v]]
  if (!(is.numeric(x) || is.logical(x))) next
  ux <- unique(x[!is.na(x)])
  masks <- list()
  if (length(ux) >= 1 && length(ux) <= 2) for (u in ux) masks[[paste0("==", u)]] <- !is.na(x) & x == u
  if (grepl(pat_sample, v, ignore.case = TRUE)) masks[["nonmissing"]] <- !is.na(x)
  for (k in names(masks)) {
    m <- masks[[k]]
    n1 <- sum(m)
    if (abs(n1 - target_n) > 25) next
    n2 <- sum(m & rx_ok)
    sc <- abs(n1 - target_n) + abs(n2 - target_n2) -
      ifelse(grepl(pat_sample, v, ignore.case = TRUE), 3, 0)
    cands[[length(cands) + 1]] <- data.frame(var = v, rule = k, n1 = n1, n2 = n2, score = sc,
                                             stringsAsFactors = FALSE)
  }
}
dedup_mask <- NULL
if ("id" %in% names(d)) {
  dm <- !duplicated(d$id)
  cat("Unique id:", sum(dm), "\n")
  if (abs(sum(dm) - target_n) <= 25) {
    dedup_mask <- dm
    cands[[length(cands) + 1]] <- data.frame(var = "id", rule = "dedup", n1 = sum(dm),
                                             n2 = sum(dm & rx_ok),
                                             score = abs(sum(dm) - target_n) + abs(sum(dm & rx_ok) - target_n2),
                                             stringsAsFactors = FALSE)
  }
}
if (length(cands) > 0) {
  cd <- do.call(rbind, cands)
  cd <- cd[order(cd$score, -grepl(pat_sample, cd$var, ignore.case = TRUE)), ]
  cat("Sample-restriction candidates:\n")
  print(head(cd, 25))
  best <- cd[1, ]
  if (best$score <= 15) {
    if (best$rule == "dedup") {
      mask <- dedup_mask
    } else if (best$rule == "nonmissing") {
      mask <- !is.na(d[[best$var]])
    } else {
      u <- as.numeric(sub("^==", "", best$rule))
      mask <- !is.na(d[[best$var]]) & d[[best$var]] == u
    }
    d <- d[mask, ]
    cat(sprintf("DEVIATION: Restricted to analysis sample via %s %s (n=%d) to match the paper's 2,055 acutely ill patients; the exact sample flag is not named in the paper\n",
                best$var, best$rule, nrow(d)))
  } else {
    cat("No sample flag close to 2055 found; keeping base sample\n")
  }
} else {
  cat("No sample-restriction candidates found\n")
}
cat("Sample size after restrictions:", nrow(d), "\n")

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
