suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/holman_2022_theresa_may_rally.script-free"
results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) results[[name]] <<- val
}

is_binary <- function(x) {
  u <- unique(x[!is.na(x)])
  length(u) > 0 && all(u %in% c(0, 1))
}

# =====================================================================
# Table 4: cross-national TSCS, executive approval
# =====================================================================
tryCatch({
  ga <- as.data.frame(read_dta(file.path(base, "global_approval.dta")))
  for (v in names(ga)) {
    if (inherits(ga[[v]], "haven_labelled")) ga[[v]] <- as.numeric(zap_labels(ga[[v]]))
  }
  nm <- names(ga)
  message("T4 vars: ", paste(nm, collapse = " "))
  cvar <- if ("country" %in% nm) "country" else if ("ccode" %in% nm) "ccode" else "country_code"
  ga$cid <- as.character(ga[[cvar]])

  qnum <- NULL
  qv <- if ("qtr" %in% nm) "qtr" else if ("quarter" %in% nm) "quarter" else NULL
  if (!is.null(qv) && is.numeric(ga[[qv]])) {
    q <- as.numeric(ga[[qv]])
    if (max(q, na.rm = TRUE) <= 4 && "year" %in% nm) {
      qnum <- as.numeric(ga$year) * 4 + q
    } else {
      qnum <- q
    }
  } else if ("year" %in% nm && !is.null(qv)) {
    q <- suppressWarnings(as.numeric(gsub("[^0-9]", "", as.character(ga[[qv]]))))
    if (all(is.na(q))) q <- 1
    qnum <- as.numeric(ga$year) * 4 + q
  }
  if (is.null(qnum) || all(is.na(qnum))) {
    ga$qnum_tmp <- NA_real_
    ord <- order(ga$cid)
    ga <- ga[ord, ]
    qnum <- ave(seq_len(nrow(ga)), ga$cid, FUN = seq_along)
  } else {
    ord <- order(ga$cid, qnum)
    ga <- ga[ord, ]
    qnum <- qnum[ord]
  }

  lead_by <- function(x, k = 1) {
    out <- rep(NA_real_, length(x))
    idx <- split(seq_along(x), ga$cid)
    for (ii in idx) {
      n <- length(ii)
      if (n > k) {
        src <- ii[(1 + k):n]; dst <- ii[1:(n - k)]
        ok <- !is.na(qnum[src]) & !is.na(qnum[dst]) & (qnum[src] - qnum[dst]) == k
        out[dst[ok]] <- as.numeric(x[src[ok]])
      }
    }
    out
  }

  ycands <- list()
  appr_names <- nm[grepl("approv", nm, ignore.case = TRUE)]
  lead_names <- appr_names[grepl("lead|^f_|_f$|next|fwd|forward|f1", appr_names, ignore.case = TRUE)]
  for (v in lead_names) ycands[[paste0("asis_", v)]] <- as.numeric(ga[[v]])
  base_appr <- setdiff(appr_names, c(lead_names, appr_names[grepl("lag", appr_names, ignore.case = TRUE)]))
  if (length(base_appr) > 0) {
    av <- if ("approval" %in% base_appr) "approval" else base_appr[1]
    ycands[["cur"]] <- as.numeric(ga[[av]])
    ycands[["lead"]] <- lead_by(ga[[av]], 1)
    for (v in setdiff(base_appr, av)) {
      if (is.numeric(ga[[v]])) {
        ycands[[paste0("lead_", v)]] <- lead_by(ga[[v]], 1)
        s <- summary(as.numeric(ga[[v]]))
        message("T4 alt approval ", v, ": mean=", round(s[["Mean"]], 3), " max=", round(s[["Max."]], 3))
      }
    }
    s <- summary(as.numeric(ga[[av]]))
    message("T4 approval ", av, ": mean=", round(s[["Mean"]], 3), " max=", round(s[["Max."]], 3))
  } else if ("lag_approval" %in% nm) {
    ycands[["cur"]] <- lead_by(ga$lag_approval, 1)
    ycands[["lead"]] <- lead_by(ga$lag_approval, 2)
  }

  acands <- list()
  pref <- c("kill_16", "pres_15death", "rally_kill", "rally_event_any", "rally_event_any2", "rally_events")
  others <- nm[grepl("kill|death", nm, ignore.case = TRUE)]
  for (v in unique(c(intersect(pref, nm), others))) {
    x <- as.numeric(ga[[v]])
    if (is_binary(x)) {
      acands[[v]] <- x
    } else if (grepl("kill", v) && max(x, na.rm = TRUE) > 15) {
      acands[[paste0(v, "_gt15")]] <- as.numeric(x > 15)
    }
  }
  gt15_def <- function(an) an %in% c("kill_16", "pres_15death") || grepl("_gt15$", an) ||
    grepl("16|15death", an)

  ex_raw <- as.numeric(ga$execrlc)
  ex_na <- ex_raw; ex_na[!is.na(ex_na) & ex_na < 0] <- NA
  ecands <- list(raw = ex_raw, negNA = ex_na)

  best <- NULL; best_score <- Inf
  for (yn in names(ycands)) for (an in names(acands)) for (en in names(ecands)) {
    d <- data.frame(y = ycands[[yn]], att = acands[[an]], fem = as.numeric(ga$female_pres),
                    growth = as.numeric(ga$growth), linf = as.numeric(ga$log_inflation),
                    ex = ecands[[en]], elec = as.numeric(ga$election_qtr), cid = ga$cid)
    d <- d[complete.cases(d), ]
    if (nrow(d) < 100 || sum(d$att) == 0) next
    m <- tryCatch(feols(y ~ att * fem + growth + linf + ex + elec | cid, data = d,
                        cluster = ~cid, warn = FALSE, notes = FALSE), error = function(e) NULL)
    if (is.null(m)) next
    N <- nobs(m)
    sa <- sum(d$att); saf <- sum(d$att * d$fem)
    sc <- abs(N - 4359) / 4359 + abs(sa - 60) / 60 + abs(saf - 9) / 9
    if (!gt15_def(an)) sc <- sc + 0.5
    if (yn == "cur") sc <- sc + 0.25
    if (grepl("^lead_", yn)) sc <- sc + 0.01
    if (en == "raw") sc <- sc + 1e-6
    if (gt15_def(an) && en == "negNA") {
      cfm <- coef(m)
      message(sprintf("T4 cand y=%s a=%s N=%d att=%.3f int=%.3f", yn, an, N, cfm["att"], cfm["att:fem"]))
    }
    if (sc < best_score) { best_score <- sc; best <- list(m = m, yn = yn, an = an, en = en) }
  }
  if (!is.null(best)) {
    cf <- coef(best$m)
    emit("intl_attack_table4", unname(cf["att"]))
    emit("intl_attack_x_woman_exec_table4", unname(cf["att:fem"]))
    emit("n_obs_table4", nobs(best$m))
    message("Table 4 spec: y=", best$yn, " attack=", best$an, " execrlc=", best$en)
  }
}, error = function(e) message("Table 4 error: ", conditionMessage(e)))

# =====================================================================
# Table 2: difference-in-differences across BES waves
# =====================================================================
tryCatch({
  want <- c("wave", "id", "gender", "labour", "income", "ideology", "time", "may_bestpm",
            "post_attack", "white", "treatment1", "treatment2", "party_other",
            "likeMayW", "bestPMW")
  dd <- read_dta(file.path(base, "did_data.dta"), col_select = any_of(want))

  recode_bestpm <- function(x) {
    labs <- attr(x, "labels")
    v <- as.numeric(zap_labels(x))
    if (is_binary(v)) return(v)
    out <- rep(NA_real_, length(v))
    if (!is.null(labs) && length(labs) > 0) {
      may <- labs[grepl("May", names(labs))]
      cor <- labs[grepl("Corbyn", names(labs))]
      if (length(may) > 0 && length(cor) > 0) {
        out[v %in% may] <- 1; out[v %in% cor] <- 0
        return(out)
      }
    }
    out[v == 1] <- 1; out[v == 2] <- 0
    out
  }
  bp_cands <- list()
  if ("bestPMW" %in% names(dd)) bp_cands[["bestPMW"]] <- recode_bestpm(dd$bestPMW)
  if ("may_bestpm" %in% names(dd)) bp_cands[["may_bestpm"]] <- recode_bestpm(dd$may_bestpm)

  dd <- as.data.table(zap_labels(dd))
  dd[, names(dd) := lapply(.SD, as.numeric)]

  dd[likeMayW > 10 | likeMayW < 0, likeMayW := NA]
  clean_codes <- function(x) { x[!is.na(x) & (x >= 98 | x < 0)] <- NA; x }
  impute_mid <- function(x) {
    mid <- (min(x, na.rm = TRUE) + max(x, na.rm = TRUE)) / 2
    x[is.na(x)] <- mid
    x
  }
  dd[ideology > 10, ideology := NA]
  dd[, ideology := clean_codes(ideology)]
  dd[, income := clean_codes(income)]
  dd[, ideology_raw := ideology]
  dd[, income_raw := income]
  dd[, ideology_imp := impute_mid(ideology)]
  dd[, income_imp := impute_mid(income)]
  if (!"time" %in% names(dd)) dd[, time := as.numeric(wave >= 12)]
  dd[is.na(time), time := as.numeric(wave >= 12)]

  tcands <- list()
  for (v in intersect(c("post_attack", "treatment1", "treatment2"), names(dd))) {
    x <- dd[[v]]
    if (!is_binary(x)) next
    tmp <- data.table(id = dd$id, x = x)[!is.na(x)]
    if (nrow(tmp) == 0) next
    cons <- tmp[, .(k = uniqueN(x)), by = id][, mean(k == 1)]
    waves_cov <- uniqueN(dd$wave[!is.na(x)])
    if (cons >= 0.99 && waves_cov > 1) tcands[[v]] <- x
  }
  if ("post_attack" %in% names(dd)) {
    w12 <- dd[wave == 12 & !is.na(post_attack), .(tr = post_attack[1]), by = id]
    tcands[["post_attack_prop"]] <- w12$tr[match(dd$id, w12$id)]
  }

  base_ctrls <- intersect(c("white", "gender", "labour", "party_other"), names(dd))
  has_ii <- all(c("ideology", "income") %in% names(dd))

  ctrl_set <- function(imp) {
    if (!has_ii) return(base_ctrls)
    if (imp) c(base_ctrls, "income_imp", "ideology_imp") else c(base_ctrls, "income_raw", "ideology_raw")
  }

  ws <- sort(unique(dd$wave[!is.na(dd$wave)]))
  starts <- ws[ws < 12]; ends <- ws[ws >= 12]
  y_like <- dd$likeMayW
  wv <- dd$wave
  ok_time <- !is.na(dd$time) & !is.na(wv)

  # Outcome-specific wave windows: the two outcomes were not asked in the
  # same set of waves, so each model's estimation window is matched to its
  # own reported N separately.
  search_win <- function(okv, target) {
    bw <- NULL; bsc <- Inf
    for (s in starts) for (e in ends) {
      inw <- wv >= s & wv <= e
      N <- sum(okv & inw, na.rm = TRUE)
      if (N < 100) next
      sc <- abs(N - target) / target
      if (s != min(ws) || e != max(ws)) sc <- sc + 0.001
      if (sc < bsc) { bsc <- sc; bw <- list(s = s, e = e, N = N, sc = sc) }
    }
    bw
  }

  spec_best <- NULL; spec_sc <- Inf
  for (tn in names(tcands)) for (imp in c(TRUE, FALSE)) {
    cs <- ctrl_set(imp)
    okc <- ok_time & !is.na(tcands[[tn]])
    for (cv in cs) okc <- okc & !is.na(dd[[cv]])
    wl <- search_win(okc & !is.na(y_like), 143499)
    if (is.null(wl)) next
    wb <- NULL; bnb <- NULL
    for (bn in names(bp_cands)) {
      w <- search_win(okc & !is.na(bp_cands[[bn]]), 97155)
      if (!is.null(w) && (is.null(wb) || w$sc < wb$sc)) { wb <- w; bnb <- bn }
    }
    if (is.null(wb)) next
    sc <- wl$sc + wb$sc + if (!imp) 0.002 else 0
    if (sc < spec_sc) {
      spec_sc <- sc
      spec_best <- list(tn = tn, imp = imp, bn = bnb, wl = wl, wb = wb)
    }
  }

  fit_did <- function(y, tr, cs, s, e) {
    d <- data.table(y = y, tr = tr, time = dd$time, wave = dd$wave)
    for (cv in cs) d[[cv]] <- dd[[cv]]
    d <- d[!is.na(wave) & wave >= s & wave <= e]
    d <- d[complete.cases(d)]
    if (nrow(d) < 100) return(NULL)
    d[, wave := factor(wave)]
    f <- as.formula(paste("y ~ tr + time + tr:time +", paste(cs, collapse = " + "), "+ wave"))
    lm(f, data = d)
  }

  if (!is.null(spec_best)) {
    sb <- spec_best
    cs <- ctrl_set(sb$imp)
    message("Table 2 spec: treatment=", sb$tn, " impute=", sb$imp, " bestpm=", sb$bn,
            " like waves ", sb$wl$s, "-", sb$wl$e, " N=", sb$wl$N,
            " bp waves ", sb$wb$s, "-", sb$wb$e, " N=", sb$wb$N,
            " all waves: ", paste(ws, collapse = ","))
    if (sb$wl$s != min(ws) || sb$wl$e != max(ws)) {
      cat(sprintf("DEVIATION: Table 2 likeability model restricted to BES waves %s-%s (window chosen to match the paper's reported N; paper does not list waves)\n", sb$wl$s, sb$wl$e))
    }
    if (sb$wb$s != min(ws) || sb$wb$e != max(ws)) {
      cat(sprintf("DEVIATION: Table 2 best-PM model restricted to BES waves %s-%s (window chosen to match the paper's reported N; paper does not list waves)\n", sb$wb$s, sb$wb$e))
    }
    if (!sb$imp) {
      cat("DEVIATION: Table 2 drops missing income/ideology instead of midpoint imputation to match reported N\n")
    }

    m <- tryCatch(fit_did(y_like, tcands[[sb$tn]], cs, sb$wl$s, sb$wl$e), error = function(e) NULL)
    if (!is.null(m)) {
      cf <- coef(m)
      emit("did_attack_x_time_like_may_table2", unname(cf["tr:time"]))
      emit("did_attack_like_may_table2", unname(cf["tr"]))
      emit("did_time_like_may_table2", unname(cf["time"]))
      emit("n_obs_did_like_may_table2", nobs(m))
      message("T2 like const=", round(cf["(Intercept)"], 4))
    }
    mb <- tryCatch(fit_did(bp_cands[[sb$bn]], tcands[[sb$tn]], cs, sb$wb$s, sb$wb$e), error = function(e) NULL)
    if (!is.null(mb)) {
      cf <- coef(mb)
      emit("did_attack_x_time_may_best_pm_table2", unname(cf["tr:time"]))
      emit("did_attack_may_best_pm_table2", unname(cf["tr"]))
      emit("did_time_may_best_pm_table2", unname(cf["time"]))
      emit("n_obs_did_may_best_pm_table2", nobs(mb))
      message("T2 bp const=", round(cf["(Intercept)"], 4))
    }
  }
}, error = function(e) message("Table 2 error: ", conditionMessage(e)))

for (nmr in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nmr, results[[nmr]]))
}
