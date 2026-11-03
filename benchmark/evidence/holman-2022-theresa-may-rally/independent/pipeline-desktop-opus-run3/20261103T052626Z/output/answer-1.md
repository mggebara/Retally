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
num <- function(x) as.numeric(zap_labels(x))

# ------------------------------------------------------------------
# Table 4: cross-national TSCS of executive approval
# ------------------------------------------------------------------
tryCatch({
  g <- as.data.table(read_dta(file.path(base, "global_approval.dta")))
  nm <- names(g)
  cat("global_approval columns:", paste(nm, collapse = ", "), "\n")
  for (v in nm) if (!is.character(g[[v]])) g[[v]] <- num(g[[v]])

  # country identifier
  cid <- intersect(c("ccode", "country_code", "country"), nm)[1]
  g[, cid_ := as.character(get(cid))]

  # dependent variable: approval in the following quarter
  apr <- grep("approv", nm, value = TRUE, ignore.case = TRUE)
  lead_cands <- apr[grepl("lead|^f_|_f$|^f\\.|next|fwd|forward|^f[0-9]?approv", apr, ignore.case = TRUE)]
  cur_cands <- setdiff(apr, c(lead_cands, apr[grepl("lag|^l_|_l$|^l\\.|diff|chg|change", apr, ignore.case = TRUE)]))
  if (length(lead_cands) > 0) {
    g[, dv_ := get(lead_cands[1])]
    cat("Using lead DV column:", lead_cands[1], "\n")
  } else {
    curv <- if ("approval" %in% cur_cands) "approval" else cur_cands[1]
    cat("Constructing lead of:", curv, "\n")
    g[, cur_ := get(curv)]
    g[, dv_ := {
      q <- qtr
      cur_[match(q + 1, q)]
    }, by = cid_]
  }

  # attack indicator: international attack with > 15 deaths
  attv <- NULL
  if ("kill_16" %in% nm) attv <- "kill_16"
  if (is.null(attv)) {
    kc <- grep("^kill_|death", nm, value = TRUE)
    kc <- setdiff(kc, c("pres_15death", "pres_20death"))
    if (length(kc)) {
      cnt <- sapply(kc, function(v) sum(g[[v]] > 0, na.rm = TRUE))
      attv <- kc[which.min(abs(cnt - 60))]
    } else attv <- "rally_kill"
  }
  cat("Attack variable:", attv, "\n")
  g[, attack := as.numeric(get(attv) > 0)]
  g[, woman := as.numeric(female_pres > 0)]

  ctrls <- intersect(c("growth", "log_inflation", "execrlc", "election_qtr"), nm)
  fml <- as.formula(paste("dv_ ~ attack * woman +", paste(ctrls, collapse = " + "), "| cid_"))
  m4 <- feols(fml, data = g)
  print(summary(m4))
  emit("intl_attack_table4", coef(m4)["attack"])
  emit("intl_attack_x_woman_exec_table4", coef(m4)["attack:woman"])
  emit("n_obs_table4", nobs(m4))
}, error = function(e) cat("Table 4 error:", conditionMessage(e), "\n"))

# ------------------------------------------------------------------
# Table 2: difference-in-differences across BES waves
# ------------------------------------------------------------------
tryCatch({
  d <- as.data.table(read_dta(file.path(base, "did_data.dta")))
  nm <- names(d)
  cat("did_data columns:", paste(nm, collapse = ", "), "\n")
  keep <- intersect(c("wave", "time", "treatment1", "post_attack", "likeMayW", "may_bestpm",
                      "bestPMW", "white", "gender", "labour", "party_other", "income",
                      "ideology", "id"), nm)
  d <- d[, ..keep]
  for (v in names(d)) if (!is.character(d[[v]])) d[[v]] <- num(d[[v]])

  trt <- if ("treatment1" %in% nm) "treatment1" else "post_attack"
  d[, attack := get(trt)]

  # outcomes
  d[, like_may := likeMayW]
  d[!(like_may >= 0 & like_may <= 10), like_may := NA]
  if ("may_bestpm" %in% nm) {
    d[, best_pm := may_bestpm]
    d[!(best_pm %in% c(0, 1)), best_pm := NA]
  } else {
    d[, best_pm := NA_real_]
  }

  # controls: missing income / ideology to scale midpoint
  for (v in c("income", "ideology")) {
    if (v %in% names(d)) {
      x <- d[[v]]
      mid <- (min(x, na.rm = TRUE) + max(x, na.rm = TRUE)) / 2
      x[is.na(x)] <- mid
      d[[v]] <- x
    }
  }
  ctrls <- intersect(c("white", "gender", "labour", "party_other", "income", "ideology"), names(d))
  d[, wave_f := factor(wave)]
  rhs <- paste("attack + time + attack:time +", paste(ctrls, collapse = " + "), "+ wave_f")

  m_like <- lm(as.formula(paste("like_may ~", rhs)), data = d)
  cl <- coef(m_like)
  print(cl[c("attack", "time", "attack:time")])
  emit("did_attack_x_time_like_may_table2", cl["attack:time"])
  emit("did_attack_like_may_table2", cl["attack"])
  emit("did_time_like_may_table2", cl["time"])
  emit("n_obs_did_like_may_table2", nobs(m_like))

  if (any(!is.na(d$best_pm))) {
    m_pm <- lm(as.formula(paste("best_pm ~", rhs)), data = d)
    cp <- coef(m_pm)
    print(cp[c("attack", "time", "attack:time")])
    emit("did_attack_x_time_may_best_pm_table2", cp["attack:time"])
    emit("did_attack_may_best_pm_table2", cp["attack"])
    emit("did_time_may_best_pm_table2", cp["time"])
    emit("n_obs_did_may_best_pm_table2", nobs(m_pm))
  }
}, error = function(e) cat("Table 2 error:", conditionMessage(e), "\n"))

for (n in names(results)) cat(sprintf("RESULT:%s=%.6f\n", n, as.numeric(results[[n]])))
