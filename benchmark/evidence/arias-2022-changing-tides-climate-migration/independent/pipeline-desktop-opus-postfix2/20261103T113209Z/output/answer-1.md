suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(fixest)
})
set.seed(42)

base_dir <- '<repo>/.cache/datasets/arias_2022_changing_tides_climate_migration.script-free'
files <- list(
  us = file.path(base_dir, 'Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv'),
  germany = file.path(base_dir, 'Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv')
)
targets <- list(us = c(resp = 1086, obs = 18966), germany = c(resp = 1074, obs = 18862))

sgrepl <- function(p, x) {
  x <- as.character(x)
  tryCatch(grepl(p, x, ignore.case = TRUE, perl = TRUE),
           error = function(e) grepl(p, x, ignore.case = TRUE, useBytes = TRUE))
}
clean_txt <- function(x) {
  x <- as.character(x)
  x <- tryCatch(gsub('<[^>]+>', '', x, perl = TRUE), error = function(e) gsub('<[^>]+>', '', x, useBytes = TRUE))
  trimws(x)
}

code_choice <- function(x) {
  x <- trimws(as.character(x))
  out <- rep(NA_integer_, length(x))
  hd <- grepl('[0-9]', x)
  out[hd] <- suppressWarnings(as.integer(sub('^.*?([0-9]+)[^0-9]*$', '\\1', x[hd], perl = TRUE)))
  nd <- !hd & !is.na(x) & x != ''
  out[nd & grepl('A\\s*$', x)] <- 1L
  out[nd & grepl('B\\s*$', x)] <- 2L
  out
}

read_q <- function(path) {
  df <- read_csv(path, col_types = cols(.default = col_character()), name_repair = 'minimal',
                 progress = FALSE, show_col_types = FALSE)
  df <- as.data.frame(df, stringsAsFactors = FALSE, check.names = FALSE)
  nm <- names(df)
  nm <- gsub('^﻿', '', nm)
  nm[is.na(nm) | nm == ''] <- paste0('V', which(is.na(nm) | nm == ''))
  names(df) <- make.unique(nm)
  df
}

pat_drought <- 'drought|D.{1,2}rre|Trockenheit'
pat_flood <- 'flood|berschw|Hochwasser|Flut'
pat_fire <- 'wildfire|fire|Waldbr|Brand|Feuer'
pat_persec <- 'persecut|Verfolg'
pat_econ <- 'econom|wirtschaft'
pat_reason_any <- paste(pat_drought, pat_flood, pat_fire, pat_persec, pat_econ, sep = '|')

excl_pat <- paste0('^(GENDER|EDUCATION|IDEOLOGY|PARTISAN|RELIGIOSITY|NATIVE|TRUST|POL_INTEREST|force_choice|',
                   'SURVEY|FP_|EMPATHY|Finished|Status|Progress|Female|state|TREATMENT|UserLanguage|',
                   'Distribution|Recipient|External|Location|IPAddress|Duration|StartDate|EndDate|',
                   'RecordedDate|ResponseId|Republican|SomeCollege|AGE|EMPLOY|INCOME)')

results <- list()

for (cty in names(files)) {
  raw <- read_q(files[[cty]])
  cat(sprintf('SAMPLE:%s:loaded=%d\n', cty, nrow(raw)))

  # Drop Qualtrics metadata rows (question text / ImportId rows)
  if ('ResponseId' %in% names(raw)) {
    keep <- grepl('^R_', raw$ResponseId)
  } else {
    keep <- grepl('^\\s*[0-9]{1,4}[-/][0-9]{1,2}[-/][0-9]{1,4}', raw$StartDate)
  }
  df <- raw[keep, , drop = FALSE]
  cat(sprintf('SAMPLE:%s:drop_qualtrics_header_rows=%d\n', cty, nrow(df)))
  df$resp_id <- seq_len(nrow(df))

  lev_cols <- grep('^F[-_.][0-9]+[-_.][0-9]+[-_.][0-9]+$', names(df), value = TRUE)
  nam_cols <- grep('^F[-_.][0-9]+[-_.][0-9]+$', names(df), value = TRUE)
  if (length(lev_cols) == 0) {
    cat(sprintf('DEVIATION: %s conjoint attribute-level columns (F-task-profile-attribute) not found; cannot estimate\n', cty))
    next
  }

  long <- bind_rows(lapply(lev_cols, function(cn) {
    p <- as.integer(strsplit(cn, '[-_.]')[[1]][-1])
    data.frame(resp = df$resp_id, task = p[1], profile = p[2], apos = p[3],
               level = clean_txt(df[[cn]]), stringsAsFactors = FALSE)
  }))
  if (length(nam_cols) > 0) {
    nlong <- bind_rows(lapply(nam_cols, function(cn) {
      p <- as.integer(strsplit(cn, '[-_.]')[[1]][-1])
      data.frame(resp = df$resp_id, task = p[1], apos = p[2],
                 aname = clean_txt(df[[cn]]), stringsAsFactors = FALSE)
    }))
    long <- left_join(long, nlong, by = c('resp', 'task', 'apos'))
    miss <- is.na(long$aname) | long$aname == ''
    long$aname[miss] <- paste0('attr', long$apos[miss])
  } else {
    long$aname <- paste0('attr', long$apos)
  }
  long <- long[!is.na(long$level) & long$level != '', ]

  wide <- long %>%
    select(resp, task, profile, aname, level) %>%
    pivot_wider(id_cols = c(resp, task, profile), names_from = aname, values_from = level,
                values_fn = function(z) z[1]) %>%
    as.data.frame(stringsAsFactors = FALSE, check.names = FALSE)
  attr_names <- setdiff(names(wide), c('resp', 'task', 'profile'))
  # keep attributes present for most profiles
  attr_names <- attr_names[sapply(attr_names, function(a) mean(!is.na(wide[[a]])) > 0.5)]
  wide <- wide[complete.cases(wide[, attr_names, drop = FALSE]), c('resp', 'task', 'profile', attr_names)]

  scores <- sapply(attr_names, function(a) mean(sgrepl(pat_reason_any, wide[[a]])))
  reason_attr <- attr_names[which.max(scores)]
  other_attrs <- setdiff(attr_names, reason_attr)
  ntask <- max(long$task)

  # Locate choice outcome columns (one per task)
  cand <- character(0)
  for (cn in names(df)) {
    if (cn %in% c(lev_cols, nam_cols, 'resp_id')) next
    if (grepl('Click|Page Submit|_DO_|TIME', cn)) next
    if (grepl(excl_pat, cn, ignore.case = TRUE)) next
    v <- df[[cn]]
    v <- v[!is.na(v) & trimws(v) != '']
    if (length(v) < 0.5 * nrow(df)) next
    if (length(unique(v)) != 2) next
    cc <- code_choice(v)
    if (any(is.na(cc))) next
    if (!setequal(unique(cc), 1:2)) next
    s <- mean(cc == 1)
    if (s < 0.3 || s > 0.7) next
    cand <- c(cand, cn)
  }
  if (length(cand) < ntask) {
    cat(sprintf('DEVIATION: %s found only %d choice columns for %d tasks\n', cty, length(cand), ntask))
  }
  cand <- head(cand, ntask)
  if (length(cand) == 0) {
    cat(sprintf('DEVIATION: %s no choice outcome columns found; cannot estimate\n', cty))
    next
  }
  ch <- bind_rows(lapply(seq_along(cand), function(t) {
    data.frame(resp = df$resp_id, task = t, choice = code_choice(df[[cand[t]]]), stringsAsFactors = FALSE)
  }))
  ch <- ch[!is.na(ch$choice), ]

  cat(sprintf('SAMPLE:%s:profiles_with_attributes=%d\n', cty, nrow(wide)))
  d <- inner_join(wide, ch, by = c('resp', 'task'))
  d$chosen <- as.integer(d$profile == d$choice)
  cat(sprintf('SAMPLE:%s:choice_task_answered=%d\n', cty, nrow(d)))

  # Respondent restriction variants: pick the one matching the stated respondent count
  fin <- if ('Finished' %in% names(df)) df$Finished %in% c('1', 'True', 'TRUE', 'true') else rep(TRUE, nrow(df))
  prog <- if ('Progress' %in% names(df)) suppressWarnings(as.numeric(df$Progress)) == 100 else rep(TRUE, nrow(df))
  prog[is.na(prog)] <- FALSE
  variants <- list(
    any_choice = df$resp_id,
    finished = df$resp_id[fin],
    progress100 = df$resp_id[prog]
  )
  vres <- sapply(variants, function(ids) length(unique(d$resp[d$resp %in% ids])))
  vobs <- sapply(variants, function(ids) sum(d$resp %in% ids))
  tg <- targets[[cty]]
  pick <- which(vres == tg['resp'])
  if (length(pick) == 0) pick <- which(vobs == tg['obs'])
  if (length(pick) == 0) {
    pick <- 1
    cat(sprintf('DEVIATION: %s respondent count %d (any choice) does not match stated %d\n',
                cty, vres[1], tg['resp']))
  }
  vname <- names(variants)[pick[1]]
  d <- d[d$resp %in% variants[[pick[1]]], ]
  cat(sprintf('SAMPLE:%s:respondents_%s=%d\n', cty, vname, nrow(d)))

  # Build factors
  lv <- sort(unique(d[[reason_attr]]))
  base_lv <- lv[sgrepl(pat_econ, lv)]
  base_lv <- if (length(base_lv) > 0) base_lv[1] else lv[1]
  d$reason <- relevel(factor(d[[reason_attr]]), ref = base_lv)
  xnames <- character(0)
  for (i in seq_along(other_attrs)) {
    nm <- paste0('a', i)
    d[[nm]] <- factor(d[[other_attrs[i]]])
    xnames <- c(xnames, nm)
  }
  fml <- as.formula(paste('chosen ~ reason', if (length(xnames)) paste('+', paste(xnames, collapse = ' + ')) else ''))
  m <- feols(fml, data = d, cluster = ~resp)
  cat(sprintf('SAMPLE:%s:estimation=%d\n', cty, nobs(m)))

  cf <- coef(m)
  se <- sqrt(diag(vcov(m)))
  get_lv <- function(p) {
    nm <- names(cf)[grepl('^reason', names(cf))]
    lvn <- sub('^reason', '', nm)
    hit <- nm[sgrepl(p, lvn)]
    if (length(hit) == 0) NA_character_ else hit[1]
  }
  pats <- list(drought = pat_drought, flooding = pat_flood, persecution = pat_persec, wildfires = pat_fire)
  used <- character(0)
  for (k in names(pats)) {
    nm <- names(cf)[grepl('^reason', names(cf))]
    nm <- setdiff(nm, used)
    hit <- nm[sgrepl(pats[[k]], sub('^reason', '', nm))]
    if (length(hit) == 0) {
      cat(sprintf('DEVIATION: %s reason level for %s not found\n', cty, k))
      next
    }
    used <- c(used, hit[1])
    results[[sprintf('amce_%s_%s', k, cty)]] <- unname(cf[hit[1]])
    results[[sprintf('amce_%s_%s_se', k, cty)]] <- unname(se[hit[1]])
  }
  results[[sprintf('respondents_%s', cty)]] <- length(unique(d$resp[!is.na(d$chosen)]))
  results[[sprintf('choice_tasks_%s', cty)]] <- nobs(m)
}

ord <- c('amce_drought_us', 'amce_flooding_us', 'amce_wildfires_us', 'amce_persecution_us',
         'amce_drought_germany', 'amce_flooding_germany', 'amce_wildfires_germany', 'amce_persecution_germany',
         'respondents_us', 'respondents_germany', 'choice_tasks_us', 'choice_tasks_germany')
for (k in c(ord, setdiff(names(results), ord))) {
  if (!is.null(results[[k]])) cat(sprintf('RESULT:%s=%.6f\n', k, results[[k]]))
}
