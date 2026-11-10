suppressMessages(library(haven))
d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-b/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
d <- zap_labels(d)
print(table(d$non_response, is.na(d$dif)))
print(table(d$before1955, sign(d$dif), useNA = "ifany"))
x <- unique(d[!is.na(d$dif), c("year", "month", "dif", "di1", "di1_i", "before1955")])
x <- x[order(x$dif), ]
print(as.data.frame(x[abs(x$dif) <= 3, ]))
print(table(d$education, useNA = "ifany")); print(table(d$ethnicity, useNA = "ifany")); print(table(d$female, useNA = "ifany"))
som <- c("head_ache", "shaking", "indigestion", "stomach_discomfort")
non <- c("mal_appetite", "sleeplessness", "scared", "nervous", "unfocused", "unhappy", "weepy", "unwillingness",
         "undecisiveness", "disrupted", "useless", "uninterest", "worthless", "suicidal", "usually_tired", "quickly_tired")
ctrl_ok <- with(d, !is.na(dif) & !is.na(province_n) & !is.na(survey_taker_id) & !is.na(education) & !is.na(ethnicity) & !is.na(female) & !is.na(month))
for (h in c(17, 30, 45, 60)) {
  for (op in c("le", "lt")) {
    inb <- if (op == "le") abs(d$dif) <= h else abs(d$dif) < h
    inb <- !is.na(inb) & inb & ctrl_ok
    cat(h, op, "ctrl", sum(inb), "week", sum(inb & !is.na(d$outside_week)), "curfew", sum(inb & !is.na(d$under_curfew)),
        "never", sum(inb & !is.na(d$never_out)),
        "all20", sum(inb & complete.cases(d[, c(som, non)])),
        "som4", sum(inb & complete.cases(d[, som])), "non16", sum(inb & complete.cases(d[, non])),
        "any_som", sum(inb & rowSums(!is.na(d[, som])) > 0), "any20", sum(inb & rowSums(!is.na(d[, c(som, non)])) > 0), "\n")
  }
}
# alternative: dif-based on di1 etc
cat("cor dif di1", cor(d$dif, d$di1, use = "complete"), "\n")
