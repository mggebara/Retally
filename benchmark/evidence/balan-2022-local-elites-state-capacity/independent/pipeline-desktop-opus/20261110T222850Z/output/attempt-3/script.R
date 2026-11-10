suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/balan_2022_local_elites_state_capacity.script-free"
base <- file.path(root, "Replication Materials - Updated October 2025", "Data", "01_base")

rd <- function(rel) {
  p <- file.path(base, rel)
  if (!file.exists(p)) { message("Missing file: ", p); return(NULL) }
  tryCatch(haven::read_dta(p), error = function(e) { message("Read error ", rel, ": ", conditionMessage(e)); NULL })
}

fc <- function(df, cands) {
  if (is.null(df)) return(NA_character_)
  n <- names(df); lo <- tolower(n)
  for (c in cands) { i <- which(lo == tolower(c)); if (length(i)) return(n[i[1]]) }
  NA_character_
}

num <- function(x) {
  x <- haven::zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  suppressWarnings(as.numeric(x))
}

# Normalize property identifiers so numeric and string IDs match across files
pidc <- function(x) {
  x <- haven::zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.numeric(x)) {
    if (all(is.na(x) | x == round(x))) return(ifelse(is.na(x), NA_character_, sprintf("%.0f", x)))
    return(as.character(x))
  }
  x <- trimws(as.character(x))
  x[x == ""] <- NA_character_
  x
}

binarize <- function(x) {
  x <- num(x)
  x[!is.na(x) & x < 0] <- NA
  u <- sort(unique(x[!is.na(x)]))
  if (length(u) == 0) return(x)
  if (all(u %in% c(0, 1))) return(x)
  if (all(u %in% c(1, 2))) return(ifelse(x == 1, 1, 0))  # 1 = yes, 2 = no
  as.numeric(x > 0)
}

emit <- function(name, val) {
  if (length(val) == 1 && !is.na(val) && is.finite(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
  else message("Could not compute ", name)
}

desc <- function(nm, df) {
  if (is.null(df)) return(invisible())
  message(sprintf("[%s] %d rows x %d cols: %s", nm, nrow(df), ncol(df),
                  paste(head(names(df), 80), collapse = ", ")))
}

# ---------------------------------------------------------------------------
# Treatment mapping
# ---------------------------------------------------------------------------
map_arm_labels <- function(x) {
  lab <- if (haven::is.labelled(x)) as.character(haven::as_factor(x, levels = "labels")) else as.character(x)
  l <- tolower(trimws(lab))
  out <- rep(NA_character_, length(l))
  out[grepl("cxl|x local|central_x|centralx|central x|cxl", l)] <- "CXL"
  out[is.na(out) & grepl("^cli$|cli|info", l)] <- "CLI"
  out[is.na(out) & grepl("local|chief|chef", l)] <- "Local"
  out[is.na(out) & grepl("central|state", l)] <- "Central"
  out[is.na(out) & grepl("control|declar|pure", l)] <- "Control"
  out
}

map_arm_numeric_by_counts <- function(code, nbid) {
  # assign by neighborhood counts: ~5 Control, ~50 CXL, ~80 CLI, two ~110 Central/Local (lower code = Central)
  d <- unique(data.frame(code = code, id = nbid))
  d <- d[!is.na(d$code), ]
  cnt <- sort(table(d$code))
  codes <- as.numeric(names(cnt))
  out_map <- list()
  if (length(codes) == 5) {
    out_map[[as.character(codes[1])]] <- "Control"
    out_map[[as.character(codes[2])]] <- "CXL"
    out_map[[as.character(codes[3])]] <- "CLI"
    big <- sort(codes[4:5])
    out_map[[as.character(big[1])]] <- "Central"
    out_map[[as.character(big[2])]] <- "Local"
  } else {
    dflt <- c("0" = "Control", "1" = "Central", "2" = "Local", "3" = "CLI", "4" = "CXL")
    for (k in names(dflt)) out_map[[k]] <- dflt[[k]]
  }
  res <- vapply(as.character(code), function(k) if (!is.na(k) && !is.null(out_map[[k]])) out_map[[k]] else NA_character_, "")
  unname(res)
}

map_arm <- function(x, nbid) {
  a <- map_arm_labels(x)
  if (mean(is.na(a)) > 0.5) {
    a <- map_arm_numeric_by_counts(num(x), nbid)
  }
  a
}

# ---------------------------------------------------------------------------
# Load data
# ---------------------------------------------------------------------------
rand  <- rd("admin_data/randomization_assignment.dta")
troll <- rd("admin_data/taxroll_noPII.dta")
reg   <- rd("admin_data/registration_noPII.dta")
pay   <- rd("admin_data/tax_payments_noPII.dta")
sched <- rd("admin_data/randomization_schedule.dta")
timing <- rd("admin_data/tax_payment_timing_noPII.dta")
desc("rand", rand); desc("taxroll", troll); desc("registration", reg); desc("payments", pay)
desc("schedule", sched); desc("timing", timing)

nb_cands <- c("a7", "polygon", "poly", "neighborhood", "neighbourhood", "grid_nm", "poly_nm")
# compound1 is the property tax ID shared by tax roll, registration and payments
pid_cands <- c("compound1", "compound_code", "compound", "code", "house_code", "property_id",
               "prop_id", "hh_code", "taxid", "tax_id", "id")

# Neighborhood-level assignment
nb_r <- fc(rand, nb_cands)
nb <- data.frame(a7 = as.character(num(rand[[nb_r]])))
if (all(is.na(nb$a7))) nb$a7 <- as.character(haven::zap_labels(rand[[nb_r]]))
st_r <- fc(rand, c("stratum", "strata", "stratum_jon"))
nb$stratum <- as.character(num(rand[[st_r]]))
tr_r <- fc(rand, c("tmt", "treatment_defacto", "treatment", "treat", "arm"))
nb$arm_rand <- map_arm(rand[[tr_r]], nb$a7)
message("Randomization (de jure) arm counts: "); print(table(nb$arm_rand, useNA = "ifany"))

# De facto assignment: one CXL neighborhood received Local by mistake. Use the
# treatment actually implemented during registration (tmt), modal per neighborhood.
tryCatch({
  if (!is.null(reg)) {
    rt <- fc(reg, c("tmt")); ra <- fc(reg, nb_cands)
    if (!is.na(rt) && !is.na(ra)) {
      ra7 <- as.character(num(reg[[ra]]))
      rarm <- map_arm(reg[[rt]], ra7)
      dd <- data.frame(a7 = ra7, arm = rarm, stringsAsFactors = FALSE)
      dd <- dd[!is.na(dd$a7) & !is.na(dd$arm), ]
      md <- dd %>% count(a7, arm) %>% group_by(a7) %>% slice_max(n, n = 1, with_ties = FALSE) %>% ungroup()
      defacto <- md$arm[match(nb$a7, md$a7)]
      cand <- ifelse(is.na(defacto), nb$arm_rand, defacto)
      tb <- table(cand)
      message("Candidate de facto arm counts:"); print(tb)
      nL <- if ("Local" %in% names(tb)) tb[["Local"]] else 0
      nX <- if ("CXL" %in% names(tb)) tb[["CXL"]] else 0
      if (nL >= 109 && nL <= 113 && nX >= 48 && nX <= 52) {
        nb$arm_rand <- cand
        message("Using de facto neighborhood assignment")
      }
    }
  }
}, error = function(e) message("De facto mapping: ", conditionMessage(e)))
message("Neighborhood arm counts used: "); print(table(nb$arm_rand, useNA = "ifany"))

# ---------------------------------------------------------------------------
# Property-level base: tax roll (fallback: registration)
# ---------------------------------------------------------------------------
P <- if (!is.null(troll)) troll else reg
P_nb <- fc(P, nb_cands)
df <- data.frame(a7 = as.character(num(P[[P_nb]])), stringsAsFactors = FALSE)
if (all(is.na(df$a7))) df$a7 <- as.character(haven::zap_labels(P[[P_nb]]))
P_pid <- fc(P, pid_cands)
df$pid <- if (!is.na(P_pid)) pidc(P[[P_pid]]) else NA_character_

# Arm: prefer property file's own (de facto) treatment variable
P_tr <- fc(P, c("tmt", "treatment_defacto", "treatment", "treat", "arm"))
if (!is.na(P_tr)) {
  df$arm <- map_arm(P[[P_tr]], df$a7)
} else df$arm <- NA_character_
df <- left_join(df, nb, by = "a7")
if (mean(is.na(df$arm)) > 0.5) df$arm <- df$arm_rand
df$arm[is.na(df$arm)] <- df$arm_rand[is.na(df$arm)]
P_st <- fc(P, c("stratum", "strata"))
if (!is.na(P_st)) {
  s2 <- as.character(num(P[[P_st]]))
  df$stratum <- ifelse(is.na(df$stratum), s2, df$stratum)
}
message("Property arm counts:"); print(table(df$arm, useNA = "ifany"))

# Pilot drop
P_pilot <- fc(P, c("pilot"))
if (!is.na(P_pilot)) { pl <- num(P[[P_pilot]]); df$pilot <- pl } else df$pilot <- NA

# Bring registration info if needed
getP <- function(cands) {
  v <- fc(P, cands)
  if (!is.na(v)) return(P[[v]])
  if (!is.null(reg) && !identical(P, reg) && !is.na(P_pid)) {
    rv <- fc(reg, cands); rp <- fc(reg, pid_cands)
    if (!is.na(rv) && !is.na(rp)) {
      m <- data.frame(pid = pidc(reg[[rp]]), v = num(reg[[rv]]), stringsAsFactors = FALSE)
      m <- m[!is.na(m$pid) & !duplicated(m$pid), ]
      return(m$v[match(df$pid, m$pid)])
    }
  }
  rep(NA, nrow(df))
}

df$house <- num(getP(c("house", "house_type", "housetype", "house_cat")))
df$exempt <- binarize(getP(c("exempt", "exempt_status", "is_exempt")))

# Compliance / revenue
P_paid <- fc(P, c("taxes_paid", "paid", "tax_paid", "paid_tax", "compliance"))
P_amt  <- fc(P, c("taxes_paid_amt", "amount_paid", "paid_amt", "amt_paid", "amount", "revenue"))
if (!is.na(P_paid)) {
  df$paid <- binarize(P[[P_paid]]); df$paid[is.na(df$paid)] <- 0
} else df$paid <- NA
if (!is.na(P_amt)) {
  df$amt <- num(P[[P_amt]]); df$amt[is.na(df$amt)] <- 0
} else df$amt <- NA
if ((is.na(P_paid) || is.na(P_amt)) && !is.null(pay)) {
  pp <- fc(pay, pid_cands)
  pa <- fc(pay, c("amountCF", "amount", "amt", "amount_paid", "taxes_paid_amt", "paid_amt"))
  message("Payments matched on ", pp, ", amount column ", pa)
  if (!is.na(pp)) {
    py <- data.frame(pid = pidc(pay[[pp]]),
                     amt = if (!is.na(pa)) num(pay[[pa]]) else 1, stringsAsFactors = FALSE)
    ppd <- fc(pay, c("paid"))
    if (!is.na(ppd)) {
      pv <- binarize(pay[[ppd]])
      py <- py[is.na(pv) | pv == 1, ]
    }
    py <- py[!is.na(py$pid), ]
    message("Payment amount quantiles:"); print(quantile(py$amt, c(0, .1, .25, .5, .75, .9, .99, 1), na.rm = TRUE))
    message("Payment rows per property:"); print(table(table(py$pid)))
    # One annual property tax per property: count a single payment per property
    # (duplicate receipts would otherwise be summed and inflate revenue)
    agg <- py %>% group_by(pid) %>%
      summarise(amt = if (all(is.na(amt))) NA_real_ else max(amt, na.rm = TRUE), .groups = "drop")
    i <- match(df$pid, agg$pid)
    message("Properties matched to a payment: ", sum(!is.na(i)))
    if (is.na(P_paid)) df$paid <- as.numeric(!is.na(i))
    if (is.na(P_amt)) { df$amt <- ifelse(is.na(i), 0, agg$amt[i]); df$amt[is.na(df$amt)] <- 0 }
    cat("DEVIATION: Revenue counts one payment per property (max amount across duplicate receipts) instead of summing all receipt rows\n")
  }
}
if (all(is.na(df$amt))) df$amt <- 0

# Sample: 356 study neighborhoods, no pilot, no villas
df <- df[df$a7 %in% nb$a7, ]
if (!all(is.na(df$pilot))) df <- df[is.na(df$pilot) | df$pilot != 1, ]
hv <- table(df$house)
if (length(hv) > 2) {
  keep <- as.numeric(names(sort(hv, decreasing = TRUE))[1:2])
  df <- df[is.na(df$house) | df$house %in% keep, ]
}
# One row per registered property
ndup <- sum(!is.na(df$pid) & duplicated(df$pid))
message("Duplicate property IDs dropped: ", ndup)
df <- df[is.na(df$pid) | !duplicated(df$pid), ]
message("Rows after restrictions: ", nrow(df))
print(table(df$arm, useNA = "ifany"))
message("Mean compliance by arm:"); print(tapply(df$paid, df$arm, mean))
message("Mean revenue by arm:"); print(tapply(df$amt, df$arm, mean))

# ---------------------------------------------------------------------------
# Neighborhood campaign dates for time fixed effects
# ---------------------------------------------------------------------------
as_date_any <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  NULL
}
nb_dates <- function(D) {
  if (is.null(D)) return(NULL)
  idc <- fc(D, nb_cands); if (is.na(idc)) return(NULL)
  dcols <- names(D)[vapply(D, function(z) inherits(z, "Date") || inherits(z, "POSIXt"), TRUE)]
  if (!length(dcols)) return(NULL)
  pref <- dcols[grepl("start|first|date|today|day", tolower(dcols))]
  dc <- if (length(pref)) pref[1] else dcols[1]
  message("Using date column ", dc)
  d <- data.frame(a7 = as.character(num(D[[idc]])), d = as_date_any(D[[dc]]))
  d <- d[!is.na(d$d) & d$d >= as.Date("2018-01-01") & d$d < as.Date("2019-07-01"), ]
  if (!nrow(d)) return(NULL)
  # typical (median) campaign date in the neighborhood, robust to stray early/late visits
  d %>% group_by(a7) %>% summarise(date = median(d), .groups = "drop")
}
nbd <- NULL
for (D in list(sched, reg, troll, timing)) {
  nbd <- tryCatch(nb_dates(D), error = function(e) NULL)
  if (!is.null(nbd) && nrow(nbd) > 200) break
}
if (is.null(nbd)) {
  # fallback: Month in collector info
  ci <- rd("admin_data/campaign_collector_info.dta")
  mc <- fc(ci, c("Month", "month")); ic <- fc(ci, nb_cands)
  if (!is.na(mc) && !is.na(ic)) {
    nbd <- data.frame(a7 = as.character(num(ci[[ic]])),
                      date = as.Date("2018-01-01") + 30.44 * (num(ci[[mc]]) - 1)) %>%
      group_by(a7) %>% summarise(date = min(date), .groups = "drop")
  }
}
message("Neighborhood dates available: ", if (is.null(nbd)) 0 else nrow(nbd))

# Two-month calendar periods of the campaign; keep only periods in which both
# compared arms were being collected.
make_period <- function(a7, arm, armA, armB) {
  if (is.null(nbd)) return(rep(1, length(a7)))
  bin_of <- function(d) {
    m <- as.numeric(format(d, "%Y")) * 12 + as.numeric(format(d, "%m")) - 1
    floor(m / 2)
  }
  d <- nbd$date[match(a7, nbd$a7)]
  p <- bin_of(d)
  nbx <- data.frame(a7 = nb$a7, arm = nb$arm_rand, stringsAsFactors = FALSE)
  arm_nb <- tapply(arm, a7, function(z) z[1])
  nbx$arm <- ifelse(nbx$a7 %in% names(arm_nb), arm_nb[nbx$a7], nbx$arm)
  nbx$p <- bin_of(nbd$date[match(nbx$a7, nbd$a7)])
  nbx <- nbx[!is.na(nbx$p) & nbx$arm %in% c(armA, armB), ]
  tb <- table(nbx$p, nbx$arm)
  message("Neighborhoods by 2-month period (", armA, " vs ", armB, "):"); print(tb)
  okp <- rownames(tb)[apply(tb, 1, function(r) all(r[colnames(tb) %in% c(armA, armB)] > 0)) &
                        all(c(armA, armB) %in% colnames(tb))]
  p[is.na(d) | !(as.character(p) %in% okp)] <- NA
  p
}

# ---------------------------------------------------------------------------
# Table 4
# ---------------------------------------------------------------------------
lc <- df[df$arm %in% c("Local", "Central"), ]
lc$local <- as.numeric(lc$arm == "Local")
lc$period <- make_period(lc$a7, lc$arm, "Local", "Central")

r <- list()
m1 <- tryCatch(feols(paid ~ local | stratum, data = lc, cluster = ~a7), error = function(e) { message(e$message); NULL })
if (!is.null(m1)) { r$c1 <- coef(m1)["local"]; r$n1 <- nobs(m1) }
lc2 <- lc[!is.na(lc$period), ]
m2 <- tryCatch(feols(paid ~ local | stratum + period, data = lc2, cluster = ~a7), error = function(e) { message(e$message); NULL })
if (!is.null(m2)) { r$c2 <- coef(m2)["local"]; r$n2 <- nobs(m2) }
m4 <- tryCatch(feols(paid ~ local | stratum + period + house, data = lc2, cluster = ~a7), error = function(e) { message(e$message); NULL })
if (!is.null(m4)) r$c4 <- coef(m4)["local"]
lc5 <- lc2[is.na(lc2$exempt) | lc2$exempt != 1, ]
m5 <- tryCatch(feols(paid ~ local | stratum + period + house, data = lc5, cluster = ~a7), error = function(e) { message(e$message); NULL })
if (!is.null(m5)) r$c5 <- coef(m5)["local"]
mb2 <- tryCatch(feols(amt ~ local | stratum + period, data = lc2, cluster = ~a7), error = function(e) { message(e$message); NULL })
if (!is.null(mb2)) r$b2 <- coef(mb2)["local"]
mb4 <- tryCatch(feols(amt ~ local | stratum + period + house, data = lc2, cluster = ~a7), error = function(e) { message(e$message); NULL })
if (!is.null(mb4)) r$b4 <- coef(mb4)["local"]

# ---------------------------------------------------------------------------
# Table 7: CLI vs Central
# ---------------------------------------------------------------------------
cc <- df[df$arm %in% c("CLI", "Central"), ]
cc$cli <- as.numeric(cc$arm == "CLI")
cc$period <- make_period(cc$a7, cc$arm, "CLI", "Central")
cc2 <- cc[!is.na(cc$period), ]
m7a <- tryCatch(feols(paid ~ cli | stratum + period + house, data = cc2, cluster = ~a7), error = function(e) { message(e$message); NULL })
m7b <- tryCatch(feols(amt ~ cli | stratum + period + house, data = cc2, cluster = ~a7), error = function(e) { message(e$message); NULL })

# ---------------------------------------------------------------------------
# Table 8: ease of payment rating within CLI
# ---------------------------------------------------------------------------
c8 <- NA
tryCatch({
  cli <- df[df$arm == "CLI", ]
  rating <- rep(NA_real_, nrow(cli))
  ease_pat <- "ease|abil|capac|pay_ease|easy"
  v <- names(P)[grepl(ease_pat, tolower(names(P)))]
  if (length(v)) {
    vv <- num(P[[v[1]]])
    idx <- match(cli$pid, pidc(P[[P_pid]]))
    rating <- vv[idx]
    message("Ease rating from tax roll column ", v[1])
  } else {
    cons <- rd("survey_data/chief_consultations.dta"); desc("chief_consultations", cons)
    v <- names(cons)[grepl(ease_pat, tolower(names(cons)))]
    cp <- fc(cons, pid_cands)
    if (length(v) && !is.na(cp)) {
      message("Ease rating from chief_consultations column ", v[1], " matched on ", cp)
      m <- data.frame(pid = pidc(cons[[cp]]), v = num(cons[[v[1]]]))
      m <- m[!is.na(m$pid) & !duplicated(m$pid), ]
      rating <- m$v[match(cli$pid, m$pid)]
    }
  }
  rating[!is.na(rating) & rating < 0] <- NA
  cli$ease <- rating
  m8 <- feols(paid ~ ease | house + stratum, data = cli, cluster = ~a7)
  c8 <<- coef(m8)["ease"]
}, error = function(e) message("Table 8: ", conditionMessage(e)))

# ---------------------------------------------------------------------------
# Table 5: bribe (endline)
# ---------------------------------------------------------------------------
c5b <- NA
tryCatch({
  en <- rd("survey_data/endline_round1_noPII.dta"); desc("endline_round1", en)
  ei <- fc(en, nb_cands)
  bv <- fc(en, c("paid_bribe", "bribe", "transport"))
  e <- data.frame(a7 = as.character(num(en[[ei]])), y = binarize(en[[bv]]), stringsAsFactors = FALSE)
  e <- left_join(e, nb[, c("a7", "stratum", "arm_rand")], by = "a7")
  arm_nb <- tapply(df$arm, df$a7, function(z) z[1])
  e$arm <- ifelse(e$a7 %in% names(arm_nb), arm_nb[e$a7], e$arm_rand)
  e <- e[e$arm %in% c("Local", "Central") & !is.na(e$y), ]
  e$local <- as.numeric(e$arm == "Local")
  mb <- feols(y ~ local | stratum, data = e, cluster = ~a7)
  c5b <<- coef(mb)["local"]
}, error = function(e) message("Table 5: ", conditionMessage(e)))

# ---------------------------------------------------------------------------
# Table 6: visited by collector (midline)
# ---------------------------------------------------------------------------
c6 <- NA
tryCatch({
  mid <- rd("survey_data/midline_noPII.dta"); desc("midline", mid)
  mi <- fc(mid, nb_cands)
  vv <- fc(mid, c("visited", "visit", "visited_post"))
  md <- data.frame(a7 = as.character(num(mid[[mi]])), y = binarize(mid[[vv]]), stringsAsFactors = FALSE)
  mp <- fc(mid, pid_cands)
  mh <- fc(mid, c("house", "house_type"))
  if (!is.na(mh)) md$house <- num(mid[[mh]]) else if (!is.na(mp)) {
    md$house <- df$house[match(pidc(mid[[mp]]), df$pid)]
  } else md$house <- 1
  md <- left_join(md, nb[, c("a7", "stratum", "arm_rand")], by = "a7")
  arm_nb <- tapply(df$arm, df$a7, function(z) z[1])
  md$arm <- ifelse(md$a7 %in% names(arm_nb), arm_nb[md$a7], md$arm_rand)
  md <- md[md$arm %in% c("Local", "Central") & !is.na(md$y), ]
  md$local <- as.numeric(md$arm == "Local")
  md$period <- make_period(md$a7, md$arm, "Local", "Central")
  md <- md[!is.na(md$period), ]
  mv <- feols(y ~ local | house + stratum + period, data = md, cluster = ~a7)
  c6 <<- coef(mv)["local"]
}, error = function(e) message("Table 6: ", conditionMessage(e)))

cat("DEVIATION: Time fixed effects built as two-month calendar periods of each neighborhood's median 2018 registration date, keeping only periods in which both compared arms operated (exact wave definition not given in the summary)\n")

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
emit("compliance_local_table4_panelA_col1", unname(r$c1))
emit("compliance_local_table4_panelA_col2", unname(r$c2))
emit("compliance_local_house_fe_table4_panelA_col4", unname(r$c4))
emit("compliance_local_exempt_excluded_table4_panelA_col5", unname(r$c5))
emit("revenue_local_table4_panelB_col2", unname(r$b2))
emit("revenue_local_house_fe_table4_panelB_col4", unname(r$b4))
emit("n_obs_table4_col1", as.numeric(r$n1))
emit("n_obs_table4_col2", as.numeric(r$n2))
emit("paid_bribe_endline_local_table5_panelB", unname(c5b))
emit("visited_by_collector_local_table6_col1", unname(c6))
emit("compliance_cli_table7_col1", if (!is.null(m7a)) unname(coef(m7a)["cli"]) else NA)
emit("revenue_cli_table7_col2", if (!is.null(m7b)) unname(coef(m7b)["cli"]) else NA)
emit("compliance_ease_of_payment_cli_table8_panelA_col2", unname(c8))