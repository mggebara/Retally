suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-01-a/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels() %>% arrange(country_code, qtr)
g <- g %>% group_by(country_code) %>% mutate(
  lead_lagapp = ifelse(lead(qtr) == qtr + 1, lead(lag_approval), NA),
  g_lag4 = ifelse(lag(qtr, 4) == qtr - 4, lag(growth, 4), NA),
  growth_pct = 100 * (growth / g_lag4 - 1),
  growth_pct1 = 100 * (growth / lag(growth) - 1),
  lag_k16 = ifelse(lag(qtr) == qtr - 1, lag(kill_16), NA)) %>% ungroup()
cc <- function(d, vars) sum(complete.cases(d[, vars]))
for (dv in c("lag_approval", "lead_lagapp")) for (gr in c("growth", "growth_pct", "growth_pct1")) for (att in c("kill_16", "lag_k16")) {
  v <- c(dv, att, "female_pres", gr, "log_inflation", "execrlc", "election_qtr")
  cat(dv, gr, att, ": all", cc(g, v), " execrlc>0", cc(g[g$execrlc %in% 1:3, ], v), "\n")
}
cat("growth changes within year? ", mean(g$growth == lag(g$growth), na.rm=TRUE), "\n")
cat("qtr gaps:", sum(diff(g$qtr) != 1 & diff(g$country_code) == 0), "\n")
print(range(g$qtr)); print(table(g$qtr %% 4))

dd <- read_dta(file.path(D, "did_data.dta")) %>% zap_labels()
# check controls time-varying
chk <- dd %>% group_by(id) %>% summarise(across(c(white, gender, labour, party_other, income, ideology, ideology2, treatment1), ~ n_distinct(.x)))
print(sapply(chk[,-1], function(x) mean(x > 1)))
like <- dd %>% filter(!is.na(likeMayW))
bp <- dd %>% filter(!is.na(bestPMW))
sets <- list(
  c("white","gender","labour","party_other","income","ideology"),
  c("white","gender","labour","party_other","income","ideology2"),
  c("white","gender","labour","party_other","income","ideo3"),
  c("white","gender","labour","party_other"),
  c("white","gender","labour","party_other","ideology2"),
  c("white","gender","labour","party_other","income"))
for (s in sets) { cat(paste(s, collapse="+"), ": like", cc(like, c("likeMayW","treatment1","time",s)),
  " like w9+", cc(like[like$wave>=9,], c("likeMayW","treatment1","time",s)),
  " bestpm", cc(bp, c("bestPMW","treatment1","time",s)), "\n")
  print(table(like$wave[complete.cases(like[, c("likeMayW", s)])]))
  print(table(bp$wave[complete.cases(bp[, c("bestPMW", s)])]))
}
