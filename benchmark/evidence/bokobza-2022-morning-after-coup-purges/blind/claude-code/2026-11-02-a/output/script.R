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
# Leader-FE models: panel set on leader spells (as Stata L. after xtset leader year), so the one-year
# lags of controls are taken within the leader spell; this is what makes lagged monarchy collinear
# with the leader fixed effects, as the paper reports.
cs <- cs %>% arrange(leader_cab_id, YEAR_DATA) %>% group_by(leader_cab_id) %>%
  mutate(lcons = (YEAR_DATA - lag(YEAR_DATA)) == 1) %>% ungroup()
cl2 <- cl %>% arrange(leader_cab_id, YEAR_DATA) %>% group_by(leader_cab_id) %>%
  mutate(lc = (YEAR_DATA - lag(YEAR_DATA)) == 1,
         ll_gdp = ifelse(lc, lag(gdp_cap_pwt_ln), NA), ll_pop = ifelse(lc, lag(pop_pwt_ln), NA),
         ll_mon = ifelse(lc, lag(monarchy_c), NA), ll_mil = ifelse(lc, lag(military_c), NA),
         ll_par = ifelse(lc, lag(party_c), NA)) %>% ungroup() %>%
  select(COUNTRY_ID, YEAR_DATA, ll_gdp, ll_pop, ll_mon, ll_mil, ll_par)
cs <- cs %>% left_join(cl2, by = c("COUNTRY_ID", "YEAR_DATA"))
m_bl <- feols(rr ~ fca + ll_gdp + ll_pop | leader_cab_id + YEAR_DATA, data = cs, cluster = ~COUNTRY_ID)
m_ml <- feols(rr ~ fca + ll_gdp + ll_pop + ll_mon + ll_mil + ll_par | leader_cab_id + YEAR_DATA, data = cs, cluster = ~COUNTRY_ID)
etable(m_bc, m_mc, m_bl, m_ml)

## ---------------- Individual level (Tables K1, K2) ----------------
il <- readRDS(file.path(d, "morning_after_dataset_individuallevel.rds"))
# The shipped pop_pwt_ln_lag is an exact copy of gdp_cap_pwt_ln_lag (data bug); rebuild the
# one-year lag of logged population within country from pop_pwt_ln.
cat("DEVIATION: individual-level pop_pwt_ln_lag equals gdp_cap_pwt_ln_lag in the data; rebuilt from pop_pwt_ln lagged one year within country\n")
cat("identical gdp/pop lag columns:", isTRUE(all.equal(il$pop_pwt_ln_lag, il$gdp_cap_pwt_ln_lag)), "\n")
pp <- il %>% filter(!is.na(pop_pwt_ln)) %>% distinct(country_isocode, year, pop_pwt_ln) %>%
  group_by(country_isocode, year) %>% summarise(pop = mean(pop_pwt_ln), .groups = "drop") %>%
  mutate(year = year + 1L) %>% rename(pop_lag_fix = pop)
il <- il %>% left_join(pp, by = c("country_isocode", "year")) %>% mutate(pop_pwt_ln_lag = pop_lag_fix)
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
