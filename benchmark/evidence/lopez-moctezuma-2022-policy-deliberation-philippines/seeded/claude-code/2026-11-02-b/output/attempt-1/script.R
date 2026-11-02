D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/2026-11-02-b/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D,"survey_raw.RData")); load(file.path(D,"data_agg.RData"))
options(width=200)
print(data.all[,c("barangay","city","assignment","treatment","partytreat","turnout.party","share.treated","att.prop")])
library(dplyr)
s <- as.data.frame(survey_raw)
print(s %>% group_by(city,barangay) %>% summarise(n=n(), a=mean(assignment), t=mean(treatment,na.rm=T), att=mean(attendance,na.rm=T), pt=first(partytreat), .groups="drop"), n=100)
str(s)
