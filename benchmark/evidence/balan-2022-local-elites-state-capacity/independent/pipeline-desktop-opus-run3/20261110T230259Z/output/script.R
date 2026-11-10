suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/balan_2022_local_elites_state_capacity.script-free/Replication Materials - Updated October 2025/Data/01_base"
adm <- file.path(root, "admin_data")
svy <- file.path(root, "survey_data")

msg <- function(...) cat(paste(..., collapse = " "), "\n", file = stderr())
rd <- function(f) { d <- haven::read_dta(f); names(d) <- tolower(names(d)); d }
pick <- function(nm, cands) { x <- intersect(cands, nm); if (length(x)) x[1] else NA_character_ }
num <- function(x) suppressWarnings(as.numeric(haven::zap_labels(x)))

res <- list()

# ---------------- helpers ----------------
arm_of <- function(x) {
  if (inherits(x, "haven_labelled")) {
    lab <- as.character(haven::as_factor(x, levels = "labels"))
  } else lab <- as.character(x)
  l <- tolower(lab)
  out <- rep(NA_character_, length(l))
  out[grepl("control|declar|pure", l)] <- "Control"
  out[grepl("central", l)] <- "Central"
  out[grepl("local", l)] <- "Local"
  out[grepl("cxl|central x local|central_x_local|central-x-local|x local| x |both", l)] <- "CXL"
  out[grepl("info|cli", l)] <- "CLI"
  out
}

arm_by_count <- function(code) {
  # fallback when treatment codes are unlabelled: map by neighborhood counts
  v <- num(code)
  tb <- sort(table(v))
  out <- rep(NA_character_, length(v))
  if (length(tb) < 4) return(out)
  vals <- as.numeric(names(tb))
  cnt <- as.numeric(tb)
  m <- c()
  m[as.character(vals[which.min(abs(cnt - 5))])] <- "Control"
  m[as.character(vals[which.min(abs(cnt - 50))])] <- "CXL"
  m[as.character(vals[which.min(abs(cnt - 80))])] <- "CLI"
  big <- vals[order(-cnt)][1:2]
  big <- sort(big)
  m[as.character(big[1])] <- "Central"
  m[as.character(big[2])] <- "Local"
  out <- unname(m[as.character(v)])
  out
}

to_bin <- function(x) {
  lab <- NULL
  if (inherits(x, "haven_labelled")) lab <- attr(x, "labels")
  v <- num(x)
  v[!is.na(v) & v < 0] <- NA
  if (!is.null(lab)) {
    nm <- tolower(names(lab))
    yes <- lab[grepl("^yes|^oui", nm)]
    no <- lab[grepl("^no$|^no |^no,|^non", nm)]
    if (length(yes) && length(no)) {
      return(ifelse(v %in% yes, 1, ifelse(v %in% no, 0, NA)))
    }
  }
  u <- unique(na.omit(v))
  if (all(u %in% c(0, 1))) return(v)
  if (all(u %in% c(1, 2))) return(ifelse(is.na(v), NA, ifelse(v == 1, 1, 0)))
  ifelse(is.na(v), NA, as.numeric(v > 0))
}

to_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  if (is.character(x)) {
    d <- suppressWarnings(as.Date(x))
    if (all(is.na(d))) d <- suppressWarnings(as.Date(x, format = "%d%b%Y"))
    if (all(is.na(d))) d <- suppressWarnings(as.Date(x, format = "%b %d, %Y"))
    if (all(is.na(d))) d <- suppressWarnings(as.Date(x, format = "%d/%m/%Y"))
    return(d)
  }
  v <- num(x)
  if (all(is.na(v))) return(as.Date(v, origin = "1960-01-01"))
  if (median(v, na.rm = TRUE) > 1e8) return(as.Date(as.POSIXct(v / 1000, origin = "1960-01-01", tz = "UTC")))
  as.Date(v, origin = "1960-01-01")
}

find_id <- function(a, b) {
  c1 <- c("compound1", "compound_code", "compound", "code", "tax_id", "taxid", "property_id", "house_id", "id")
  x <- intersect(intersect(c1, names(a)), names(b))
  if (length(x)) return(x[1])
  cm <- intersect(names(a), names(b))
  cm <- cm[grepl("compound|code|^id", cm)]
  if (length(cm)) cm[1] else NA_character_
}

# ---------------- neighborhood-level data ----------------
nbp <- rd(file.path(adm, "tax_payments_neighborhoods.dta"))
ra <- rd(file.path(adm, "randomization_assignment.dta"))
msg("nb names:", names(nbp))
msg("ra names:", names(ra))

nbid_nb <- pick(names(nbp), c("a7", "polygon", "grid_nm"))
nbid_ra <- pick(names(ra), c("a7", "polygon", "grid_nm"))

nb <- data.frame(a7 = as.character(num(nbp[[nbid_nb]])), stringsAsFactors = FALSE)
if (all(is.na(nb$a7))) nb$a7 <- as.character(nbp[[nbid_nb]])
nb$stratum <- if ("stratum" %in% names(nbp)) num(nbp$stratum) else NA

arm <- rep(NA_character_, nrow(nb))
if ("program" %in% names(nbp)) {
  arm <- arm_of(nbp$program)
  if (sum(!is.na(arm)) < 300) arm <- arm_by_count(nbp$program)
}
if (sum(!is.na(arm)) < 300 && !is.na(nbid_ra)) {
  ra_id <- as.character(num(ra[[nbid_ra]]))
  if (all(is.na(ra_id))) ra_id <- as.character(ra[[nbid_ra]])
  tcol <- pick(names(ra), c("treatment", "tmt"))
  a2 <- arm_of(ra[[tcol]])
  if (sum(!is.na(a2)) < 300) a2 <- arm_by_count(ra[[tcol]])
  arm <- a2[match(nb$a7, ra_id)]
  if (all(is.na(nb$stratum))) nb$stratum <- num(ra$stratum)[match(nb$a7, ra_id)]
}
# fill neighborhoods with missing arm / stratum from the randomization file
tryCatch({
  if ((any(is.na(arm)) || any(is.na(nb$stratum))) && !is.na(nbid_ra)) {
    ra_id <- as.character(num(ra[[nbid_ra]]))
    if (all(is.na(ra_id))) ra_id <- as.character(ra[[nbid_ra]])
    tcol <- pick(names(ra), c("treatment", "tmt"))
    a2 <- arm_of(ra[[tcol]])
    if (sum(!is.na(a2)) < 300) a2 <- arm_by_count(ra[[tcol]])
    fill <- a2[match(nb$a7, ra_id)]
    nfill <- sum(is.na(arm) & !is.na(fill))
    arm[is.na(arm)] <- fill[is.na(arm)]
    if (nfill > 0) cat(sprintf("DEVIATION: Filled treatment arm for %d neighborhoods with missing program code from randomization_assignment\n", nfill))
    if ("stratum" %in% names(ra)) {
      sf <- num(ra$stratum)[match(nb$a7, ra_id)]
      nb$stratum[is.na(nb$stratum)] <- sf[is.na(nb$stratum)]
    }
  }
}, error = function(e) msg("arm fill fail", conditionMessage(e)))
nb$arm <- arm
msg("nb arm table:"); msg(capture.output(print(table(nb$arm, useNA = "ifany"))))

nb$start <- as.Date(NA)
if ("program_start" %in% names(nbp)) nb$start <- to_date(nbp$program_start)

# ---------------- registration / property register ----------------
reg <- rd(file.path(adm, "registration_noPII.dta"))
msg("reg names:", names(reg))
rid <- pick(names(reg), c("a7", "polygon", "grid_nm"))
reg$a7 <- as.character(num(reg[[rid]]))
if (all(is.na(reg$a7))) reg$a7 <- as.character(reg[[rid]])
if ("pilot" %in% names(reg)) reg <- reg[is.na(num(reg$pilot)) | num(reg$pilot) != 1, ]
reg <- reg[reg$a7 %in% nb$a7, ]

# house type; drop villas
reg$house_n <- num(reg$house)
msg("house table:"); msg(capture.output(print(table(reg$house_n, useNA = "ifany"))))
if (inherits(reg$house, "haven_labelled")) {
  hl <- attr(reg$house, "labels")
  vil <- hl[grepl("villa", tolower(names(hl)))]
  if (length(vil)) reg <- reg[!(reg$house_n %in% vil), ]
}
th <- table(reg$house_n)
if (length(th) > 2) {
  small <- as.numeric(names(th)[th < 1000])
  reg <- reg[!(reg$house_n %in% small), ]
}

reg$exempt_n <- if ("exempt" %in% names(reg)) to_bin(reg$exempt) else 0

# de facto treatment
reg$arm <- nb$arm[match(reg$a7, nb$a7)]
tc <- pick(names(reg), c("tmt", "treatment"))
if (!is.na(tc)) {
  a3 <- arm_of(reg[[tc]])
  if (mean(!is.na(a3)) > 0.9) reg$arm <- a3
}
reg$stratum <- nb$stratum[match(reg$a7, nb$a7)]

# ---------------- 2018 campaign start date per neighborhood ----------------
# program_start in the neighborhood file is dated 2016 (previous campaign) and is
# missing for many neighborhoods; the 2018 campaign timing is taken from the
# 2018 registration (door-to-door) dates in the property register.
reg_start_nb <- function() {
  cands <- intersect(c("today", "date", "start", "time", "date_f", "end"), names(reg))
  best <- NULL; bshare <- 0; bname <- NA
  for (cn in cands) {
    d <- tryCatch(to_date(reg[[cn]]), error = function(e) NULL)
    if (is.null(d) || length(d) != nrow(reg)) next
    ok <- !is.na(d) & d >= as.Date("2018-03-01") & d <= as.Date("2019-12-31")
    sh <- mean(ok)
    msg("reg date col", cn, "share in 2018-19:", sh)
    if (sh > bshare) { bshare <- sh; best <- d; best[!ok] <- NA; bname <- cn }
  }
  msg("chosen reg date col:", bname, bshare)
  if (is.null(best) || bshare < 0.5) return(NULL)
  tmp <- tapply(as.numeric(best), reg$a7, function(z) {
    z <- z[!is.na(z)]
    if (!length(z)) NA_real_ else as.numeric(quantile(z, 0.01, type = 1))
  })
  as.Date(as.numeric(tmp[nb$a7]), origin = "1970-01-01")
}
rs <- tryCatch(reg_start_nb(), error = function(e) { msg("reg start fail", conditionMessage(e)); NULL })
if (!is.null(rs) && sum(!is.na(rs)) >= 0.8 * nrow(nb)) {
  msg("program_start non-missing:", sum(!is.na(nb$start)), "reg-based start non-missing:", sum(!is.na(rs)))
  msg("reg-based start range:", as.character(min(rs, na.rm = TRUE)), as.character(max(rs, na.rm = TRUE)))
  nb$start <- rs
  cat("DEVIATION: Campaign start per neighborhood taken from earliest 2018 registration dates in the property register (program_start in the neighborhood file is 2016-dated and missing for many neighborhoods)\n")
} else if (all(is.na(nb$start))) {
  dc <- pick(names(reg), c("today", "date", "time", "starttime", "submissiondate"))
  if (!is.na(dc)) {
    rd8 <- to_date(reg[[dc]])
    tmp <- tapply(as.numeric(rd8), reg$a7, function(z) suppressWarnings(min(z, na.rm = TRUE)))
    tmp[!is.finite(tmp)] <- NA
    nb$start <- as.Date(as.numeric(tmp[nb$a7]), origin = "1970-01-01")
  }
}

# ---------------- payments ----------------
had_tp <- "taxes_paid" %in% names(reg)
done <- FALSE
if (had_tp) {
  tp <- to_bin(reg$taxes_paid)
  if (sum(!is.na(tp)) > 0) {
    reg$taxes_paid <- tp
    reg$revenue <- NA_real_
    ac <- pick(names(reg), c("taxes_paid_amt", "amt_paid", "amount_paid"))
    if (!is.na(ac)) { a <- num(reg[[ac]]); a[is.na(a)] <- 0; reg$revenue <- a * reg$taxes_paid }
    done <- TRUE
  }
}
if (!done) {
  reg$taxes_paid <- NA_real_
  reg$revenue <- NA_real_
}
if (!done) {
  pay <- tryCatch(rd(file.path(adm, "tax_payments_noPII.dta")), error = function(e) { msg("pay read fail", conditionMessage(e)); NULL })
  if (!is.null(pay)) {
    msg("pay names:", names(pay))
    pid <- find_id(reg, pay)
    msg("payment id:", pid)
    if (!is.na(pid)) {
      amc <- pick(names(pay), c("amountcf", "amount", "amt_paid", "amount_paid", "paid_amount", "amt", "montant"))
      msg("amount column:", amc)
      pay$k <- as.character(pay[[pid]])
      pay$amt <- if (!is.na(amc)) num(pay[[amc]]) else NA
      msg("payment rows:", nrow(pay))
      # keep only actual payment records
      if ("paid" %in% names(pay)) {
        pv <- num(pay$paid)
        msg("pay$paid table:"); msg(capture.output(print(table(pv, useNA = "ifany"))))
        if (any(pv == 1, na.rm = TRUE) && any(pv == 0, na.rm = TRUE)) {
          pay <- pay[!is.na(pv) & pv == 1, ]
          cat("DEVIATION: Payment records restricted to paid==1 before matching to the register\n")
        }
      }
      pay <- pay[!is.na(pay$k) & pay$k != "", ]
      # neighborhood-qualified matching key to avoid cross-neighborhood false matches
      pa7c <- pick(names(pay), c("a7", "polygon"))
      key1_r <- as.character(reg[[pid]])
      n1 <- sum(key1_r %in% pay$k)
      use_a7 <- FALSE
      if (!is.na(pa7c)) {
        pa7 <- as.character(num(pay[[pa7c]]))
        key2_p <- paste(pa7, pay$k)
        key2_r <- paste(reg$a7, key1_r)
        n2 <- sum(key2_r %in% key2_p)
        msg("matched props compound-only:", n1, "compound+a7:", n2)
        if (n2 >= 0.9 * n1) use_a7 <- TRUE
      }
      if (use_a7) { pay$kk <- key2_p; key <- key2_r } else { pay$kk <- pay$k; key <- key1_r }
      msg("receipts per compound:"); msg(capture.output(print(table(pmin(table(pay$kk), 5)))))
      # one payment per property (duplicate receipts not summed)
      pa <- pay %>% group_by(kk) %>%
        summarise(amt = if (all(is.na(amt))) NA_real_ else max(amt, na.rm = TRUE), n = n(), .groups = "drop")
      m <- match(key, pa$kk)
      tp <- ifelse(is.na(m), 0, 1)
      am <- pa$amt[m]
      if (all(is.na(pa$amt)) || all(pa$amt == 0, na.rm = TRUE)) {
        rc <- pick(names(reg), c("rate", "rate_assigned"))
        am <- if (!is.na(rc)) ifelse(is.na(m), 0, num(reg[[rc]])) else rep(NA_real_, length(m))
      }
      am[is.na(m)] <- 0
      payer <- tp == 1
      msg("payer amount quantiles:"); msg(capture.output(print(quantile(am[payer], c(0, .01, .1, .5, .9, .99, .999, 1), na.rm = TRUE))))
      msg("top payer amounts:", head(sort(am[payer], decreasing = TRUE), 15))
      # data-entry outliers / missing amounts among payers -> typical amount for that house type
      med <- median(am[payer & !is.na(am) & am > 0])
      bad <- payer & (is.na(am) | am <= 0 | am > 15 * med)
      if (any(bad)) {
        hm <- tapply(am[payer & !bad], reg$house_n[payer & !bad], median)
        rep_v <- unname(hm[as.character(reg$house_n[bad])])
        rep_v[is.na(rep_v)] <- med
        am[bad] <- rep_v
        cat(sprintf("DEVIATION: %d payer amounts that were missing, non-positive or above 15x the median payment were replaced by the median payment for that house type\n", sum(bad)))
      }
      if (sum(tp) > 100) {
        reg$taxes_paid <- tp
        reg$revenue <- am
        done <- TRUE
      }
    }
  }
}
if (!done && "amt_paid" %in% names(reg)) {
  a <- num(reg$amt_paid); a[is.na(a)] <- 0
  reg$taxes_paid <- as.numeric(a > 0)
  reg$revenue <- a
  done <- TRUE
}
msg("mean compliance:", mean(reg$taxes_paid, na.rm = TRUE))
msg("mean revenue:", mean(reg$revenue, na.rm = TRUE), "non-missing:", sum(!is.na(reg$revenue)))
msg("compliance by arm:"); msg(capture.output(print(tapply(reg$taxes_paid, reg$arm, mean))))
msg("revenue by arm:"); msg(capture.output(print(tapply(reg$revenue, reg$arm, mean))))

# ---------------- time periods ----------------
make_period <- function(armA, armB) {
  s <- nb[nb$arm %in% c(armA, armB) & !is.na(nb$start), ]
  fa <- min(s$start[s$arm == armA]); fb <- min(s$start[s$arm == armB])
  la <- max(s$start[s$arm == armA]); lb <- max(s$start[s$arm == armB])
  st <- fa + as.numeric(fb - fa) / 2
  en <- la + as.numeric(lb - la) / 2
  st <- as.Date(floor(as.numeric(st)), origin = "1970-01-01")
  en <- as.Date(ceiling(as.numeric(en)), origin = "1970-01-01")
  br <- seq(st, en + 70, by = "2 months")
  pmaxv <- max(1, findInterval(as.numeric(en), as.numeric(br)))
  p <- findInterval(as.numeric(nb$start), as.numeric(br))
  ok <- !is.na(p)
  p[ok] <- pmin(pmax(p[ok], 1), pmaxv)
  p[is.na(nb$start)] <- 0
  msg("periods", armA, armB, as.character(st), as.character(en)); msg(capture.output(print(table(p[nb$arm %in% c(armA, armB)], useNA = "ifany"))))
  setNames(p, nb$a7)
}

per_lc <- tryCatch(make_period("Local", "Central"), error = function(e) { msg("period fail", conditionMessage(e)); NULL })
per_cli <- tryCatch(make_period("CLI", "Central"), error = function(e) { msg("period fail", conditionMessage(e)); NULL })
cat("DEVIATION: Time FE built as two-month campaign periods with neighborhoods starting outside the Local/Central overlap window pooled into the edge periods instead of being dropped (paper does not detail period construction)\n")

run <- function(fml, data, cf) {
  tryCatch({
    m <- feols(as.formula(fml), data = data, cluster = ~a7, warn = FALSE, notes = FALSE)
    msg(fml, "coef", coef(m)[cf], "se", sqrt(diag(vcov(m)))[cf], "N", nobs(m))
    m
  }, error = function(e) { msg("FAIL", fml, conditionMessage(e)); NULL })
}
getc <- function(m, cf) if (is.null(m)) NA else unname(coef(m)[cf])

# ---------------- Table 4 ----------------
lc <- reg[reg$arm %in% c("Local", "Central"), ]
lc$local <- as.numeric(lc$arm == "Local")
lc$period <- if (!is.null(per_lc)) unname(per_lc[lc$a7]) else NA
lc$house_n[is.na(lc$house_n)] <- -1
msg("N Local+Central:", nrow(lc))

m1 <- run("taxes_paid ~ local | stratum", lc, "local")
res$compliance_local_table4_panelA_col1 <- getc(m1, "local")
if (!is.null(m1)) res$n_obs_table4_col1 <- nobs(m1)

lc2 <- lc[!is.na(lc$period), ]
m2 <- run("taxes_paid ~ local | stratum + period", lc2, "local")
res$compliance_local_table4_panelA_col2 <- getc(m2, "local")
if (!is.null(m2)) res$n_obs_table4_col2 <- nobs(m2)

m4 <- run("taxes_paid ~ local | stratum + period + house_n", lc2, "local")
res$compliance_local_house_fe_table4_panelA_col4 <- getc(m4, "local")

lc5 <- lc2[is.na(lc2$exempt_n) | lc2$exempt_n != 1, ]
m5 <- run("taxes_paid ~ local | stratum + period + house_n", lc5, "local")
res$compliance_local_exempt_excluded_table4_panelA_col5 <- getc(m5, "local")

r2 <- run("revenue ~ local | stratum + period", lc2, "local")
res$revenue_local_table4_panelB_col2 <- getc(r2, "local")
r4 <- run("revenue ~ local | stratum + period + house_n", lc2, "local")
res$revenue_local_house_fe_table4_panelB_col4 <- getc(r4, "local")

# ---------------- Table 7: CLI vs Central ----------------
# Pooled specification over all non-control arms (Central omitted), with the
# other arms entering as separate treatment indicators, so the stratum and
# campaign-period FE are estimated on the full experimental sample. The same
# campaign periods as in Table 4 are used.
cc <- reg[reg$arm %in% c("CLI", "Central", "Local", "CXL"), ]
cc$cli <- as.numeric(cc$arm == "CLI")
cc$local <- as.numeric(cc$arm == "Local")
cc$cxl <- as.numeric(cc$arm == "CXL")
cc$period <- if (!is.null(per_lc)) unname(per_lc[cc$a7]) else NA
cc$house_n[is.na(cc$house_n)] <- -1
cc <- cc[!is.na(cc$period), ]
msg("N pooled Table 7 sample:", nrow(cc))
t7a <- run("taxes_paid ~ cli + local + cxl | stratum + period", cc, "cli")
res$compliance_cli_table7_col1 <- getc(t7a, "cli")
t7b <- run("revenue ~ cli + local + cxl | stratum + period", cc, "cli")
res$revenue_cli_table7_col2 <- getc(t7b, "cli")
# diagnostics: alternative specifications
run("taxes_paid ~ cli + local + cxl | stratum + period + house_n", cc, "cli")
run("taxes_paid ~ cli + local + cxl | stratum", cc, "cli")

# ---------------- Table 5: endline bribe ----------------
tryCatch({
  el <- rd(file.path(svy, "endline_round1_noPII.dta"))
  eid <- pick(names(el), c("a7", "polygon", "grid_nm"))
  el$a7 <- as.character(num(el[[eid]]))
  cpl <- pick(names(el), c("tot_complete", "complete"))
  if (!is.na(cpl)) { v <- num(el[[cpl]]); if (any(v == 1, na.rm = TRUE)) el <- el[!is.na(v) & v == 1, ] }
  el$arm <- nb$arm[match(el$a7, nb$a7)]
  el$stratum <- nb$stratum[match(el$a7, nb$a7)]
  bc <- pick(names(el), c("paid_bribe", "bribe", "transport", "bribe_self"))
  msg("bribe var:", bc); msg(capture.output(print(table(num(el[[bc]]), useNA = "ifany"))))
  el$bribe_b <- to_bin(el[[bc]])
  e2 <- el[el$arm %in% c("Local", "Central"), ]
  e2$local <- as.numeric(e2$arm == "Local")
  mb <- run("bribe_b ~ local | stratum", e2, "local")
  res$paid_bribe_endline_local_table5_panelB <- getc(mb, "local")
}, error = function(e) msg("endline fail", conditionMessage(e)))

# ---------------- Table 6: midline visits ----------------
tryCatch({
  ml <- rd(file.path(svy, "midline_noPII.dta"))
  cpl <- pick(names(ml), c("tot_complete", "complete"))
  if (!is.na(cpl)) { v <- num(ml[[cpl]]); if (any(v == 1, na.rm = TRUE)) ml <- ml[!is.na(v) & v == 1, ] }
  mid <- find_id(ml, reg)
  if (!is.na(mid)) {
    k <- match(as.character(ml[[mid]]), as.character(reg[[mid]]))
    ml$house_n <- reg$house_n[k]
    ml$a7r <- reg$a7[k]
  } else { ml$house_n <- NA; ml$a7r <- NA }
  meid <- pick(names(ml), c("a7", "polygon", "grid_nm"))
  ml$a7 <- if (!is.na(meid)) as.character(num(ml[[meid]])) else ml$a7r
  ml$a7[is.na(ml$a7)] <- ml$a7r[is.na(ml$a7)]
  if (all(is.na(ml$house_n)) && "house" %in% names(ml)) ml$house_n <- num(ml$house)
  ml$house_n[is.na(ml$house_n)] <- -1
  ml$arm <- nb$arm[match(ml$a7, nb$a7)]
  ml$stratum <- nb$stratum[match(ml$a7, nb$a7)]
  ml$period <- if (!is.null(per_lc)) unname(per_lc[ml$a7]) else NA
  vc <- pick(names(ml), c("visited", "visit"))
  msg("visited table:"); msg(capture.output(print(table(num(ml[[vc]]), useNA = "ifany"))))
  ml$visited_b <- to_bin(ml[[vc]])
  m6 <- ml[ml$arm %in% c("Local", "Central") & !is.na(ml$period), ]
  m6$local <- as.numeric(m6$arm == "Local")
  mv <- run("visited_b ~ local | house_n + stratum + period", m6, "local")
  res$visited_by_collector_local_table6_col1 <- getc(mv, "local")
}, error = function(e) msg("midline fail", conditionMessage(e)))

# ---------------- Table 8: chief ease-of-payment rating (CLI only) ----------------
tryCatch({
  ch <- rd(file.path(svy, "chief_consultations.dta"))
  cand <- names(ch)[grepl("ease|easy|facil|abil|capac", names(ch))]
  ec <- cand[1]
  cid <- find_id(ch, reg)
  msg("chief id:", cid, "ease var:", ec)
  x <- ch[[ec]]
  v <- num(x); v[!is.na(v) & v < 0] <- NA
  if (inherits(x, "haven_labelled")) {
    lab <- attr(x, "labels"); lab <- lab[lab >= 0]
    if (length(lab)) {
      top <- tolower(names(lab)[which.max(lab)])
      if (grepl("diffic|hard|unable|not|low|cannot|never", top)) v <- max(lab) + min(lab) - v
    }
  }
  ch$ease <- v
  chs <- ch %>% mutate(k = as.character(.data[[cid]])) %>% filter(!is.na(k)) %>%
    group_by(k) %>% summarise(ease = mean(ease, na.rm = TRUE), .groups = "drop")
  cl <- reg[reg$arm %in% "CLI", ]
  cl$ease <- chs$ease[match(as.character(cl[[cid]]), chs$k)]
  cl$house_n[is.na(cl$house_n)] <- -1
  m8 <- run("taxes_paid ~ ease | house_n + stratum", cl, "ease")
  res$compliance_ease_of_payment_cli_table8_panelA_col2 <- getc(m8, "ease")
}, error = function(e) msg("chief fail", conditionMessage(e)))

# ---------------- output ----------------
for (nm in names(res)) {
  v <- res[[nm]]
  if (length(v) == 1 && !is.na(v)) cat(sprintf("RESULT:%s=%s\n", nm, format(v, digits = 8)))
}