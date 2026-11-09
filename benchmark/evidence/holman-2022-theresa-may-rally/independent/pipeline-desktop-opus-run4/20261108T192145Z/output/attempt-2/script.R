suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/holman_2022_theresa_may_rally.script-free"

results <- list()
emit <- function(name, value) {
  if (!is.null(value) && length(value) == 1 && is.finite(value)) {
    results[[name]] <<- value
  }
}

strip <- function(df) {
  df <- as.data.frame(df)
  for (v in names(df)) {
    x <- df[[v]]
    if (inherits(x, "haven_labelled")) x <- zap_labels(x)
    attributes(x)[c("label", "format.stata", "labels")] <- NULL
    df[[v]] <- x
  }
  df
}

pick <- function(df, cands) {
  for (c in cands) if (c %in% names(df)) return(c)
  NA_character_
}

# --------------------------------------------------------------------------
# Table 4: cross-national country-quarter regression
# --------------------------------------------------------------------------
tryCatch({
  ga <- strip(read_dta(file.path(base, "global_approval.dta")))
  cat("global_approval columns:", paste(names(ga), collapse = ", "), "\n")

  ctry <- pick(ga, c("country", "ccode", "country_code"))
  qv <- pick(ga, c("qtr", "quarter", "date_q"))

  # The only approval measure in the file is 'lag_approval'; the deposited
  # dataset is structured so that this is the approval outcome paired with the
  # attack quarter (approval in the quarter after the attack).
  appr <- pick(ga, c("approval", "exec_approval", "approve", "approval_rating",
                     "pct_approve", "lag_approval"))
  cat("Using approval outcome variable:", appr, "\n")
  ga$y_lead <- as.numeric(ga[[appr]])
  cat("DEVIATION: Outcome for Table 4 is lag_approval as deposited (no other approval variable exists in global_approval.dta)\n")

  att <- pick(ga, c("kill_16", "intl_kill_16", "rally_kill", "kill15", "kill_15"))
  cat("Attack variable:", att, "\n")
  ga$attack <- as.numeric(ga[[att]])
  ga$woman <- as.numeric(ga[["female_pres"]])

  ctrl <- c("growth", "log_inflation", "execrlc", "election_qtr")
  ctrl <- ctrl[ctrl %in% names(ga)]

  d4 <- ga[, c("y_lead", "attack", "woman", ctrl, ctry)]
  names(d4)[ncol(d4)] <- "cfe"
  d4 <- d4[complete.cases(d4), ]

  f4 <- as.formula(paste("y_lead ~ attack + woman + attack:woman +",
                         paste(ctrl, collapse = " + "), "| cfe"))
  m4 <- feols(f4, data = d4, vcov = "iid")
  print(summary(m4))
  cf <- coef(m4)
  emit("intl_attack_table4", unname(cf["attack"]))
  emit("intl_attack_x_woman_exec_table4", unname(cf["attack:woman"]))
  emit("n_obs_table4", nobs(m4))

  # diagnostic: next-quarter lead of the same variable
  if (!is.na(qv)) {
    key_next <- paste(ga[[ctry]], ga[[qv]] + 1)
    key_now <- paste(ga[[ctry]], ga[[qv]])
    ga$y_alt <- ga$y_lead[match(key_next, key_now)]
    d4b <- ga[, c("y_alt", "attack", "woman", ctrl, ctry)]
    names(d4b)[ncol(d4b)] <- "cfe"
    d4b <- d4b[complete.cases(d4b), ]
    m4b <- feols(as.formula(paste("y_alt ~ attack + woman + attack:woman +",
                                  paste(ctrl, collapse = " + "), "| cfe")),
                 data = d4b, vcov = "iid")
    cat("Diagnostic (lead of lag_approval):\n")
    print(coef(m4b)[c("attack", "attack:woman")]); cat("N =", nobs(m4b), "\n")
  }
}, error = function(e) cat("Table 4 error:", conditionMessage(e), "\n"))

# --------------------------------------------------------------------------
# Table 2: interrupted time series difference-in-differences (BES panel)
# --------------------------------------------------------------------------
tryCatch({
  dd <- read_dta(file.path(base, "did_data.dta"),
                 col_select = any_of(c("wave", "gender", "labour", "income", "ideology",
                                       "time", "may_bestpm", "bestPMW", "white",
                                       "treatment1", "treatment2", "post_attack",
                                       "party_other", "id", "likeMayW")))
  dd <- strip(dd)
  cat("did_data rows:", nrow(dd), "\n")
  dd$wave <- as.numeric(dd$wave)
  print(table(dd$wave, useNA = "ifany"))

  # treatment: surveyed after the Manchester attack in wave 12 (respondent-level)
  trt <- pick(dd, c("treatment1", "post_attack", "treatment2"))
  cat("Treatment variable:", trt, "\n")
  w12 <- dd[dd$wave == 12 & !is.na(dd[[trt]]), c("id", trt)]
  w12 <- w12[!duplicated(w12$id), ]
  dd$attack <- as.numeric(w12[[trt]][match(dd$id, w12$id)])
  # keep only respondents who took part in wave 12 (where assignment is defined)
  dd <- dd[!is.na(dd$attack), ]
  cat("Rows after restricting to wave-12 respondents:", nrow(dd), "\n")
  dd$time <- as.numeric(dd$time)
  print(table(dd$wave, dd$time, useNA = "ifany"))

  clean_scale <- function(x) {
    x <- as.numeric(x)
    x[x >= 99] <- NA
    x
  }
  dd$income <- clean_scale(dd$income)
  dd$ideology <- clean_scale(dd$ideology)
  mid_inc <- (min(dd$income, na.rm = TRUE) + max(dd$income, na.rm = TRUE)) / 2
  mid_ide <- (min(dd$ideology, na.rm = TRUE) + max(dd$ideology, na.rm = TRUE)) / 2
  dd$income[is.na(dd$income)] <- mid_inc
  dd$ideology[is.na(dd$ideology)] <- mid_ide

  dd$likeMay <- clean_scale(dd$likeMayW)

  # best PM: 1 = May, 0 = Corbyn, from the wave-specific item
  raw <- as.numeric(dd$bestPMW)
  cat("bestPMW values:\n"); print(table(raw, useNA = "ifany"))
  uv <- sort(unique(na.omit(raw)))
  if (length(uv) == 2 && all(uv == c(0, 1))) {
    bp <- raw
  } else {
    bp <- ifelse(raw == 1, 1, ifelse(raw == 2, 0, NA))
  }
  dd$bestpm <- bp

  ctrl2 <- c("white", "gender", "labour", "party_other", "income", "ideology")
  ctrl2 <- ctrl2[ctrl2 %in% names(dd)]
  for (v in ctrl2) dd[[v]] <- as.numeric(dd[[v]])

  run_did <- function(yvar) {
    vars <- c(yvar, "attack", "time", ctrl2, "wave", "id")
    d <- dd[, vars[vars %in% names(dd)]]
    d <- d[complete.cases(d[, c(yvar, "attack", "time", ctrl2, "wave")]), ]
    f <- as.formula(paste(yvar, "~ attack * time +", paste(ctrl2, collapse = " + "),
                          "+ factor(wave)"))
    m <- lm(f, data = d)
    print(summary(m)$coefficients[1:min(12, nrow(summary(m)$coefficients)), ])
    list(cf = coef(m), n = nobs(m))
  }

  r1 <- run_did("likeMay")
  emit("did_attack_x_time_like_may_table2", unname(r1$cf["attack:time"]))
  emit("did_attack_like_may_table2", unname(r1$cf["attack"]))
  emit("did_time_like_may_table2", unname(r1$cf["time"]))
  emit("n_obs_did_like_may_table2", r1$n)

  r2 <- run_did("bestpm")
  emit("did_attack_x_time_may_best_pm_table2", unname(r2$cf["attack:time"]))
  emit("did_attack_may_best_pm_table2", unname(r2$cf["attack"]))
  emit("did_time_may_best_pm_table2", unname(r2$cf["time"]))
  emit("n_obs_did_may_best_pm_table2", r2$n)
}, error = function(e) cat("Table 2 error:", conditionMessage(e), "\n"))

for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
}