d <- read.csv("<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/independent/2026-11-07-a/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data/master.csv")
print(table(d$scene, d$Condition, useNA="ifany"))
print(table(d$scene, d$Child))
for (v in c("Violation","ViolationHelp","Help","Punishment","Helping","male","hugo","Morning","witness","rich","Rain","Hot")) {cat(v,"\n"); print(table(d[[v]], d$scene, useNA="ifany"))}
print(length(unique(d$School)))
