# Independent, blind reproduction of Dancygier, Egami, Jamal & Rischke (2022, AJPS)
# Table 1 (survey OLS) and SI Table C1 cols (5)-(6) (municipality logit), built
# from the paper's description only.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest); library(readr)})

D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/blind/2026-11-07-a/mount/dancygier_2022_hate_crimes_gender_imbalances"

# ------------------------------------------------------------------ Survey (Table 1)
s <- read_dta(file.path(D, "survey.dta"))
s <- s[as.numeric(s$wave) == 4, ]
lab_num <- function(x) readr::parse_number(as.character(as_factor(x)))
w4 <- data.frame(
  only_means = as.numeric(s$hate_violence_means),
  mate = as.numeric(s$MateComp.cont),
  job = as.numeric(s$JobComp.cont),
  lifesat = as.numeric(s$LifeSatis.cont),
  age = as.numeric(s$age),
  gender = factor(as_factor(s$gender)),
  eduyrs = as.numeric(s$eduyrs),
  income = factor(as_factor(s$income)),          # 11 brackets + "No answer" kept as a category
  occupation = factor(as_factor(s$occupation)),  # main economic activity / employment status
  citizenship = as.numeric(s$citizenship),
  hhsize = lab_num(s$household_size),
  self_econ = lab_num(s$self_econ),              # 0 (bottom) - 10 (top)
  religion = factor(as_factor(s$religion)),
  state = factor(as_factor(s$state)),
  # national attitudes toward refugees
  ref_integrating = as.numeric(s$ref_integrating), ref_citizenship = as.numeric(s$ref_citizenship),
  ref_reduce = as.numeric(s$ref_reduce), ref_moredone = as.numeric(s$ref_moredone),
  ref_cultgiveup = as.numeric(s$ref_cultgiveup), ref_economy = as.numeric(s$ref_economy),
  ref_crime = as.numeric(s$ref_crime), ref_terror = as.numeric(s$ref_terror),
  # local attitudes toward refugees
  ref_loc_services = as.numeric(s$ref_loc_services), ref_loc_economy = as.numeric(s$ref_loc_economy),
  ref_loc_crime = as.numeric(s$ref_loc_crime), ref_loc_culture = as.numeric(s$ref_loc_culture),
  ref_loc_islam = as.numeric(s$ref_loc_islam), ref_loc_schools = as.numeric(s$ref_loc_schools),
  ref_loc_housing = as.numeric(s$ref_loc_housing), ref_loc_wayoflife = as.numeric(s$ref_loc_wayoflife),
  # additional controls
  contact_ind = as.numeric(s$contact_ind),
  distance_ref = factor(as_factor(s$distance_ref)),
  settle_ref = factor(as_factor(s$settle_ref)),
  afd = as.numeric(s$afd), afd_ind = as.numeric(s$afd_ind),
  lrscale = as.numeric(s$lrscale), muslim_ind = as.numeric(s$muslim_ind)
)

socio <- "age + gender + eduyrs + income + occupation + citizenship + hhsize + self_econ + religion + state"
nat <- "ref_integrating + ref_citizenship + ref_reduce + ref_moredone + ref_cultgiveup + ref_economy + ref_crime + ref_terror"
loc <- "ref_loc_services + ref_loc_economy + ref_loc_crime + ref_loc_culture + ref_loc_islam + ref_loc_schools + ref_loc_housing + ref_loc_wayoflife"
add <- "contact_ind + distance_ref + settle_ref + afd + afd_ind + lrscale + muslim_ind"
rhs <- list(
  "mate",
  "mate + job + lifesat",
  paste("mate + job + lifesat", socio, sep = " + "),
  paste("mate + job + lifesat", socio, nat, sep = " + "),
  paste("mate + job + lifesat", socio, nat, loc, sep = " + "),
  paste("mate + job + lifesat", socio, nat, loc, add, sep = " + ")
)
# columns (1)-(2) share a sample; columns (3)-(6) share a sample (complete on all controls)
allv <- all.vars(as.formula(paste("only_means ~", rhs[[6]])))
s12 <- w4[complete.cases(w4[, c("only_means", "mate", "job", "lifesat")]), ]
s36 <- w4[complete.cases(w4[, allv]), ]
fits <- lapply(1:6, function(k) lm(as.formula(paste("only_means ~", rhs[[k]])),
                                     data = if (k <= 2) s12 else s36))
for (k in 1:6) {
  cf <- summary(fits[[k]])$coefficients
  cat(sprintf("Table1 col%d: mate=%.4f (se %.4f) N=%d R2=%.3f\n", k, cf["mate", 1], cf["mate", 2],
              nobs(fits[[k]]), summary(fits[[k]])$r.squared))
}

# ------------------------------------------------------------------ Context (SI Table C1)
cx <- read_dta(file.path(D, "context.dta"))
cx <- cx %>% mutate(ags_muni = as.numeric(ags_muni))
ctrl <- c("log_population_muni_2015", "log_popdens_muni_2015", "d_pop1511_muni",
          "log_unemp_all_muni_2015", "unemp_gendergap_2015", "log_pop_ref_2014",
          "log_ref_inflow_1514", "pc_hidegree_all2011", "pc_manufacturing_2015",
          "d_manuf1115", "vote_afd_2013_muni", "log_violence_percap_2015")
# municipality-level cross-section (time-invariant covariates, 2015 values)
muni <- cx %>% group_by(ags_muni) %>%
  summarise(hate_sum = as.numeric(max(Hate_all_muni_bin, na.rm = TRUE) > 0),
            across(all_of(c("ags_county", "ags_state", "pop_15_44_muni_gendergap_2015", ctrl)), first),
            .groups = "drop")
em <- muni$pop_15_44_muni_gendergap_2015
q <- quantile(em, c(0.025, 0.975), na.rm = TRUE)
keep_ids <- muni$ags_muni[!is.na(em) & em >= q[1] & em <= q[2]]
cat(sprintf("Excess males trimming bounds: [%.4f, %.4f]; kept %d of %d municipalities\n",
            q[1], q[2], length(keep_ids), sum(!is.na(em))))

fml_rhs <- paste(c("pop_15_44_muni_gendergap_2015", ctrl), collapse = " + ")
msum <- muni %>% filter(ags_muni %in% keep_ids)
msum <- msum[complete.cases(msum[, c("hate_sum", "pop_15_44_muni_gendergap_2015", ctrl)]), ]
f_sum <- feglm(as.formula(paste("hate_sum ~", fml_rhs, "| ags_state")), data = msum,
               family = binomial("logit"), cluster = ~ags_county)
print(summary(f_sum))

pan <- cx %>% filter(ags_muni %in% keep_ids)
pan <- pan[complete.cases(pan[, c("Hate_all_muni_bin", "pop_15_44_muni_gendergap_2015", ctrl)]), ]
f_ann <- feglm(as.formula(paste("Hate_all_muni_bin ~", fml_rhs, "| ags_state + year")), data = pan,
               family = binomial("logit"), cluster = ~ags_county)
print(summary(f_ann))

# ------------------------------------------------------------------ Results
cat(sprintf("RESULT:mate_competition_table1_col1=%.6f\n", coef(fits[[1]])["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col2=%.6f\n", coef(fits[[2]])["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col3=%.6f\n", coef(fits[[3]])["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col4=%.6f\n", coef(fits[[4]])["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col5=%.6f\n", coef(fits[[5]])["mate"]))
cat(sprintf("RESULT:mate_competition_table1_col6=%.6f\n", coef(fits[[6]])["mate"]))
cat(sprintf("RESULT:job_competition_table1_col2=%.6f\n", coef(fits[[2]])["job"]))
cat(sprintf("RESULT:n_obs_table1_col1=%d\n", nobs(fits[[1]])))
cat(sprintf("RESULT:n_obs_table1_col3=%d\n", nobs(fits[[3]])))
cat(sprintf("RESULT:excess_males_sum_tableC1_col5=%.6f\n", coef(f_sum)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:excess_males_annual_tableC1_col6=%.6f\n", coef(f_ann)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:n_obs_sum_tableC1_col5=%d\n", nobs(f_sum)))
cat(sprintf("RESULT:n_obs_annual_tableC1_col6=%d\n", nobs(f_ann)))
