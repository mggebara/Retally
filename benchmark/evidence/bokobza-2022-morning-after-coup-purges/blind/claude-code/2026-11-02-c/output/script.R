# Retally blind reproduction: Bokobza et al. (2022) "The Morning After"
# Country-level (Tables A1, A2) and individual-level (Tables K1, K2) OLS / LPM models.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-c/mount/bokobza_2022_morning_after_coup_purges"

## ---------------- Country level ----------------
c <- read_dta(file.path(D, "morning_after_dataset_countrylevel.dta"))
c <- zap_labels(c)
# Lags within country (consecutive years), used for the country-FE models and for the
# autocracy restriction (lagged Boix-Miller-Rosato democracy == 0).
c <- c %>% arrange(COUNTRY_ID, YEAR_DATA) %>% group_by(COUNTRY_ID) %>%
  mutate(okc  = dplyr::lag(YEAR_DATA) == YEAR_DATA - 1,
         ldem = ifelse(okc, dplyr::lag(democracy1), NA),
         lgdp = ifelse(okc, dplyr::lag(gdp_cap_pwt_ln), NA),
         lpop = ifelse(okc, dplyr::lag(pop_pwt_ln), NA),
         lmon = ifelse(okc, dplyr::lag(monarchy_c), NA),
         lmil = ifelse(okc, dplyr::lag(military_c), NA),
         lpar = ifelse(okc, dplyr::lag(party_c), NA)) %>% ungroup()
# Lags within leader spell (panel = leader), used for the leader-FE models
c <- c %>% arrange(leader_cab_id, YEAR_DATA) %>% group_by(leader_cab_id) %>%
  mutate(okl   = dplyr::lag(YEAR_DATA) == YEAR_DATA - 1,
         lgdpL = ifelse(okl, dplyr::lag(gdp_cap_pwt_ln), NA),
         lpopL = ifelse(okl, dplyr::lag(pop_pwt_ln), NA),
         lmonL = ifelse(okl, dplyr::lag(monarchy_c), NA),
         lmilL = ifelse(okl, dplyr::lag(military_c), NA),
         lparL = ifelse(okl, dplyr::lag(party_c), NA)) %>% ungroup()

cs <- c %>% filter(ldem == 0, YEAR_DATA >= 1967, YEAR_DATA <= 2016)

m_cb <- feols(replacement_rateadj_minister ~ coupattempt_whogov + lgdp + lpop | COUNTRY_ID + YEAR_DATA,
              data = cs, cluster = ~COUNTRY_ID)
m_cm <- feols(replacement_rateadj_minister ~ coupattempt_whogov + lgdp + lpop + lmon + lmil + lpar | COUNTRY_ID + YEAR_DATA,
              data = cs, cluster = ~COUNTRY_ID)
m_lb <- feols(replacement_rateadj_minister ~ coupattempt_whogov + lgdpL + lpopL | leader_cab_id + YEAR_DATA,
              data = cs, cluster = ~COUNTRY_ID)
m_lm <- feols(replacement_rateadj_minister ~ coupattempt_whogov + lgdpL + lpopL + lmonL + lmilL + lparL | leader_cab_id + YEAR_DATA,
              data = cs, cluster = ~COUNTRY_ID)
for (m in list(m_cb, m_cm, m_lb, m_lm)) {
  cat("N =", nobs(m), " clusters =", length(unique(cs$COUNTRY_ID[obs(m)])), "\n"); print(coeftable(m))
}

## ---------------- Individual level ----------------
i <- readRDS(file.path(D, "morning_after_dataset_individuallevel.rds"))
# Data fix: in the supplied file pop_pwt_ln_lag is an exact copy of gdp_cap_pwt_ln_lag
# (correlation 1), so population would drop out as collinear.  Rebuild the one-year lag of
# logged population (and, as a check, of logged GDP/capita) from the country-year series.
cyr <- i %>% distinct(country_isocode, year, gdp_cap_pwt_ln, pop_pwt_ln) %>%
  group_by(country_isocode, year) %>% summarise(gdp = first(gdp_cap_pwt_ln), pop = first(pop_pwt_ln), .groups = "drop") %>%
  arrange(country_isocode, year) %>% group_by(country_isocode) %>%
  mutate(okp = dplyr::lag(year) == year - 1,
         pop_lag_fix = ifelse(okp, dplyr::lag(pop), NA),
         gdp_lag_fix = ifelse(okp, dplyr::lag(gdp), NA)) %>% ungroup() %>%
  select(country_isocode, year, pop_lag_fix, gdp_lag_fix)
i <- i %>% left_join(cyr, by = c("country_isocode", "year"))
cat("cor(given pop lag, given gdp lag):", cor(i$pop_pwt_ln_lag, i$gdp_cap_pwt_ln_lag, use = "complete"), "\n")
cat("max |given gdp lag - rebuilt gdp lag|:", max(abs(i$gdp_cap_pwt_ln_lag - i$gdp_lag_fix), na.rm = TRUE),
    " NA mismatch:", sum(is.na(i$gdp_cap_pwt_ln_lag) != is.na(i$gdp_lag_fix)), "\n")
i$pop_pwt_ln_lag <- i$pop_lag_fix
i <- i %>% filter(democracy_lag == 0, year >= 1967, year <= 2016, leader == 0) %>%
  mutate(fca = as.integer(coupattempt_presentyear == "Coup attempt"),
         exper = as.numeric(experience),
         imp = as.character(importance_numeric))

# H2a: experience groups (no cubic polynomials), leader and ministers without an importance tier excluded
d_exp <- i %>% filter(!is.na(imp)) %>%
  mutate(expg = relevel(factor(experience_group), ref = "1year"))
m_exp <- feols(purged_y1 ~ fca * expg + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
               data = d_exp, cluster = ~country_isocode)
# H2b: party affiliation (ref other party), cubic in years in office
d_aff <- i %>% filter(party_group %in% c("independent", "leader_party", "other_party")) %>%
  mutate(pg = relevel(factor(party_group), ref = "other_party"))
m_aff <- feols(purged_y1 ~ fca * pg + exper + I(exper^2) + I(exper^3) + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
               data = d_aff, cluster = ~country_isocode)
# H3a: portfolio type (ref defense)
d_res <- i %>% filter(!is.na(minister_type)) %>%
  mutate(mt = relevel(factor(minister_type), ref = "Minister of Defense"))
m_res <- feols(purged_y1 ~ fca * mt + exper + I(exper^2) + I(exper^3) + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
               data = d_res, cluster = ~country_isocode)
# H3b: importance tier (ref "4" = PM/President who is not the leader)
d_imp <- i %>% filter(imp %in% c("0.5", "1", "2", "3", "4")) %>%
  mutate(it = relevel(factor(imp), ref = "4"))
m_imp <- feols(purged_y1 ~ fca * it + exper + I(exper^2) + I(exper^3) + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
               data = d_imp, cluster = ~country_isocode)
for (m in list(m_exp, m_aff, m_res, m_imp)) { cat("N =", nobs(m), "\n"); print(coeftable(m)) }

out <- c(
  failed_coup_base_country_fe = coef(m_cb)[["coupattempt_whogov"]],
  failed_coup_main_country_fe = coef(m_cm)[["coupattempt_whogov"]],
  failed_coup_base_leader_fe  = coef(m_lb)[["coupattempt_whogov"]],
  failed_coup_main_leader_fe  = coef(m_lm)[["coupattempt_whogov"]],
  failed_coup_experience_model = coef(m_exp)[["fca"]],
  failed_coup_x_over_6_years_experience = coef(m_exp)[["fca:expgOver 6 years"]],
  failed_coup_affiliation_model = coef(m_aff)[["fca"]],
  failed_coup_x_leaders_party = coef(m_aff)[["fca:pgleader_party"]],
  failed_coup_responsibility_model = coef(m_res)[["fca"]],
  failed_coup_x_natural_resources = coef(m_res)[["fca:mtMinister of Natural Resources"]],
  failed_coup_importance_model = coef(m_imp)[["fca"]]
)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
