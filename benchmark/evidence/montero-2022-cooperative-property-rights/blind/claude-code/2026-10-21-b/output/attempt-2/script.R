suppressMessages({library(haven); library(dplyr)})
d <- read_dta("/Users/matthew/dev/Retally/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/blind/2026-10-21-b/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)
cat("own_amt-500 vs norm_dist max diff:", max(abs(d$own_amt-500-d$norm_dist)), "\n")
cat("Above500 vs own_amt>=500 mismatch:", sum(d$Above500 != (d$own_amt>=500)), "\n")
print(table(d$year, useNA="ifany")); print(table(d$survey_year, useNA="ifany"))
print(table(reform=d$reform, Above=d$Above500)); print(table(Matched=d$Matched, Coop=d$Coop_Member, useNA="ifany"))
print(table(NonCoop=d$Non_Coop_Member, reform=d$reform, useNA="ifany"))
print(table(d$Occupation_Type, d$reform))
print(summary(d[,c("hh_income","hh_income_pc","hh_inc_pc_real","Work_Income","temp","sex")]))
cat("hh_income/hh_income_pc summary:\n"); print(summary(d$hh_income/d$hh_income_pc))
cat("uniq ID", length(unique(d$ID)), "uniq Exprop", length(unique(d$Expropretario_ISTA)), "uniq match_id", length(unique(d$match_id)),
    "uniq own_amt", length(unique(d$own_amt)), "\n")
# ID nested in owner?
cat("match_id per ID max:", max(tapply(d$match_id, d$ID, function(x) length(unique(x)))), "\n")
cat("ID per match_id max:", max(tapply(d$ID, d$match_id, function(x) length(unique(x)))), "\n")
cat("Exprop per match_id max:", max(tapply(d$Expropretario_ISTA, d$match_id, function(x) length(unique(x)))), "\n")
cat("own_amt per Exprop max:", max(tapply(d$own_amt, d$Expropretario_ISTA, function(x) length(unique(x)))), "\n")
cat("Exprop per own_amt max:", max(tapply(d$Expropretario_ISTA, d$own_amt, function(x) length(unique(x)))), "\n")
cat("match_id same as Reform_Coop_id/Hacienda_id?\n"); print(head(d[,c("match_id","Reform_Coop_id","Hacienda_id","ID","Expropretario_ISTA","reform","own_amt","Total_Propretario","AREA_HECTAREA")], 15))
for (bw in c(300,150)) {
  s <- d[abs(d$norm_dist) <= bw, ]
  cat(sprintf("bw %d: rows %d, match_id %d, ID %d, Exprop %d, own_amt %d, matchid-year %d, ID-year %d\n", bw, nrow(s),
     length(unique(s$match_id)), length(unique(s$ID)), length(unique(s$Expropretario_ISTA)), length(unique(s$own_amt)),
     nrow(unique(s[,c("match_id","year")])), nrow(unique(s[,c("ID","year")]))))
  for (yv in c("hh_income_pc","hh_inc_pc_real")) cat("  mean", yv, mean(s[[yv]], na.rm=TRUE), "\n")
  s2 <- s[s$year>=2002,]
  cat(sprintf("  year>=2002 rows %d match_id %d Exprop %d\n", nrow(s2), length(unique(s2$match_id)), length(unique(s2$Expropretario_ISTA))))
  g <- s %>% group_by(match_id, year) %>% summarise(n=n(), .groups="drop")
  cat("  match_id-year cells with n>=5:", sum(g$n>=5), "\n")
  g <- s %>% group_by(match_id) %>% summarise(n=n(), .groups="drop")
  cat("  match_id with n>=5:", sum(g$n>=5), "\n")
}
