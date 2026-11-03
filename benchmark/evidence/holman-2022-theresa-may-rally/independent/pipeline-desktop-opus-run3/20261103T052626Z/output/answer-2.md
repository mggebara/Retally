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
  g <- copy(g)
  nm <- names(g)
  cat("global_approval columns:", paste(nm, collapse = ", "), "\n")
  for (v in nm) if (!is.character(g[[v]])) set(g, j = v, value = num(g[[v]]))

  # country identifier
  cid <- intersect(c("ccode", "country_code", "country"), nm)[1]
  g[, cid_ := as.character(get(cid))]

  # dependent variable: the only approval series in the file is 'lag_approval',
  # which is the approval measure aligned to the quarter following the event
  # quarter (the paper's DV). Use it directly.
  if ("lag_approval" %in% nm) {
    g[, dv_ := lag_approval]
    cat("Using DV column: lag_approval (approval in the quarter following the attack quarter)\n")
  } else {
    apr <- grep("approv", nm, value = TRUE, ignore.case = TRUE)
    g[, dv_ := get(apr[1])]
    cat("Using DV column:", apr[1], "\n")
  }
  print(summary(g$dv_))

  # attack indicator: international attack with > 15 deaths (16+)
  attv <- if ("kill_16" %in% nm) "kill_16" else "rally_kill"
  cat("Attack variable:", attv, "\n")
  g[, attack := as.numeric(get(attv) > 0)]
  g[, woman := as.numeric(female_pres > 0)]
  cat("Attack quarters:", sum(g$attack == 1, na.rm = TRUE),
      " under women:", sum(g$attack == 1 & g$woman == 1, na.rm = TRUE), "\n")

  ctrls <- intersect(c("growth", "log_inflation", "execrlc", "election_qtr"), nm)
  fml <- as.formula(paste("dv_ ~ attack * woman +", paste(ctrls, collapse = " + "), "| cid_"))
  m4 <- feols(fml, data = g, cluster = ~cid_)
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
  keep <- intersect(c("wave", "time", "treatment1", "treatment2", "post_attack", "likeMayW",
                      "bestPMW", "white", "gender", "labour", "party_other", "income",
                      "ideology", "id"), nm)
  d <- copy(d[, ..keep])
  for (v in names(d)) if (!is.character(d[[v]])) set(d, j = v, value = num(d[[v]]))

  cat("Rows:", nrow(d), "\n")
  cat("wave x time:\n"); print(table(d$wave, d$time, useNA = "ifany"))
  for (tv in intersect(c("treatment1", "treatment2", "post_attack"), names(d))) {
    cat("Table of", tv, ":\n"); print(table(d[[tv]], useNA = "ifany"))
  }

  # Treatment: assignment group (surveyed after the attack in wave 12), carried
  # across the respondent's panel waves. treatment2 is the respondent-level
  # assignment defined only for wave-12 participants.
  trt <- if ("treatment2" %in% names(d)) "treatment2" else if ("treatment1" %in% names(d)) "treatment1" else "post_attack"
  cat("Treatment variable:", trt, "\n")
  cat("DEVIATION: Used treatment2 (respondent-level wave-12 assignment) instead of treatment1 for the DiD treatment indicator\n")
  d[, attack := get(trt)]
  d[!(attack %in% c(0, 1)), attack := NA]

  # outcomes: wave-specific like/dislike and wave-specific best PM
  d[, like_may := likeMayW]
  d[!(like_may >= 0 & like_may <= 10), like_may := NA]
  if ("bestPMW" %in% names(d)) {
    cat("bestPMW values:\n"); print(table(d$bestPMW, useNA = "ifany"))
    vals <- sort(unique(na.omit(d$bestPMW)))
    if (all(vals %in% c(0, 1))) {
      d[, best_pm := bestPMW]
    } else {
      # BES coding: 1 = Theresa May, 2 = Jeremy Corbyn; others (don't know) missing
      d[, best_pm := fifelse(bestPMW == 1, 1, fifelse(bestPMW == 2, 0, NA_real_))]
    }
  } else {
    d[, best_pm := NA_real_]
  }

  # controls: missing income / ideology to scale midpoint
  for (v in c("income", "ideology")) {
    if (v %in% names(d)) {
      x <- d[[v]]
      mid <- (min(x, na.rm = TRUE) + max(x, na.rm = TRUE)) / 2
      x[is.na(x)] <- mid
      set(d, j = v, value = x)
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
