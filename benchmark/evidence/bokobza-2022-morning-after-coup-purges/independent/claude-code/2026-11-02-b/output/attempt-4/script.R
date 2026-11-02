# Independent reproduction: Bokobza et al. (2022), "The Morning After" (JOP)
# Country-level (Tables A1/A2) and individual-level (Tables K1/K2) estimates.
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
dir <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-b/mount/bokobza_2022_morning_after_coup_purges"

## ---------------- Country level ----------------
c <- read_dta(file.path(dir, "morning_after_dataset_countrylevel.dta")) %>%
  zap_labels() %>% arrange(COUNTRY_ID, YEAR_DATA)
lag1 <- function(x, yr) ifelse(yr - dplyr::lag(yr) == 1, dplyr::lag(x), NA)
c <- c %>% group_by(COUNTRY_ID) %>% mutate(
  ldem   = lag1(democracy1, YEAR_DATA),      # lagged Boix-Miller-Rosato democracy
  lgdp   = lag1(gdp_cap_pwt_ln, YEAR_DATA),
  lpop   = lag1(pop_pwt_ln, YEAR_DATA),
  lmon   = lag1(monarchy_c, YEAR_DATA),
  lmil   = lag1(military_c, YEAR_DATA),
  lparty = lag1(party_c, YEAR_DATA)) %>% ungroup()
cs <- c %>% filter(ldem == 0, YEAR_DATA >= 1967, YEAR_DATA <= 2016)
cs$fca <- cs$coupattempt_whogov   # failed coup attempt, July-recoded (WhoGov timing)

m_a1_base <- feols(replacement_rateadj_minister ~ fca + lgdp + lpop | COUNTRY_ID + YEAR_DATA,
                   data = cs, cluster = ~COUNTRY_ID)
m_a1_main <- feols(replacement_rateadj_minister ~ fca + lgdp + lpop + lmon + lmil + lparty | COUNTRY_ID + YEAR_DATA,
                   data = cs, cluster = ~COUNTRY_ID)
m_a2_base <- feols(replacement_rateadj_minister ~ fca + lgdp + lpop | leader_cab_id + YEAR_DATA,
                   data = cs, cluster = ~COUNTRY_ID)
m_a2_main <- feols(replacement_rateadj_minister ~ fca + lgdp + lpop + lmon + lmil + lparty | leader_cab_id + YEAR_DATA,
                   data = cs, cluster = ~COUNTRY_ID)
etable(m_a1_base, m_a1_main, m_a2_base, m_a2_main)

## ---------------- Individual level ----------------
i <- readRDS(file.path(dir, "morning_after_dataset_individuallevel.rds"))
ind <- i %>% filter(democracy_lag == 0, year >= 1967, year <= 2016, leader == 0) %>%
  mutate(fca = as.integer(coupattempt_presentyear == "Coup attempt"),
         lgdp = gdp_cap_pwt_ln_lag, lpop = pop_pwt_ln_lag,
         imp = as.character(importance_numeric))
# fixest's default collinearity tolerance spuriously drops lagged log population
# (which varies only slowly within country) at this sample size; tighten it so the
# specification matches the paper, which estimates the population coefficient.
setFixest_estimation(collin.tol = 1e-14)
cat("within-country SD of lagged log population:",
    sd(ind$lpop - ave(ind$lpop, ind$country_isocode, FUN = function(z) mean(z, na.rm = TRUE)), na.rm = TRUE), "\n")

# H2a experience: no cubic polynomials; sample excludes leader and rows without a rank tier
d_exp <- ind %>% filter(!is.na(imp)) %>%
  mutate(e23 = as.integer(experience_group == "2-3 years"),
         e46 = as.integer(experience_group == "4-6 years"),
         e6p = as.integer(experience_group == "Over 6 years"))
m_exp <- feols(purged_y1 ~ fca*(e23 + e46 + e6p) + lgdp + lpop | country_isocode + year,
               data = d_exp, cluster = ~country_isocode)

# H2b affiliation: ref = other party; drop unknown/missing affiliation
d_aff <- ind %>% filter(party_group %in% c("independent", "leader_party", "other_party")) %>%
  mutate(nopty = as.integer(party_group == "independent"),
         ldpty = as.integer(party_group == "leader_party"))
m_aff <- feols(purged_y1 ~ fca*(nopty + ldpty) + experience + I(experience^2) + I(experience^3) + lgdp + lpop |
                 country_isocode + year, data = d_aff, cluster = ~country_isocode)

# H3a responsibility: ref = Minister of Defense
d_res <- ind %>% filter(!is.na(minister_type)) %>%
  mutate(mfa = as.integer(minister_type == "Minister of Foreign Affairs"),
         mfin = as.integer(minister_type == "Minister of Finance"),
         moth = as.integer(minister_type == "Other type of minister"),
         mnat = as.integer(minister_type == "Minister of Natural Resources"))
m_res <- feols(purged_y1 ~ fca*(mfa + mfin + moth + mnat) + experience + I(experience^2) + I(experience^3) + lgdp + lpop |
                 country_isocode + year, data = d_res, cluster = ~country_isocode)

# H3b importance: ref = PM/President not leader (tier 4)
d_imp <- ind %>% filter(imp %in% c("0.5", "1", "2", "3", "4")) %>%
  mutate(top = as.integer(imp == "3"), med = as.integer(imp == "2"),
         low = as.integer(imp == "1"), jun = as.integer(imp == "0.5"))
m_imp <- feols(purged_y1 ~ fca*(top + med + low + jun) + experience + I(experience^2) + I(experience^3) + lgdp + lpop |
                 country_isocode + year, data = d_imp, cluster = ~country_isocode)
etable(m_exp, m_aff, m_res, m_imp)

r <- function(name, m, v) cat(sprintf("RESULT:%s=%.6f\n", name, coef(m)[[v]]))
r("failed_coup_base_country_fe", m_a1_base, "fca")
r("failed_coup_main_country_fe", m_a1_main, "fca")
r("failed_coup_base_leader_fe", m_a2_base, "fca")
r("failed_coup_main_leader_fe", m_a2_main, "fca")
r("failed_coup_experience_model", m_exp, "fca")
r("failed_coup_x_over_6_years_experience", m_exp, "fca:e6p")
r("failed_coup_affiliation_model", m_aff, "fca")
r("failed_coup_x_leaders_party", m_aff, "fca:ldpty")
r("failed_coup_responsibility_model", m_res, "fca")
r("failed_coup_x_natural_resources", m_res, "fca:mnat")
r("failed_coup_importance_model", m_imp, "fca")
