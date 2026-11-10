suppressPackageStartupMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rd <- function(f, ...) read_dta(file.path(base, f), ...)
tb <- function(...) print(table(..., useNA = "ifany"))
labs <- function(x) { l <- attr(x, "labels"); if (!is.null(l)) print(l) }
ra <- rd("admin_data/randomization_assignment.dta") %>% mutate(treatment = as.numeric(zap_labels(treatment)))
rs <- rd("admin_data/randomization_schedule.dta")
print(as.data.frame(rs %>% filter(a7 %in% c(639, 654, 374))))
print(as.data.frame(rs %>% filter(treatment == 4) %>% head(5)))
print(as.data.frame(rs %>% filter(treatment == 2) %>% head(3)))

listvars <- function(f, pat = NULL) {
  d <- rd(f, n_max = 3)
  cat("\n=====", f, ncol(d), "cols\n")
  for (v in names(d)) {
    lb <- attr(d[[v]], "label"); if (is.null(lb)) lb <- ""
    if (is.null(pat) || grepl(pat, v, ignore.case = TRUE) || grepl(pat, lb, ignore.case = TRUE))
      cat(sprintf("%-28s %s\n", v, substr(lb, 1, 90)))
  }
}
listvars("survey_data/midline_noPII.dta")
pat <- "transport|bribe|a7|compound|tmt|treat|stratum|polygon|code|date|today|visit|paid|tax_id|house"
listvars("survey_data/endline_round1_noPII.dta", pat)
listvars("survey_data/endline_round2_noPII.dta", pat)

mid <- rd("survey_data/midline_noPII.dta", col_select = c(any_of(c("a7","compound1","month","visited","visits","today","tmt","house","exempt"))))
cat("midline rows", nrow(mid), "\n"); print(names(mid))
for (v in intersect(c("month","visited","visits","tmt","house"), names(mid))) { cat("--", v, "\n"); labs(mid[[v]]); tb(zap_labels(mid[[v]])) }
mid <- left_join(mid, ra %>% select(a7, treatment), by = "a7") %>% left_join(rs %>% select(a7, smonth = month), by = "a7")
if ("month" %in% names(mid)) { tb(zap_labels(mid$month), mid$treatment); tb(zap_labels(mid$month), mid$smonth) }
