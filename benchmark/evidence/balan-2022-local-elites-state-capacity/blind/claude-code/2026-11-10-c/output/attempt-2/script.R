suppressMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base/admin_data/"
ra <- read_dta(paste0(B, "randomization_assignment.dta"))
print(attr(ra$treatment, "labels")); print(table(ra$treatment))
rs <- read_dta(paste0(B, "randomization_schedule.dta"))
print(table(rs$treatment, rs$month))
print(all(rs$treatment == ra$treatment[match(rs$a7, ra$a7)]))
reg <- read_dta(paste0(B, "registration_noPII.dta"))
for (v in c("house","exempt","tot_complete","dup_poly","pilot","who","carto_pay","first","tmt","correct","collect_success","double_sensi")) {
  cat("\n--", v, "\n"); print(attr(reg[[v]], "labels")); print(table(reg[[v]], useNA="always"))
}
cat("\nin rand a7:", sum(reg$a7 %in% ra$a7), " a7_compound in rand:", sum(reg$a7_compound %in% ra$a7), "\n")
cat("a7==a7_compound:", sum(reg$a7 == reg$a7_compound), " a7==a7b:", sum(reg$a7 == reg$a7b, na.rm=TRUE), "\n")
cat("dup compound1:", sum(duplicated(reg$compound1)), "\n")
print(table(tmt = reg$tmt, trt = ra$treatment[match(reg$a7, ra$a7)], useNA="always"))
print(table(pilot=reg$pilot, tc=reg$tot_complete))
print(table(house=reg$house, tc=reg$tot_complete))
r2 <- reg %>% filter(a7 %in% ra$a7, pilot==0)
cat("n in rand & non pilot", nrow(r2), " uniq compound", length(unique(r2$compound1)), "\n")
r3 <- r2 %>% filter(tot_complete==1); cat("tot_complete==1:", nrow(r3), length(unique(r3$compound1)), "\n")
print(table(trt=ra$treatment[match(r3$a7, ra$a7)], house=r3$house))
# compound1 structure
cat("compound1 / 1000 vs a7:", mean(floor(r3$compound1/1000) == r3$a7), "\n")
print(head(r3$compound1, 30))
tp <- read_dta(paste0(B, "tax_payments_noPII.dta"))
cat("\npayments\n"); print(attr(tp$paid, "labels")); print(table(tp$paid, useNA="always"))
print(table(tp$error_code, useNA="always")); print(table(tp$unmatched_compound, useNA="always")); print(table(tp$dup_receipt, useNA="always")); print(table(tp$mult_tax, useNA="always"))
print(table(tp$amountCF, useNA="always")); print(table(tp$house, useNA="always")); print(table(tp$lateCollection, useNA="always"))
cat("tp compound in reg:", sum(tp$compound1 %in% r3$compound1), " dup compound:", sum(duplicated(tp$compound1[!is.na(tp$compound1)])), "\n")
print(summary(tp$date)); print(table(tp$Villas, useNA="always"))
print(table(tp$rate_verified))
# dates by neighborhood
nb <- r3 %>% group_by(a7) %>% summarise(d0 = min(today, na.rm=TRUE), d1 = max(today, na.rm=TRUE), n=n()) %>%
  mutate(trt = ra$treatment[match(a7, ra$a7)], month = rs$month[match(a7, rs$a7)])
print(nb %>% group_by(trt) %>% summarise(n=n(), first=min(d0), last=max(d0), lastend=max(d1), props=sum(n)))
print(table(nb$month, format(nb$d0, "%Y-%m"), nb$trt))
print(table(is.na(r3$today)));
