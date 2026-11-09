# Independent reproduction: Bokobza et al. (2022), "The Morning After" (JOP)
# Country-level (Table A1/A2) and individual-level (Table K1/K2) OLS / LPM with FE.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
setFixest_estimation(collin.tol = 1e-14)  # keep lagged population (default tol drops it as near-collinear)
D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-07-a/mount/bokobza_2022_morning_after_coup_purges"

## ---------------- Country level ----------------
c <- zap_labels(read_dta(file.path(D, "morning_after_dataset_countrylevel.dta")))
c <- c %>% arrange(COUNTRY_ID, YEAR_DATA) %>% group_by(COUNTRY_ID) %>%
  mutate(cons = lag(YEAR_DATA) == YEAR_DATA - 1,
         ldem = ifelse(cons, lag(democracy1), NA),          # lagged BMR democracy
         lgdp = ifelse(cons, lag(gdp_cap_pwt_ln), NA),
         lpop = ifelse(cons, lag(pop_pwt_ln), NA),
         lmon = ifelse(cons, lag(monarchy_c), NA),
         lmil = ifelse(cons, lag(military_c), NA),
         lpar = ifelse(cons, lag(party_c), NA)) %>% ungroup()
# coupattempt_whogov is used as delivered (the WhoGov July-to-July aligned failed coup indicator)
cs <- c %>% filter(ldem == 0, YEAR_DATA >= 1967, YEAR_DATA <= 2016,
                   !is.na(replacement_rateadj_minister), !is.na(coupattempt_whogov))
cs$fca <- cs$coupattempt_whogov

fs <- list()
fs$base_c <- feols(replacement_rateadj_minister ~ fca + lgdp + lpop | COUNTRY_ID + YEAR_DATA,
                   data = cs, cluster = ~COUNTRY_ID, fixef.rm = "singleton")
fs$main_c <- feols(replacement_rateadj_minister ~ fca + lgdp + lpop + lmon + lmil + lpar | COUNTRY_ID + YEAR_DATA,
                   data = cs, cluster = ~COUNTRY_ID, fixef.rm = "singleton")
# Leader-FE models: panel defined by leader spell (as with xtset on the leader id), so the one-year
# lags (democracy filter and controls) are taken within each leader's tenure; the first year of a
# spell has no lag and drops out.
cl <- c %>% arrange(leader_cab_id, YEAR_DATA) %>% group_by(leader_cab_id) %>%
  mutate(cons = lag(YEAR_DATA) == YEAR_DATA - 1,
         ldem = ifelse(cons, lag(democracy1), NA),
         lgdp = ifelse(cons, lag(gdp_cap_pwt_ln), NA),
         lpop = ifelse(cons, lag(pop_pwt_ln), NA),
         lmon = ifelse(cons, lag(monarchy_c), NA),
         lmil = ifelse(cons, lag(military_c), NA),
         lpar = ifelse(cons, lag(party_c), NA)) %>% ungroup() %>%
  filter(ldem == 0, YEAR_DATA >= 1967, YEAR_DATA <= 2016,
         !is.na(replacement_rateadj_minister), !is.na(coupattempt_whogov)) %>%
  mutate(fca = coupattempt_whogov)
fs$base_l <- feols(replacement_rateadj_minister ~ fca + lgdp + lpop | leader_cab_id + YEAR_DATA,
                   data = cl, cluster = ~COUNTRY_ID, fixef.rm = "singleton")
fs$main_l <- feols(replacement_rateadj_minister ~ fca + lgdp + lpop + lmon + lmil + lpar | leader_cab_id + YEAR_DATA,
                   data = cl, cluster = ~COUNTRY_ID, fixef.rm = "singleton")
for (n in names(fs)) { cat("==", n, " N =", nobs(fs[[n]]), "\n"); print(coeftable(fs[[n]])) }

## ---------------- Individual level ----------------
i <- readRDS(file.path(D, "morning_after_dataset_individuallevel.rds"))
b <- i %>% filter(democracy_lag == 0, year >= 1967, year <= 2016, leader == 0,
                  !is.na(coupattempt_presentyear), !is.na(purged_y1),
                  !is.na(gdp_cap_pwt_ln_lag), !is.na(pop_pwt_ln_lag)) %>%
  mutate(fca = as.integer(coupattempt_presentyear == "Coup attempt"),
         e1 = experience, e2 = experience^2, e3 = experience^3)

# H2a: experience groups (ref: <2 years), no polynomials
dE <- b %>% filter(!is.na(importance_numeric)) %>%
  mutate(eg = relevel(factor(experience_group), ref = "1year"))
mE <- feols(purged_y1 ~ fca * eg + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
            data = dE, cluster = ~country_isocode)
# H2b: affiliation (ref: other party), cubic in experience
dA <- b %>% filter(!is.na(party_group), party_group != "unknown") %>%
  mutate(pg = relevel(factor(party_group), ref = "other_party"))
mA <- feols(purged_y1 ~ fca * pg + e1 + e2 + e3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
            data = dA, cluster = ~country_isocode)
# H3a: portfolio (ref: defense)
dR <- b %>% filter(!is.na(minister_type)) %>%
  mutate(mt = relevel(factor(minister_type), ref = "Minister of Defense"))
mR <- feols(purged_y1 ~ fca * mt + e1 + e2 + e3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
            data = dR, cluster = ~country_isocode)
# H3b: importance tier (ref: PM/President not leader = 4)
dI <- b %>% filter(!is.na(importance_numeric), importance_numeric != "0") %>%
  mutate(it = relevel(factor(as.character(importance_numeric)), ref = "4"))
mI <- feols(purged_y1 ~ fca * it + e1 + e2 + e3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
            data = dI, cluster = ~country_isocode)
for (m in list(E = mE, A = mA, R = mR, I = mI)) { cat("== N =", nobs(m), "\n"); print(coeftable(m)) }

cf <- function(m, k) unname(coef(m)[k])
cat(sprintf("RESULT:failed_coup_base_country_fe=%.6f\n", cf(fs$base_c, "fca")))
cat(sprintf("RESULT:failed_coup_main_country_fe=%.6f\n", cf(fs$main_c, "fca")))
cat(sprintf("RESULT:failed_coup_base_leader_fe=%.6f\n", cf(fs$base_l, "fca")))
cat(sprintf("RESULT:failed_coup_main_leader_fe=%.6f\n", cf(fs$main_l, "fca")))
cat(sprintf("RESULT:failed_coup_experience_model=%.6f\n", cf(mE, "fca")))
cat(sprintf("RESULT:failed_coup_x_over_6_years_experience=%.6f\n", cf(mE, "fca:egOver 6 years")))
cat(sprintf("RESULT:failed_coup_affiliation_model=%.6f\n", cf(mA, "fca")))
cat(sprintf("RESULT:failed_coup_x_leaders_party=%.6f\n", cf(mA, "fca:pgleader_party")))
cat(sprintf("RESULT:failed_coup_responsibility_model=%.6f\n", cf(mR, "fca")))
cat(sprintf("RESULT:failed_coup_x_natural_resources=%.6f\n", cf(mR, "fca:mtMinister of Natural Resources")))
cat(sprintf("RESULT:failed_coup_importance_model=%.6f\n", cf(mI, "fca")))
