suppressPackageStartupMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-b/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
desc <- function(f, n_rows = TRUE, maxv = 400) {
  cat("\n=================", f, "\n")
  d <- read_dta(file.path(base, f), n_max = if (n_rows) Inf else 0)
  cat("dim:", dim(d), "\n")
  nm <- names(d)[seq_len(min(length(names(d)), maxv))]
  for (v in nm) {
    x <- d[[v]]
    lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    nu <- length(unique(x))
    ex <- paste(head(unique(as.character(x)), 6), collapse = "|")
    cat(sprintf("%-28s [%s] nuniq=%d NA=%d | %s | %s\n", v, class(x)[1], nu, sum(is.na(x)), substr(lab, 1, 60), substr(ex, 1, 80)))
  }
  invisible(d)
}
desc("admin_data/registration_noPII.dta")
desc("admin_data/tax_payments_noPII.dta")
desc("admin_data/randomization_assignment.dta")
desc("admin_data/randomization_schedule.dta")
desc("admin_data/stratum.dta")
desc("admin_data/taxroll_noPII.dta")
desc("admin_data/tax_payment_timing_noPII.dta")
desc("admin_data/campaign_2016_neighborhoods.dta")
desc("survey_data/chief_consultations.dta")
