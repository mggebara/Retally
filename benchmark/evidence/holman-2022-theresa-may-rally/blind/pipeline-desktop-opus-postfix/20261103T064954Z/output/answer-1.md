suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- '<repo>/.cache/datasets/holman_2022_theresa_may_rally.script-free'
num <- function(x) as.numeric(haven::zap_labels(x))
fmt <- function(x) formatC(as.numeric(x), digits = 10, format = 'g')
mid_recode <- function(x) {
  x <- num(x)
  if (any(is.na(x)) && any(!is.na(x))) {
    m <- (min(x, na.rm = TRUE) + max(x, na.rm = TRUE)) / 2
    x[is.na(x)] <- m
  }
  x
}
safe_coef <- function(m, nm) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (nm %in% names(cf)) unname(cf[nm]) else NA_real_
}

results <- list()

## ---------------------------------------------------------------
## Table 4: cross-national TSCS of executive approval
## ---------------------------------------------------------------
ga <- haven::read_dta(file.path(base, 'global_approval.dta'))
ga <- as.data.frame(ga)
cat(sprintf('SAMPLE:table4:loaded=%d\n', nrow(ga)))
nms <- names(ga)

# panel id and time
pid <- if ('country_code' %in% nms) 'country_code' else if ('ccode' %in% nms) 'ccode' else 'country'
ga$pid <- num(ga[[pid]])
if (all(is.na(ga$pid))) ga$pid <- as.numeric(factor(as.character(ga[[pid]])))
ga$tq <- num(ga$qtr)

# approval variable
appr_candidates <- c('approval', 'exec_approval', 'approve', 'approval_rating')
appr_var <- appr_candidates[appr_candidates %in% nms]
if (length(appr_var) == 0) {
  cand <- grep('approv', nms, value = TRUE, ignore.case = TRUE)
  cand <- cand[!grepl('lag', cand, ignore.case = TRUE)]
  appr_var <- cand
}
lead_candidates <- grep('^(f_|lead_|f1_|F_)approv|approv.*(_lead|_f1|_next)$', nms, value = TRUE, ignore.case = TRUE)

ga <- ga[order(ga$pid, ga$tq), ]
if (length(lead_candidates) > 0) {
  ga$dv <- num(ga[[lead_candidates[1]]])
} else if (length(appr_var) > 0) {
  a <- num(ga[[appr_var[1]]])
  ga$dv <- ave(seq_along(a), ga$pid, FUN = function(i) {
    out <- rep(NA_real_, length(i))
    tq <- ga$tq[i]
    for (k in seq_along(i)) {
      j <- which(tq == tq[k] + 1)
      if (length(j) == 1) out[k] <- a[i[j]]
    }
    out
  })
} else {
  ga$dv <- NA_real_
}

# attack indicator: international attack with more than 15 deaths
att_var <- if ('kill_16' %in% nms) 'kill_16' else if ('pres_15death' %in% nms) 'pres_15death' else 'manchester'
ga$attack <- num(ga[[att_var]])
ga$attack[!is.na(ga$attack) & ga$attack > 1] <- 1
ga$woman <- num(ga$female_pres)
ga$growth_c <- num(ga$growth)
ga$loginf <- num(ga$log_inflation)
ga$elec <- num(ga$election_qtr)
ga$rlc <- factor(num(ga$execrlc))

ga4 <- ga[!is.na(ga$dv), ]
cat(sprintf('SAMPLE:table4:next_quarter_approval_nonmissing=%d\n', nrow(ga4)))

m4 <- tryCatch(
  feols(dv ~ attack * woman + growth_c + loginf + rlc + elec | pid,
        data = ga4, cluster = ~pid),
  error = function(e) { message(e$message); NULL })
n4 <- if (is.null(m4)) NA else nobs(m4)
cat(sprintf('SAMPLE:table4:estimation=%s\n', ifelse(is.na(n4), 'NA', as.character(n4))))

results$intl_attack_table4 <- safe_coef(m4, 'attack')
results$intl_attack_x_woman_exec_table4 <- safe_coef(m4, 'attack:woman')
results$n_obs_table4 <- n4

rm(ga, ga4); invisible(gc())

## ---------------------------------------------------------------
## Table 2: panel difference-in-differences with wave fixed effects
## ---------------------------------------------------------------
dd <- haven::read_dta(file.path(base, 'did_data.dta'))
dd <- as.data.frame(dd)
cat(sprintf('SAMPLE:did_like_may:loaded=%d\n', nrow(dd)))
cat(sprintf('SAMPLE:did_may_best_pm:loaded=%d\n', nrow(dd)))

dd$wave_f <- num(dd$wave)
dd$attack <- num(dd$treatment1)
dd$time_v <- num(dd$time)
dd$white_v <- num(dd$white)
dd$gender_v <- num(dd$gender)
dd$labour_v <- num(dd$labour)
dd$other_v <- num(dd$party_other)
inc <- num(dd$income); inc[!is.na(inc) & inc > 15] <- NA
dd$income_v <- mid_recode(inc)
ideo <- num(dd$ideology); ideo[!is.na(ideo) & ideo > 10] <- NA
dd$ideology_v <- mid_recode(ideo)

lm_ <- num(dd$likeMayW); lm_[!is.na(lm_) & (lm_ > 10 | lm_ < 0)] <- NA
dd$like_may <- lm_

# May best PM: 1 = May, 0 = Corbyn
mb <- num(dd$may_bestpm)
use_mb <- FALSE
if (any(!is.na(mb))) {
  w_with <- unique(dd$wave_f[!is.na(mb)])
  if (length(w_with) > 1 && all(mb[!is.na(mb)] %in% c(0, 1))) use_mb <- TRUE
}
if (use_mb) {
  dd$best_pm <- mb
} else {
  bp <- num(dd$bestPMW)
  dd$best_pm <- ifelse(bp == 1, 1, ifelse(bp == 2, 0, NA_real_))
}

ctrl <- '+ white_v + gender_v + labour_v + other_v + income_v + ideology_v'

d1 <- dd[!is.na(dd$like_may), ]
cat(sprintf('SAMPLE:did_like_may:like_may_nonmissing=%d\n', nrow(d1)))
m_like <- tryCatch(
  feols(as.formula(paste('like_may ~ attack * time_v', ctrl, '| wave_f')),
        data = d1, cluster = ~id),
  error = function(e) { message(e$message); NULL })
n_like <- if (is.null(m_like)) NA else nobs(m_like)
cat(sprintf('SAMPLE:did_like_may:estimation=%s\n', ifelse(is.na(n_like), 'NA', as.character(n_like))))
rm(d1); invisible(gc())

d2 <- dd[!is.na(dd$best_pm), ]
cat(sprintf('SAMPLE:did_may_best_pm:may_or_corbyn_best_pm=%d\n', nrow(d2)))
m_pm <- tryCatch(
  feglm(as.formula(paste('best_pm ~ attack * time_v', ctrl, '| wave_f')),
        data = d2, family = binomial(link = 'logit'), cluster = ~id),
  error = function(e) { message(e$message); NULL })
n_pm <- if (is.null(m_pm)) NA else nobs(m_pm)
cat(sprintf('SAMPLE:did_may_best_pm:estimation=%s\n', ifelse(is.na(n_pm), 'NA', as.character(n_pm))))

results$did_attack_x_time_like_may_table2 <- safe_coef(m_like, 'attack:time_v')
results$did_attack_like_may_table2 <- safe_coef(m_like, 'attack')
results$did_time_like_may_table2 <- safe_coef(m_like, 'time_v')
results$did_attack_x_time_may_best_pm_table2 <- safe_coef(m_pm, 'attack:time_v')
results$did_attack_may_best_pm_table2 <- safe_coef(m_pm, 'attack')
results$did_time_may_best_pm_table2 <- safe_coef(m_pm, 'time_v')
results$n_obs_did_like_may_table2 <- n_like
results$n_obs_did_may_best_pm_table2 <- n_pm

## ---------------------------------------------------------------
for (nm in names(results)) {
  cat(sprintf('RESULT:%s=%s\n', nm, fmt(results[[nm]])))
}
