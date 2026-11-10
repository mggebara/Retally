suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)
options(width = 200, warn = 1)

root <- "<repo>/.cache/datasets/balan_2022_local_elites_state_capacity.script-free/Replication Materials - Updated October 2025/Data/01_base"
adm <- file.path(root, "admin_data")
srv <- file.path(root, "survey_data")

rd <- function(p) {
  tryCatch(haven::read_dta(p), error = function(e) {
    cat("ERROR reading", p, ":", conditionMessage(e), "\n"); NULL
  })
}
findcol <- function(d, cands) {
  if (is.null(d)) return(NA_character_)
  n <- names(d)
  for (cc in cands) {
    hit <- n[tolower(n) == tolower(cc)]
    if (length(hit)) return(hit[1])
  }
  NA_character_
}
mkkey <- function(x) {
  x <- haven::zap_labels(x)
  if (is.numeric(x)) {
    out <- ifelse(is.na(x), NA_character_, format(x, scientific = FALSE, trim = TRUE, digits = 15))
  } else {
    out <- toupper(trimws(as.character(x)))
    out[out == ""] <- NA_character_
  }
  out
}
num01 <- function(x) {
  v <- suppressWarnings(as.numeric(haven::zap_labels(x)))
  v[!is.na(v) & v < 0] <- NA
  u <- sort(unique(v[!is.na(v)]))
  if (length(u) && all(u %in% c(0, 1))) return(v)
  if (length(u) && all(u %in% c(1, 2))) return(ifelse(v == 1, 1, 0))
  v[!is.na(v) & v > 1] <- NA
  v
}
to_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  if (is.numeric(x)) {
    x <- haven::zap_labels(x)
    if (all(is.na(x))) return(as.Date(rep(NA, length(x))))
    if (median(x, na.rm = TRUE) > 1e9) return(as.Date(as.POSIXct(x / 1000, origin = "1960-01-01", tz = "UTC")))
    return(as.Date(x, origin = "1960-01-01"))
  }
  suppressWarnings(as.Date(as.character(x)))
}
parse_any_date <- function(x) {
  if (inherits(x, "Date") || inherits(x, "POSIXt") || is.numeric(x)) {
    return(tryCatch(to_date(x), error = function(e) NULL))
  }
  s <- as.character(x)
  s[!is.na(s) & trimws(s) == ""] <- NA
  out <- tryCatch(suppressWarnings(as.Date(lubridate::parse_date_time(s,
           orders = c("ymd HMS", "ymd HM", "ymd", "dmy HMS", "dmy HM", "dmy", "mdy HMS", "mdy HM", "mdy",
                      "b d, Y I:M:S p", "b d Y", "d b Y"), quiet = TRUE))), error = function(e) NULL)
  out
}
pick_date <- function(d, cands) {
  best <- NULL; bestn <- 0; bestc <- NA_character_
  if (is.null(d)) return(list(date = NULL, col = NA_character_))
  for (cc in cands) {
    c1 <- findcol(d, cc); if (is.na(c1)) next
    dd <- parse_any_date(d[[c1]])
    if (is.null(dd) || length(dd) != nrow(d)) next
    ok <- !is.na(dd) & dd >= as.Date("2017-06-01") & dd <= as.Date("2020-01-01")
    dd[!ok] <- NA
    cat("date candidate", c1, ": valid share", round(mean(ok), 3), "\n")
    if (sum(ok) > bestn) { best <- dd; bestn <- sum(ok); bestc <- c1 }
  }
  list(date = best, col = bestc)
}
classify <- function(x) {
  lab <- NULL
  if (haven::is.labelled(x)) lab <- tolower(as.character(haven::as_factor(x, levels = "labels")))
  else if (is.factor(x) || is.character(x)) lab <- tolower(as.character(x))
  if (!is.null(lab)) {
    out <- ifelse(grepl("cli|info", lab), "CLI",
           ifelse(grepl("cxl|cx l| x |times", lab), "CXL",
           ifelse(grepl("control|declar|pure", lab), "Control",
           ifelse(grepl("local|chief|chef", lab), "Local",
           ifelse(grepl("central|state", lab), "Central", NA_character_)))))
    if (mean(!is.na(out[!is.na(lab)])) > 0.9) return(out)
  }
  v <- suppressWarnings(as.numeric(haven::zap_labels(x)))
  map <- c("0" = "Control", "1" = "Central", "2" = "Local", "3" = "CLI", "4" = "CXL", "5" = "Control")
  unname(map[as.character(v)])
}
showd <- function(nm, d) {
  if (is.null(d)) { cat(nm, ": NULL\n"); return(invisible()) }
  cat("\n==", nm, ":", nrow(d), "rows,", ncol(d), "cols\n")
  cat(head(names(d), 150), "\n")
}

results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) results[[name]] <<- val
}
safe <- function(label, expr) {
  tryCatch(expr, error = function(e) { cat("ERROR in", label, ":", conditionMessage(e), "\n"); NULL })
}

# ------------------------------------------------------------------ neighborhoods
nb <- rd(file.path(adm, "tax_payments_neighborhoods.dta"))
ra <- rd(file.path(adm, "randomization_assignment.dta"))
showd("tax_payments_neighborhoods", nb)
showd("randomization_assignment", ra)

nbc <- findcol(nb, c("a7"))
nbinfo <- data.frame(a7 = mkkey(nb[[nbc]]), stringsAsFactors = FALSE)
prog_col <- findcol(nb, c("program", "treatment", "tmt"))
nbinfo$program <- suppressWarnings(as.numeric(haven::zap_labels(nb[[prog_col]])))
nbinfo$arm <- classify(nb[[prog_col]])
nbinfo$stratum <- as.character(haven::zap_labels(nb[[findcol(nb, c("stratum"))]]))
ps_col <- findcol(nb, c("program_start", "start_date", "start"))
nbinfo$pstart <- if (!is.na(ps_col)) to_date(nb[[ps_col]]) else as.Date(NA)
cat("Program variable:", prog_col, "\n"); print(table(nb[[prog_col]], nbinfo$arm, useNA = "ifany"))
if (!is.null(ra)) {
  rac <- findcol(ra, c("a7"))
  rtc <- findcol(ra, c("treatment", "tmt"))
  if (!is.na(rac) && !is.na(rtc)) {
    cat("Randomization treatment variable:\n"); print(table(haven::as_factor(ra[[rtc]]), useNA = "ifany"))
    rr <- data.frame(a7 = mkkey(ra[[rac]]), arm_ra = classify(ra[[rtc]]), stringsAsFactors = FALSE)
    tmp <- merge(nbinfo, rr, by = "a7", all.x = TRUE)
    cat("program (de facto) vs assignment:\n"); print(table(tmp$arm, tmp$arm_ra, useNA = "ifany"))
    # 'program' in the neighborhoods file is a 0/1 indicator (program implemented), not the
    # treatment arm. Use the randomized assignment (5 arms) whenever it carries more arm information.
    n_arm_nb <- length(unique(na.omit(nbinfo$arm)))
    n_arm_ra <- length(unique(na.omit(rr$arm_ra)))
    if (all(is.na(nbinfo$arm)) || n_arm_ra > n_arm_nb) {
      nbinfo$arm <- rr$arm_ra[match(nbinfo$a7, rr$a7)]
      cat("Using randomization_assignment treatment as arm.\n")
    }
    if (all(is.na(nbinfo$stratum))) {
      rsc <- findcol(ra, c("stratum"))
      nbinfo$stratum <- as.character(haven::zap_labels(ra[[rsc]]))[match(nbinfo$a7, rr$a7)]
    }
  }
}
cat("Neighborhood counts by arm:\n"); print(table(nbinfo$arm, useNA = "ifany"))
cat("Arm by program indicator:\n"); print(table(nbinfo$arm, nbinfo$program, useNA = "ifany"))
cat("Arm by program_start available:\n"); print(table(nbinfo$arm, !is.na(nbinfo$pstart), useNA = "ifany"))

# ------------------------------------------------------------------ properties
reg <- rd(file.path(adm, "registration_noPII.dta"))
tr <- rd(file.path(adm, "taxroll_noPII.dta"))
tp <- rd(file.path(adm, "tax_payments_noPII.dta"))
showd("registration", reg); showd("taxroll", tr); showd("tax_payments", tp)

idc_cands <- c("compound1", "compound_code", "compound", "code", "property_id", "hhid")
nbc_cands <- c("a7", "polygon", "neighborhood")
paid_cands <- c("taxes_paid", "paid", "tax_paid", "compliance", "paid_tax")
amt_cands <- c("taxes_paid_amt", "amount", "amt_paid", "tax_amt", "amount_paid", "revenue", "amountcf")

base_src <- NULL
if (!is.null(tr) && !is.na(findcol(tr, nbc_cands)) && !is.na(findcol(tr, idc_cands))) base_src <- "taxroll"
if (is.null(base_src)) base_src <- "registration"
B0 <- if (base_src == "taxroll") tr else reg
cat("Base source:", base_src, "\n")
b_id <- findcol(B0, idc_cands); b_nb <- findcol(B0, nbc_cands)
base <- data.frame(id = mkkey(B0[[b_id]]), a7 = mkkey(B0[[b_nb]]), stringsAsFactors = FALSE)

# house, exempt, pilot from base or registration
r_id <- findcol(reg, idc_cands)
pull_var <- function(cands) {
  c1 <- findcol(B0, cands)
  if (!is.na(c1)) return(B0[[c1]])
  c2 <- findcol(reg, cands)
  if (!is.na(c2) && !is.na(r_id)) {
    rk <- mkkey(reg[[r_id]])
    return(reg[[c2]][match(base$id, rk)])
  }
  rep(NA, nrow(base))
}
house_raw <- pull_var(c("house", "house_type", "property_type"))
base$house <- suppressWarnings(as.numeric(haven::zap_labels(house_raw)))
base$exempt <- num01(pull_var(c("exempt")))
base$pilot <- num01(pull_var(c("pilot")))
cat("house table:\n"); print(table(haven::as_factor(house_raw), useNA = "ifany"))
cat("exempt table:\n"); print(table(base$exempt, useNA = "ifany"))
cat("pilot table:\n"); print(table(base$pilot, useNA = "ifany"))

# villa exclusion
villa <- rep(FALSE, nrow(base))
if (haven::is.labelled(house_raw)) {
  hl <- tolower(as.character(haven::as_factor(house_raw, levels = "labels")))
  villa <- !is.na(hl) & grepl("villa", hl)
}
if (!any(villa)) {
  u <- sort(unique(base$house[!is.na(base$house)]))
  if (length(u) == 3 && sum(base$house == max(u), na.rm = TRUE) < 1500) villa <- !is.na(base$house) & base$house == max(u)
}
cat("Villas flagged:", sum(villa), "\n")

# payments
pc <- findcol(B0, paid_cands); ac <- findcol(B0, amt_cands)
cat("Base paid column:", pc, " base amount column:", ac, "\n")
if (!is.na(pc)) {
  base$paid <- num01(B0[[pc]]); base$paid[is.na(base$paid)] <- 0
} else base$paid <- NA_real_
if (!is.na(ac)) {
  base$amt <- suppressWarnings(as.numeric(haven::zap_labels(B0[[ac]]))); base$amt[is.na(base$amt)] <- 0
} else base$amt <- NA_real_
if ((all(is.na(base$paid)) || all(is.na(base$amt))) && !is.null(tp)) {
  t_id <- findcol(tp, idc_cands)
  t_amt <- findcol(tp, amt_cands)
  cat("Using tax_payments file; id:", t_id, " amount:", t_amt, "\n")
  tk <- mkkey(tp[[t_id]])
  ta <- if (!is.na(t_amt)) suppressWarnings(as.numeric(haven::zap_labels(tp[[t_amt]]))) else rep(1, length(tk))
  ta[is.na(ta)] <- 0
  agg <- tapply(ta, tk, sum)
  inpay <- base$id %in% names(agg)
  if (all(is.na(base$paid))) base$paid <- as.numeric(inpay)
  if (all(is.na(base$amt))) { base$amt <- 0; base$amt[inpay] <- agg[base$id[inpay]] }
}
# Revenue is the amount actually paid: the amount column may hold the assessed liability
# for every property, so revenue must be zero for non-payers.
cat("Share of non-payers with positive amount (before fix):",
    mean(base$amt[!is.na(base$paid) & base$paid == 0] > 0, na.rm = TRUE), "\n")
base$amt[!is.na(base$paid) & base$paid == 0] <- 0
cat("Amount among payers (quantiles):\n")
print(quantile(base$amt[!is.na(base$paid) & base$paid == 1], c(0, .1, .25, .5, .75, .9, .99, 1), na.rm = TRUE))
cat("paid summary:\n"); print(summary(base$paid)); cat("amt summary:\n"); print(summary(base$amt))

# dedupe and restrict
base <- base[!is.na(base$id), ]
base <- base[!duplicated(base$id), ]
base$villa <- FALSE
base$villa <- villa[match(base$id, mkkey(B0[[b_id]]))]
base <- base[is.na(base$pilot) | base$pilot != 1, ]
base <- base[!base$villa %in% TRUE, ]
base <- merge(base, nbinfo, by = "a7")
cat("Properties by arm:\n"); print(table(base$arm, useNA = "ifany"))

# ------------------------------------------------------------------ property-level campaign dates
rdi <- pick_date(reg, c("today", "date", "today_fr", "date_f", "start", "end"))
cat("Registration date column:", rdi$col, "\n")
base$rdate <- as.Date(NA)
if (!is.null(rdi$date) && !is.na(r_id)) {
  rk <- mkkey(reg[[r_id]])
  dn <- as.numeric(rdi$date)
  okk <- !is.na(rk) & !is.na(dn)
  if (any(okk)) {
    mn <- tapply(dn[okk], rk[okk], min)
    base$rdate <- as.Date(unname(mn[base$id]), origin = "1970-01-01")
  }
}
cat("Share of properties with registration date:", mean(!is.na(base$rdate)), "\n")
print(table(format(base$rdate, "%Y-%m"), base$arm, useNA = "ifany"))

# time FE construction (fallback: neighborhood program start dates)
make_periods <- function(d, armA, armB = "Central") {
  ni <- nbinfo[nbinfo$arm %in% c(armA, armB) & !is.na(nbinfo$pstart), ]
  if (!any(ni$arm == armA) || !any(ni$arm == armB)) {
    cat("No program start dates for", armA, "and/or", armB, "; periods set to NA\n")
    return(rep(NA_real_, nrow(d)))
  }
  fA <- min(ni$pstart[ni$arm == armA]); fB <- min(ni$pstart[ni$arm == armB])
  lA <- max(ni$pstart[ni$arm == armA]); lB <- max(ni$pstart[ni$arm == armB])
  st <- as.Date(floor((as.numeric(fA) + as.numeric(fB)) / 2), origin = "1970-01-01")
  en <- as.Date(floor((as.numeric(lA) + as.numeric(lB)) / 2), origin = "1970-01-01")
  cat("Periods for", armA, "vs", armB, ":", format(st), "to", format(en), "\n")
  br <- seq(st, en + 70, by = "2 months")
  inwin <- !is.na(d$pstart) & d$pstart >= st & d$pstart <= en
  per <- ifelse(inwin, findInterval(as.numeric(d$pstart), as.numeric(br)), NA)
  per
}
# Campaign-wave periods from each property's own registration (door-to-door) date:
# two-month bins from the start of the campaign, keeping bins where both arms operated.
make_periods_prop <- function(d, treat, armA) {
  if (mean(!is.na(d$rdate)) < 0.5) {
    cat("Too few property dates; falling back to neighborhood program_start periods\n")
    return(make_periods(d, armA))
  }
  t0 <- min(d$rdate, na.rm = TRUE)
  per <- floor(as.numeric(d$rdate - t0) / 61)
  tab <- table(per, d[[treat]])
  if (!all(c("0", "1") %in% colnames(tab))) return(per)
  okp <- as.numeric(rownames(tab)[tab[, "0"] > 0 & tab[, "1"] > 0])
  cat("Periods (2-month bins) by treatment:\n"); print(tab)
  per[!per %in% okp] <- NA
  per
}
cat("DEVIATION: Campaign-wave time FE built as two-month bins of each property's registration date (common support across arms), since neighborhood program_start is missing for ~40% of neighborhoods\n")
cat("DEVIATION: Revenue set to zero for properties that did not pay (amount column may record assessed liability)\n")

LC <- base[base$arm %in% c("Local", "Central"), ]
LC$local <- as.numeric(LC$arm == "Local")
LC$per <- make_periods_prop(LC, "local", "Local")
cat("LC N:", nrow(LC), " with period:", sum(!is.na(LC$per)), "\n"); print(table(LC$per, LC$arm, useNA = "ifany"))
LCt <- LC[!is.na(LC$per), ]
LCh <- LCt[!is.na(LCt$house), ]

getc <- function(m, v) unname(coef(m)[v])

safe("col1", {
  m <- feols(paid ~ local | stratum, data = LC, cluster = ~a7)
  print(summary(m))
  emit("compliance_local_table4_panelA_col1", getc(m, "local"))
  emit("n_obs_table4_col1", nobs(m))
})
safe("col2", {
  m <- feols(paid ~ local | stratum + per, data = LCt, cluster = ~a7)
  print(summary(m))
  emit("compliance_local_table4_panelA_col2", getc(m, "local"))
  emit("n_obs_table4_col2", nobs(m))
  m2 <- feols(amt ~ local | stratum + per, data = LCt, cluster = ~a7)
  print(summary(m2))
  emit("revenue_local_table4_panelB_col2", getc(m2, "local"))
})
safe("col4", {
  m <- feols(paid ~ local | stratum + per + house, data = LCh, cluster = ~a7)
  print(summary(m))
  emit("compliance_local_house_fe_table4_panelA_col4", getc(m, "local"))
  m2 <- feols(amt ~ local | stratum + per + house, data = LCh, cluster = ~a7)
  print(summary(m2))
  emit("revenue_local_house_fe_table4_panelB_col4", getc(m2, "local"))
})
safe("col5", {
  d5 <- LCh[is.na(LCh$exempt) | LCh$exempt != 1, ]
  m <- feols(paid ~ local | stratum + per + house, data = d5, cluster = ~a7)
  print(summary(m))
  emit("compliance_local_exempt_excluded_table4_panelA_col5", getc(m, "local"))
})

# ------------------------------------------------------------------ Table 7: CLI vs Central
CC <- base[base$arm %in% c("CLI", "Central"), ]
CC$cli <- as.numeric(CC$arm == "CLI")
safe("table7", {
  CC$per <- make_periods_prop(CC, "cli", "CLI")
  CCt <- CC[!is.na(CC$per) & !is.na(CC$house), ]
  m <- feols(paid ~ cli | stratum + per + house, data = CCt, cluster = ~a7)
  print(summary(m))
  emit("compliance_cli_table7_col1", getc(m, "cli"))
  m2 <- feols(amt ~ cli | stratum + per + house, data = CCt, cluster = ~a7)
  print(summary(m2))
  emit("revenue_cli_table7_col2", getc(m2, "cli"))
})

# ------------------------------------------------------------------ Table 6: visits (midline)
safe("table6", {
  mid <- rd(file.path(srv, "midline_noPII.dta"))
  showd("midline", mid)
  m_id <- findcol(mid, idc_cands)
  vc <- findcol(mid, c("visit_post_carto", "visited_post", "visit_post", "visited_post_carto", "visited"))
  cat("midline id:", m_id, " visit var:", vc, "\n"); print(table(mid[[vc]], useNA = "ifany"))
  md <- data.frame(id = if (!is.na(m_id)) mkkey(mid[[m_id]]) else NA_character_,
                   visited = num01(mid[[vc]]), stringsAsFactors = FALSE)
  md <- md[!is.na(md$visited), ]
  ov <- mean(md$id %in% LCh$id)
  cat("midline id overlap with base:", ov, "\n")
  if (!is.na(ov) && ov > 0.3) {
    md <- md[!duplicated(md$id), ]
    d6 <- merge(md, LCh[, c("id", "a7", "local", "stratum", "per", "house")], by = "id")
  } else {
    m_nb <- findcol(mid, nbc_cands); m_h <- findcol(mid, c("house"))
    md <- data.frame(a7 = mkkey(mid[[m_nb]]), visited = num01(mid[[vc]]),
                     house = if (!is.na(m_h)) as.numeric(haven::zap_labels(mid[[m_h]])) else 1,
                     stringsAsFactors = FALSE)
    nbp <- LCt[!duplicated(LCt$a7), c("a7", "local", "stratum", "per")]
    d6 <- merge(md[!is.na(md$visited), ], nbp, by = "a7")
  }
  m <- feols(visited ~ local | stratum + per + house, data = d6, cluster = ~a7)
  print(summary(m))
  emit("visited_by_collector_local_table6_col1", getc(m, "local"))
})

# ------------------------------------------------------------------ Table 5: bribe (endline)
safe("table5", {
  en <- rd(file.path(srv, "endline_round1_noPII.dta"))
  showd("endline_round1", en)
  e_nb <- findcol(en, nbc_cands)
  bc <- findcol(en, c("bribe", "paid_bribe", "bribe_self", "transport"))
  cat("endline nb:", e_nb, " bribe var:", bc, "\n"); print(table(en[[bc]], useNA = "ifany"))
  ed <- data.frame(bribe = num01(en[[bc]]), stringsAsFactors = FALSE)
  if (!is.na(e_nb)) ed$a7 <- mkkey(en[[e_nb]]) else {
    e_id <- findcol(en, idc_cands)
    ed$a7 <- base$a7[match(mkkey(en[[e_id]]), base$id)]
  }
  ed <- merge(ed[!is.na(ed$bribe), ], nbinfo[nbinfo$arm %in% c("Local", "Central"), c("a7", "arm", "stratum")], by = "a7")
  ed$local <- as.numeric(ed$arm == "Local")
  m <- feols(bribe ~ local | stratum, data = ed, cluster = ~a7)
  print(summary(m))
  emit("paid_bribe_endline_local_table5_panelB", getc(m, "local"))
})

# ------------------------------------------------------------------ Table 8: ease of payment (CLI)
safe("table8", {
  ch <- rd(file.path(srv, "chief_consultations.dta"))
  showd("chief_consultations", ch)
  rc <- findcol(ch, c("pay_ease", "ease_pay", "ease_payment", "ease_of_payment", "ability_pay", "ability_to_pay", "ability"))
  if (is.na(rc)) {
    g <- grep("ease|abil", names(ch), value = TRUE, ignore.case = TRUE)
    cat("candidate rating vars:", g, "\n")
    rc <- g[1]
  }
  c_id <- findcol(ch, idc_cands)
  cat("chief id:", c_id, " rating:", rc, "\n"); print(table(ch[[rc]], useNA = "ifany"))
  rv <- suppressWarnings(as.numeric(haven::zap_labels(ch[[rc]])))
  rv[!is.na(rv) & (rv < 1 | rv > 3)] <- NA
  cd <- data.frame(id = mkkey(ch[[c_id]]), ease = rv, stringsAsFactors = FALSE)
  cd <- cd[!is.na(cd$id) & !is.na(cd$ease) & !duplicated(cd$id), ]
  d8 <- merge(cd, base[base$arm == "CLI" & !is.na(base$house), ], by = "id")
  cat("Table 8 N:", nrow(d8), "\n")
  m <- feols(paid ~ ease | house + stratum, data = d8, cluster = ~a7)
  print(summary(m))
  emit("compliance_ease_of_payment_cli_table8_panelA_col2", getc(m, "ease"))
})

cat("\n")
for (nm in names(results)) cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
