# Independent reproduction: Dancygier, Egami, Jamal & Rischke (2022, AJPS)
# Table 1 (survey OLS) and SI Table C1 cols 5-6 (municipality logit), built from the paper text.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/independent/2026-11-07-a/mount/dancygier_2022_hate_crimes_gender_imbalances"

## ---------------- Survey: Table 1 ----------------
s <- read_dta(file.path(D, "survey.dta"))
w4 <- s %>% filter(wave == 4) %>% zap_labels()
# self_econ: codes 1..10 are the scale values, code 11 is the "0 (BOTTOM)" box -> recode to 0
w4$self_econ <- ifelse(w4$self_econ == 11, 0, w4$self_econ)
w4 <- w4 %>% mutate(
  gender_f = factor(gender), income_f = factor(income), occ_f = factor(occupation),
  relig_f = factor(religion), state_f = factor(state), dist_f = factor(distance_ref),
  settle_f = factor(settle_ref))

y <- "hate_violence_means"
base1 <- "MateComp.cont"
base2 <- c("MateComp.cont", "JobComp.cont", "LifeSatis.cont")
socio <- c("age", "gender_f", "eduyrs", "income_f", "occ_f", "citizenship",
           "household_size", "self_econ", "relig_f", "state_f")
nat <- c("ref_integrating", "ref_citizenship", "ref_reduce", "ref_moredone",
         "ref_cultgiveup", "ref_economy", "ref_crime", "ref_terror")
loc <- c("ref_loc_services", "ref_loc_economy", "ref_loc_crime", "ref_loc_culture",
         "ref_loc_islam", "ref_loc_schools", "ref_loc_housing", "ref_loc_wayoflife")
addl <- c("contact_ind", "dist_f", "settle_f", "afd", "afd_ind", "lrscale", "muslim_ind")

specs <- list(base1, base2, c(base2, socio), c(base2, socio, nat),
              c(base2, socio, nat, loc), c(base2, socio, nat, loc, addl))
fits <- lapply(specs, function(x) lm(reformulate(x, y), data = w4))
for (i in seq_along(fits)) {
  f <- fits[[i]]; sm <- summary(f)
  cat(sprintf("Col %d: Mate=%.4f (se %.4f)  N=%d  R2=%.3f adjR2=%.3f\n", i,
              coef(f)["MateComp.cont"], sm$coefficients["MateComp.cont", 2],
              nobs(f), sm$r.squared, sm$adj.r.squared))
  if (i >= 2) cat(sprintf("        Job=%.4f Life=%.4f\n", coef(f)["JobComp.cont"], coef(f)["LifeSatis.cont"]))
}

## ---------------- Context: SI Table C1 cols 5-6 ----------------
cx <- read_dta(file.path(D, "context.dta")) %>% zap_labels()
cx$ags_muni <- as.numeric(cx$ags_muni)
# Excess Males is time-invariant (2015); trim top/bottom 2.5 percentiles across municipalities
m15 <- cx %>% filter(year == 2015)
q <- quantile(m15$pop_15_44_muni_gendergap_2015, c(0.025, 0.975), na.rm = TRUE)
cat("Trim bounds:", q, "\n")
keep_ids <- m15$ags_muni[!is.na(m15$pop_15_44_muni_gendergap_2015) &
                         m15$pop_15_44_muni_gendergap_2015 >= q[1] &
                         m15$pop_15_44_muni_gendergap_2015 <= q[2]]
ctrls <- c("log_population_muni_2015", "log_popdens_muni_2015", "d_pop1511_muni",
           "log_unemp_all_muni_2015", "unemp_gendergap_2015", "log_pop_ref_2014",
           "log_ref_inflow_1514", "pc_hidegree_all2011", "pc_manufacturing_2015",
           "d_manuf1115", "vote_afd_2013_muni", "log_violence_percap_2015")
rhs <- paste(c("pop_15_44_muni_gendergap_2015", ctrls), collapse = " + ")

# Sum model: any hate crime over 2015-2017, municipality cross-section, state FE
sumd <- cx %>% group_by(ags_muni) %>%
  summarise(hate_sum = sum(Hate_all_muni, na.rm = TRUE),
            across(all_of(c("ags_county", "ags_state", "pop_15_44_muni_gendergap_2015", ctrls)), first),
            .groups = "drop") %>%
  mutate(hate_sum_bin = as.numeric(hate_sum > 0)) %>%
  filter(ags_muni %in% keep_ids)
f_sum <- feglm(as.formula(paste("hate_sum_bin ~", rhs, "| ags_state")), data = sumd,
               family = binomial("logit"), cluster = ~ags_county)
print(summary(f_sum))

# Annual model: municipality-years, state + year FE
ann <- cx %>% filter(ags_muni %in% keep_ids)
f_ann <- feglm(as.formula(paste("Hate_all_muni_bin ~", rhs, "| ags_state + year")), data = ann,
               family = binomial("logit"), cluster = ~ags_county)
print(summary(f_ann))

cat(sprintf("RESULT:mate_competition_table1_col1=%.6f\n", coef(fits[[1]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col2=%.6f\n", coef(fits[[2]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col3=%.6f\n", coef(fits[[3]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col4=%.6f\n", coef(fits[[4]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col5=%.6f\n", coef(fits[[5]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col6=%.6f\n", coef(fits[[6]])["MateComp.cont"]))
cat(sprintf("RESULT:job_competition_table1_col2=%.6f\n", coef(fits[[2]])["JobComp.cont"]))
cat(sprintf("RESULT:n_obs_table1_col1=%d\n", nobs(fits[[1]])))
cat(sprintf("RESULT:n_obs_table1_col3=%d\n", nobs(fits[[3]])))
cat(sprintf("RESULT:excess_males_sum_tableC1_col5=%.6f\n", coef(f_sum)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:excess_males_annual_tableC1_col6=%.6f\n", coef(f_ann)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:n_obs_sum_tableC1_col5=%d\n", nobs(f_sum)))
cat(sprintf("RESULT:n_obs_annual_tableC1_col6=%d\n", nobs(f_ann)))
