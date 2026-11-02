suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(lmtest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/dancygier_2022_hate_crimes_gender_imbalances"

results <- list()
add_result <- function(name, value) {
  if (!is.null(value) && length(value) == 1 && is.finite(as.numeric(value))) {
    results[[name]] <<- as.numeric(value)
  }
}

# ------------------------------------------------------------------
# Helpers to mimic readstata13::read.dta13 conversion behaviour
# ------------------------------------------------------------------
to_plain <- function(x) {
  if (inherits(x, "haven_labelled") || inherits(x, "labelled")) {
    x <- zap_labels(x)
  }
  attr(x, "label") <- NULL
  attr(x, "format.stata") <- NULL
  x
}

# read.dta13 (convert.factors = TRUE, generate.factors = FALSE) turns a labelled
# numeric variable into a factor only if every observed value carries a label.
mimic_rs13 <- function(x) {
  if (inherits(x, "haven_labelled")) {
    labs <- attr(x, "labels")
    vals <- unique(as.numeric(zap_labels(x)))
    vals <- vals[!is.na(vals)]
    if (!is.null(labs) && length(labs) > 0 && length(vals) > 0 &&
        all(vals %in% as.numeric(labs))) {
      return(factor(as.numeric(zap_labels(x))))
    }
    return(as.numeric(zap_labels(x)))
  }
  to_plain(x)
}

as_num <- function(x) {
  x <- to_plain(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) x <- suppressWarnings(as.numeric(x))
  as.numeric(x)
}

# ==================================================================
# PART 1: Survey analysis, Table 1
# ==================================================================
tryCatch({
  sv_raw <- read_dta(file.path(base_dir, "survey.dta"))
  sv <- as.data.frame(sv_raw)

  wave_num <- as_num(sv_raw$wave)
  if (!any(wave_num == 4, na.rm = TRUE)) {
    wave_chr <- as.character(as_factor(sv_raw$wave))
    keep <- grepl("4", wave_chr)
  } else {
    keep <- !is.na(wave_num) & wave_num == 4
  }

  # Numeric variables used linearly
  num_vars <- c("hate_violence_means", "MateComp.cont", "JobComp.cont", "LifeSatis.cont")
  # Variables used linearly in the authors' formula but whose type depended on read.dta13
  lin_vars <- c("eduyrs", "lrscale", "afd", "muslim_ind", "afd_ind", "contact_ind")
  # Variables wrapped in factor()
  fac_vars <- c("age_group", "gender", "state", "citizenship", "marital", "religion",
                "occupation", "income", "household_size", "self_econ",
                "ref_integrating", "ref_citizenship", "ref_reduce", "ref_moredone",
                "ref_cultgiveup", "ref_economy", "ref_crime", "ref_terror",
                "ref_loc_services", "ref_loc_economy", "ref_loc_crime", "ref_loc_culture",
                "ref_loc_islam", "ref_loc_schools", "ref_loc_housing", "ref_loc_wayoflife",
                "distance_ref", "settle_ref")

  d <- data.frame(row.names = seq_len(nrow(sv)))
  for (v in num_vars) {
    if (v %in% names(sv)) d[[v]] <- as_num(sv_raw[[v]]) else d[[v]] <- NA_real_
  }
  for (v in lin_vars) {
    if (v %in% names(sv)) d[[v]] <- mimic_rs13(sv_raw[[v]]) else d[[v]] <- NA_real_
  }
  for (v in fac_vars) {
    if (v %in% names(sv)) {
      x <- to_plain(sv_raw[[v]])
      if (is.character(x)) x[x == ""] <- NA
      d[[v]] <- factor(x)
    } else {
      cat("Warning: missing survey variable", v, "\n")
    }
  }
  dat_use <- d[keep, , drop = FALSE]
  cat("Wave 4 rows:", nrow(dat_use), "\n")
  for (v in lin_vars) cat(v, "class:", class(dat_use[[v]])[1], "\n")

  f1 <- hate_violence_means ~ MateComp.cont
  f2 <- hate_violence_means ~ MateComp.cont + JobComp.cont + LifeSatis.cont
  socio <- "factor(age_group) + factor(gender) + factor(state) + factor(citizenship) + factor(marital) + factor(religion) + eduyrs + factor(occupation) + factor(income) + factor(household_size) + factor(self_econ)"
  nat <- "factor(ref_integrating) + factor(ref_citizenship) + factor(ref_reduce) + factor(ref_moredone) + factor(ref_cultgiveup) + factor(ref_economy) + factor(ref_crime) + factor(ref_terror)"
  loc <- "factor(ref_loc_services) + factor(ref_loc_economy) + factor(ref_loc_crime) + factor(ref_loc_culture) + factor(ref_loc_islam) + factor(ref_loc_schools) + factor(ref_loc_housing) + factor(ref_loc_wayoflife)"
  addl <- "factor(distance_ref) + factor(settle_ref) + lrscale + afd + muslim_ind + afd_ind + contact_ind"
  base2 <- "hate_violence_means ~ MateComp.cont + JobComp.cont + LifeSatis.cont"
  f3 <- as.formula(paste(base2, socio, sep = " + "))
  f4 <- as.formula(paste(base2, socio, nat, sep = " + "))
  f5 <- as.formula(paste(base2, socio, nat, loc, sep = " + "))
  f6 <- as.formula(paste(base2, socio, nat, loc, addl, sep = " + "))

  forms <- list(f1, f2, f3, f4, f5, f6)
  fits <- list()
  for (i in seq_along(forms)) {
    fits[[i]] <- tryCatch(lm(forms[[i]], data = dat_use), error = function(e) {
      cat("Model", i, "failed:", conditionMessage(e), "\n"); NULL
    })
    if (!is.null(fits[[i]])) {
      s <- summary(fits[[i]])
      cf <- s$coefficients
      cat(sprintf("Table1 col%d: MateComp = %.4f (SE %.4f), N = %d, R2 = %.3f, adjR2 = %.3f\n",
                  i, cf["MateComp.cont", 1], cf["MateComp.cont", 2], nobs(fits[[i]]),
                  s$r.squared, s$adj.r.squared))
      add_result(paste0("mate_competition_table1_col", i), coef(fits[[i]])["MateComp.cont"])
    }
  }
  if (!is.null(fits[[2]])) {
    add_result("job_competition_table1_col2", coef(fits[[2]])["JobComp.cont"])
    add_result("n_obs_table1_col1", nobs(fits[[2]]))
  } else if (!is.null(fits[[1]])) {
    add_result("n_obs_table1_col1", nobs(fits[[1]]))
  }
  if (!is.null(fits[[3]])) add_result("n_obs_table1_col3", nobs(fits[[3]]))
}, error = function(e) cat("Survey part failed:", conditionMessage(e), "\n"))

# ==================================================================
# PART 2: Context analysis, SI Table C1 columns (5) and (6)
# ==================================================================
tryCatch({
  cx_raw <- read_dta(file.path(base_dir, "context.dta"))
  dat <- as.data.frame(lapply(cx_raw, to_plain), stringsAsFactors = FALSE)

  dat$year <- as_num(dat$year)
  num_cols <- c("Hate_all_muni", "pop_15_44_muni_gendergap_2015",
                "log_population_muni_2015", "log_popdens_muni_2015",
                "log_unemp_all_muni_2015", "d_pop1511_muni", "vote_afd_2013_muni",
                "log_ref_inflow_1514", "log_pop_ref_2014", "log_violence_percap_2015",
                "pc_hidegree_all2011", "d_manuf1115", "pc_manufacturing_2015",
                "unemp_gendergap_2015")
  # Construct logs if not present
  if (!"log_population_muni_2015" %in% names(dat) && "population_muni_2015" %in% names(dat))
    dat$log_population_muni_2015 <- log(as_num(dat$population_muni_2015))
  if (!"log_popdens_muni_2015" %in% names(dat) && "popdens_muni_2015" %in% names(dat))
    dat$log_popdens_muni_2015 <- log(as_num(dat$popdens_muni_2015))
  if (!"log_pop_ref_2014" %in% names(dat) && "pop_ref_2014" %in% names(dat))
    dat$log_pop_ref_2014 <- log(as_num(dat$pop_ref_2014))
  if (!"log_violence_percap_2015" %in% names(dat) && "violence_percap_2015" %in% names(dat))
    dat$log_violence_percap_2015 <- log(as_num(dat$violence_percap_2015))
  for (v in num_cols) {
    if (v %in% names(dat)) dat[[v]] <- as_num(dat[[v]]) else cat("Warning: missing context var", v, "\n")
  }
  if (!"Hate_all_muni_bin" %in% names(dat)) {
    dat$Hate_all_muni_bin <- as.numeric(dat$Hate_all_muni > 0)
  } else {
    dat$Hate_all_muni_bin <- as_num(dat$Hate_all_muni_bin)
  }
  dat$ags_muni <- as.character(dat$ags_muni)
  dat$ags_county <- as.character(dat$ags_county)
  dat$ags_state <- as.character(dat$ags_state)

  dat <- dat[order(dat$year, dat$ags_muni), ]
  dat_2015 <- dat[dat$year == 2015, ]
  dat_2016 <- dat[dat$year == 2016, ]
  dat_2017 <- dat[dat$year == 2017, ]
  h16 <- dat_2016$Hate_all_muni[match(dat_2015$ags_muni, dat_2016$ags_muni)]
  h17 <- dat_2017$Hate_all_muni[match(dat_2015$ags_muni, dat_2017$ags_muni)]
  dat_2015$Hate_all_muni_1517 <- dat_2015$Hate_all_muni + h16 + h17
  dat_2015$Hate_all_muni_1517_bin <- ifelse(dat_2015$Hate_all_muni_1517 > 0, 1, 0)

  range_x <- quantile(dat_2015$pop_15_44_muni_gendergap_2015, c(0.025, 0.975), na.rm = TRUE)
  dat_2015_s <- dat_2015[which(dat_2015$pop_15_44_muni_gendergap_2015 >= range_x[1] &
                                 dat_2015$pop_15_44_muni_gendergap_2015 <= range_x[2]), ]
  dat_s <- dat[which(dat$pop_15_44_muni_gendergap_2015 >= range_x[1] &
                       dat$pop_15_44_muni_gendergap_2015 <= range_x[2]), ]

  controls <- c("pop_15_44_muni_gendergap_2015",
                "log_population_muni_2015", "log_popdens_muni_2015",
                "log_unemp_all_muni_2015", "d_pop1511_muni", "vote_afd_2013_muni",
                "log_ref_inflow_1514", "log_pop_ref_2014", "log_violence_percap_2015",
                "pc_hidegree_all2011", "d_manuf1115", "pc_manufacturing_2015",
                "unemp_gendergap_2015")

  run_logit <- function(yvar, data, fe) {
    vars <- unique(c(yvar, controls, fe, "ags_county"))
    du <- data[, vars]
    du <- du[complete.cases(du), ]
    rhs <- paste(c(controls, paste0("as.factor(", fe, ")")), collapse = " + ")
    f <- as.formula(paste(yvar, "~", rhs))
    fit <- glm(f, data = du, family = binomial())
    vc <- tryCatch(vcovCL(fit, cluster = du$ags_county), error = function(e) NULL)
    se <- if (!is.null(vc)) sqrt(diag(vc))["pop_15_44_muni_gendergap_2015"] else NA
    list(fit = fit, n = nrow(du), se = se)
  }

  m5 <- tryCatch(run_logit("Hate_all_muni_1517_bin", dat_2015_s, c("ags_state")),
                 error = function(e) { cat("C1 col5 failed:", conditionMessage(e), "\n"); NULL })
  if (!is.null(m5)) {
    b <- coef(m5$fit)["pop_15_44_muni_gendergap_2015"]
    cat(sprintf("Table C1 col5 (Sum): Excess Males = %.4f (cluster SE %.4f), N = %d\n", b, m5$se, m5$n))
    add_result("excess_males_sum_tableC1_col5", b)
    add_result("n_obs_sum_tableC1_col5", m5$n)
  }

  m6 <- tryCatch(run_logit("Hate_all_muni_bin", dat_s, c("ags_state", "year")),
                 error = function(e) { cat("C1 col6 failed:", conditionMessage(e), "\n"); NULL })
  if (!is.null(m6)) {
    b <- coef(m6$fit)["pop_15_44_muni_gendergap_2015"]
    cat(sprintf("Table C1 col6 (Annual): Excess Males = %.4f (cluster SE %.4f), N = %d\n", b, m6$se, m6$n))
    add_result("excess_males_annual_tableC1_col6", b)
    add_result("n_obs_annual_tableC1_col6", m6$n)
  }
}, error = function(e) cat("Context part failed:", conditionMessage(e), "\n"))

# ==================================================================
# Emit results
# ==================================================================
order_names <- c("mate_competition_table1_col1", "mate_competition_table1_col2",
                 "mate_competition_table1_col3", "mate_competition_table1_col4",
                 "mate_competition_table1_col5", "mate_competition_table1_col6",
                 "job_competition_table1_col2", "n_obs_table1_col1", "n_obs_table1_col3",
                 "excess_males_sum_tableC1_col5", "excess_males_annual_tableC1_col6",
                 "n_obs_sum_tableC1_col5", "n_obs_annual_tableC1_col6")
for (nm in order_names) {
  if (!is.null(results[[nm]])) {
    cat(sprintf("RESULT:%s=%s\n", nm, format(results[[nm]], digits = 10)))
  }
}