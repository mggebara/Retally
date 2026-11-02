# Retally blind independent reproduction: bokobza-2022-morning-after-coup-purges
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges"

## ---------------- Country level (Tables A1, A2) ----------------
cl <- read_dta(file.path(d, "morning_after_dataset_countrylevel.dta")) %>% zap_labels() %>% as.data.frame()
cl <- cl %>% arrange(COUNTRY_ID, YEAR_DATA) %>% group_by(COUNTRY_ID) %>%
  mutate(cons = (YEAR_DATA - lag(YEAR_DATA)) == 1,
         l_dem  = ifelse(cons, lag(democracy1), NA),
         l_gdp  = ifelse(cons, lag(gdp_cap_pwt_ln), NA),
         l_pop  = ifelse(cons, lag(pop_pwt_ln), NA),
         l_mon  = ifelse(cons, lag(monarchy_c), NA),
         l_mil  = ifelse(cons, lag(military_c), NA),
         l_par  = ifelse(cons, lag(party_c), NA)) %>% ungroup()
# Autocracies: lagged Boix-Miller-Rosato democracy == 0; 1967-2016
cs <- cl %>% filter(l_dem == 0, YEAR_DATA >= 1967, YEAR_DATA <= 2016)
cs$rr <- cs$replacement_rateadj_minister   # = 1 - adjusted retention rate
cs$fca <- cs$coupattempt_whogov            # failed coup attempt, July-aligned

m_bc <- feols(rr ~ fca + l_gdp + l_pop | COUNTRY_ID + YEAR_DATA, data = cs, cluster = ~COUNTRY_ID)
m_mc <- feols(rr ~ fca + l_gdp + l_pop + l_mon + l_mil + l_par | COUNTRY_ID + YEAR_DATA, data = cs, cluster = ~COUNTRY_ID)
m_bl <- feols(rr ~ fca + l_gdp + l_pop | leader_cab_id + YEAR_DATA, data = cs, cluster = ~COUNTRY_ID)
m_ml <- feols(rr ~ fca + l_gdp + l_pop + l_mon + l_mil + l_par | leader_cab_id + YEAR_DATA, data = cs, cluster = ~COUNTRY_ID)
etable(m_bc, m_mc, m_bl, m_ml)

## ---------------- Individual level (Tables K1, K2) ----------------
il <- readRDS(file.path(d, "morning_after_dataset_individuallevel.rds"))
il <- il %>% filter(democracy_lag == 0, year >= 1967, year <= 2016, leader == 0,
                    !is.na(coupattempt_presentyear), !is.na(gdp_cap_pwt_ln_lag), !is.na(pop_pwt_ln_lag)) %>%
  mutate(fca = as.integer(coupattempt_presentyear == "Coup attempt"),
         purged = purged_y1,
         t1 = experience, t2 = experience^2, t3 = experience^3,
         imp = as.character(importance_numeric))
cat("individual base sample:", nrow(il), "\n")

# H2a experience (no cubic polynomials); exclude junior ministers / other low-ranking posts
ie <- il %>% filter(is.na(imp) | imp != "0.5") %>%
  mutate(e23 = as.integer(experience_group == "2-3 years"),
         e46 = as.integer(experience_group == "4-6 years"),
         e6p = as.integer(experience_group == "Over 6 years"))
m_exp <- feols(purged ~ fca + e23 + e46 + e6p + fca:e23 + fca:e46 + fca:e6p + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag |
                 country_isocode + year, data = ie, cluster = ~country_isocode)

# H2b affiliation (ref: other party)
ia <- il %>% filter(party_group %in% c("independent", "leader_party", "other_party")) %>%
  mutate(nop = as.integer(party_group == "independent"), lp = as.integer(party_group == "leader_party"))
m_aff <- feols(purged ~ fca + nop + lp + fca:nop + fca:lp + t1 + t2 + t3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag |
                 country_isocode + year, data = ia, cluster = ~country_isocode)

# H3a responsibility (ref: minister of defense)
ir <- il %>% filter(!is.na(minister_type)) %>%
  mutate(fa = as.integer(minister_type == "Minister of Foreign Affairs"),
         fi = as.integer(minister_type == "Minister of Finance"),
         nr = as.integer(minister_type == "Minister of Natural Resources"),
         ot = as.integer(minister_type == "Other type of minister"))
m_res <- feols(purged ~ fca + fa + fi + nr + ot + fca:fa + fca:fi + fca:nr + fca:ot + t1 + t2 + t3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag |
                 country_isocode + year, data = ir, cluster = ~country_isocode)

# H3b importance (ref: PM/President not leader)
ii <- il %>% filter(imp %in% c("0.5", "1", "2", "3", "4")) %>%
  mutate(top = as.integer(imp == "3"), med = as.integer(imp == "2"),
         low = as.integer(imp == "1"), jun = as.integer(imp == "0.5"))
m_imp <- feols(purged ~ fca + top + med + low + jun + fca:top + fca:med + fca:low + fca:jun + t1 + t2 + t3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag |
                 country_isocode + year, data = ii, cluster = ~country_isocode)
etable(m_exp, m_aff, m_res, m_imp)

g <- function(m, v) unname(coef(m)[v])
cat(sprintf("RESULT:failed_coup_base_country_fe=%.6f\n", g(m_bc, "fca")))
cat(sprintf("RESULT:failed_coup_main_country_fe=%.6f\n", g(m_mc, "fca")))
cat(sprintf("RESULT:failed_coup_base_leader_fe=%.6f\n", g(m_bl, "fca")))
cat(sprintf("RESULT:failed_coup_main_leader_fe=%.6f\n", g(m_ml, "fca")))
cat(sprintf("RESULT:failed_coup_experience_model=%.6f\n", g(m_exp, "fca")))
cat(sprintf("RESULT:failed_coup_x_over_6_years_experience=%.6f\n", g(m_exp, "fca:e6p")))
cat(sprintf("RESULT:failed_coup_affiliation_model=%.6f\n", g(m_aff, "fca")))
cat(sprintf("RESULT:failed_coup_x_leaders_party=%.6f\n", g(m_aff, "fca:lp")))
cat(sprintf("RESULT:failed_coup_responsibility_model=%.6f\n", g(m_res, "fca")))
cat(sprintf("RESULT:failed_coup_x_natural_resources=%.6f\n", g(m_res, "fca:nr")))
cat(sprintf("RESULT:failed_coup_importance_model=%.6f\n", g(m_imp, "fca")))
