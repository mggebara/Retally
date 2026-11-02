# Retally blind independent reproduction: bokobza-2022-morning-after-coup-purges
# Reconstructed from the paper text only.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-b/mount/bokobza_2022_morning_after_coup_purges"

## ---------------- Country level (Tables A1, A2) ----------------
# Outcome: replacement_rateadj_minister (= 1 - size-adjusted retention rate)
# Treatment: coupattempt_whogov (Powell & Thyne failed coup attempt, already
#   recoded July-to-July: coups after 1 July counted in the following year)
# Sample: autocracies = lagged Boix-Miller-Rosato democracy (democracy1) == 0, 1967-2016
# Controls lagged one year: ln GDP/cap, ln pop (PWT); Main adds military/monarchy/party dummies
cdat <- read_dta(file.path(D, "morning_after_dataset_countrylevel.dta")) %>%
  mutate(across(where(is.labelled), ~ as.numeric(zap_labels(.x))))
lagv <- c("democracy1", "gdp_cap_pwt_ln", "pop_pwt_ln", "military_c", "monarchy_c", "party_c")
prev <- cdat %>% select(COUNTRY_DATA, YEAR_DATA, all_of(lagv)) %>%
  mutate(YEAR_DATA = YEAR_DATA + 1) %>% rename_with(~ paste0("L_", .x), all_of(lagv))
cdat <- cdat %>% left_join(prev, by = c("COUNTRY_DATA", "YEAR_DATA"))
cs <- cdat %>% filter(L_democracy1 == 0, YEAR_DATA >= 1967, YEAR_DATA <= 2016)

m_base_c <- feols(replacement_rateadj_minister ~ coupattempt_whogov + L_gdp_cap_pwt_ln + L_pop_pwt_ln |
                    COUNTRY_DATA + YEAR_DATA, data = cs, cluster = ~COUNTRY_DATA)
m_main_c <- feols(replacement_rateadj_minister ~ coupattempt_whogov + L_gdp_cap_pwt_ln + L_pop_pwt_ln +
                    L_monarchy_c + L_military_c + L_party_c |
                    COUNTRY_DATA + YEAR_DATA, data = cs, cluster = ~COUNTRY_DATA)
m_base_l <- feols(replacement_rateadj_minister ~ coupattempt_whogov + L_gdp_cap_pwt_ln + L_pop_pwt_ln |
                    leader_cab_id + YEAR_DATA, data = cs, cluster = ~COUNTRY_DATA)
m_main_l <- feols(replacement_rateadj_minister ~ coupattempt_whogov + L_gdp_cap_pwt_ln + L_pop_pwt_ln +
                    L_monarchy_c + L_military_c + L_party_c |
                    leader_cab_id + YEAR_DATA, data = cs, cluster = ~COUNTRY_DATA)

for (nm in c("m_base_c", "m_main_c", "m_base_l", "m_main_l")) {
  m <- get(nm); cat("\n==", nm, " N =", nobs(m), "\n"); print(coeftable(m))
  smp <- cs[obs(m), ]
  cat("countries:", length(unique(smp$COUNTRY_DATA)), " failed coups:", sum(smp$coupattempt_whogov), "\n")
}

## ---------------- Individual level (Tables K1, K2) ----------------
# Outcome: purged_y1 (absent from cabinet next year). Treatment: coupattempt_presentyear.
# Sample: lagged BMR democracy == 0, 1967-2016, leader excluded. Country + year FE,
# lagged ln GDP/cap and ln pop, SE clustered by country.
idat <- readRDS(file.path(D, "morning_after_dataset_individuallevel.rds"))
idat <- idat %>%
  mutate(fca = as.integer(coupattempt_presentyear == "Coup attempt"),
         exp1 = experience, exp2 = experience^2, exp3 = experience^3,
         imp = as.character(importance_numeric)) %>%
  filter(democracy_lag == 0, year >= 1967, year <= 2016, leader == 0,
         !is.na(fca), !is.na(gdp_cap_pwt_ln_lag), !is.na(pop_pwt_ln_lag))
cat("\nIndividual base sample N =", nrow(idat), " years", range(idat$year), "\n")

# H2a Experience: exclude junior ministers / low-ranking posts (importance 0.5); no polynomials
ex <- idat %>% filter(is.na(imp) | imp != "0.5") %>%
  mutate(eg = factor(experience_group, levels = c("1year", "2-3 years", "4-6 years", "Over 6 years")),
         e23 = as.integer(eg == "2-3 years"), e46 = as.integer(eg == "4-6 years"),
         e6p = as.integer(eg == "Over 6 years"))
m_exp <- feols(purged_y1 ~ fca + e23 + e46 + e6p + fca:e23 + fca:e46 + fca:e6p +
                 gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_name + year,
               data = ex, cluster = ~country_name)
cat("\n== H2a experience N =", nobs(m_exp), "\n"); print(coeftable(m_exp))

# H2b Affiliation: ref = other party; independent = no party affiliation; unknown / NA excluded
af <- idat %>% filter(party_group %in% c("other_party", "independent", "leader_party")) %>%
  mutate(noparty = as.integer(party_group == "independent"),
         lparty = as.integer(party_group == "leader_party"))
m_aff <- feols(purged_y1 ~ fca + noparty + lparty + fca:noparty + fca:lparty +
                 exp1 + exp2 + exp3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_name + year,
               data = af, cluster = ~country_name)
cat("\n== H2b affiliation N =", nobs(m_aff), "\n"); print(coeftable(m_aff))

# H3a Responsibility: ref = Minister of Defense
rs <- idat %>% filter(!is.na(minister_type)) %>%
  mutate(mfa = as.integer(minister_type == "Minister of Foreign Affairs"),
         mfin = as.integer(minister_type == "Minister of Finance"),
         mnr = as.integer(minister_type == "Minister of Natural Resources"),
         moth = as.integer(minister_type == "Other type of minister"))
m_resp <- feols(purged_y1 ~ fca + mfa + mfin + mnr + moth + fca:mfa + fca:mfin + fca:mnr + fca:moth +
                  exp1 + exp2 + exp3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_name + year,
                data = rs, cluster = ~country_name)
cat("\n== H3a responsibility N =", nobs(m_resp), "\n"); print(coeftable(m_resp))

# H3b Importance: tiers; ref = PM/President not leader (importance 4)
im <- idat %>% filter(imp %in% c("4", "3", "2", "1", "0.5")) %>%
  mutate(t3 = as.integer(imp == "3"), t2 = as.integer(imp == "2"),
         t1 = as.integer(imp == "1"), t05 = as.integer(imp == "0.5"))
m_imp <- feols(purged_y1 ~ fca + t3 + t2 + t1 + t05 + fca:t3 + fca:t2 + fca:t1 + fca:t05 +
                 exp1 + exp2 + exp3 + gdp_cap_pwt_ln_lag + pop_pwt_ln_lag | country_name + year,
               data = im, cluster = ~country_name)
cat("\n== H3b importance N =", nobs(m_imp), "\n"); print(coeftable(m_imp))

## ---------------- Results ----------------
g <- function(m, v) unname(coef(m)[v])
res <- c(
  failed_coup_base_country_fe = g(m_base_c, "coupattempt_whogov"),
  failed_coup_main_country_fe = g(m_main_c, "coupattempt_whogov"),
  failed_coup_base_leader_fe = g(m_base_l, "coupattempt_whogov"),
  failed_coup_main_leader_fe = g(m_main_l, "coupattempt_whogov"),
  failed_coup_experience_model = g(m_exp, "fca"),
  failed_coup_x_over_6_years_experience = g(m_exp, "fca:e6p"),
  failed_coup_affiliation_model = g(m_aff, "fca"),
  failed_coup_x_leaders_party = g(m_aff, "fca:lparty"),
  failed_coup_responsibility_model = g(m_resp, "fca"),
  failed_coup_x_natural_resources = g(m_resp, "fca:mnr"),
  failed_coup_importance_model = g(m_imp, "fca")
)
cat("\n")
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
