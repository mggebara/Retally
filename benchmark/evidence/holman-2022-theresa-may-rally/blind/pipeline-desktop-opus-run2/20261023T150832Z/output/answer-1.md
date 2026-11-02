suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/holman_2022_theresa_may_rally.script-free"

out <- list(
  intl_attack_table4 = NA, intl_attack_x_woman_exec_table4 = NA, n_obs_table4 = NA,
  did_attack_x_time_like_may_table2 = NA, did_attack_like_may_table2 = NA, did_time_like_may_table2 = NA,
  did_attack_x_time_may_best_pm_table2 = NA, did_attack_may_best_pm_table2 = NA, did_time_may_best_pm_table2 = NA,
  n_obs_did_like_may_table2 = NA, n_obs_did_may_best_pm_table2 = NA
)

findvar <- function(df, cands) {
  nm <- names(df)
  for (c in cands) {
    hit <- nm[tolower(nm) == tolower(c)]
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}
num <- function(x) as.numeric(zap_labels(x))

# ---------------- Table 4: cross-national TSCS ----------------
tryCatch({
  g <- read_dta(file.path(base, "global_approval.dta"))
  g <- as.data.frame(zap_labels(g))
  nm <- names(g)
  cat("global_approval columns:", paste(nm, collapse = ", "), "\n")

  # dependent variable: approval in the quarter following the attack
  leadv <- nm[grepl("approv", nm, ignore.case = TRUE) &
                grepl("lead|^f_|^f\\.|next|_f$|fwd|forward", nm, ignore.case = TRUE)]
  cid <- findvar(g, c("ccode", "country_code", "country"))
  tq <- findvar(g, c("qtr", "quarter", "date"))
  if (length(leadv) > 0) {
    g$dv <- num(g[[leadv[1]]])
    cat("Using lead approval variable:", leadv[1], "\n")
  } else {
    apv <- findvar(g, c("approval", "approve", "exec_approval", "approval_smoothed"))
    if (is.na(apv)) {
      cand <- nm[grepl("approv", nm, ignore.case = TRUE) & !grepl("lag", nm, ignore.case = TRUE)]
      apv <- cand[1]
    }
    cat("Approval variable:", apv, "; computing next-quarter lead within", cid, "by", tq, "\n")
    g$apv_ <- num(g[[apv]])
    g$cid_ <- g[[cid]]
    g$tq_ <- suppressWarnings(as.numeric(g[[tq]]))
    g <- g[order(g$cid_, g$tq_), ]
    g <- g %>% group_by(cid_) %>%
      mutate(nxt_t = dplyr::lead(tq_), nxt_a = dplyr::lead(apv_),
             dv = ifelse(!is.na(nxt_t) & !is.na(tq_) & (nxt_t - tq_) == 1, nxt_a, NA_real_)) %>%
      ungroup() %>% as.data.frame()
    if (all(is.na(g$dv))) g <- g %>% group_by(cid_) %>% mutate(dv = dplyr::lead(apv_)) %>% ungroup() %>% as.data.frame()
  }

  fem <- findvar(g, c("female_pres", "woman_exec", "female"))
  g$woman <- num(g[[fem]])

  # attack indicator: international attack with more than 15 deaths
  killvars <- nm[grepl("^kill", nm, ignore.case = TRUE) | tolower(nm) == "rally_kill"]
  att <- NA_character_
  if ("pres_15death" %in% nm && length(killvars) > 0) {
    p15 <- num(g$pres_15death)
    best <- -1
    for (k in killvars) {
      kv <- num(g[[k]])
      ok <- !is.na(kv) & !is.na(p15) & !is.na(g$woman)
      if (sum(ok) == 0) next
      if (!all(kv[ok] %in% c(0, 1))) next
      m <- mean((kv[ok] * g$woman[ok]) == p15[ok])
      if (m > best || (m == best && grepl("15", k))) { best <- m; att <- k }
    }
    if (best < 0.999 || sum(num(g[[att]]) * g$woman, na.rm = TRUE) == 0) att <- NA_character_
  }
  if (is.na(att)) att <- findvar(g, c("kill_15", "kill_16", "rally_kill", "kill"))
  cat("Attack variable:", att, "\n")
  g$attack <- num(g[[att]])
  g$attack[is.na(g$attack)] <- NA

  g$growth_ <- num(g[[findvar(g, c("growth", "gdp_growth"))]])
  g$loginf_ <- num(g[[findvar(g, c("log_inflation", "loginflation"))]])
  rl <- num(g[[findvar(g, c("execrlc"))]])
  rl[!is.na(rl) & rl < 0] <- NA
  g$execrlc_ <- rl
  g$elec_ <- num(g[[findvar(g, c("election_qtr", "election"))]])
  g$cfe <- g[[cid]]

  m4 <- feols(dv ~ attack * woman + growth_ + loginf_ + execrlc_ + elec_ | cfe, data = g)
  print(summary(m4))
  cf <- coef(m4)
  out$intl_attack_table4 <- unname(cf["attack"])
  out$intl_attack_x_woman_exec_table4 <- unname(cf["attack:woman"])
  out$n_obs_table4 <- nobs(m4)
}, error = function(e) cat("Table 4 error:", conditionMessage(e), "\n"))

# ---------------- Table 2: difference-in-differences ----------------
tryCatch({
  d <- read_dta(file.path(base, "did_data.dta"))
  d <- as.data.frame(zap_labels(d))
  cat("did_data columns:", paste(names(d), collapse = ", "), "\n")

  d$wave_ <- num(d[[findvar(d, c("wave"))]])
  d$time_ <- num(d[[findvar(d, c("time"))]])
  pa <- num(d[[findvar(d, c("post_attack"))]])
  idv <- findvar(d, c("id"))
  # treatment group: respondent surveyed after the attack in wave 12 (respondent-level)
  grp <- ave(ifelse(is.na(pa), -Inf, pa), d[[idv]], FUN = max)
  grp[is.infinite(grp)] <- NA
  d$attack_ <- grp
  d$attack_time_ <- d$attack_ * d$time_
  cat("post_attack within-id variation check: share rows pa != grp:",
      mean(pa != grp, na.rm = TRUE), "\n")

  lm_ <- num(d[[findvar(d, c("likeMayW"))]])
  lm_[!is.na(lm_) & (lm_ < 0 | lm_ > 10)] <- NA
  d$likemay_ <- lm_
  bp <- num(d[[findvar(d, c("may_bestpm"))]])
  bp[!is.na(bp) & !(bp %in% c(0, 1))] <- NA
  d$bestpm_ <- bp

  d$white_ <- num(d[[findvar(d, c("white"))]])
  d$gender_ <- num(d[[findvar(d, c("gender"))]])
  d$labour_ <- num(d[[findvar(d, c("labour"))]])
  d$other_ <- num(d[[findvar(d, c("party_other"))]])

  inc <- num(d[[findvar(d, c("income"))]])
  inc[!is.na(inc) & inc > 50] <- NA
  inc[is.na(inc)] <- (min(inc, na.rm = TRUE) + max(inc, na.rm = TRUE)) / 2
  d$income_ <- inc
  ide <- num(d[[findvar(d, c("ideology"))]])
  ide[!is.na(ide) & (ide < 0 | ide > 10)] <- NA
  ide[is.na(ide)] <- (min(ide, na.rm = TRUE) + max(ide, na.rm = TRUE)) / 2
  d$ideology_ <- ide

  d$wavef <- factor(d$wave_)
  keep <- c("likemay_", "bestpm_", "attack_", "time_", "attack_time_", "wavef",
            "white_", "gender_", "labour_", "other_", "income_", "ideology_")
  d <- d[, keep]
  gc()

  # time listed before the wave dummies: the collinear wave dummy is dropped (as in Stata)
  f1 <- likemay_ ~ attack_ + time_ + attack_time_ + wavef + white_ + gender_ + labour_ + other_ + income_ + ideology_
  m1 <- lm(f1, data = d)
  c1 <- coef(m1)
  print(c1)
  out$did_attack_x_time_like_may_table2 <- unname(c1["attack_time_"])
  out$did_attack_like_may_table2 <- unname(c1["attack_"])
  out$did_time_like_may_table2 <- unname(c1["time_"])
  out$n_obs_did_like_may_table2 <- nobs(m1)
  rm(m1); gc()

  f2 <- bestpm_ ~ attack_ + time_ + attack_time_ + wavef + white_ + gender_ + labour_ + other_ + income_ + ideology_
  m2 <- glm(f2, data = d, family = binomial(link = "logit"))
  c2 <- coef(m2)
  print(c2)
  out$did_attack_x_time_may_best_pm_table2 <- unname(c2["attack_time_"])
  out$did_attack_may_best_pm_table2 <- unname(c2["attack_"])
  out$did_time_may_best_pm_table2 <- unname(c2["time_"])
  out$n_obs_did_may_best_pm_table2 <- nobs(m2)
}, error = function(e) cat("Table 2 error:", conditionMessage(e), "\n"))

for (n in names(out)) {
  v <- out[[n]]
  if (is.null(v) || length(v) == 0) v <- NA
  cat(sprintf("RESULT:%s=%s\n", n, format(v, digits = 10)))
}
