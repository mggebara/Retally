# Exploratory: inspect SRQ-20 item coding and inverse-covariance weights (no index estimates, no RESULT lines)
suppressPackageStartupMessages({library(haven); library(fixest)})
path <- "<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/seeded/2026-11-10-a/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta"
d0 <- read_dta(path)
list1 <- c("head_ache","mal_appetite","sleeplessness","scared","shaking","nervous",
           "indigestion","unfocused","unhappy","weepy","unwillingness","undecisiveness",
           "disrupted","useless","uninterest","worthless","suicidal","usually_tired",
           "stomach_discomfort","quickly_tired")
list2 <- c("head_ache","shaking","indigestion","stomach_discomfort")
for (v in list1) { cat("==", v, "\n"); print(attr(d0[[v]], "labels")); print(table(as.numeric(d0[[v]]), useNA = "ifany")) }
d <- as.data.frame(zap_labels(d0)); d <- d[d$non_response == 0, ]
ctrl <- d$before1955 == 0
Z <- sapply(list1, function(v) { x <- d[[v]]; (x - mean(x[ctrl], na.rm=TRUE)) / sd(x[ctrl], na.rm=TRUE) })
cc <- complete.cases(Z)
cat("complete cases full sample:", sum(cc), "\n")
w1 <- rowSums(solve(cov(Z[cc, ]))); print(round(w1 / sum(w1), 3))
w2 <- rowSums(solve(cov(Z[cc, list2]))); print(round(w2 / sum(w2), 3))
print(round(cor(Z[cc, list2]), 3))
# item-level RD coefficients (z-scored items), bandwidth 45
s <- d[abs(d$dif) <= 45, ]; s[, paste0("z_", list1)] <- Z[abs(d$dif) <= 45, ]
s$cc <- complete.cases(s[, list1])
rhs <- paste("before1955 + di1 + di1_i +", paste(grep("^month_[0-9]+$", names(d), value=TRUE), collapse=" + "), "+",
             paste(grep("^province_n_[0-9]+$", names(d), value=TRUE), collapse=" + "),
             "+ factor(ethnicity) + factor(education) + female + factor(survey_taker_id)")
for (v in list1) {
  m <- feols(as.formula(paste0("z_", v, " ~ ", rhs)), data = s[s$cc, ], cluster = ~modate, notes = FALSE)
  cat(sprintf("item %-20s b=%.4f\n", v, coef(m)["before1955"]))
}
