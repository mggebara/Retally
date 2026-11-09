library(haven); library(dplyr); library(fixest)
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-07-a/mount/holman_2022_theresa_may_rally"
g <- zap_labels(read_dta(file.path(D,"global_approval.dta")))
cat("ccode==country_code:", all(g$ccode==g$country_code), "\n")
print(table(table(g$country_code)))
print(g %>% group_by(country_code) %>% summarise(country=first(country), n=n(), qmin=min(qtr), qmax=max(qtr), naA=sum(is.na(lag_approval)), naI=sum(is.na(log_inflation)), naF=sum(is.na(female_pres)), naG=sum(is.na(growth)), naE=sum(is.na(execrlc)), e0=sum(execrlc==0,na.rm=T)), n=70)
g <- g %>% arrange(country_code, qtr) %>% group_by(country_code) %>%
  mutate(gr4 = 100*(growth/lag(growth,4)-1), L1A = lag(lag_approval)) %>% ungroup()
run <- function(lab, f, dat) { m <- feols(f, data=dat); cat(sprintf("%-30s N=%d b1=%.3f bint=%.3f R2=%.4f cons?\n", lab, nobs(m), coef(m)["kill_16"], coef(m)["kill_16:female_pres"], r2(m,"r2"))) }
base <- lag_approval ~ kill_16*female_pres + growth + log_inflation + execrlc + election_qtr | country_code
run("base", base, g)
run("execrlc>0", base, filter(g, execrlc>0))
run("execrlc factor", lag_approval ~ kill_16*female_pres + growth + log_inflation + i(execrlc) + election_qtr | country_code, g)
run("gr4", lag_approval ~ kill_16*female_pres + gr4 + log_inflation + execrlc + election_qtr | country_code, g)
run("with L1A", lag_approval ~ kill_16*female_pres + growth + log_inflation + execrlc + election_qtr + L1A| country_code, g)
run("no FE", lag_approval ~ kill_16*female_pres + growth + log_inflation + execrlc + election_qtr, g)
run("rally_event_any2 nonmiss", base, filter(g, !is.na(rally_event_any2)))
run("qtr fe too", lag_approval ~ kill_16*female_pres + growth + log_inflation + execrlc + election_qtr | country_code + qtr, g)
