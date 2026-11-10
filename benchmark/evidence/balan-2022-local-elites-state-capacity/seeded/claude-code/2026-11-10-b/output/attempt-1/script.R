suppressPackageStartupMessages({library(haven); library(readxl)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/seeded/2026-11-10-b/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
A <- file.path(B, "admin_data"); S <- file.path(B, "survey_data")
show <- function(nm, d) {
  cat("=====", nm, nrow(d), "x", ncol(d), "\n")
  cl <- sapply(d, function(x) class(x)[1])
  cat(paste0(names(d), ":", cl, collapse = " "), "\n")
}
files <- list(
  campaign2016 = file.path(A, "campaign_2016_neighborhoods.dta"),
  sched = file.path(A, "randomization_schedule.dta"),
  stratum = file.path(A, "stratum.dta"),
  taxroll = file.path(A, "taxroll_noPII.dta"),
  taxpay = file.path(A, "tax_payments_noPII.dta"),
  consult = file.path(S, "chief_consultations.dta")
)
for (n in names(files)) show(n, read_dta(files[[n]]))
fl <- read_dta(file.path(A, "fliers_campaign.dta"))
show("fliers", fl)
for (i in 1:3) show(paste0("pilot", i), read_excel(file.path(A, sprintf("fliers_pilot_set%d.xlsx", i))))
reg <- read_dta(file.path(A, "registration_noPII.dta"))
show("registration", reg)
mid <- read_dta(file.path(S, "midline_noPII.dta"))
show("midline", mid)
cat("chefferies:\n"); print(head(read.csv(file.path(A, "concessions_chefferies.csv"))))
tp <- read_dta(files$taxpay)
print(summary(tp$compound1)); print(table(tp$unmatched_compound, useNA = "a"))
tpk <- tp[!(tp$unmatched_compound %in% 1) & !is.na(tp$compound1), ]
cat("taxpay dup compound:", sum(duplicated(tpk$compound1)), "\n")
print(table(reg$tot_complete, useNA = "a"))
cat("reg dup compound1 among complete:", sum(duplicated(reg$compound1[reg$tot_complete %in% 1])), "\n")
for (v in c("house", "code_same", "mm_rate", "pay_ease", "willingness", "exempt", "exempt_other", "pilot", "stratum", "a7", "visited", "visits", "tmt"))
  cat(v, ": reg", v %in% names(reg), " mid", v %in% names(mid), " taxroll", v %in% names(read_dta(files$taxroll)), " tp", v %in% names(tp), " fl", v %in% names(fl), "\n")
print(table(reg$house, useNA = "a"))
print(class(reg$today)); print(head(reg$today)); print(class(tp$date)); print(head(tp$date))
