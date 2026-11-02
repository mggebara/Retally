## Independent reproduction: Dancygier, Egami, Jamal & Rischke (2022, AJPS)
## Table 1 (survey OLS) and SI Table C1 cols (5)-(6) (municipality logit)
suppressPackageStartupMessages({ library(haven); library(dplyr); library(sandwich); library(lmtest) })
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/independent/2026-11-02-c/mount/dancygier_2022_hate_crimes_gender_imbalances"

## ---------------- Survey: Table 1 ----------------
s <- read_dta(file.path(D, "survey.dta"))
s4 <- s %>% filter(wave == 4) %>%
  mutate(gender_f = factor(as.numeric(gender)),
         income_f = factor(as.numeric(income)),
         occ_f = factor(as.numeric(occupation)),
         relig_f = factor(as.numeric(religion)),
         state_f = factor(as.numeric(state)),
         hh = as.numeric(household_size),
         selfecon = ifelse(as.numeric(self_econ) == 11, 0, as.numeric(self_econ)),
         dist_f = factor(as.numeric(distance_ref)),
         settle_f = factor(as.numeric(settle_ref)))

f1 <- hate_violence_means ~ MateComp.cont
f2 <- update(f1, . ~ . + JobComp.cont + LifeSatis.cont)
socio <- "age + gender_f + eduyrs + income_f + occ_f + citizenship + hh + selfecon + relig_f + state_f"
nat <- "ref_integrating + ref_citizenship + ref_reduce + ref_moredone + ref_cultgiveup + ref_economy + ref_crime + ref_terror"
loc <- "ref_loc_services + ref_loc_economy + ref_loc_crime + ref_loc_culture + ref_loc_islam + ref_loc_schools + ref_loc_housing + ref_loc_wayoflife"
addc <- "contact_ind + dist_f + settle_f + afd + afd_ind + lrscale + muslim_ind"
f3 <- as.formula(paste("hate_violence_means ~ MateComp.cont + JobComp.cont + LifeSatis.cont +", socio))
f4 <- as.formula(paste(deparse(f3, width.cutoff = 500), "+", nat))
f5 <- as.formula(paste(deparse(f4, width.cutoff = 500), "+", loc))
f6 <- as.formula(paste(deparse(f5, width.cutoff = 500), "+", addc))
mods <- lapply(list(f1, f2, f3, f4, f5, f6), function(f) lm(f, data = s4))
for (i in seq_along(mods)) {
  m <- mods[[i]]
  cat(sprintf("Col %d: b_mate=%.4f (se %.4f) b_job=%s N=%d R2=%.3f adjR2=%.3f\n", i,
              coef(m)["MateComp.cont"], sqrt(vcov(m)["MateComp.cont","MateComp.cont"]),
              ifelse("JobComp.cont" %in% names(coef(m)), sprintf("%.4f", coef(m)["JobComp.cont"]), "-"),
              nobs(m), summary(m)$r.squared, summary(m)$adj.r.squared))
}

## ---------------- Context: SI Table C1 ----------------
cx <- read_dta(file.path(D, "context.dta")) %>% mutate(ags_muni = as.numeric(ags_muni))
## Exclude extreme Excess Males (top/bottom 2.5 percentiles across municipalities)
em <- cx %>% filter(year == 2015) %>% pull(pop_15_44_muni_gendergap_2015)
q <- quantile(em, c(0.025, 0.975), na.rm = TRUE)
cat("Excess males cutoffs:", q, "\n")
cx <- cx %>% filter(!is.na(pop_15_44_muni_gendergap_2015),
                    pop_15_44_muni_gendergap_2015 >= q[1], pop_15_44_muni_gendergap_2015 <= q[2])

ctrl <- c("log_population_muni_2015", "log_popdens_muni_2015", "d_pop1511_muni",
          "log_unemp_all_muni_2015", "unemp_gendergap_2015", "log_pop_ref_2014",
          "log_ref_inflow_1514", "pc_hidegree_all2011", "pc_manufacturing_2015",
          "d_manuf1115", "vote_afd_2013_muni", "log_violence_percap_2015")

## Sum model: one row per municipality, outcome = any hate crime 2015-2017
sumd <- cx %>% group_by(ags_muni) %>%
  summarise(hate_any = as.numeric(sum(Hate_all_muni, na.rm = TRUE) > 0),
            across(all_of(c("ags_county", "ags_state", "pop_15_44_muni_gendergap_2015", ctrl)), ~ first(.x)),
            .groups = "drop")
fs <- as.formula(paste("hate_any ~ pop_15_44_muni_gendergap_2015 +", paste(ctrl, collapse = " + "), "+ factor(ags_state)"))
sumd_cc <- sumd[complete.cases(sumd[, c("hate_any", "pop_15_44_muni_gendergap_2015", ctrl, "ags_state")]), ]
m_sum <- glm(fs, data = sumd_cc, family = binomial())
vc_sum <- vcovCL(m_sum, cluster = ~ ags_county)
cat("Sum model:\n"); print(coeftest(m_sum, vcov. = vc_sum)[2, ])
cat("Sum N:", nobs(m_sum), "\n")

## Annual model: municipality-years, state and year FE
fa <- as.formula(paste("Hate_all_muni_bin ~ pop_15_44_muni_gendergap_2015 +", paste(ctrl, collapse = " + "), "+ factor(ags_state) + factor(year)"))
ann_cc <- cx[complete.cases(cx[, c("Hate_all_muni_bin", "pop_15_44_muni_gendergap_2015", ctrl, "ags_state", "year")]), ]
m_ann <- glm(fa, data = ann_cc, family = binomial())
vc_ann <- vcovCL(m_ann, cluster = ~ ags_county)
cat("Annual model:\n"); print(coeftest(m_ann, vcov. = vc_ann)[2, ])
cat("Annual N:", nobs(m_ann), "\n")

## ---------------- Results ----------------
cat(sprintf("RESULT:mate_competition_table1_col1=%.6f\n", coef(mods[[1]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col2=%.6f\n", coef(mods[[2]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col3=%.6f\n", coef(mods[[3]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col4=%.6f\n", coef(mods[[4]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col5=%.6f\n", coef(mods[[5]])["MateComp.cont"]))
cat(sprintf("RESULT:mate_competition_table1_col6=%.6f\n", coef(mods[[6]])["MateComp.cont"]))
cat(sprintf("RESULT:job_competition_table1_col2=%.6f\n", coef(mods[[2]])["JobComp.cont"]))
cat(sprintf("RESULT:n_obs_table1_col1=%d\n", nobs(mods[[1]])))
cat(sprintf("RESULT:n_obs_table1_col3=%d\n", nobs(mods[[3]])))
cat(sprintf("RESULT:excess_males_sum_tableC1_col5=%.6f\n", coef(m_sum)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:excess_males_annual_tableC1_col6=%.6f\n", coef(m_ann)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:n_obs_sum_tableC1_col5=%d\n", nobs(m_sum)))
cat(sprintf("RESULT:n_obs_annual_tableC1_col6=%d\n", nobs(m_ann)))
