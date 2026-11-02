D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/independent/2026-11-02-c/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D,"data_agg.RData")); load(file.path(D,"survey_raw.RData"))
options(width=200)
print(data.all[,c("barangay","city","assignment","treatment","partytreat","turnout.party","share.treated","share.akbayan","share.umalabka","att.prop","att.prop.turn","reg.num","vote.num.party")])
s <- as.data.frame(survey_raw)
str(s)
print(table(s$city, s$assignment, useNA="ifany"))
print(table(s$turnout_pl, useNA="ifany"))
print(table(s$turnout_all, useNA="ifany"))
print(table(s$vote, s$turnout_pl, useNA="ifany"))
s$one <- 1
print(aggregate(cbind(att=ifelse(is.na(attendance),0,attendance), na_att=is.na(attendance), n=one) ~ barangay + city + assignment + partytreat, data=s, FUN=sum))
for (v in c("femhouse","fempol","equality","discrimination","harassment","poverty","gap","cct","corruption")) {cat(v,"\n"); print(table(s[[v]],useNA="ifany"))}
print(setdiff(unique(s$barangay), data.all$barangay))
