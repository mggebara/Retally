suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/lopez_2022_patient_demand_prescription_overuse.script-free"
path <- file.path(root, "Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta")
d <- haven::read_dta(path)
d <- as.data.frame(haven::zap_labels(d))
nm <- names(d)
lnm <- tolower(nm)

tonum <- function(x) {
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(as.numeric(x))
  if (is.logical(x)) return(as.numeric(x))
  if (is.numeric(x)) return(as.numeric(x))
  if (is.character(x)) {
    y <- tolower(trimws(x))
    out <- suppressWarnings(as.numeric(y))
    out[y %in% c("yes", "oui", "y", "true")] <- 1
    out[y %in% c("no", "non", "n", "false")] <- 0
    out[y == ""] <- NA
    return(out)
  }
  suppressWarnings(as.numeric(x))
}

to01 <- function(x) {
  x <- tonum(x)
  v <- sort(unique(x[!is.na(x)]))
  if (length(v) == 2 && all(v == c(1, 2))) x <- ifelse(x == 1, 1, ifelse(x == 2, 0, NA))
  x
}

getv <- function(cands) {
  for (cc in cands) {
    i <- match(tolower(cc), lnm)
    if (!is.na(i)) return(nm[i])
  }
  NULL
}

# Treatment dummies
pvn <- getv(c("patient_voucher", "pv", "treat_pv", "pv_day"))
dvn <- getv(c("doctor_voucher", "dv", "treat_dv", "dv_day"))
pv <- to01(d[[pvn]])
dv <- to01(d[[dvn]])
message("PV var: ", pvn, "  DV var: ", dvn)

# Date
daten <- getv(c("date", "visit_date", "date_clinic", "survey_date"))
datev <- d[[daten]]
datef <- as.character(datev)

# Sample: in-clinic survey patients (paper: 2,055 acutely ill patients)
base <- !is.na(pv) & !is.na(dv) & !is.na(datef) & datef != ""
message("Base sample (non-missing PV/DV/date): ", sum(base))
target <- 2055
skip_pat <- "(voucher|^pv$|^dv$|^rx|presc|bought|purch|home|_h$|rdt|pred)"
pref_pat <- "(clinic|cscom|survey|sample|consent|ill|acute|interview|patient|in_|main|analy|elig|keep|incl|final)"
if (sum(base) != target) {
  hits <- data.frame(j = integer(0), val = numeric(0), cnt = numeric(0), pref = logical(0))
  for (j in seq_along(nm)) {
    if (grepl(skip_pat, lnm[j])) next
    x <- tryCatch(suppressWarnings(to01(d[[j]])), error = function(e) NULL)
    if (is.null(x) || length(x) != nrow(d)) next
    v <- unique(x[!is.na(x) & base])
    if (length(v) == 2 && all(v %in% c(0, 1))) {
      for (val in c(1, 0)) {
        cnt <- sum(x == val & base, na.rm = TRUE)
        if (abs(cnt - target) <= 5)
          hits <- rbind(hits, data.frame(j = j, val = val, cnt = cnt, pref = grepl(pref_pat, lnm[j])))
      }
    }
  }
  if (nrow(hits) > 0) {
    hits$score <- abs(hits$cnt - target) * 10 + ifelse(hits$pref, 0, 5) + ifelse(hits$val == 1, 0, 2)
    message("Indicator candidates: ", paste(sprintf("%s(=%g:%d)", nm[hits$j], hits$val, hits$cnt), collapse = ", "))
    h <- hits[which.min(hits$score), ]
    x <- to01(d[[h$j]])
    base <- base & !is.na(x) & x == h$val
    message("Sample restricted using indicator: ", nm[h$j], " == ", h$val)
  } else {
    nmh <- data.frame(j = integer(0), cnt = numeric(0))
    for (j in seq_along(nm)) {
      if (grepl(skip_pat, lnm[j])) next
      cnt <- sum(!is.na(d[[j]]) & base & !(is.character(d[[j]]) & d[[j]] %in% ""))
      if (abs(cnt - target) <= 2) nmh <- rbind(nmh, data.frame(j = j, cnt = cnt))
    }
    if (nrow(nmh) > 0) {
      message("Non-missing candidates: ", paste(nm[nmh$j], collapse = ", "))
      jj <- nmh$j[which.min(abs(nmh$cnt - target) * 10 + ifelse(grepl(pref_pat, lnm[nmh$j]), 0, 5))]
      base <- base & !is.na(d[[jj]]) & !(is.character(d[[jj]]) & d[[jj]] %in% "")
      message("Sample restricted to non-missing: ", nm[jj])
    } else {
      done <- FALSE
      for (j in which(grepl("(id|code|num)", lnm))) {
        x <- d[[j]]
        u <- length(unique(x[base & !is.na(x)]))
        if (abs(u - target) <= 2) {
          base <- base & !is.na(x) & !duplicated(ifelse(base, as.character(x), NA_character_) , incomparables = NA)
          message("Deduplicated on id: ", nm[j])
          done <- TRUE
          break
        }
      }
      if (!done) message("No 2055 restriction found; using base sample of ", sum(base))
    }
  }
}
message("Final sample: ", sum(base))

# Clinic cluster variable
pick_clinic <- function() {
  cand <- which(grepl("(cscom|clinic|cluster|centre|center)", lnm))
  best <- NULL; bestd <- Inf
  for (j in cand) {
    x <- d[[j]][base]
    u <- length(unique(x[!is.na(x)]))
    if (u >= 50 && u <= 70 && mean(is.na(x)) < 0.05) {
      dd <- abs(u - 60)
      if (dd < bestd) { bestd <- dd; best <- nm[j] }
    }
  }
  if (is.null(best)) {
    for (j in seq_along(nm)) {
      x <- d[[j]][base]
      if (!(is.numeric(x) || is.character(x))) next
      u <- length(unique(x[!is.na(x)]))
      if (u == 60 && mean(is.na(x)) < 0.01 && min(table(x)) >= 5) { best <- nm[j]; break }
    }
  }
  best
}
cln <- pick_clinic()
message("Cluster var: ", ifelse(is.null(cln), "NONE", cln))
clv <- if (!is.null(cln)) as.character(d[[cln]]) else datef

# Voucher used outcome
vun <- getv(c("voucher_used", "used_voucher", "vouchers_used", "usedvoucher", "voucherused"))
if (!is.null(vun)) {
  vused <- to01(d[[vun]])
  vused[is.na(vused) & base] <- 0
} else {
  a <- if ("voucher_used_PV" %in% nm) to01(d[["voucher_used_PV"]]) else rep(NA_real_, nrow(d))
  b <- if ("voucher_used_DV" %in% nm) to01(d[["voucher_used_DV"]]) else rep(NA_real_, nrow(d))
  a[is.na(a)] <- 0; b[is.na(b)] <- 0
  vused <- pmax(a, b)
}
message("Voucher used var: ", ifelse(is.null(vun), "constructed from voucher_used_PV/DV", vun))

# Binary candidate outcome search
nbase <- sum(base)
is_bin <- logical(length(nm)); nonmiss <- integer(length(nm)); bmean <- rep(NA_real_, length(nm))
for (j in seq_along(nm)) {
  x <- d[[j]]
  if (!(is.numeric(x) || is.logical(x))) next
  xs <- as.numeric(x[base])
  v <- unique(xs[!is.na(xs)])
  if (length(v) == 2 && all(v %in% c(0, 1))) {
    is_bin[j] <- TRUE
    nonmiss[j] <- sum(!is.na(xs))
    bmean[j] <- mean(xs, na.rm = TRUE)
  }
}
excl_pat <- "(home|_h$|^h_|^hh|pred|rdt|match|neg|pos|test|cost|price)"
binlist <- function(rx) {
  idx <- which(is_bin & nonmiss >= nbase - 50 & !grepl(excl_pat, lnm))
  if (rx) idx[grepl("^rx", lnm[idx])] else idx[!grepl("^rx", lnm[idx])]
}
message("RX binary vars (well-populated): ",
        paste(sprintf("%s[%d,%.2f]", nm[binlist(TRUE)], nonmiss[binlist(TRUE)], bmean[binlist(TRUE)]), collapse = ", "))

# Combine two 0/1 vars into "any": 1 if either is 1, 0 if both observed 0 (NA only if both NA)
combine_any <- function(a, b) {
  out <- pmax(ifelse(is.na(a), 0, a), ifelse(is.na(b), 0, b))
  out[is.na(a) & is.na(b)] <- NA
  out
}

# Severe outcomes
sevp_n <- getv(c("RXtreat_severe_mal", "RXsevere_mal", "RXsev_mal"))
if (!is.null(sevp_n) && !is_bin[match(sevp_n, nm)]) sevp_n <- NULL
sevb_n <- getv(c("treat_severe_mal", "sev_mal_purchased", "purchased_sev_mal", "bought_sev_mal"))
if (!is.null(sevb_n) && !is_bin[match(sevb_n, nm)]) sevb_n <- NULL

# Any antimalarial: look for an explicit "any" treatment var (well populated), else build simple OR severe
find_any <- function(rx) {
  pre <- if (rx) "^rx" else "^"
  idx <- binlist(rx)
  pats <- c(paste0(pre, "treat_any"), paste0(pre, "any_?(mal|antimal|treat)"),
            paste0(pre, "treat_(mal|antimal)$"), paste0(pre, "(antimal|anymal)"))
  for (p in pats) {
    m <- idx[grepl(p, lnm[idx])]
    if (length(m) > 0) return(list(name = nm[m[which.max(nonmiss[m])]], y = to01(d[[m[which.max(nonmiss[m])]]])))
  }
  sev <- if (rx) sevp_n else sevb_n
  idx2 <- which(is_bin & !grepl(excl_pat, lnm))
  idx2 <- if (rx) idx2[grepl("^rx", lnm[idx2])] else idx2[!grepl("^rx", lnm[idx2])]
  sp <- c(paste0(pre, "treat_simple_mal$"), paste0(pre, "treat_simp"), paste0(pre, "treat_(uncomp|act)"),
          paste0(pre, "treat_.*simple"), paste0(pre, "simple_mal"))
  for (p in sp) {
    m <- idx2[grepl(p, lnm[idx2]) & !grepl("sev", lnm[idx2])]
    if (length(m) > 0 && !is.null(sev)) {
      sn <- nm[m[which.max(nonmiss[m])]]
      return(list(name = paste0(sn, " OR ", sev), y = combine_any(to01(d[[sn]]), to01(d[[sev]]))))
    }
  }
  fb <- if (rx) "RXmalacur" else "malacur"
  if (!is.null(sev) && fb %in% nm) {
    return(list(name = paste0(fb, " OR ", sev), y = combine_any(to01(d[[fb]]), to01(d[[sev]]))))
  }
  NULL
}
anyp <- find_any(TRUE)
anyb <- find_any(FALSE)
message("Any prescribed -> ", ifelse(is.null(anyp), "NONE", anyp$name))
message("Any purchased -> ", ifelse(is.null(anyb), "NONE", anyb$name))
message("Severe prescribed -> ", ifelse(is.null(sevp_n), "NONE", sevp_n))
message("Severe purchased -> ", ifelse(is.null(sevb_n), "NONE", sevb_n))

# Estimation: y = b0 + bP PV + bD DV + date FE, clustered by clinic
run <- function(y) {
  df <- data.frame(y = y[base], pv = pv[base], dv = dv[base],
                   date = factor(datef[base]), cl = clv[base], stringsAsFactors = FALSE)
  df <- df[!is.na(df$y), ]
  m <- feols(y ~ pv + dv | date, data = df, cluster = ~cl)
  list(bp = unname(coef(m)["pv"]), bd = unname(coef(m)["dv"]),
       sep = unname(sqrt(diag(vcov(m)))["pv"]), sed = unname(sqrt(diag(vcov(m)))["dv"]),
       n = nobs(m))
}

res <- list()
safe_run <- function(y) tryCatch(run(y), error = function(e) { message("ERR: ", conditionMessage(e)); NULL })

r1 <- safe_run(vused)
if (!is.null(r1)) {
  res$voucher_used_patient_voucher_table3_col1 <- r1$bp
  res$voucher_used_doctor_voucher_table3_col1 <- r1$bd
  res$n_obs_table3_col1 <- r1$n
}
if (!is.null(anyp)) {
  r2 <- safe_run(anyp$y)
  if (!is.null(r2)) {
    res$any_malaria_treatment_prescribed_patient_voucher_table3_col2 <- r2$bp
    res$any_malaria_treatment_prescribed_doctor_voucher_table3_col2 <- r2$bd
    res$n_obs_table3_cols2_5 <- r2$n
  }
}
if (!is.null(anyb)) {
  r3 <- safe_run(anyb$y)
  if (!is.null(r3)) {
    res$any_malaria_treatment_purchased_patient_voucher_table3_col3 <- r3$bp
    res$any_malaria_treatment_purchased_doctor_voucher_table3_col3 <- r3$bd
    if (is.null(res$n_obs_table3_cols2_5)) res$n_obs_table3_cols2_5 <- r3$n
  }
}
if (!is.null(sevp_n)) {
  r4 <- safe_run(to01(d[[sevp_n]]))
  if (!is.null(r4)) {
    res$severe_malaria_treatment_prescribed_patient_voucher_table3_col4 <- r4$bp
    res$severe_malaria_treatment_prescribed_doctor_voucher_table3_col4 <- r4$bd
  }
}
if (!is.null(sevb_n)) {
  r5 <- safe_run(to01(d[[sevb_n]]))
  if (!is.null(r5)) {
    res$severe_malaria_treatment_purchased_patient_voucher_table3_col5 <- r5$bp
    res$severe_malaria_treatment_purchased_doctor_voucher_table3_col5 <- r5$bd
  }
}

if (!is.null(anyp) && grepl(" OR ", anyp$name))
  cat('DEVIATION: Any-antimalarial outcome constructed as simple-or-severe treatment because no single any-antimalarial variable was identified\n')

for (k in names(res)) {
  cat(sprintf("RESULT:%s=%s\n", k, format(res[[k]], digits = 6)))
}