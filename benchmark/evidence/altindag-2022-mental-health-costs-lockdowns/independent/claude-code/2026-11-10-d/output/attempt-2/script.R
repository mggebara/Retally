suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-d/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
d <- zap_labels(d)
print(head(d[, c("year","month","dif","modate","di1","di1_i","di2","before1955","age","non_response")], 5))
print(table(d$dif[d$year==1955 & !is.na(d$year)], d$month[d$year==1955 & !is.na(d$year)]))
print(table(d$dif[d$year==1956 & !is.na(d$year)], d$month[d$year==1956 & !is.na(d$year)]))
cat("di1==dif:", all(d$di1==d$dif, na.rm=TRUE), " di1_i==dif*b:", all(d$di1_i==d$dif*d$before1955, na.rm=TRUE), "\n")
print(table(d$non_response, is.na(d$year)))
ctrl <- c("education","ethnicity","female","province_n","survey_taker_id","month","modate")
srq <- c("head_ache","mal_appetite","sleeplessness","scared","shaking","nervous","indigestion","unfocused","unhappy","weepy","unwillingness","undecisiveness","disrupted","useless","uninterest","worthless","suicidal","usually_tired","stomach_discomfort","quickly_tired")
som <- c("head_ache","shaking","indigestion","stomach_discomfort")
cc <- complete.cases(d[, ctrl])
for (bw in c(17,30,45,60)) for (op in c("le","lt")) {
  inb <- if (op=="le") abs(d$dif) <= bw else abs(d$dif) < bw
  inb[is.na(inb)] <- FALSE
  s <- inb & cc
  cat(sprintf("bw %d %s: days %d curfew %d never %d allsrq %d som %d nonsom %d\n", bw, op,
    sum(s & !is.na(d$outside_week)), sum(s & !is.na(d$under_curfew)), sum(s & !is.na(d$never_out)),
    sum(s & complete.cases(d[, srq])), sum(s & complete.cases(d[, som])), sum(s & complete.cases(d[, setdiff(srq, som)]))))
}
print(table(d$education, useNA="a")); print(table(d$ethnicity, useNA="a"))
