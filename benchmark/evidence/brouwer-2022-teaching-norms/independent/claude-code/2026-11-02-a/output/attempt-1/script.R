d <- read.csv("<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/independent/2026-11-02-a/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data/master.csv")
print(dim(d))
print(table(d$scene, d$ViolationHelp, useNA="ifany"))
print(table(d$scene, d$Violation, useNA="ifany"))
print(table(d$scene, d$Help, useNA="ifany"))
print(table(d$Child, d$children, useNA="ifany"))
for (v in c("Punishment","Helping","male","hugo","Morning","witness","rich","Rain","Hot")) {cat(v,"\n"); print(table(d$scene, d[[v]], useNA="ifany"))}
print(length(unique(d$School)))
