D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/blind/2026-11-07-a/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D,"data_agg.RData")); load(file.path(D,"survey_raw.RData"))
options(width=250)
print(data.all[,c("barangay","city","assignment","treatment","partytreat","turnout.party","share.treated","att.prop","att.prop.turn","reg.num","vote.num.party")])
s <- as.data.frame(survey_raw)
str(s)
print(with(s, table(turnout_pl, turnout_all, useNA="ifany")))
print(with(s, table(vote, turnout_pl, useNA="ifany")))
print(with(s, table(attendance, assignment, useNA="ifany")))
s$n <- 1
print(aggregate(cbind(attendance, n) ~ barangay+city+assignment+treatment+partytreat, data=s, FUN=sum, na.action=na.pass))
for (v in c("femhouse","fempol","equality","discrimination","harassment","poverty","gap","cct","corruption","vote.akbayan","vote.umalabka","partytreat","region","city","barangay")) {cat(v,"\n");print(table(s[[v]],useNA="ifany"))}
