# Exploratory: inspect variables (no estimates printed)
suppressPackageStartupMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/seeded/2026-11-10-a/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
cat(names(d), sep = " "); cat("\n")
cat("nrow", nrow(d), "\n")
print(table(d$non_response, useNA = "ifany"))
d <- d[d$non_response == 0, ]
for (v in c("dif", "before1955", "modate", "education", "ethnicity", "female", "survey_taker_id")) {
  cat("---", v, "class", class(d[[v]]), "NA:", sum(is.na(d[[v]])), "\n")
}
print(summary(d$dif))
print(table(d$before1955, d$dif <= 0, useNA = "ifany"))
print(head(d[, grep("^di1|^dif|^modate", names(d))], 10))
print(sapply(d[, grep("^di1", names(d))], function(x) summary(as.numeric(x))))
print(table(d$education, useNA = "ifany")); print(table(d$ethnicity, useNA = "ifany"))
cat("month_ cols:", grep("^month_", names(d), value = TRUE), "\n")
cat("province cols:", length(grep("^province_n_", names(d))), "\n")
print(sum(is.na(d$province_n)))
w <- abs(d$dif) <= 45
cat("in bw45:", sum(w), "\n")
print(colSums(is.na(d[w, c("outside_week", "under_curfew", "never_out")])))
