suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/balan_2022_local_elites_state_capacity"
pkg  <- file.path(root, "Replication Materials - Updated October 2025")
base <- file.path(pkg, "Data", "01_base")
adm  <- file.path(base, "admin_data")
srv  <- file.path(base, "survey_data")

num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  suppressWarnings(as.numeric(x))
}
pick <- function(df, cands) {
  nm <- names(df)
  for (c in cands) if (c %in% nm) return(c)
  lw <- tolower(nm)
  for (c in cands) { i <- which(lw == tolower(c)); if (length(i)) return(nm[i[1]]) }
  NA_character_
}
diag_names <- function(label, df) {
  cat(sprintf("[diag] %s: %d rows, %d cols\n", label, nrow(df), ncol(df)))
  cat("[diag]   first names:", paste(head(names(df), 60), collapse = ", "), "\n")
}
to_stata_day <- function(x) {
  if (inherits(x, "POSIXt")) return(as.numeric(as.Date(x)) + 3653)
  if (inherits(x, "Date")) return(as.numeric(x) + 3653)
  if (is.character(x)) {
    d <- suppressWarnings(as.Date(substr(x, 1, 10)))
    if (mean(is.na(d)) > 0.9) d <- suppressWarnings(as.Date(x, format = "%d%b%Y"))
    return(as.numeric(d) + 3653)
  }
  v <- num(x)
  med <- suppressWarnings(median(v, na.rm = TRUE))
  if (is.finite(med) && med > 1e9) v <- floor(v / 86400000)   # Stata %tc clock
  v
}
cut_icodes <- function(x, br) {
  out <- findInterval(x, br) - 1
  out[is.na(x) | x < br[1] | x >= br[length(br)]] <- NA
  out
}
results <- list()
put <- function(name, val) results[[name]] <<- val
safe <- function(expr, label) tryCatch(expr, error = function(e) {
  cat(sprintf("[warn] %s failed: %s\n", label, conditionMessage(e))); NULL })
getb <- function(m, v) if (is.null(m)) NA_real_ else unname(coef(m)[v])

# ---------------------------------------------------------------------------
# 1. Analysis data: use the clean combined file if present, else rebuild it
# ---------------------------------------------------------------------------
ad_path <- list.files(root, pattern = "^analysis_data\\.dta$", recursive = TRUE, full.names = TRUE)
if (length(ad_path) > 0) {
  cat("[diag] using", ad_path[1], "\n")
  ad <- read_dta(ad_path[1])
  ad <- as.data.frame(ad)
  for (v in names(ad)) if (inherits(ad[[v]], "haven_labelled")) ad[[v]] <- zap_labels(ad[[v]])
  ad$today_alt <- to_stata_day(ad$today_alt)
} else {
  cat("[diag] analysis_data.dta not found; rebuilding from 01_base\n")
  reg <- as.data.frame(read_dta(file.path(adm, "registration_noPII.dta")))
  diag_names("registration", reg)
  print(names(reg))
  k_reg <- pick(reg, c("compound1", "compound_code", "compound"))
  ad <- data.frame(compound1 = num(reg[[k_reg]]))
  ad$a7 <- num(reg[[pick(reg, c("a7", "polygon", "poly"))]])
  for (v in c("house", "exempt", "pilot", "rate", "stratum", "tmt", "present_sensi", "status")) {
    if (v %in% names(reg)) ad[[v]] <- num(reg[[v]])
  }
  # date of the registration / campaign visit
  dcands <- c("today_alt", "today_carto", "today", "date_carto", "date", "submissiondate", "starttime", "time")
  dcands <- c(dcands, grep("^today|date", names(reg), value = TRUE))
  ad$today_alt <- NA_real_
  for (dc in unique(dcands)) {
    if (!(dc %in% names(reg))) next
    v <- safe(to_stata_day(reg[[dc]]), paste("date", dc))
    if (is.null(v)) next
    med <- suppressWarnings(median(v, na.rm = TRUE))
    cat(sprintf("[diag] date candidate %s: median %s, NA share %.3f\n", dc, med, mean(is.na(v))))
    if (is.finite(med) && med > 21300 && med < 21700) { ad$today_alt <- v; cat("[diag] using date", dc, "\n"); break }
  }

  # treatment and stratum from randomization file (unless registration has them)
  ra <- as.data.frame(read_dta(file.path(adm, "randomization_assignment.dta")))
  diag_names("randomization_assignment", ra)
  map_tmt <- function(x) {
    if (is.numeric(x) && !inherits(x, "haven_labelled")) return(num(x))
    lab <- tolower(as.character(as_factor(x)))
    out <- rep(NA_real_, length(lab))
    out[grepl("control|declar", lab)] <- 0
    is_cli <- grepl("info|cli", lab) & is.na(out)
    out[is_cli] <- 3
    is_cxl <- (grepl("cxl|x local|central x|times", lab) | (grepl("central", lab) & grepl("local", lab))) & is.na(out)
    out[is_cxl] <- 4
    out[grepl("local", lab) & is.na(out)] <- 2
    out[grepl("central", lab) & is.na(out)] <- 1
    if (all(is.na(out))) out <- num(x)
    out
  }
  tcol <- pick(ra, c("tmt", "treatment_final", "treatment"))
  print(table(as.character(as_factor(ra[[tcol]])), useNA = "ifany"))
  ra2 <- data.frame(a7 = num(ra$a7), tmt_ra = map_tmt(ra[[tcol]]), stratum_ra = num(ra$stratum))
  ra2 <- ra2[!duplicated(ra2$a7), ]
  ad <- left_join(ad, ra2, by = "a7")
  if (!("tmt" %in% names(ad)) || all(is.na(ad$tmt))) ad$tmt <- ad$tmt_ra
  if (!("stratum" %in% names(ad)) || all(is.na(ad$stratum))) ad$stratum <- ad$stratum_ra
  cat("[diag] unmatched a7 in registration:", paste(head(unique(ad$a7[is.na(ad$tmt_ra)]), 30), collapse = ","), "\n")

  # payments
  tp <- as.data.frame(read_dta(file.path(adm, "tax_payments_noPII.dta")))
  diag_names("tax_payments", tp)
  print(names(tp))
  k_tp <- pick(tp, c("compound1", "compound_code", "compound"))
  a_tp <- pick(tp, c("amount", "amt_paid", "amt", "paid_amt", "taxes_paid_amt", "montant", "amount_paid"))
  if (!is.na(k_tp)) {
    tp2 <- data.frame(compound1 = num(tp[[k_tp]]),
                      amt = if (!is.na(a_tp)) num(tp[[a_tp]]) else 1)
    tp2 <- tp2[!is.na(tp2$compound1), ]
    tpa <- tp2 %>% group_by(compound1) %>% summarise(taxes_paid_amt = sum(amt, na.rm = TRUE), .groups = "drop")
    ad <- left_join(ad, tpa, by = "compound1")
    ad$taxes_paid <- as.numeric(!is.na(ad$taxes_paid_amt))
    ad$taxes_paid_amt[is.na(ad$taxes_paid_amt)] <- 0
  } else {
    ap <- num(reg[[pick(reg, c("amt_paid"))]])
    ad$taxes_paid_amt <- ifelse(is.na(ap), 0, ap)
    ad$taxes_paid <- as.numeric(ad$taxes_paid_amt > 0)
  }

  # midline survey (visits)
  ml <- as.data.frame(read_dta(file.path(srv, "midline_noPII.dta")))
  diag_names("midline", ml)
  k_ml <- pick(ml, c("compound1", "compound", "compound_code"))
  if ("tot_complete" %in% names(ml)) ml <- ml[num(ml$tot_complete) %in% 1, ]
  mlk <- data.frame(compound1 = num(ml[[k_ml]]))
  for (v in c("visited", "visits", "bribe", "paid_self", "salongo")) if (v %in% names(ml)) mlk[[v]] <- num(ml[[v]])
  mlk <- mlk[!is.na(mlk$compound1) & !duplicated(mlk$compound1), ]
  ad <- left_join(ad, mlk, by = "compound1")

  # sample restrictions
  ad <- ad[!(ad$pilot %in% 1), ]
  ad <- ad[!(ad$house %in% 3), ]
  ad <- ad[!(!is.na(ad$a7) & ad$a7 > 400 & ad$a7 < 500), ]
  ad <- ad[!(ad$a7 %in% c(200, 201, 202, 203, 207, 208, 210)), ]
  ad <- ad[!is.na(ad$compound1) & !duplicated(ad$compound1), ]
}

ad$t_c   <- as.numeric(ad$tmt %in% 1)
ad$t_l   <- as.numeric(ad$tmt %in% 2)
ad$t_cli <- as.numeric(ad$tmt %in% 3)
cat("[diag] tmt counts:\n"); print(table(ad$tmt, useNA = "ifany"))
cat("[diag] today_alt range:", range(ad$today_alt, na.rm = TRUE), "\n")

# visit variables
if (all(c("visited", "visits") %in% names(ad))) {
  vd <- ad$visited; vs <- ad$visits
  ad$visit_post_carto <- ifelse(vd %in% 0 | (!is.na(vs) & vs != 0), 0, NA)
  ad$visit_post_carto[!is.na(vs) & vs > 1] <- 1
}

ad$tfe_CvL    <- cut_icodes(ad$today_alt, c(21355, 21415, 21475, 21532))
ad$tfe_CvL6   <- cut_icodes(ad$today_alt, c(21355, 21415, 21475, 21529))
ad$tfe_CvCLI  <- cut_icodes(ad$today_alt, c(21365.5, 21425.5, 21485.5, 21519))

ctrl <- list(cluster = ~a7, fixef.rm = "none", ssc = ssc(adj = TRUE, fixef.K = "full", cluster.adj = TRUE))
fe <- function(fml, data) safe(do.call(feols, c(list(fml = fml, data = data), ctrl)), deparse(fml))

cl <- ad[ad$tmt %in% c(1, 2), ]
cl$exempt_ok <- if ("exempt" %in% names(cl)) (is.na(cl$exempt) | cl$exempt != 1) else rep(TRUE, nrow(cl))

# ---------------------------------------------------------------------------
# Table 4
# ---------------------------------------------------------------------------
m1 <- fe(taxes_paid ~ t_l | stratum, cl)
m2 <- fe(taxes_paid ~ t_l | stratum + tfe_CvL, cl)
m4 <- fe(taxes_paid ~ t_l | stratum + house + tfe_CvL, cl)
m5 <- fe(taxes_paid ~ t_l | stratum + house + tfe_CvL, cl[cl$exempt_ok, ])
r2 <- fe(taxes_paid_amt ~ t_l | stratum + tfe_CvL, cl)
r4 <- fe(taxes_paid_amt ~ t_l | stratum + house + tfe_CvL, cl)

put("compliance_local_table4_panelA_col1", getb(m1, "t_l"))
put("compliance_local_table4_panelA_col2", getb(m2, "t_l"))
put("compliance_local_house_fe_table4_panelA_col4", getb(m4, "t_l"))
put("compliance_local_exempt_excluded_table4_panelA_col5", getb(m5, "t_l"))
put("revenue_local_table4_panelB_col2", getb(r2, "t_l"))
put("revenue_local_house_fe_table4_panelB_col4", getb(r4, "t_l"))
put("n_obs_table4_col1", if (is.null(m1)) NA else nobs(m1))
put("n_obs_table4_col2", if (is.null(m2)) NA else nobs(m2))

# ---------------------------------------------------------------------------
# Table 5, Panel B: paid bribe (endline)
# ---------------------------------------------------------------------------
el_raw <- safe(as.data.frame(read_dta(file.path(srv, "endline_round1_noPII.dta"))), "read endline")
if (!is.null(el_raw)) {
  el <- el_raw[num(el_raw$tot_complete) %in% 1, ]
  b <- num(el$bribe)
  for (v in c("bribe2a", "bribe2b", "bribe3")) if (v %in% names(el)) b <- ifelse(is.na(b), num(el[[v]]), b)
  tm <- ad %>% filter(!is.na(a7)) %>% group_by(a7) %>%
    summarise(treatment = suppressWarnings(max(tmt, na.rm = TRUE)),
              stratum = suppressWarnings(max(stratum, na.rm = TRUE)), .groups = "drop")
  tm$treatment[!is.finite(tm$treatment)] <- NA
  tm$stratum[!is.finite(tm$stratum)] <- NA
  eb <- data.frame(a7 = num(el$a7), bribe_endline = b)
  eb <- inner_join(eb, tm, by = "a7")
  eb$t_l <- as.numeric(eb$treatment %in% 2)
  eb <- eb[eb$treatment %in% c(1, 2), ]
  mb <- fe(bribe_endline ~ t_l | stratum, eb)
  put("paid_bribe_endline_local_table5_panelB", getb(mb, "t_l"))
} else put("paid_bribe_endline_local_table5_panelB", NA)

# ---------------------------------------------------------------------------
# Table 6: visited by collector (cut points as in Table6.do)
# ---------------------------------------------------------------------------
if ("visit_post_carto" %in% names(cl)) {
  mv <- fe(visit_post_carto ~ t_l | house + stratum + tfe_CvL6, cl)
  put("visited_by_collector_local_table6_col1", getb(mv, "t_l"))
} else put("visited_by_collector_local_table6_col1", NA)

# ---------------------------------------------------------------------------
# Table 7: CLI vs Central
# ---------------------------------------------------------------------------
ccli <- ad[ad$tmt %in% c(1, 3), ]
m7a <- fe(taxes_paid ~ t_cli | house + stratum + tfe_CvCLI, ccli)
m7b <- fe(taxes_paid_amt ~ t_cli | house + stratum + tfe_CvCLI, ccli)
put("compliance_cli_table7_col1", getb(m7a, "t_cli"))
put("revenue_cli_table7_col2", getb(m7b, "t_cli"))

# ---------------------------------------------------------------------------
# Table 8, Panel A col 2: ease of payment within CLI
# (analysis data merged 1:m with endline respondents by compound code, then consultations)
# ---------------------------------------------------------------------------
t8 <- safe({
  cons <- as.data.frame(read_dta(file.path(srv, "chief_consultations.dta")))
  cons2 <- data.frame(compound1 = num(cons$compound1), pay_ease = num(cons$pay_ease))
  cons2 <- cons2[!is.na(cons2$compound1) & !duplicated(cons2$compound1), ]
  d8 <- ad[ad$tmt %in% c(1, 2, 3), c("compound1", "a7", "tmt", "t_cli", "house", "stratum", "taxes_paid")]
  if (!is.null(el_raw)) {
    e <- el_raw[num(el_raw$tot_complete) %in% 1, ]
    cc <- num(e$compound_code)
    if ("compound_code_prev" %in% names(e) && "move" %in% names(e)) {
      mv_ <- num(e$move)
      cc <- ifelse(mv_ %in% c(1, 2), num(e$compound_code_prev), cc)
    }
    cc[cc %in% c(99999, 9999999)] <- 999999
    cc <- cc[!is.na(cc) & cc != 999999]
    ecount <- as.data.frame(table(cc), stringsAsFactors = FALSE)
    names(ecount) <- c("compound1", "n_el")
    ecount$compound1 <- as.numeric(ecount$compound1)
    d8 <- left_join(d8, ecount, by = "compound1")
    d8$n_el[is.na(d8$n_el)] <- 1
    d8 <- d8[rep(seq_len(nrow(d8)), d8$n_el), ]
  }
  d8 <- left_join(d8, cons2, by = "compound1")
  d8 <- d8[d8$t_cli == 1, ]
  fe(taxes_paid ~ pay_ease | house + stratum, d8)
}, "table8")
put("compliance_ease_of_payment_cli_table8_panelA_col2", getb(t8, "pay_ease"))

# ---------------------------------------------------------------------------
for (nm in names(results)) {
  v <- results[[nm]]
  cat(sprintf("RESULT:%s=%s\n", nm, ifelse(is.null(v) || is.na(v), "NA", format(signif(v, 8), scientific = FALSE))))
}