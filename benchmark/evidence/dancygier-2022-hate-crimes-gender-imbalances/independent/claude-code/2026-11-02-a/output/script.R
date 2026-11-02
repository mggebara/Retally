suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/independent/2026-11-02-a/mount/dancygier_2022_hate_crimes_gender_imbalances"

## ---------------- Table 1: survey, Wave 4 ----------------
sv <- read_dta(file.path(D, "survey.dta"))
w4 <- sv %>% filter(wave == 4)
w4 <- w4 %>% mutate(
  gender_f = factor(as.numeric(gender)),
  income_f = factor(as.numeric(income)),
  occ_f = factor(as.numeric(occupation)),
  rel_f = factor(as.numeric(religion)),
  state_f = factor(as.numeric(state)),
  hh = as.numeric(household_size),
  selfecon = as.numeric(self_econ),
  dist_f = factor(as.numeric(distance_ref)),
  settle_f = factor(as.numeric(settle_ref))
)
cat("self_econ codes:\n"); print(table(as.numeric(w4$self_econ)))
cat("household codes:\n"); print(table(as.numeric(w4$household_size)))

f1 <- hate_violence_means ~ MateComp.cont
f2 <- update(f1, . ~ . + JobComp.cont + LifeSatis.cont)
socio <- "age + gender_f + eduyrs + income_f + occ_f + citizenship + hh + selfecon + rel_f + state_f"
nat <- "ref_integrating + ref_citizenship + ref_reduce + ref_moredone + ref_cultgiveup + ref_economy + ref_crime + ref_terror"
loc <- "ref_loc_services + ref_loc_economy + ref_loc_crime + ref_loc_culture + ref_loc_islam + ref_loc_schools + ref_loc_housing + ref_loc_wayoflife"
addc <- "contact_ind + dist_f + settle_f + afd + afd_ind + lrscale + muslim_ind"
base2 <- "hate_violence_means ~ MateComp.cont + JobComp.cont + LifeSatis.cont"
f3 <- as.formula(paste(base2, socio, sep = " + "))
f4 <- as.formula(paste(base2, socio, nat, sep = " + "))
f5 <- as.formula(paste(base2, socio, nat, loc, sep = " + "))
f6 <- as.formula(paste(base2, socio, nat, loc, addc, sep = " + "))
ms <- lapply(list(f1, f2, f3, f4, f5, f6), function(f) lm(f, data = w4))
for (i in 1:6) cat(sprintf("col%d: mate=%.4f se=%.4f n=%d r2=%.3f\n", i, coef(ms[[i]])["MateComp.cont"],
  sqrt(diag(vcov(ms[[i]])))["MateComp.cont"], nobs(ms[[i]]), summary(ms[[i]])$r.squared))

## ---------------- SI Table C1: context ----------------
cx <- read_dta(file.path(D, "context.dta")) %>% mutate(ags_muni = as.numeric(ags_muni))
ctrl <- c("log_population_muni_2015", "log_popdens_muni_2015", "d_pop1511_muni", "log_unemp_all_muni_2015",
          "unemp_gendergap_2015", "log_pop_ref_2014", "log_ref_inflow_1514", "pc_hidegree_all2011",
          "pc_manufacturing_2015", "d_manuf1115", "vote_afd_2013_muni", "log_violence_percap_2015")
muni <- cx %>% filter(year == 2015)
q <- quantile(muni$pop_15_44_muni_gendergap_2015, c(0.025, 0.975), na.rm = TRUE)
cat("trim bounds:", q, "\n")
keep_ids <- muni$ags_muni[!is.na(muni$pop_15_44_muni_gendergap_2015) &
  muni$pop_15_44_muni_gendergap_2015 >= q[1] & muni$pop_15_44_muni_gendergap_2015 <= q[2]]
sumd <- cx %>% group_by(ags_muni) %>% summarise(hate_sum_bin = as.numeric(sum(Hate_all_muni) > 0), .groups = "drop") %>%
  left_join(muni %>% dplyr::select(-year, -Hate_all_muni, -Hate_all_muni_bin), by = "ags_muni") %>%
  filter(ags_muni %in% keep_ids)
fsum <- as.formula(paste("hate_sum_bin ~ pop_15_44_muni_gendergap_2015 +", paste(ctrl, collapse = " + "), "| ags_state"))
msum <- feglm(fsum, data = sumd, family = binomial("logit"), cluster = ~ags_county)
print(summary(msum))
ann <- cx %>% filter(ags_muni %in% keep_ids)
fann <- as.formula(paste("Hate_all_muni_bin ~ pop_15_44_muni_gendergap_2015 +", paste(ctrl, collapse = " + "), "| ags_state + year"))
mann <- feglm(fann, data = ann, family = binomial("logit"), cluster = ~ags_county)
print(summary(mann))

cat(sprintf("RESULT:mate_competition_table1_col%d=%.6f\n", 1:6, sapply(ms, function(m) coef(m)["MateComp.cont"])), sep = "")
cat(sprintf("RESULT:job_competition_table1_col2=%.6f\n", coef(ms[[2]])["JobComp.cont"]))
cat(sprintf("RESULT:n_obs_table1_col1=%d\n", nobs(ms[[1]])))
cat(sprintf("RESULT:n_obs_table1_col3=%d\n", nobs(ms[[3]])))
cat(sprintf("RESULT:excess_males_sum_tableC1_col5=%.6f\n", coef(msum)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:excess_males_annual_tableC1_col6=%.6f\n", coef(mann)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:n_obs_sum_tableC1_col5=%d\n", nobs(msum)))
cat(sprintf("RESULT:n_obs_annual_tableC1_col6=%d\n", nobs(mann)))
