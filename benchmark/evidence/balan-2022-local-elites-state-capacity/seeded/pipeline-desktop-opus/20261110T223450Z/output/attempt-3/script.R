suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)
options(width = 200)

root <- "<repo>/.cache/datasets/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
adm <- file.path(root, "admin_data")
srv <- file.path(root, "survey_data")

results <- list()
put <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) results[[name]] <<- val
}

rd <- function(f) as.data.frame(haven::read_dta(f))
show <- function(nm, d) {
  cat("### ", nm, ": ", nrow(d), " rows; cols: ", paste(names(d), collapse = ", "), "\n", sep = "")
}
num <- function(v) {
  v <- haven::zap_labels(v)
  if (is.numeric(v)) as.numeric(v) else suppressWarnings(as.numeric(as.character(v)))
}
firstcol <- function(d, cands) {
  h <- cands[cands %in% names(d)]
  if (length(h)) h[1] else NA_character_
}
pilot_a7 <- c(200, 201, 202, 203, 207, 208, 210)

# ---- treatment code mapping (target coding: 0 control, 1 central, 2 local, 3 CLI, 4 CXL)
map_tmt <- function(v) {
  lab <- NULL
  if (haven::is.labelled(v)) {
    lab <- as.character(haven::as_factor(v, levels = "labels"))
  } else if (is.character(v) || is.factor(v)) {
    lab <- as.character(v)
  }
  if (!is.null(lab)) {
    l <- tolower(lab)
    out <- rep(NA_real_, length(l))
    out[grepl("control|pure|declar", l)] <- 0
    out[is.na(out) & grepl("info|cli", l)] <- 3
    out[is.na(out) & grepl("cxl| x |cross|both|\\*", l)] <- 4
    out[is.na(out) & grepl("local|chief|chef", l)] <- 2
    out[is.na(out) & grepl("central|state|dgrkoc", l)] <- 1
    ok <- !is.na(lab) & lab != ""
    if (sum(ok) > 0 && mean(!is.na(out[ok])) > 0.9) return(out)
  }
  num(v)
}

# ---- Stata daily date conversion
to_td <- function(x) {
  tryCatch({
    if (inherits(x, "Date")) {
      as.numeric(x) + 3653
    } else if (inherits(x, "POSIXt")) {
      as.numeric(as.Date(x, tz = "UTC")) + 3653
    } else if (is.numeric(x) || haven::is.labelled(x)) {
      v <- num(x)
      m <- suppressWarnings(median(v, na.rm = TRUE))
      if (is.na(m)) rep(NA_real_, length(v))
      else if (m > 20000 && m < 23000) v
      else if (m > 1.7e12 && m < 2.0e12) floor(v / 86400000)
      else if (m > 17000 && m < 19000) v + 3653
      else rep(NA_real_, length(v))
    } else if (is.character(x)) {
      p <- suppressWarnings(lubridate::parse_date_time(x,
        orders = c("Ymd", "dmY", "mdY", "bdY", "dbY", "Ymd HMS", "bdY HMS", "mdY HMS", "dmY HMS", "Ymd HM"),
        quiet = TRUE))
      as.numeric(as.Date(p)) + 3653
    } else rep(NA_real_, length(x))
  }, error = function(e) rep(NA_real_, length(x)))
}
plaus <- function(v) mean(!is.na(v) & v > 21250 & v < 21700)
find_date <- function(d, pref) {
  cands <- unique(c(pref[pref %in% names(d)],
                    grep("today|date|start|time", names(d), value = TRUE, ignore.case = TRUE)))
  for (cn in cands) {
    v <- to_td(d[[cn]])
    if (plaus(v) > 0.5) return(list(name = cn, v = v))
  }
  NULL
}

# Stata egen cut(), at() icodes
scut <- function(x, br) {
  i <- findInterval(x, br)
  out <- i - 1
  out[is.na(x) | x < br[1] | x >= br[length(br)]] <- NA
  out
}

fit <- function(fml, data) feols(fml, data = data, cluster = ~a7, fixef.rm = "none")
co <- function(m, v) unname(coef(m)[v])

# =====================================================================
# 1. Build property-level analysis data
# =====================================================================
reg_raw <- rd(file.path(adm, "registration_noPII.dta"))
show("registration", reg_raw)

idr <- firstcol(reg_raw, c("compound1", "compound_code", "compound"))
cat("registration id column:", idr, "\n")
reg <- reg_raw
reg$..id <- num(reg[[idr]])
if ("tot_complete" %in% names(reg)) {
  reg <- reg[order(-(num(reg$tot_complete) %in% 1)), ]
}
reg <- reg[!is.na(reg$..id), ]
reg <- reg[!duplicated(reg$..id), ]
cat("registration unique ids:", nrow(reg), "\n")

ra <- rd(file.path(adm, "randomization_assignment.dta"))
show("randomization_assignment", ra)
ra_tmt_col <- firstcol(ra, c("tmt", "treatment"))
ra_df <- data.frame(a7 = num(ra$a7),
                    tmt_ra = if (!is.na(ra_tmt_col)) map_tmt(ra[[ra_tmt_col]]) else NA_real_,
                    stratum_ra = num(ra$stratum))
ra_df <- ra_df[!duplicated(ra_df$a7), ]
cat("randomization tmt table:\n"); print(table(ra_df$tmt_ra, useNA = "ifany"))

A <- data.frame(compound1 = reg$..id, a7 = num(reg$a7))
A$house  <- if ("house" %in% names(reg)) num(reg$house) else NA_real_
A$exempt <- if ("exempt" %in% names(reg)) num(reg$exempt) else NA_real_
A$pilot  <- if ("pilot" %in% names(reg)) num(reg$pilot) else NA_real_
A$rate   <- if ("rate" %in% names(reg)) num(reg$rate) else NA_real_
A$tmt_reg <- if ("tmt" %in% names(reg)) map_tmt(reg$tmt) else NA_real_
A$stratum_reg <- if ("stratum" %in% names(reg)) num(reg$stratum) else NA_real_
A <- left_join(A, ra_df, by = "a7")
cat("a7 in registration not found in randomization file:",
    length(setdiff(unique(A$a7), ra_df$a7)), "\n")

if (sum(!is.na(A$tmt_reg)) > 0) {
  cat("tmt_reg vs tmt_ra:\n"); print(table(A$tmt_reg, A$tmt_ra, useNA = "ifany"))
}
# Treatment is assigned at the neighborhood level: use the de facto (modal
# registration) treatment of each neighborhood, falling back to the
# randomization assignment where the registration record lacks tmt.
mode_reg <- A %>% filter(!is.na(tmt_reg), !is.na(a7)) %>%
  count(a7, tmt_reg) %>% group_by(a7) %>%
  arrange(desc(n), .by_group = TRUE) %>% slice(1) %>% ungroup() %>%
  transmute(a7, tmt_mode = tmt_reg)
A <- left_join(A, mode_reg, by = "a7")
A$tmt <- ifelse(!is.na(A$tmt_mode), A$tmt_mode, A$tmt_ra)
a7tab <- A %>% filter(!is.na(a7)) %>% distinct(a7, tmt_ra, tmt_mode, tmt)
cat("Neighborhood-level tmt_ra vs de facto tmt:\n"); print(table(a7tab$tmt_ra, a7tab$tmt, useNA = "ifany"))
A$stratum <- ifelse(!is.na(A$stratum_ra), A$stratum_ra, A$stratum_reg)

cat("house table:\n"); print(table(A$house, useNA = "ifany"))
cat("exempt table:\n"); print(table(A$exempt, useNA = "ifany"))
cat("pilot table:\n"); print(table(A$pilot, useNA = "ifany"))

A <- A[!(A$a7 %in% pilot_a7), ]
A <- A[!(!is.na(A$a7) & A$a7 > 400 & A$a7 < 500), ]
A <- A[!(A$pilot %in% 1), ]
A <- A[!(A$house %in% 3), ]
cat("Properties by tmt after restrictions:\n"); print(table(A$tmt, useNA = "ifany"))
cat("Neighborhoods by tmt:\n"); print(table(tapply(A$tmt, A$a7, max)))

# ---- dates (today_alt)
dt <- find_date(reg_raw[match(A$compound1, num(reg_raw[[idr]])), , drop = FALSE],
                c("today_alt", "today", "today_carto", "date", "date_carto", "starttime", "start", "submissiondate", "time"))
if (!is.null(dt)) {
  cat("today_alt taken from registration column:", dt$name, "\n")
  A$today_alt <- dt$v
} else {
  A$today_alt <- NA_real_
}

# ---- midline (visits)
mid <- tryCatch(rd(file.path(srv, "midline_noPII.dta")), error = function(e) NULL)
if (!is.null(mid)) {
  show("midline", mid)
  if ("tot_complete" %in% names(mid)) mid <- mid[num(mid$tot_complete) %in% 1, ]
  idm <- firstcol(mid, c("compound1", "compound", "compound_code"))
  cat("midline id column:", idm, "\n")
  mid$..id <- num(mid[[idm]])
  mid <- mid[!is.na(mid$..id) & !duplicated(mid$..id), ]
  M <- data.frame(compound1 = mid$..id,
                  visited = if ("visited" %in% names(mid)) num(mid$visited) else NA_real_,
                  visits = if ("visits" %in% names(mid)) num(mid$visits) else NA_real_)
  if (all(is.na(A$today_alt))) {
    dm <- find_date(mid, c("today_alt", "today", "date", "starttime", "start"))
    if (!is.null(dm)) {
      cat("today_alt fallback from midline column:", dm$name, "\n")
      M$today_mid <- dm$v
    }
  }
  A <- left_join(A, M, by = "compound1")
  if ("today_mid" %in% names(A)) { A$today_alt <- A$today_mid; A$today_mid <- NULL }
} else {
  A$visited <- NA_real_; A$visits <- NA_real_
}
if (all(is.na(A$today_alt))) {
  sch <- tryCatch(rd(file.path(adm, "randomization_schedule.dta")), error = function(e) NULL)
  if (!is.null(sch)) {
    show("randomization_schedule", sch)
    ds <- find_date(sch, c("today_alt", "date", "start_date", "date_start"))
    if (!is.null(ds)) {
      cat("today_alt fallback from schedule column:", ds$name, "\n")
      S <- data.frame(a7 = num(sch$a7), today_s = ds$v)
      S <- S[!duplicated(S$a7), ]
      A <- left_join(A, S, by = "a7"); A$today_alt <- A$today_s; A$today_s <- NULL
    }
  }
}
cat("today_alt summary:\n"); print(summary(A$today_alt))

# ---- today_alt: replace missing / implausible (non-2018) device dates with the
# neighborhood median registration date, so that properties are not dropped
# from the wave-FE specifications only because of a missing timestamp.
inCvL <- !is.na(A$today_alt) & A$today_alt >= 21355 & A$today_alt < 21532
cat("today_alt NA:", sum(is.na(A$today_alt)),
    " outside CvL bins:", sum(!is.na(A$today_alt) & !inCvL),
    " outside 2018:", sum(!is.na(A$today_alt) & (A$today_alt < 21185 | A$today_alt > 21549)), "\n")
cat("today_alt missing/out-of-bins by tmt:\n"); print(table(A$tmt, inCvL, useNA = "ifany"))
nb_med <- A %>% filter(inCvL) %>% group_by(a7) %>%
  summarise(med_td = floor(median(today_alt)), .groups = "drop")
A <- left_join(A, nb_med, by = "a7")
bad_td <- is.na(A$today_alt) | A$today_alt < 21185 | A$today_alt > 21549
fill_td <- bad_td & !is.na(A$med_td)
A$today_alt[fill_td] <- A$med_td[fill_td]
A$med_td <- NULL
cat("today_alt filled with neighborhood median for", sum(fill_td), "properties\n")
cat("DEVIATION: Missing or non-2018 registration dates replaced by the neighborhood median registration date when building wave FE (today_alt)\n")

# ---- tax payments
if ("taxes_paid" %in% names(reg)) {
  cat("Using taxes_paid from registration file\n")
  rr <- reg[match(A$compound1, reg$..id), ]
  A$taxes_paid <- num(rr$taxes_paid)
  A$taxes_paid_amt <- if ("taxes_paid_amt" %in% names(rr)) num(rr$taxes_paid_amt) else A$taxes_paid * A$rate
} else {
  pay <- rd(file.path(adm, "tax_payments_noPII.dta"))
  show("tax_payments", pay)
  kp <- firstcol(pay, c("compound1", "compound_code", "compound"))
  pay_id <- NULL
  if (!is.na(kp)) {
    pay_id <- num(pay[[kp]])
  } else {
    tr <- rd(file.path(adm, "taxroll_noPII.dta"))
    show("taxroll", tr)
    ktr <- firstcol(tr, c("compound1", "compound_code", "compound"))
    common <- setdiff(intersect(names(pay), names(tr)), c("a7", "commune", "stratum", "house", "rate", "amount", ktr))
    cat("pay/taxroll common columns:", paste(common, collapse = ", "), "\n")
    if (length(common) && !is.na(ktr)) {
      kc <- common[1]
      map <- data.frame(k = as.character(tr[[kc]]), id = num(tr[[ktr]]))
      map <- map[!duplicated(map$k), ]
      pay_id <- map$id[match(as.character(pay[[kc]]), map$k)]
    }
  }
  amtc <- firstcol(pay, c("amount", "amt_paid", "paid_amt", "amt", "montant", "amount_paid", "tax_amount", "paid_amount"))
  if (is.na(amtc)) {
    cand <- grep("amt|amount|montant", names(pay), value = TRUE)
    amtc <- if (length(cand)) cand[1] else NA_character_
  }
  cat("payment id/amount columns:", kp, amtc, "\n")
  P <- data.frame(compound1 = pay_id, amt = if (!is.na(amtc)) num(pay[[amtc]]) else NA_real_)
  P <- P[!is.na(P$compound1), ]
  print(summary(P$amt))
  cat("payment records per compound:\n"); print(table(pmin(table(P$compound1), 5)))
  # One property-tax payment per property: duplicate receipt records are not summed
  Pa <- P %>% group_by(compound1) %>%
    summarise(amt = suppressWarnings(max(amt, na.rm = TRUE)), .groups = "drop")
  Pa$amt[!is.finite(Pa$amt)] <- NA
  cat("DEVIATION: Revenue per property uses one payment per property (max over duplicate receipt records) rather than summing duplicate records\n")
  A$taxes_paid <- as.numeric(A$compound1 %in% Pa$compound1)
  A$taxes_paid_amt <- Pa$amt[match(A$compound1, Pa$compound1)]
  A$taxes_paid_amt[is.na(A$taxes_paid_amt)] <- 0
  if (all(is.na(P$amt))) A$taxes_paid_amt <- A$taxes_paid * A$rate
}
cat("rate summary:\n"); print(summary(A$rate))
cat("Mean amount per payer by tmt (raw):\n")
print(tapply(A$taxes_paid_amt[A$taxes_paid %in% 1], A$tmt[A$taxes_paid %in% 1], mean, na.rm = TRUE))
# Revenue = the property's assigned (possibly abated) tax rate when paid;
# receipt amounts above the assigned rate (duplicates, multi-year or
# mis-keyed amounts) are capped at the assigned rate.
rate_ok <- !is.na(A$rate) & A$rate > 0
rmed <- suppressWarnings(median(A$rate[rate_ok]))
if (sum(rate_ok) > 0 && is.finite(rmed) && rmed > 300 && rmed < 50000) {
  pd <- A$taxes_paid %in% 1 & rate_ok
  A$taxes_paid_amt[pd] <- ifelse(A$taxes_paid_amt[pd] > 0,
                                 pmin(A$taxes_paid_amt[pd], A$rate[pd]),
                                 A$rate[pd])
  cat("DEVIATION: Revenue per paying property capped at the property's assigned tax rate (amount set to the rate when the receipt amount is missing)\n")
  cat("Mean amount per payer by tmt (capped):\n")
  print(tapply(A$taxes_paid_amt[A$taxes_paid %in% 1], A$tmt[A$taxes_paid %in% 1], mean, na.rm = TRUE))
}
cat("Compliance by tmt:\n"); print(tapply(A$taxes_paid, A$tmt, mean, na.rm = TRUE))
cat("Revenue by tmt:\n"); print(tapply(A$taxes_paid_amt, A$tmt, mean, na.rm = TRUE))

A$t_c <- as.numeric(A$tmt %in% 1)
A$t_l <- as.numeric(A$tmt %in% 2)
A$t_cli <- as.numeric(A$tmt %in% 3)

# visit_post_carto (Stata logic)
A$visit_post_carto <- NA_real_
A$visit_post_carto[(A$visited %in% 0) | (!is.na(A$visits) & A$visits != 0)] <- 0
A$visit_post_carto[!is.na(A$visits) & A$visits > 1] <- 1

A$time_FE_tdm_2mo_CvL <- scut(A$today_alt, c(21355, 21415, 21475, 21532))
A$time_FE_tdm_2mo_CvL_t6 <- scut(A$today_alt, c(21355, 21415, 21475, 21529))
A$time_FE_tdm_2mo_CvCLI <- scut(A$today_alt, c(21365.5, 21425.5, 21485.5, 21519))

# =====================================================================
# 2. Table 4
# =====================================================================
D4 <- A[A$tmt %in% c(1, 2), ]
tryCatch({
  m1 <- fit(taxes_paid ~ t_l | stratum, D4)
  put("compliance_local_table4_panelA_col1", co(m1, "t_l"))
  put("n_obs_table4_col1", nobs(m1))
  cat("T4 c1: b=", co(m1, "t_l"), " se=", se(m1)["t_l"], " N=", nobs(m1), "\n")
}, error = function(e) cat("T4 c1 error:", conditionMessage(e), "\n"))
tryCatch({
  m2 <- fit(taxes_paid ~ t_l | stratum + time_FE_tdm_2mo_CvL, D4)
  put("compliance_local_table4_panelA_col2", co(m2, "t_l"))
  put("n_obs_table4_col2", nobs(m2))
  cat("T4 c2: b=", co(m2, "t_l"), " se=", se(m2)["t_l"], " N=", nobs(m2), "\n")
}, error = function(e) cat("T4 c2 error:", conditionMessage(e), "\n"))
tryCatch({
  m4 <- fit(taxes_paid ~ t_l | stratum + house + time_FE_tdm_2mo_CvL, D4)
  put("compliance_local_house_fe_table4_panelA_col4", co(m4, "t_l"))
  cat("T4 c4: N=", nobs(m4), "\n")
}, error = function(e) cat("T4 c4 error:", conditionMessage(e), "\n"))
tryCatch({
  D5 <- D4[is.na(D4$exempt) | D4$exempt != 1, ]
  m5 <- fit(taxes_paid ~ t_l | stratum + house + time_FE_tdm_2mo_CvL, D5)
  put("compliance_local_exempt_excluded_table4_panelA_col5", co(m5, "t_l"))
  cat("T4 c5: N=", nobs(m5), "\n")
}, error = function(e) cat("T4 c5 error:", conditionMessage(e), "\n"))
tryCatch({
  r2 <- fit(taxes_paid_amt ~ t_l | stratum + time_FE_tdm_2mo_CvL, D4)
  put("revenue_local_table4_panelB_col2", co(r2, "t_l"))
  r4 <- fit(taxes_paid_amt ~ t_l | stratum + house + time_FE_tdm_2mo_CvL, D4)
  put("revenue_local_house_fe_table4_panelB_col4", co(r4, "t_l"))
}, error = function(e) cat("T4 revenue error:", conditionMessage(e), "\n"))

# =====================================================================
# 3. Table 5 Panel B: paid bribe (endline)
# =====================================================================
tryCatch({
  el <- rd(file.path(srv, "endline_round1_noPII.dta"))
  show("endline_round1", el)
  if ("tot_complete" %in% names(el)) el <- el[num(el$tot_complete) %in% 1, ]
  b <- if ("bribe" %in% names(el)) num(el$bribe) else rep(NA_real_, nrow(el))
  for (v in c("bribe2a", "bribe2b", "bribe3")) {
    if (v %in% names(el)) b[is.na(b)] <- num(el[[v]])[is.na(b)]
  }
  E <- data.frame(a7 = num(el$a7), bribe_endline = b)
  T7 <- A %>% filter(!is.na(a7)) %>% group_by(a7) %>%
    summarise(treatment = suppressWarnings(max(tmt, na.rm = TRUE)),
              stratum = suppressWarnings(max(stratum, na.rm = TRUE)), .groups = "drop")
  T7$treatment[!is.finite(T7$treatment)] <- NA
  T7$stratum[!is.finite(T7$stratum)] <- NA
  E <- inner_join(E, T7, by = "a7")
  E$t_l <- as.numeric(E$treatment %in% 2)
  mb <- fit(bribe_endline ~ t_l | stratum, E[E$treatment %in% c(1, 2), ])
  put("paid_bribe_endline_local_table5_panelB", co(mb, "t_l"))
  cat("T5 bribe N=", nobs(mb), "\n")
}, error = function(e) cat("T5 error:", conditionMessage(e), "\n"))

# =====================================================================
# 4. Table 6 col 1: visited post registration
# =====================================================================
tryCatch({
  m6 <- fit(visit_post_carto ~ t_l | house + stratum + time_FE_tdm_2mo_CvL_t6, D4)
  put("visited_by_collector_local_table6_col1", co(m6, "t_l"))
  cat("T6 c1 N=", nobs(m6), "\n")
}, error = function(e) cat("T6 error:", conditionMessage(e), "\n"))

# =====================================================================
# 5. Table 7: CLI vs Central
# =====================================================================
tryCatch({
  D7 <- A[A$tmt %in% c(1, 3), ]
  c1 <- fit(taxes_paid ~ t_cli | house + stratum + time_FE_tdm_2mo_CvCLI, D7)
  put("compliance_cli_table7_col1", co(c1, "t_cli"))
  c2 <- fit(taxes_paid_amt ~ t_cli | house + stratum + time_FE_tdm_2mo_CvCLI, D7)
  put("revenue_cli_table7_col2", co(c2, "t_cli"))
  cat("T7 N=", nobs(c1), "\n")
}, error = function(e) cat("T7 error:", conditionMessage(e), "\n"))

# =====================================================================
# 6. Table 8 Panel A col 2: ease of payment within CLI
# =====================================================================
tryCatch({
  A8 <- A[A$tmt %in% c(1, 2, 3), ]
  # 1:m merge with endline compound codes (replicates the do-file's duplication)
  el2 <- rd(file.path(srv, "endline_round1_noPII.dta"))
  if ("tot_complete" %in% names(el2)) el2 <- el2[num(el2$tot_complete) %in% 1, ]
  cc <- num(el2$compound_code)
  if (all(c("compound_code_prev", "move") %in% names(el2))) {
    mv <- num(el2$move)
    rep_ix <- mv %in% c(1, 2)
    cc[rep_ix] <- num(el2$compound_code_prev)[rep_ix]
  }
  cc[cc %in% c(99999, 9999999)] <- 999999
  cc <- cc[!is.na(cc) & cc != 999999]
  cnt <- as.data.frame(table(cc), stringsAsFactors = FALSE)
  cnt$cc <- as.numeric(cnt$cc)
  nrep <- cnt$Freq[match(A8$compound1, cnt$cc)]
  nrep[is.na(nrep)] <- 1
  A8 <- A8[rep(seq_len(nrow(A8)), times = nrep), ]
  cons <- rd(file.path(srv, "chief_consultations.dta"))
  show("chief_consultations", cons)
  C <- data.frame(compound1 = num(cons$compound1), pay_ease = num(cons$pay_ease),
                  willingness = num(cons$willingness))
  C <- C[!is.na(C$compound1) & !duplicated(C$compound1), ]
  A8 <- left_join(A8, C, by = "compound1")
  cat("pay_ease table (CLI):\n"); print(table(A8$pay_ease[A8$t_cli == 1], useNA = "ifany"))
  m8 <- fit(taxes_paid ~ pay_ease | house + stratum, A8[A8$t_cli == 1, ])
  put("compliance_ease_of_payment_cli_table8_panelA_col2", co(m8, "pay_ease"))
  cat("T8 N=", nobs(m8), "\n")
}, error = function(e) cat("T8 error:", conditionMessage(e), "\n"))

# =====================================================================
# Output
# =====================================================================
for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.10g\n", nm, results[[nm]]))
}