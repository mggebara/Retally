suppressMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base/admin_data/"
desc <- function(f, maxv=200) {
  d <- read_dta(paste0(B, f))
  cat("\n=====", f, nrow(d), "x", ncol(d), "\n")
  for (v in names(d)[1:min(ncol(d),maxv)]) {
    x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    nu <- length(unique(x))
    ex <- if (is.numeric(x)) paste(signif(head(sort(unique(x)), 6),5), collapse=",") else paste(substr(head(unique(as.character(x)),4),1,25), collapse="|")
    cat(sprintf("%-28s %-8s nuniq=%-6d NA=%-6d [%s] %s\n", v, class(x)[1], nu, sum(is.na(x)), substr(lab,1,60), ex))
  }
  invisible(d)
}
for (f in c("randomization_assignment.dta","randomization_schedule.dta","stratum.dta","tax_payments_noPII.dta","tax_payment_timing_noPII.dta","taxroll_noPII.dta","campaign_2016_neighborhoods.dta","tax_payments_neighborhoods.dta")) desc(f)
desc("registration_noPII.dta")
