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

  trt <- pick(dd, c("treatment1", "post_attack", "treatment2"))
  cat("Treatment variable:", trt, "\n")
  dd$time <- as.numeric(dd$time)

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

  raw <- as.numeric(dd$bestPMW)
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

  # The panel file is rectangular (every id x every wave), so treatment1 is
  # filled even for people who never answered wave 12.  Assignment (surveyed
  # before vs after the attack) is only meaningful for actual wave-12
  # respondents of the outcome item, so restrict to ids who answered the
  # outcome in wave 12, and take their wave-12 assignment.
  cat("DEVIATION: DiD sample restricted to panel members who answered the outcome item in wave 12 (the wave where attack assignment is observed); rectangular panel otherwise includes non-participants\n")

  run_did <- function(yvar) {
    w12 <- dd[dd$wave == 12 & !is.na(dd[[yvar]]) & !is.na(dd[[trt]]), c("id", trt)]
    w12 <- w12[!duplicated(w12$id), ]
    d <- dd
    d$attack <- as.numeric(w12[[trt]][match(d$id, w12$id)])
    d <- d[!is.na(d$attack), ]
    vars <- c(yvar, "attack", "time", ctrl2, "wave", "id")
    d <- d[, vars[vars %in% names(d)]]
    d <- d[complete.cases(d[, c(yvar, "attack", "time", ctrl2, "wave")]), ]
    cat(yvar, "wave-12 respondents:", nrow(w12), " rows:", nrow(d), "\n")
    print(table(d$wave))
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
