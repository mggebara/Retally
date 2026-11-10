suppressMessages({library(haven); library(dplyr)})
R <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base/"
B <- paste0(R, "admin_data/"); S <- paste0(R, "survey_data/")
options(width=200)
ra <- read_dta(paste0(B, "randomization_assignment.dta"))
reg <- read_dta(paste0(B, "registration_noPII.dta"))
r3 <- reg %>% filter(a7 %in% ra$a7, pilot==0, tot_complete==1, house %in% c(1,2))
tp <- read_dta(paste0(B, "tax_payments_noPII.dta"))
print(table(err=tp$error_code, inreg=tp$compound1 %in% r3$compound1, useNA="always"))
print(table(amt=tp$amountCF, err=tp$error_code, useNA="always"))
print(table(unm=tp$unmatched_compound, inreg=tp$compound1 %in% r3$compound1, useNA="always"))
print(table(late=tp$lateCollection, err=tp$error_code, useNA="always"))
print(table(paid=tp$paid, err=tp$error_code, useNA="always"))
print(table(format(tp$date, "%Y-%m"), tp$error_code, useNA="always"))
# a7 consistency between payment and registration
m <- tp %>% filter(compound1 %in% r3$compound1) %>% mutate(ra7 = r3$a7[match(compound1, r3$compound1)])
cat("payment a7 == reg a7:", mean(m$a7 == m$ra7, na.rm=TRUE), "\n")
# compare payment amount with house type
m$house <- r3$house[match(m$compound1, r3$compound1)]
print(table(m$amountCF, m$house))
# exempt payers
m$exempt <- r3$exempt[match(m$compound1, r3$compound1)]
print(table(m$exempt, useNA="always"))
print(table(exempt=r3$exempt, house=r3$house, useNA="always"))
