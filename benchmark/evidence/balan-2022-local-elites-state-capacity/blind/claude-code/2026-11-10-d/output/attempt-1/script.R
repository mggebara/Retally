suppressPackageStartupMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
showvars <- function(f, n = 5) {
  cat("\n=====", f, "\n")
  d <- read_dta(file.path(base, f), n_max = n)
  for (v in names(d)) {
    lb <- attr(d[[v]], "label"); if (is.null(lb)) lb <- ""
    cat(sprintf("%-30s %-10s %s | %s\n", v, class(d[[v]])[1], substr(lb, 1, 60),
                paste(head(as.character(d[[v]]), 3), collapse = ",")))
  }
}
for (f in c("admin_data/registration_noPII.dta", "admin_data/tax_payments_noPII.dta",
            "admin_data/randomization_assignment.dta", "admin_data/randomization_schedule.dta",
            "admin_data/stratum.dta", "admin_data/taxroll_noPII.dta",
            "admin_data/tax_payments_neighborhoods.dta", "admin_data/tax_payment_timing_noPII.dta",
            "survey_data/chief_consultations.dta")) showvars(f)
