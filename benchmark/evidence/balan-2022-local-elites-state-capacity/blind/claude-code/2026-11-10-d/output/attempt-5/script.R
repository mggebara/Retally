suppressPackageStartupMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rd <- function(f, ...) read_dta(file.path(base, f), ...)
tb <- function(...) print(table(..., useNA = "ifany"))
ra <- rd("admin_data/randomization_assignment.dta") %>% mutate(treatment = as.numeric(zap_labels(treatment)))
rs <- rd("admin_data/randomization_schedule.dta")
reg <- rd("admin_data/registration_noPII.dta") %>% mutate(across(where(is.labelled), ~as.numeric(zap_labels(.x)))) %>%
  inner_join(ra %>% select(a7, treatment, stratum), by = "a7") %>% filter(pilot == 0, tot_complete == 1, house != 3)
reg <- reg %>% mutate(treat = ifelse(treatment == 4 & a7 %in% c(639, 654), 2, treatment), d = as.Date(start))
nb <- reg %>% group_by(a7, treat) %>% summarise(n = n(), nNAtoday = sum(is.na(today)), allNA = all(is.na(today)),
  dmin = min(d), dmin_t = suppressWarnings(min(today, na.rm = TRUE)), dmed = median(d), dmax = max(d),
  cpNA = mean(is.na(carto_pay)), .groups = "drop") %>% left_join(rs %>% select(a7, month), by = "a7")
cat("nbhds with all today NA by treat:\n"); tb(nb$allNA, nb$treat)
print(as.data.frame(nb %>% filter(allNA | nNAtoday > 0, treat %in% c(1,2,3)) %>% arrange(dmin)))
print(nb %>% filter(treat %in% 1:3) %>% group_by(treat) %>% summarise(f_start = min(dmin), f_today = min(dmin_t, na.rm=TRUE), l_start = max(dmin), l_today = max(dmin_t, na.rm=TRUE), lmax = max(dmax)))
# date spread within nbhd
nb <- nb %>% mutate(span = as.numeric(dmax - dmin))
print(summary(nb$span)); print(as.data.frame(nb %>% filter(span > 40) %>% arrange(desc(span))))
# compare start dates vs schedule month
print(as.data.frame(nb %>% filter(treat %in% 1:3) %>% group_by(treat, month) %>% summarise(n = n(), min = min(dmin), med = median(dmin), max = max(dmin), .groups="drop")))
# payments timing
tp <- rd("admin_data/tax_payments_noPII.dta")
tp2 <- tp %>% inner_join(reg %>% select(compound1, treat, a7r = a7, d), by = "compound1")
cat("matched payments", nrow(tp2), " in L/C:", sum(tp2$treat %in% 1:2), "\n")
tb(tp2$treat)
cat("payment date before registration date:", sum(tp2$date < tp2$d, na.rm=TRUE), "\n")
um <- tp %>% filter(!(compound1 %in% reg$compound1)); cat("unmatched payments", nrow(um), "\n")
um <- um %>% left_join(ra %>% select(a7, treatment), by = "a7"); tb(um$treatment); tb(um$unmatched_compound)
tb(zap_labels(tp$paid), tp$compound1 %in% reg$compound1)
tb(tp$error_code, tp$compound1 %in% reg$compound1)
# reg compound a7 consistency
cat("reg a7 != floor(compound/1000):", sum(reg$a7 != floor(reg$compound1/1000)), "\n")
