# Exploratory: inspect admin data files (no estimates)
suppressMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-a/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
desc <- function(f, maxv = 200) {
  cat("\n=========", f, "\n")
  d <- read_dta(file.path(B, f))
  cat("rows", nrow(d), "cols", ncol(d), "\n")
  for (v in head(names(d), maxv)) {
    x <- d[[v]]
    lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    nu <- length(unique(x))
    ex <- paste(head(unique(as.character(zap_labels(x))), 6), collapse = " | ")
    vl <- attr(x, "labels")
    vls <- if (!is.null(vl)) paste0(" {", paste(paste0(vl, "=", names(vl)), collapse = ";"), "}") else ""
    cat(sprintf("%-28s %-8s nuniq=%-6d NA=%-6d [%s] %s%s\n", v, class(x)[1], nu, sum(is.na(x)), substr(lab, 1, 60), substr(ex, 1, 90), substr(vls, 1, 200)))
  }
  invisible(d)
}
for (f in c("admin_data/randomization_assignment.dta", "admin_data/randomization_schedule.dta",
            "admin_data/stratum.dta", "admin_data/tax_payments_noPII.dta",
            "admin_data/tax_payments_neighborhoods.dta", "admin_data/taxroll_noPII.dta",
            "admin_data/registration_noPII.dta", "admin_data/tax_payment_timing_noPII.dta",
            "admin_data/campaign_2016_neighborhoods.dta",
            "survey_data/chief_consultations.dta")) {
  tryCatch(desc(f), error = function(e) cat("ERR", f, conditionMessage(e), "\n"))
}
