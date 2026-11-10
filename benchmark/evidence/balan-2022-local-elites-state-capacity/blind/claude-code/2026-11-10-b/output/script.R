# Independent, blind reproduction: Balan et al. (2022, AER), "Local Elites as State Capacity"
# Equation (1): y_ijkt = b0 + b*Local_j + X_ijk G + a_k + th_t + e, OLS, SEs clustered by neighborhood (a7).
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-b/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rd <- function(f, ...) read_dta(file.path(base, f), ...)

## ---------------- Neighborhood-level treatment and strata ----------------
ra <- rd("admin_data/randomization_assignment.dta")          # stratum = group(geo_stratum jontax chef_collect_stratum)
rs <- rd("admin_data/randomization_schedule.dta")
nbh <- rs %>% transmute(a7, tr = as.numeric(treatment)) %>%
  left_join(ra %>% transmute(a7, stratum = as.numeric(stratum)), by = "a7")
# Paper fn 40: one neighborhood assigned to CXL received Local; de facto assignment is used.
# Neighborhood 654: CXL in the schedule, but registration shows chief-only collectors and the
# endline survey codes it Local (all other CXL neighborhoods keep CXL coding).
nbh$tr[nbh$a7 == 654] <- 2
cat("Neighborhoods by de facto arm (0 Control,1 Central,2 Local,3 CLI,4 CXL):\n"); print(table(nbh$tr))

## ---------------- Property register ----------------
reg <- rd("admin_data/registration_noPII.dta",
          col_select = c(a7, compound1, start, tot_complete, house, exempt)) %>%
  filter(a7 %in% nbh$a7, tot_complete == 1) %>%          # drops the 8 pilot neighborhoods and incomplete forms
  filter(!duplicated(compound1)) %>%
  mutate(house = as.numeric(house), regdate = as.Date(start)) %>%
  filter(house %in% c(1, 2))                               # villas (house 3) are outside the campaign (fn 28)
roll <- rd("admin_data/taxroll_noPII.dta") %>% select(compound1, MontantIF, Exempte)
reg <- reg %>% left_join(roll, by = "compound1") %>% left_join(nbh, by = "a7")
reg$liab <- suppressWarnings(as.numeric(gsub("[^0-9]", "", reg$MontantIF)))
reg$exempt_any <- (as.numeric(reg$exempt) %in% 1) | (!is.na(reg$Exempte) & reg$Exempte != "")

## ---------------- Payments (receipt data) ----------------
tp <- rd("admin_data/tax_payments_noPII.dta") %>% filter(!is.na(compound1)) %>%
  select(compound1, amountCF) %>% group_by(compound1) %>% summarise(amountCF = sum(amountCF), .groups = "drop")
reg <- reg %>% left_join(tp %>% mutate(payrec = 1), by = "compound1")
reg$paid <- ifelse(is.na(reg$payrec), 0, 1)
amt <- reg$amountCF
bad <- reg$paid == 1 & (is.na(amt) | amt < 1500 | amt > 13200)   # data-entry errors in receipt amounts
cat("Payers with implausible/missing amount, replaced by the property's tax-roll liability:", sum(bad), "\n")
amt[bad] <- reg$liab[bad]
reg$revenue <- ifelse(reg$paid == 1, amt, 0)
reg$revenue[is.na(reg$revenue)] <- 0

## ---------------- Campaign-period (time) fixed effects, online App. A2.5 ----------------
# Neighborhood date = first registration day. For arms A and B: start = midpoint of their first days,
# end = midpoint of their last days; two-month periods from start; neighborhoods outside [start, end] drop.
nb_dates <- reg %>% group_by(a7) %>% summarise(d0 = min(regdate, na.rm = TRUE), d1 = max(regdate, na.rm = TRUE), tr = first(tr), .groups = "drop")
make_period <- function(armA, armB) {
  x <- nb_dates %>% filter(tr %in% c(armA, armB))
  fA <- min(x$d0[x$tr == armA]); fB <- min(x$d0[x$tr == armB])
  lA <- max(x$d1[x$tr == armA]); lB <- max(x$d1[x$tr == armB])
  st <- fA + as.numeric(fB - fA) / 2; en <- lA + as.numeric(lB - lA) / 2
  st <- as.Date(floor(as.numeric(st)), origin = "1970-01-01"); en <- as.Date(ceiling(as.numeric(en)), origin = "1970-01-01")
  brk <- seq(st, by = "2 months", length.out = 8)
  x$period <- findInterval(as.numeric(x$d0), as.numeric(brk))
  x$period[x$d0 < st | x$d0 > en] <- NA
  cat(sprintf("Periods arms %d vs %d: start %s end %s; neighborhoods kept %d of %d\n", armA, armB, st, en, sum(!is.na(x$period)), nrow(x)))
  print(table(arm = x$tr, period = x$period, useNA = "ifany"))
  x %>% select(a7, period)
}
per_LC <- make_period(1, 2)
per_CLI <- make_period(1, 3)

ct <- function(m, v) { b <- coef(m)[v]; s <- se(m)[v]; cat(sprintf("  %s: b=%.5f se=%.5f N=%d\n", v, b, s, nobs(m))); b }

## ---------------- Table 4: Local vs Central ----------------
lc <- reg %>% filter(tr %in% c(1, 2)) %>% mutate(local = as.numeric(tr == 2)) %>% left_join(per_LC, by = "a7")
cat("Local/Central properties:", nrow(lc), "\n")
m1 <- feols(paid ~ local | stratum, data = lc, cluster = ~a7)
lc2 <- lc %>% filter(!is.na(period))
m2 <- feols(paid ~ local | stratum + period, data = lc2, cluster = ~a7)
m4 <- feols(paid ~ local | stratum + period + house, data = lc2, cluster = ~a7)
m5 <- feols(paid ~ local | stratum + period + house, data = lc2 %>% filter(!exempt_any), cluster = ~a7)
r2 <- feols(revenue ~ local | stratum + period, data = lc2, cluster = ~a7)
r4 <- feols(revenue ~ local | stratum + period + house, data = lc2, cluster = ~a7)
cat("Table 4:\n")
b1 <- ct(m1, "local"); b2 <- ct(m2, "local"); b4 <- ct(m4, "local"); b5 <- ct(m5, "local"); br2 <- ct(r2, "local"); br4 <- ct(r4, "local")
cat(sprintf("  Means (col2 sample): Central compliance %.4f, Local %.4f\n", mean(lc2$paid[lc2$local == 0]), mean(lc2$paid[lc2$local == 1])))

## ---------------- Table 5 Panel B: paid bribe (endline) ----------------
el <- rd("survey_data/endline_round1_noPII.dta", col_select = c(a7, tot_complete, bribe)) %>%
  filter(tot_complete == 1) %>% mutate(bribe = as.numeric(bribe)) %>% filter(bribe %in% c(0, 1)) %>%
  left_join(nbh, by = "a7") %>% filter(tr %in% c(1, 2)) %>% mutate(local = as.numeric(tr == 2))
mb <- feols(bribe ~ local | stratum, data = el, cluster = ~a7)
cat("Table 5 paid bribe (endline):\n"); bb <- ct(mb, "local")

## ---------------- Table 6 col 1: visited by collector after registration (midline) ----------------
ml <- rd("survey_data/midline_noPII.dta", col_select = c(a7, compound, tot_complete, visited, visits)) %>%
  filter(tot_complete == 1) %>%
  mutate(visited = as.numeric(visited), visits = as.numeric(visits), visits = ifelse(visits > 100, NA, visits),
         postvisit = case_when(visited == 0 ~ 0, visits >= 2 ~ 1, visits %in% c(0, 1) ~ 0, TRUE ~ NA_real_)) %>%
  left_join(nbh, by = "a7") %>% filter(tr %in% c(1, 2)) %>% mutate(local = as.numeric(tr == 2)) %>%
  left_join(reg %>% select(compound = compound1, house), by = "compound") %>%
  left_join(per_LC, by = "a7")
mv <- feols(postvisit ~ local | house + stratum + period, data = ml, cluster = ~a7)
cat("Table 6 visited by collector:\n"); bv <- ct(mv, "local")

## ---------------- Table 7: CLI vs Central ----------------
cl <- reg %>% filter(tr %in% c(1, 3)) %>% mutate(cli = as.numeric(tr == 3)) %>% left_join(per_CLI, by = "a7") %>% filter(!is.na(period))
mc1 <- feols(paid ~ cli | house + stratum + period, data = cl, cluster = ~a7)
mc2 <- feols(revenue ~ cli | house + stratum + period, data = cl, cluster = ~a7)
cat("Table 7:\n"); bc1 <- ct(mc1, "cli"); bc2 <- ct(mc2, "cli")

## ---------------- Table 8 Panel A col 2: chief's ease-of-payment rating, CLI only ----------------
cc <- rd("survey_data/chief_consultations.dta", col_select = c(compound1, pay_ease)) %>%
  mutate(pay_ease = as.numeric(pay_ease)) %>% filter(pay_ease %in% c(0, 1, 2)) %>% filter(!duplicated(compound1))
cd <- reg %>% filter(tr == 3) %>% inner_join(cc, by = "compound1")
me <- feols(paid ~ pay_ease | house + stratum, data = cd, cluster = ~a7)
cat("Table 8 ease of payment:\n"); be <- ct(me, "pay_ease")

cat(sprintf("RESULT:compliance_local_table4_panelA_col1=%.6f\n", b1))
cat(sprintf("RESULT:compliance_local_table4_panelA_col2=%.6f\n", b2))
cat(sprintf("RESULT:compliance_local_house_fe_table4_panelA_col4=%.6f\n", b4))
cat(sprintf("RESULT:compliance_local_exempt_excluded_table4_panelA_col5=%.6f\n", b5))
cat(sprintf("RESULT:revenue_local_table4_panelB_col2=%.6f\n", br2))
cat(sprintf("RESULT:revenue_local_house_fe_table4_panelB_col4=%.6f\n", br4))
cat(sprintf("RESULT:n_obs_table4_col1=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_obs_table4_col2=%d\n", nobs(m2)))
cat(sprintf("RESULT:paid_bribe_endline_local_table5_panelB=%.6f\n", bb))
cat(sprintf("RESULT:visited_by_collector_local_table6_col1=%.6f\n", bv))
cat(sprintf("RESULT:compliance_cli_table7_col1=%.6f\n", bc1))
cat(sprintf("RESULT:revenue_cli_table7_col2=%.6f\n", bc2))
cat(sprintf("RESULT:compliance_ease_of_payment_cli_table8_panelA_col2=%.6f\n", be))
