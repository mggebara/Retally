suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/holman_2022_theresa_may_rally.script-free"
res <- list()
put <- function(nm, v) res[[nm]] <<- v

strip <- function(df) {
  df <- as.data.frame(df)
  for (v in names(df)) {
    x <- df[[v]]
    if (inherits(x, "haven_labelled")) x <- zap_labels(x)
    if (is.numeric(x)) x <- as.numeric(x)
    df[[v]] <- x
  }
  df
}

## ---------------- Table 4: cross-national TSCS ----------------
tryCatch({
  ga <- strip(read_dta(file.path(base, "global_approval.dta")))
  nms <- names(ga)
  message("global_approval vars: ", paste(nms, collapse = ", "))

  # Attack indicator: international attack with > 15 deaths
  cand_att <- c(grep("int.*(15|16)|(15|16).*int", nms, value = TRUE, ignore.case = TRUE),
                "kill_16", "pres_15death")
  cand_att <- cand_att[cand_att %in% nms]
  att_var <- cand_att[1]
  message("attack variable: ", att_var)
  ga$attack <- as.numeric(ga[[att_var]] > 0)

  # Woman executive
  fem_var <- intersect(c("female_pres", "female_exec", "woman_exec", "female"), nms)[1]
  ga$woman <- as.numeric(ga[[fem_var]] > 0)

  # Dependent variable: approval in the quarter following the attack
  lead_cands <- grep("(lead|^f_|^f\\.|next|_f1|_lead|forward).*approval|approval.*(lead|_f1|next)",
                     nms, value = TRUE, ignore.case = TRUE)
  ord_var <- intersect(c("qtr", "quarter", "date", "time"), nms)[1]
  cvar <- intersect(c("country", "ccode", "country_code"), nms)[1]
  if (length(lead_cands) > 0) {
    ga$dv <- ga[[lead_cands[1]]]
    message("DV (lead) variable: ", lead_cands[1])
  } else {
    appr <- grep("approval", nms, value = TRUE, ignore.case = TRUE)
    appr <- appr[!grepl("lag", appr, ignore.case = TRUE)]
    appr_var <- if ("approval" %in% appr) "approval" else appr[1]
    message("approval variable (leading by one quarter): ", appr_var)
    dt <- as.data.table(ga)
    dt[, .row := .I]
    setorderv(dt, c(cvar, ord_var))
    dt[, dv := shift(get(appr_var), type = "lead"), by = cvar]
    setorder(dt, .row)
    ga <- as.data.frame(dt)
  }

  ga$cfe <- factor(ga[[cvar]])
  ctrl4 <- intersect(c("growth", "log_inflation", "execrlc", "election_qtr"), nms)
  f4 <- as.formula(paste("dv ~ attack * woman +", paste(ctrl4, collapse = " + "), "| cfe"))
  m4 <- feols(f4, data = ga)
  print(summary(m4))
  cf <- coef(m4)
  put("intl_attack_table4", cf["attack"])
  put("intl_attack_x_woman_exec_table4", cf["attack:woman"])
  put("n_obs_table4", nobs(m4))
}, error = function(e) message("Table 4 error: ", conditionMessage(e)))

## ---------------- Table 2: panel DiD ----------------
tryCatch({
  dd <- strip(read_dta(file.path(base, "did_data.dta")))
  dd <- as.data.table(dd)
  nms <- names(dd)

  # Treatment: surveyed after the attack in wave 12 (respondent-level group)
  tr_var <- intersect(c("treatment1", "treatment2", "post_attack"), nms)[1]
  message("treatment variable: ", tr_var)
  dd[, treat := get(tr_var)]
  # If the treatment is only defined in some waves, propagate it to the respondent
  if (dd[time == 0, mean(is.na(treat))] > 0.5) {
    dd[, treat := suppressWarnings(max(treat, na.rm = TRUE)), by = id]
    dd[!is.finite(treat), treat := NA]
  }

  # Controls; missing income/ideology recoded to scale midpoint
  for (v in c("income", "ideology")) {
    if (v %in% nms) {
      x <- dd[[v]]
      mid <- (min(x, na.rm = TRUE) + max(x, na.rm = TRUE)) / 2
      x[is.na(x)] <- mid
      set(dd, j = v, value = x)
    }
  }
  ctrl <- intersect(c("white", "gender", "labour", "party_other", "income", "ideology"), nms)

  # Outcomes
  dd[, likemay := likeMayW]
  dd[!(likemay >= 0 & likemay <= 10), likemay := NA]
  bp <- if ("may_bestpm" %in% nms) dd$may_bestpm else dd$bestPMW
  bp[!(bp %in% c(0, 1))] <- NA
  dd[, bestpm := bp]
  dd[, wavef := factor(wave)]

  rhs <- paste("treat + time + treat:time +", paste(ctrl, collapse = " + "), "+ wavef")

  d1 <- dd[complete.cases(dd[, c("likemay", "treat", "time", "wave", ctrl), with = FALSE])]
  m1 <- lm(as.formula(paste("likemay ~", rhs)), data = d1)
  c1 <- coef(m1)
  print(c1[c("treat", "time", "treat:time")])
  put("did_attack_x_time_like_may_table2", c1["treat:time"])
  put("did_attack_like_may_table2", c1["treat"])
  put("did_time_like_may_table2", c1["time"])
  put("n_obs_did_like_may_table2", nobs(m1))
  rm(m1); gc()

  d2 <- dd[complete.cases(dd[, c("bestpm", "treat", "time", "wave", ctrl), with = FALSE])]
  m2 <- glm(as.formula(paste("bestpm ~", rhs)), data = d2, family = binomial("logit"))
  c2 <- coef(m2)
  print(c2[c("treat", "time", "treat:time")])
  put("did_attack_x_time_may_best_pm_table2", c2["treat:time"])
  put("did_attack_may_best_pm_table2", c2["treat"])
  put("did_time_may_best_pm_table2", c2["time"])
  put("n_obs_did_may_best_pm_table2", nobs(m2))
}, error = function(e) message("Table 2 error: ", conditionMessage(e)))

## ---------------- Output ----------------
out_names <- c("intl_attack_table4", "intl_attack_x_woman_exec_table4", "n_obs_table4",
               "did_attack_x_time_like_may_table2", "did_attack_like_may_table2",
               "did_time_like_may_table2", "did_attack_x_time_may_best_pm_table2",
               "did_attack_may_best_pm_table2", "did_time_may_best_pm_table2",
               "n_obs_did_like_may_table2", "n_obs_did_may_best_pm_table2")
for (nm in out_names) {
  v <- res[[nm]]
  v <- if (is.null(v)) NA else unname(as.numeric(v))
  cat(sprintf("RESULT:%s=%s\n", nm, format(v, digits = 10)))
}
