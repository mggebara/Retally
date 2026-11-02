suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-01-a/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels() %>% arrange(country_code, qtr)
g <- g %>% group_by(country_code) %>% mutate(
  lead_lagapp = ifelse(lead(qtr) == qtr + 1, lead(lag_approval), NA),
  lead2 = ifelse(lead(qtr, 2) == qtr + 2, lead(lag_approval, 2), NA),
  lag_k16 = ifelse(lag(qtr) == qtr - 1, lag(kill_16), NA),
  g_lag4 = ifelse(lag(qtr, 4) == qtr - 4, lag(growth, 4), NA),
  growth_pct = 100 * (growth / g_lag4 - 1)) %>% ungroup()
runs <- function(ok) { g2 <- g; g2$ok <- ok; g2 %>% group_by(country_code) %>%
  summarise(r = sum(ok & !dplyr::lag(ok, default = FALSE)), n = sum(ok)) %>% summarise(r = sum(r), n = sum(n)) }
ctl <- c("female_pres", "log_inflation", "execrlc", "election_qtr")
for (dv in c("lag_approval", "lead_lagapp", "lead2")) for (gr in c("growth", "growth_pct")) for (att in c("kill_16", "lag_k16")) {
  ok <- complete.cases(g[, c(dv, att, gr, ctl)])
  r <- runs(ok); cat(dv, gr, att, ": n", r$n, " runs", r$r, " n-runs", r$n - r$r, " n-panels", r$n - sum(tapply(ok, g$country_code, any)), "\n")
}
