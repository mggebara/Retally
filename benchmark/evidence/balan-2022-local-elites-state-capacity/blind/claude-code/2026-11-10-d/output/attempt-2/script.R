suppressPackageStartupMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rd <- function(f, ...) read_dta(file.path(base, f), ...)
tb <- function(x) print(table(x, useNA = "ifany"))
labs <- function(x) { l <- attr(x, "labels"); if (!is.null(l)) print(l) }

reg <- rd("admin_data/registration_noPII.dta")
cat("reg rows", nrow(reg), "\n")
for (v in c("carto_pay","first","tot_complete","dup_poly","pilot","house","exempt","tmt","who","double_sensi")) {
  cat("--", v, "\n"); labs(reg[[v]]); tb(zap_labels(reg[[v]])) }
cat("unique compound1", n_distinct(reg$compound1), " NA:", sum(is.na(reg$compound1)), "\n")
cat("unique a7", n_distinct(reg$a7), "\n")
print(table(reg$carto_pay, reg$tot_complete, useNA="ifany"))
r0 <- reg %>% filter(carto_pay == 0)
cat("carto rows", nrow(r0), " unique compound1", n_distinct(r0$compound1), "\n")
cat("dups of compound1 among carto rows:", sum(duplicated(r0$compound1)), "\n")
print(summary(r0$today))
print(table(r0$tmt, r0$pilot, useNA="ifany"))
print(table(r0$tmt, r0$dup_poly, useNA="ifany"))

ra <- rd("admin_data/randomization_assignment.dta")
labs(ra$treatment); tb(zap_labels(ra$treatment))
tm <- r0 %>% group_by(a7) %>% summarise(tmt = paste(sort(unique(tmt)), collapse="/"), n = n())
x <- left_join(tm, ra %>% select(a7, treatment, stratum), by = "a7")
print(table(x$tmt, zap_labels(x$treatment), useNA="ifany"))
cat("strata", n_distinct(ra$stratum), "\n")
st <- rd("admin_data/stratum.dta"); cat("stratum.dta n", nrow(st), "\n")
y <- left_join(ra %>% select(a7, stratum), st %>% select(a7, s2 = stratum), by="a7"); cat("stratum agree", mean(y$stratum == y$s2, na.rm=TRUE), "\n")

rs <- rd("admin_data/randomization_schedule.dta")
cat("schedule rows", nrow(rs), " unique a7", n_distinct(rs$a7), "\n")
print(table(rs$treatment, rs$month, useNA = "ifany"))
print(head(rs, 3))

tpn <- rd("admin_data/tax_payments_neighborhoods.dta")
print(summary(tpn$program_start)); print(table(format(tpn$program_start, "%Y-%m"), useNA="ifany"))
z <- left_join(tpn %>% select(a7, program_start, program, stratum), ra %>% select(a7, treatment), by="a7")
print(table(format(z$program_start, "%Y-%m"), zap_labels(z$treatment), useNA="ifany"))
print(table(format(z$program_start, "%Y-%m-%d"), zap_labels(z$treatment), useNA="ifany"))
zz <- left_join(z, rs %>% select(a7, month), by = "a7")
print(table(zz$month, format(zz$program_start, "%Y-%m"), useNA="ifany"))

tp <- rd("admin_data/tax_payments_noPII.dta")
cat("tax payments rows", nrow(tp), " unique compound1", n_distinct(tp$compound1), "\n")
labs(tp$paid); tb(zap_labels(tp$paid)); tb(tp$house); tb(tp$amountCF)
for (v in c("error_code","unmatched_compound","dup_receipt","mult_tax","rate_verified","lateCollection","Villas","Peripherie","Maison_Moyenne","error_rate")) { cat("--", v, "\n"); tb(tp[[v]]) }
print(summary(tp$date))
cat("payments compound in carto reg:", mean(tp$compound1 %in% r0$compound1), "\n")
cat("payment a7 == floor(compound1/1000)?", mean(tp$a7 == floor(tp$compound1/1000), na.rm=TRUE), "\n")
cat("reg a7 == floor(compound1/1000)?", mean(r0$a7 == floor(r0$compound1/1000), na.rm=TRUE), "\n")

cc <- rd("survey_data/chief_consultations.dta")
cat("cc rows", nrow(cc), " unique compound1", n_distinct(cc$compound1), " a7", n_distinct(cc$a7), "\n")
labs(cc$pay_ease); tb(zap_labels(cc$pay_ease)); labs(cc$willingness); tb(zap_labels(cc$willingness))
tb(zap_labels(cc$`_merge`)); tb(cc$dup_code); tb(cc$tot_complete_cc)

tr <- rd("admin_data/taxroll_noPII.dta"); cat("taxroll rows", nrow(tr), " a7", n_distinct(tr$a7), "\n")
