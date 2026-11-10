suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)
options(warn = 1)

ROOT <- file.path("<repo>/.cache/datasets/balan_2022_local_elites_state_capacity",
                  "Replication Materials - Updated October 2025")
DATA <- file.path(ROOT, "Data")
f_analysis <- file.path(DATA, "03_clean_combined", "analysis_data.dta")
f_reg      <- file.path(DATA, "01_base", "admin_data", "registration_noPII.dta")
f_taxroll  <- file.path(DATA, "01_base", "admin_data", "taxroll_noPII.dta")
f_pay      <- file.path(DATA, "01_base", "admin_data", "tax_payments_noPII.dta")
f_paytime  <- file.path(DATA, "01_base", "admin_data", "tax_payment_timing_noPII.dta")
f_rand     <- file.path(DATA, "01_base", "admin_data", "randomization_assignment.dta")
f_midline  <- file.path(DATA, "01_base", "survey_data", "midline_noPII.dta")
f_endline  <- file.path(DATA, "01_base", "survey_data", "endline_round1_noPII.dta")
f_consult  <- file.path(DATA, "01_base", "survey_data", "chief_consultations.dta")

res <- list()
add_res <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) res[[name]] <<- as.numeric(val)
}

# ----------------------------------------------------------------- helpers
num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- unclass(haven::zap_labels(x))
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) x <- suppressWarnings(as.numeric(x))
  if (inherits(x, "Date")) x <- as.numeric(x - as.Date("1960-01-01"))
  as.numeric(x)
}

stata_day <- function(x) {
  if (inherits(x, "Date")) return(as.numeric(x - as.Date("1960-01-01")))
  if (inherits(x, "POSIXt")) return(as.numeric(as.Date(x) - as.Date("1960-01-01")))
  if (is.character(x) || is.factor(x)) {
    x <- as.character(x)
    fmts <- c("%Y-%m-%d", "%d%b%Y", "%b %d, %Y", "%m/%d/%Y", "%d/%m/%Y", "%Y/%m/%d")
    best <- NULL; bestn <- -1
    for (f in fmts) {
      d <- suppressWarnings(as.Date(substr(x, 1, 30), format = f))
      n <- sum(!is.na(d))
      if (n > bestn) { bestn <- n; best <- d }
    }
    return(as.numeric(best - as.Date("1960-01-01")))
  }
  v <- num(x)
  med <- suppressWarnings(median(v, na.rm = TRUE))
  if (is.finite(med) && med > 1e9) v <- floor(v / 86400000)   # %tc milliseconds
  v
}

pick <- function(nms, cands) {
  for (c in cands) if (!is.na(c) && c %in% nms) return(c)
  lc <- tolower(nms)
  for (c in cands) { i <- which(lc == tolower(c)); if (length(i)) return(nms[i[1]]) }
  NA_character_
}

# choose the column of df whose values best overlap with the key vector
best_id <- function(df, keys, cands) {
  cands <- cands[cands %in% names(df)]
  if (!length(cands)) {
    cands <- names(df)[sapply(df, function(z) is.numeric(z) || inherits(z, "haven_labelled"))]
  }
  ukeys <- unique(keys[!is.na(keys)])
  best <- NA_character_; bestr <- -1
  for (c in cands) {
    v <- unique(num(df[[c]])); v <- v[!is.na(v)]
    if (!length(v)) next
    r <- sum(v %in% ukeys)
    if (r > bestr) { bestr <- r; best <- c }
  }
  best
}

# open-ended campaign-wave bins: first wave absorbs earlier dates, last wave later dates
cutcodes <- function(x, br) {
  br2 <- br; br2[1] <- -Inf; br2[length(br2)] <- Inf
  k <- findInterval(x, br2)
  k[is.na(x) | k == 0 | k == length(br2)] <- NA
  k - 1
}

map_tmt <- function(x) {
  lab <- NULL
  if (inherits(x, "haven_labelled")) {
    lab <- as.character(haven::as_factor(x, levels = "default"))
    v <- num(x)
  } else if (is.character(x) || is.factor(x)) {
    lab <- as.character(x); v <- suppressWarnings(as.numeric(lab))
  } else v <- num(x)
  out <- rep(NA_real_, length(v))
  if (!is.null(lab) && any(grepl("[A-Za-z]", lab))) {
    l <- tolower(lab)
    out[grepl("info|\\bcli\\b", l)] <- 3
    i <- is.na(out) & grepl("cxl|xlocal| x |both|central.*local|local.*central", l); out[i] <- 4
    i <- is.na(out) & grepl("local|chief|chef", l); out[i] <- 2
    i <- is.na(out) & grepl("central|state|dgrkoc", l); out[i] <- 1
    i <- is.na(out) & grepl("control|pure|declar", l); out[i] <- 0
  }
  if (all(is.na(out))) {
    out <- v
    u <- unique(v[!is.na(v)])
    if (5 %in% u && !(0 %in% u)) out[out == 5] <- 0
  }
  out
}

modal <- function(z) {
  z <- z[!is.na(z)]
  if (!length(z)) return(NA_real_)
  as.numeric(names(which.max(table(z))))
}

rd <- function(f) as.data.frame(haven::read_dta(f))

ID_CANDS <- c("compound1", "compound_code", "compound", "compound_id", "code_compound")

# ----------------------------------------------------------------- build analysis data
build_analysis <- function() {
  reg <- haven::read_dta(f_reg)
  cat("registration columns:", paste(names(reg), collapse = " "), "\n")
  rid <- pick(names(reg), ID_CANDS)
  ra7 <- pick(names(reg), c("a7", "polygon", "poly", "a7_final"))
  if (is.na(rid) || is.na(ra7)) stop("cannot locate id / a7 in registration")
  cat("registration raw rows:", nrow(reg), "\n")
  ord <- seq_len(nrow(reg))
  if ("tot_complete" %in% names(reg)) ord <- order(-(num(reg$tot_complete) %in% 1), ord)
  reg <- reg[ord, ]
  idv <- num(reg[[rid]])
  a7v <- num(reg[[ra7]])
  ida <- data.frame(id = idv, a7 = a7v)[!is.na(idv), ]
  ida <- ida[!duplicated(ida), ]
  ncross <- sum(duplicated(ida$id))
  cat("compound ids appearing in more than one neighborhood:", ncross, "\n")
  for (fl in c("dup_poly", "double_sensi", "tot_complete")) if (fl %in% names(reg)) {
    cat(fl, ":\n"); print(table(num(reg[[fl]]), useNA = "ifany"))
  }
  # deduplicate within neighborhood: a property is identified by (neighborhood, compound id)
  key <- paste(a7v, idv)
  keep <- !is.na(idv) & !duplicated(key)
  reg <- reg[keep, ]
  if (ncross > 0)
    cat('DEVIATION: Properties identified by (neighborhood, compound id) rather than compound id alone, because compound ids repeat across neighborhoods\n')
  B <- data.frame(compound1 = num(reg[[rid]]), a7 = num(reg[[ra7]]))

  vars <- c("house", "exempt", "pilot", "rate", "taxes_paid", "taxes_paid_amt")
  for (v in vars) if (v %in% names(reg)) B[[v]] <- num(reg[[v]])
  if ("tmt" %in% names(reg)) B$tmt_reg <- num(reg$tmt)
  if ("today_alt" %in% names(reg)) B$today_alt <- stata_day(reg$today_alt)
  cat("registration rows (dedup):", nrow(B), " neighborhoods:", length(unique(B$a7)), "\n")
  if (!is.null(B$house)) { cat("house:\n"); print(table(B$house, useNA = "ifany")) }
  if (!is.null(B$pilot)) { cat("pilot:\n"); print(table(B$pilot, useNA = "ifany")) }

  # supplement from tax roll
  tr <- tryCatch(haven::read_dta(f_taxroll), error = function(e) NULL)
  if (!is.null(tr)) {
    cat("taxroll columns:", paste(names(tr), collapse = " "), "\n")
    tid <- best_id(tr, B$compound1, c(rid, ID_CANDS))
    if (!is.na(tid)) {
      tv <- num(tr[[tid]]); tk <- !is.na(tv) & !duplicated(tv)
      m <- match(B$compound1, tv[tk])
      for (v in c(vars, "today_alt")) {
        if (is.null(B[[v]]) && v %in% names(tr)) {
          B[[v]] <- if (v == "today_alt") stata_day(tr[[v]])[tk][m] else num(tr[[v]])[tk][m]
        }
      }
    }
  }

  # treatment / stratum from randomization file (by neighborhood)
  rnd <- as.data.frame(haven::read_dta(f_rand))
  cat("randomization columns:", paste(names(rnd), collapse = " "), "\n")
  rnd <- rnd[!is.na(num(rnd$a7)) & !duplicated(num(rnd$a7)), ]
  r_a7 <- num(rnd$a7)
  cat("randomization neighborhoods:", length(r_a7), "\n")
  tcol <- pick(names(rnd), c("treatment_defacto", "tmt_defacto", "treatment_final", "treatment", "tmt"))
  r_trt <- map_tmt(rnd[[tcol]])
  cat("randomization treatment column:", tcol, "\n")
  print(table(raw = as.character(haven::as_factor(rnd[[tcol]])), mapped = r_trt, useNA = "ifany"))

  # stratum: keep as a categorical key (may be non-numeric); fall back to design variables
  rs <- rnd$stratum
  s_chr <- if (is.character(rs) || is.factor(rs)) as.character(rs) else as.character(num(rs))
  s_chr[is.na(s_chr) | s_chr %in% c("", "NA", ".")] <- NA
  fbv <- intersect(c("geo_stratum", "joncomp2016", "chef_collect_stratum"), names(rnd))
  if (any(is.na(s_chr)) && length(fbv)) {
    fb <- do.call(paste, c(lapply(fbv, function(v) as.character(num(rnd[[v]]))), sep = "_"))
    s_chr[is.na(s_chr)] <- paste0("fb_", fb[is.na(s_chr)])
  }
  cat("strata:", length(unique(s_chr)), " missing:", sum(is.na(s_chr)), "\n")
  B$stratum <- s_chr[match(B$a7, r_a7)]
  B$tmt <- r_trt[match(B$a7, r_a7)]

  # de facto assignment: use registration-recorded treatment where it disagrees with assignment
  if (!is.null(B$tmt_reg) && any(!is.na(B$tmt_reg))) {
    mod <- tapply(B$tmt_reg, B$a7, modal)
    nb <- data.frame(a7 = as.numeric(names(mod)), reg = as.numeric(mod))
    nb$rand <- r_trt[match(nb$a7, r_a7)]
    cat("neighborhood registration tmt vs randomization:\n")
    print(table(reg = nb$reg, rand = nb$rand, useNA = "ifany"))
    ok <- !is.na(nb$reg) & !is.na(nb$rand)
    if (any(ok)) {
      cmap <- tapply(nb$rand[ok], nb$reg[ok], modal)
      nb$fact <- as.numeric(cmap[as.character(nb$reg)])
      dif <- ok & !is.na(nb$fact) & nb$fact != nb$rand
      cat("neighborhoods whose de facto treatment differs from assignment:", sum(dif), "\n")
      if (sum(dif) >= 1 && sum(dif) <= 3) {
        fix <- nb[dif, ]
        print(fix)
        B$tmt <- ifelse(B$a7 %in% fix$a7, fix$fact[match(B$a7, fix$a7)], B$tmt)
      }
    }
  }

  # tax payments
  if (is.null(B$taxes_paid)) {
    pay <- haven::read_dta(f_pay)
    cat("tax_payments columns:", paste(names(pay), collapse = " "), "\n")
    for (cc in c("dup_receipt", "lateCollection", "mult_tax", "error_code", "unmatched_compound",
                 "error_rate", "endOfCollect", "paid", "rate_verified")) {
      if (cc %in% names(pay)) {
        z <- num(pay[[cc]])
        if (length(unique(z)) <= 25) { cat("payments", cc, ":\n"); print(table(z, useNA = "ifany")) }
      }
    }
    pid <- best_id(pay, B$compound1, c(rid, ID_CANDS, "code", "tax_id", "taxid", "id"))
    pamt <- pick(names(pay), c("amountCF", "amount", "amt", "amt_paid", "amount_paid", "paid_amt", "montant",
                               "taxes_paid_amt", "tax_amt", "amount_cf", "paid_amount"))
    ppaid <- pick(names(pay), c("taxes_paid", "paid"))
    pa7c <- pick(names(pay), c("a7", "polygon"))
    P <- data.frame(id = num(pay[[pid]]),
                    a7 = if (!is.na(pa7c)) num(pay[[pa7c]]) else NA_real_,
                    amt = if (!is.na(pamt)) num(pay[[pamt]]) else NA_real_,
                    usd = if ("amountUSD" %in% names(pay)) num(pay$amountUSD) else NA_real_,
                    paid = if (!is.na(ppaid)) num(pay[[ppaid]]) else 1)
    if ("polygon" %in% names(pay) && !is.na(pa7c) && pa7c == "a7") {
      pp <- num(pay$polygon); P$a7[is.na(P$a7)] <- pp[is.na(P$a7)]
    }
    # amount cleaning: CF amounts inconsistent with the USD amount are re-derived from USD
    cat("amountCF quantiles (raw):\n"); print(quantile(P$amt, c(0, .1, .25, .5, .75, .9, .95, .99, 1), na.rm = TRUE))
    rat <- P$amt / P$usd
    okr <- is.finite(rat) & rat > 0
    if (sum(okr) > 50) {
      medr <- median(rat[okr])
      bad <- okr & (rat > 1.5 * medr | rat < medr / 1.5)
      fillu <- (is.na(P$amt) | P$amt <= 0) & is.finite(P$usd) & P$usd > 0
      cat("CF/USD median ratio:", medr, " inconsistent CF amounts:", sum(bad), " CF filled from USD:", sum(fillu), "\n")
      P$amt[bad | fillu] <- P$usd[bad | fillu] * medr
      if (sum(bad | fillu) > 0)
        cat('DEVIATION: CF payment amounts inconsistent with the recorded USD amount were re-derived from USD at the median CF/USD ratio\n')
    }
    # drop duplicate receipts and payments collected after the end of the campaign
    drop <- rep(FALSE, nrow(P))
    if ("dup_receipt" %in% names(pay)) drop <- drop | (num(pay$dup_receipt) %in% 1)
    if ("lateCollection" %in% names(pay)) drop <- drop | (num(pay$lateCollection) %in% 1)
    cat("payment rows dropped (duplicate receipt / late collection):", sum(drop), "of", nrow(P), "\n")
    cat('DEVIATION: Dropped duplicate receipts and late-collection payments and counted one payment (max amount) per property, since summed amounts double-counted revenue\n')
    P <- P[!drop, ]
    P <- P[!is.na(P$id) & (is.na(P$paid) | P$paid > 0), ]
    agg <- P %>% group_by(id, a7) %>%
      summarise(amt = suppressWarnings(max(amt, na.rm = TRUE)), .groups = "drop")
    agg$amt[!is.finite(agg$amt)] <- 0
    kB <- paste(B$a7, B$compound1)
    kP <- paste(agg$a7, agg$id)
    hit <- kP %in% kB
    B$taxes_paid <- 0
    B$taxes_paid_amt <- 0
    mi <- match(kP[hit], kB)
    B$taxes_paid[mi] <- 1
    B$taxes_paid_amt[mi] <- agg$amt[hit]
    rest <- agg[!hit, ]
    rB <- match(rest$id, B$compound1)
    okf <- !is.na(rB) & !duplicated(rB)
    okf <- okf & !(B$taxes_paid[ifelse(is.na(rB), 1, rB)] %in% 1)
    B$taxes_paid[rB[okf]] <- 1
    B$taxes_paid_amt[rB[okf]] <- rest$amt[okf]
    cat("payment id column:", pid, " amount column:", pamt, " payment a7 column:", pa7c,
        "\n  payer records:", nrow(agg), " matched on (a7,id):", sum(hit),
        " matched on id only:", sum(okf), " unmatched:", sum(!hit) - sum(okf), "\n")
    if (is.na(pamt) && !is.null(B$rate)) B$taxes_paid_amt <- B$taxes_paid * B$rate
  }

  # campaign timing
  if (is.null(B$today_alt)) {
    dcol <- pick(names(reg), c("today", "today_carto", "date", "starttime", "start", "submissiondate"))
    if (!is.na(dcol)) {
      d <- stata_day(reg[[dcol]])
      cat("timing from registration column:", dcol, " missing:", sum(is.na(d)), "\n")
      for (alt in c("date", "date_f", "start", "end", "today_fr")) {
        if (alt %in% names(reg) && alt != dcol && any(is.na(d))) {
          d2 <- tryCatch(stata_day(reg[[alt]]), error = function(e) rep(NA_real_, length(d)))
          d2[!(is.finite(d2) & d2 > 21300 & d2 < 21600)] <- NA
          f <- is.na(d) & !is.na(d2)
          if (any(f)) { cat("  filled", sum(f), "dates from", alt, "\n"); d[f] <- d2[f] }
        }
      }
      # property-level registration day; missing filled with neighborhood median day
      med <- tapply(d, B$a7, function(z) median(z, na.rm = TRUE))
      nbm <- as.numeric(med[as.character(B$a7)])
      B$today_alt <- ifelse(is.na(d), nbm, d)
      cat('DEVIATION: Campaign-wave FE built from property-level registration date (alternate date fields, then neighborhood median, where missing)\n')
    } else B$today_alt <- NA_real_
  }

  # midline visits
  mn <- names(haven::read_dta(f_midline, n_max = 0))
  mcols <- intersect(c(ID_CANDS, "visited", "visits", "tot_complete"), mn)
  mid <- as.data.frame(haven::read_dta(f_midline, col_select = all_of(mcols)))
  mid_id <- best_id(mid, B$compound1, ID_CANDS)
  if ("tot_complete" %in% names(mid)) mid <- mid[num(mid$tot_complete) %in% 1, ]
  mv <- num(mid[[mid_id]])
  mk <- !is.na(mv) & !duplicated(mv)
  mm <- match(B$compound1, mv[mk])
  B$visited <- if ("visited" %in% names(mid)) num(mid$visited)[mk][mm] else NA_real_
  B$visits  <- if ("visits" %in% names(mid)) num(mid$visits)[mk][mm] else NA_real_

  # sample restrictions: villas out; logistics-pilot neighborhoods out; keep randomized neighborhoods
  if (!is.null(B$house)) B <- B[is.na(B$house) | B$house != 3, ]
  if (!is.null(B$pilot)) {
    pm <- tapply(B$pilot %in% 1, B$a7, mean)
    pil <- as.numeric(names(pm)[pm > 0.5])
    cat("pilot neighborhoods dropped:", length(pil), "\n")
    B <- B[!(B$a7 %in% pil), ]
  }
  B <- B[!is.na(B$a7) & B$a7 %in% r_a7 & !is.na(B$tmt), ]
  B
}

if (file.exists(f_analysis)) {
  A0 <- rd(f_analysis)
  for (v in c("a7", "tmt", "stratum", "house", "exempt", "taxes_paid", "taxes_paid_amt",
              "visited", "visits", "compound1")) if (v %in% names(A0)) A0[[v]] <- num(A0[[v]])
  A0$today_alt <- stata_day(A0$today_alt)
  ALL <- A0
} else {
  ALL <- build_analysis()
}

cat("Treatment allocation (neighborhoods / properties):\n")
print(tapply(ALL$a7, ALL$tmt, function(z) length(unique(z))))
print(table(ALL$tmt))
cat("today_alt summary:\n"); print(summary(ALL$today_alt))
cat("mean compliance by arm:\n"); print(tapply(ALL$taxes_paid, ALL$tmt, mean, na.rm = TRUE))
cat("mean revenue by arm:\n"); print(tapply(ALL$taxes_paid_amt, ALL$tmt, mean, na.rm = TRUE))
cat("mean revenue per payer by arm:\n")
print(tapply(ALL$taxes_paid_amt[ALL$taxes_paid %in% 1], ALL$tmt[ALL$taxes_paid %in% 1], mean, na.rm = TRUE))

ALL$t_l   <- as.numeric(ALL$tmt == 2)
ALL$t_c   <- as.numeric(ALL$tmt == 1)
ALL$t_cli <- as.numeric(ALL$tmt == 3)

A <- ALL[ALL$tmt %in% c(1, 2, 3), ]
A$tfe_CvL   <- cutcodes(A$today_alt, c(21355, 21415, 21475, 21532))
A$tfe_CvL6  <- cutcodes(A$today_alt, c(21355, 21415, 21475, 21529))
A$tfe_CvCLI <- cutcodes(A$today_alt, c(21365.5, 21425.5, 21485.5, 21519))
cat('DEVIATION: Campaign-wave bins made open-ended at the first and last wave so early/late registration dates are not dropped\n')

vpc <- rep(NA_real_, nrow(A))
vpc[(!is.na(A$visited) & A$visited == 0) | (!is.na(A$visits) & A$visits != 0)] <- 0
vpc[!is.na(A$visits) & A$visits > 1] <- 1
A$visit_post_carto <- vpc

fit <- function(fml, d) feols(fml, data = d, cluster = ~a7, fixef.rm = "none")
cf <- function(m, v) unname(coef(m)[v])

# ----------------------------------------------------------------- Table 4
CL <- A[A$tmt %in% c(1, 2), ]
tryCatch({
  m1 <- fit(taxes_paid ~ t_l | stratum, CL)
  add_res("compliance_local_table4_panelA_col1", cf(m1, "t_l"))
  add_res("n_obs_table4_col1", nobs(m1))
}, error = function(e) cat("T4 col1 error:", conditionMessage(e), "\n"))
tryCatch({
  m2 <- fit(taxes_paid ~ t_l | stratum + tfe_CvL, CL)
  add_res("compliance_local_table4_panelA_col2", cf(m2, "t_l"))
  add_res("n_obs_table4_col2", nobs(m2))
}, error = function(e) cat("T4 col2 error:", conditionMessage(e), "\n"))
tryCatch({
  m4 <- fit(taxes_paid ~ t_l | stratum + house + tfe_CvL, CL)
  add_res("compliance_local_house_fe_table4_panelA_col4", cf(m4, "t_l"))
}, error = function(e) cat("T4 col4 error:", conditionMessage(e), "\n"))
tryCatch({
  m5 <- fit(taxes_paid ~ t_l | stratum + house + tfe_CvL, CL[is.na(CL$exempt) | CL$exempt != 1, ])
  add_res("compliance_local_exempt_excluded_table4_panelA_col5", cf(m5, "t_l"))
}, error = function(e) cat("T4 col5 error:", conditionMessage(e), "\n"))
tryCatch({
  r2 <- fit(taxes_paid_amt ~ t_l | stratum + tfe_CvL, CL)
  add_res("revenue_local_table4_panelB_col2", cf(r2, "t_l"))
}, error = function(e) cat("T4 rev col2 error:", conditionMessage(e), "\n"))
tryCatch({
  r4 <- fit(taxes_paid_amt ~ t_l | stratum + house + tfe_CvL, CL)
  add_res("revenue_local_house_fe_table4_panelB_col4", cf(r4, "t_l"))
}, error = function(e) cat("T4 rev col4 error:", conditionMessage(e), "\n"))

# ----------------------------------------------------------------- Table 6
tryCatch({
  v1 <- fit(visit_post_carto ~ t_l | house + stratum + tfe_CvL6, CL)
  add_res("visited_by_collector_local_table6_col1", cf(v1, "t_l"))
}, error = function(e) cat("T6 error:", conditionMessage(e), "\n"))

# ----------------------------------------------------------------- Table 7
CC <- A[A$tmt %in% c(1, 3), ]
tryCatch({
  c1 <- fit(taxes_paid ~ t_cli | house + stratum + tfe_CvCLI, CC)
  add_res("compliance_cli_table7_col1", cf(c1, "t_cli"))
}, error = function(e) cat("T7 col1 error:", conditionMessage(e), "\n"))
tryCatch({
  c2 <- fit(taxes_paid_amt ~ t_cli | house + stratum + tfe_CvCLI, CC)
  add_res("revenue_cli_table7_col2", cf(c2, "t_cli"))
}, error = function(e) cat("T7 col2 error:", conditionMessage(e), "\n"))

# ----------------------------------------------------------------- Endline data
EL <- tryCatch(rd(f_endline), error = function(e) NULL)
if (!is.null(EL) && "tot_complete" %in% names(EL)) EL <- EL[num(EL$tot_complete) %in% 1, ]

# Table 5, Panel B: paid bribe (endline)
tryCatch({
  E <- EL
  br <- num(E$bribe)
  for (alt in c("bribe2a", "bribe2b", "bribe3")) if (alt %in% names(E)) br[is.na(br)] <- num(E[[alt]])[is.na(br)]
  tm <- ALL %>% group_by(a7) %>%
    summarise(treatment = dplyr::first(tmt[!is.na(tmt)]),
              stratum = dplyr::first(stratum[!is.na(stratum)]), .groups = "drop")
  E5 <- data.frame(a7 = num(E$a7), bribe_endline = br)
  E5 <- inner_join(E5, tm, by = "a7")
  E5$t_l <- as.numeric(E5$treatment == 2)
  E5 <- E5[E5$treatment %in% c(1, 2), ]
  b1 <- fit(bribe_endline ~ t_l | stratum, E5)
  add_res("paid_bribe_endline_local_table5_panelB", cf(b1, "t_l"))
}, error = function(e) cat("T5 error:", conditionMessage(e), "\n"))

# ----------------------------------------------------------------- Table 8, Panel A col 2
tryCatch({
  A8 <- A
  if (!is.null(EL)) {
    cc <- num(EL$compound_code)
    mv <- if ("move" %in% names(EL)) num(EL$move) else rep(NA_real_, nrow(EL))
    if ("compound_code_prev" %in% names(EL)) {
      sw <- !is.na(mv) & mv %in% c(1, 2)
      cc[sw] <- num(EL$compound_code_prev)[sw]
    }
    cc[cc %in% c(99999, 9999999)] <- 999999
    cc <- cc[!is.na(cc) & cc != 999999]
    cnt <- table(cc)
    w <- as.numeric(cnt[as.character(A8$compound1)])
    w[is.na(w)] <- 1
    A8 <- A8[rep(seq_len(nrow(A8)), times = w), ]
  }
  con <- haven::read_dta(f_consult)
  cid <- best_id(con, A8$compound1, ID_CANDS)
  cv <- num(con[[cid]]); ck <- !is.na(cv) & !duplicated(cv)
  A8$pay_ease <- num(con$pay_ease)[ck][match(A8$compound1, cv[ck])]
  D8 <- A8[A8$t_cli == 1, ]
  p2 <- fit(taxes_paid ~ pay_ease | house + stratum, D8)
  add_res("compliance_ease_of_payment_cli_table8_panelA_col2", cf(p2, "pay_ease"))
}, error = function(e) cat("T8 error:", conditionMessage(e), "\n"))

# ----------------------------------------------------------------- output
order_names <- c("compliance_local_table4_panelA_col1",
                 "compliance_local_table4_panelA_col2",
                 "compliance_local_house_fe_table4_panelA_col4",
                 "compliance_local_exempt_excluded_table4_panelA_col5",
                 "revenue_local_table4_panelB_col2",
                 "revenue_local_house_fe_table4_panelB_col4",
                 "n_obs_table4_col1",
                 "n_obs_table4_col2",
                 "paid_bribe_endline_local_table5_panelB",
                 "visited_by_collector_local_table6_col1",
                 "compliance_cli_table7_col1",
                 "revenue_cli_table7_col2",
                 "compliance_ease_of_payment_cli_table8_panelA_col2")
for (n in order_names) {
  if (!is.null(res[[n]])) cat(sprintf("RESULT:%s=%s\n", n, format(res[[n]], digits = 10)))
}