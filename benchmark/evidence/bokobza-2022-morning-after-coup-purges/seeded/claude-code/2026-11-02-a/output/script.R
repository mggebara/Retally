## Retally seeded reproduction: bokobza-2022-morning-after-coup-purges
## Country-level (Tables A1, A2): translation of Stata xtreg, fe with i.YEAR_DATA, cluster(COUNTRY_ID)
## Individual-level (Tables K1, K2): translation of the authors' felm models
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest); library(forcats)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges"

########## Country level ##########
cl <- read_dta(file.path(D, "morning_after_dataset_countrylevel.dta")) %>% zap_labels() %>% as.data.frame()

# Stata L. operator: value at YEAR_DATA-1 within the xtset panel (full data, gaps -> missing)
add_lags <- function(df, panel, vars) {
  key <- df[!is.na(df[[panel]]), c(panel, "YEAR_DATA", vars)]
  key$YEAR_DATA <- key$YEAR_DATA + 1
  names(key)[-(1:2)] <- paste0("L_", vars)
  left_join(df, key, by = c(panel, "YEAR_DATA"))
}
lagvars <- c("gdp_cap_pwt_ln", "pop_pwt_ln", "military_c", "monarchy_c", "party_c")

cl_c <- add_lags(cl, "COUNTRY_ID", lagvars) %>% filter(democracy1 == 0 & independent == 1)
cl_l <- add_lags(cl %>% filter(!is.na(leader_cab_id)), "leader_cab_id", lagvars) %>%
  filter(democracy1 == 0 & independent == 1)

a1_base <- feols(replacement_rateadj_minister ~ coupattempt_whogov + L_gdp_cap_pwt_ln + L_pop_pwt_ln |
                   COUNTRY_ID + YEAR_DATA, data = cl_c, cluster = ~COUNTRY_ID)
a1_main <- feols(replacement_rateadj_minister ~ coupattempt_whogov + L_gdp_cap_pwt_ln + L_pop_pwt_ln +
                   L_military_c + L_monarchy_c + L_party_c | COUNTRY_ID + YEAR_DATA, data = cl_c, cluster = ~COUNTRY_ID)
a2_base <- feols(replacement_rateadj_minister ~ coupattempt_whogov + L_gdp_cap_pwt_ln + L_pop_pwt_ln |
                   leader_cab_id + YEAR_DATA, data = cl_l, cluster = ~COUNTRY_ID)
a2_main <- feols(replacement_rateadj_minister ~ coupattempt_whogov + L_gdp_cap_pwt_ln + L_pop_pwt_ln +
                   L_military_c + L_monarchy_c + L_party_c | leader_cab_id + YEAR_DATA, data = cl_l, cluster = ~COUNTRY_ID)
for (m in list(a1_base, a1_main, a2_base, a2_main)) print(summary(m))

########## Individual level ##########
df_aut <- readRDS(file.path(D, "morning_after_dataset_individuallevel.rds")) %>%
  filter(democracy_lag == 0 & leader == 0 & !is.na(purged_y1) & !is.na(gdp_cap_pwt_ln) & !is.na(pop_pwt_ln))
df_aut$fca <- as.integer(df_aut$coupattempt_presentyear != levels(df_aut$coupattempt_presentyear)[1])
cat("coup levels:", levels(df_aut$coupattempt_presentyear), "\n")
print(levels(df_aut$importance_factor))

# Experience (H2a)
df_experience <- df_aut %>% filter(importance_factor != "0.5")
df_experience$experience_group <- factor(df_experience$experience_group)  # ref "1year"
m_exp <- feols(purged_y1 ~ experience_group * fca + gdp_cap_pwt_ln + pop_pwt_ln | country_isocode + year,
               data = df_experience, cluster = ~country_isocode)

# Affiliation (H2b)
df_party <- df_aut %>% filter(party_group != "unknown") %>%
  mutate(party_group = recode(party_group, "independent" = "No party affiliation",
                              "leader_party" = "From the leader's party", "other_party" = "From another party"),
         party_group = factor(party_group, levels = c("From another party", "No party affiliation", "From the leader's party")))
m_aff <- feols(purged_y1 ~ party_group * fca + gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                 I(experience^3) | country_isocode + year, data = df_party, cluster = ~country_isocode)

# Responsibility (H3a)
df_resp <- df_aut %>% filter(!is.na(minister_type)) %>%
  mutate(minister_type = factor(minister_type, levels = c("Minister of Defense", "Minister of Foreign Affairs",
                                                          "Minister of Finance", "Other type of minister",
                                                          "Minister of Natural Resources")))
m_resp <- feols(purged_y1 ~ minister_type * fca + gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                  I(experience^3) | country_isocode + year, data = df_resp, cluster = ~country_isocode)

# Importance (H3b)
df_importance <- df_aut %>% filter(importance_factor != "0" & !is.na(importance_factor)) %>% droplevels()
df_importance$importance_factor <- relevel(df_importance$importance_factor, ref = "Prime minister/President\n(not leader)")
m_imp <- feols(purged_y1 ~ importance_factor * fca + gdp_cap_pwt_ln + pop_pwt_ln + experience + I(experience^2) +
                 I(experience^3) | country_isocode + year, data = df_importance, cluster = ~country_isocode)

for (m in list(m_exp, m_aff, m_resp, m_imp)) print(summary(m))

g <- function(m, nm) unname(coef(m)[nm])
res <- c(
  failed_coup_base_country_fe = g(a1_base, "coupattempt_whogov"),
  failed_coup_main_country_fe = g(a1_main, "coupattempt_whogov"),
  failed_coup_base_leader_fe = g(a2_base, "coupattempt_whogov"),
  failed_coup_main_leader_fe = g(a2_main, "coupattempt_whogov"),
  failed_coup_experience_model = g(m_exp, "fca"),
  failed_coup_x_over_6_years_experience = g(m_exp, "experience_groupOver 6 years:fca"),
  failed_coup_affiliation_model = g(m_aff, "fca"),
  failed_coup_x_leaders_party = g(m_aff, "party_groupFrom the leader's party:fca"),
  failed_coup_responsibility_model = g(m_resp, "fca"),
  failed_coup_x_natural_resources = g(m_resp, "minister_typeMinister of Natural Resources:fca"),
  failed_coup_importance_model = g(m_imp, "fca")
)
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
