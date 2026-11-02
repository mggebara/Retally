# Retally reproduction: Dancygier et al. (2022) Hate Crimes and Gender Imbalances
# Seeded mode: follows SurveyAnalysis_Main.R (Table 1) and ContextAnalysis_Appendix.R (Table C1).
set.seed(42)
suppressMessages({library(haven); library(sandwich); library(lmtest)})
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/seeded/2026-11-02-b/mount/dancygier_2022_hate_crimes_gender_imbalances"

strip <- function(df) { df[] <- lapply(df, function(x) { if (inherits(x, "haven_labelled")) x <- as.vector(zap_labels(x)); x }); as.data.frame(df) }

# ---------------- Table 1 (survey, wave 4, OLS) ----------------
s <- strip(read_dta(file.path(D, "survey.dta")))
dat_use <- s[s$wave == 4, ]

f1 <- "hate_violence_means ~ MateComp.cont"
f2 <- paste(f1, "+ JobComp.cont + LifeSatis.cont")
f3 <- paste(f2, "+ factor(age_group) + factor(gender) + factor(state) + factor(citizenship) + factor(marital) +
  factor(religion) + eduyrs + factor(occupation) + factor(income) + factor(household_size) + factor(self_econ)")
f4 <- paste(f3, "+ factor(ref_integrating) + factor(ref_citizenship) + factor(ref_reduce) + factor(ref_moredone) +
  factor(ref_cultgiveup) + factor(ref_economy) + factor(ref_crime) + factor(ref_terror)")
f5 <- paste(f4, "+ factor(ref_loc_services) + factor(ref_loc_economy) + factor(ref_loc_crime) + factor(ref_loc_culture) +
  factor(ref_loc_islam) + factor(ref_loc_schools) + factor(ref_loc_housing) + factor(ref_loc_wayoflife)")
f6 <- paste(f5, "+ factor(distance_ref) + factor(settle_ref) + lrscale + afd + muslim_ind + afd_ind + contact_ind")

lms <- lapply(list(f1, f2, f3, f4, f5, f6), function(f) lm(as.formula(f), data = dat_use))
for (i in 1:6) cat(sprintf("Table1 col%d: Mate=%.4f (se %.4f)  N=%d\n", i,
                           coef(lms[[i]])["MateComp.cont"],
                           sqrt(diag(vcov(lms[[i]])))["MateComp.cont"], nobs(lms[[i]])))
cat(sprintf("Table1 col2: Job=%.4f\n", coef(lms[[2]])["JobComp.cont"]))

# ---------------- Table C1 (context, logit, county-clustered) ----------------
cx <- strip(read_dta(file.path(D, "context.dta")))
d15 <- cx[cx$year == 2015, ]; d16 <- cx[cx$year == 2016, ]; d17 <- cx[cx$year == 2017, ]
stopifnot(identical(d15$ags_muni, d16$ags_muni), identical(d15$ags_muni, d17$ags_muni))
d15$Hate_all_muni_1517 <- d15$Hate_all_muni + d16$Hate_all_muni + d17$Hate_all_muni
d15$Hate_all_muni_1517_bin <- ifelse(d15$Hate_all_muni_1517 > 0, 1, 0)

rx <- quantile(d15$pop_15_44_muni_gendergap_2015, c(0.025, 0.975), na.rm = TRUE)
keep <- function(d) d[!is.na(d$pop_15_44_muni_gendergap_2015) &
                        d$pop_15_44_muni_gendergap_2015 >= rx[1] & d$pop_15_44_muni_gendergap_2015 <= rx[2], ]
d15s <- keep(d15); ds <- keep(cx)

ctrl <- "pop_15_44_muni_gendergap_2015 + log_population_muni_2015 + log_popdens_muni_2015 +
  log_unemp_all_muni_2015 + d_pop1511_muni + vote_afd_2013_muni + log_ref_inflow_1514 + log_pop_ref_2014 +
  log_violence_percap_2015 + pc_hidegree_all2011 + d_manuf1115 + pc_manufacturing_2015 + unemp_gendergap_2015"

bin_fit <- function(fml, data, id = "ags_county") {
  fml <- as.formula(fml)
  du <- na.omit(data[, unique(c(all.vars(fml), id))])
  fit <- glm(fml, data = du, family = "binomial")
  V <- vcovCL(fit, cluster = du[[id]])
  list(fit = fit, se = sqrt(diag(V)), n = nobs(fit))
}
c5 <- bin_fit(paste("Hate_all_muni_1517_bin ~", ctrl, "+ as.factor(ags_state)"), d15s)
c6 <- bin_fit(paste("Hate_all_muni_bin ~", ctrl, "+ as.factor(ags_state) + as.factor(year)"), ds)
v <- "pop_15_44_muni_gendergap_2015"
cat(sprintf("C1 col5: %.4f (se %.4f) N=%d\n", coef(c5$fit)[v], c5$se[v], c5$n))
cat(sprintf("C1 col6: %.4f (se %.4f) N=%d\n", coef(c6$fit)[v], c6$se[v], c6$n))

out <- c(
  mate_competition_table1_col1 = unname(coef(lms[[1]])["MateComp.cont"]),
  mate_competition_table1_col2 = unname(coef(lms[[2]])["MateComp.cont"]),
  mate_competition_table1_col3 = unname(coef(lms[[3]])["MateComp.cont"]),
  mate_competition_table1_col4 = unname(coef(lms[[4]])["MateComp.cont"]),
  mate_competition_table1_col5 = unname(coef(lms[[5]])["MateComp.cont"]),
  mate_competition_table1_col6 = unname(coef(lms[[6]])["MateComp.cont"]),
  job_competition_table1_col2 = unname(coef(lms[[2]])["JobComp.cont"]),
  n_obs_table1_col1 = nobs(lms[[1]]),
  n_obs_table1_col3 = nobs(lms[[3]]),
  excess_males_sum_tableC1_col5 = unname(coef(c5$fit)[v]),
  excess_males_annual_tableC1_col6 = unname(coef(c6$fit)[v]),
  n_obs_sum_tableC1_col5 = c5$n,
  n_obs_annual_tableC1_col6 = c6$n)
for (n in names(out)) cat(sprintf("RESULT:%s=%s\n", n, format(out[[n]], digits = 8)))
