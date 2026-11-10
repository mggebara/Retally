suppressPackageStartupMessages({library(haven)})
base <- "<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/blind/2026-11-10-a/mount/corno_2022_interaction_stereotypes_performance/ForJournals_a/Data/Clean/"
options(width = 200)
for (f in c("uctdata_balanced.dta", "uctdata_clean.dta")) {
  d <- read_dta(paste0(base, f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]
    lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    if (is.numeric(x)) {
      cat(sprintf("%-28s %-50s nNA=%4d nuniq=%4d mean=%.4g min=%.4g max=%.4g\n", v, substr(lab,1,50), sum(is.na(x)), length(unique(x)),
                  mean(x, na.rm=TRUE), suppressWarnings(min(x, na.rm=TRUE)), suppressWarnings(max(x, na.rm=TRUE))))
    } else cat(sprintf("%-28s %-50s char nuniq=%d\n", v, substr(lab,1,50), length(unique(x))))
  }
}
d <- read_dta(paste0(base, "uctdata_balanced.dta"))
print(table(d$Race, useNA="ifany"))
print(table(d$Res_base, useNA="ifany"))
cat("both IAT nonmiss:", sum(!is.na(d$DscoreraceIAT) & !is.na(d$DscoreacaIAT) & !is.na(d$DscoreraceIATbas) & !is.na(d$DscoreacaIATbas)), "\n")
if ("round" %in% names(d)) print(table(d$round))
c2 <- read_dta(paste0(base, "uctdata_clean.dta"))
if ("round" %in% names(c2)) print(table(c2$round))
