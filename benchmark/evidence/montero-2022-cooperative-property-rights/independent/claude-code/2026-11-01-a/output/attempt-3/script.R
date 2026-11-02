suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-11-01-a/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d$dist <- d$own_amt - 500
print(table(d$Above500, d$own_amt >= 500))
print(summary(d$norm_dist)); print(summary(abs(d$dist) - d$norm_dist))
for (bw in c(300,150)) {
  s <- d[abs(d$dist) <= bw, ]
  s2 <- d[d$norm_dist <= bw, ]
  cat("\nbw", bw, "N(own_amt)", nrow(s), "N(norm_dist)", nrow(s2), "\n")
  for (v in c("match_id","Expropretario_ISTA","ID","own_amt","Total_Propretario","Total_Propretario2","Reform_Coop_id","Hacienda_id","CODIGO")) cat(v, length(unique(s[[v]])), length(unique(s2[[v]])), "\n")
  cat("prop-year:", nrow(distinct(s, match_id, year)), "\n")
  for (v in c("hh_income_pc","hh_inc_pc_real","hh_income","Work_Income","Land_Net_Income")) cat(v, mean(s[[v]], na.rm=TRUE), "\n")
}
cat("\nnum_members summary\n"); print(summary(d$num_members))
x <- d %>% group_by(match_id) %>% summarise(n=n(), nm=first(num_members), nmu=n_distinct(num_members))
print(head(x,20)); print(sum(x$n==x$nm))
y <- d %>% group_by(match_id, year) %>% summarise(n=n(), .groups="drop")
print(table(y$n >= 5)); print(nrow(y))
