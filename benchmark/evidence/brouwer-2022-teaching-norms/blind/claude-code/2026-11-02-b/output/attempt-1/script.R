library(haven)
d <- read_dta("<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/blind/2026-11-02-b/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")
str(d[, c("School","Child","scene","Condition","Violation","ViolationHelp","Help","Punishment","Helping","HelpingParents","kidshelped","male","hugo","Morning","witness","rich","Rain","Hot")])
for (v in c("scene","Condition","Violation","ViolationHelp","Help","Punishment","Helping","HelpingParents","kidshelped","male","hugo","Morning","witness","rich","Rain","Hot","Child")) {cat(v,"\n"); print(table(d[[v]], useNA="always"))}
print(table(d$scene, d$Condition))
print(table(d$Helping, d$HelpingParents, useNA="always"))
print(table(d$scene, is.na(d$Helping)))
print(table(d$scene, is.na(d$Punishment)))
print(length(unique(d$School)))
