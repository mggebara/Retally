# Exploratory run 1: inspect variables of key data files (no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
desc <- function(f, cols = NULL, full = FALSE) {
  cat("\n==========", f, "\n")
  d <- read_dta(file.path(B, f), col_select = if (is.null(cols)) everything() else any_of(cols))
  cat("rows:", nrow(d), " cols:", ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    nu <- length(unique(x))
    s <- if (is.numeric(x)) sprintf("num min=%s max=%s mean=%s NA=%d", signif(min(x, na.rm=TRUE),4), signif(max(x, na.rm=TRUE),4), signif(mean(x, na.rm=TRUE),4), sum(is.na(x)))
         else sprintf("chr ex=%s", paste(head(unique(as.character(x)), 4), collapse=" | "))
    cat(sprintf("%-28s nu=%-6d %s :: %s\n", v, nu, s, substr(lab, 1, 80)))
    vl <- attr(x, "labels"); if (!is.null(vl) && length(vl) <= 12) cat("     labels:", paste(names(vl), vl, sep="=", collapse="; "), "\n")
  }
  invisible(d)
}
desc("admin_data/randomization_assignment.dta")
desc("admin_data/randomization_schedule.dta")
desc("admin_data/stratum.dta")
desc("admin_data/tax_payments_noPII.dta")
desc("admin_data/tax_payments_neighborhoods.dta")
desc("admin_data/taxroll_noPII.dta")
desc("admin_data/registration_noPII.dta")
desc("survey_data/chief_consultations.dta")
desc("admin_data/tax_payment_timing_noPII.dta")
