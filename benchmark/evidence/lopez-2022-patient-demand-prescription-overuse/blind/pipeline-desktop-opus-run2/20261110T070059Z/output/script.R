suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/lopez_2022_patient_demand_prescription_overuse.script-free"
f <- file.path(base_dir, "Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta")
raw <- haven::read_dta(f)
cat("Loaded rows:", nrow(raw), "cols:", ncol(raw), "\n")

nms <- names(raw)
labs <- vapply(raw, function(x) {
  l <- attr(x, "label")
  if (is.null(l)) "" else as.character(l)[1]
}, character(1))
txt <- tolower(paste(nms, labs, sep = " || "))
names(txt) <- nms

to_num <- function(x) {
  x <- haven::zap_labels(x)
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(as.numeric(x))
  suppressWarnings(as.numeric(x))
}

is_binary <- function(x) {
  v <- to_num(x)
  v <- v[!is.na(v)]
  length(v) > 50 && all(v %in% c(0, 1)) && length(unique(v)) == 2
}

find_col <- function(must_all, must_not = NULL, exact = NULL, binary = TRUE, exclude_names = NULL) {
  if (!is.null(exact)) {
    for (e in exact) {
      hit <- nms[tolower(nms) == tolower(e)]
      if (length(hit) > 0 && (!binary || is_binary(raw[[hit[1]]]))) return(hit[1])
    }
  }
  ok <- rep(TRUE, length(nms))
  for (p in must_all) ok <- ok & grepl(p, txt, perl = TRUE)
  if (!is.null(must_not)) for (p in must_not) ok <- ok & !grepl(p, txt, perl = TRUE)
  if (!is.null(exclude_names)) for (p in exclude_names) ok <- ok & !grepl(p, tolower(nms), perl = TRUE)
  cand <- nms[ok]
  if (binary) cand <- cand[vapply(cand, function(cn) is_binary(raw[[cn]]), logical(1))]
  if (length(cand) == 0) return(NA_character_)
  nn <- vapply(cand, function(cn) sum(!is.na(to_num(raw[[cn]]))), numeric(1))
  cat("  candidates:", paste0(cand, "(", nn, ")", collapse = ", "), "\n")
  cand[which.max(nn)]
}

# ---- treatment indicators ----
pv_col <- if ("patient_voucher" %in% nms) "patient_voucher" else find_col(c("patient.?voucher"), c("used", "number", "time"))
dv_col <- if ("doctor_voucher" %in% nms) "doctor_voucher" else find_col(c("doctor.?voucher"), c("used", "number", "time"))
cat("PV col:", pv_col, " DV col:", dv_col, "\n")

# ---- clinic identifier ----
clinic_col <- NA_character_
for (e in c("cscom", "cscomnum", "cscom_id", "cscomid", "clinic", "clinic_id", "clinicid", "cscomnum_OS", "cscom_num")) {
  hit <- nms[tolower(nms) == tolower(e)]
  if (length(hit) > 0) { clinic_col <- hit[1]; break }
}
if (is.na(clinic_col)) {
  cand <- nms[grepl("cscom|clinic", tolower(nms))]
  cand <- cand[vapply(cand, function(cn) {
    u <- length(unique(na.omit(to_num(raw[[cn]]))))
    u >= 40 && u <= 100
  }, logical(1))]
  if (length(cand) > 0) clinic_col <- cand[1]
}
cat("Clinic col:", clinic_col, "\n")

# ---- date ----
date_col <- if ("date" %in% nms) "date" else nms[grepl("^date", tolower(nms))][1]
cat("Date col:", date_col, "\n")

df <- raw
df$PV <- to_num(df[[pv_col]])
df$DV <- to_num(df[[dv_col]])
df$clinic_id <- as.character(to_num(df[[clinic_col]]))
df$date_fe <- as.character(df[[date_col]])

# ---- sample: in-clinic acutely ill patients with assigned treatment ----
samp <- !is.na(df$PV) & !is.na(df$DV) & !is.na(df$clinic_id) & !is.na(df$date_fe) & df$date_fe != "NA"
cat("Rows with treatment/clinic/date:", sum(samp), "\n")
acute_col <- NA_character_
for (e in c("acute", "acutely_ill", "acute_ill", "acuteill", "sample_acute", "main_sample", "in_sample")) {
  hit <- nms[tolower(nms) == e]
  if (length(hit) > 0 && is_binary(raw[[hit[1]]])) { acute_col <- hit[1]; break }
}
if (!is.na(acute_col)) {
  a <- to_num(df[[acute_col]])
  if (sum(samp & a %in% 1) > 1000) samp <- samp & a %in% 1
  cat("Restricted by", acute_col, "->", sum(samp), "\n")
}
d <- df[samp, ]
cat("Analysis sample:", nrow(d), "  Control obs:", sum(d$PV == 0 & d$DV == 0), "\n")

# ---- outcomes ----
cat("Finding voucher used\n")
vu_col <- NA_character_
for (e in c("voucher_used", "used_voucher", "voucherused", "usedvoucher")) {
  hit <- nms[tolower(nms) == e]
  if (length(hit) > 0 && is_binary(raw[[hit[1]]])) { vu_col <- hit[1]; break }
}
if (!is.na(vu_col)) {
  d$y_voucher <- to_num(d[[vu_col]])
  d$y_voucher[is.na(d$y_voucher)] <- 0
} else {
  vpv <- if ("voucher_used_PV" %in% nms) to_num(d$voucher_used_PV) else rep(NA_real_, nrow(d))
  vdv <- if ("voucher_used_DV" %in% nms) to_num(d$voucher_used_DV) else rep(NA_real_, nrow(d))
  vpv[is.na(vpv)] <- 0; vdv[is.na(vdv)] <- 0
  d$y_voucher <- as.numeric((vpv == 1) | (vdv == 1))
}
cat("Voucher used col:", ifelse(is.na(vu_col), "constructed from voucher_used_PV/DV", vu_col), "\n")

excl <- c("home", "_hs$", "^hs_", "pred", "self", "_bl$", "^bl_", "doc_", "^mean", "_ctrl")
cat("Finding any malaria prescribed\n")
rx_any <- find_col(c("(malaria|antimal|anti-mal|_mal)", "(presc|rx)"), c("severe", "simple", "act\\b", "voucher", "test", "rdt"),
                   exact = c("RXmalaria", "rx_malaria", "rx_any_malaria", "prescribed_malaria", "presc_malaria", "rx_antimalarial", "any_antimalarial_rx"),
                   exclude_names = excl)
cat("Finding any malaria purchased\n")
pu_any <- find_col(c("(malaria|antimal|anti-mal|_mal)", "(purch|bought|buy|obtain)"), c("severe", "simple", "act\\b", "voucher", "test", "rdt"),
                   exact = c("purchmalaria", "purch_malaria", "purchased_malaria", "bought_malaria", "purch_any_malaria", "any_antimalarial_purch"),
                   exclude_names = excl)
cat("Finding severe prescribed\n")
rx_sev <- find_col(c("severe", "(presc|rx)"), c("simple", "voucher", "test", "rdt"),
                   exact = c("RXsevere", "rx_severe", "rx_severe_malaria", "prescribed_severe", "presc_severe"),
                   exclude_names = excl)
cat("Finding severe purchased\n")
pu_sev <- find_col(c("severe", "(purch|bought|buy|obtain)"), c("simple", "voucher", "test", "rdt"),
                   exact = c("purchsevere", "purch_severe", "purch_severe_malaria", "purchased_severe", "bought_severe"),
                   exclude_names = excl)
cat("Outcome cols:", rx_any, pu_any, rx_sev, pu_sev, "\n")

# NOTE: the paper's Table 3 adds post-double-selection lasso controls; no lasso package is
# installed, so the baseline specification (date fixed effects only) is estimated here.
run_reg <- function(yname) {
  dd <- d
  dd$y <- if (yname == "y_voucher") dd$y_voucher else to_num(dd[[yname]])
  dd <- dd[!is.na(dd$y), ]
  m <- feols(y ~ PV + DV | date_fe, data = dd, cluster = ~clinic_id)
  print(summary(m))
  list(bP = unname(coef(m)["PV"]), bD = unname(coef(m)["DV"]), n = nobs(m))
}
safe <- function(col) {
  if (is.na(col)) return(list(bP = NA, bD = NA, n = NA))
  tryCatch(run_reg(col), error = function(e) { cat("Error:", conditionMessage(e), "\n"); list(bP = NA, bD = NA, n = NA) })
}

r1 <- safe("y_voucher")
r2 <- safe(rx_any)
r3 <- safe(pu_any)
r4 <- safe(rx_sev)
r5 <- safe(pu_sev)

n25 <- r2$n
if (is.na(n25)) n25 <- r3$n
if (is.na(n25)) n25 <- r4$n

cat(sprintf("RESULT:voucher_used_patient_voucher_table3_col1=%.6f\n", r1$bP))
cat(sprintf("RESULT:voucher_used_doctor_voucher_table3_col1=%.6f\n", r1$bD))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_patient_voucher_table3_col2=%.6f\n", r2$bP))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_doctor_voucher_table3_col2=%.6f\n", r2$bD))
cat(sprintf("RESULT:any_malaria_treatment_purchased_patient_voucher_table3_col3=%.6f\n", r3$bP))
cat(sprintf("RESULT:any_malaria_treatment_purchased_doctor_voucher_table3_col3=%.6f\n", r3$bD))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_patient_voucher_table3_col4=%.6f\n", r4$bP))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_doctor_voucher_table3_col4=%.6f\n", r4$bD))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_patient_voucher_table3_col5=%.6f\n", r5$bP))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_doctor_voucher_table3_col5=%.6f\n", r5$bD))
cat(sprintf("RESULT:n_obs_table3_col1=%s\n", as.character(r1$n)))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%s\n", as.character(n25)))