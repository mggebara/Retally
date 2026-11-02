# Retally reproduction: Bokobza et al. (2022), "The Morning After" (seeded mode)
# Country-level: Appendix A (Tables A1/A2) from the authors' Stata do-file
#   xtset <panel> YEAR_DATA; xtreg y coupattempt_whogov L.x ... i.YEAR_DATA if democracy1==0 & independent==1, fe cluster(COUNTRY_ID)
# Individual-level: Appendix K (Tables K1/K2) from the authors' R script (felm -> feols).
set.seed(42)
suppressMessages({library(dplyr); library(haven); library(fixest)})

M <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b/mount/bokobza_2022_morning_after_coup_purges"

res <- list()

## ---------------- Country level ----------------
cc <- read_dta(file.path(M, "morning_after_dataset_countrylevel.dta")) %>% zap_labels()
cc <- as.data.frame(cc)

# Stata L. operator under xtset <panel> YEAR_DATA: value at (same panel, year-1), missing on gaps
add_lags <- function(df, panel, vars) {
  key <- df[!is.na(df[[panel]]), c(panel, "YEAR_DATA", vars)]
  key$YEAR_DATA <- key$YEAR_DATA + 1
  names(key)[-(1:2)] <- paste0("L_", vars)
  left_join(df, key, by = c(panel, "YEAR_DATA"))
}
lagvars <- c("gdp_cap_pwt_ln", "pop_pwt_ln", "military_c", "monarchy_c", "party_c")

cc_c <- add_lags(cc, "COUNTRY_ID", lagvars) %>% filter(democracy1 == 0 & independent == 1)
cc_l <- add_lags(cc %>% filter(!is.na(leader_cab_id)), "leader_cab_id", lagvars) %>%
  filter(democracy1 == 0 & independent == 1)

a1_base <- feols(replacement_rateadj_minister ~ coupattempt_whogov + L_gdp_cap_pwt_ln + L_pop_pwt_ln |
                   COUNTRY_ID + YEAR_DATA, data = cc_c, cluster = ~COUNTRY_ID)
a1_main <- feols(replacement_rateadj_minister ~ coupattempt_whogov + L_gdp_cap_pwt_ln + L_pop_pwt_ln +
                   L_military_c + L_monarchy_c + L_party_c | COUNTRY_ID + YEAR_DATA,
                 data = cc_c, cluster = ~COUNTRY_ID)
a2_base <- feols(replacement_rateadj_minister ~ coupattempt_whogov + L_gdp_cap_pwt_ln + L_pop_pwt_ln |
                   leader_cab_id + YEAR_DATA, data = cc_l, cluster = ~COUNTRY_ID)
a2_main <- feols(replacement_rateadj_minister ~ coupattempt_whogov + L_gdp_cap_pwt_ln + L_pop_pwt_ln +
                   L_military_c + L_monarchy_c + L_party_c | leader_cab_id + YEAR_DATA,
                 data = cc_l, cluster = ~COUNTRY_ID)
etable(a1_base, a1_main, a2_base, a2_main)

res$failed_coup_base_country_fe   <- coef(a1_base)[["coupattempt_whogov"]]
res$failed_coup_main_country_fe   <- coef(a1_main)[["coupattempt_whogov"]]
res$failed_coup_base_leader_fe    <- coef(a2_base)[["coupattempt_whogov"]]
res$failed_coup_main_leader_fe    <- coef(a2_main)[["coupattempt_whogov"]]

## ---------------- Individual level ----------------
d <- readRDS(file.path(M, "morning_after_dataset_individuallevel.rds"))
df_aut <- d %>% filter(democracy_lag == 0 & leader == 0 & !is.na(purged_y1) &
                         !is.na(gdp_cap_pwt_ln) & !is.na(pop_pwt_ln)) %>%
  mutate(fca = as.numeric(coupattempt_presentyear == "Coup attempt"))
rm(d); invisible(gc())

# H2a: Experience (df_experience: importance_factor != "0.5", which also drops NA importance_factor)
df_experience <- df_aut %>% filter(importance_factor != "0.5") %>%
  mutate(experience_group = factor(experience_group))   # reference "1year" (<2 y), as in R's default
m_exp <- feols(purged_y1 ~ experience_group * fca + gdp_cap_pwt_ln + pop_pwt_ln | country_isocode + year,
               data = df_experience, cluster = ~country_isocode)

# H2b: Affiliation (ref: other party)
df_party <- df_aut %>% filter(party_group != "unknown") %>%
  mutate(party_group = factor(party_group, levels = c("other_party", "independent", "leader_party")))
m_aff <- feols(purged_y1 ~ party_group * fca + gdp_cap_pwt_ln + pop_pwt_ln +
                 experience + I(experience^2) + I(experience^3) | country_isocode + year,
               data = df_party, cluster = ~country_isocode)

# H3a: Responsibility (ref: Minister of Defense)
df_resp <- df_aut %>% mutate(minister_type = relevel(factor(minister_type), ref = "Minister of Defense"))
m_resp <- feols(purged_y1 ~ minister_type * fca + gdp_cap_pwt_ln + pop_pwt_ln +
                  experience + I(experience^2) + I(experience^3) | country_isocode + year,
                data = df_resp, cluster = ~country_isocode)

# H3b: Importance (ref: Prime minister/President (not leader))
df_importance <- df_aut %>% filter(importance_factor != "0" & !is.na(importance_factor)) %>%
  mutate(importance_factor = droplevels(relevel(importance_factor, ref = "Prime minister/President\n(not leader)")))
m_imp <- feols(purged_y1 ~ importance_factor * fca + gdp_cap_pwt_ln + pop_pwt_ln +
                 experience + I(experience^2) + I(experience^3) | country_isocode + year,
               data = df_importance, cluster = ~country_isocode)

etable(m_exp, m_aff)
etable(m_resp, m_imp)

res$failed_coup_experience_model           <- coef(m_exp)[["fca"]]
res$failed_coup_x_over_6_years_experience  <- coef(m_exp)[["experience_groupOver 6 years:fca"]]
res$failed_coup_affiliation_model          <- coef(m_aff)[["fca"]]
res$failed_coup_x_leaders_party            <- coef(m_aff)[["party_groupleader_party:fca"]]
res$failed_coup_responsibility_model       <- coef(m_resp)[["fca"]]
res$failed_coup_x_natural_resources        <- coef(m_resp)[["minister_typeMinister of Natural Resources:fca"]]
res$failed_coup_importance_model           <- coef(m_imp)[["fca"]]

for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
