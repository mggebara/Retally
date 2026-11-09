library(haven); library(dplyr); library(fixest)
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-07-a/mount/holman_2022_theresa_may_rally"
g <- zap_labels(read_dta(file.path(D,"global_approval.dta")))
m33 <- g %>% filter(country_code==33) %>% arrange(qtr); m34 <- g %>% filter(country_code==34) %>% arrange(qtr)
cat("Macedonia dup identical except code:", isTRUE(all.equal(select(m33,-country_code,-ccode), select(m34,-country_code,-ccode))), "\n")
print(head(m33 %>% select(qtr, lag_approval, female_pres, execrlc)), 3); print(head(m34 %>% select(qtr, lag_approval, female_pres, execrlc)), 3)
g <- g %>% arrange(country_code, qtr) %>% group_by(country_code) %>%
  mutate(gr4 = 100*(growth/lag(growth,4)-1),
         gr4b = ifelse(lag(qtr,4)==qtr-4, 100*(growth/lag(growth,4)-1), NA),
         grq = 100*(growth/lag(growth)-1), ldiff = log(growth)-log(lag(growth,4))) %>% ungroup()
run <- function(lab, f, dat) { m <- feols(f, data=dat); cat(sprintf("%-30s N=%d b1=%.3f bint=%.3f R2=%.4f\n", lab, nobs(m), coef(m)["kill_16"], coef(m)["kill_16:female_pres"], r2(m,"r2"))) }
for (gv in c("growth","gr4","gr4b","grq","ldiff")) {
  f <- as.formula(paste("lag_approval ~ kill_16*female_pres +", gv, "+ log_inflation + execrlc + election_qtr | country_code"))
  run(gv, f, g); run(paste(gv,"no34"), f, filter(g, country_code!=34))
  run(paste(gv,"no33"), f, filter(g, country_code!=33))
}
