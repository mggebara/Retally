suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- file.path('<repo>/.cache/datasets/altindag_2022_mental_health_costs_lockdowns.script-free',
                  'ICPSR_183165-V1.1', 'konda_data_for_analysis.dta')
raw <- haven::read_dta(path)
nm <- names(raw)
cat('Columns:', paste(nm, collapse = ', '), '\n')

# ---- helpers ----
find_col <- function(patterns, exclude = character(0)) {
  for (p in patterns) {
    hits <- nm[grepl(p, nm, ignore.case = TRUE)]
    if (length(exclude)) hits <- setdiff(hits, exclude)
    if (length(hits)) return(hits[1])
  }
  NA_character_
}

to_yes <- function(v) {
  # convert a yes/no item to 0/1 with 1 = yes
  labs <- attr(v, 'labels')
  x <- as.numeric(haven::zap_labels(v))
  if (!is.null(labs) && length(labs) > 0) {
    ln <- tolower(names(labs))
    yes_code <- labs[grepl('^yes|evet', ln)]
    no_code  <- labs[grepl('^no|hay', ln)]
    if (length(yes_code) == 1 && length(no_code) == 1) {
      out <- ifelse(x == yes_code, 1, ifelse(x == no_code, 0, NA))
      return(out)
    }
  }
  u <- sort(unique(x[!is.na(x)]))
  if (all(u %in% c(0, 1))) return(x)
  if (all(u %in% c(1, 2))) return(ifelse(x == 1, 1, ifelse(x == 2, 0, NA)))
  x[!(x %in% c(0, 1))] <- NA
  x
}

num <- function(v) as.numeric(haven::zap_labels(v))

df <- raw
df$year_n  <- num(df$year)
df$month_n <- num(df$month)
if (max(df$year_n, na.rm = TRUE) < 100) df$year_n <- df$year_n + 1900

# ---- running variable ----
# months of birth: treated if born in or before Dec 1955.
bm <- df$year_n * 12 + df$month_n
cut_dec55 <- 1955 * 12 + 12
# months older than the threshold: Dec 1955 -> 0, Jan 1956 -> -1
df$run <- cut_dec55 - bm
df$treat <- as.numeric(df$run >= 0)
if ('before1955' %in% nm) {
  b <- num(df$before1955)
  cat('Agreement treat vs before1955:', mean(b == df$treat, na.rm = TRUE), '\n')
}
df$birth_ym <- bm
# 45 months on each side: treated 0..44, control -1..-45
h <- 45
df$inbw <- df$run >= -h & df$run <= (h - 1)

# ---- controls ----
prov_col <- find_col(c('^province', 'province', '^il$', '^il_', 'city', '^region', 'region'))
surv_col <- find_col(c('^survey_taker_id$', 'survey_taker', 'surveyor', 'interviewer', 'anketor'))
eth_col  <- if ('non_turk' %in% nm) 'non_turk' else find_col(c('ethnic'))
cat('Province col:', prov_col, ' Surveyor col:', surv_col, ' Ethnicity col:', eth_col, '\n')

df$educ_f   <- num(df$education)
df$female_n <- num(df$female)
df$eth_n    <- num(df[[eth_col]])
df$prov_f   <- if (!is.na(prov_col)) num(df[[prov_col]]) else 1
df$surv_f   <- if (!is.na(surv_col)) num(df[[surv_col]]) else 1
df$mob_f    <- df$month_n

# ---- SRQ-20 items ----
item_patterns <- list(
  headache      = c('headache', 'head'),
  appetite      = c('appetite'),
  sleep         = c('sleep'),
  frightened    = c('fright', 'scare', 'afraid'),
  shaking       = c('^shaking$', 'shak', 'tremb'),
  nervous       = c('^nervous$', 'nervous', 'worr', 'tense'),
  indigestion   = c('^indigestion$', 'indigest', 'digest'),
  thinking      = c('think', 'clear'),
  unhappy       = c('^unhappy$', 'unhappy'),
  crying        = c('cry'),
  enjoy         = c('enjoy'),
  decisions     = c('decision', 'decide'),
  work          = c('work_suff', 'worksuff', 'daily_work', 'work'),
  useful        = c('useful', 'role'),
  uninterest    = c('^uninterest$', 'uninterest', 'lost_interest', 'interest'),
  worthless     = c('^worthless$', 'worthless'),
  suicide       = c('suicid', 'end_life', 'endlife'),
  tired_all     = c('tired_all', 'always_tired', 'tired_time', '^tired$', 'tired'),
  stomach       = c('^stomach_discomfort$', 'stomach'),
  tired_easily  = c('tired_eas', 'easily_tired', 'tire_eas', 'tired')
)
exclude_cols <- c('poor_overall_health', 'poor_physical_health', 'poor_mental_health',
                  'labor', 'hh_size', 'pre_covid_hhsize', 'limited_physical_act',
                  'lim_social_interaction', 'interviewer')
used <- character(0)
item_cols <- c()
for (k in names(item_patterns)) {
  cc <- find_col(item_patterns[[k]], exclude = c(used, exclude_cols))
  if (!is.na(cc)) {
    item_cols[k] <- cc
    used <- c(used, cc)
  }
}
cat('SRQ items found (', length(item_cols), '):\n')
print(item_cols)

somatic_keys <- c('headache', 'shaking', 'indigestion', 'stomach')
somatic_cols <- item_cols[names(item_cols) %in% somatic_keys]
nonsom_cols  <- item_cols[!(names(item_cols) %in% somatic_keys)]

Y <- sapply(item_cols, function(cn) to_yes(df[[cn]]))
Y <- as.data.frame(Y)
complete_items <- stats::complete.cases(Y)
ctrl <- df$treat == 0

anderson_index <- function(cols) {
  Z <- sapply(cols, function(cn) {
    v <- Y[[cn]]
    m <- mean(v[ctrl & complete_items], na.rm = TRUE)
    s <- sd(v[ctrl & complete_items], na.rm = TRUE)
    if (is.na(s) || s == 0) s <- 1
    (v - m) / s
  })
  idx <- rowMeans(as.matrix(Z))
  idx[!complete_items] <- NA
  m <- mean(idx[ctrl], na.rm = TRUE)
  s <- sd(idx[ctrl], na.rm = TRUE)
  (idx - m) / s
}
names(Y) <- item_cols
df$mdi     <- anderson_index(unname(item_cols))
df$somatic <- if (length(somatic_cols)) anderson_index(unname(somatic_cols)) else NA
df$nonsom  <- if (length(nonsom_cols)) anderson_index(unname(nonsom_cols)) else NA
df$srq_sum <- ifelse(complete_items, rowSums(as.matrix(Y)), NA)

# ---- outcomes ----
df$days_out  <- num(df$outside_week)
df$under_cur <- num(df$under_curfew)
df$never_o   <- num(df$never_out)

est <- df[df$inbw, ]

run_rd <- function(y) {
  f <- as.formula(paste0(y, ' ~ treat + run + treat:run + female_n + eth_n + factor(educ_f)',
                         ' | mob_f + prov_f + surv_f'))
  m <- feols(f, data = est, cluster = ~birth_ym, warn = FALSE, notes = FALSE)
  list(b = unname(coef(m)['treat']), se = unname(sqrt(diag(vcov(m)))['treat']), n = nobs(m))
}

r_days  <- run_rd('days_out')
r_cur   <- run_rd('under_cur')
r_never <- run_rd('never_o')
r_mdi   <- run_rd('mdi')
r_som   <- run_rd('somatic')
r_nons  <- run_rd('nonsom')
r_sum   <- run_rd('srq_sum')

cat(sprintf('RESULT:days_outside_last_week_table3_col3=%.6f\n', r_days$b))
cat(sprintf('RESULT:under_curfew_table3_col3=%.6f\n', r_cur$b))
cat(sprintf('RESULT:never_goes_out_table3_col3=%.6f\n', r_never$b))
cat(sprintf('RESULT:n_obs_days_outside_table3_col3=%d\n', as.integer(r_days$n)))
cat(sprintf('RESULT:n_obs_under_curfew_table3_col3=%d\n', as.integer(r_cur$n)))
cat(sprintf('RESULT:mental_distress_index_table4_col3=%.6f\n', r_mdi$b))
cat(sprintf('RESULT:somatic_symptoms_index_table4_col3=%.6f\n', r_som$b))
cat(sprintf('RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n', r_nons$b))
cat(sprintf('RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n', r_sum$b))
cat(sprintf('RESULT:n_obs_mental_distress_index_table4_col3=%d\n', as.integer(r_mdi$n)))