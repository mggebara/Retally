suppressPackageStartupMessages({
  library(haven)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances"

results <- list()
emit <- function(name, value) {
  if (!is.null(value) && length(value) == 1 && is.finite(value)) {
    results[[name]] <<- value
  }
}

# Mimic readstata13::read.dta13 default conversion: a variable with value labels
# is converted to a factor only if every observed value carries a label;
# otherwise it is kept numeric.
convert_like_readstata13 <- function(df) {
  for (nm in names(df)) {
    x <- df[[nm]]
    if (inherits(x, "haven_labelled")) {
      labs <- attr(x, "labels")
      vals <- unique(as.vector(zap_missing(x)))
      vals <- vals[!is.na(vals)]
      if (!is.null(labs) && length(labs) > 0 && length(vals) > 0 &&
          all(vals %in% as.vector(labs))) {
        f <- as_factor(x, levels = "labels")
        f <- droplevels(f)
        df[[nm]] <- f
      } else {
        df[[nm]] <- as.vector(zap_labels(zap_missing(x)))
      }
    } else if (is.character(x)) {
      df[[nm]] <- x
    }
  }
  as.data.frame(df, stringsAsFactors = FALSE)
}

# =========================================================
# Part 1: Survey, Table 1 (Wave 4)
# =========================================================
tryCatch({
  dat <- read_dta(file.path(base_dir, "survey.dta"))
  dat <- convert_like_readstata13(dat)
  wave_num <- suppressWarnings(as.numeric(as.character(dat$wave)))
  if (all(is.na(wave_num))) wave_num <- as.numeric(dat$wave)
  dat_use <- dat[!is.na(wave_num) & wave_num == 4, ]

  # Make sure the numeric regressors / outcome are numeric
  num_force <- c("hate_violence_means", "MateComp.cont", "JobComp.cont", "LifeSatis.cont")
  for (v in num_force) {
    if (is.factor(dat_use[[v]])) {
      dat_use[[v]] <- suppressWarnings(as.numeric(as.character(dat_use[[v]])))
      if (all(is.na(dat_use[[v]]))) dat_use[[v]] <- as.numeric(dat[[v]][!is.na(wave_num) & wave_num == 4])
    }
  }

  lm1 <- lm(hate_violence_means ~ MateComp.cont, data = dat_use)
  lm2 <- lm(hate_violence_means ~ MateComp.cont + JobComp.cont + LifeSatis.cont, data = dat_use)

  f3 <- "hate_violence_means ~ MateComp.cont + JobComp.cont + LifeSatis.cont +
            factor(age_group) + factor(gender) + factor(state) + factor(citizenship) +
            factor(marital) + factor(religion) + eduyrs + factor(occupation) +
            factor(income) + factor(household_size) + factor(self_econ)"
  f4 <- paste(f3, "+ factor(ref_integrating) + factor(ref_citizenship) + factor(ref_reduce) +
            factor(ref_moredone) + factor(ref_cultgiveup) + factor(ref_economy) +
            factor(ref_crime) + factor(ref_terror)")
  f5 <- paste(f4, "+ factor(ref_loc_services) + factor(ref_loc_economy) + factor(ref_loc_crime) +
            factor(ref_loc_culture) + factor(ref_loc_islam) + factor(ref_loc_schools) +
            factor(ref_loc_housing) + factor(ref_loc_wayoflife)")
  f6 <- paste(f5, "+ factor(distance_ref) + factor(settle_ref) +
            lrscale + afd + muslim_ind + afd_ind + contact_ind")

  emit("mate_competition_table1_col1", unname(coef(lm1)["MateComp.cont"]))
  emit("mate_competition_table1_col2", unname(coef(lm2)["MateComp.cont"]))
  emit("job_competition_table1_col2", unname(coef(lm2)["JobComp.cont"]))
  emit("n_obs_table1_col1", nobs(lm2))

  lm3 <- tryCatch(lm(as.formula(f3), data = dat_use), error = function(e) { message(e$message); NULL })
  if (!is.null(lm3)) {
    emit("mate_competition_table1_col3", unname(coef(lm3)["MateComp.cont"]))
    emit("n_obs_table1_col3", nobs(lm3))
  }
  lm4 <- tryCatch(lm(as.formula(f4), data = dat_use), error = function(e) { message(e$message); NULL })
  if (!is.null(lm4)) emit("mate_competition_table1_col4", unname(coef(lm4)["MateComp.cont"]))
  lm5 <- tryCatch(lm(as.formula(f5), data = dat_use), error = function(e) { message(e$message); NULL })
  if (!is.null(lm5)) emit("mate_competition_table1_col5", unname(coef(lm5)["MateComp.cont"]))
  lm6 <- tryCatch(lm(as.formula(f6), data = dat_use), error = function(e) { message(e$message); NULL })
  if (!is.null(lm6)) emit("mate_competition_table1_col6", unname(coef(lm6)["MateComp.cont"]))
}, error = function(e) message("Survey part failed: ", e$message))

# =========================================================
# Part 2: Context, SI Table C1 columns (5) and (6)
# =========================================================
tryCatch({
  dat <- read_dta(file.path(base_dir, "context.dta"))
  dat <- as.data.frame(zap_labels(zap_missing(dat)))
  for (nm in names(dat)) {
    if (inherits(dat[[nm]], "haven_labelled")) dat[[nm]] <- as.vector(dat[[nm]])
  }
  dat$year <- as.numeric(dat$year)
  dat <- dat[order(dat$year, dat$ags_muni), ]

  dat_2015 <- dat[dat$year == 2015, ]
  dat_2016 <- dat[dat$year == 2016, ]
  dat_2017 <- dat[dat$year == 2017, ]
  h16 <- dat_2016$Hate_all_muni[match(dat_2015$ags_muni, dat_2016$ags_muni)]
  h17 <- dat_2017$Hate_all_muni[match(dat_2015$ags_muni, dat_2017$ags_muni)]
  dat_2015$Hate_all_muni_1517 <- dat_2015$Hate_all_muni + h16 + h17
  dat_2015$Hate_all_muni_1517_bin <- ifelse(dat_2015$Hate_all_muni_1517 > 0, 1, 0)
  if (!("Hate_all_muni_bin" %in% names(dat))) dat$Hate_all_muni_bin <- as.numeric(dat$Hate_all_muni > 0)

  range_x <- quantile(dat_2015$pop_15_44_muni_gendergap_2015, c(0.025, 0.975), na.rm = TRUE)
  keep15 <- !is.na(dat_2015$pop_15_44_muni_gendergap_2015) &
    dat_2015$pop_15_44_muni_gendergap_2015 >= range_x[1] &
    dat_2015$pop_15_44_muni_gendergap_2015 <= range_x[2]
  dat_2015_s <- dat_2015[keep15, ]
  keepall <- !is.na(dat$pop_15_44_muni_gendergap_2015) &
    dat$pop_15_44_muni_gendergap_2015 >= range_x[1] &
    dat$pop_15_44_muni_gendergap_2015 <= range_x[2]
  dat_s <- dat[keepall, ]

  ctrl <- c("pop_15_44_muni_gendergap_2015",
            "log_population_muni_2015", "log_popdens_muni_2015",
            "log_unemp_all_muni_2015", "d_pop1511_muni", "vote_afd_2013_muni",
            "log_ref_inflow_1514", "log_pop_ref_2014", "log_violence_percap_2015",
            "pc_hidegree_all2011", "d_manuf1115", "pc_manufacturing_2015",
            "unemp_gendergap_2015")

  fit_logit <- function(yvar, fe, d) {
    vars <- unique(c(yvar, ctrl, fe, "ags_county"))
    du <- d[, vars]
    du <- du[complete.cases(du), ]
    fin <- rep(TRUE, nrow(du))
    for (v in c(yvar, ctrl)) fin <- fin & is.finite(du[[v]])
    du <- du[fin, ]
    rhs <- paste(c(ctrl, paste0("as.factor(", fe, ")")), collapse = " + ")
    f <- as.formula(paste(yvar, "~", rhs))
    fit <- glm(f, data = du, family = binomial())
    list(fit = fit, n = nrow(du))
  }

  m5 <- fit_logit("Hate_all_muni_1517_bin", "ags_state", dat_2015_s)
  emit("excess_males_sum_tableC1_col5", unname(coef(m5$fit)["pop_15_44_muni_gendergap_2015"]))
  emit("n_obs_sum_tableC1_col5", length(m5$fit$residuals))

  m6 <- fit_logit("Hate_all_muni_bin", c("ags_state", "year"), dat_s)
  emit("excess_males_annual_tableC1_col6", unname(coef(m6$fit)["pop_15_44_muni_gendergap_2015"]))
  emit("n_obs_annual_tableC1_col6", length(m6$fit$residuals))
}, error = function(e) message("Context part failed: ", e$message))

order_names <- c("mate_competition_table1_col1", "mate_competition_table1_col2",
                 "mate_competition_table1_col3", "mate_competition_table1_col4",
                 "mate_competition_table1_col5", "mate_competition_table1_col6",
                 "job_competition_table1_col2", "n_obs_table1_col1", "n_obs_table1_col3",
                 "excess_males_sum_tableC1_col5", "excess_males_annual_tableC1_col6",
                 "n_obs_sum_tableC1_col5", "n_obs_annual_tableC1_col6")
for (nm in order_names) {
  if (!is.null(results[[nm]])) {
    cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
  }
}
