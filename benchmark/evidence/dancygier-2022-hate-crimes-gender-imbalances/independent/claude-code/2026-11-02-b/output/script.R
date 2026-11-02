suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/independent/2026-11-02-b/mount/dancygier_2022_hate_crimes_gender_imbalances"

## ---------------- Survey: Table 1 ----------------
s <- zap_labels(read_dta(file.path(D, "survey.dta")))
w <- s[s$wave == 4, ]
w$mate <- w$MateComp.cont; w$job <- w$JobComp.cont; w$life <- w$LifeSatis.cont
w$f_gender <- factor(w$gender); w$f_income <- factor(w$income)
w$f_occ <- factor(w$occupation); w$f_rel <- factor(w$religion); w$f_state <- factor(w$state)
socio <- "age + f_gender + eduyrs + f_income + f_occ + citizenship + household_size + self_econ + f_rel + f_state"
nat <- "ref_integrating + ref_citizenship + ref_reduce + ref_moredone + ref_cultgiveup + ref_economy + ref_crime + ref_terror"
loc <- "ref_loc_services + ref_loc_economy + ref_loc_crime + ref_loc_culture + ref_loc_islam + ref_loc_schools + ref_loc_housing + ref_loc_wayoflife"
add <- "contact_ind + distance_ref + settle_ref + afd + afd_ind + lrscale + muslim_ind"
f <- list(
  "hate_violence_means ~ mate",
  "hate_violence_means ~ mate + job + life",
  paste("hate_violence_means ~ mate + job + life +", socio),
  paste("hate_violence_means ~ mate + job + life +", socio, "+", nat),
  paste("hate_violence_means ~ mate + job + life +", socio, "+", nat, "+", loc),
  paste("hate_violence_means ~ mate + job + life +", socio, "+", nat, "+", loc, "+", add))
m <- lapply(f, function(x) lm(as.formula(x), data = w))
for (i in 1:6) cat(sprintf("col%d: mate=%.4f se=%.4f N=%d R2=%.3f\n", i, coef(m[[i]])["mate"],
  sqrt(diag(vcov(m[[i]])))["mate"], nobs(m[[i]]), summary(m[[i]])$r.squared))

## ---------------- Context: Table C1 cols 5-6 ----------------
cx <- zap_labels(read_dta(file.path(D, "context.dta")))
cx$ags_muni <- as.character(cx$ags_muni)
ctrl <- "log_population_muni_2015 + log_popdens_muni_2015 + d_pop1511_muni + log_unemp_all_muni_2015 + unemp_gendergap_2015 + log_pop_ref_2014 + log_ref_inflow_1514 + pc_hidegree_all2011 + pc_manufacturing_2015 + d_manuf1115 + vote_afd_2013_muni + log_violence_percap_2015"
mu <- cx %>% group_by(ags_muni) %>%
  summarise(sum_bin = as.numeric(any(Hate_all_muni_bin == 1)), across(c(ags_county, ags_state, pop_15_44_muni_gendergap_2015,
    log_population_muni_2015, log_popdens_muni_2015, d_pop1511_muni, log_unemp_all_muni_2015, unemp_gendergap_2015,
    log_pop_ref_2014, log_ref_inflow_1514, pc_hidegree_all2011, pc_manufacturing_2015, d_manuf1115,
    vote_afd_2013_muni, log_violence_percap_2015), first), .groups = "drop")
q <- quantile(mu$pop_15_44_muni_gendergap_2015, c(0.025, 0.975), na.rm = TRUE)
cat("cutoffs:", q, "\n")
keep <- function(x) !is.na(x) & x >= q[1] & x <= q[2]
mus <- mu[keep(mu$pop_15_44_muni_gendergap_2015), ]
fs <- as.formula(paste("sum_bin ~ pop_15_44_muni_gendergap_2015 +", ctrl, "+ factor(ags_state)"))
ms <- feglm(fs, data = mus, family = binomial("logit"), cluster = ~ags_county)
print(summary(ms))
cxs <- cx[keep(cx$pop_15_44_muni_gendergap_2015), ]
fa <- as.formula(paste("Hate_all_muni_bin ~ pop_15_44_muni_gendergap_2015 +", ctrl, "+ factor(ags_state) + factor(year)"))
ma <- feglm(fa, data = cxs, family = binomial("logit"), cluster = ~ags_county)
print(summary(ma))

cat(sprintf("RESULT:mate_competition_table1_col1=%.6f\n", coef(m[[1]])["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col2=%.6f\n", coef(m[[2]])["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col3=%.6f\n", coef(m[[3]])["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col4=%.6f\n", coef(m[[4]])["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col5=%.6f\n", coef(m[[5]])["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col6=%.6f\n", coef(m[[6]])["mate"]))
cat(sprintf("RESULT:job_competition_table1_col2=%.6f\n", coef(m[[2]])["job"]))
cat(sprintf("RESULT:n_obs_table1_col1=%d\n", nobs(m[[1]])))
cat(sprintf("RESULT:n_obs_table1_col3=%d\n", nobs(m[[3]])))
cat(sprintf("RESULT:excess_males_sum_tableC1_col5=%.6f\n", coef(ms)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:excess_males_annual_tableC1_col6=%.6f\n", coef(ma)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:n_obs_sum_tableC1_col5=%d\n", nobs(ms)))
cat(sprintf("RESULT:n_obs_annual_tableC1_col6=%d\n", nobs(ma)))
