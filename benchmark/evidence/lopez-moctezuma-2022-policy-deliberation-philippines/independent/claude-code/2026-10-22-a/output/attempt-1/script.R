M <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/independent/2026-10-22-a/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(M,"data_agg.RData")); load(file.path(M,"survey_raw.RData"))
options(width=200)
print(data.all[,c("barangay","city","assignment","treatment","partytreat","turnout.party","share.treated","share.akbayan","share.umalabka","att.prop","att.prop.turn","reg.num","vote.num.party")])
s <- as.data.frame(survey_raw); str(s)
print(table(s$city, s$assignment, useNA="ifany"))
print(table(s$barangay, s$attendance, useNA="ifany"))
print(table(s$turnout_pl, useNA="ifany")); print(table(s$turnout_all, useNA="ifany"))
print(with(s, table(vote, turnout_pl, useNA="ifany")))
print(with(s, table(vote, turnout_all, useNA="ifany")))
for (v in c("femhouse","fempol","equality","discrimination","harassment","poverty","gap","cct","corruption")) {cat(v,"\n"); print(table(s[[v]],useNA="ifany"))}
print(with(s, table(partytreat, assign.akbayan, useNA="ifany")))
