suppressMessages(library(haven))
d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-a/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
cat(dim(d), "\n")
for (v in names(d)) {
  x <- d[[v]]
  lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  u <- unique(x); nu <- length(u)
  s <- if (is.numeric(x)) sprintf("min=%s max=%s mean=%.3f", min(x,na.rm=T), max(x,na.rm=T), mean(x,na.rm=T)) else paste(head(u,5), collapse="|")
  cat(sprintf("%-28s %-10s NA=%4d nu=%4d %s | %s\n", v, class(x)[1], sum(is.na(x)), nu, s, lab))
}
for (v in c("year","month","education","ethnicity","survey_taker_id","under_curfew","outside_week","never_out","before1955")) if (v %in% names(d)) {cat("==",v,"\n"); print(table(as_factor(d[[v]]), useNA="ifany"))}
