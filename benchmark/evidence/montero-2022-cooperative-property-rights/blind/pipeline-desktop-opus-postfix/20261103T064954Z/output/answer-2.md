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
lnm <- tolower(nm)

pick <- function(cands) {
  for (c in cands) {
    i <- which(lnm == tolower(c))
    if (length(i) > 0) return(nm[i[1]])
  }
  NA_character_
}
pick_pattern <- function(pats) {
  for (p in pats) {
    i <- grep(p, lnm)
    if (length(i) > 0) return(nm[i[1]])
  }
  NA_character_
}

# Outcome: household earnings per capita in the previous month
y_var <- pick(c('hh_earnings_pc', 'hh_income_pc', 'earnings_pc', 'income_pc', 'ingpe',
                'hh_earnings_percapita', 'earnings_per_capita', 'income_per_capita',
                'hh_inc_pc', 'inc_pc', 'ingreso_pc', 'Work_Income_pc'))
if (is.na(y_var)) y_var <- pick_pattern(c('earn.*(pc|per_?cap)', 'inc.*(pc|per_?cap)', 'per_?cap', '_pc$', 'ingpe'))
if (is.na(y_var)) y_var <- pick(c('Work_Income'))

run_var <- pick(c('own_amt'))
treat_var <- pick(c('Above500'))
year_var <- pick(c('survey_year', 'year', 'anio'))

df0$y <- suppressWarnings(as.numeric(df0[[y_var]]))
df0$own_amt_ <- suppressWarnings(as.numeric(df0[[run_var]]))
df0$above <- suppressWarnings(as.numeric(df0[[treat_var]]))
if (all(is.na(df0$above))) df0$above <- as.numeric(df0$own_amt_ >= 500)
df0$dist <- df0$own_amt_ - 500
df0$year <- if (!is.na(year_var)) df0[[year_var]] else 1

# Property identifier: cooperative or hacienda id
coop_id <- if ('Reform_Coop_id' %in% nm) as.character(df0$Reform_Coop_id) else NA_character_
hac_id <- if ('Hacienda_id' %in% nm) as.character(df0$Hacienda_id) else NA_character_
coop_id[coop_id %in% c('', 'NA', '.')] <- NA
hac_id[hac_id %in% c('', 'NA', '.')] <- NA
prop <- ifelse(!is.na(coop_id), paste0('C_', coop_id),
               ifelse(!is.na(hac_id), paste0('H_', hac_id), NA))
if (all(is.na(prop)) && 'match_id' %in% nm) prop <- paste0('M_', df0$match_id)
df0$prop_id <- prop

# Former-owner cluster identifier
owner_var <- pick(c('Expropretario_ISTA', 'owner_id', 'former_owner_id', 'Propretario_id'))
owner <- if (!is.na(owner_var)) as.character(df0[[owner_var]]) else rep(NA_character_, nrow(df0))
owner[owner %in% c('', 'NA', '.')] <- NA
if (mean(is.na(owner)) > 0.5) {
  # fall back: owner identified by cumulative holdings value
  owner <- ifelse(is.na(owner), paste0('amt_', round(df0$own_amt_, 4)), owner)
}
df0$owner_id <- ifelse(is.na(owner), paste0('amt_', round(df0$own_amt_, 4)), owner)
df0$prop_id <- ifelse(is.na(df0$prop_id), paste0('O_', df0$owner_id), df0$prop_id)

# Modal non-missing year within a group; NA if all years are missing
mode_year <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA_real_)
  tb <- table(x)
  suppressWarnings(as.numeric(names(tb)[which.max(tb)]))
}

build_level <- function(bw, name) {
  d <- df0
  cat(sprintf('SAMPLE:%s:loaded=%d\n', name, nrow(d)))
  d <- d[!is.na(d$own_amt_), ]
  cat(sprintf('SAMPLE:%s:matched_to_former_owner=%d\n', name, nrow(d)))
  d <- d[abs(d$dist) <= bw, ]
  cat(sprintf('SAMPLE:%s:within_%dha=%d\n', name, bw, nrow(d)))
  d <- d[!is.na(d$y), ]
  cat(sprintf('SAMPLE:%s:nonmissing_outcome=%d\n', name, nrow(d)))
  d
}

fit_level <- function(d, name) {
  m <- feols(y ~ above + dist + above:dist | year, data = d, cluster = ~owner_id)
  cat(sprintf('SAMPLE:%s:estimation=%d\n', name, nobs(m)))
  m
}

build_iqr <- function(bw, name) {
  d <- build_level(bw, name)
  agg <- d %>%
    group_by(prop_id) %>%
    summarise(n_members = n(),
              iqr = as.numeric(quantile(y, 0.75, na.rm = TRUE) - quantile(y, 0.25, na.rm = TRUE)),
              above = first(above), dist = first(dist), owner_id = first(owner_id),
              year = mode_year(year),
              .groups = 'drop') %>%
    as.data.frame()
  cat(sprintf('SAMPLE:%s:collapsed_to_property=%d\n', name, nrow(agg)))
  agg <- agg[agg$n_members >= 5, ]
  cat(sprintf('SAMPLE:%s:at_least_5_members=%d\n', name, nrow(agg)))
  agg
}

fit_iqr <- function(a, name) {
  m <- tryCatch(feols(iqr ~ above + dist + above:dist | year, data = a, cluster = ~owner_id),
                error = function(e) feols(iqr ~ above + dist + above:dist, data = a, cluster = ~owner_id))
  cat(sprintf('SAMPLE:%s:estimation=%d\n', name, nobs(m)))
  m
}

d300 <- build_level(300, 'level_bw300')
m1 <- fit_level(d300, 'level_bw300')
d150 <- build_level(150, 'level_bw150')
m2 <- fit_level(d150, 'level_bw150')
a300 <- build_iqr(300, 'iqr_bw300')
m3 <- fit_iqr(a300, 'iqr_bw300')
a150 <- build_iqr(150, 'iqr_bw150')
m4 <- fit_iqr(a150, 'iqr_bw150')

used_clusters <- function(m, d) {
  idx <- obs(m)
  length(unique(d$owner_id[idx]))
}

se <- function(m) sqrt(diag(vcov(m)))['above']

cat(sprintf('RESULT:earnings_level_above500_bw300=%.6f\n', coef(m1)['above']))
cat(sprintf('RESULT:earnings_level_above500_bw300_se=%.6f\n', se(m1)))
cat(sprintf('RESULT:earnings_level_above500_bw150=%.6f\n', coef(m2)['above']))
cat(sprintf('RESULT:earnings_level_above500_bw150_se=%.6f\n', se(m2)))
cat(sprintf('RESULT:earnings_iqr_above500_bw300=%.6f\n', coef(m3)['above']))
cat(sprintf('RESULT:earnings_iqr_above500_bw300_se=%.6f\n', se(m3)))
cat(sprintf('RESULT:earnings_iqr_above500_bw150=%.6f\n', coef(m4)['above']))
cat(sprintf('RESULT:earnings_iqr_above500_bw150_se=%.6f\n', se(m4)))
cat(sprintf('RESULT:n_obs_earnings_level_bw300=%d\n', nobs(m1)))
cat(sprintf('RESULT:n_obs_earnings_level_bw150=%d\n', nobs(m2)))
cat(sprintf('RESULT:n_obs_earnings_iqr_bw300=%d\n', nobs(m3)))
cat(sprintf('RESULT:n_obs_earnings_iqr_bw150=%d\n', nobs(m4)))
cat(sprintf('RESULT:n_clusters_bw300=%d\n', used_clusters(m1, d300)))
cat(sprintf('RESULT:n_clusters_bw150=%d\n', used_clusters(m2, d150)))
