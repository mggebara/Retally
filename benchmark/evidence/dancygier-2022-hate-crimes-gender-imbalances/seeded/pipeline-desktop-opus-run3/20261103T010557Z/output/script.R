# Reproduction: Dancygier et al. (2022) "Hate Crimes and Gender Imbalances: Fears over Mate"
# Table 1 (survey OLS) and SI Table C1 columns (5)-(6) (logit, county-clustered SEs)
suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances"

emit <- function(name, value) {
  if (is.null(value) || length(value) == 0 || is.na(value)) return(invisible(NULL))
  cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(value)))
}

# ------------------------------------------------------------------
# Part 1: Survey analysis, Table 1
# ------------------------------------------------------------------
svy <- tryCatch({
  d <- haven::read_dta(file.path(base_dir, "survey.dta"))
  d <- haven::zap_labels(d)
  as.data.frame(d)
}, error = function(e) { message("survey load failed: ", conditionMessage(e)); NULL })

if (!is.null(svy)) {
  dat_use <- svy[!is.na(svy$wave) & svy$wave == 4, ]

  f1 <- hate_violence_means ~ MateComp.cont
  f2 <- hate_violence_means ~ MateComp.cont + JobComp.cont + LifeSatis.cont
  f3 <- hate_violence_means ~ MateComp.cont + JobComp.cont + LifeSatis.cont +
    factor(age_group) + factor(gender) + factor(state) + factor(citizenship) +
    factor(marital) + factor(religion) + eduyrs + factor(occupation) +
    factor(income) + factor(household_size) + factor(self_econ)
  f4 <- update(f3, . ~ . + factor(ref_integrating) + factor(ref_citizenship) +
                 factor(ref_reduce) + factor(ref_moredone) + factor(ref_cultgiveup) +
                 factor(ref_economy) + factor(ref_crime) + factor(ref_terror))
  f5 <- update(f4, . ~ . + factor(ref_loc_services) + factor(ref_loc_economy) +
                 factor(ref_loc_crime) + factor(ref_loc_culture) + factor(ref_loc_islam) +
                 factor(ref_loc_schools) + factor(ref_loc_housing) + factor(ref_loc_wayoflife))
  f6 <- update(f5, . ~ . + factor(distance_ref) + factor(settle_ref) +
                 lrscale + afd + muslim_ind + afd_ind + contact_ind)

  fits <- lapply(list(f1, f2, f3, f4, f5, f6), function(f)
    tryCatch(lm(f, data = dat_use), error = function(e) {
      message("lm failed: ", conditionMessage(e)); NULL }))

  for (j in 1:6) {
    if (!is.null(fits[[j]])) {
      emit(sprintf("mate_competition_table1_col%d", j), coef(fits[[j]])["MateComp.cont"])
      emit(sprintf("mate_competition_se_table1_col%d", j),
           sqrt(diag(vcov(fits[[j]])))["MateComp.cont"])
    }
  }
  if (!is.null(fits[[2]])) {
    emit("job_competition_table1_col2", coef(fits[[2]])["JobComp.cont"])
    emit("n_obs_table1_col1", nobs(fits[[2]]))   # columns (1)-(2) reported N
  }
  if (!is.null(fits[[1]])) emit("n_obs_table1_col1_only_mate", nobs(fits[[1]]))
  if (!is.null(fits[[3]])) emit("n_obs_table1_col3", nobs(fits[[3]]))
  if (!is.null(fits[[6]])) {
    emit("r2_table1_col6", summary(fits[[6]])$r.squared)
    emit("adj_r2_table1_col6", summary(fits[[6]])$adj.r.squared)
  }
}

# ------------------------------------------------------------------
# Part 2: Context analysis, SI Table C1 columns (5) Sum and (6) Annual
# ------------------------------------------------------------------
ctx <- tryCatch({
  d <- haven::read_dta(file.path(base_dir, "context.dta"))
  d <- haven::zap_labels(d)
  as.data.frame(d)
}, error = function(e) { message("context load failed: ", conditionMessage(e)); NULL })

bin_fit <- function(formula, id, data) {
  vars <- unique(c(all.vars(formula), id))
  data_use <- data[, vars]
  data_use <- data_use[complete.cases(data_use), ]
  fit <- glm(formula, data = data_use, family = binomial())
  V <- vcovCL(fit, cluster = data_use[[id]])
  list(fit = fit, vcov = V, n = nobs(fit))
}

if (!is.null(ctx)) {
  dat <- ctx
  dat_2015 <- dat[dat$year == 2015, ]
  dat_2016 <- dat[dat$year == 2016, ]
  dat_2017 <- dat[dat$year == 2017, ]
  # Authors sum by row position (files are aligned by municipality);
  # align explicitly via ags_muni if available, else positional.
  if ("ags_muni" %in% names(dat)) {
    h16 <- dat_2016$Hate_all_muni[match(dat_2015$ags_muni, dat_2016$ags_muni)]
    h17 <- dat_2017$Hate_all_muni[match(dat_2015$ags_muni, dat_2017$ags_muni)]
  } else {
    h16 <- dat_2016$Hate_all_muni
    h17 <- dat_2017$Hate_all_muni
  }
  dat_2015$Hate_all_muni_1517 <- dat_2015$Hate_all_muni + h16 + h17
  dat_2015$Hate_all_muni_1517_bin <- ifelse(dat_2015$Hate_all_muni_1517 > 0, 1, 0)

  if (!"Hate_all_muni_bin" %in% names(dat)) {
    dat$Hate_all_muni_bin <- ifelse(dat$Hate_all_muni > 0, 1, 0)
  }

  range_x <- quantile(dat_2015$pop_15_44_muni_gendergap_2015, c(0.025, 0.975), na.rm = TRUE)
  keep15 <- !is.na(dat_2015$pop_15_44_muni_gendergap_2015) &
    dat_2015$pop_15_44_muni_gendergap_2015 >= range_x[1] &
    dat_2015$pop_15_44_muni_gendergap_2015 <= range_x[2]
  dat_2015_s <- dat_2015[keep15, ]
  keepall <- !is.na(dat$pop_15_44_muni_gendergap_2015) &
    dat$pop_15_44_muni_gendergap_2015 >= range_x[1] &
    dat$pop_15_44_muni_gendergap_2015 <= range_x[2]
  dat_s <- dat[keepall, ]

  rhs <- "pop_15_44_muni_gendergap_2015 + log_population_muni_2015 + log_popdens_muni_2015 +
          log_unemp_all_muni_2015 + d_pop1511_muni + vote_afd_2013_muni +
          log_ref_inflow_1514 + log_pop_ref_2014 + log_violence_percap_2015 +
          pc_hidegree_all2011 + d_manuf1115 + pc_manufacturing_2015 +
          unemp_gendergap_2015"

  f_sum <- as.formula(paste("Hate_all_muni_1517_bin ~", rhs, "+ as.factor(ags_state)"))
  f_ann <- as.formula(paste("Hate_all_muni_bin ~", rhs, "+ as.factor(ags_state) + as.factor(year)"))

  b_sum <- tryCatch(bin_fit(f_sum, "ags_county", dat_2015_s),
                    error = function(e) { message("sum logit failed: ", conditionMessage(e)); NULL })
  b_ann <- tryCatch(bin_fit(f_ann, "ags_county", dat_s),
                    error = function(e) { message("annual logit failed: ", conditionMessage(e)); NULL })

  if (!is.null(b_sum)) {
    emit("excess_males_sum_tableC1_col5", coef(b_sum$fit)["pop_15_44_muni_gendergap_2015"])
    emit("excess_males_sum_se_tableC1_col5",
         sqrt(diag(b_sum$vcov))["pop_15_44_muni_gendergap_2015"])
    emit("n_obs_sum_tableC1_col5", b_sum$n)
  }
  if (!is.null(b_ann)) {
    emit("excess_males_annual_tableC1_col6", coef(b_ann$fit)["pop_15_44_muni_gendergap_2015"])
    emit("excess_males_annual_se_tableC1_col6",
         sqrt(diag(b_ann$vcov))["pop_15_44_muni_gendergap_2015"])
    emit("n_obs_annual_tableC1_col6", b_ann$n)
  }
}