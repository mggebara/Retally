# Exploratory run 3: sample construction checks (no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
ra <- zap_labels(read_dta(file.path(B, "admin_data/randomization_assignment.dta")))
rs <- zap_labels(read_dta(file.path(B, "admin_data/randomization_schedule.dta")))
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta")))
tr <- zap_labels(read_dta(file.path(B, "admin_data/taxroll_noPII.dta")))
tp <- zap_labels(read_dta(file.path(B, "admin_data/tax_payments_noPII.dta")))
rg <- merge(rg, ra[, c("a7","treatment","stratum")], by = "a7")
rg <- merge(rg, rs[, c("a7","month")], by = "a7")
# misassigned neighborhood: CXL nb where 'who' mostly chief only
w <- rg %>% filter(treatment == 4) %>% group_by(a7) %>% summarise(n = n(), chief = mean(who == 1, na.rm=TRUE), both = mean(who == 2, na.rm=TRUE), tmtm = mean(tmt, na.rm=TRUE))
print(as.data.frame(w %>% arrange(both) %>% head(6)))
w2 <- rg %>% filter(treatment == 2) %>% group_by(a7) %>% summarise(n = n(), chief = mean(who == 1, na.rm=TRUE), both = mean(who == 2, na.rm=TRUE))
print(summary(w2$chief))
d <- rg %>% filter(house %in% c(1,2))
cat("house12 by trt:\n"); print(table(d$treatment))
cat("in taxroll:\n"); print(table(d$treatment, d$compound1 %in% tr$compound1))
cat("dup compound within house12:", sum(duplicated(d$compound1)), "\n")
cat("taxroll dup:", sum(duplicated(tr$compound1)), " taxroll a7 in 356:", sum(tr$a7 %in% ra$a7), "\n")
tr2 <- merge(tr[, c("compound1","a7")], ra[, c("a7","treatment")], by = "a7")
cat("taxroll by trt:\n"); print(table(tr2$treatment))
rgall <- rg
cat("registration (all houses) compound in taxroll by house:\n"); print(table(rgall$house, rgall$compound1 %in% tr$compound1))
# taxroll compounds not in registration
cat("taxroll not in registration:", sum(!tr2$compound1 %in% rg$compound1), "\n")
tr2$inreg <- tr2$compound1 %in% rg$compound1
print(table(tr2$treatment, tr2$inreg))
# combos
dd <- d[!duplicated(d$compound1), ]
dd <- dd[dd$compound1 %in% tr$compound1, ]
cat("house12 dedup in taxroll:\n"); print(table(dd$treatment))
# taxroll merged with registration house; taxroll properties lacking registration: count with house unknown
cat("taxroll in 356, minus registration villas:\n")
vill <- rg$compound1[rg$house == 3]
print(table(tr2$treatment[!tr2$compound1 %in% vill]))
# dates
d$dt <- as.Date(d$today)
fd <- d %>% group_by(treatment) %>% summarise(first = min(dt, na.rm=TRUE), last = max(dt, na.rm=TRUE))
print(fd)
nb <- d %>% group_by(a7, treatment, month) %>% summarise(n = n(), dmin = min(dt), dmed = median(dt), dmax = max(dt), .groups="drop")
cat("neighborhood start dates, central + local, earliest 15:\n")
print(as.data.frame(nb %>% filter(treatment %in% c(1,2)) %>% arrange(dmin) %>% head(15)))
cat("latest 15 by dmin:\n")
print(as.data.frame(nb %>% filter(treatment %in% c(1,2)) %>% arrange(desc(dmin)) %>% head(15)))
cat("CLI nb dates earliest/latest:\n")
print(as.data.frame(nb %>% filter(treatment == 3) %>% arrange(dmin) %>% head(5)))
print(as.data.frame(nb %>% filter(treatment == 3) %>% arrange(desc(dmin)) %>% head(5)))
# payments
tp$inreg <- tp$compound1 %in% d$compound1
cat("payment amounts by paid flag:\n"); print(table(tp$amountCF, tp$paid, useNA="a"))
cat("error_code x inreg:\n"); print(table(tp$error_code, tp$inreg, useNA="a"))
cat("lateCollection x inreg:\n"); print(table(tp$lateCollection, tp$inreg, useNA="a"))
cat("payment a7 vs compound prefix equal:", sum(tp$a7 == tp$compound1 %/% 1000, na.rm=TRUE), "\n")
# midline
md <- zap_labels(read_dta(file.path(B, "survey_data/midline_noPII.dta"), col_select = c(a7, compound, treatment, month, visited, visits, tot_complete, pilot, dup_real, dup_compound, unknown_compound, monitoring_survey_twice, exempt, present, today)))
cat("\nmidline compound range:", range(md$compound, na.rm=TRUE), "\n")
print(table(md$visited, useNA="a")); print(summary(md$visits)); print(table(md$treatment, useNA="a"))
print(table(md$tot_complete, useNA="a")); print(table(md$dup_real, useNA="a")); print(table(md$dup_compound, useNA="a")); print(table(md$pilot, useNA="a")); print(table(md$unknown_compound, useNA="a")); print(table(md$monitoring_survey_twice, useNA="a"))
md$compound1 <- ifelse(md$compound < 1e5, md$a7 * 1000 + md$compound, md$compound)
cat("midline compound1 in reg:", sum(md$compound1 %in% d$compound1), " raw compound in reg:", sum(md$compound %in% d$compound1), "\n")
# chief consultations
cc <- zap_labels(read_dta(file.path(B, "survey_data/chief_consultations.dta"), col_select = c(a7, compound1, pay_ease, willingness, `_merge`)))
cat("cc pay_ease:\n"); print(table(cc$pay_ease, useNA="a")); print(table(cc$`_merge`))
cat("cc in reg house12:", sum(cc$compound1 %in% d$compound1), " dup:", sum(duplicated(cc$compound1)), "\n")
x <- merge(d[, c("compound1","treatment","a7")], cc[, c("compound1","pay_ease")], by = "compound1")
print(table(x$treatment, x$pay_ease, useNA="a"))
# endline round 1
e1 <- zap_labels(read_dta(file.path(B, "survey_data/endline_round1_noPII.dta"), col_select = c(a7, treatment, code, compound_code, bribe, dup_respondent, dup_compound, paid_self)))
cat("\nendline1 treatment:\n"); print(table(e1$treatment, useNA="a"))
print(table(e1$bribe, e1$treatment, useNA="a"))
print(table(e1$dup_respondent, useNA="a")); print(table(e1$dup_compound, useNA="a"))
e1b <- merge(e1, ra[, c("a7","treatment")], by = "a7", suffixes = c("", ".ra"))
print(table(e1b$treatment, e1b$treatment.ra, useNA="a"))
