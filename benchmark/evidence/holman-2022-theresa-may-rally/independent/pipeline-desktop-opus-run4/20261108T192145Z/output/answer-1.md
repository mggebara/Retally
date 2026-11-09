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

  # outcome: approval in the following quarter
  lead_c <- pick(ga, c("f_approval", "lead_approval", "approval_lead", "F_approval",
                       "approval_next", "next_approval", "f1_approval", "approval_f1"))
  if (is.na(lead_c)) {
    appr <- pick(ga, c("approval", "exec_approval", "approve", "approval_rating",
                       "pct_approve", "approval_smoothed"))
    if (is.na(appr)) {
      cand <- grep("approv", names(ga), value = TRUE, ignore.case = TRUE)
      cand <- cand[!grepl("^lag|lag_", cand)]
      appr <- cand[1]
    }
    cat("Using approval variable:", appr, "(computing next-quarter lead)\n")
    ga <- ga %>% arrange(.data[[ctry]], .data[[qv]])
    key_next <- paste(ga[[ctry]], ga[[qv]] + 1)
    key_now <- paste(ga[[ctry]], ga[[qv]])
    ga$y_lead <- ga[[appr]][match(key_next, key_now)]
  } else {
    cat("Using lead approval variable:", lead_c, "\n")
    ga$y_lead <- ga[[lead_c]]
  }

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

  # treatment: surveyed after the Manchester attack (respondent-level)
  trt <- pick(dd, c("treatment1", "post_attack", "treatment2"))
  cat("Treatment variable:", trt, "\n")
  dd$attack <- as.numeric(dd[[trt]])
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

  # best PM: 1 = May, 0 = Corbyn
  bp <- as.numeric(dd$may_bestpm)
  if (all(is.na(bp)) || length(unique(na.omit(bp))) < 2) {
    raw <- as.numeric(dd$bestPMW)
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
