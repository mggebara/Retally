# Independent reproduction: Balan, Bergeron, Tourek & Weigel (2022), "Local Elites as State Capacity"
# Reconstructed from the paper text only. Equation (1): y = b0 + b*Local + X*G + stratum FE + time FE + e,
# SEs clustered by neighborhood (a7).
suppressMessages({library(haven); library(dplyr); library(fixest); library(lubridate)})
set.seed(42)
options(width = 200)
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-b/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"

# ---------------- treatment assignment (de facto) ----------------
ra <- read_dta(file.path(B, "admin_data/randomization_assignment.dta")) %>%
  transmute(a7, treatment = as.vector(treatment), stratum)
# Footnote 40: one neighborhood assigned to CXL received Local; endline survey and the
# registration form (chief-only teams) identify it as a7 654. Use de facto assignment.
ra$treatment[ra$a7 == 654] <- 2
cat("Neighborhoods by de facto arm:\n"); print(table(ra$treatment))

# ---------------- property register ----------------
rg <- read_dta(file.path(B, "admin_data/registration_noPII.dta"),
               col_select = c(start, a7, house, compound1, exempt))
reg <- rg %>% inner_join(ra, by = "a7") %>%                 # 356 study neighborhoods (drops logistics pilot)
  mutate(house = as.vector(house), exempt = as.vector(exempt), rdate = as.Date(start)) %>%
  filter(house %in% c(1, 2)) %>%                            # villas (house==3) are outside the campaign
  arrange(compound1, start) %>% distinct(compound1, .keep_all = TRUE)
cat("Registered properties by arm:\n"); print(table(reg$treatment))

# ---------------- tax payments (receipt data), matched by tax ID ----------------
pay <- read_dta(file.path(B, "admin_data/tax_payments_noPII.dta")) %>% select(compound1, amountCF)
reg_h <- reg %>% select(compound1, house)
pay <- pay %>% left_join(reg_h, by = "compound1") %>%
  mutate(liab = ifelse(house %in% 2, 13200, 3000),
         amt = ifelse(is.na(amountCF) | amountCF > 13200 | amountCF < 1000, liab, amountCF))  # obvious entry errors -> liability
cat("Payment records with unusable amounts replaced by liability:", sum(is.na(pay$amountCF) | pay$amountCF > 13200 | pay$amountCF < 1000), "\n")
payc <- pay %>% group_by(compound1) %>% summarise(amount = sum(amt), .groups = "drop") %>% mutate(paid = 1)
reg <- reg %>% left_join(payc, by = "compound1") %>%
  mutate(paid = ifelse(is.na(paid), 0, 1), revenue = ifelse(is.na(amount), 0, amount))

# ---------------- time fixed effects (online App. A2.5 as described in the claims) ----------------
# two-month periods starting at the midpoint between the two arms' first registration days and
# ending at the midpoint between their last days; properties outside the window drop out.
add_period <- function(d, arms) {
  f <- sapply(arms, function(a) as.numeric(min(d$rdate[d$treatment == a], na.rm = TRUE)))
  l <- sapply(arms, function(a) as.numeric(max(d$rdate[d$treatment == a], na.rm = TRUE)))
  s <- as.Date(floor(mean(f)), origin = "1970-01-01"); e <- as.Date(ceiling(mean(l)), origin = "1970-01-01")
  bounds <- s %m+% months(seq(0, 24, by = 2))
  d$period <- findInterval(as.numeric(d$rdate), as.numeric(bounds))
  d$inwin <- !is.na(d$rdate) & d$rdate >= s & d$rdate <= e
  cat(sprintf("  window for arms %s: %s to %s\n", paste(arms, collapse = "/"), format(s), format(e)))
  d
}

cl <- reg %>% filter(treatment %in% c(1, 2)) %>% mutate(local = as.integer(treatment == 2))
cl <- add_period(cl, c(1, 2))
clw <- cl %>% filter(inwin)

m1  <- feols(paid ~ local | stratum, cl, cluster = ~a7)
m2  <- feols(paid ~ local | stratum + period, clw, cluster = ~a7)
m4  <- feols(paid ~ local | stratum + period + house, clw, cluster = ~a7)
m5  <- feols(paid ~ local | stratum + period + house, clw %>% filter(!(exempt %in% 1)), cluster = ~a7)
r2  <- feols(revenue ~ local | stratum + period, clw, cluster = ~a7)
r4  <- feols(revenue ~ local | stratum + period + house, clw, cluster = ~a7)
cat("\nTable 4 (Local vs Central)\n")
etable(m1, m2, m4, m5, r2, r4, se.below = TRUE)
cat("Clusters col1:", n_distinct(cl$a7), " col2:", n_distinct(clw$a7), "\n")
cat("Central mean col1:", mean(cl$paid[cl$local == 0]), " col2:", mean(clw$paid[clw$local == 0]),
    " revenue col2:", mean(clw$revenue[clw$local == 0]), "\n")

# ---------------- Table 7: CLI vs Central ----------------
cc <- reg %>% filter(treatment %in% c(1, 3)) %>% mutate(cli = as.integer(treatment == 3))
cc <- add_period(cc, c(1, 3)) %>% filter(inwin)
t7c <- feols(paid ~ cli | stratum + period + house, cc, cluster = ~a7)
t7r <- feols(revenue ~ cli | stratum + period + house, cc, cluster = ~a7)
cat("\nTable 7 (CLI vs Central)\n"); etable(t7c, t7r, se.below = TRUE)
cat("Clusters:", n_distinct(cc$a7), "\n")

# ---------------- Table 8: value of chiefs' information (CLI only) ----------------
cons <- read_dta(file.path(B, "survey_data/chief_consultations.dta")) %>%
  transmute(compound1, pay_ease = as.vector(pay_ease)) %>% filter(pay_ease %in% 0:2)
t8d <- reg %>% filter(treatment == 3) %>% inner_join(cons, by = "compound1")
t8 <- feols(paid ~ pay_ease | house + stratum, t8d, cluster = ~a7)
cat("\nTable 8 Panel A col 2\n"); etable(t8, se.below = TRUE); cat("Clusters:", n_distinct(t8d$a7), "\n")

# ---------------- Table 6: visited by collector after registration (midline) ----------------
ml <- read_dta(file.path(B, "survey_data/midline_noPII.dta"),
               col_select = c(a7, compound, today, visited, visits, tot_complete, pilot)) %>%
  mutate(visited = as.vector(visited), visits = as.vector(visits)) %>%
  filter(pilot == 0, tot_complete == 1, !is.na(compound)) %>%
  mutate(visits = ifelse(visits >= 99999, NA, visits),
         visited_after = case_when(visited == 0 ~ 0,
                                   visited %in% c(1, 2) & !is.na(visits) ~ as.numeric(visits >= 2),
                                   TRUE ~ NA_real_)) %>%
  filter(!is.na(visited_after)) %>% arrange(compound, today) %>% distinct(compound, .keep_all = TRUE)
t6d <- clw %>% select(compound1, a7, local, stratum, house, period) %>% inner_join(ml %>% select(compound1 = compound, visited_after), by = "compound1")
t6 <- feols(visited_after ~ local | house + stratum + period, t6d, cluster = ~a7)
cat("\nTable 6 col 1\n"); etable(t6, se.below = TRUE); cat("Clusters:", n_distinct(t6d$a7), " mean:", mean(t6d$visited_after), "\n")

# ---------------- Table 5 Panel B: paid bribe (endline) ----------------
e1 <- read_dta(file.path(B, "survey_data/endline_round1_noPII.dta"), col_select = c(a7, bribe, visited)) %>%
  mutate(bribe = as.vector(bribe), visited = as.vector(visited)) %>%
  inner_join(ra, by = "a7") %>% filter(treatment %in% c(1, 2)) %>% mutate(local = as.integer(treatment == 2)) %>%
  mutate(bribe_end = case_when(bribe %in% c(0, 1) ~ as.numeric(bribe),
                               visited %in% c(0, 2) ~ 0,          # not visited by collectors -> no bribe paid to them
                               TRUE ~ NA_real_)) %>% filter(!is.na(bribe_end))
t5 <- feols(bribe_end ~ local | stratum, e1, cluster = ~a7)
cat("\nTable 5 paid bribe (endline)\n"); etable(t5, se.below = TRUE); cat("Central mean:", mean(e1$bribe_end[e1$local == 0]), "\n")

b <- function(m, v) unname(coef(m)[v])
cat(sprintf("RESULT:compliance_local_table4_panelA_col1=%.6f\n", b(m1, "local")))
cat(sprintf("RESULT:compliance_local_table4_panelA_col2=%.6f\n", b(m2, "local")))
cat(sprintf("RESULT:compliance_local_house_fe_table4_panelA_col4=%.6f\n", b(m4, "local")))
cat(sprintf("RESULT:compliance_local_exempt_excluded_table4_panelA_col5=%.6f\n", b(m5, "local")))
cat(sprintf("RESULT:revenue_local_table4_panelB_col2=%.6f\n", b(r2, "local")))
cat(sprintf("RESULT:revenue_local_house_fe_table4_panelB_col4=%.6f\n", b(r4, "local")))
cat(sprintf("RESULT:n_obs_table4_col1=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_obs_table4_col2=%d\n", nobs(m2)))
cat(sprintf("RESULT:paid_bribe_endline_local_table5_panelB=%.6f\n", b(t5, "local")))
cat(sprintf("RESULT:visited_by_collector_local_table6_col1=%.6f\n", b(t6, "local")))
cat(sprintf("RESULT:compliance_cli_table7_col1=%.6f\n", b(t7c, "cli")))
cat(sprintf("RESULT:revenue_cli_table7_col2=%.6f\n", b(t7r, "cli")))
cat(sprintf("RESULT:compliance_ease_of_payment_cli_table8_panelA_col2=%.6f\n", b(t8, "pay_ease")))
