suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/holman_2022_theresa_may_rally.script-free"

res <- list()
emit <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0 || is.na(v)) v <- NA
  cat(sprintf("RESULT:%s=%s\n", name, ifelse(is.na(v), "NA", format(v, digits = 10))))
}

num <- function(x) as.numeric(haven::zap_labels(x))

pick <- function(nms, cands) {
  for (c in cands) if (c %in% nms) return(c)
  NA_character_
}

## ---------------------------------------------------------------
## Table 4: cross-national TSCS of executive approval
## ---------------------------------------------------------------
t4 <- tryCatch({
  ga <- haven::read_dta(file.path(base, "global_approval.dta"))
  ga <- as.data.frame(lapply(ga, function(x) if (is.numeric(x) || inherits(x, "haven_labelled")) num(x) else x),
                      stringsAsFactors = FALSE)
  nms <- names(ga)
  cat("global_approval columns:", paste(nms, collapse = ", "), "\n")

  # Attack indicator: international attack with more than 15 deaths
  att <- pick(nms, c("kill_15", "intl_15death", "kill15", "kill_16", "rally_kill"))
  if (is.na(att)) stop("no attack var")
  ga$attack <- as.numeric(ga[[att]] > 0)
  cat("Attack variable used:", att, "\n")

  fem <- pick(nms, c("female_pres", "female_exec", "woman_exec", "female"))
  ga$woman <- as.numeric(ga[[fem]])

  # Dependent variable: approval in the quarter following the attack
  lead_dv <- pick(nms, c("lead_approval", "f_approval", "approval_lead", "f1_approval",
                         "approval_next", "approval_f1", "lead_approve", "F_approval"))
  cid <- pick(nms, c("ccode", "country_code", "country"))
  tvar <- pick(nms, c("qtr", "quarter", "date", "time"))
  if (!is.na(lead_dv)) {
    ga$dv <- as.numeric(ga[[lead_dv]])
    cat("DV used:", lead_dv, "\n")
  } else {
    appr <- pick(nms, c("approval", "approve", "exec_approval", "approval_smoothed",
                        grep("approv", nms, value = TRUE)[!grepl("lag", grep("approv", nms, value = TRUE))]))
    cat("Approval variable used (lead constructed):", appr, "\n")
    ga <- ga %>% mutate(.ord = row_number()) %>%
      arrange(.data[[cid]], .data[[tvar]]) %>%
      group_by(.data[[cid]]) %>%
      mutate(.t = as.numeric(.data[[tvar]]),
             dv = ifelse(dplyr::lead(.t) == .t + 1, dplyr::lead(.data[[appr]]), NA_real_)) %>%
      ungroup() %>% as.data.frame()
    # if quarter variable isn't consecutive integers, fall back to simple lead
    if (all(is.na(ga$dv))) {
      ga <- ga %>% group_by(.data[[cid]]) %>%
        mutate(dv = dplyr::lead(.data[[appr]])) %>% ungroup() %>% as.data.frame()
    }
  }

  ga$cfe <- ga[[cid]]
  ctrl <- c("growth", "log_inflation", "execrlc", "election_qtr")
  ctrl <- ctrl[ctrl %in% nms]
  d4 <- ga[complete.cases(ga[, c("dv", "attack", "woman", ctrl, "cfe")]), ]
  fml <- as.formula(paste("dv ~ attack * woman +", paste(ctrl, collapse = " + "), "| cfe"))
  m4 <- feols(fml, data = d4, cluster = ~cfe)
  print(summary(m4))
  list(b_att = coef(m4)["attack"], b_int = coef(m4)["attack:woman"], n = nobs(m4))
}, error = function(e) { cat("Table 4 error:", conditionMessage(e), "\n"); list(b_att = NA, b_int = NA, n = NA) })

## ---------------------------------------------------------------
## Table 2: panel difference-in-differences
## ---------------------------------------------------------------
t2 <- tryCatch({
  keep <- c("wave", "gender", "labour", "party_other", "income", "ideology", "ideology2", "ideo3",
            "white", "time", "treatment1", "post_attack", "likeMayW", "may_bestpm", "bestPMW", "id")
  dd <- haven::read_dta(file.path(base, "did_data.dta"))
  keep <- keep[keep %in% names(dd)]
  dd <- as.data.frame(lapply(dd[, keep], num))
  rm_list <- NULL

  # Treatment: surveyed after the attack within wave 12 (respondent-level)
  trt <- if ("treatment1" %in% names(dd)) "treatment1" else "post_attack"
  dd$attack <- dd[[trt]]
  cat("Treatment variable:", trt, " table:\n"); print(table(dd$attack, useNA = "ifany"))
  cat("time by wave:\n"); print(table(dd$wave, dd$time, useNA = "ifany"))

  # Controls with midpoint recoding for missing ideology and income
  mid <- function(x) { r <- range(x, na.rm = TRUE); m <- (r[1] + r[2]) / 2; x[is.na(x)] <- m; x }
  dd$ideo_c <- mid(dd$ideology)
  dd$inc_c <- mid(dd$income)

  dd$likeMay <- dd$likeMayW
  dd$likeMay[!is.na(dd$likeMay) & (dd$likeMay < 0 | dd$likeMay > 10)] <- NA

  # May best PM: 1 = May, 0 = Corbyn
  dd$bestpm <- dd$may_bestpm
  dd$bestpm[!(dd$bestpm %in% c(0, 1))] <- NA
  nwave_bpm <- length(unique(dd$wave[!is.na(dd$bestpm)]))
  if (nwave_bpm < 2 && "bestPMW" %in% names(dd)) {
    cat("Constructing best-PM outcome from bestPMW\n"); print(table(dd$bestPMW, useNA = "ifany"))
    dd$bestpm <- ifelse(dd$bestPMW == 1, 1, ifelse(dd$bestPMW == 2, 0, NA))
  }

  dd$wavef <- factor(dd$wave)
  ctrl <- c("white", "gender", "labour", "party_other", "inc_c", "ideo_c")
  ctrl <- ctrl[ctrl %in% names(dd)]
  rhs <- paste("attack + time + attack:time +", paste(ctrl, collapse = " + "), "+ wavef")

  d1 <- dd[complete.cases(dd[, c("likeMay", "attack", "time", ctrl, "wavef")]), ]
  m1 <- lm(as.formula(paste("likeMay ~", rhs)), data = d1)
  print(coef(m1)[c("attack", "time", "attack:time")])

  d2 <- dd[complete.cases(dd[, c("bestpm", "attack", "time", ctrl, "wavef")]), ]
  m2 <- glm(as.formula(paste("bestpm ~", rhs)), data = d2, family = binomial("logit"))
  print(coef(m2)[c("attack", "time", "attack:time")])

  list(l_int = coef(m1)["attack:time"], l_att = coef(m1)["attack"], l_time = coef(m1)["time"],
       b_int = coef(m2)["attack:time"], b_att = coef(m2)["attack"], b_time = coef(m2)["time"],
       n1 = nobs(m1), n2 = nobs(m2))
}, error = function(e) { cat("Table 2 error:", conditionMessage(e), "\n")
  list(l_int = NA, l_att = NA, l_time = NA, b_int = NA, b_att = NA, b_time = NA, n1 = NA, n2 = NA) })

emit("intl_attack_table4", t4$b_att)
emit("intl_attack_x_woman_exec_table4", t4$b_int)
emit("n_obs_table4", t4$n)
emit("did_attack_x_time_like_may_table2", t2$l_int)
emit("did_attack_like_may_table2", t2$l_att)
emit("did_time_like_may_table2", t2$l_time)
emit("did_attack_x_time_may_best_pm_table2", t2$b_int)
emit("did_attack_may_best_pm_table2", t2$b_att)
emit("did_time_may_best_pm_table2", t2$b_time)
emit("n_obs_did_like_may_table2", t2$n1)
emit("n_obs_did_may_best_pm_table2", t2$n2)
