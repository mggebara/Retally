# Retally blind independent reproduction: Balan, Bergeron, Tourek & Weigel (2022, AER)
# "Local Elites as State Capacity" -- Tables 4, 5 (endline bribe), 6 (col 1), 7 (cols 1-2), 8 (panel A col 2)
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-a/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rd <- function(p, ...) read_dta(file.path(B, p), ...)

# ---------------------------------------------------------------- neighborhoods
# Treatment codes: 0 Control, 1 Central, 2 Local, 3 CLI, 4 CXL.
sch <- rd("admin_data/randomization_schedule.dta") %>% transmute(a7, arm = as.numeric(treatment))
asg <- rd("admin_data/randomization_assignment.dta") %>% transmute(a7, stratum = as.numeric(stratum))
nb <- left_join(sch, asg, by = "a7")
# Footnote 40: one neighborhood assigned to CXL received Local; de facto assignment is used.
# Neighborhood 654 (CXL in the schedule) was registered by the chief alone and is coded Local
# (treatment = 2) in the endline survey -> de facto Local.
nb$arm[nb$a7 == 654] <- 2
cat("Neighborhoods by de facto arm:\n"); print(table(nb$arm))

# Registration register: house band, collector-designated exemption, registration dates
reg <- rd("admin_data/registration_noPII.dta",
          col_select = c(a7_compound, compound1, today, start, house, exempt))
reg$day <- as.Date(ifelse(is.na(reg$today), as.Date(reg$start), reg$today), origin = "1970-01-01")
# Neighborhood campaign date = median registration date in the neighborhood
nbdate <- reg %>% filter(!is.na(day)) %>% group_by(a7 = a7_compound) %>%
  summarise(nb_date = as.Date(median(as.numeric(day)), origin = "1970-01-01"), .groups = "drop")
nb <- left_join(nb, nbdate, by = "a7")

# Time fixed effects (online App. A2.5 as summarised in the task): two-month periods starting at
# the midpoint between the first days of the two arms compared and ending at the midpoint
# between their last days; neighborhoods outside that window drop out.
mid <- function(a, b) as.Date(floor((as.numeric(a) + as.numeric(b)) / 2), origin = "1970-01-01")
make_periods <- function(armA, armB) {
  dA <- nb$nb_date[nb$arm == armA]; dB <- nb$nb_date[nb$arm == armB]
  s <- mid(min(dA, na.rm = TRUE), min(dB, na.rm = TRUE))
  e <- mid(max(dA, na.rm = TRUE), max(dB, na.rm = TRUE))
  br <- seq(s, by = "2 months", length.out = 12)
  per <- findInterval(as.numeric(nb$nb_date), as.numeric(br))
  per[is.na(nb$nb_date) | nb$nb_date < s | nb$nb_date > e] <- NA
  cat(sprintf("Periods arms %d vs %d: window %s to %s\n", armA, armB, s, e))
  print(table(arm = nb$arm[nb$arm %in% c(armA, armB)], period = per[nb$arm %in% c(armA, armB)], useNA = "ifany"))
  data.frame(a7 = nb$a7, period = per)
}
per_LC <- make_periods(2, 1)
per_CLI <- make_periods(3, 1)

# ---------------------------------------------------------------- property-level tax data
regp <- reg %>% group_by(compound1) %>%
  summarise(house = first(house), exempt = as.numeric(any(exempt %in% 1)), .groups = "drop")
tr <- rd("admin_data/taxroll_noPII.dta") %>% select(compound1, a7)
pay <- rd("admin_data/tax_payments_noPII.dta") %>% filter(!is.na(compound1)) %>%
  group_by(compound1) %>% summarise(amount = sum(amountCF), .groups = "drop")
prop <- tr %>% left_join(regp, by = "compound1") %>% left_join(pay, by = "compound1") %>%
  left_join(nb %>% select(a7, arm, stratum), by = "a7") %>%
  filter(!is.na(arm), !(house %in% 3))            # villas are outside the 2018 campaign
prop$paid <- as.numeric(!is.na(prop$amount) | prop$compound1 %in% pay$compound1)
# Revenue: amount paid (0 for non-payers). Two receipts carry implausible amounts (>1.4m CF,
# > 100x the highest liability) and a few have no amount: these payers are given the median
# amount paid by payers in the same house band.
med_band <- prop %>% filter(paid == 1, !is.na(amount), amount <= 13200) %>% group_by(house) %>%
  summarise(med = median(amount))
prop <- prop %>% left_join(med_band, by = "house") %>%
  mutate(revenue = case_when(paid == 0 ~ 0,
                             is.na(amount) | amount > 13200 ~ med,
                             TRUE ~ amount))
cat("Payers with imputed revenue:", sum(prop$paid == 1 & (is.na(prop$amount) | prop$amount > 13200)), "\n")
prop$house_f <- factor(prop$house)

LC <- prop %>% filter(arm %in% c(1, 2)) %>% mutate(local = as.numeric(arm == 2)) %>%
  left_join(per_LC, by = "a7")
CC <- prop %>% filter(arm %in% c(1, 3)) %>% mutate(cli = as.numeric(arm == 3)) %>%
  left_join(per_CLI, by = "a7")

# ---------------------------------------------------------------- Table 4
t4_1  <- feols(paid ~ local | stratum, data = LC, cluster = ~a7)
t4_2  <- feols(paid ~ local | stratum + period, data = LC, cluster = ~a7)
t4_4  <- feols(paid ~ local | stratum + period + house_f, data = LC, cluster = ~a7)
t4_5  <- feols(paid ~ local | stratum + period + house_f, data = LC %>% filter(exempt == 0), cluster = ~a7)
t4b_2 <- feols(revenue ~ local | stratum + period, data = LC, cluster = ~a7)
t4b_4 <- feols(revenue ~ local | stratum + period + house_f, data = LC, cluster = ~a7)
etable(t4_1, t4_2, t4_4, t4_5, t4b_2, t4b_4)

# ---------------------------------------------------------------- Table 7 (CLI vs Central)
t7_1 <- feols(paid ~ cli | stratum + period + house_f, data = CC, cluster = ~a7)
t7_2 <- feols(revenue ~ cli | stratum + period + house_f, data = CC, cluster = ~a7)
etable(t7_1, t7_2)

# ---------------------------------------------------------------- Table 8 panel A col 2
cc <- rd("survey_data/chief_consultations.dta", col_select = c(compound1, pay_ease)) %>%
  mutate(pay_ease = as.numeric(pay_ease)) %>% filter(pay_ease %in% 0:2) %>%
  distinct(compound1, .keep_all = TRUE)
CLIp <- prop %>% filter(arm == 3) %>% inner_join(cc, by = "compound1")
t8 <- feols(paid ~ pay_ease | house_f + stratum, data = CLIp, cluster = ~a7)
etable(t8)

# ---------------------------------------------------------------- Table 6 col 1 (midline)
ml <- rd("survey_data/midline_noPII.dta", col_select = c(a7, compound, today, visited, visits, tot_complete)) %>%
  filter(tot_complete == 1, !is.na(compound)) %>% arrange(compound, today) %>%
  distinct(compound, .keep_all = TRUE)
ml <- ml %>% mutate(visited = as.numeric(visited),
                    visit_post = case_when(visits >= 2 & visits < 100 ~ 1,   # visits include registration visit
                                           visited == 0 ~ 0,
                                           visits %in% c(0, 1) ~ 0,
                                           TRUE ~ NA_real_))
ML <- ml %>% inner_join(regp %>% select(compound1, house), by = c("compound" = "compound1")) %>%
  filter(!(house %in% 3)) %>% left_join(nb %>% select(a7, arm, stratum), by = "a7") %>%
  filter(arm %in% c(1, 2)) %>% mutate(local = as.numeric(arm == 2), house_f = factor(house)) %>%
  left_join(per_LC, by = "a7")
t6 <- feols(visit_post ~ local | house_f + stratum + period, data = ML, cluster = ~a7)
etable(t6)

# ---------------------------------------------------------------- Table 5 panel B: paid bribe (endline)
e1 <- rd("survey_data/endline_round1_noPII.dta", col_select = c(a7, code, today, visited, bribe)) %>%
  mutate(visited = as.numeric(visited), bribe = as.numeric(bribe)) %>%
  filter(!is.na(visited)) %>%
  mutate(paid_bribe = case_when(bribe == 1 ~ 1, bribe == 0 ~ 0,
                                visited %in% c(0, 2) ~ 0,   # no collector contact -> no transport paid
                                TRUE ~ NA_real_)) %>%
  filter(!is.na(paid_bribe)) %>% arrange(code, desc(today)) %>% distinct(code, .keep_all = TRUE)
EL <- e1 %>% left_join(nb %>% select(a7, arm, stratum), by = "a7") %>% filter(arm %in% c(1, 2)) %>%
  mutate(local = as.numeric(arm == 2))
t5 <- feols(paid_bribe ~ local | stratum, data = EL, cluster = ~a7)
etable(t5)

# ---------------------------------------------------------------- results
out <- c(
  compliance_local_table4_panelA_col1 = coef(t4_1)[["local"]],
  compliance_local_table4_panelA_col2 = coef(t4_2)[["local"]],
  compliance_local_house_fe_table4_panelA_col4 = coef(t4_4)[["local"]],
  compliance_local_exempt_excluded_table4_panelA_col5 = coef(t4_5)[["local"]],
  revenue_local_table4_panelB_col2 = coef(t4b_2)[["local"]],
  revenue_local_house_fe_table4_panelB_col4 = coef(t4b_4)[["local"]],
  n_obs_table4_col1 = nobs(t4_1),
  n_obs_table4_col2 = nobs(t4_2),
  paid_bribe_endline_local_table5_panelB = coef(t5)[["local"]],
  visited_by_collector_local_table6_col1 = coef(t6)[["local"]],
  compliance_cli_table7_col1 = coef(t7_1)[["cli"]],
  revenue_cli_table7_col2 = coef(t7_2)[["cli"]],
  compliance_ease_of_payment_cli_table8_panelA_col2 = coef(t8)[["pay_ease"]]
)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
