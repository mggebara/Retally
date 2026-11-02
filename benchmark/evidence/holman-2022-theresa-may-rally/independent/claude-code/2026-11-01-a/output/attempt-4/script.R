suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-01-a/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels() %>% arrange(country_code, qtr)
g <- g %>% group_by(country_code) %>% mutate(
  lead_lagapp = ifelse(lead(qtr) == qtr + 1, lead(lag_approval), NA)) %>% ungroup()
v1 <- c("lag_approval", "kill_16", "female_pres", "growth", "log_inflation", "execrlc", "election_qtr")
v2 <- replace(v1, 1, "lead_lagapp")
g$c1 <- complete.cases(g[, v1]); g$c2 <- complete.cases(g[, v2])
print(as.data.frame(g %>% group_by(country, country_code) %>% summarise(n=n(), c1=sum(c1), c2=sum(c2),
  na_fem=sum(is.na(female_pres)), na_inf=sum(is.na(log_inflation)), ex0=sum(execrlc==0, na.rm=TRUE),
  na_ex=sum(is.na(execrlc)), na_app=sum(is.na(lag_approval)), pres15=first(pres_15death), .groups="drop")))
# execrlc 0 among complete
cat("complete c1 & execrlc==0:", sum(g$c1 & g$execrlc==0), "\n")
cat("complete c1 & female_pres NA counted if NA->0:", sum(complete.cases(g[, setdiff(v1, "female_pres")])), "\n")
