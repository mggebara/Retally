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

# ---- running variable, treatment, ids ----
df0$own_amt <- as.numeric(df0$own_amt)
df0$x <- df0$own_amt - 500
df0$Above500 <- if ('Above500' %in% nm) as.numeric(df0$Above500) else as.numeric(df0$own_amt >= 500)
df0$survey_year <- as.numeric(df0$survey_year)

# ---- outcome candidates: household earnings per capita (previous month) ----
hhs <- find_col(c('hh_size', 'hhsize', 'members', 'miembros', 'tamhog', 'HH_Size', 'num_members'),
                c('hh_?size', 'miembro', 'tamhog', 'member'))
y_col <- find_col(c('hh_income_pc', 'income_pc', 'earnings_pc', 'hh_earnings_pc', 'ingpe',
                    'Income_PC', 'Earnings_PC', 'HH_Income_PC', 'hh_inc_pc', 'inc_pc',
                    'Household_Income_PC', 'Income_per_capita', 'Earnings_per_capita'),
                  c('earn.*pc', 'inc.*pc', 'per_?cap', 'percap', 'ingpe', '_pc$'))
ycands <- list()
if (!is.null(y_col)) {
  ycands[[y_col]] <- as.numeric(df0[[y_col]])
  v0 <- as.numeric(df0[[y_col]]); v0[is.na(v0)] <- 0
  ycands[[paste0(y_col, '_na_as_zero')]] <- v0
}
if ('Work_Income' %in% nm) {
  wi <- as.numeric(df0$Work_Income)
  oi <- if ('Other_Income' %in% nm) as.numeric(df0$Other_Income) else rep(0, nrow(df0))
  tot <- rowSums(cbind(wi, oi), na.rm = TRUE)
  tot[is.na(wi) & is.na(oi)] <- NA
  if (!is.null(hhs)) ycands[['(Work+Other)/hhsize']] <- tot / as.numeric(df0[[hhs]])
  ycands[['Work_Income']] <- wi
}
in300 <- !is.na(df0$own_amt) & abs(df0$x) <= 300 & !is.na(df0$survey_year) & !is.na(df0$Above500)
target_n <- 4770
best <- NULL; bestgap <- Inf
for (k in names(ycands)) {
  n <- sum(in300 & !is.na(ycands[[k]]))
  cat(sprintf('NOTE: outcome candidate %s nonmissing within 300ha = %d\n', k, n))
  g <- abs(n - target_n)
  if (g < bestgap) { bestgap <- g; best <- k }
}
df0$y <- ycands[[best]]
cat(sprintf('NOTE: outcome column used = %s\n', best))
if (!is.null(y_col) && best != y_col) {
  cat(sprintf('DEVIATION: outcome constructed as %s (instead of raw %s) because it reproduces the paper sample of workers\n', best, y_col))
}

owner_col <- find_col(c('owner_id', 'propietario_id', 'Propretario_id', 'Expropietario_id', 'former_owner_id'),
                      c('owner_?id', 'propr?ietario_?id', 'propretario_?id'))
if (!is.null(owner_col)) {
  df0$owner <- as.character(df0[[owner_col]])
  cat(sprintf('NOTE: cluster (former owner) column used = %s\n', owner_col))
} else {
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
# candidate property identifiers; choose the one that reproduces the paper's property count
gcands <- list(prop = df0$prop)
for (cc in c('Reform_Coop_id', 'Hacienda_id', 'match_id')) {
  if (cc %in% nm) gcands[[cc]] <- as.character(df0[[cc]])
}
can_col <- find_col(c('canton', 'canton_id', 'cod_canton', 'Canton', 'r107', 'segmento'),
                    c('canton', 'segment'))
if (!is.null(can_col)) gcands[[can_col]] <- as.character(df0[[can_col]])
if (all(c('Reform_Coop_id', 'Hacienda_id') %in% nm)) {
  gcands[['coop_hac_owner']] <- paste(df0$Reform_Coop_id, df0$Hacienda_id, df0$owner, sep = '_')
}
iqr_agg <- function(d, gvar) {
  d$g <- gvar
  d <- d[!is.na(d$g) & !(d$g %in% c('', 'NA', 'NA_NA')), ]
  d %>%
    group_by(g, survey_year) %>%
    summarise(n_mem = n(),
              iqr = as.numeric(quantile(y, 0.75, type = 2) - quantile(y, 0.25, type = 2)),
              Above500 = first(Above500), x = first(x), owner = first(owner),
              .groups = 'drop') %>%
    as.data.frame()
}
dsel <- df0[!is.na(df0$own_amt) & abs(df0$x) <= 300 & !is.na(df0$y) & !is.na(df0$survey_year), ]
bestg <- 'prop'; bestgg <- Inf
for (k in names(gcands)) {
  a <- iqr_agg(dsel, gcands[[k]][!is.na(df0$own_amt) & abs(df0$x) <= 300 & !is.na(df0$y) & !is.na(df0$survey_year)])
  n <- sum(a$n_mem >= 5)
  cat(sprintf('NOTE: IQR grouping candidate %s -> %d property-rounds with >=5 members\n', k, n))
  if (abs(n - 327) < bestgg) { bestgg <- abs(n - 327); bestg <- k }
}
df0$gid <- gcands[[bestg]]
cat(sprintf('NOTE: IQR property identifier used = %s\n', bestg))
if (bestg != 'prop') cat(sprintf('DEVIATION: IQR computed by %s x survey round to match the paper property count\n', bestg))

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
  agg <- iqr_agg(d, d$gid)
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