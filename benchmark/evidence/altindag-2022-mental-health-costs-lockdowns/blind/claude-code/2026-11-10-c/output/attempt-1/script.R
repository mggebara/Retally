suppressPackageStartupMessages({library(haven); library(dplyr)})
p <- "<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/blind/2026-11-10-c/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta"
d <- read_dta(p)
cat(dim(d), "\n")
for (v in names(d)) {
  x <- d[[v]]
  lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  if (is.numeric(x)) {
    cat(sprintf("%-28s %-50s nNA=%4d nuniq=%4d min=%s max=%s mean=%s\n", v, substr(lab,1,50), sum(is.na(x)), length(unique(x)),
      format(min(x,na.rm=TRUE)), format(max(x,na.rm=TRUE)), format(round(mean(x,na.rm=TRUE),3))))
  } else cat(sprintf("%-28s %-50s char nuniq=%d\n", v, substr(lab,1,50), length(unique(x))))
}
vl <- function(v) { if (!is.null(attr(d[[v]],"labels"))) print(attr(d[[v]],"labels")) }
for (v in c("before1955","education","ethnicity","survey_taker_id","province_n","month","year")) if (v %in% names(d)) { cat("==",v,"\n"); vl(v); print(table(d[[v]], useNA="ifany")) }
rv <- grep("month|birth|forc|run|dist|cohort|age|resp|response|answer", names(d), value=TRUE)
print(rv)
