# Reproduction of Dancygier et al. (2022) Table 1 and SI Table C1 cols (5)-(6)
# following SurveyAnalysis_Main.R and ContextAnalysis_Appendix.R (+ Help.R::bin.summary)
set.seed(42)
suppressPackageStartupMessages({ library(haven); library(sandwich); library(lmtest) })
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/seeded/2026-11-02-a/mount/dancygier_2022_hate_crimes_gender_imbalances"

# ---------------- Table 1 ----------------
s <- read_dta(file.path(D, "survey.dta"))
s <- zap_labels(s)   # labelled codes -> plain numeric; factor() below reproduces read.dta13 factors
dat_use <- as.data.frame(s[s$wave == 4, ])

f1 <- hate_violence_means ~ MateComp.cont
f2 <- hate_violence_means ~ MateComp.cont + JobComp.cont + LifeSatis.cont
socio <- "factor(age_group) + factor(gender) + factor(state) + factor(citizenship) + factor(marital) + factor(religion) + eduyrs + factor(occupation) + factor(income) + factor(household_size) + factor(self_econ)"
nat <- "factor(ref_integrating) + factor(ref_citizenship) + factor(ref_reduce) + factor(ref_moredone) + factor(ref_cultgiveup) + factor(ref_economy) + factor(ref_crime) + factor(ref_terror)"
loc <- "factor(ref_loc_services) + factor(ref_loc_economy) + factor(ref_loc_crime) + factor(ref_loc_culture) + factor(ref_loc_islam) + factor(ref_loc_schools) + factor(ref_loc_housing) + factor(ref_loc_wayoflife)"
add <- "factor(distance_ref) + factor(settle_ref) + lrscale + afd + muslim_ind + afd_ind + contact_ind"
base <- "hate_violence_means ~ MateComp.cont + JobComp.cont + LifeSatis.cont"
f3 <- as.formula(paste(base, socio, sep = " + "))
f4 <- as.formula(paste(base, socio, nat, sep = " + "))
f5 <- as.formula(paste(base, socio, nat, loc, sep = " + "))
f6 <- as.formula(paste(base, socio, nat, loc, add, sep = " + "))

lms <- lapply(list(f1, f2, f3, f4, f5, f6), function(f) lm(f, data = dat_use))
for (i in 1:6) {
  ct <- summary(lms[[i]])$coef
  cat(sprintf("Table1 col%d: Mate=%.4f (se %.4f)  N=%d\n", i, ct["MateComp.cont", 1], ct["MateComp.cont", 2], nobs(lms[[i]])))
}

# ---------------- SI Table C1 cols 5-6 ----------------
dat <- as.data.frame(zap_labels(read_dta(file.path(D, "context.dta"))))
dat_2015 <- dat[dat$year == 2015, ]
dat_2016 <- dat[dat$year == 2016, ]
dat_2017 <- dat[dat$year == 2017, ]
cat("muni order aligned across years:", identical(dat_2015$ags_muni, dat_2016$ags_muni) && identical(dat_2015$ags_muni, dat_2017$ags_muni), "\n")
dat_2015$Hate_all_muni_1517 <- dat_2015$Hate_all_muni + dat_2016$Hate_all_muni + dat_2017$Hate_all_muni
dat_2015$Hate_all_muni_1517_bin <- ifelse(dat_2015$Hate_all_muni_1517 > 0, 1, 0)

range_x <- quantile(dat_2015$pop_15_44_muni_gendergap_2015, c(0.025, 0.975), na.rm = TRUE)
keep15 <- which(dat_2015$pop_15_44_muni_gendergap_2015 >= range_x[1] & dat_2015$pop_15_44_muni_gendergap_2015 <= range_x[2])
keepall <- which(dat$pop_15_44_muni_gendergap_2015 >= range_x[1] & dat$pop_15_44_muni_gendergap_2015 <= range_x[2])
dat_2015_s <- dat_2015[keep15, ]
dat_s <- dat[keepall, ]

bin_fit <- function(formula, id, data) {
  vars <- all.vars(formula)
  du <- na.omit(data[, unique(c(vars, id))])
  fit <- glm(formula, data = du, family = "binomial")
  V <- vcovCL(fit, cluster = du[, id])
  list(fit = fit, vcov = V, n = length(fit$residuals))
}
ctrl3 <- "pop_15_44_muni_gendergap_2015 + log_population_muni_2015 + log_popdens_muni_2015 + log_unemp_all_muni_2015 + d_pop1511_muni + vote_afd_2013_muni + log_ref_inflow_1514 + log_pop_ref_2014 + log_violence_percap_2015 + pc_hidegree_all2011 + d_manuf1115 + pc_manufacturing_2015 + unemp_gendergap_2015"
b3s <- bin_fit(as.formula(paste("Hate_all_muni_1517_bin ~", ctrl3, "+ as.factor(ags_state)")), "ags_county", dat_2015_s)
b3p <- bin_fit(as.formula(paste("Hate_all_muni_bin ~", ctrl3, "+ as.factor(ags_state) + as.factor(year)")), "ags_county", dat_s)
for (nm in c("b3s", "b3p")) {
  b <- get(nm); co <- coef(b$fit)["pop_15_44_muni_gendergap_2015"]; se <- sqrt(diag(b$vcov))["pop_15_44_muni_gendergap_2015"]
  cat(sprintf("TableC1 %s: ExcessMales=%.4f (cluster se %.4f) N=%d\n", nm, co, se, b$n))
}

cat(sprintf("RESULT:mate_competition_table1_col1=%.6f\n", coef(lms[[1]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col2=%.6f\n", coef(lms[[2]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col3=%.6f\n", coef(lms[[3]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col4=%.6f\n", coef(lms[[4]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col5=%.6f\n", coef(lms[[5]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col6=%.6f\n", coef(lms[[6]])["MateComp.cont"]))
cat(sprintf("RESULT:job_competition_table1_col2=%.6f\n", coef(lms[[2]])["JobComp.cont"]))
cat(sprintf("RESULT:n_obs_table1_col1=%d\n", nobs(lms[[1]])))
cat(sprintf("RESULT:n_obs_table1_col3=%d\n", nobs(lms[[3]])))
cat(sprintf("RESULT:excess_males_sum_tableC1_col5=%.6f\n", coef(b3s$fit)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:excess_males_annual_tableC1_col6=%.6f\n", coef(b3p$fit)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:n_obs_sum_tableC1_col5=%d\n", b3s$n))
cat(sprintf("RESULT:n_obs_annual_tableC1_col6=%d\n", b3p$n))
