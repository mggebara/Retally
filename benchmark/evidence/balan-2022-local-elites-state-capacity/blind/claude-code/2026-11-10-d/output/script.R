# Balan, Bergeron, Tourek & Weigel (2022, AER) "Local Elites as State Capacity"
# Independent, blind reproduction of Tables 4-8 quantities from the raw base data.
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest); library(lubridate)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rd <- function(f, ...) read_dta(file.path(base, f), ...)
unlab <- function(d) mutate(d, across(where(is.labelled), ~as.numeric(zap_labels(.x))))

## ---- Treatment assignment (de facto) and strata --------------------------------
ra <- rd("admin_data/randomization_assignment.dta") %>% unlab() %>% select(a7, treatment, stratum)
# One neighbourhood randomly assigned to CXL (4) was implemented as Local (2): a7 654
# (chief-only registration teams; endline file records it as Local). Use de facto assignment.
ra <- ra %>% mutate(treat = ifelse(a7 == 654 & treatment == 4, 2, treatment))
cat("De facto neighbourhoods by arm (0 ctrl,1 Central,2 Local,3 CLI,4 CXL):\n"); print(table(ra$treat))

## ---- Property register ------------------------------------------------------------
reg <- rd("admin_data/registration_noPII.dta",
          col_select = c(a7, compound1, start, pilot, tot_complete, house, exempt)) %>% unlab() %>%
  inner_join(ra, by = "a7") %>%                       # 356 randomised neighbourhoods (drops pilot)
  filter(pilot == 0, tot_complete == 1, house %in% c(1, 2)) %>%   # completed records; villas outside campaign
  distinct(compound1, .keep_all = TRUE) %>%
  mutate(rdate = as.Date(start))
cat("Registered properties by arm:\n"); print(table(reg$treat))

## ---- Payments (administrative receipts matched by tax ID) ---------------------------
tp <- rd("admin_data/tax_payments_noPII.dta") %>% unlab() %>% filter(!is.na(compound1))
tp <- tp %>% filter(is.na(dup_receipt) | dup_receipt == 0)        # drop duplicate copies of receipts
pay <- tp %>% group_by(compound1) %>%
  summarise(n_rec = n(), amt_raw = sum(amountCF, na.rm = TRUE), amt_na = all(is.na(amountCF)),
            amt_max = suppressWarnings(max(amountCF, na.rm = TRUE)), .groups = "drop")
reg <- reg %>% left_join(pay, by = "compound1") %>%
  mutate(paid = as.numeric(!is.na(n_rec)),
         liability = ifelse(house == 2, 13200, 3000),
         # amounts above the top statutory liability (13,200 CF) or missing are entry errors:
         # replace by the property's statutory liability
         revenue = case_when(paid == 0 ~ 0,
                             amt_na | amt_raw > 13200 ~ liability,
                             TRUE ~ amt_raw))
cat("Payers matched to register:", sum(reg$paid), "; revenue fixes:",
    sum(reg$paid == 1 & (reg$amt_na | reg$amt_raw > 13200)), "\n")

## ---- Campaign-period (time) fixed effects, online App. A2.5 -------------------------
# Two-month periods starting at the midpoint between the two arms' first campaign days and ending
# at the midpoint between their last days (dates = property registration dates). Properties outside drop.
make_periods <- function(d, arms) {
  x <- d %>% filter(treat %in% arms)
  f <- x %>% group_by(treat) %>% summarise(first = min(rdate, na.rm = TRUE), last = max(rdate, na.rm = TRUE))
  s <- min(f$first) + floor(as.numeric(max(f$first) - min(f$first)) / 2)
  e <- min(f$last) + floor(as.numeric(max(f$last) - min(f$last)) / 2)
  cat("Arms", paste(arms, collapse = "/"), ": first days", format(f$first), "last days", format(f$last),
      "-> window", format(s), "to", format(e), "\n")
  x %>% mutate(inwin = !is.na(rdate) & rdate >= s & rdate <= e,
               period = ifelse(inwin, floor(interval(s, rdate) %/% months(1) / 2), NA_real_))
}

lc <- make_periods(reg, c(1, 2)) %>% mutate(local = as.numeric(treat == 2))
lcw <- lc %>% filter(inwin)
cat("L/C periods:\n"); print(table(lcw$period, lcw$treat))
cat("L/C clusters all:", n_distinct(lc$a7), " in window:", n_distinct(lcw$a7), "\n")

vc <- ~a7
m1 <- feols(paid ~ local | stratum, data = lc, cluster = vc)
m2 <- feols(paid ~ local | stratum + period, data = lcw, cluster = vc)
m4 <- feols(paid ~ local | stratum + period + house, data = lcw, cluster = vc)
m5 <- feols(paid ~ local | stratum + period + house, data = filter(lcw, !(exempt %in% 1)), cluster = vc)
r2 <- feols(revenue ~ local | stratum + period, data = lcw, cluster = vc)
r4 <- feols(revenue ~ local | stratum + period + house, data = lcw, cluster = vc)
etable(m1, m2, m4, m5, r2, r4, digits = 4)
cat("Central means: col1", mean(lc$paid[lc$local == 0]), " col2", mean(lcw$paid[lcw$local == 0]),
    " rev col2", mean(lcw$revenue[lcw$local == 0]), "\n")

## ---- Table 7: CLI vs Central -------------------------------------------------------
cc <- make_periods(reg, c(1, 3)) %>% filter(inwin) %>% mutate(cli = as.numeric(treat == 3))
t7c <- feols(paid ~ cli | stratum + period + house, data = cc, cluster = vc)
t7r <- feols(revenue ~ cli | stratum + period + house, data = cc, cluster = vc)
etable(t7c, t7r, digits = 4)

## ---- Table 8: chief's ease-of-payment rating within CLI ----------------------------
cons <- rd("survey_data/chief_consultations.dta", col_select = c(compound1, pay_ease)) %>% unlab() %>%
  filter(!is.na(compound1)) %>% distinct(compound1, .keep_all = TRUE)
cli <- reg %>% filter(treat == 3) %>% inner_join(cons, by = "compound1") %>% filter(pay_ease %in% 0:2)
t8 <- feols(paid ~ pay_ease | house + stratum, data = cli, cluster = vc)
etable(t8, digits = 4)

## ---- Table 6 col 1: visited after registration (midline) ----------------------------
mid <- rd("survey_data/midline_noPII.dta",
          col_select = c(a7, compound, tot_complete, pilot, dup_compound, monitoring_survey_twice,
                         unknown_compound, visited, visits)) %>% unlab() %>%
  filter(tot_complete == 1, pilot == 0, !(dup_compound %in% 1:3), monitoring_survey_twice == 0, unknown_compound == 0) %>%
  mutate(visits = ifelse(visits >= 99, NA, visits),
         # "visits" counts all collector visits incl. the registration visit -> post-registration visit if >= 2
         vis_post = case_when(visited == 0 ~ 0, visits >= 2 ~ 1, visits %in% 0:1 ~ 0, TRUE ~ NA_real_)) %>%
  filter(!is.na(vis_post)) %>% distinct(compound, .keep_all = TRUE)
md <- lcw %>% select(compound1, a7, stratum, period, house, local) %>% inner_join(mid %>% select(compound, vis_post), by = c("compound1" = "compound"))
t6 <- feols(vis_post ~ local | house + stratum + period, data = md, cluster = vc)
etable(t6, digits = 4)

## ---- Table 5 Panel B: paid bribe at endline -----------------------------------------
e1 <- rd("survey_data/endline_round1_noPII.dta", col_select = c(a7, tot_complete, visited, bribe)) %>% unlab() %>%
  filter(tot_complete == 1) %>% inner_join(ra, by = "a7") %>% filter(treat %in% c(1, 2)) %>%
  mutate(bribe_end = case_when(bribe == 1 ~ 1, bribe == 0 ~ 0, visited %in% c(0, 2) ~ 0, TRUE ~ NA_real_),
         local = as.numeric(treat == 2)) %>% filter(!is.na(bribe_end))
t5 <- feols(bribe_end ~ local | stratum, data = e1, cluster = vc)
etable(t5, digits = 4)

## ---- Results ----------------------------------------------------------------------
res <- c(
  compliance_local_table4_panelA_col1 = coef(m1)[["local"]],
  compliance_local_table4_panelA_col2 = coef(m2)[["local"]],
  compliance_local_house_fe_table4_panelA_col4 = coef(m4)[["local"]],
  compliance_local_exempt_excluded_table4_panelA_col5 = coef(m5)[["local"]],
  revenue_local_table4_panelB_col2 = coef(r2)[["local"]],
  revenue_local_house_fe_table4_panelB_col4 = coef(r4)[["local"]],
  n_obs_table4_col1 = nobs(m1),
  n_obs_table4_col2 = nobs(m2),
  paid_bribe_endline_local_table5_panelB = coef(t5)[["local"]],
  visited_by_collector_local_table6_col1 = coef(t6)[["local"]],
  compliance_cli_table7_col1 = coef(t7c)[["cli"]],
  revenue_cli_table7_col2 = coef(t7r)[["cli"]],
  compliance_ease_of_payment_cli_table8_panelA_col2 = coef(t8)[["pay_ease"]])
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
