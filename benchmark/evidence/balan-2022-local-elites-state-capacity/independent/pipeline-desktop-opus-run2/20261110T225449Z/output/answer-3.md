suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)
options(warn = 1)

root <- file.path('<repo>/.cache/datasets/balan_2022_local_elites_state_capacity.script-free',
                  'Replication Materials - Updated October 2025', 'Data', '01_base')
rd <- function(p) haven::read_dta(file.path(root, p))

results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) results[[name]] <<- as.numeric(val)
}

num <- function(x) suppressWarnings(as.numeric(haven::zap_labels(x)))
chr <- function(x) trimws(as.character(haven::zap_labels(x)))
lab <- function(x) if (haven::is.labelled(x)) as.character(haven::as_factor(x)) else as.character(x)
showcols <- function(nm, d, maxn = 200) {
  n <- names(d)
  cat(sprintf('[cols] %s (%d rows, %d cols): %s%s\n', nm, nrow(d), length(n),
              paste(head(n, maxn), collapse = ', '), ifelse(length(n) > maxn, ' ...', '')))
}
pick <- function(d, cands) {
  n <- names(d)
  for (c in cands) if (c %in% n) return(c)
  for (c in cands) { m <- grep(paste0('^', c), n, value = TRUE); if (length(m)) return(m[1]) }
  NA_character_
}
to_bin <- function(x) {
  v <- num(x)
  v[!is.na(v) & v < 0] <- NA
  u <- sort(unique(na.omit(v)))
  if (length(u) == 0) return(v)
  if (all(u %in% c(0, 1))) return(v)
  if (all(u %in% c(1, 2))) return(ifelse(is.na(v), NA, ifelse(v == 1, 1, 0)))
  ifelse(is.na(v), NA, ifelse(v > 0, 1, 0))
}
# label-aware yes/no binarizer: yes = 1, no = 0, anything else (don't know, refuse, n/a) = NA
yesno <- function(x) {
  if (haven::is.labelled(x)) {
    lb <- attr(x, 'labels'); nm <- tolower(trimws(names(lb))); v <- num(x)
    yes <- lb[grepl('^(yes|oui)', nm)]
    no <- lb[grepl('^(no|non)($|[^a-z])', nm)]
    if (length(yes) && length(no)) return(ifelse(v %in% yes, 1, ifelse(v %in% no, 0, NA)))
  }
  to_bin(x)
}
nbc <- c('a7', 'polygon', 'neighborhood', 'nbhd', 'poly', 'grid_nm')
std_a7 <- function(d, nm) {
  k <- pick(d, nbc)
  if (is.na(k)) { cat(sprintf('[warn] no neighborhood key in %s\n', nm)); return(d) }
  if (k != 'a7') { d$a7 <- d[[k]] }
  d$a7 <- chr(d$a7)
  d
}
named_vec <- function(tb) setNames(as.numeric(tb), names(tb))

# ---------------- Neighborhood frame ----------------
nb <- rd('admin_data/tax_payments_neighborhoods.dta'); showcols('tax_payments_neighborhoods', nb)
ra <- rd('admin_data/randomization_assignment.dta'); showcols('randomization_assignment', ra)
nb <- std_a7(nb, 'nb'); ra <- std_a7(ra, 'ra')

map_arm <- function(x) {
  s <- tolower(lab(x)); out <- rep(NA_character_, length(s))
  set <- function(cond, v) out[is.na(out) & cond] <<- v
  set(grepl('cxl|central x local|central_x_local|centralxlocal|c x l|cxlocal', s), 'CXL')
  set(grepl('cli|info', s), 'CLI')
  set(grepl('control|declar', s), 'Control')
  set(grepl('local|chief', s), 'Local')
  set(grepl('central|state', s), 'Central')
  if (all(is.na(out))) {
    v <- num(x); tb <- sort(table(v))
    if (length(tb) == 5) {
      codes <- as.numeric(names(tb))
      out <- rep(NA_character_, length(v))
      out[v == codes[1]] <- 'Control'; out[v == codes[2]] <- 'CXL'; out[v == codes[3]] <- 'CLI'
      big <- sort(codes[4:5]); out[v == big[1]] <- 'Central'; out[v == big[2]] <- 'Local'
      cat('[warn] arm mapping via counts\n')
    }
  }
  out
}

tsrc <- if ('program' %in% names(nb)) nb$program else NULL
nb$arm <- if (!is.null(tsrc)) map_arm(tsrc) else NA
if (all(is.na(nb$arm)) || sum(!is.na(nb$arm)) < 300) {
  tcol <- pick(ra, c('treatment', 'treat', 'tmt'))
  nb$arm <- map_arm(ra[[tcol]])[match(nb$a7, ra$a7)]
}
cat('[arms nb]\n'); print(table(nb$arm, useNA = 'ifany'))
if (!('stratum' %in% names(nb))) nb$stratum <- ra$stratum[match(nb$a7, ra$a7)]
nb$stratum <- chr(nb$stratum)

to_day <- function(x) {
  if (inherits(x, 'Date')) return(as.numeric(x))
  if (inherits(x, 'POSIXt')) return(as.numeric(as.Date(x)))
  if (is.character(x)) {
    x <- trimws(x); best <- rep(NA_real_, length(x))
    for (f in c('%Y-%m-%d', '%d/%m/%Y', '%m/%d/%Y', '%b %d, %Y', '%d%b%Y', '%Y/%m/%d', '%d-%m-%Y')) {
      d <- suppressWarnings(as.numeric(as.Date(substr(x, 1, 30), format = f)))
      if (sum(!is.na(d)) > sum(!is.na(best))) best <- d
    }
    return(best)
  }
  v <- num(x)
  if (median(v, na.rm = TRUE) > 1e8) v <- v / 86400000
  v
}
nb$start_day <- if ('program_start' %in% names(nb)) to_day(nb$program_start) else NA
if (all(is.na(nb$start_day))) {
  rs <- tryCatch(rd('admin_data/randomization_schedule.dta'), error = function(e) NULL)
  if (!is.null(rs)) {
    showcols('randomization_schedule', rs); rs <- std_a7(rs, 'rs')
    dc <- names(rs)[sapply(rs, function(z) inherits(z, 'Date') || inherits(z, 'POSIXt'))]
    if (length(dc)) nb$start_day <- to_day(rs[[dc[1]]])[match(nb$a7, rs$a7)]
  }
}
cat('[start_day] summary:\n'); print(summary(nb$start_day))
unit_width <- if (median(nb$start_day, na.rm = TRUE) < 100) 2 else 61

nb_period <- function(arms) {
  s <- nb[nb$arm %in% arms & !is.na(nb$start_day), ]
  dA <- s$start_day[s$arm == arms[1]]; dB <- s$start_day[s$arm == arms[2]]
  st <- (min(dA) + min(dB)) / 2; en <- (max(dA) + max(dB)) / 2
  s <- s[s$start_day >= st & s$start_day <= en, ]
  s$period <- as.character(floor((s$start_day - st) / unit_width))
  cat(sprintf('[period %s] window %.1f-%.1f, nbhds kept %d\n', paste(arms, collapse = '/'), st, en, nrow(s)))
  print(table(s$period, s$arm))
  s[, c('a7', 'period')]
}

# ---------------- Property frame ----------------
tr <- rd('admin_data/taxroll_noPII.dta'); showcols('taxroll', tr)
reg <- rd('admin_data/registration_noPII.dta'); showcols('registration', reg)
pay <- rd('admin_data/tax_payments_noPII.dta'); showcols('tax_payments', pay)
tr <- std_a7(tr, 'taxroll'); reg <- std_a7(reg, 'registration'); pay <- std_a7(pay, 'payments')
if ('pilot' %in% names(reg)) reg <- reg[is.na(num(reg$pilot)) | num(reg$pilot) != 1, ]

# ---- Fill missing neighborhood campaign start dates, only from a date source that actually tracks program_start ----
tryCatch({
  per_a7 <- function(a7v, dv) {
    md <- median(dv, na.rm = TRUE); dv[!is.na(dv) & abs(dv - md) > 400] <- NA
    s <- tapply(dv, a7v, function(z) if (all(is.na(z))) NA_real_ else min(z, na.rm = TRUE))
    s <- named_vec(s)
    as.numeric(s[nb$a7])
  }
  srcs <- list()
  for (dc in c('TDM', 'date', 'endOfCollect')) if (dc %in% names(pay)) {
    dd <- tryCatch(to_day(pay[[dc]]), error = function(e) NULL)
    if (!is.null(dd) && is.numeric(dd) && sum(!is.na(dd)) > 0.3 * nrow(pay)) srcs[[paste0('pay_', dc)]] <- per_a7(pay$a7, dd)
  }
  for (dc in c('today', 'date', 'start', 'end', 'date_f')) if (dc %in% names(reg)) {
    dd <- tryCatch(to_day(reg[[dc]]), error = function(e) NULL)
    if (!is.null(dd) && is.numeric(dd) && sum(!is.na(dd)) > 0.3 * nrow(reg)) srcs[[paste0('reg_', dc)]] <- per_a7(reg$a7, dd)
  }
  best <- NULL; bc <- 0.6
  for (s in names(srcs)) {
    v <- srcs[[s]]; ov <- !is.na(nb$start_day) & !is.na(v)
    cr <- NA_real_; sr <- NA_real_
    if (sum(ov) >= 10 && sd(v[ov]) > 0) { cr <- cor(nb$start_day[ov], v[ov]); sr <- sd(v[ov]) / sd(nb$start_day[ov]) }
    cat(sprintf('[start src] %s: overlap %d, cor %.3f, sd ratio %.3f, covers missing %d\n', s, sum(ov), cr, sr,
                sum(is.na(nb$start_day) & !is.na(v))))
    if (!is.na(cr) && cr > bc && !is.na(sr) && sr > 0.5 && sr < 2 && any(is.na(nb$start_day) & !is.na(v))) { bc <- cr; best <- s }
  }
  if (!is.null(best)) {
    v <- srcs[[best]]; ov <- !is.na(nb$start_day) & !is.na(v)
    off <- median(nb$start_day[ov] - v[ov])
    fill <- is.na(nb$start_day) & !is.na(v)
    nb$start_day[fill] <- v[fill] + off
    cat(sprintf('[start fill] source %s, cor %.3f, offset %.1f, filled %d, still missing %d\n', best, bc, off,
                sum(fill), sum(is.na(nb$start_day))))
    if (any(fill)) cat(sprintf('DEVIATION: Neighborhood campaign start dates missing in program_start were filled from %s (first date in the neighborhood, shifted by the median offset; cor %.2f with program_start) to build the 2-month campaign-wave FE\n', best, bc))
    print(table(nb$arm, is.na(nb$start_day)))
    unit_width <- if (median(nb$start_day, na.rm = TRUE) < 100) 2 else 61
  } else cat('[start fill] no date source tracks program_start; leaving missing start dates unfilled\n')
}, error = function(e) cat('[err] start fill:', conditionMessage(e), '\n'))

find_key <- function(a, b) {
  ex <- c('a7', 'stratum', 'commune', 'treatment', 'house', 'exempt', 'status', 'time', 'pilot', 'rate',
          'paid', 'amount', 'month', 'first', 'present', 'tot_complete', 'date', 'today', 'rate_assigned')
  common <- setdiff(intersect(names(a), names(b)), ex)
  best <- NULL; bs <- 0
  for (k in common) for (comb in c(FALSE, TRUE)) {
    if (comb && !('a7' %in% names(a) && 'a7' %in% names(b))) next
    va <- chr(a[[k]]); vb <- chr(b[[k]])
    ok <- !is.na(va) & va != '' & va != 'NA'
    if (sum(ok) < 0.5 * nrow(a)) next
    ka <- if (comb) paste(a$a7, va) else va
    kb <- if (comb) paste(b$a7, vb) else vb
    uq <- length(unique(ka[ok])) / sum(ok)
    if (uq < 0.9) next
    ov <- mean(kb %in% ka[ok])
    if (ov > bs + 0.01) { bs <- ov; best <- list(k = k, comb = comb, ov = ov) }
  }
  if (!is.null(best)) cat(sprintf('[key] %s comb=%s overlap=%.3f\n', best$k, best$comb, bs)) else cat('[key] none found\n')
  best
}
mk <- function(d, key) if (key$comb) paste(d$a7, chr(d[[key$k]])) else chr(d[[key$k]])

base <- if ('a7' %in% names(tr) && nrow(tr) > 30000) tr else reg
other <- if (identical(base, tr)) reg else tr
cat(sprintf('[base] using %s\n', if (identical(base, tr)) 'taxroll' else 'registration'))
bk <- find_key(base, other)
if (!is.null(bk)) {
  base$.k <- mk(base, bk); other$.k <- mk(other, bk)
  other <- other[!duplicated(other$.k), ]
  for (v in c('house', 'exempt')) if (!(v %in% names(base)) && v %in% names(other)) base[[v]] <- other[[v]][match(base$.k, other$.k)]
}

pk <- find_key(base, pay)
amtc <- pick(pay, c('amount', 'amt', 'amount_paid', 'amt_paid', 'montant', 'paid_amount', 'tax_amount'))
if (!is.null(pk) && pk$ov > 0.5) {
  base$.pk <- mk(base, pk); pay$.pk <- mk(pay, pk)
  cat(sprintf('[base] duplicated payment keys in base: %d\n', sum(duplicated(base$.pk))))
  # ---- Calibrate payment-record filters and the amount definition against the authors' neighborhood aggregates ----
  tgt_paid <- if ('paid' %in% names(nb)) num(nb$paid) else rep(NA_real_, nrow(nb))
  if (any(!is.na(tgt_paid)) && max(tgt_paid, na.rm = TRUE) <= 1 && 'hh_final' %in% names(nb)) tgt_paid <- tgt_paid * num(nb$hh_final)
  tgt_amt <- if ('amount' %in% names(nb)) num(nb$amount) else rep(NA_real_, nrow(nb))
  okflag <- function(v) { x <- num(pay[[v]]); is.na(x) | x != 1 }
  flags <- list(all = rep(TRUE, nrow(pay)))
  if ('dup_receipt' %in% names(pay)) flags$nodup <- okflag('dup_receipt')
  if ('lateCollection' %in% names(pay)) flags$nolate <- okflag('lateCollection')
  if ('mult_tax' %in% names(pay)) flags$nomult <- okflag('mult_tax')
  if ('unmatched_compound' %in% names(pay)) flags$matched <- okflag('unmatched_compound')
  if ('paid' %in% names(pay)) {
    x <- num(pay$paid)
    if (any(x == 1, na.rm = TRUE) && any(x != 1 | is.na(x))) flags$paidflag <- !is.na(x) & x == 1
  }
  bf <- setdiff(names(flags), 'all')
  if (length(bf) >= 2) for (i in seq_along(bf)) for (j in seq_along(bf)) if (i < j)
    flags[[paste(bf[i], bf[j], sep = '+')]] <- flags[[bf[i]]] & flags[[bf[j]]]
  if (length(bf) > 2) flags[['allflags']] <- Reduce(`&`, flags[bf])
  ok_t <- !is.na(tgt_paid)
  score_paid <- sapply(names(flags), function(f) {
    s <- flags[[f]]
    if (!any(s) || !any(ok_t)) return(NA_real_)
    cnt <- named_vec(tapply(pay$.pk[s], pay$a7[s], function(z) length(unique(z))))
    our <- as.numeric(cnt[nb$a7]); our[is.na(our)] <- 0
    sum(abs(our[ok_t] - tgt_paid[ok_t]))
  })
  cat('[pay filter scores vs nb$paid]\n'); print(score_paid)
  best_f <- if (all(is.na(score_paid))) 'all' else names(score_paid)[which.min(score_paid)]
  if (!is.na(score_paid['all']) && !is.na(score_paid[best_f]) && score_paid[best_f] >= score_paid['all']) best_f <- 'all'
  fsel <- flags[[best_f]]
  cat(sprintf('[pay] chosen record filter: %s (%d of %d records)\n', best_f, sum(fsel), nrow(pay)))
  if (best_f != 'all') cat(sprintf('DEVIATION: Payment records filtered (%s) so that neighborhood payer counts match the authors\' neighborhood file\n', best_f))

  amt_cols <- grep('^amount', names(pay), value = TRUE)
  if (!length(amt_cols) && !is.na(amtc)) amt_cols <- amtc
  opts <- list()
  for (ac in amt_cols) for (ag in c('max', 'sum')) opts[[paste(ac, ag)]] <- list(ac = ac, ag = ag)
  ok_a <- !is.na(tgt_amt) & tgt_amt > 0
  per_prop <- function(o) {
    x <- num(pay[[o$ac]]); s <- fsel & !is.na(x)
    pp <- named_vec(tapply(x[s], pay$.pk[s], if (o$ag == 'max') max else sum))
    pp
  }
  score_amt <- sapply(opts, function(o) {
    if (!any(ok_a)) return(NA_real_)
    pp <- per_prop(o)
    if (!length(pp)) return(NA_real_)
    s <- fsel
    pa7 <- pay$a7[s][match(names(pp), pay$.pk[s])]
    tot <- named_vec(tapply(pp, pa7, sum))
    our <- as.numeric(tot[nb$a7]); our[is.na(our)] <- 0
    cat(sprintf('[amt option] %s %s: total ratio ours/nb %.3f\n', o$ac, o$ag, sum(our[ok_a]) / sum(tgt_amt[ok_a])))
    median(abs(log((our[ok_a] + 1) / (tgt_amt[ok_a] + 1))))
  })
  cat('[amount scores vs nb$amount]\n'); print(score_amt)
  if (length(opts) == 0) {
    pay$.amt <- 1; best_o <- list(ac = NA, ag = 'max')
  } else {
    best_o <- if (all(is.na(score_amt))) opts[[1]] else opts[[which.min(score_amt)]]
    pay$.amt <- num(pay[[best_o$ac]])
  }
  cat(sprintf('[pay] amount column: %s (%s per property)\n', best_o$ac, best_o$ag))
  # convert to CF if the best-matching amount is in USD
  if (!is.na(best_o$ac) && grepl('usd', tolower(best_o$ac))) {
    cfc <- grep('cf', amt_cols, value = TRUE, ignore.case = TRUE)
    if (length(cfc)) {
      a <- num(pay[[cfc[1]]]); b <- num(pay[[best_o$ac]]); okr <- !is.na(a) & !is.na(b) & a > 0 & b > 0
      fx <- median(a[okr] / b[okr]); pay$.amt <- pay$.amt * fx
      cat(sprintf('DEVIATION: Revenue built from %s (best match to the neighborhood file) converted to CF at the median receipt rate %.1f\n', best_o$ac, fx))
    }
  }
  print(quantile(pay$.amt[fsel], c(0, .01, .1, .25, .5, .75, .9, .99, .999, 1), na.rm = TRUE))
  ps <- pay[fsel, ]
  agg <- ps %>% group_by(.pk) %>%
    summarise(amt = if (all(is.na(.amt))) 0 else if (best_o$ag == 'max') max(.amt, na.rm = TRUE) else sum(.amt, na.rm = TRUE),
              anypay = any(is.na(.amt) | .amt > 0), .groups = 'drop')
  base$revenue <- agg$amt[match(base$.pk, agg$.pk)]
  base$revenue[is.na(base$revenue)] <- 0
  base$paid <- as.numeric(base$.pk %in% agg$.pk[agg$anypay])
} else {
  pc <- pick(base, c('taxes_paid', 'paid', 'paid_tax', 'tax_paid'))
  ac <- pick(base, c('taxes_paid_amt', 'amount', 'amt_paid', 'amount_paid'))
  base$paid <- to_bin(base[[pc]]); base$paid[is.na(base$paid)] <- 0
  base$revenue <- if (!is.na(ac)) num(base[[ac]]) else NA
  base$revenue[is.na(base$revenue)] <- 0
}

hl <- tolower(lab(base$house))
cat('[house]\n'); print(table(hl, useNA = 'ifany'))
if (any(grepl('villa', hl))) {
  base <- base[!grepl('villa', hl), ]
} else {
  tb <- table(num(base$house))
  if (length(tb) == 3 && min(tb) >= 150 && min(tb) <= 500) base <- base[num(base$house) != as.numeric(names(tb)[which.min(tb)]), ]
}
base$house_f <- chr(base$house)
base$exempt01 <- if ('exempt' %in% names(base)) to_bin(base$exempt) else 0
base$exempt01[is.na(base$exempt01)] <- 0

base <- base %>% inner_join(nb[, c('a7', 'arm', 'stratum')], by = 'a7')
cat('[base arms]\n'); print(table(base$arm, useNA = 'ifany'))
cat(sprintf('[base] paid mean by arm:\n')); print(tapply(base$paid, base$arm, mean))
print(tapply(base$revenue, base$arm, mean))
cat('[base] mean payment among payers by arm:\n'); print(tapply(base$revenue[base$paid == 1], base$arm[base$paid == 1], mean))

reg_coef <- function(fml, data, var) {
  m <- feols(fml, data = data, cluster = ~a7)
  print(summary(m))
  list(b = unname(coef(m)[var]), n = nobs(m))
}

# ---------------- Table 4 ----------------
d4 <- base[base$arm %in% c('Local', 'Central'), ]
d4$local <- as.numeric(d4$arm == 'Local')
tryCatch({
  r <- reg_coef(paid ~ local | stratum, d4, 'local')
  emit('compliance_local_table4_panelA_col1', r$b); emit('n_obs_table4_col1', r$n)
}, error = function(e) cat('[err] col1:', conditionMessage(e), '\n'))

p_lc <- tryCatch(nb_period(c('Local', 'Central')), error = function(e) { cat('[err] period:', conditionMessage(e), '\n'); NULL })
if (!is.null(p_lc)) {
  d4p <- inner_join(d4, p_lc, by = 'a7')
  tryCatch({
    r <- reg_coef(paid ~ local | stratum + period, d4p, 'local')
    emit('compliance_local_table4_panelA_col2', r$b); emit('n_obs_table4_col2', r$n)
  }, error = function(e) cat('[err] col2:', conditionMessage(e), '\n'))
  tryCatch(emit('compliance_local_house_fe_table4_panelA_col4',
                reg_coef(paid ~ local | stratum + period + house_f, d4p, 'local')$b),
           error = function(e) cat('[err] col4:', conditionMessage(e), '\n'))
  tryCatch(emit('compliance_local_exempt_excluded_table4_panelA_col5',
                reg_coef(paid ~ local | stratum + period + house_f, d4p[d4p$exempt01 == 0, ], 'local')$b),
           error = function(e) cat('[err] col5:', conditionMessage(e), '\n'))
  tryCatch(emit('revenue_local_table4_panelB_col2',
                reg_coef(revenue ~ local | stratum + period, d4p, 'local')$b),
           error = function(e) cat('[err] rev col2:', conditionMessage(e), '\n'))
  tryCatch(emit('revenue_local_house_fe_table4_panelB_col4',
                reg_coef(revenue ~ local | stratum + period + house_f, d4p, 'local')$b),
           error = function(e) cat('[err] rev col4:', conditionMessage(e), '\n'))
}

# ---------------- Table 7: CLI vs Central ----------------
tryCatch({
  p_cc <- nb_period(c('CLI', 'Central'))
  d7 <- base[base$arm %in% c('CLI', 'Central'), ] %>% inner_join(p_cc, by = 'a7')
  d7$cli <- as.numeric(d7$arm == 'CLI')
  emit('compliance_cli_table7_col1', reg_coef(paid ~ cli | stratum + period + house_f, d7, 'cli')$b)
  emit('revenue_cli_table7_col2', reg_coef(revenue ~ cli | stratum + period + house_f, d7, 'cli')$b)
}, error = function(e) cat('[err] table7:', conditionMessage(e), '\n'))

# ---------------- Table 8: ease of payment within CLI ----------------
tryCatch({
  cc <- rd('survey_data/chief_consultations.dta'); showcols('chief_consultations', cc)
  cc <- std_a7(cc, 'chief_consultations')
  ec <- grep('ease|easy', names(cc), value = TRUE, ignore.case = TRUE)
  if (!length(ec)) ec <- grep('abil|capac|facil|wtp|pay', names(cc), value = TRUE, ignore.case = TRUE)
  cat('[ease candidates]', paste(ec, collapse = ', '), '\n')
  ecol <- ec[1]
  ev <- num(cc[[ecol]]); ev[!is.na(ev) & ev < 0] <- NA
  if (haven::is.labelled(cc[[ecol]])) {
    lb <- attr(cc[[ecol]], 'labels'); cat('[ease labels]\n'); print(lb)
    mx <- max(ev, na.rm = TRUE); ml <- tolower(names(lb)[lb == mx])
    if (length(ml) && grepl('diffic|hard|unable|not|low', ml[1])) ev <- (max(ev, na.rm = TRUE) + min(ev, na.rm = TRUE)) - ev
  }
  cc$ease <- ev
  ck <- find_key(base, cc)
  b8 <- base[base$arm == 'CLI', ]
  b8$.ck <- mk(b8, ck); cc$.ck <- mk(cc, ck)
  cc <- cc[!is.na(cc$ease) & !duplicated(cc$.ck), ]
  b8$ease <- cc$ease[match(b8$.ck, cc$.ck)]
  cat(sprintf('[table8] CLI props %d, with ease %d\n', nrow(b8), sum(!is.na(b8$ease))))
  emit('compliance_ease_of_payment_cli_table8_panelA_col2', reg_coef(paid ~ ease | house_f + stratum, b8, 'ease')$b)
}, error = function(e) cat('[err] table8:', conditionMessage(e), '\n'))

# ---------------- Table 6: visited (midline) ----------------
tryCatch({
  ml <- rd('survey_data/midline_noPII.dta'); showcols('midline', ml)
  ml <- std_a7(ml, 'midline')
  vc <- pick(ml, c('visited', 'visit_post', 'visited_post'))
  ml$visited01 <- to_bin(ml[[vc]])
  if ('tot_complete' %in% names(ml)) { tc <- num(ml$tot_complete); if (mean(tc == 1, na.rm = TRUE) > 0.5) ml <- ml[!is.na(tc) & tc == 1, ] }
  mk6 <- find_key(base, ml)
  if (!is.null(mk6) && mk6$ov > 0.5) {
    base$.mk <- mk(base, mk6); ml$.mk <- mk(ml, mk6)
    ml$house_f <- base$house_f[match(ml$.mk, base$.mk)]
  }
  if (!('house_f' %in% names(ml)) || all(is.na(ml$house_f))) ml$house_f <- if ('house' %in% names(ml)) chr(ml$house) else '1'
  ml <- ml[, c('a7', 'visited01', 'house_f')] %>% inner_join(nb[, c('a7', 'arm', 'stratum')], by = 'a7') %>%
    filter(arm %in% c('Local', 'Central')) %>% inner_join(p_lc, by = 'a7')
  ml$local <- as.numeric(ml$arm == 'Local')
  emit('visited_by_collector_local_table6_col1', reg_coef(visited01 ~ local | house_f + stratum + period, ml, 'local')$b)
  rm(ml); invisible(gc())
}, error = function(e) cat('[err] table6:', conditionMessage(e), '\n'))

# ---------------- Table 5: paid bribe (endline) ----------------
bribe_from <- function(e) {
  bc <- grep('bribe', names(e), value = TRUE, ignore.case = TRUE)
  # 1) a direct yes/no bribe question
  for (b in bc) {
    if (grepl('amt|amount|freq|who|why|other|_t$|when|where', b, ignore.case = TRUE)) next
    y <- yesno(e[[b]])
    if (sum(!is.na(y)) > 0.3 * nrow(e)) return(list(v = y, src = b))
  }
  # 2) frequency / amount questions: paid any bribe = 1
  fc <- grep('freq', bc, value = TRUE); acn <- grep('amt|amount', bc, value = TRUE)
  if (length(fc) || length(acn)) {
    out <- rep(NA_real_, nrow(e))
    for (f in fc) {
      x <- e[[f]]; v <- num(x); v[!is.na(v) & v < 0] <- NA
      zero <- 0
      if (haven::is.labelled(x)) {
        lb <- attr(x, 'labels'); nmv <- tolower(names(lb))
        z <- lb[grepl('never|jamais|aucun|none|^no|^non|^0', nmv)]
        if (length(z)) zero <- as.numeric(z)
      }
      ind <- ifelse(is.na(v), NA, ifelse(v %in% zero, 0, 1))
      if (!haven::is.labelled(x)) ind <- ifelse(is.na(v), NA, ifelse(v > 0, 1, 0))
      out <- ifelse(is.na(out), ind, pmax(out, ind))
    }
    for (a in acn) {
      v <- num(e[[a]]); v[!is.na(v) & v < 0] <- NA
      ind <- ifelse(is.na(v), NA, ifelse(v > 0, 1, 0))
      out <- ifelse(is.na(out), ind, pmax(out, ind))
    }
    cov <- mean(!is.na(out))
    cat(sprintf('[bribe] from %s; coverage %.3f\n', paste(c(fc, acn), collapse = ','), cov))
    if (cov < 0.5) {
      out[is.na(out)] <- 0
      cat('DEVIATION: Bribe follow-up questions are asked only of bribe payers; non-respondents to them coded as not having paid a bribe\n')
    }
    return(list(v = out, src = paste(c(fc, acn), collapse = ',')))
  }
  if ('transport' %in% names(e)) return(list(v = yesno(e$transport), src = 'transport'))
  NULL
}
tryCatch({
  rds <- list()
  for (f in c('survey_data/endline_round1_noPII.dta', 'survey_data/endline_round2_noPII.dta')) {
    e <- tryCatch(rd(f), error = function(err) NULL)
    if (is.null(e)) next
    cat(sprintf('[endline %s] rows %d; a7-like: %s; bribe-like: %s\n', f, nrow(e),
                paste(grep('^a7|polygon|neigh', names(e), value = TRUE), collapse = ','),
                paste(grep('transport|bribe', names(e), value = TRUE), collapse = ',')))
    e <- std_a7(e, f)
    if (!('a7' %in% names(e))) next
    if ('tot_complete' %in% names(e)) { tc <- num(e$tot_complete); if (mean(tc == 1, na.rm = TRUE) > 0.5) e <- e[!is.na(tc) & tc == 1, ] }
    bb <- bribe_from(e)
    if (is.null(bb)) next
    cat(sprintf('[endline %s] bribe source: %s, mean %.4f, n %d\n', f, bb$src, mean(bb$v, na.rm = TRUE), sum(!is.na(bb$v))))
    rds[[f]] <- data.frame(a7 = e$a7, bribe = bb$v, stringsAsFactors = FALSE)
  }
  en <- bind_rows(rds) %>% inner_join(nb[, c('a7', 'arm', 'stratum')], by = 'a7') %>% filter(arm %in% c('Local', 'Central'))
  en$local <- as.numeric(en$arm == 'Local')
  cat(sprintf('[endline] n=%d, bribe mean=%.4f\n', sum(!is.na(en$bribe)), mean(en$bribe, na.rm = TRUE)))
  emit('paid_bribe_endline_local_table5_panelB', reg_coef(bribe ~ local | stratum, en, 'local')$b)
}, error = function(e) cat('[err] table5:', conditionMessage(e), '\n'))

# ---------------- Output ----------------
for (nm in names(results)) cat(sprintf('RESULT:%s=%s\n', nm, format(results[[nm]], digits = 10)))
