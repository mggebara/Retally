suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- '<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances.script-free'

num <- function(x) as.numeric(haven::zap_labels(x))
fac <- function(x) {
  if (inherits(x, 'haven_labelled')) x <- haven::as_factor(x, levels = 'values')
  factor(x)
}

# =========================================================
# Individual-level survey analysis (Table 1)
# =========================================================
sv <- haven::read_dta(file.path(base_dir, 'survey.dta'))
cat(sprintf('SAMPLE:table1_col1_2:loaded=%d\n', nrow(sv)))
cat(sprintf('SAMPLE:table1_col3_6:loaded=%d\n', nrow(sv)))

sv <- sv[num(sv$wave) == 4 & !is.na(num(sv$wave)), ]
cat(sprintf('SAMPLE:table1_col1_2:wave4=%d\n', nrow(sv)))
cat(sprintf('SAMPLE:table1_col3_6:wave4=%d\n', nrow(sv)))

nm <- names(sv)
d <- data.frame(row = seq_len(nrow(sv)))
d$only_means <- num(sv$hate_violence_means)
d$mate <- num(sv[['MateComp.cont']])
d$job <- num(sv[['JobComp.cont']])
d$lifesat <- num(sv[['LifeSatis.cont']])

# Sociodemographics
socio_num <- intersect(c('age', 'eduyrs', 'household_size', 'self_econ'), nm)
socio_fac <- intersect(c('gender', 'income', 'occupation', 'employment', 'empl_status',
                         'citizenship', 'religion', 'state'), nm)
socio_vars <- c()
for (v in socio_num) { d[[v]] <- num(sv[[v]]); socio_vars <- c(socio_vars, v) }
for (v in socio_fac) {
  vn <- paste0(v, '_f')
  x <- num(sv[[v]])
  d[[vn]] <- factor(x)
  socio_vars <- c(socio_vars, vn)
}

# National attitudes toward refugees
nat_vars <- setdiff(grep('^ref_', nm, value = TRUE), grep('^ref_loc', nm, value = TRUE))
nat_vars <- setdiff(nat_vars, c('ref_ind'))
loc_vars <- grep('^ref_loc', nm, value = TRUE)
add_vars <- intersect(c('contact_ind', 'distance_ref', 'settle_ref', 'refugee_ind',
                        'afd', 'afd_ind', 'lrscale', 'muslim_ind'), nm)
for (v in c(nat_vars, loc_vars, add_vars)) d[[v]] <- num(sv[[v]])

# Columns 1-2 sample
s12 <- d[complete.cases(d[, c('only_means', 'mate', 'job', 'lifesat')]), ]
cat(sprintf('SAMPLE:table1_col1_2:nonmissing_outcome_mate_job_lifesat=%d\n', nrow(s12)))
m1 <- lm(only_means ~ mate, data = s12)
m2 <- lm(only_means ~ mate + job + lifesat, data = s12)
cat(sprintf('SAMPLE:table1_col1_2:estimation=%d\n', nobs(m2)))

mk <- function(vars) as.formula(paste('only_means ~', paste(vars, collapse = ' + ')))
v3 <- c('mate', 'job', 'lifesat', socio_vars)
v4 <- c(v3, nat_vars)
v5 <- c(v4, loc_vars)
v6 <- c(v5, add_vars)

s3 <- d[complete.cases(d[, c('only_means', v3)]), ]
cat(sprintf('SAMPLE:table1_col3_6:nonmissing_sociodemographics=%d\n', nrow(s3)))
m3 <- lm(mk(v3), data = s3)
m4 <- lm(mk(v4), data = s3)
m5 <- lm(mk(v5), data = s3)
m6 <- lm(mk(v6), data = s3)
cat(sprintf('SAMPLE:table1_col3_6:estimation=%d\n', nobs(m3)))

# =========================================================
# Ecological analysis (SI Table C1, columns 5 and 6)
# =========================================================
cx <- haven::read_dta(file.path(base_dir, 'context.dta'))
cx <- as.data.frame(lapply(cx, num))
cat(sprintf('SAMPLE:sum_c1_col5:loaded=%d\n', nrow(cx)))
cat(sprintf('SAMPLE:annual_c1_col6:loaded=%d\n', nrow(cx)))

controls <- c('log_population_muni_2015', 'log_popdens_muni_2015', 'd_pop1511_muni',
              'log_unemp_all_muni_2015', 'unemp_gendergap_2015', 'log_pop_ref_2014',
              'log_ref_inflow_1514', 'pc_hidegree_all2011', 'pc_manufacturing_2015',
              'd_manuf1115', 'vote_afd_2013_muni', 'log_violence_percap_2015')
controls <- intersect(controls, names(cx))

# Municipality-level cross-section
muni_cov <- cx %>%
  arrange(ags_muni, year) %>%
  group_by(ags_muni) %>%
  summarise(across(all_of(c('ags_county', 'ags_state', 'pop_15_44_muni_gendergap_2015', controls)),
                   ~ first(na.omit(.x))[1]),
            hate_sum = sum(Hate_all_muni, na.rm = TRUE),
            hate_any = as.integer(any(Hate_all_muni_bin == 1, na.rm = TRUE) |
                                    sum(Hate_all_muni, na.rm = TRUE) > 0),
            .groups = 'drop')
cat(sprintf('SAMPLE:sum_c1_col5:aggregate_to_municipality=%d\n', nrow(muni_cov)))

em <- muni_cov$pop_15_44_muni_gendergap_2015
q <- quantile(em, c(0.025, 0.975), na.rm = TRUE)
sum_df <- muni_cov[!is.na(em) & em >= q[1] & em <= q[2], ]
cat(sprintf('SAMPLE:sum_c1_col5:drop_extreme_excess_males=%d\n', nrow(sum_df)))

f_sum <- as.formula(paste('hate_any ~ pop_15_44_muni_gendergap_2015 +',
                          paste(controls, collapse = ' + '), '| ags_state'))
m_sum <- feglm(f_sum, data = sum_df, family = binomial('logit'), cluster = ~ags_county)
cat(sprintf('SAMPLE:sum_c1_col5:estimation=%d\n', nobs(m_sum)))

# Annual panel
ann <- cx[cx$year %in% c(2015, 2016, 2017), ]
cat(sprintf('SAMPLE:annual_c1_col6:years_2015_2017=%d\n', nrow(ann)))
ann <- ann[ann$ags_muni %in% sum_df$ags_muni, ]
cat(sprintf('SAMPLE:annual_c1_col6:drop_extreme_excess_males=%d\n', nrow(ann)))
ann$hate_bin <- as.integer(ann$Hate_all_muni_bin == 1 | ann$Hate_all_muni > 0)
f_ann <- as.formula(paste('hate_bin ~ pop_15_44_muni_gendergap_2015 +',
                          paste(controls, collapse = ' + '), '| ags_state + year'))
m_ann <- feglm(f_ann, data = ann, family = binomial('logit'), cluster = ~ags_county)
cat(sprintf('SAMPLE:annual_c1_col6:estimation=%d\n', nobs(m_ann)))

# =========================================================
# Results
# =========================================================
cat(sprintf('RESULT:mate_competition_table1_col1=%.6f\n', coef(m1)['mate']))
cat(sprintf('RESULT:mate_competition_table1_col2=%.6f\n', coef(m2)['mate']))
cat(sprintf('RESULT:mate_competition_table1_col3=%.6f\n', coef(m3)['mate']))
cat(sprintf('RESULT:mate_competition_table1_col4=%.6f\n', coef(m4)['mate']))
cat(sprintf('RESULT:mate_competition_table1_col5=%.6f\n', coef(m5)['mate']))
cat(sprintf('RESULT:mate_competition_table1_col6=%.6f\n', coef(m6)['mate']))
cat(sprintf('RESULT:job_competition_table1_col2=%.6f\n', coef(m2)['job']))
cat(sprintf('RESULT:n_obs_table1_col1=%d\n', nobs(m1)))
cat(sprintf('RESULT:n_obs_table1_col3=%d\n', nobs(m3)))
cat(sprintf('RESULT:excess_males_sum_tableC1_col5=%.6f\n', coef(m_sum)['pop_15_44_muni_gendergap_2015']))
cat(sprintf('RESULT:excess_males_annual_tableC1_col6=%.6f\n', coef(m_ann)['pop_15_44_muni_gendergap_2015']))
cat(sprintf('RESULT:n_obs_sum_tableC1_col5=%d\n', nobs(m_sum)))
cat(sprintf('RESULT:n_obs_annual_tableC1_col6=%d\n', nobs(m_ann)))