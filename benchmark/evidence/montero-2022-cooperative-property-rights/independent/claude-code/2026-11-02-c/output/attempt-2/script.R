suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-11-02-c/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)
print(summary(d$norm_dist)); print(summary(d$own_amt - 500 - d$norm_dist))
print(table(d$Above500, d$reform))
print(table(d$year, useNA="a")); print(table(d$survey_year, useNA="a"))
for (bw in c(300,150)) {
  s <- d %>% filter(abs(norm_dist) <= bw)
  cat("bw", bw, "N", nrow(s), " match_id", n_distinct(s$match_id), " ISTA", n_distinct(s$Expropretario_ISTA), " own_amt", n_distinct(s$own_amt),
      " Hacienda_id", n_distinct(s$Hacienda_id), " Reform_Coop_id", n_distinct(s$Reform_Coop_id), " ID", n_distinct(s$ID),
      " match_id x year", n_distinct(paste(s$match_id, s$year)), " ID x year", n_distinct(paste(s$ID, s$year)), "\n")
  cat("  mean hh_income_pc", mean(s$hh_income_pc), " real", mean(s$hh_inc_pc_real), " nonNA ln real", sum(!is.na(s$ln_hh_inc_pc_real)), "\n")
  s2 <- s %>% filter(abs(norm_dist) < bw)
  cat("  strict <: N", nrow(s2), "\n")
  g <- s %>% group_by(match_id, year) %>% summarise(n=n(), iqr=quantile(hh_income_pc,.75)-quantile(hh_income_pc,.25), .groups="drop")
  cat("  match_id-year cells n>=5:", sum(g$n>=5), " mean iqr", mean(g$iqr[g$n>=5]), "\n")
  g2 <- s %>% group_by(match_id) %>% summarise(n=n(), .groups="drop"); cat("  match_id n>=5:", sum(g2$n>=5), "\n")
  g3 <- s %>% group_by(ID, year) %>% summarise(n=n(), .groups="drop"); cat("  ID-year n>=5:", sum(g3$n>=5), "\n")
}
cat("num_members summary\n"); print(summary(d$num_members))
print(head(as.data.frame(d[, c("match_id","ID","Expropretario_ISTA","Reform_Coop_id","Hacienda_id","own_amt","Total_Propretario","Total_Propretario2","norm_dist","reform","Above500","year","num_members","hh_income_pc","hh_inc_pc_real")]), 30))
