suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- '<repo>/.cache/datasets/holman_2022_theresa_may_rally.script-free'
num <- function(x) if (is.null(x)) NULL else as.numeric(haven::zap_labels(x))
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
first_present <- function(cands, nms) {
  hit <- cands[cands %in% nms]
  if (length(hit) == 0) NULL else hit[1]
}
usable <- function(x) !is.null(x) && sum(!is.na(x)) > 0

results <- list()

## ---------------------------------------------------------------
## Table 4: cross-national TSCS of executive approval
## ---------------------------------------------------------------
ga <- haven::read_dta(file.path(base, 'global_approval.dta'))
ga <- as.data.frame(ga)
cat(sprintf('SAMPLE:table4:loaded=%d\n', nrow(ga)))
nms <- names(ga)
message('global_approval names: ', paste(nms, collapse = ', '))

# panel id
pid <- first_present(c('country_code', 'ccode', 'cowcode', 'country', 'countryname', 'country_name', 'iso3', 'cname'), nms)
if (is.null(pid)) pid <- grep('country|ccode', nms, value = TRUE, ignore.case = TRUE)[1]
if (is.na(pid) || is.null(pid)) {
  ga$pid <- 1
} else {
  ga$pid <- suppressWarnings(num(ga[[pid]]))
  if (all(is.na(ga$pid))) ga$pid <- as.numeric(factor(as.character(ga[[pid]])))
}
ga$pid[is.na(ga$pid)] <- -1

# time index
ga$row_order <- seq_len(nrow(ga))
tvar <- first_present(c('qtr', 'quarter', 'yq', 'yearqtr', 'year_qtr', 'qdate', 'date_q', 'time', 'period', 'date'), nms)
tq <- if (!is.null(tvar)) suppressWarnings(num(ga[[tvar]])) else NULL
if (!usable(tq)) {
  yr <- if ('year' %in% nms) num(ga$year) else NULL
  qq <- first_present(c('quarter', 'qtr', 'q'), nms)
  if (usable(yr) && !is.null(qq)) tq <- yr * 4 + num(ga[[qq]]) else if (usable(yr)) tq <- yr
}
if (!usable(tq)) tq <- ga$row_order
# if quarter coded 1-4 within year, combine with year
if (usable(tq) && max(tq, na.rm = TRUE) <= 4 && 'year' %in% nms) tq <- num(ga$year) * 4 + tq
ga$tq <- tq

# approval variable
appr_candidates <- c('approval', 'exec_approval', 'approve', 'approval_rating', 'approval_smoothed', 'net_approval')
appr_var <- appr_candidates[appr_candidates %in% nms]
if (length(appr_var) == 0) {
  cand <- grep('approv', nms, value = TRUE, ignore.case = TRUE)
  cand <- cand[!grepl('lag|lead|^f_|^f1_|_f1$|_next$', cand, ignore.case = TRUE)]
  appr_var <- cand
}
appr_var <- appr_var[vapply(appr_var, function(v) usable(suppressWarnings(num(ga[[v]]))), logical(1))]
lead_candidates <- grep('^(f_|lead_|f1_|F_|f\\.)approv|approv.*(_lead|_f1|_next|_f)$', nms, value = TRUE, ignore.case = TRUE)
lead_candidates <- lead_candidates[vapply(lead_candidates, function(v) usable(suppressWarnings(num(ga[[v]]))), logical(1))]

ga <- ga[order(ga$pid, ga$tq, ga$row_order), ]
ga$dv <- NA_real_
if (length(lead_candidates) > 0) {
  ga$dv <- num(ga[[lead_candidates[1]]])
}
if (!usable(ga$dv) && length(appr_var) > 0) {
  a <- num(ga[[appr_var[1]]])
  nxt_a <- ave(a, ga$pid, FUN = function(v) c(v[-1], NA))
  nxt_t <- ave(ga$tq, ga$pid, FUN = function(v) c(v[-1], NA))
  dt <- nxt_t - ga$tq
  step <- suppressWarnings(as.numeric(names(sort(table(dt[!is.na(dt) & dt > 0]), decreasing = TRUE))[1]))
  if (is.na(step)) step <- 1
  dv <- ifelse(!is.na(dt) & dt == step, nxt_a, NA_real_)
  if (!usable(dv)) dv <- nxt_a
  ga$dv <- dv
}
message('table4 dv source: ', if (length(lead_candidates) > 0) lead_candidates[1] else paste(appr_var, collapse = ','))

# attack indicator: international attack with more than 15 deaths
att_var <- first_present(c('kill_16', 'pres_15death', 'intl_attack', 'attack', 'manchester'), nms)
if (is.null(att_var)) {
  cand <- grep('kill|attack|terror|death', nms, value = TRUE, ignore.case = TRUE)
  att_var <- if (length(cand) > 0) cand[1] else NULL
}
ga$attack <- if (!is.null(att_var)) num(ga[[att_var]]) else NA_real_
ga$attack[!is.na(ga$attack) & ga$attack > 1] <- 1

getnum <- function(cands) {
  v <- first_present(cands, nms)
  if (is.null(v)) return(NULL)
  x <- num(ga[[v]])
  if (!usable(x)) NULL else x
}
wv <- getnum(c('female_pres', 'female_exec', 'woman', 'female', 'female_leader'))
ga$woman <- if (is.null(wv)) NA_real_ else wv
rhs <- c('attack * woman')
gv <- getnum(c('growth', 'gdp_growth')); if (!is.null(gv)) { ga$growth_c <- gv; rhs <- c(rhs, 'growth_c') }
iv <- getnum(c('log_inflation', 'loginf', 'inflation_log')); if (!is.null(iv)) { ga$loginf <- iv; rhs <- c(rhs, 'loginf') }
rv <- getnum(c('execrlc', 'rlc')); if (!is.null(rv)) { ga$rlc <- factor(rv); rhs <- c(rhs, 'rlc') }
ev <- getnum(c('election_qtr', 'election', 'elec')); if (!is.null(ev)) { ga$elec <- ev; rhs <- c(rhs, 'elec') }

ga4 <- ga[!is.na(ga$dv), ]
cat(sprintf('SAMPLE:table4:next_quarter_approval_nonmissing=%d\n', nrow(ga4)))

f4 <- as.formula(paste('dv ~', paste(rhs, collapse = ' + '), '| pid'))
m4 <- tryCatch(
  feols(f4, data = ga4, cluster = ~pid),
  error = function(e) { message(e$message); NULL })
if (is.null(m4)) {
  m4 <- tryCatch(
    feols(dv ~ attack * woman | pid, data = ga4, cluster = ~pid),
    error = function(e) { message(e$message); NULL })
}
if (!is.null(m4)) message('table4 coef names: ', paste(names(coef(m4)), collapse = ', '))
n4 <- if (is.null(m4)) NA else nobs(m4)
cat(sprintf('SAMPLE:table4:estimation=%s\n', ifelse(is.na(n4), 'NA', as.character(n4))))

int_nm <- if (!is.null(m4)) grep('^attack:woman$|^woman:attack$', names(coef(m4)), value = TRUE)[1] else NA
results$intl_attack_table4 <- safe_coef(m4, 'attack')
results$intl_attack_x_woman_exec_table4 <- if (is.na(int_nm)) NA_real_ else safe_coef(m4, int_nm)
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
# time main effect is absorbed by wave fixed effects; estimate it without wave FE
m_like_t <- tryCatch(
  feols(as.formula(paste('like_may ~ attack * time_v', ctrl)),
        data = d1, cluster = ~id),
  error = function(e) { message(e$message); NULL })
rm(d1); invisible(gc())

d2 <- dd[!is.na(dd$best_pm), ]
cat(sprintf('SAMPLE:did_may_best_pm:may_or_corbyn_best_pm=%d\n', nrow(d2)))
m_pm <- tryCatch(
  feglm(as.formula(paste('best_pm ~ attack * time_v', ctrl, '| wave_f')),
        data = d2, family = binomial(link = 'logit'), cluster = ~id),
  error = function(e) { message(e$message); NULL })
n_pm <- if (is.null(m_pm)) NA else nobs(m_pm)
cat(sprintf('SAMPLE:did_may_best_pm:estimation=%s\n', ifelse(is.na(n_pm), 'NA', as.character(n_pm))))
m_pm_t <- tryCatch(
  feglm(as.formula(paste('best_pm ~ attack * time_v', ctrl)),
        data = d2, family = binomial(link = 'logit'), cluster = ~id),
  error = function(e) { message(e$message); NULL })

results$did_attack_x_time_like_may_table2 <- safe_coef(m_like, 'attack:time_v')
results$did_attack_like_may_table2 <- safe_coef(m_like, 'attack')
results$did_time_like_may_table2 <- safe_coef(m_like_t, 'time_v')
results$did_attack_x_time_may_best_pm_table2 <- safe_coef(m_pm, 'attack:time_v')
results$did_attack_may_best_pm_table2 <- safe_coef(m_pm, 'attack')
results$did_time_may_best_pm_table2 <- safe_coef(m_pm_t, 'time_v')
results$n_obs_did_like_may_table2 <- n_like
results$n_obs_did_may_best_pm_table2 <- n_pm

## ---------------------------------------------------------------
for (nm in names(results)) {
  cat(sprintf('RESULT:%s=%s\n', nm, fmt(results[[nm]])))
}
