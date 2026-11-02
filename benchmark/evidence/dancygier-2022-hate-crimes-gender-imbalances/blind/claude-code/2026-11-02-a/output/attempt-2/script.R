# Retally independent/blind reproduction: Dancygier, Egami, Jamal & Rischke (2022, AJPS)
# Table 1 (survey, Wave 4 OLS) and SI Table C1 cols (5)-(6) (municipality logit).
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/blind/2026-11-02-a/mount/dancygier_2022_hate_crimes_gender_imbalances"

# ---------------------------------------------------------------- Table 1
s <- read_dta(file.path(D, "survey.dta"))
w <- zap_labels(s[s$wave == 4, ])
w <- as.data.frame(w)
# sociodemographics
w$female        <- as.numeric(w$gender == 2)
w$income_f      <- factor(w$income)          # 12 = "No answer" kept as its own category
w$occupation_f  <- factor(w$occupation)      # main economic activity / employment status
w$religion_f    <- factor(w$religion)
w$state_f       <- factor(w$state)
w$hhsize        <- w$household_size - 1      # code k corresponds to (k-1) persons
w$selfecon      <- ifelse(w$self_econ == 11, 0, w$self_econ)  # 11 = "0 (bottom)"
# additional controls
w$distance_f    <- factor(w$distance_ref)    # includes "don't know"
w$settle_f      <- factor(w$settle_ref)

nat <- c("ref_integrating","ref_citizenship","ref_reduce","ref_moredone",
         "ref_cultgiveup","ref_economy","ref_crime","ref_terror")
loc <- c("ref_loc_services","ref_loc_economy","ref_loc_crime","ref_loc_culture",
         "ref_loc_islam","ref_loc_schools","ref_loc_housing","ref_loc_wayoflife")
socio <- c("age","female","eduyrs","income_f","occupation_f","citizenship","hhsize",
           "selfecon","religion_f","state_f")
addl <- c("contact_ind","distance_f","settle_f","afd_ind","afd","lrscale","muslim_ind")

f1 <- c("MateComp.cont")
f2 <- c(f1, "JobComp.cont", "LifeSatis.cont")
f3 <- c(f2, socio)
f4 <- c(f3, nat)
f5 <- c(f4, loc)
f6 <- c(f5, addl)
specs <- list(f1, f2, f3, f4, f5, f6)
fit <- lapply(specs, function(x) lm(reformulate(sprintf("`%s`", x), "hate_violence_means"), data = w))
for (i in seq_along(fit)) {
  cf <- coef(summary(fit[[i]]))
  cat(sprintf("col%d: MateComp=%.5f (se %.5f)  N=%d  R2=%.3f\n", i, cf["`MateComp.cont`",1], cf["`MateComp.cont`",2],
              nobs(fit[[i]]), summary(fit[[i]])$r.squared))
}
mc <- sapply(fit, function(m) coef(m)["`MateComp.cont`"])
jc2 <- coef(fit[[2]])["`JobComp.cont`"]

# ---------------------------------------------------------------- SI Table C1
cx <- as.data.frame(zap_labels(read_dta(file.path(D, "context.dta"))))
ctrl <- c("log_population_muni_2015","log_popdens_muni_2015","d_pop1511_muni",
          "log_unemp_all_muni_2015","unemp_gendergap_2015","log_pop_ref_2014",
          "log_ref_inflow_1514","pc_hidegree_all2011","pc_manufacturing_2015",
          "d_manuf1115","vote_afd_2013_muni","log_violence_percap_2015")
# trimming: drop municipalities in the top/bottom 2.5 percentiles of Excess Males (15-44)
mu <- cx[cx$year == 2015, ]
q <- quantile(mu$pop_15_44_muni_gendergap_2015, c(0.025, 0.975), na.rm = TRUE)
cat(sprintf("trim bounds: %.4f %.4f\n", q[1], q[2]))
keep <- with(cx, !is.na(pop_15_44_muni_gendergap_2015) &
               pop_15_44_muni_gendergap_2015 >= q[1] & pop_15_44_muni_gendergap_2015 <= q[2])
cx <- cx[keep, ]

# Sum model: any hate crime 2015-2017, one row per municipality
sm <- cx %>% group_by(ags_muni) %>%
  mutate(hate_sum_bin = as.numeric(sum(Hate_all_muni) > 0)) %>% ungroup() %>%
  filter(year == 2015) %>% as.data.frame()
fml <- as.formula(paste("hate_sum_bin ~ pop_15_44_muni_gendergap_2015 +", paste(ctrl, collapse = " + "), "| ags_state"))
m5 <- feglm(fml, data = sm, family = binomial("logit"), cluster = ~ags_county)
print(summary(m5))

fml6 <- as.formula(paste("Hate_all_muni_bin ~ pop_15_44_muni_gendergap_2015 +", paste(ctrl, collapse = " + "), "| ags_state + year"))
m6 <- feglm(fml6, data = cx, family = binomial("logit"), cluster = ~ags_county)
print(summary(m6))

cat(sprintf("RESULT:mate_competition_table1_col1=%.6f\n", mc[1]))
cat(sprintf("RESULT:mate_competition_table1_col2=%.6f\n", mc[2]))
cat(sprintf("RESULT:mate_competition_table1_col3=%.6f\n", mc[3]))
cat(sprintf("RESULT:mate_competition_table1_col4=%.6f\n", mc[4]))
cat(sprintf("RESULT:mate_competition_table1_col5=%.6f\n", mc[5]))
cat(sprintf("RESULT:mate_competition_table1_col6=%.6f\n", mc[6]))
cat(sprintf("RESULT:job_competition_table1_col2=%.6f\n", jc2))
cat(sprintf("RESULT:n_obs_table1_col1=%d\n", nobs(fit[[1]])))
cat(sprintf("RESULT:n_obs_table1_col3=%d\n", nobs(fit[[3]])))
cat(sprintf("RESULT:excess_males_sum_tableC1_col5=%.6f\n", coef(m5)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:excess_males_annual_tableC1_col6=%.6f\n", coef(m6)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:n_obs_sum_tableC1_col5=%d\n", nobs(m5)))
cat(sprintf("RESULT:n_obs_annual_tableC1_col6=%d\n", nobs(m6)))
