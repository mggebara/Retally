suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-02-c/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels() %>% arrange(country_code, qtr)
# time-aware lags
lagq <- function(df, v, k) {
  key <- paste(df$country_code, df$qtr)
  key2 <- paste(df$country_code, df$qtr - k)
  df[[v]][match(key2, key)]
}
g$gL1 <- lagq(g, "growth", 1); g$gL4 <- lagq(g, "growth", 4)
g$gr1 <- 100 * (g$growth - g$gL1) / g$gL1
g$gr4 <- 100 * (g$growth - g$gL4) / g$gL4
g$apL1 <- lagq(g, "lag_approval", 1); g$apF1 <- lagq(g, "lag_approval", -1)
g$kL1 <- lagq(g, "kill_16", 1)
print(head(g[g$country == "United Kingdom", c("qtr","growth","gr1","gr4")], 10))
run <- function(f, lab, dat = g) {
  m <- feols(f, dat, notes = FALSE)
  b <- coef(m)
  cat(sprintf("%-40s N=%d R2=%.4f b1=%.3f bint=%.3f\n", lab, nobs(m), r2(m, "r2"), b[2 - 1], b[grep(":", names(b))][1]))
  invisible(m)
}
run(lag_approval ~ kill_16*female_pres + gr1 + log_inflation + execrlc + election_qtr | country_code, "gr1")
run(lag_approval ~ kill_16*female_pres + gr4 + log_inflation + execrlc + election_qtr | country_code, "gr4")
run(lag_approval ~ kill_16*female_pres + growth + log_inflation + execrlc + election_qtr + apL1 | country_code, "ldv apL1")
run(apF1 ~ kill_16*female_pres + growth + log_inflation + execrlc + election_qtr + lag_approval | country_code, "F1 with lag ctrl")
run(apF1 ~ kill_16*female_pres + growth + log_inflation + execrlc + election_qtr | country_code, "F1")
run(lag_approval ~ kL1*female_pres + growth + log_inflation + execrlc + election_qtr + apL1 | country_code, "kL1 ldv")
run(lag_approval ~ kill_16*female_pres + gr4 + log_inflation + i(execrlc) + election_qtr | country_code, "gr4 factor ex")
