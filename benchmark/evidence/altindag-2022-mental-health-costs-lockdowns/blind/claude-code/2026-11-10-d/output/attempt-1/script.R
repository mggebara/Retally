suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/blind/2026-11-10-d/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
cat(dim(d), "\n")
for (v in names(d)) {
  x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  cat(sprintf("%-28s %-10s nNA=%4d nuniq=%4d  %s | %s\n", v, class(x)[1], sum(is.na(x)), length(unique(x)), lab,
      paste(head(sort(unique(as.vector(x))), 8), collapse=",")))
}
cat("\n--- year x month table ---\n"); print(table(d$year, useNA="ifany"))
print(table(d$before1955, d$year, useNA="ifany"))
