# Exploratory: list variables and labels in key files (no estimates)
suppressMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-b/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
desc <- function(f, show = FALSE) {
  d <- read_dta(file.path(B, f), n_max = if (show) Inf else 0)
  cat("\n=====", f, "ncol", ncol(d), if (show) paste("nrow", nrow(d)) else "", "\n")
  labs <- sapply(d, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
  cls <- sapply(d, function(x) class(x)[1])
  for (i in seq_along(labs)) cat(sprintf("%s [%s] %s\n", names(d)[i], cls[i], substr(labs[i], 1, 80)))
  invisible(d)
}
small <- c("admin_data/randomization_assignment.dta","admin_data/randomization_schedule.dta","admin_data/stratum.dta",
           "admin_data/tax_payments_neighborhoods.dta","admin_data/tax_payments_noPII.dta","admin_data/taxroll_noPII.dta",
           "admin_data/tax_payment_timing_noPII.dta","survey_data/chief_consultations.dta","admin_data/campaign_2016_neighborhoods.dta")
options(width = 250)
for (f in small) {
  d <- desc(f, show = TRUE)
  dd <- as.data.frame(lapply(d, function(x) if (is.labelled(x)) as.vector(x) else x))
  print(head(dd[, 1:min(30, ncol(dd))], 4))
}
d <- desc("admin_data/registration_noPII.dta")
