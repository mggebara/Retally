# Independent, blind reproduction: Dancygier et al. (2022), Table 1 and SI Table C1 cols (5)-(6)
set.seed(42)
suppressMessages({library(haven); library(fixest); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/blind/2026-11-02-b/mount/dancygier_2022_hate_crimes_gender_imbalances"

## ---------------- Survey: Table 1 ----------------
s <- read_dta(file.path(D, "survey.dta"))
s <- zap_labels(s)
w4 <- s %>% filter(wave == 4) %>% as.data.frame()
cat("Wave 4 rows:", nrow(w4), "\n")

# recodes
w4$self_status <- ifelse(w4$self_econ == 11, 0, w4$self_econ)   # code 11 = "0 (BOTTOM)"
w4$hh_size     <- w4$household_size - 1                           # code 2 = "1 person"
w4$f_gender  <- factor(w4$gender)
w4$f_income  <- factor(w4$income)        # includes "No answer" category
w4$f_occ     <- factor(w4$occupation)    # main economic activity / employment status
w4$f_relig   <- factor(w4$religion)
w4$f_state   <- factor(w4$state)
w4$f_dist    <- factor(w4$distance_ref)  # incl. "Don't know"
w4$f_settle  <- factor(w4$settle_ref)

y <- "hate_violence_means"
base1 <- "MateComp.cont"
base2 <- c("MateComp.cont", "JobComp.cont", "LifeSatis.cont")
socio <- c("age", "f_gender", "eduyrs", "f_income", "f_occ", "citizenship", "hh_size",
           "self_status", "f_relig", "f_state")
nat   <- c("ref_integrating", "ref_citizenship", "ref_reduce", "ref_moredone",
           "ref_cultgiveup", "ref_economy", "ref_crime", "ref_terror")
loc   <- c("ref_loc_services", "ref_loc_economy", "ref_loc_crime", "ref_loc_culture",
           "ref_loc_islam", "ref_loc_schools", "ref_loc_housing", "ref_loc_wayoflife")
addl  <- c("contact_ind", "f_dist", "f_settle", "afd", "afd_ind", "lrscale", "muslim_ind")

specs <- list(base1, base2, c(base2, socio), c(base2, socio, nat),
              c(base2, socio, nat, loc), c(base2, socio, nat, loc, addl))
fits <- lapply(specs, function(x) lm(reformulate(x, y), data = w4))
for (i in seq_along(fits)) {
  sm <- summary(fits[[i]])
  cat(sprintf("Col %d: mate=%.4f (se %.4f) job=%s N=%d R2=%.3f adjR2=%.3f\n", i,
              coef(fits[[i]])["MateComp.cont"], sm$coefficients["MateComp.cont", 2],
              ifelse("JobComp.cont" %in% names(coef(fits[[i]])),
                     sprintf("%.4f", coef(fits[[i]])["JobComp.cont"]), "NA"),
              nobs(fits[[i]]), sm$r.squared, sm$adj.r.squared))
}

## ---------------- Context: SI Table C1 cols (5) Sum, (6) Annual ----------------
cx <- zap_labels(read_dta(file.path(D, "context.dta"))) %>% as.data.frame()
cx$ags_muni <- as.numeric(cx$ags_muni)
ctrl <- c("log_population_muni_2015", "log_popdens_muni_2015", "d_pop1511_muni",
          "log_unemp_all_muni_2015", "unemp_gendergap_2015", "log_pop_ref_2014",
          "log_ref_inflow_1514", "pc_hidegree_all2011", "pc_manufacturing_2015",
          "d_manuf1115", "vote_afd_2013_muni", "log_violence_percap_2015")

# Excess Males trimming: top/bottom 2.5 percentiles across municipalities
muni <- cx %>% filter(year == 2015)
q <- quantile(muni$pop_15_44_muni_gendergap_2015, c(0.025, 0.975), na.rm = TRUE)
cat("Excess Males trimming bounds:", q, "\n")
keep <- function(v) !is.na(v) & v >= q[1] & v <= q[2]

# Sum model: one row per municipality, outcome = any hate crime 2015-2017
sum_df <- cx %>% group_by(ags_muni) %>%
  summarise(hate_sum = sum(Hate_all_muni), across(all_of(c("pop_15_44_muni_gendergap_2015", ctrl, "ags_county", "ags_state")), first), .groups = "drop") %>%
  mutate(hate_any = as.numeric(hate_sum > 0)) %>% as.data.frame()
sum_df <- sum_df[keep(sum_df$pop_15_44_muni_gendergap_2015), ]
fml_sum <- as.formula(paste("hate_any ~ pop_15_44_muni_gendergap_2015 +", paste(ctrl, collapse = " + "), "| ags_state"))
m5 <- feglm(fml_sum, data = sum_df, family = binomial("logit"), cluster = ~ags_county)
print(summary(m5))

ann_df <- cx[keep(cx$pop_15_44_muni_gendergap_2015), ]
fml_ann <- as.formula(paste("Hate_all_muni_bin ~ pop_15_44_muni_gendergap_2015 +", paste(ctrl, collapse = " + "), "| ags_state + year"))
m6 <- feglm(fml_ann, data = ann_df, family = binomial("logit"), cluster = ~ags_county)
print(summary(m6))

# cross-check with glm + state dummies (fixest may drop perfectly-predicted FE groups)
g5 <- glm(update(as.formula(paste("hate_any ~ pop_15_44_muni_gendergap_2015 +", paste(ctrl, collapse = " + "))), . ~ . + factor(ags_state)),
          data = sum_df, family = binomial("logit"))
cat("glm check col5: coef", coef(g5)[2], " N", nobs(g5), "\n")

## ---------------- Results ----------------
cat(sprintf("RESULT:mate_competition_table1_col%d=%.6f\n", 1:6, sapply(fits, function(f) coef(f)["MateComp.cont"])), sep = "")
cat(sprintf("RESULT:job_competition_table1_col2=%.6f\n", coef(fits[[2]])["JobComp.cont"]))
cat(sprintf("RESULT:n_obs_table1_col1=%d\n", nobs(fits[[2]])))
cat(sprintf("RESULT:n_obs_table1_col3=%d\n", nobs(fits[[3]])))
cat(sprintf("RESULT:excess_males_sum_tableC1_col5=%.6f\n", coef(m5)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:excess_males_annual_tableC1_col6=%.6f\n", coef(m6)["pop_15_44_muni_gendergap_2015"]))
cat(sprintf("RESULT:n_obs_sum_tableC1_col5=%d\n", nobs(m5)))
cat(sprintf("RESULT:n_obs_annual_tableC1_col6=%d\n", nobs(m6)))
