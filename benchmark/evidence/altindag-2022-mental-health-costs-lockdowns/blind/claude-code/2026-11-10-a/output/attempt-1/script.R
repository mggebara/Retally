suppressMessages(library(haven))
d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/blind/2026-11-10-a/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
cat(dim(d), "\n")
for (v in names(d)) {
  x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  if (is.numeric(x)) {
    cat(sprintf("%-28s %-50s n=%d na=%d uniq=%d min=%s max=%s mean=%.3f\n", v, substr(lab,1,50), sum(!is.na(x)), sum(is.na(x)), length(unique(x)), min(x,na.rm=T), max(x,na.rm=T), mean(x,na.rm=T)))
  } else cat(sprintf("%-28s %-50s chr uniq=%d na=%d\n", v, substr(lab,1,50), length(unique(x)), sum(is.na(x)|x=="")))
}
for (v in c("year","month","education","ethnicity","survey_taker_id","gender","female","male","under_curfew","never_out","outside_week")) if (v %in% names(d)) {cat("--",v,"\n"); print(table(d[[v]], useNA="always"))}
