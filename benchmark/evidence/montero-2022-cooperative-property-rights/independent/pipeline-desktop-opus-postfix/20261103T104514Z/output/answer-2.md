suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- file.path('<repo>/.cache/datasets/montero_2022_cooperative_property_rights.script-free',
                  'ehpm_incomemodule_wreform.dta')
raw <- haven::read_dta(path)
raw <- haven::zap_labels(raw)
df0 <- as.data.frame(raw)
nm <- names(df0)

find_col <- function(cands, patterns = NULL) {
  for (c in cands) {
    hit <- nm[tolower(nm) == tolower(c)]
    if (length(hit) > 0) return(hit[1])
  }
  if (!is.null(patterns)) {
    for (p in patterns) {
      hit <- nm[grepl(p, nm, ignore.case = TRUE)]
      if (length(hit) > 0) hit <- hit[vapply(hit, function(h) is.numeric(df0[[h]]), logical(1))]
      if (length(hit) > 0) return(hit[1])
    }
  }
  NULL
}

# ---- outcome: household earnings per capita (previous month) ----
y_col <- find_col(c('hh_income_pc', 'income_pc', 'earnings_pc', 'hh_earnings_pc', 'ingpe',
                    'Income_PC', 'Earnings_PC', 'HH_Income_PC', 'hh_inc_pc', 'inc_pc',
                    'Household_Income_PC', 'Income_per_capita', 'Earnings_per_capita'),
                  c('earn.*pc', 'inc.*pc', 'per_?cap', 'percap', 'ingpe', '_pc$'))
if (!is.null(y_col)) {
  df0$y <- as.numeric(df0[[y_col]])
  cat(sprintf('NOTE: outcome column used = %s\n', y_col))
} else {
  hhs <- find_col(c('hh_size', 'hhsize', 'members', 'miembros', 'tamhog', 'HH_Size', 'num_members'),
                  c('hh_?size', 'miembro', 'tamhog', 'member'))
  inc <- as.numeric(df0$Work_Income)
  if ('Other_Income' %in% nm) inc <- rowSums(cbind(inc, as.numeric(df0$Other_Income)), na.rm = FALSE)
  if (!is.null(hhs)) {
    df0$y <- inc / as.numeric(df0[[hhs]])
    cat(sprintf('DEVIATION: no per-capita earnings column found; using (Work_Income+Other_Income)/%s\n', hhs))
  } else {
    df0$y <- as.numeric(df0$Work_Income)
    cat('DEVIATION: no per-capita earnings or household size column found; using Work_Income\n')
  }
}

# ---- running variable, treatment, ids ----
df0$own_amt <- as.numeric(df0$own_amt)
df0$x <- df0$own_amt - 500
df0$Above500 <- if ('Above500' %in% nm) as.numeric(df0$Above500) else as.numeric(df0$own_amt >= 500)
df0$survey_year <- as.numeric(df0$survey_year)

owner_col <- find_col(c('owner_id', 'propietario_id', 'Propretario_id', 'Expropietario_id', 'former_owner_id'),
                      c('owner_?id', 'propr?ietario_?id', 'propretario_?id'))
if (!is.null(owner_col)) {
  df0$owner <- as.character(df0[[owner_col]])
  cat(sprintf('NOTE: cluster (former owner) column used = %s\n', owner_col))
} else {
  # cumulative landholdings are owner-specific: use them as the owner identifier
  df0$owner <- as.character(round(df0$own_amt, 4))
  cat('NOTE: former-owner cluster identified by cumulative landholdings (own_amt)\n')
}

if ('match_id' %in% nm) {
  df0$prop <- as.character(df0$match_id)
} else {
  df0$prop <- paste(df0$Reform_Coop_id, df0$Hacienda_id, sep = '_')
}
miss_prop <- is.na(df0$prop) | df0$prop %in% c('', 'NA')
if (any(miss_prop) && all(c('Reform_Coop_id', 'Hacienda_id') %in% nm)) {
  df0$prop[miss_prop] <- paste(df0$Reform_Coop_id[miss_prop], df0$Hacienda_id[miss_prop], sep = '_')
}

# ---- earnings-level samples ----
results <- list()
nobs_l <- list(); ncl_l <- list()
for (bw in c(300, 150)) {
  s <- paste0('level_bw', bw)
  d <- df0
  cat(sprintf('SAMPLE:%s:loaded=%d\n', s, nrow(d)))
  d <- d[!is.na(d$own_amt), ]
  cat(sprintf('SAMPLE:%s:matched_to_former_owner=%d\n', s, nrow(d)))
  d <- d[abs(d$x) <= bw, ]
  cat(sprintf('SAMPLE:%s:within_%dha_of_threshold=%d\n', s, bw, nrow(d)))
  d <- d[!is.na(d$y) & !is.na(d$survey_year) & !is.na(d$Above500), ]
  cat(sprintf('SAMPLE:%s:nonmissing_earnings=%d\n', s, nrow(d)))
  m <- feols(y ~ Above500 + x + x:Above500 | survey_year, data = d, cluster = ~owner)
  cat(sprintf('SAMPLE:%s:estimation=%d\n', s, nobs(m)))
  results[[paste0('earnings_level_above500_bw', bw)]] <- coef(m)['Above500']
  results[[paste0('earnings_level_above500_bw', bw, '_se')]] <- sqrt(diag(vcov(m)))['Above500']
  nobs_l[[as.character(bw)]] <- nobs(m)
  used <- d[obs(m), ]
  ncl_l[[as.character(bw)]] <- length(unique(used$owner))
}

# ---- interquartile-range samples (property x survey round, >= 5 members) ----
nobs_i <- list()
for (bw in c(300, 150)) {
  s <- paste0('iqr_bw', bw)
  d <- df0
  cat(sprintf('SAMPLE:%s:loaded=%d\n', s, nrow(d)))
  d <- d[!is.na(d$own_amt), ]
  cat(sprintf('SAMPLE:%s:matched_to_former_owner=%d\n', s, nrow(d)))
  d <- d[abs(d$x) <= bw, ]
  cat(sprintf('SAMPLE:%s:within_%dha_of_threshold=%d\n', s, bw, nrow(d)))
  d <- d[!is.na(d$y) & !is.na(d$survey_year), ]
  cat(sprintf('SAMPLE:%s:nonmissing_earnings=%d\n', s, nrow(d)))
  agg <- d %>%
    group_by(prop, survey_year) %>%
    summarise(n_mem = n(),
              iqr = as.numeric(quantile(y, 0.75, type = 2) - quantile(y, 0.25, type = 2)),
              Above500 = first(Above500), x = first(x), owner = first(owner),
              .groups = 'drop') %>%
    as.data.frame()
  cat(sprintf('SAMPLE:%s:collapsed_to_property_round=%d\n', s, nrow(agg)))
  agg <- agg[agg$n_mem >= 5, ]
  cat(sprintf('SAMPLE:%s:at_least_5_members=%d\n', s, nrow(agg)))
  m <- feols(iqr ~ Above500 + x + x:Above500 | survey_year, data = agg, cluster = ~owner)
  cat(sprintf('SAMPLE:%s:estimation=%d\n', s, nobs(m)))
  results[[paste0('earnings_iqr_above500_bw', bw)]] <- coef(m)['Above500']
  results[[paste0('earnings_iqr_above500_bw', bw, '_se')]] <- sqrt(diag(vcov(m)))['Above500']
  nobs_i[[as.character(bw)]] <- nobs(m)
}

for (k in names(results)) cat(sprintf('RESULT:%s=%.6f\n', k, as.numeric(results[[k]])))
cat(sprintf('RESULT:n_obs_earnings_level_bw300=%d\n', as.integer(nobs_l[['300']])))
cat(sprintf('RESULT:n_obs_earnings_level_bw150=%d\n', as.integer(nobs_l[['150']])))
cat(sprintf('RESULT:n_obs_earnings_iqr_bw300=%d\n', as.integer(nobs_i[['300']])))
cat(sprintf('RESULT:n_obs_earnings_iqr_bw150=%d\n', as.integer(nobs_i[['150']])))
cat(sprintf('RESULT:n_clusters_bw300=%d\n', as.integer(ncl_l[['300']])))
cat(sprintf('RESULT:n_clusters_bw150=%d\n', as.integer(ncl_l[['150']])))
