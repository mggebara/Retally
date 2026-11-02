suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-02-c/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels() %>% arrange(country_code, qtr)
cat("countries", length(unique(g$country_code)), "ccode", length(unique(g$ccode)), "\n")
cat("sum kill_16", sum(g$kill_16), " female & kill16", sum(g$kill_16 * g$female_pres, na.rm=TRUE), "\n")
print(table(g$execrlc, useNA="a"))
print(table(g$pres_15death))
print(head(g[g$country=="United Kingdom", c("qtr","lag_approval","kill_16","female_pres","manchester")], 3))
print(g[g$country=="United Kingdom" & g$qtr >= 225, c("qtr","lag_approval","kill_16","female_pres","manchester","election_qtr")])
# check duplicates country-qtr
cat("dups", sum(duplicated(g[,c("country_code","qtr")])), " dups ccode", sum(duplicated(g[,c("ccode","qtr")])), "\n")
print(table(g$country[duplicated(g[,c("ccode","qtr")])]))
g <- g %>% group_by(country_code) %>% mutate(lead1 = dplyr::lead(lag_approval), lead2 = dplyr::lead(lag_approval, 2), k_l1 = dplyr::lag(kill_16)) %>% ungroup()
for (y in c("lag_approval","lead1","lead2")) {
  for (x in c("kill_16","k_l1")) {
    f1 <- as.formula(paste0(y, " ~ ", x, "*female_pres + growth + log_inflation + execrlc + election_qtr | country_code"))
    m <- feols(f1, g, notes=FALSE)
    cat(y, x, "N", nobs(m), "\n"); print(round(coef(m)[c(x, paste0(x, ":female_pres"))], 3))
  }
}
d <- read_dta(file.path(D, "did_data.dta")) %>% zap_labels()
d <- d %>% filter(!is.na(likeMayW) | !is.na(bestPMW))
cat("like nonmiss", sum(!is.na(d$likeMayW)), " best nonmiss", sum(!is.na(d$bestPMW)), "\n")
print(table(d$wave, !is.na(d$likeMayW))); print(table(d$wave, !is.na(d$bestPMW)))
for (ideo in c("ideology","ideology2","ideo3")) {
  for (y in c("likeMayW","bestPMW")) {
    cc <- complete.cases(d[, c(y, "treatment1","time","white","gender","labour","party_other","income", ideo)])
    cat(ideo, y, sum(cc), "\n")
  }
}
for (y in c("likeMayW","bestPMW")) {
  cat(y, "no ideo/income", sum(complete.cases(d[, c(y,"white","gender","labour","party_other")])), " w income", sum(complete.cases(d[, c(y,"white","gender","labour","party_other","income")])), "\n")
}
print(summary(d$income)); print(table(d$ideology, useNA="a")); print(table(d$ideology2, useNA="a"))
