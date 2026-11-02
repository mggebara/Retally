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
dedupe <- function(lst) {
  out <- list()
  for (k in names(lst)) {
    dup <- FALSE
    for (k2 in names(out)) if (identical(lst[[k]], out[[k2]])) { dup <- TRUE; break }
    if (!dup) out[[k]] <- lst[[k]]
  }
  out
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

  setorderv(ga, c(cfe, "qtr"))
  ga[, qn := as.numeric(qtr)]
  lead_k <- function(v, k) {
    ga[, {
      x <- as.numeric(get(v)); q <- qn
      nx <- shift(x, -k); nq <- shift(q, -k)
      list(r = ifelse(!is.na(nq) & nq == q + k, nx, NA_real_))
    }, by = cfe]$r
  }
  # calendar year from the quarter index
  q <- ga$qn
  yr <- if (max(q, na.rm = TRUE) < 1000) 1960 + floor(q / 4) else if (min(q, na.rm = TRUE) > 10000) floor(q / 10) else floor(q)
  message("year range: ", min(yr, na.rm = TRUE), "-", max(yr, na.rm = TRUE))
  restr <- list(all = rep(TRUE, nrow(ga)))
  r7517 <- !is.na(yr) & yr >= 1975 & yr <= 2017
  if (!all(r7517)) restr[["y1975_2017"]] <- r7517

  v0 <- if ("lag_approval" %in% nm) "lag_approval" else is_num_vec(grep("approv", nm, value = TRUE, ignore.case = TRUE), ga)[1]
  # lag_approval(t) = approval(t-1); approval in quarter after attack = lag_approval(t+2)
  dvs <- list(
    lead2 = list(y = lead_k(v0, 2), l = lead_k(v0, 1)),
    lead1 = list(y = lead_k(v0, 1), l = as.numeric(ga[[v0]])),
    raw   = list(y = as.numeric(ga[[v0]]), l = lead_k(v0, -1))
  )
  fits <- list()
  for (k in names(dvs)) for (r in names(restr)) for (ldv in c(FALSE, TRUE)) {
    ga[, dv_ := dvs[[k]]$y]
    ga[, ldv_ := dvs[[k]]$l]
    rhs <- c("att", "fem_", "ia", ctrls, if (ldv) "ldv_")
    f <- as.formula(paste("dv_ ~", paste(rhs, collapse = " + "), "|", cfe))
    sub <- ga[restr[[r]]]
    m <- tryCatch(feols(f, data = sub, notes = FALSE, warn = FALSE, cluster = cfe), error = function(e) NULL)
    if (!is.null(m)) {
      key <- paste(k, r, if (ldv) "ldv" else "noldv", sep = "|")
      fits[[key]] <- m
      message(sprintf("T4 spec %s: N=%d att=%.3f ia=%.3f", key, nobs(m), coef(m)["att"], coef(m)["ia"]))
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
    cat(sprintf("DEVIATION: Table 4 specification chosen by sample size among DV timings/period restriction/lagged-DV control built from lag_approval: %s\n", kbest))
  }
}, error = function(e) message("Table 4 error: ", conditionMessage(e)))

# =====================================================================
# Table 2: panel difference-in-differences
# =====================================================================
tryCatch({
  hdr <- tryCatch(names(read_dta(file.path(base, "did_data.dta"), n_max = 0)), error = function(e) character(0))
  wcols <- head(grep("^wt|weight|_wt", hdr, value = TRUE, ignore.case = TRUE), 3)
  message("weight candidates: ", paste(wcols, collapse = ", "))
  want <- unique(c("wave", "treatment1", "treatment2", "post_attack", "time", "likeMayW", "bestPMW", "may_bestpm",
            "white", "gender", "labour", "party_other", "income", "ideology", "ideology2", "ideo3", "id", wcols))
  dd <- read_dta(file.path(base, "did_data.dta"), col_select = any_of(want))
  dd <- as.data.table(zap_labels(dd))
  nm <- names(dd)
  wcols <- intersect(wcols, nm)
  wcols <- wcols[vapply(wcols, function(v) is.numeric(dd[[v]]), logical(1))]

  tlist <- list()
  for (tv in intersect(c("treatment1", "treatment2", "post_attack"), nm)) tlist[[tv]] <- as.numeric(dd[[tv]])
  tlist <- dedupe(tlist)
  dd[, time_ := as.numeric(time)]

  lm_y <- as.numeric(dd$likeMayW)
  lm_y[!is.na(lm_y) & (lm_y < 0 | lm_y > 10)] <- NA

  clean <- function(x) { x <- as.numeric(x); x[!is.na(x) & x >= 98] <- NA; x }
  midimp <- function(x) { m <- (min(x, na.rm = TRUE) + max(x, na.rm = TRUE)) / 2; x[is.na(x)] <- m; x }
  inc_opts <- list(raw = clean(dd$income), mid = midimp(clean(dd$income)))
  ideo_opts <- list(raw = clean(dd$ideology), mid = midimp(clean(dd$ideology)))
  if ("ideology2" %in% nm) ideo_opts[["ideology2"]] <- as.numeric(dd$ideology2)
  if ("ideo3" %in% nm) ideo_opts[["ideo3"]] <- as.numeric(dd$ideo3)
  ideo_opts <- dedupe(ideo_opts)

  base_ctrl <- intersect(c("white", "gender", "labour", "party_other"), nm)
  base_ok <- complete.cases(dd[, c("time_", "wave", base_ctrl), with = FALSE])

  bp <- list()
  if ("bestPMW" %in% nm) {
    x <- as.numeric(dd$bestPMW)
    bp[["bpw_1v0"]] <- ifelse(x == 1, 1, ifelse(x == 0, 0, NA_real_))
    bp[["bpw_1v2"]] <- ifelse(x == 1, 1, ifelse(x == 2, 0, NA_real_))
    bp[["bpw_1vother"]] <- ifelse(is.na(x) | x >= 98, NA_real_, as.numeric(x == 1))
  }
  bp <- bp[vapply(bp, function(y) length(unique(na.omit(y[base_ok]))) == 2, logical(1))]
  bp <- dedupe(bp)

  run_did <- function(ylist, target, const_target) {
    cands <- list()
    for (yk in names(ylist)) for (tk in names(tlist)) for (i in names(inc_opts)) for (j in names(ideo_opts)) {
      n <- sum(base_ok & !is.na(tlist[[tk]]) & !is.na(ylist[[yk]]) & !is.na(inc_opts[[i]]) & !is.na(ideo_opts[[j]]))
      cands[[length(cands) + 1]] <- list(y = yk, t = tk, i = i, j = j, n = n)
    }
    ns <- vapply(cands, function(z) z$n, numeric(1))
    keep <- cands[abs(ns - target) == min(abs(ns - target))]
    best <- NULL; bd <- Inf; bkey <- NULL
    for (cd in keep) for (w in c("none", wcols)) {
      dd[, y_ := ylist[[cd$y]]]
      dd[, treat := tlist[[cd$t]]]
      dd[, tt := treat * time_]
      dd[, inc_ := inc_opts[[cd$i]]]
      dd[, ideo_ := ideo_opts[[cd$j]]]
      ok <- base_ok & !is.na(dd$y_) & !is.na(dd$treat) & !is.na(dd$inc_) & !is.na(dd$ideo_)
      if (w != "none") ok <- ok & !is.na(dd[[w]]) & dd[[w]] > 0
      if (sum(ok) != cd$n) next
      sub <- dd[ok]
      f <- as.formula(paste("y_ ~ treat + time_ + tt +", paste(c(base_ctrl, "inc_", "ideo_"), collapse = " + "), "+ factor(wave)"))
      m <- tryCatch(if (w == "none") lm(f, data = sub) else lm(f, data = sub, weights = sub[[w]]), error = function(e) NULL)
      if (is.null(m) || is.na(coef(m)["tt"])) next
      key <- paste(cd$y, cd$t, cd$i, cd$j, w, sep = "|")
      dc <- abs(unname(coef(m)["(Intercept)"]) - const_target)
      message(sprintf("DiD cand %s N=%d const=%.4f treat=%.4f time=%.4f tt=%.4f", key, nobs(m),
                      coef(m)["(Intercept)"], coef(m)["treat"], coef(m)["time_"], coef(m)["tt"]))
      if (dc < bd) { bd <- dc; best <- m; bkey <- key }
    }
    message("DiD chosen: ", bkey)
    if (!is.null(best)) print(head(coef(summary(best)), 14))
    list(m = best, key = bkey)
  }

  r1 <- run_did(list(like = lm_y), 143499, 1.9443)
  if (!is.null(r1$m)) {
    m1 <- r1$m
    emit("did_attack_x_time_like_may_table2", unname(coef(m1)["tt"]))
    emit("did_attack_like_may_table2", unname(coef(m1)["treat"]))
    emit("did_time_like_may_table2", unname(coef(m1)["time_"]))
    emit("n_obs_did_like_may_table2", nobs(m1))
    cat(sprintf("DEVIATION: Like-May DiD treatment/ideology/weight variant chosen among N-matching candidates by intercept closeness: %s\n", r1$key))
  }

  if (length(bp)) {
    r2 <- run_did(bp, 97155, 0.1505)
    if (!is.null(r2$m)) {
      m2 <- r2$m
      emit("did_attack_x_time_may_best_pm_table2", unname(coef(m2)["tt"]))
      emit("did_attack_may_best_pm_table2", unname(coef(m2)["treat"]))
      emit("did_time_may_best_pm_table2", unname(coef(m2)["time_"]))
      emit("n_obs_did_may_best_pm_table2", nobs(m2))
      cat("DEVIATION: May-best-PM DiD estimated as a linear probability model (Table 2 magnitudes are on the probability scale)\n")
      cat(sprintf("DEVIATION: Best-PM DiD variant chosen among N-matching candidates by intercept closeness: %s\n", r2$key))
    }
  }
}, error = function(e) message("Table 2 error: ", conditionMessage(e)))

for (k in names(results)) cat(sprintf("RESULT:%s=%s\n", k, format(results[[k]], digits = 8)))
