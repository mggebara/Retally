# Retally blind/independent reproduction: Bokobza et al. (2022), "The Morning After"
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-03-a/mount/bokobza_2022_morning_after_coup_purges"

## ---------------- Country level (Tables A1, A2) ----------------
cl <- zap_labels(read_dta(file.path(D, "morning_after_dataset_countrylevel.dta"))) %>%
  arrange(COUNTRY_ID, YEAR_DATA) %>%
  group_by(COUNTRY_ID) %>%
  mutate(gap = YEAR_DATA - lag(YEAR_DATA),
         l_dem  = ifelse(gap == 1, lag(democracy1), NA),
         l_gdp  = ifelse(gap == 1, lag(gdp_cap_pwt_ln), NA),
         l_pop  = ifelse(gap == 1, lag(pop_pwt_ln), NA),
         l_mon  = ifelse(gap == 1, lag(monarchy_c), NA),
         l_mil  = ifelse(gap == 1, lag(military_c), NA),
         l_par  = ifelse(gap == 1, lag(party_c), NA)) %>%
  ungroup()
cs <- cl %>% filter(YEAR_DATA >= 1967, YEAR_DATA <= 2016, l_dem == 0)

m1 <- feols(replacement_rateadj_minister ~ coupattempt_whogov + l_gdp + l_pop | COUNTRY_ID + YEAR_DATA,
            data = cs, cluster = ~COUNTRY_ID)
m2 <- feols(replacement_rateadj_minister ~ coupattempt_whogov + l_gdp + l_pop + l_mon + l_mil + l_par | COUNTRY_ID + YEAR_DATA,
            data = cs, cluster = ~COUNTRY_ID)
m3 <- feols(replacement_rateadj_minister ~ coupattempt_whogov + l_gdp + l_pop | leader_cab_id + YEAR_DATA,
            data = cs, cluster = ~COUNTRY_ID)
# Paper (Table A2): monarchy is excluded from the leader-FE Main Model as collinear with leader FE.
# In this data it varies within a handful of leader spells, so it is excluded explicitly.
cat("leader spells with within-spell variation in lagged monarchy:",
    sum(tapply(cs$l_mon, cs$leader_cab_id, function(x) length(unique(na.omit(x))) > 1), na.rm = TRUE), "\n")
m4 <- feols(replacement_rateadj_minister ~ coupattempt_whogov + l_gdp + l_pop + l_mil + l_par | leader_cab_id + YEAR_DATA,
            data = cs, cluster = ~COUNTRY_ID)
etable(m1, m2, m3, m4)

## ---------------- Individual level (Tables K1, K2) ----------------
ind <- readRDS(file.path(D, "morning_after_dataset_individuallevel.rds"))
# The supplied pop_pwt_ln_lag column is a copy of gdp_cap_pwt_ln_lag, so both lags are rebuilt
# from the country-year panel (previous calendar year only).
cy <- ind %>% distinct(country_isocode, year, gdp_cap_pwt_ln, pop_pwt_ln) %>%
  distinct(country_isocode, year, .keep_all = TRUE) %>% arrange(country_isocode, year) %>%
  group_by(country_isocode) %>%
  mutate(gap = year - lag(year),
         gdp_l = ifelse(gap == 1, lag(gdp_cap_pwt_ln), NA),
         pop_l = ifelse(gap == 1, lag(pop_pwt_ln), NA)) %>% ungroup() %>%
  select(country_isocode, year, gdp_l, pop_l)
ind <- ind %>% left_join(cy, by = c("country_isocode", "year")) %>%
  filter(year >= 1967, year <= 2016, democracy_lag == 0, leader == 0,
         !is.na(coupattempt_presentyear), !is.na(purged_y1)) %>%
  mutate(fca = as.integer(coupattempt_presentyear == "Coup attempt"),
         exp1 = experience, exp2 = experience^2, exp3 = experience^3)

# H2a experience: excludes junior ministers / other low-ranking posts; no experience polynomials
d_exp <- ind %>% filter(is.na(importance_numeric) | importance_numeric != "0.5") %>%
  mutate(eg = factor(experience_group, levels = c("1year", "2-3 years", "4-6 years", "Over 6 years")))
k_exp <- feols(purged_y1 ~ fca * eg + gdp_l + pop_l | country_isocode + year,
               data = d_exp, cluster = ~country_isocode)

# H2b affiliation: ref = other party; rows with unknown/missing affiliation dropped
d_aff <- ind %>% filter(party_group %in% c("independent", "leader_party", "other_party")) %>%
  mutate(pg = factor(party_group, levels = c("other_party", "independent", "leader_party")))
k_aff <- feols(purged_y1 ~ fca * pg + exp1 + exp2 + exp3 + gdp_l + pop_l | country_isocode + year,
               data = d_aff, cluster = ~country_isocode)

# H3a responsibility: ref = Minister of Defense
d_res <- ind %>% filter(!is.na(minister_type)) %>%
  mutate(mt = factor(minister_type, levels = c("Minister of Defense", "Minister of Foreign Affairs",
                                               "Minister of Finance", "Minister of Natural Resources",
                                               "Other type of minister")))
k_res <- feols(purged_y1 ~ fca * mt + exp1 + exp2 + exp3 + gdp_l + pop_l | country_isocode + year,
               data = d_res, cluster = ~country_isocode)

# H3b importance: ref = prime minister / president (not leader)
d_imp <- ind %>% filter(importance_numeric %in% c("0.5", "1", "2", "3", "4")) %>%
  mutate(imp = factor(as.character(importance_numeric), levels = c("4", "3", "2", "1", "0.5")))
k_imp <- feols(purged_y1 ~ fca * imp + exp1 + exp2 + exp3 + gdp_l + pop_l | country_isocode + year,
               data = d_imp, cluster = ~country_isocode)
etable(k_exp, k_aff, k_res, k_imp)

cf <- function(m, n) unname(coef(m)[n])
res <- c(
  failed_coup_base_country_fe = cf(m1, "coupattempt_whogov"),
  failed_coup_main_country_fe = cf(m2, "coupattempt_whogov"),
  failed_coup_base_leader_fe  = cf(m3, "coupattempt_whogov"),
  failed_coup_main_leader_fe  = cf(m4, "coupattempt_whogov"),
  failed_coup_experience_model = cf(k_exp, "fca"),
  failed_coup_x_over_6_years_experience = cf(k_exp, "fca:egOver 6 years"),
  failed_coup_affiliation_model = cf(k_aff, "fca"),
  failed_coup_x_leaders_party = cf(k_aff, "fca:pgleader_party"),
  failed_coup_responsibility_model = cf(k_res, "fca"),
  failed_coup_x_natural_resources = cf(k_res, "fca:mtMinister of Natural Resources"),
  failed_coup_importance_model = cf(k_imp, "fca")
)
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
