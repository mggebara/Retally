suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_2022_patient_demand_prescription_overuse.script-free"
df <- haven::read_dta(file.path(base, "Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta"))
df <- as.data.frame(df)
nm <- names(df)

num <- function(x) suppressWarnings(as.numeric(haven::zap_labels(x)))

is_binary <- function(x) {
  u <- unique(x[!is.na(x)])
  length(u) >= 2 && all(u %in% c(0, 1))
}

# ---- treatment indicators ----
find_exact <- function(cands) {
  for (c in cands) {
    hit <- nm[tolower(nm) == tolower(c)]
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}
pv_var <- find_exact(c("patient_voucher", "PV", "pv", "tmt_PV", "PV_day"))
dv_var <- find_exact(c("doctor_voucher", "DV", "dv", "tmt_DV", "DV_day"))
message("PV var: ", pv_var, " | DV var: ", dv_var)
df$PVt <- num(df[[pv_var]])
df$DVt <- num(df[[dv_var]])

# ---- date ----
date_var <- find_exact(c("date", "visit_date", "date_cscom", "survey_date"))
message("Date var: ", date_var)
df$date_fe <- as.character(df[[date_var]])

# ---- clinic id ----
clinic_var <- find_exact(c("cscom", "cscomnum", "cscom_num", "cscom_id", "cscomid", "clinic", "clinic_id", "clinicid", "cscomnum_OS", "CSCom"))
if (is.na(clinic_var)) {
  cands <- grep("cscom|clinic", nm, ignore.case = TRUE, value = TRUE)
  best <- NA_character_; bestd <- Inf
  for (v in cands) {
    k <- length(unique(df[[v]][!is.na(df[[v]])]))
    if (k >= 40 && k <= 100 && abs(k - 60) < bestd) { best <- v; bestd <- abs(k - 60) }
  }
  clinic_var <- best
}
message("Clinic var: ", clinic_var)
df$clinic_id <- as.character(haven::zap_labels(df[[clinic_var]]))

# ---- sample: in-clinic surveyed acutely ill patients ----
samp <- df
if ("patient" %in% nm) {
  p <- num(samp$patient)
  if (is_binary(p) && sum(p == 1, na.rm = TRUE) > 1000) samp <- samp[!is.na(p) & p == 1, ]
}
acute_v <- grep("^acute|acutely|acute_ill", nm, ignore.case = TRUE, value = TRUE)
for (v in acute_v) {
  a <- num(samp[[v]])
  if (is_binary(a) && sum(a == 1, na.rm = TRUE) > 1500) { samp <- samp[!is.na(a) & a == 1, ]; message("Acute filter: ", v); break }
}
samp <- samp[!is.na(samp$PVt) & !is.na(samp$DVt) & !is.na(samp$date_fe) & samp$date_fe != "" &
               !is.na(samp$clinic_id) & samp$clinic_id != "", ]
message("Sample rows: ", nrow(samp))

generic_excl <- "home|_h$|pred|Xpred|_X_|bin|risk|rdt|test|ctrl|control|mean|share|pct|know|belief|_hh|followup|fu_|expect|_DV$|_PV$|doc_|wtp"

pick_bin <- function(d, patterns, exclude = NULL) {
  for (p in patterns) {
    cand <- grep(p, names(d), ignore.case = TRUE, value = TRUE)
    cand <- cand[!grepl(generic_excl, cand, ignore.case = TRUE)]
    if (!is.null(exclude)) cand <- cand[!grepl(exclude, cand, ignore.case = TRUE)]
    best <- NA_character_; bestn <- -1
    for (v in cand) {
      x <- num(d[[v]])
      if (is_binary(x)) {
        n <- sum(!is.na(x))
        if (n > bestn || (n == bestn && nchar(v) < nchar(best))) { best <- v; bestn <- n }
      }
    }
    if (!is.na(best) && bestn > 500) return(best)
  }
  NA_character_
}

# ---- outcome: voucher used ----
v_used <- pick_bin(samp, c("^used_?voucher$", "^voucher_?used$", "^used_?vouch", "voucher_?used", "used_?voucher", "vouch.*used|used.*vouch", "vouch.*redeem|redeem.*vouch"),
                   exclude = "received|time|number|comment")
if (!is.na(v_used)) {
  samp$y_voucher <- num(samp[[v_used]])
} else {
  u1 <- if ("voucher_used_DV" %in% nm) num(samp$voucher_used_DV) else rep(NA_real_, nrow(samp))
  u2 <- if ("voucher_used_PV" %in% nm) num(samp$voucher_used_PV) else rep(NA_real_, nrow(samp))
  samp$y_voucher <- as.numeric((!is.na(u1) & u1 == 1) | (!is.na(u2) & u2 == 1))
  v_used <- "constructed(voucher_used_DV|voucher_used_PV)"
}
if (all(is.na(samp$y_voucher))) samp$y_voucher <- 0
samp$y_voucher[is.na(samp$y_voucher)] <- 0
message("Voucher used var: ", v_used)

# ---- outcomes: malaria treatment ----
any_rx <- pick_bin(samp, c("^rx_?any_?mal", "^any_?mal.*(rx|presc)", "(rx|presc).*any.*mal", "any.*mal.*(rx|presc)",
                           "^RXtreat_?mal", "(rx|presc).*antimal", "antimal.*(rx|presc)", "(rx|presc).*mal", "mal.*(rx|presc)"),
                   exclude = "sev|simp|ACT|quin|arte|purch|bought|buy|obtain")
any_pu <- pick_bin(samp, c("^purch_?any_?mal", "^any_?mal.*(purch|bought|buy|obtain)", "(purch|bought|buy|obtain).*any.*mal",
                           "any.*mal.*(purch|bought|buy|obtain)", "(purch|bought|buy|obtain).*antimal", "antimal.*(purch|bought|buy|obtain)",
                           "(purch|bought|buy|obtain).*mal", "mal.*(purch|bought|buy|obtain)"),
                   exclude = "sev|simp|ACT|quin|arte|rx|presc")
sev_rx <- pick_bin(samp, c("^rx_?sev", "(rx|presc).*sev", "sev.*(rx|presc)"),
                   exclude = "purch|bought|buy|obtain|simp")
sev_pu <- pick_bin(samp, c("^purch_?sev", "(purch|bought|buy|obtain).*sev", "sev.*(purch|bought|buy|obtain)"),
                   exclude = "rx|presc|simp")
message("Any rx: ", any_rx, " | Any purch: ", any_pu, " | Sev rx: ", sev_rx, " | Sev purch: ", sev_pu)

run_reg <- function(yvar, d) {
  if (is.na(yvar)) return(NULL)
  d$yy <- num(d[[yvar]])
  d <- d[!is.na(d$yy), ]
  tryCatch(feols(yy ~ PVt + DVt | date_fe, data = d, cluster = ~clinic_id), error = function(e) { message(e$message); NULL })
}

samp$y_voucher_num <- samp$y_voucher
m1 <- run_reg("y_voucher_num", samp)
m2 <- run_reg(any_rx, samp)
m3 <- run_reg(any_pu, samp)
m4 <- run_reg(sev_rx, samp)
m5 <- run_reg(sev_pu, samp)

getc <- function(m, v) if (is.null(m)) NA else unname(coef(m)[v])
getn <- function(m) if (is.null(m)) NA else nobs(m)

for (m in list(m1, m2, m3, m4, m5)) if (!is.null(m)) print(summary(m))

n25 <- getn(m2)
if (is.na(n25)) n25 <- getn(m3)

cat(sprintf("RESULT:voucher_used_patient_voucher_table3_col1=%s\n", getc(m1, "PVt")))
cat(sprintf("RESULT:voucher_used_doctor_voucher_table3_col1=%s\n", getc(m1, "DVt")))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_patient_voucher_table3_col2=%s\n", getc(m2, "PVt")))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_doctor_voucher_table3_col2=%s\n", getc(m2, "DVt")))
cat(sprintf("RESULT:any_malaria_treatment_purchased_patient_voucher_table3_col3=%s\n", getc(m3, "PVt")))
cat(sprintf("RESULT:any_malaria_treatment_purchased_doctor_voucher_table3_col3=%s\n", getc(m3, "DVt")))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_patient_voucher_table3_col4=%s\n", getc(m4, "PVt")))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_doctor_voucher_table3_col4=%s\n", getc(m4, "DVt")))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_patient_voucher_table3_col5=%s\n", getc(m5, "PVt")))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_doctor_voucher_table3_col5=%s\n", getc(m5, "DVt")))
cat(sprintf("RESULT:n_obs_table3_col1=%s\n", getn(m1)))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%s\n", n25))
