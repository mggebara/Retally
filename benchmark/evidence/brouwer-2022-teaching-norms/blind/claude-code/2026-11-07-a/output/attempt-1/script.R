suppressMessages(library(haven))
d <- read_dta("<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/blind/2026-11-07-a/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data/master.dta")
print(dim(d))
for (v in c("Child","scene","Condition","Violation","ViolationHelp","Help","Punishment","Helping","male","hugo","Morning","witness","rich","Rain","Hot","School")) {
  cat(v, attr(d[[v]], "label"), "\n"); print(table(d[[v]], useNA = "ifany"))
}
print(attr(d$scene, "labels"))
print(with(d, table(scene, Violation, useNA = "ifany")))
print(with(d, table(scene, ViolationHelp)))
print(with(d, table(scene, Help)))
print(with(d, table(scene, is.na(Punishment))))
print(with(d, table(scene, is.na(Helping))))
print(sapply(d, function(x) sum(is.na(x))))
