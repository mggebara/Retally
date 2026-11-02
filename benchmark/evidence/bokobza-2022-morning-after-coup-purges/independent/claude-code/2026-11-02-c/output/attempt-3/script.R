## Independent reproduction: Bokobza et al. (2022), "The Morning After"
## Country-level (Table A1/A2) and individual-level (Table K1/K2) models.
set.seed(42)
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-c/mount/bokobza_2022_morning_after_coup_purges"

## ---------------- Country level ----------------
cl <- read_dta(file.path(D, "morning_after_dataset_countrylevel.dta")) %>%
  zap_labels() %>% arrange(COUNTRY_ID, YEAR_DATA)
lag1 <- function(x, yr) ifelse(dplyr::lag(yr) == yr - 1, dplyr::lag(x), NA)
cl <- cl %>% group_by(COUNTRY_ID) %>% mutate(
  l_gdp = lag1(gdp_cap_pwt_ln, YEAR_DATA),
  l_pop = lag1(pop_pwt_ln, YEAR_DATA),
  l_mon = lag1(monarchy_c, YEAR_DATA),
  l_mil = lag1(military_c, YEAR_DATA),
  l_par = lag1(party_c, YEAR_DATA)) %>% ungroup()
## Autocracies (Boix-Miller-Rosato democracy score 0); democracy1 reproduces the
## reported sample of 3,715 country-years in 115 countries for the base model.
cs <- cl %>% filter(democracy1 == 0)

m_base_c <- feols(replacement_rateadj_minister ~ coupattempt_whogov + l_gdp + l_pop | COUNTRY_ID + YEAR_DATA,
                  data = cs, cluster = ~COUNTRY_ID)
m_main_c <- feols(replacement_rateadj_minister ~ coupattempt_whogov + l_gdp + l_pop + l_mon + l_mil + l_par | COUNTRY_ID + YEAR_DATA,
                  data = cs, cluster = ~COUNTRY_ID)
m_base_l <- feols(replacement_rateadj_minister ~ coupattempt_whogov + l_gdp + l_pop | leader_cab_id + YEAR_DATA,
                  data = cs, cluster = ~COUNTRY_ID)
m_main_l <- feols(replacement_rateadj_minister ~ coupattempt_whogov + l_gdp + l_pop + l_mon + l_mil + l_par | leader_cab_id + YEAR_DATA,
                  data = cs, cluster = ~COUNTRY_ID)
for (m in list(m_base_c, m_main_c, m_base_l, m_main_l)) cat("country-level N:", nobs(m), "\n")

## ---------------- Individual level ----------------
ind <- readRDS(file.path(D, "morning_after_dataset_individuallevel.rds"))
ind <- ind %>% filter(democracy_lag == 0, leader == 0) %>%
  mutate(fca = as.integer(coupattempt_presentyear == "Coup attempt"),
         exp1 = experience, exp2 = experience^2, exp3 = experience^3)

## H2a experience: experience groups (ref <2 years), no cubic polynomials.
## Sample: ministers with a valid importance tier (the reported N of 90,020).
d_exp <- ind %>% filter(!is.na(importance_numeric)) %>%
  mutate(expg = relevel(factor(experience_group), ref = "1year"))
m_exp <- feols(purged_y1 ~ fca * expg + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
               data = d_exp, cluster = ~country_isocode)

## H2b affiliation: ref other party
d_aff <- ind %>% filter(party_group %in% c("independent", "leader_party", "other_party")) %>%
  mutate(pg = relevel(factor(party_group), ref = "other_party"))
m_aff <- feols(purged_y1 ~ fca * pg + exp1 + exp2 + exp3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
               data = d_aff, cluster = ~country_isocode)

## H3a responsibility: ref Minister of Defense
d_res <- ind %>% filter(!is.na(minister_type)) %>%
  mutate(mt = relevel(factor(minister_type), ref = "Minister of Defense"))
m_res <- feols(purged_y1 ~ fca * mt + exp1 + exp2 + exp3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
               data = d_res, cluster = ~country_isocode)

## H3b importance: five tiers, ref PM/President (not leader)
d_imp <- ind %>% filter(importance_numeric %in% c("0.5", "1", "2", "3", "4")) %>%
  mutate(tier = relevel(factor(as.character(importance_numeric)), ref = "4"))
m_imp <- feols(purged_y1 ~ fca * tier + exp1 + exp2 + exp3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
               data = d_imp, cluster = ~country_isocode)

for (m in list(m_exp, m_aff, m_res, m_imp)) cat("individual-level N:", nobs(m), "\n")
print(etable(m_exp, m_aff, m_res, m_imp))
print(etable(m_base_c, m_main_c, m_base_l, m_main_l))

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("failed_coup_base_country_fe", coef(m_base_c)["coupattempt_whogov"])
r("failed_coup_main_country_fe", coef(m_main_c)["coupattempt_whogov"])
r("failed_coup_base_leader_fe",  coef(m_base_l)["coupattempt_whogov"])
r("failed_coup_main_leader_fe",  coef(m_main_l)["coupattempt_whogov"])
r("failed_coup_experience_model", coef(m_exp)["fca"])
r("failed_coup_x_over_6_years_experience", coef(m_exp)["fca:expgOver 6 years"])
r("failed_coup_affiliation_model", coef(m_aff)["fca"])
r("failed_coup_x_leaders_party", coef(m_aff)["fca:pgleader_party"])
r("failed_coup_responsibility_model", coef(m_res)["fca"])
r("failed_coup_x_natural_resources", coef(m_res)["fca:mtMinister of Natural Resources"])
r("failed_coup_importance_model", coef(m_imp)["fca"])
