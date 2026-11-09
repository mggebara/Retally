# Independent, blind reproduction of Bokobza et al. (2022) "The Morning After"
# Country-level (Table A1/A2) and individual-level (Tables K1/K2) models.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
P <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-07-a/mount/bokobza_2022_morning_after_coup_purges"

## ---------------- Country level ----------------
cl <- read_dta(file.path(P, "morning_after_dataset_countrylevel.dta"))
cl <- zap_labels(cl)
lag1 <- function(x, yr) ifelse(c(NA, diff(yr)) == 1, dplyr::lag(x), NA)
cl <- cl %>% arrange(COUNTRY_ID, YEAR_DATA) %>% group_by(COUNTRY_ID) %>%
  mutate(ldem   = lag1(democracy1, YEAR_DATA),      # lagged Boix-Miller-Rosato democracy
         l_gdp  = lag1(gdp_cap_pwt_ln, YEAR_DATA),
         l_pop  = lag1(pop_pwt_ln, YEAR_DATA),
         l_mon  = lag1(monarchy_c, YEAR_DATA),
         l_mil  = lag1(military_c, YEAR_DATA),
         l_par  = lag1(party_c, YEAR_DATA)) %>% ungroup()
cs <- cl %>% filter(ldem == 0, YEAR_DATA >= 1967, YEAR_DATA <= 2016) %>%
  mutate(rr = replacement_rateadj_minister, fca = coupattempt_whogov)

m_base_c <- feols(rr ~ fca + l_gdp + l_pop | COUNTRY_ID + YEAR_DATA, data = cs, cluster = ~COUNTRY_ID)
m_main_c <- feols(rr ~ fca + l_gdp + l_pop + l_mon + l_mil + l_par | COUNTRY_ID + YEAR_DATA, data = cs, cluster = ~COUNTRY_ID)
m_base_l <- feols(rr ~ fca + l_gdp + l_pop | leader_cab_id + YEAR_DATA, data = cs, cluster = ~COUNTRY_ID)
m_main_l <- feols(rr ~ fca + l_gdp + l_pop + l_mon + l_mil + l_par | leader_cab_id + YEAR_DATA, data = cs, cluster = ~COUNTRY_ID)
etable(m_base_c, m_main_c, m_base_l, m_main_l)
for (m in list(m_base_c, m_main_c, m_base_l, m_main_l))
  cat("N =", nobs(m), " clusters =", length(unique(cs$COUNTRY_ID[obs(m)])), " coups =", sum(cs$fca[obs(m)]), "\n")

## ---------------- Individual level ----------------
d <- readRDS(file.path(P, "morning_after_dataset_individuallevel.rds"))
d <- d %>% filter(democracy_lag == 0, year >= 1967, year <= 2016, leader == 0,
                  !is.na(coupattempt_presentyear), !is.na(importance_numeric)) %>%
  mutate(fca = as.integer(coupattempt_presentyear == "Coup attempt"),
         exp1 = experience, exp2 = experience^2, exp3 = experience^3,
         expg = relevel(factor(experience_group), ref = "1year"),
         imp  = as.character(importance_numeric))
cat("Individual base sample:", nrow(d), " no-coup:", sum(d$fca == 0), " coup:", sum(d$fca == 1),
    " countries:", n_distinct(d$country_isocode), "\n")

# H2a Experience: exclude junior ministers / low-ranking posts; no cubic polynomial
dE <- d %>% filter(imp != "0.5")
mE <- feols(purged_y1 ~ fca * expg + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
            data = dE, cluster = ~country_isocode)

# H2b Affiliation: ref = other party; 'independent' = no party affiliation; unknown dropped
dA <- d %>% filter(party_group %in% c("other_party", "independent", "leader_party")) %>%
  mutate(aff = factor(party_group, levels = c("other_party", "independent", "leader_party")))
mA <- feols(purged_y1 ~ fca * aff + exp1 + exp2 + exp3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
            data = dA, cluster = ~country_isocode)

# H3a Responsibility: portfolio type, ref = Minister of Defense
dR <- d %>% filter(!is.na(minister_type)) %>%
  mutate(mt = relevel(factor(minister_type), ref = "Minister of Defense"))
mR <- feols(purged_y1 ~ fca * mt + exp1 + exp2 + exp3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
            data = dR, cluster = ~country_isocode)

# H3b Importance: tiers, ref = PM/President (not leader) (importance 4)
dI <- d %>% filter(imp %in% c("4", "3", "2", "1", "0.5")) %>%
  mutate(tier = factor(imp, levels = c("4", "3", "2", "1", "0.5")))
mI <- feols(purged_y1 ~ fca * tier + exp1 + exp2 + exp3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_isocode + year,
            data = dI, cluster = ~country_isocode)
etable(mE, mA, mR, mI)
for (m in list(mE, mA, mR, mI)) cat("N =", nobs(m), "\n")

## ---------------- Results ----------------
out <- c(
  failed_coup_base_country_fe = coef(m_base_c)[["fca"]],
  failed_coup_main_country_fe = coef(m_main_c)[["fca"]],
  failed_coup_base_leader_fe  = coef(m_base_l)[["fca"]],
  failed_coup_main_leader_fe  = coef(m_main_l)[["fca"]],
  failed_coup_experience_model = coef(mE)[["fca"]],
  failed_coup_x_over_6_years_experience = coef(mE)[["fca:expgOver 6 years"]],
  failed_coup_affiliation_model = coef(mA)[["fca"]],
  failed_coup_x_leaders_party = coef(mA)[["fca:affleader_party"]],
  failed_coup_responsibility_model = coef(mR)[["fca"]],
  failed_coup_x_natural_resources = coef(mR)[["fca:mtMinister of Natural Resources"]],
  failed_coup_importance_model = coef(mI)[["fca"]]
)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
