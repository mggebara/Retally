suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- '<repo>/.cache/datasets/holman_2022_theresa_may_rally.script-free'

res <- list()
put <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0 || is.na(v[1])) v <- NA
  res[[name]] <<- v[1]
}
strip <- function(df) {
  df <- as.data.frame(df)
  for (v in names(df)) {
    x <- df[[v]]
    if (inherits(x, "haven_labelled") || inherits(x, "labelled")) x <- zap_labels(x)
    attr(x, "label") <- NULL
    attr(x, "format.stata") <- NULL
    df[[v]] <- x
  }
  df
}
isbin <- function(x) {
  u <- unique(x[!is.na(x)])
  length(u) > 0 && all(u %in% c(0, 1))
}

############################ Table 4 ############################
tryCatch({
  g <- strip(read_dta(file.path(base, "global_approval.dta")))
  cat("global_approval columns:\n"); print(names(g))
  nm <- names(g)
  fe_var <- if ("country" %in% nm) "country" else if ("ccode" %in% nm) "ccode" else "country_code"
  woman <- if ("female_pres" %in% nm) "female_pres" else nm[grepl("female|woman", nm, ignore.case = TRUE)][1]
  g[[woman]] <- as.numeric(g[[woman]])

  # Attack variable detection
  attack <- NULL
  binary_cols <- nm[sapply(nm, function(v) is.numeric(g[[v]]) && isbin(g[[v]]))]
  pref <- c("kill_16", "intl_15", "death15", "attack15", "intl_attack", "kill16", "kill_15")
  if ("pres_15death" %in% nm) {
    p <- as.numeric(g$pres_15death)
    ok <- !is.na(p) & !is.na(g[[woman]])
    is_inter <- isbin(p) && all(g[[woman]][ok & p == 1] == 1) && !all(p[ok] == g[[woman]][ok])
    if (is_inter) {
      cands <- unique(c(pref[pref %in% binary_cols], setdiff(binary_cols, c(woman, "pres_15death", "pres_20death"))))
      for (cv in cands) {
        x <- as.numeric(g[[cv]])
        o2 <- ok & !is.na(x)
        if (sum(o2) > 0.9 * sum(ok) && all((x[o2] * g[[woman]][o2]) == p[o2]) && sum(x[o2]) > sum(p[o2])) {
          attack <- cv; break
        }
      }
    } else {
      attack <- "pres_15death"
    }
  }
  if (is.null(attack)) {
    attack <- pref[pref %in% nm][1]
    if (is.na(attack)) attack <- "rally_kill"
  }
  cat("Attack variable:", attack, " Woman exec variable:", woman, "\n")
  g$attack_v <- as.numeric(g[[attack]])
  g$woman_v <- g[[woman]]
  g$inter_v <- g$attack_v * g$woman_v

  # DV detection
  appcols <- nm[grepl("approv", nm, ignore.case = TRUE) & !grepl("^lag", nm, ignore.case = TRUE)]
  cat("Approval candidates:", appcols, "\n")
  lead_cands <- appcols[grepl("lead|^f_|_f$|next|fwd|f1", appcols, ignore.case = TRUE)]
  ctrls <- intersect(c("growth", "log_inflation", "execrlc", "election_qtr"), nm)

  g <- g[order(g[[fe_var]], g$qtr), ]
  specs <- list()
  if (length(lead_cands) > 0) {
    specs[["lead_var"]] <- lead_cands[1]
  }
  main_app <- if ("approval" %in% appcols) "approval" else if (length(setdiff(appcols, lead_cands)) > 0) setdiff(appcols, lead_cands)[1] else NA
  if (!is.na(main_app)) {
    specs[["contemp"]] <- main_app
    g$app_lead_constructed <- ave(as.numeric(g[[main_app]]), g[[fe_var]],
                                  FUN = function(z) c(z[-1], NA))
    specs[["constructed_lead"]] <- "app_lead_constructed"
  }
  fits <- list()
  for (s in names(specs)) {
    f <- as.formula(paste0(specs[[s]], " ~ attack_v + woman_v + inter_v",
                           if (length(ctrls)) paste0(" + ", paste(ctrls, collapse = " + ")) else "",
                           " | ", fe_var))
    m <- tryCatch(feols(f, data = g, warn = FALSE, notes = FALSE), error = function(e) NULL)
    if (!is.null(m)) {
      fits[[s]] <- m
      cat("Spec", s, "DV", specs[[s]], "N =", nobs(m), "\n")
      print(coeftable(m))
    }
  }
  # Prefer an explicit lead variable; otherwise the spec whose sample matches the described 4,359 country-quarters
  chosen <- NULL
  if ("lead_var" %in% names(fits)) chosen <- "lead_var"
  if (is.null(chosen) && length(fits) > 0) {
    d <- sapply(fits, function(m) abs(nobs(m) - 4359))
    chosen <- names(fits)[which.min(d)]
  }
  cat("Chosen Table 4 spec:", chosen, "\n")
  m4 <- fits[[chosen]]
  put("intl_attack_table4", coef(m4)["attack_v"])
  put("intl_attack_x_woman_exec_table4", coef(m4)["inter_v"])
  put("n_obs_table4", nobs(m4))
}, error = function(e) cat("Table 4 error:", conditionMessage(e), "\n"))

############################ Table 2 ############################
tryCatch({
  d <- strip(read_dta(file.path(base, "did_data.dta")))
  cat("did_data columns:\n"); print(names(d))
  nm <- names(d)

  # treatment group: indicator constant within respondent
  treat <- NULL
  for (cv in c("treatment1", "treatment2", "post_attack")) {
    if (cv %in% nm && isbin(d[[cv]])) {
      tmp <- d[!is.na(d[[cv]]), c("id", cv)]
      sdv <- tapply(tmp[[cv]], tmp$id, function(z) length(unique(z)))
      cat(cv, ": share ids with constant value =", mean(sdv == 1), " mean =", mean(tmp[[cv]]), "\n")
      if (mean(sdv == 1) > 0.999) { treat <- cv; break }
    }
  }
  if (is.null(treat)) treat <- "treatment1"
  cat("Treatment variable:", treat, "\n")
  d$treat_v <- as.numeric(d[[treat]])
  d$time_v <- as.numeric(d$time)
  d$wave_f <- as.numeric(d$wave)

  # controls with midpoint recode for income / ideology
  for (v in c("income", "ideology")) {
    x <- as.numeric(d[[v]])
    mid <- (min(x, na.rm = TRUE) + max(x, na.rm = TRUE)) / 2
    if (v == "ideology" && max(x, na.rm = TRUE) <= 10 && min(x, na.rm = TRUE) >= 0) mid <- 5
    x[is.na(x)] <- mid
    d[[paste0(v, "_r")]] <- x
  }
  ctrls <- c("white", "gender", "labour", "party_other", "income_r", "ideology_r")
  ctrls <- ctrls[ctrls %in% names(d)]
  for (v in ctrls) d[[v]] <- as.numeric(d[[v]])
  cat("Controls:", ctrls, "\n")

  rhs <- paste0("treat_v + time_v + i(wave_f) + ", paste(ctrls, collapse = " + "), " + treat_v:time_v")

  d$likeMay <- as.numeric(d$likeMayW)
  d$likeMay[d$likeMay < 0 | d$likeMay > 10] <- NA
  m_like <- feols(as.formula(paste0("likeMay ~ ", rhs)), data = d, warn = FALSE, notes = FALSE)
  print(coeftable(m_like))
  put("did_attack_x_time_like_may_table2", coef(m_like)["treat_v:time_v"])
  put("did_attack_like_may_table2", coef(m_like)["treat_v"])
  put("did_time_like_may_table2", coef(m_like)["time_v"])
  put("n_obs_did_like_may_table2", nobs(m_like))

  d$bestpm <- as.numeric(d$may_bestpm)
  if (!isbin(d$bestpm)) d$bestpm[!(d$bestpm %in% c(0, 1))] <- NA
  m_pm <- feglm(as.formula(paste0("bestpm ~ ", rhs)), data = d, family = binomial("logit"),
                warn = FALSE, notes = FALSE)
  print(coeftable(m_pm))
  put("did_attack_x_time_may_best_pm_table2", coef(m_pm)["treat_v:time_v"])
  put("did_attack_may_best_pm_table2", coef(m_pm)["treat_v"])
  put("did_time_may_best_pm_table2", coef(m_pm)["time_v"])
  put("n_obs_did_may_best_pm_table2", nobs(m_pm))
}, error = function(e) cat("Table 2 error:", conditionMessage(e), "\n"))

names_out <- c("intl_attack_table4", "intl_attack_x_woman_exec_table4", "n_obs_table4",
               "did_attack_x_time_like_may_table2", "did_attack_like_may_table2", "did_time_like_may_table2",
               "did_attack_x_time_may_best_pm_table2", "did_attack_may_best_pm_table2", "did_time_may_best_pm_table2",
               "n_obs_did_like_may_table2", "n_obs_did_may_best_pm_table2")
for (n in names_out) {
  v <- if (!is.null(res[[n]])) res[[n]] else NA
  cat(sprintf("RESULT:%s=%s\n", n, ifelse(is.na(v), "NA", format(v, digits = 10))))
}
