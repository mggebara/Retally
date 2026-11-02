D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/independent/2026-11-01-a/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D,"data_agg.RData")); load(file.path(D,"survey_raw.RData"))
options(width=250)
print(data.all[,c("barangay","city","assignment","treatment","partytreat","turnout.party","share.treated","share.akbayan","share.umalabka","att.prop","att.prop.turn")])
s <- as.data.frame(survey_raw)
str(s)
print(table(s$city, s$assignment, useNA="ifany"))
print(with(s, table(barangay, attendance, useNA="ifany")))
print(table(s$turnout_pl, useNA="ifany")); print(table(s$turnout_all, useNA="ifany"))
print(table(s$vote, s$turnout_pl, useNA="ifany"))
for (v in c("femhouse","fempol","equality","discrimination","harassment","poverty","gap","cct","corruption")) {cat(v,"\n"); print(table(s[[v]],useNA="ifany"))}
print(setdiff(unique(s$barangay), data.all$barangay)); print(setdiff(unique(s$city), data.all$city))
