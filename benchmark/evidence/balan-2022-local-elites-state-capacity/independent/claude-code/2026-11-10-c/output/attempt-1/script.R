# Exploratory run: inspect structure of admin data files (no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
desc <- function(f, n_max = Inf, maxvars = 200) {
  cat("\n\n==========", f, "==========\n")
  d <- read_dta(file.path(B, f), n_max = n_max)
  cat("dim:", dim(d), "\n")
  vs <- names(d)[seq_len(min(length(d), maxvars))]
  for (v in vs) {
    x <- d[[v]]
    lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    vl <- attr(x, "labels")
    nu <- length(unique(x))
    s <- if (is.numeric(x)) sprintf("num min=%s max=%s mean=%s NA=%d", signif(min(x, na.rm=TRUE),5), signif(max(x, na.rm=TRUE),5), signif(mean(x, na.rm=TRUE),5), sum(is.na(x))) else {
      ux <- head(unique(as.character(x)), 4); paste0("chr ex: ", paste(substr(ux,1,25), collapse=" | "), " empty=", sum(is.na(x) | x == ""))
    }
    cat(sprintf("%-28s nu=%-6d %s | %s", v, nu, substr(lab,1,60), s))
    if (!is.null(vl) && length(vl) <= 12) cat(" | labels:", paste(names(vl), vl, sep="=", collapse="; "))
    cat("\n")
  }
  invisible(d)
}
options(warn = 1)
for (f in c("admin_data/randomization_assignment.dta", "admin_data/stratum.dta", "admin_data/randomization_schedule.dta",
            "admin_data/tax_payments_noPII.dta", "admin_data/tax_payments_neighborhoods.dta", "admin_data/taxroll_noPII.dta",
            "admin_data/registration_noPII.dta", "admin_data/tax_payment_timing_noPII.dta", "survey_data/chief_consultations.dta",
            "admin_data/campaign_2016_neighborhoods.dta")) {
  tryCatch(desc(f), error = function(e) cat("ERROR", conditionMessage(e), "\n"))
}
