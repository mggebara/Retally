suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances.script-free"

results <- list()
add_result <- function(name, value) {
  results[[name]] <<- value
}

safe_num <- function(x) {
  x <- zap_labels(x)
  suppressWarnings(as.numeric(x))
}

# =====================================================================
# Part 1: Individual-level survey analysis (Table 1)
# =====================================================================
survey <- read_dta(file.path(base_dir, "survey.dta"))
cat(sprintf("SAMPLE:table1_col1:loaded=%d\n", nrow(survey)))

nm <- names(survey)
has <- function(v) v[v %in% nm]

# Wave 4 restriction
wave_num <- safe_num(survey$wave)
w4_val <- if (any(wave_num == 4, na.rm = TRUE)) 4 else max(wave_num, na.rm = TRUE)
sv <- survey[!is.na(wave_num) & wave_num == w4_val, ]
cat(sprintf("SAMPLE:table1_col1:wave4=%d\n", nrow(sv)))

# Convert all to plain numeric (labelled -> numeric)
for (v in names(sv)) {
  if (inherits(sv[[v]], "haven_labelled") || is.numeric(sv[[v]])) {
    sv[[v]] <- safe_num(sv[[v]])
  }
}

dv <- "hate_violence_means"
mate <- "MateComp.cont"
job <- "JobComp.cont"
life <- "LifeSatis.cont"

# rename columns with dots for formula safety
names(sv) <- gsub("\\.", "_", names(sv))
mate <- "MateComp_cont"; job <- "JobComp_cont"; life <- "LifeSatis_cont"
nm <- names(sv)
has <- function(v) v[v %in% nm]

# Sociodemographic controls
socio_num <- has(c("age", "eduyrs", "income", "household_size", "self_econ"))
socio_fac <- has(c("gender", "occupation", "citizenship", "religion", "state"))
# employment status if present under some name
emp_cands <- nm[grepl("employ|emp_stat|erwerb", nm, ignore.case = TRUE)]
socio_fac <- unique(c(socio_fac, emp_cands))

# National attitudes toward refugees
nat_att <- has(c("ref_citizenship", "ref_reduce", "ref_crime", "ref_integrating",
                 "ref_moredone", "ref_cultgiveup", "ref_economy", "ref_terror"))
# Local attitudes toward refugees
loc_att <- nm[grepl("^ref_loc_", nm)]
# Additional controls
add_ctrl <- has(c("contact_ind", "distance_ref", "settle_ref", "refugee_ind",
                  "afd", "afd_ind", "lrscale", "muslim_ind"))

for (v in socio_fac) sv[[v]] <- factor(sv[[v]])

fml <- function(rhs) as.formula(paste(dv, "~", paste(rhs, collapse = " + ")))

# Columns 1-2 sample: non-missing DV, mate, job, life
s12 <- sv[complete.cases(sv[, c(dv, mate, job, life)]), ]
cat(sprintf("SAMPLE:table1_col1:nonmissing_core_vars=%d\n", nrow(s12)))

m1 <- lm(fml(mate), data = s12)
cat(sprintf("SAMPLE:table1_col1:estimation=%d\n", nobs(m1)))

cat(sprintf("SAMPLE:table1_col2:loaded=%d\n", nrow(survey)))
cat(sprintf("SAMPLE:table1_col2:wave4=%d\n", nrow(sv)))
cat(sprintf("SAMPLE:table1_col2:nonmissing_core_vars=%d\n", nrow(s12)))
m2 <- lm(fml(c(mate, job, life)), data = s12)
cat(sprintf("SAMPLE:table1_col2:estimation=%d\n", nobs(m2)))

rhs3 <- c(mate, job, life, socio_num, socio_fac)
rhs4 <- c(rhs3, nat_att)
rhs5 <- c(rhs4, loc_att)
rhs6 <- c(rhs5, add_ctrl)

# Columns 3-6: common sample defined by sociodemographic controls (N = 3008);
# missing attitude items would otherwise shrink the sample, so they are
# mean-imputed with missing indicators to keep the stated common N.
s36 <- s12[complete.cases(s12[, c(socio_num, socio_fac)]), ]
for (v in socio_fac) s36[[v]] <- droplevels(s36[[v]])
att_vars <- c(nat_att, loc_att, add_ctrl)
miss_dummies <- c()
for (v in att_vars) {
  if (any(is.na(s36[[v]]))) {
    md <- paste0(v, "_miss")
    s36[[md]] <- as.integer(is.na(s36[[v]]))
    s36[[v]][is.na(s36[[v]])] <- mean(s36[[v]], na.rm = TRUE)
    miss_dummies <- c(miss_dummies, md)
  }
}
md_of <- function(vars) intersect(paste0(vars, "_miss"), miss_dummies)
if (length(miss_dummies) > 0) {
  cat(sprintf("DEVIATION: attitude items with missing values mean-imputed with missing indicators to keep the common columns 3-6 sample: %s\n",
              paste(sub("_miss$", "", miss_dummies), collapse = ",")))
}

models36 <- list()
rhs_list <- list(col3 = rhs3,
                 col4 = c(rhs4, md_of(nat_att)),
                 col5 = c(rhs5, md_of(c(nat_att, loc_att))),
                 col6 = c(rhs6, md_of(att_vars)))
for (cn in names(rhs_list)) {
  sname <- paste0("table1_", cn)
  cat(sprintf("SAMPLE:%s:loaded=%d\n", sname, nrow(survey)))
  cat(sprintf("SAMPLE:%s:wave4=%d\n", sname, nrow(sv)))
  cat(sprintf("SAMPLE:%s:nonmissing_core_vars=%d\n", sname, nrow(s12)))
  cat(sprintf("SAMPLE:%s:nonmissing_sociodemographics=%d\n", sname, nrow(s36)))
  m <- lm(fml(rhs_list[[cn]]), data = s36)
  cat(sprintf("SAMPLE:%s:estimation=%d\n", sname, nobs(m)))
  models36[[cn]] <- m
}

add_result("mate_competition_table1_col1", unname(coef(m1)[mate]))
add_result("mate_competition_table1_col1_se", unname(sqrt(diag(vcov(m1)))[mate]))
add_result("mate_competition_table1_col2", unname(coef(m2)[mate]))
add_result("mate_competition_table1_col3", unname(coef(models36$col3)[mate]))
add_result("mate_competition_table1_col4", unname(coef(models36$col4)[mate]))
add_result("mate_competition_table1_col5", unname(coef(models36$col5)[mate]))
add_result("mate_competition_table1_col6", unname(coef(models36$col6)[mate]))
add_result("mate_competition_table1_col6_se", unname(sqrt(diag(vcov(models36$col6)))[mate]))
add_result("job_competition_table1_col2", unname(coef(m2)[job]))
add_result("n_obs_table1_col1", nobs(m1))
add_result("n_obs_table1_col3", nobs(models36$col3))

# =====================================================================
# Part 2: Ecological analysis (SI Table C1, columns 5 and 6)
# =====================================================================
ctx <- read_dta(file.path(base_dir, "context.dta"))
for (v in names(ctx)) ctx[[v]] <- safe_num(ctx[[v]])
ctx <- ctx %>% filter(year %in% 2015:2017)

key <- "pop_15_44_muni_gendergap_2015"
controls <- c("log_population_muni_2015", "log_popdens_muni_2015", "d_pop1511_muni",
              "log_unemp_all_muni_2015", "unemp_gendergap_2015",
              "log_pop_ref_2014", "log_ref_inflow_1514",
              "pc_hidegree_all2011", "pc_manufacturing_2015", "d_manuf1115",
              "vote_afd_2013_muni", "log_violence_percap_2015")
controls <- controls[controls %in% names(ctx)]

# Municipality-level cross-section (Sum model)
muni <- ctx %>%
  group_by(ags_muni) %>%
  summarise(
    hate_sum = sum(Hate_all_muni, na.rm = TRUE),
    hate_any = as.integer(any(Hate_all_muni_bin == 1, na.rm = TRUE) | sum(Hate_all_muni, na.rm = TRUE) > 0),
    across(all_of(c(key, controls, "ags_county", "ags_state")), ~ first(na.omit(.x))),
    .groups = "drop"
  )
cat(sprintf("SAMPLE:tableC1_sum:loaded=%d\n", nrow(muni)))

q <- quantile(muni[[key]], c(0.025, 0.975), na.rm = TRUE)
keep_munis <- muni$ags_muni[!is.na(muni[[key]]) & muni[[key]] >= q[1] & muni[[key]] <= q[2]]
muni_t <- muni %>% filter(ags_muni %in% keep_munis)
cat(sprintf("SAMPLE:tableC1_sum:drop_extreme_excess_males=%d\n", nrow(muni_t)))

muni_cc <- muni_t[complete.cases(muni_t[, c("hate_any", key, controls, "ags_state", "ags_county")]), ]
cat(sprintf("SAMPLE:tableC1_sum:complete_cases=%d\n", nrow(muni_cc)))

f_sum <- as.formula(paste("hate_any ~", paste(c(key, controls), collapse = " + "), "| ags_state"))
m_sum <- feglm(f_sum, data = muni_cc, family = binomial("logit"), cluster = ~ags_county)
cat(sprintf("SAMPLE:tableC1_sum:estimation=%d\n", nobs(m_sum)))

# Annual panel
cat(sprintf("SAMPLE:tableC1_annual:loaded=%d\n", nrow(ctx)))
ann <- ctx %>% filter(ags_muni %in% keep_munis)
cat(sprintf("SAMPLE:tableC1_annual:drop_extreme_excess_males=%d\n", nrow(ann)))
ann$hate_bin <- ifelse(!is.na(ann$Hate_all_muni_bin), ann$Hate_all_muni_bin,
                       as.integer(ann$Hate_all_muni > 0))
ann_cc <- ann[complete.cases(ann[, c("hate_bin", key, controls, "ags_state", "ags_county", "year")]), ]
cat(sprintf("SAMPLE:tableC1_annual:complete_cases=%d\n", nrow(ann_cc)))

f_ann <- as.formula(paste("hate_bin ~", paste(c(key, controls), collapse = " + "), "| ags_state + year"))
m_ann <- feglm(f_ann, data = ann_cc, family = binomial("logit"), cluster = ~ags_county)
cat(sprintf("SAMPLE:tableC1_annual:estimation=%d\n", nobs(m_ann)))

add_result("excess_males_sum_tableC1_col5", unname(coef(m_sum)[key]))
add_result("excess_males_sum_tableC1_col5_se", unname(sqrt(diag(vcov(m_sum)))[key]))
add_result("excess_males_annual_tableC1_col6", unname(coef(m_ann)[key]))
add_result("excess_males_annual_tableC1_col6_se", unname(sqrt(diag(vcov(m_ann)))[key]))
add_result("n_obs_sum_tableC1_col5", nobs(m_sum))
add_result("n_obs_annual_tableC1_col6", nobs(m_ann))

# =====================================================================
# Output
# =====================================================================
for (nm_r in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm_r, as.numeric(results[[nm_r]])))
}
