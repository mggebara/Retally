## Independent reproduction: Bokobza et al. (2022), "The Morning After" (JOP)
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
P <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges"

## ---------------- Country level (Tables A1, A2) ----------------
c <- read_dta(file.path(P, "morning_after_dataset_countrylevel.dta")) %>% zap_labels()
c <- c %>% arrange(COUNTRY_ID, YEAR_DATA) %>% group_by(COUNTRY_ID) %>%
  mutate(lagok = !is.na(lag(YEAR_DATA)) & lag(YEAR_DATA) == YEAR_DATA - 1,
         lgdp = ifelse(lagok, lag(gdp_cap_pwt_ln), NA),
         lpop = ifelse(lagok, lag(pop_pwt_ln), NA),
         lmon = ifelse(lagok, lag(monarchy_c), NA),
         lmil = ifelse(lagok, lag(military_c), NA),
         lpar = ifelse(lagok, lag(party_c), NA)) %>% ungroup()
# autocracies (BMR democracy1 == 0; this variable reproduces the paper's N of 3,715 / 115 countries / 95 coups), 1967-2016
cd <- c %>% filter(democracy1 == 0, YEAR_DATA >= 1967, YEAR_DATA <= 2016)

m_bc <- feols(replacement_rateadj_minister ~ coupattempt_whogov + lgdp + lpop | COUNTRY_ID + YEAR_DATA, cd, cluster = ~COUNTRY_ID)
m_mc <- feols(replacement_rateadj_minister ~ coupattempt_whogov + lgdp + lpop + lmon + lmil + lpar | COUNTRY_ID + YEAR_DATA, cd, cluster = ~COUNTRY_ID)
# Leader-FE models: panel set by leader spell, so controls are lagged within the leader's spell
# (first year of each spell has no lag). This matches the paper's lower N (3,332) and the
# monarchy dummy being collinear with leader FE (Table A2 note).
cl <- c %>% arrange(leader_cab_id, YEAR_DATA) %>% group_by(leader_cab_id) %>%
  mutate(lok = !is.na(lag(YEAR_DATA)) & lag(YEAR_DATA) == YEAR_DATA - 1,
         lgdp = ifelse(lok, lag(gdp_cap_pwt_ln), NA),
         lpop = ifelse(lok, lag(pop_pwt_ln), NA),
         lmon = ifelse(lok, lag(monarchy_c), NA),
         lmil = ifelse(lok, lag(military_c), NA),
         lpar = ifelse(lok, lag(party_c), NA)) %>% ungroup() %>%
  filter(democracy1 == 0, YEAR_DATA >= 1967, YEAR_DATA <= 2016)
m_bl <- feols(replacement_rateadj_minister ~ coupattempt_whogov + lgdp + lpop | leader_cab_id + YEAR_DATA, cl, cluster = ~COUNTRY_ID)
m_ml <- feols(replacement_rateadj_minister ~ coupattempt_whogov + lgdp + lpop + lmon + lmil + lpar | leader_cab_id + YEAR_DATA, cl, cluster = ~COUNTRY_ID)
etable(m_bc, m_mc, m_bl, m_ml)

## ---------------- Individual level (Tables K1, K2) ----------------
i <- readRDS(file.path(P, "morning_after_dataset_individuallevel.rds"))
# country-year lags of logged GDP/cap and population (the supplied pop lag column duplicates the GDP lag)
cy <- i %>% group_by(country_isocode, year) %>%
  summarise(gdp = first(gdp_cap_pwt_ln), pop = first(pop_pwt_ln), .groups = "drop") %>%
  arrange(country_isocode, year) %>% group_by(country_isocode) %>%
  mutate(ok = !is.na(lag(year)) & lag(year) == year - 1,
         lgdp = ifelse(ok, lag(gdp), NA), lpop = ifelse(ok, lag(pop), NA)) %>% ungroup() %>%
  select(country_isocode, year, lgdp, lpop)
i <- i %>% left_join(cy, by = c("country_isocode", "year"))
b <- i %>% filter(democracy_lag == 0, year >= 1967, year <= 2016, leader == 0,
                  !is.na(coupattempt_presentyear), !is.na(lgdp), !is.na(lpop)) %>%
  mutate(fca = as.integer(coupattempt_presentyear == "Coup attempt"),
         exp1 = experience, exp2 = experience^2, exp3 = experience^3)
cat("Individual base sample:", nrow(b), "\n")

# H2a experience: groups (ref <2 years), no cubic polynomials
de <- b %>% filter(!is.na(importance_numeric)) %>%
  mutate(eg = relevel(factor(experience_group), ref = "1year"))
m_exp <- feols(purged_y1 ~ fca * eg + lgdp + lpop | country_isocode + year, de, cluster = ~country_isocode)

# H2b affiliation (ref: other party)
da <- b %>% filter(party_group %in% c("independent", "leader_party", "other_party")) %>%
  mutate(pg = relevel(factor(party_group), ref = "other_party"))
m_aff <- feols(purged_y1 ~ fca * pg + exp1 + exp2 + exp3 + lgdp + lpop | country_isocode + year, da, cluster = ~country_isocode)

# H3a responsibility (ref: defense)
dr <- b %>% filter(!is.na(minister_type)) %>%
  mutate(mt = relevel(factor(minister_type), ref = "Minister of Defense"))
m_res <- feols(purged_y1 ~ fca * mt + exp1 + exp2 + exp3 + lgdp + lpop | country_isocode + year, dr, cluster = ~country_isocode)

# H3b importance (ref: PM/President not leader = tier 4)
di <- b %>% filter(importance_numeric %in% c("0.5", "1", "2", "3", "4")) %>%
  mutate(imp = relevel(factor(as.character(importance_numeric)), ref = "4"))
m_imp <- feols(purged_y1 ~ fca * imp + exp1 + exp2 + exp3 + lgdp + lpop | country_isocode + year, di, cluster = ~country_isocode)
etable(m_exp, m_aff, m_res, m_imp)

r <- function(nm, m, term) cat(sprintf("RESULT:%s=%.6f\n", nm, coef(m)[[term]]))
r("failed_coup_base_country_fe", m_bc, "coupattempt_whogov")
r("failed_coup_main_country_fe", m_mc, "coupattempt_whogov")
r("failed_coup_base_leader_fe", m_bl, "coupattempt_whogov")
r("failed_coup_main_leader_fe", m_ml, "coupattempt_whogov")
r("failed_coup_experience_model", m_exp, "fca")
r("failed_coup_x_over_6_years_experience", m_exp, "fca:egOver 6 years")
r("failed_coup_affiliation_model", m_aff, "fca")
r("failed_coup_x_leaders_party", m_aff, "fca:pgleader_party")
r("failed_coup_responsibility_model", m_res, "fca")
r("failed_coup_x_natural_resources", m_res, "fca:mtMinister of Natural Resources")
r("failed_coup_importance_model", m_imp, "fca")
