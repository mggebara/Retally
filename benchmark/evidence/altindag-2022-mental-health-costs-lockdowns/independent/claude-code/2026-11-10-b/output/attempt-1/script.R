suppressMessages(library(haven))
d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-b/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
cat(dim(d), "\n")
for (v in names(d)) {
  x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  u <- unique(x)
  cat(sprintf("%-28s %-10s nNA=%4d nuniq=%4d | %s | %s\n", v, class(x)[1], sum(is.na(x)), length(u), substr(lab,1,60),
      paste(head(sort(u), 8), collapse=",")))
}
