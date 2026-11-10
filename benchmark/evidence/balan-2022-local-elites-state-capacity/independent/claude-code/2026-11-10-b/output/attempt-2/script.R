# Exploratory: registration structure, timing, payments (no estimates)
suppressMessages({library(haven); library(dplyr)})
options(width = 220)
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-b/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rg <- read_dta(file.path(B, "admin_data/registration_noPII.dta"),
  col_select = c(today, a7, a7b, tmt, carto_pay, first, who, house, house_correct, compound1, compound2, exempt, exempt_enum,
                 collect_success, amt_paid, a7_compound, date_f, month_tmpp, day_tmpp, tot_complete, double_sensi, dup_poly, pilot, type, keep, present, status))
tb <- function(...) print(table(..., useNA = "ifany"))
cat("nrow", nrow(rg), "\n")
for (v in c("tmt","carto_pay","pilot","dup_poly","double_sensi","keep","house","exempt","collect_success","amt_paid","month_tmpp","type","tot_complete"))
{ cat("\n--", v, "\n"); tb(as.vector(rg[[v]])) }
print(attr(rg$house, "labels")); print(attr(rg$exempt, "labels")); print(attr(rg$carto_pay, "labels")); print(attr(rg$amt_paid, "labels"))
cat("\n-- tmt x carto_pay\n"); tb(rg$tmt, as.vector(rg$carto_pay))
cat("\n-- tmt x pilot\n"); tb(rg$tmt, rg$pilot)
cat("\n-- tmt x house\n"); tb(rg$tmt, as.vector(rg$house))
cat("compound1 NA:", sum(is.na(rg$compound1)), " dup compound1:", sum(duplicated(rg$compound1[!is.na(rg$compound1)])), "\n")
cat("a7_compound NA:", sum(is.na(rg$a7_compound)), " dup:", sum(duplicated(rg$a7_compound[!is.na(rg$a7_compound)])), "\n")
print(head(as.data.frame(rg[, c("a7","compound1","a7_compound","today","date_f","month_tmpp","day_tmpp")]), 5))
# neighborhood level timing
nb <- rg %>% group_by(a7) %>% summarise(tmt = first(tmt), n = n(), d0 = min(today, na.rm=TRUE), d1 = max(today, na.rm=TRUE),
   df0 = min(date_f, na.rm=TRUE), m = min(month_tmpp, na.rm=TRUE), pilot = max(pilot, na.rm=TRUE))
cat("neighborhoods:", nrow(nb), "\n"); tb(nb$tmt)
print(nb %>% group_by(tmt) %>% summarise(n = n(), props = sum(n), first = min(d0), last = max(d0), lastmax = max(d1)))
print(as.data.frame(nb %>% arrange(d0)), max = 2000)
ra <- read_dta(file.path(B, "admin_data/randomization_assignment.dta"))
rs <- read_dta(file.path(B, "admin_data/randomization_schedule.dta"))
tp <- read_dta(file.path(B, "admin_data/tax_payments_neighborhoods.dta"))
cat("\n-- assignment treatment\n"); tb(as.vector(ra$treatment))
cat("\n-- schedule treatment x month\n"); tb(rs$treatment, rs$month)
x <- ra %>% select(a7, treatment, stratum) %>% left_join(rs %>% select(a7, month, ttt = treatment), by = "a7") %>%
  left_join(tp %>% select(a7, program_start, stratum_tp = stratum, program, nganza), by = "a7") %>% left_join(nb, by = "a7")
cat("\n-- assignment vs reg tmt\n"); tb(as.vector(x$treatment), x$tmt)
cat("\n-- schedule ttt vs assignment\n"); tb(as.vector(x$treatment), x$ttt)
cat("stratum equal:", sum(x$stratum == x$stratum_tp, na.rm=TRUE), "\n")
print(as.data.frame(x %>% select(a7, treatment, tmt, month, program_start, d0, d1, n) %>% arrange(program_start)), max = 3000)
pay <- read_dta(file.path(B, "admin_data/tax_payments_noPII.dta"))
cat("\n-- payments\n")
for (v in c("paid","house","Villas","error_code","dup_receipt","mult_tax","rate_verified","amountCF","lateCollection","unmatched_compound","error_rate","Peripherie","Maison_Moyenne"))
{ cat("\n--", v, "\n"); tb(as.vector(pay[[v]])) }
cat("dup compound1 in payments:", sum(duplicated(pay$compound1)), "\n")
cat("payments compound1 in reg:", sum(pay$compound1 %in% rg$compound1), "of", nrow(pay), "\n")
print(summary(pay$date))
