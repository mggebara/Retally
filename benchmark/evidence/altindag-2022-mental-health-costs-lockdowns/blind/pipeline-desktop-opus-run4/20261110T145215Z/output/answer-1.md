suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- file.path('<repo>/.cache/datasets/altindag_2022_mental_health_costs_lockdowns.script-free',
                  'ICPSR_183165-V1.1', 'konda_data_for_analysis.dta')
raw <- haven::read_dta(path)
df <- as.data.frame(lapply(raw, function(v) {
  if (inherits(v, 'haven_labelled')) v <- haven::zap_labels(v)
  v
}), stringsAsFactors = FALSE)
nms <- names(df)
msg <- function(...) message(paste0(...))
msg('Columns: ', paste(nms, collapse = ', '))

find_col <- function(patterns, exclude = character(0)) {
  for (p in patterns) {
    hits <- nms[grepl(p, nms, ignore.case = TRUE)]
    hits <- setdiff(hits, exclude)
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}

to_num <- function(v) suppressWarnings(as.numeric(v))
to_binary <- function(v) {
  v <- to_num(v)
  u <- sort(unique(v[!is.na(v)]))
  if (length(u) == 2 && all(u == c(1, 2))) v <- ifelse(v == 1, 1, 0)
  v
}

# ---- Running variable and treatment ----
yr <- to_num(df$year)
if (all(yr[!is.na(yr)] < 100)) yr <- yr + 1900
mo <- to_num(df$month)
# months older than the threshold month (December 1955): Dec 1955 -> 0, older -> positive
df$xrun <- (1955 * 12 + 12) - (yr * 12 + mo)
df$z <- as.numeric(df$xrun >= 0)
if ('before1955' %in% nms) {
  b <- to_binary(df$before1955)
  msg('Agreement before1955 vs computed z: ', mean(b == df$z, na.rm = TRUE))
  df$z <- ifelse(is.na(b), df$z, b)
}
df$ym <- yr * 100 + mo
df$birth_month <- mo

# ---- Fixed effects and controls ----
prov_col <- find_col(c('^province$', '^province_id$', '^prov', 'province', '^il$', '^il_', '^city', '^region'))
surv_col <- find_col(c('^survey_taker_id$', 'survey_taker', 'surveyor', 'interviewer', 'anketor'))
msg('Province column: ', prov_col, '; surveyor column: ', surv_col)
df$prov_fe <- if (!is.na(prov_col)) df[[prov_col]] else 1
df$surv_fe <- if (!is.na(surv_col)) df[[surv_col]] else 1
df$educ_f <- factor(df$education)
df$eth_f <- factor(df$ethnicity)
df$fem_f <- factor(df$female)

# ---- SRQ-20 items ----
item_patterns <- list(
  headache   = c('headache', 'head_ache', 'bas_agri'),
  appetite   = c('mal_appetite', 'appetite'),
  sleep      = c('sleep'),
  frightened = c('fright', 'scare', 'fear'),
  shaking    = c('^shaking$', 'shak', 'tremb'),
  nervous    = c('^nervous$', 'nervous', 'tense', 'worr(y|ied)$'),
  digestion  = c('^indigestion$', 'digest'),
  thinking   = c('think', 'thought_clear', 'clear'),
  unhappy    = c('^unhappy$', 'unhappy'),
  cry        = c('cry'),
  enjoy      = c('enjoy'),
  decision   = c('decision', 'decide'),
  worksuffer = c('work_suff', 'suffer', 'daily_work'),
  useful     = c('useful', 'useless', 'play_part'),
  interest   = c('uninte', 'interest'),
  worthless  = c('^worthless$', 'worthless'),
  suicide    = c('suicid'),
  tired      = c('tired_all', 'always_tired', 'tired_time', 'feel_tired', '^tired$'),
  tired_easy = c('tired_eas', 'easily_tired', 'tire_eas', 'fatigu'),
  stomach    = c('stomach', 'uncomf')
)
used <- character(0)
items <- list()
for (it in names(item_patterns)) {
  cands <- character(0)
  for (p in item_patterns[[it]]) {
    cands <- c(cands, nms[grepl(p, nms, ignore.case = TRUE)])
  }
  cands <- setdiff(unique(cands), used)
  # keep binary-looking columns
  ok <- cands[sapply(cands, function(cn) {
    v <- to_binary(df[[cn]]); u <- unique(v[!is.na(v)])
    length(u) >= 1 && all(u %in% c(0, 1))
  })]
  if (it == 'tired') ok <- ok[!grepl('eas', ok, ignore.case = TRUE)]
  if (length(ok) > 0) {
    items[[it]] <- ok[1]
    used <- c(used, ok[1])
  } else {
    items[[it]] <- NA_character_
  }
}
msg('SRQ item mapping: ', paste(names(items), unlist(items), sep = '=', collapse = '; '))
item_cols <- unlist(items)
item_cols <- item_cols[!is.na(item_cols)]
somatic_keys <- c('headache', 'shaking', 'digestion', 'stomach')
som_cols <- unlist(items[somatic_keys]); som_cols <- som_cols[!is.na(som_cols)]
nonsom_cols <- setdiff(item_cols, som_cols)

for (cn in item_cols) df[[cn]] <- to_binary(df[[cn]])
ctrl <- !is.na(df$z) & df$z == 0

all_items_obs <- complete.cases(df[, item_cols, drop = FALSE])

anderson_index <- function(cols) {
  zs <- sapply(cols, function(cn) {
    v <- df[[cn]]
    (v - mean(v[ctrl & all_items_obs], na.rm = TRUE)) / sd(v[ctrl & all_items_obs], na.rm = TRUE)
  })
  zs <- as.matrix(zs)
  idx <- rowMeans(zs)
  idx[!all_items_obs] <- NA
  (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
}

df$mdi <- anderson_index(item_cols)
df$somatic_idx <- anderson_index(som_cols)
df$nonsomatic_idx <- anderson_index(nonsom_cols)
df$srq_sum <- ifelse(all_items_obs, rowSums(df[, item_cols, drop = FALSE]), NA)

# ---- Mobility outcomes ----
df$days_out <- to_num(df$outside_week)
df$under_curfew_y <- to_binary(df$under_curfew)
nev_col <- if ('never_out' %in% nms) 'never_out' else find_col(c('never'))
df$never_out_y <- to_binary(df[[nev_col]])

# ---- RD estimation ----
h <- 45
rd <- function(yvar) {
  d <- df[!is.na(df$xrun) & abs(df$xrun) <= h, ]
  f <- as.formula(paste0(yvar, ' ~ z + xrun + z:xrun + educ_f + eth_f + fem_f | birth_month + prov_fe + surv_fe'))
  m <- feols(f, data = d, cluster = ~ym)
  list(b = unname(coef(m)['z']), se = unname(sqrt(diag(vcov(m)))['z']), n = nobs(m))
}

r_days <- rd('days_out')
r_cur  <- rd('under_curfew_y')
r_nev  <- rd('never_out_y')
r_mdi  <- rd('mdi')
r_som  <- rd('somatic_idx')
r_non  <- rd('nonsomatic_idx')
r_sum  <- rd('srq_sum')

msg('SEs: days ', r_days$se, ' curfew ', r_cur$se, ' never ', r_nev$se,
    ' mdi ', r_mdi$se, ' som ', r_som$se, ' nonsom ', r_non$se, ' sum ', r_sum$se)

cat(sprintf('RESULT:days_outside_last_week_table3_col3=%.6f\n', r_days$b))
cat(sprintf('RESULT:under_curfew_table3_col3=%.6f\n', r_cur$b))
cat(sprintf('RESULT:never_goes_out_table3_col3=%.6f\n', r_nev$b))
cat(sprintf('RESULT:n_obs_days_outside_table3_col3=%d\n', as.integer(r_days$n)))
cat(sprintf('RESULT:n_obs_under_curfew_table3_col3=%d\n', as.integer(r_cur$n)))
cat(sprintf('RESULT:mental_distress_index_table4_col3=%.6f\n', r_mdi$b))
cat(sprintf('RESULT:somatic_symptoms_index_table4_col3=%.6f\n', r_som$b))
cat(sprintf('RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n', r_non$b))
cat(sprintf('RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n', r_sum$b))
cat(sprintf('RESULT:n_obs_mental_distress_index_table4_col3=%d\n', as.integer(r_mdi$n)))
