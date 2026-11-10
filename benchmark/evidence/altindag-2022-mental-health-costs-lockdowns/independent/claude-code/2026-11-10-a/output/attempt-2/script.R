suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-a/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
d <- zap_labels(d)
print(table(d$non_response, is.na(d$dif)))
print(with(d, table(before1955, sign(dif), useNA="ifany")))
print(head(unique(d[order(d$dif), c("year","month","dif","modate","di1","di1_i","before1955")]), 3))
print(d[d$dif %in% c(-1,0,1), c("year","month","dif","modate","di1","di1_i","di2_i","before1955")][1:6,])
som <- c("head_ache","shaking","indigestion","stomach_discomfort")
non <- c("mal_appetite","sleeplessness","scared","nervous","unfocused","unhappy","weepy","unwillingness","undecisiveness","disrupted","useless","uninterest","worthless","suicidal","usually_tired","quickly_tired")
ctrl <- c("month","province_n","survey_taker_id","education","ethnicity","female")
cc <- complete.cases(d[, ctrl])
for (h in c(44,45,46)) for (op in c("le","lt")) {
  inb <- if (op=="le") abs(d$dif) <= h else abs(d$dif) < h
  inb <- inb & !is.na(inb) & cc
  cat(h, op, "ow", sum(inb & !is.na(d$outside_week)), "uc", sum(inb & !is.na(d$under_curfew)),
      "no", sum(inb & !is.na(d$never_out)),
      "all20", sum(inb & complete.cases(d[, c(som,non)])),
      "som4", sum(inb & complete.cases(d[, som])), "non16", sum(inb & complete.cases(d[, non])),
      "som_any", sum(inb & rowSums(!is.na(d[, som]))>0), "\n")
}
