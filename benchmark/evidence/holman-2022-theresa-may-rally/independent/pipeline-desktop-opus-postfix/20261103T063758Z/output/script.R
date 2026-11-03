suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- '<repo>/.cache/datasets/holman_2022_theresa_may_rally.script-free'

num <- function(x) as.numeric(haven::zap_labels(x))

results <- list()

# ------------------------------------------------------------------
# Table 4: cross-national TSCS of executive approval
# ------------------------------------------------------------------
ga <- haven::read_dta(file.path(base, 'global_approval.dta'))
ga <- as.data.frame(lapply(ga, function(x) if (inherits(x, 'haven_labelled')) num(x) else x))
cat(sprintf('SAMPLE:table4:loaded=%d\n', nrow(ga)))
nm <- names(ga)

# Attack indicator: international attack with more than 15 deaths (16+)
att_var <- if ('kill_16' %in% nm) 'kill_16' else if ('pres_15death' %in% nm) 'pres_15death' else 'manchester'
ga$attack <- num(ga[[att_var]])
ga$woman <- num(ga$female_pres)

# Country identifier for fixed effects
cid <- if ('country_code' %in% nm) 'country_code' else if ('ccode' %in% nm) 'ccode' else 'country'
ga$cid <- ga[[cid]]
ga$qtr_n <- num(ga$qtr)

# Dependent variable: approval in the quarter following the attack
lead_cands <- grep('^(f_?|lead_?|F)approval|approval_?(lead|f1|next)', nm, value = TRUE, ignore.case = TRUE)
if (length(lead_cands) > 0) {
  ga$dv <- num(ga[[lead_cands[1]]])
  cat(sprintf('NOTE: using existing lead approval variable %s\n', lead_cands[1]))
} else {
  appr_cands <- setdiff(grep('approv', nm, value = TRUE, ignore.case = TRUE), 'lag_approval')
  appr_cands <- appr_cands[!grepl('lag', appr_cands, ignore.case = TRUE)]
  if (length(appr_cands) > 0) {
    av <- if ('approval' %in% appr_cands) 'approval' else appr_cands[1]
    ga$appr <- num(ga[[av]])
  } else {
    # reconstruct current approval from the lag of the next quarter
    ga <- ga %>% arrange(cid, qtr_n) %>% group_by(cid) %>%
      mutate(appr = ifelse(lead(qtr_n) == qtr_n + 1, lead(num(lag_approval)), NA_real_)) %>%
      ungroup() %>% as.data.frame()
    av <- 'lead(lag_approval)'
  }
  ga <- ga %>% arrange(cid, qtr_n) %>% group_by(cid) %>%
    mutate(dv = ifelse(!is.na(lead(qtr_n)) & lead(qtr_n) == qtr_n + 1, lead(appr), NA_real_)) %>%
    ungroup() %>% as.data.frame()
  cat(sprintf('NOTE: DV = next-quarter value of %s within country\n', av))
}

ga$growth <- num(ga$growth)
ga$log_inflation <- num(ga$log_inflation)
ga$execrlc <- num(ga$execrlc)
ga$election_qtr <- num(ga$election_qtr)

ga4 <- ga[!is.na(ga$dv), ]
cat(sprintf('SAMPLE:table4:nonmissing_next_quarter_approval=%d\n', nrow(ga4)))

m4 <- feols(dv ~ attack * woman + growth + log_inflation + execrlc + election_qtr | cid,
            data = ga4, cluster = ~cid)
cat(sprintf('SAMPLE:table4:estimation=%d\n', nobs(m4)))
if (abs(nobs(m4) - 4328) > 50) cat(sprintf('DEVIATION: Table 4 N = %d differs from paper 4328\n', nobs(m4)))
cf4 <- coef(m4)
results$intl_attack_table4 <- cf4['attack']
results$intl_attack_x_woman_exec_table4 <- cf4['attack:woman']
results$n_obs_table4 <- nobs(m4)

# ------------------------------------------------------------------
# Table 2: difference-in-differences on BES panel
# ------------------------------------------------------------------
dd <- haven::read_dta(file.path(base, 'did_data.dta'),
                      col_select = any_of(c('wave', 'id', 'time', 'treatment1', 'post_attack',
                                            'likeMayW', 'may_bestpm', 'bestPMW', 'white', 'gender',
                                            'labour', 'party_other', 'income', 'ideology')))
dd <- as.data.frame(lapply(dd, num))
cat(sprintf('SAMPLE:did_like:loaded=%d\n', nrow(dd)))
cat(sprintf('SAMPLE:did_bestpm:loaded=%d\n', nrow(dd)))

dd$treat <- if ('treatment1' %in% names(dd)) dd$treatment1 else dd$post_attack

# Recode missing income / ideology to scale midpoint
mid <- function(x) { r <- range(x, na.rm = TRUE); (r[1] + r[2]) / 2 }
dd$income[dd$income > 100 & !is.na(dd$income)] <- NA
dd$ideology[dd$ideology > 100 & !is.na(dd$ideology)] <- NA
dd$income[is.na(dd$income)] <- mid(dd$income)
dd$ideology[is.na(dd$ideology)] <- mid(dd$ideology)

dd$likeMayW[!is.na(dd$likeMayW) & (dd$likeMayW < 0 | dd$likeMayW > 10)] <- NA
dd$may_bestpm[!is.na(dd$may_bestpm) & !(dd$may_bestpm %in% c(0, 1))] <- NA

# Wave fixed effects; keep 'time' identified by dropping one extra wave dummy
time_const <- all(tapply(dd$time, dd$wave, function(z) length(unique(z[!is.na(z)])) <= 1))
waves <- sort(unique(dd$wave[!is.na(dd$wave)]))
if (time_const) {
  post_waves <- sort(unique(dd$wave[!is.na(dd$time) & dd$time == 1]))
  drop_w <- c(waves[1], post_waves[1])
  keep_w <- setdiff(waves, drop_w)
  wnames <- character(0)
  for (w in keep_w) {
    v <- paste0('wv_', w)
    dd[[v]] <- as.numeric(dd$wave == w)
    wnames <- c(wnames, v)
  }
  wfe <- paste(wnames, collapse = ' + ')
  fml_rhs <- paste('treat * time + white + gender + labour + party_other + income + ideology +', wfe)
  fe_part <- ''
} else {
  fml_rhs <- 'treat * time + white + gender + labour + party_other + income + ideology'
  fe_part <- ' | wave'
}

ctrl <- c('treat', 'time', 'white', 'gender', 'labour', 'party_other', 'income', 'ideology', 'wave')

dl <- dd[!is.na(dd$likeMayW), ]
cat(sprintf('SAMPLE:did_like:nonmissing_like_may=%d\n', nrow(dl)))
dl <- dl[complete.cases(dl[, ctrl]), ]
cat(sprintf('SAMPLE:did_like:nonmissing_controls=%d\n', nrow(dl)))
m2a <- feols(as.formula(paste('likeMayW ~', fml_rhs, fe_part)), data = dl, cluster = ~id)
cat(sprintf('SAMPLE:did_like:estimation=%d\n', nobs(m2a)))
if (abs(nobs(m2a) - 143499) > 500) cat(sprintf('DEVIATION: like May DiD N = %d differs from paper 143499\n', nobs(m2a)))

db <- dd[!is.na(dd$may_bestpm), ]
cat(sprintf('SAMPLE:did_bestpm:nonmissing_may_best_pm=%d\n', nrow(db)))
db <- db[complete.cases(db[, ctrl]), ]
cat(sprintf('SAMPLE:did_bestpm:nonmissing_controls=%d\n', nrow(db)))
m2b <- feols(as.formula(paste('may_bestpm ~', fml_rhs, fe_part)), data = db, cluster = ~id)
cat(sprintf('SAMPLE:did_bestpm:estimation=%d\n', nobs(m2b)))
if (abs(nobs(m2b) - 97155) > 500) cat(sprintf('DEVIATION: best PM DiD N = %d differs from paper 97155\n', nobs(m2b)))
cat('DEVIATION: best-PM DiD estimated as linear probability model (paper reports probability-scale coefficients)\n')

getc <- function(m, v) { cf <- coef(m); if (v %in% names(cf)) unname(cf[v]) else NA_real_ }
results$did_attack_x_time_like_may_table2 <- getc(m2a, 'treat:time')
results$did_attack_like_may_table2 <- getc(m2a, 'treat')
results$did_time_like_may_table2 <- getc(m2a, 'time')
results$did_attack_x_time_may_best_pm_table2 <- getc(m2b, 'treat:time')
results$did_attack_may_best_pm_table2 <- getc(m2b, 'treat')
results$did_time_may_best_pm_table2 <- getc(m2b, 'time')
results$n_obs_did_like_may_table2 <- nobs(m2a)
results$n_obs_did_may_best_pm_table2 <- nobs(m2b)

for (k in names(results)) {
  cat(sprintf('RESULT:%s=%s\n', k, format(unname(results[[k]]), digits = 8)))
}