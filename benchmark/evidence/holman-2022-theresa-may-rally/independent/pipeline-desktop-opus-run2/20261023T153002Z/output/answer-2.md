suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(data.table)
})
set.seed(42)

base <- "<repo>/.cache/datasets/holman_2022_theresa_may_rally.script-free"
results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) results[[name]] <<- val
}
is_num_vec <- function(cols, d) {
  if (length(cols) == 0) return(character(0))
  cols[vapply(cols, function(v) is.numeric(d[[v]]), logical(1))]
}

# =====================================================================
# Table 4: cross-national TSCS of executive approval
# =====================================================================
tryCatch({
  ga <- as.data.table(zap_labels(read_dta(file.path(base, "global_approval.dta"))))
  nm <- names(ga)
  message("global_approval columns: ", paste(nm, collapse = ", "))

  fem <- if ("female_pres" %in% nm) "female_pres" else grep("female|woman|women", nm, value = TRUE, ignore.case = TRUE)[1]
  cfe <- if ("ccode" %in% nm) "ccode" else if ("country_code" %in% nm) "country_code" else "country"
  ctrls <- intersect(c("growth", "log_inflation", "execrlc", "election_qtr"), nm)

  att_c <- unique(c(
    grep("int.*1[56]|1[56].*int", nm, value = TRUE, ignore.case = TRUE),
    intersect(c("kill_16", "kill_15", "kill15", "kill16"), nm),
    grep("death_?1[56]|1[56]_?death", nm, value = TRUE)
  ))
  att_c <- att_c[!grepl("^pres_|female|lag", att_c)]
  att_c <- is_num_vec(att_c, ga)
  att_pref <- NULL
  if ("pres_15death" %in% nm && length(att_c) > 0) {
    for (v in att_c) {
      a <- as.numeric(ga[[v]] > 0)
      p <- ga[["pres_15death"]]
      ok <- !is.na(a) & !is.na(p) & !is.na(ga[[fem]])
      if (sum(ok) > 0 && mean((a * ga[[fem]])[ok] == p[ok]) > 0.999) { att_pref <- v; break }
    }
  }
  if (is.null(att_pref)) att_pref <- if ("kill_16" %in% att_c) "kill_16" else att_c[1]
  message("attack var: ", att_pref)
  a <- as.numeric(ga[[att_pref]])
  if (!all(na.omit(a) %in% c(0, 1))) a <- as.numeric(a > 0)
  ga[, att := a]
  ga[, fem_ := as.numeric(get(fem))]
  ga[, ia := att * fem_]
  message("attack country-quarters: ", sum(ga$att == 1, na.rm = TRUE),
          "; under women: ", sum(ga$ia == 1, na.rm = TRUE))

  # The only approval series in the file is lag_approval; build the
  # contemporaneous and next-quarter approval from it by within-country leads.
  setorderv(ga, c(cfe, "qtr"))
  ga[, qn := as.numeric(qtr)]
  lead_k <- function(v, k) {
    ga[, {
      x <- as.numeric(get(v)); q <- qn
      nx <- shift(x, -k); nq <- shift(q, -k)
      list(r = ifelse(!is.na(nq) & nq == q + k, nx, NA_real_))
    }, by = cfe]$r
  }
  dvs <- list()
  appr <- is_num_vec(grep("approv", nm, value = TRUE, ignore.case = TRUE), ga)
  for (v in appr) {
    dvs[[paste0(v, "_raw")]] <- as.numeric(ga[[v]])
    if (grepl("lag", v, ignore.case = TRUE)) {
      dvs[[paste0(v, "_lead1")]] <- lead_k(v, 1)
      dvs[[paste0(v, "_lead2")]] <- lead_k(v, 2)
    } else {
      dvs[[paste0(v, "_lead1")]] <- lead_k(v, 1)
    }
  }
  fits <- list()
  for (k in names(dvs)) {
    ga[, dv_ := dvs[[k]]]
    f <- as.formula(paste("dv_ ~ att + fem_ + ia", if (length(ctrls)) paste("+", paste(ctrls, collapse = " + ")) else "", "|", cfe))
    m <- tryCatch(feols(f, data = ga, notes = FALSE, warn = FALSE, cluster = cfe), error = function(e) NULL)
    if (!is.null(m)) {
      fits[[k]] <- m
      message(sprintf("T4 spec %s: N=%d att=%.3f ia=%.3f", k, nobs(m), coef(m)["att"], coef(m)["ia"]))
    }
  }
  if (length(fits)) {
    d <- vapply(names(fits), function(k) abs(nobs(fits[[k]]) - 4328), numeric(1))
    kbest <- names(fits)[which.min(d)]
    best <- fits[[kbest]]
    message("T4 chosen: ", kbest)
    emit("intl_attack_table4", unname(coef(best)["att"]))
    emit("intl_attack_x_woman_exec_table4", unname(coef(best)["ia"]))
    emit("n_obs_table4", nobs(best))
    if (kbest != "lag_approval_raw")
      cat(sprintf("DEVIATION: Table 4 DV constructed as %s from lag_approval (only approval series in file)\n", kbest))
  }
}, error = function(e) message("Table 4 error: ", conditionMessage(e)))

# =====================================================================
# Table 2: panel difference-in-differences
# =====================================================================
tryCatch({
  want <- c("wave", "treatment1", "treatment2", "post_attack", "time", "likeMayW", "bestPMW", "may_bestpm",
            "white", "gender", "labour", "party_other", "income", "ideology", "ideology2", "ideo3", "id")
  dd <- read_dta(file.path(base, "did_data.dta"), col_select = any_of(want))
  dd <- as.data.table(zap_labels(dd))
  nm <- names(dd)
  trt <- if ("treatment1" %in% nm) "treatment1" else if ("treatment2" %in% nm) "treatment2" else "post_attack"
  dd[, treat := as.numeric(get(trt))]
  dd[, time_ := as.numeric(time)]
  dd[, tt := treat * time_]

  lm_y <- as.numeric(dd$likeMayW)
  lm_y[!is.na(lm_y) & (lm_y < 0 | lm_y > 10)] <- NA
  dd[, y_like := lm_y]

  clean <- function(x) { x <- as.numeric(x); x[!is.na(x) & x >= 98] <- NA; x }
  midimp <- function(x) { m <- (min(x, na.rm = TRUE) + max(x, na.rm = TRUE)) / 2; x[is.na(x)] <- m; x }
  inc_opts <- list(raw = clean(dd$income), mid = midimp(clean(dd$income)))
  ideo_opts <- list(raw = clean(dd$ideology), mid = midimp(clean(dd$ideology)))
  if ("ideology2" %in% nm) ideo_opts[["ideology2"]] <- as.numeric(dd$ideology2)
  if ("ideo3" %in% nm) ideo_opts[["ideo3"]] <- as.numeric(dd$ideo3)

  base_ctrl <- intersect(c("white", "gender", "labour", "party_other"), nm)
  base_ok <- complete.cases(dd[, c("treat", "time_", "wave", base_ctrl), with = FALSE])

  # best PM outcome codings (1 = May, 0 = Corbyn)
  bp <- list()
  if ("bestPMW" %in% nm) {
    x <- as.numeric(dd$bestPMW)
    message("bestPMW values: ", paste(capture.output(print(table(x, useNA = "ifany"))), collapse = " | "))
    bp[["bpw_1v0"]] <- ifelse(x == 1, 1, ifelse(x == 0, 0, NA_real_))
    bp[["bpw_1v2"]] <- ifelse(x == 1, 1, ifelse(x == 2, 0, NA_real_))
    bp[["bpw_1v02"]] <- ifelse(x == 1, 1, ifelse(x %in% c(0, 2), 0, NA_real_))
    bp[["bpw_1vother"]] <- ifelse(is.na(x) | x >= 98, NA_real_, as.numeric(x == 1))
  }
  if ("may_bestpm" %in% nm) {
    x <- as.numeric(dd$may_bestpm)
    if (all(na.omit(x) %in% c(0, 1))) {
      bp[["may_bestpm"]] <- x
      if ("bestPMW" %in% nm) {
        b <- as.numeric(dd$bestPMW)
        bp[["may_bestpm_valid"]] <- ifelse(is.na(b) | b >= 98, NA_real_, x)
      }
    }
  }
  # drop degenerate codings
  bp <- bp[vapply(bp, function(y) length(unique(na.omit(y[base_ok]))) == 2, logical(1))]

  choose_spec <- function(ylist, target) {
    best <- NULL; bd <- Inf
    for (yk in names(ylist)) for (i in names(inc_opts)) for (j in names(ideo_opts)) {
      n <- sum(base_ok & !is.na(ylist[[yk]]) & !is.na(inc_opts[[i]]) & !is.na(ideo_opts[[j]]))
      message(sprintf("  y=%s inc=%s ideo=%s N=%d", yk, i, j, n))
      if (abs(n - target) < bd) { bd <- abs(n - target); best <- c(yk, i, j) }
    }
    best
  }

  run_did <- function(ylist, target) {
    sp <- choose_spec(ylist, target)
    dd[, y_ := ylist[[sp[1]]]]
    dd[, inc_ := inc_opts[[sp[2]]]]
    dd[, ideo_ := ideo_opts[[sp[3]]]]
    sub <- dd[base_ok & !is.na(y_) & !is.na(inc_) & !is.na(ideo_)]
    f <- as.formula(paste("y_ ~ treat + time_ + tt +", paste(c(base_ctrl, "inc_", "ideo_"), collapse = " + "), "+ factor(wave)"))
    m <- lm(f, data = sub)
    message(sprintf("DiD spec y=%s inc=%s ideo=%s N=%d", sp[1], sp[2], sp[3], nobs(m)))
    print(coef(summary(m))[1:min(14, length(coef(m))), , drop = FALSE])
    m
  }

  m1 <- run_did(list(like = dd$y_like), 143499)
  emit("did_attack_x_time_like_may_table2", unname(coef(m1)["tt"]))
  emit("did_attack_like_may_table2", unname(coef(m1)["treat"]))
  emit("did_time_like_may_table2", unname(coef(m1)["time_"]))
  emit("n_obs_did_like_may_table2", nobs(m1))

  if (length(bp)) {
    m2 <- run_did(bp, 97155)
    emit("did_attack_x_time_may_best_pm_table2", unname(coef(m2)["tt"]))
    emit("did_attack_may_best_pm_table2", unname(coef(m2)["treat"]))
    emit("did_time_may_best_pm_table2", unname(coef(m2)["time_"]))
    emit("n_obs_did_may_best_pm_table2", nobs(m2))
    cat("DEVIATION: May-best-PM DiD estimated as a linear probability model (Table 2 magnitudes are on the probability scale)\n")
  }
}, error = function(e) message("Table 2 error: ", conditionMessage(e)))

for (k in names(results)) cat(sprintf("RESULT:%s=%s\n", k, format(results[[k]], digits = 8)))
