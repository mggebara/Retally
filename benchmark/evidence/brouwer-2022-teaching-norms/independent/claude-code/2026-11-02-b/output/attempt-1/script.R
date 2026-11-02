d <- readr::read_csv("<repo>/benchmark/.cache/claude-code/brouwer-2022-teaching-norms/independent/2026-11-02-b/mount/brouwer_2022_teaching_norms/Data Replication Package EJ MS20210782/3 replication package/Data/master.csv", show_col_types = FALSE)
print(dim(d)); str(d)
for (v in c("scene","Condition","Violation","ViolationHelp","Help","Child","male","hugo","Morning","witness","rich","Rain","Hot","School")) { cat("==", v, "\n"); print(table(d[[v]], useNA="ifany")) }
print(with(d, table(scene, Condition, useNA="ifany")))
print(with(d, table(Violation, ViolationHelp, Help, useNA="ifany")))
print(with(d, table(scene, is.na(Punishment)))); print(with(d, table(scene, is.na(Helping))))
