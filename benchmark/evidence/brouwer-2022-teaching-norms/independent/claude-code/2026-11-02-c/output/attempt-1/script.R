library(haven)
d <- read_dta("<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/independent/2026-11-02-c/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")
for (v in c("Child","scene","Condition","Violation","ViolationHelp","Help","Punishment","Helping","male","hugo","Morning","witness","rich","Rain","Hot","School")) { cat("==",v,"\n"); print(attr(d[[v]],"labels")); print(table(d[[v]],useNA="ifany")) }
print(with(d, table(scene, Violation, useNA="ifany"))); print(with(d, table(scene, ViolationHelp))); print(with(d, table(scene, Help)))
print(with(d, table(scene, is.na(Punishment)))); print(with(d, table(scene, is.na(Helping))))
