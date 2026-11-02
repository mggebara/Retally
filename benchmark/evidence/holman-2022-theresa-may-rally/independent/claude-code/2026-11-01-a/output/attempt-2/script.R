suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-01-a/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels() %>% arrange(country_code, qtr)
g <- g %>% group_by(country_code) %>% mutate(lead_lagapp = ifelse(lead(qtr) == qtr + 1, lead(lag_approval), NA),
  lag_k16 = ifelse(lag(qtr) == qtr - 1, lag(kill_16), NA)) %>% ungroup()
cc <- function(vars) sum(complete.cases(g[, vars]))
base <- c("kill_16","female_pres","growth","log_inflation","execrlc","election_qtr")
cat("N lag_approval DV:", cc(c("lag_approval", base)), "\n")
cat("N lead DV:", cc(c("lead_lagapp", base)), "\n")
cat("N lag_approval DV, lagged attack:", cc(c("lag_approval", "lag_k16", base[-1])), "\n")
cat("N without execrlc:", cc(c("lag_approval", base[-5])), "\n")
cat("execrlc==0 rows:", sum(g$execrlc==0, na.rm=TRUE), "\n")
cat("N lag_approval DV excluding execrlc 0:", sum(complete.cases(g[, c("lag_approval", base)]) & g$execrlc != 0, na.rm=TRUE), "\n")
print(table(g$kill_16, g$female_pres, useNA="a"))
print(g %>% filter(kill_16==1) %>% select(country, qtr, female_pres, lag_approval, lead_lagapp) %>% as.data.frame())
print(g %>% distinct(country, country_code) %>% as.data.frame())

dd <- read_dta(file.path(D, "did_data.dta")) %>% zap_labels()
cat("rows", nrow(dd), "\n")
print(table(dd$wave, is.na(dd$likeMayW)))
print(table(dd$wave, dd$likeMayW == 9999))
print(table(dd$wave, is.na(dd$bestPMW)))
print(table(dd$wave, dd$bestPMW, useNA="a"))
print(table(dd$wave, dd$may_bestpm, useNA="a"))
print(table(dd$wave, dd$treatment1, useNA="a"))
print(table(dd$wave, dd$time, useNA="a"))
print(table(dd$wave, dd$post_attack, useNA="a"))
print(table(dd$wave, dd$treatment2, useNA="a"))
for (v in c("white","gender","labour","party_other","income","ideology","ideology2","ideo3","conservative")) {
  cat("--", v, "\n"); print(table(dd[[v]], useNA="a")) }
print(summary(dd$ideology)); print(summary(dd$ideology2))
EOF_MARK <- NULL
