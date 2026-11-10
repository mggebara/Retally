# Exploratory 8: endline and midline survey variables (no estimates)
suppressMessages({library(haven); library(dplyr)})
options(width = 250)
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-a/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rs <- zap_labels(read_dta(file.path(B, "admin_data/randomization_schedule.dta")))
show <- function(d, pat) {
  v <- names(d)[grepl(pat, names(d), ignore.case = TRUE) | sapply(d, function(x) { l <- attr(x, "label"); !is.null(l) && grepl(pat, l, ignore.case = TRUE) })]
  for (vv in v) {
    x <- d[[vv]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    vl <- attr(x, "labels"); vls <- if (!is.null(vl)) paste0(" {", paste(paste0(vl, "=", names(vl)), collapse = ";"), "}") else ""
    tb <- table(zap_labels(x), useNA = "ifany"); tbs <- if (length(tb) <= 12) paste(names(tb), tb, sep = ":", collapse = " ") else paste("nuniq", length(tb), "NA", sum(is.na(x)))
    cat(sprintf("  %-26s [%s]%s\n      %s\n", vv, substr(lab, 1, 110), substr(vls, 1, 160), substr(tbs, 1, 200)))
  }
}
for (f in c("survey_data/endline_round1_noPII.dta", "survey_data/endline_round2_noPII.dta")) {
  d <- read_dta(file.path(B, f))
  cat("\n=====", f, nrow(d), "rows\n")
  show(d, "^a7$|compound|^today$|^start$|transport|bribe|visited|^visits$|paid_self|tmt|treat|polygon|respondent|survey_e$|^date")
  if ("a7" %in% names(d)) { dd <- zap_labels(d) %>% left_join(rs[, c("a7", "treatment")], by = "a7"); print(table(dd$treatment, useNA = "ifany")) }
  if ("today" %in% names(d)) print(range(d$today, na.rm = TRUE))
}
d <- read_dta(file.path(B, "survey_data/midline_noPII.dta"))
cat("\n===== midline", nrow(d), "rows\n")
show(d, "^a7$|compound|^today$|^month$|visited|^visits$|tot_complete|sample_select|exempt|^first$|record$|dup|consent|^house")
dd <- zap_labels(d) %>% left_join(rs[, c("a7", "treatment")], by = "a7"); print(table(dd$treatment, dd$visited, useNA = "ifany"))
