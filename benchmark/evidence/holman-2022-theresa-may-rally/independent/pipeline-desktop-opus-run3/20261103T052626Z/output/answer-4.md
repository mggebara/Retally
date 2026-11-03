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

  # Sample period: the paper's panel covers 1975-2017. Derive the year from qtr.
  if ("qtr" %in% nm && is.numeric(g$qtr)) {
    q <- g$qtr
    cat("qtr range:", range(q, na.rm = TRUE), "\n")
    mx <- max(q, na.rm = TRUE)
    yr <- if (mx < 400) 1960 + floor(q / 4) else if (mx < 3000) floor(q) else if (mx < 30000) floor(q / 10) else floor(q / 100)
    g[, year_ := yr]
    cat("Year range:", range(g$year_, na.rm = TRUE), "\n")
    print(table(g$year_ > 2017 | g$year_ < 1975, useNA = "ifany"))
    g <- g[year_ >= 1975 & year_ <= 2017]
    cat("Rows after restricting to 1975-2017:", nrow(g), "\n")
  }

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
                      "ideology", "id", "starttimeW", "dates_to_bomb"), nm)
  d <- copy(d[, ..keep])
  for (v in names(d)) if (!is.character(d[[v]])) set(d, j = v, value = num(d[[v]]))

  cat("Rows:", nrow(d), "\n")

  # Sample: the DiD compares the wave-12 assignment groups across panel waves,
  # so restrict to respondents who actually took part in wave 12 (the only
  # respondents with a defined assignment).
  w12 <- d[wave == 12]
  if ("starttimeW" %in% names(d) && any(!is.na(w12$starttimeW))) {
    ids12 <- unique(w12[!is.na(starttimeW), id])
  } else {
    ids12 <- unique(w12[!is.na(likeMayW), id])
  }
  cat("Wave-12 participants:", length(ids12), "\n")
  d <- d[id %in% ids12]
  cat("Rows after restricting to wave-12 participants:", nrow(d), "\n")
  cat("wave x time:\n"); print(table(d$wave, d$time, useNA = "ifany"))
  for (tv in intersect(c("treatment1", "treatment2", "post_attack"), names(d))) {
    cat("Table of", tv, ":\n"); print(table(d[[tv]], useNA = "ifany"))
  }

  # Treatment: respondent-level indicator for being surveyed after the attack
  # in wave 12, carried across all the respondent's panel waves (treatment1).
  trt <- if ("treatment1" %in% names(d)) "treatment1" else if ("post_attack" %in% names(d)) "post_attack" else "treatment2"
  cat("Treatment variable:", trt, "\n")
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

  # controls: the panel DiD is estimated on complete cases (no midpoint
  # imputation); the reported Ns (143,499 / 97,155) are consistent with
  # listwise deletion on the full control set.
  for (v in c("income", "ideology")) {
    if (v %in% names(d)) cat("Missing", v, ":", sum(is.na(d[[v]])), "\n")
  }
  cat("DEVIATION: Table 2 DiD uses listwise deletion on income/ideology instead of midpoint recoding (midpoint recoding is described for Table 1; reported DiD Ns imply complete cases)\n")
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
