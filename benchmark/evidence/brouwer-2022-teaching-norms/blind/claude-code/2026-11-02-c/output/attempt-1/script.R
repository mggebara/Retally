d <- read.csv("<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/blind/2026-11-02-c/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data/master.csv")
str(d)
for (v in c("Child","children","scene","Condition","Violation","ViolationHelp","Help","Punishment","Helping","male","hugo","Morning","witness","rich","Rain","Hot","School")) { cat("==",v,"\n"); print(table(d[[v]], useNA="ifany")) }
print(with(d, table(scene, Violation, useNA="ifany"))); print(with(d, table(scene, ViolationHelp, useNA="ifany"))); print(with(d, table(scene, Help, useNA="ifany")))
print(with(d, table(scene, is.na(Punishment)))); print(with(d, table(scene, is.na(Helping))))
print(with(d, table(Child, children, useNA="ifany")))
print(with(d, table(scene, Child)))
