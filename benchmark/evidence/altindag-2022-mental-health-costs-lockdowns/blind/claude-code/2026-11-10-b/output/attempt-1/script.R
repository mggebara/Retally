# Exploratory: inspect variables (no estimates)
suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/blind/2026-11-10-b/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
cat("dim", dim(d), "\n")
for (v in names(d)) {
  x <- d[[v]]
  lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  nu <- length(unique(x))
  cat(sprintf("%-28s %-10s nNA=%4d nuniq=%5d | %s", v, class(x)[1], sum(is.na(x)), nu, lab))
  if (is.numeric(x) && nu <= 12) cat(" | vals:", paste(sort(unique(as.numeric(x))), collapse=","))
  else if (is.numeric(x)) cat(sprintf(" | range %.2f..%.2f", min(x,na.rm=TRUE), max(x,na.rm=TRUE)))
  cat("\n")
}
print(table(d$year, useNA="ifany"))
for (v in intersect(c("dist","running","forcing","x","month_year","myob","before1955","respond","response","nonresponse","sample"), names(d))) {cat(v,"\n"); print(head(table(d[[v]], useNA="ifany"), 30))}
