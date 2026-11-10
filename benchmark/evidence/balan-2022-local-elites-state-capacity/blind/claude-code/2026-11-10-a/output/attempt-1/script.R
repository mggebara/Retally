suppressMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-a/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
desc <- function(d, maxlev = 12) {
  for (v in names(d)) {
    x <- d[[v]]
    lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    nu <- length(unique(x))
    cat(sprintf("  %-30s %-10s nuniq=%-6d NA=%-6d | %s\n", v, class(x)[1], nu, sum(is.na(x)), substr(lab, 1, 70)))
    if (nu <= maxlev) { tb <- table(as_factor(x, levels = "both"), useNA = "ifany"); cat("     ", paste(names(tb), tb, sep = ":", collapse = "  "), "\n") }
    else if (is.numeric(x)) cat("      range", paste(signif(range(x, na.rm = TRUE), 6), collapse = " .. "), "\n")
    else cat("      e.g.", paste(head(unique(x), 4), collapse = " | "), "\n")
  }
}
f <- function(p, ...) { cat("\n=====", p, "\n"); d <- read_dta(file.path(B, p), ...); cat("rows", nrow(d), "cols", ncol(d), "\n"); d }
for (p in c("admin_data/randomization_schedule.dta", "admin_data/randomization_assignment.dta", "admin_data/stratum.dta",
            "admin_data/tax_payments_noPII.dta", "admin_data/tax_payment_timing_noPII.dta", "admin_data/campaign_2016_neighborhoods.dta")) {
  d <- f(p); desc(d)
}
d <- f("admin_data/registration_noPII.dta"); desc(d)
d <- f("admin_data/taxroll_noPII.dta"); desc(d)
d <- f("survey_data/chief_consultations.dta"); desc(d)
