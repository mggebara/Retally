D <- "<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/independent/2026-10-21-b/mount/manekin_2022_effective_for_whom/Replication/Data"
for (f in c("us_survey_wave1","isr_survey_wave1","us_survey_wave2","isr_survey_wave2")) {
  load(file.path(D, paste0(f, ".rdata")))
  d <- get(f)
  cat("=====", f, nrow(d), "\n")
  str(d)
  for (v in intersect(c("identity_protesters","tactic","survey","wave","black","commitment","group_goal","identity_protesters_fac"), names(d))) print(table(d[[v]], useNA="ifany"))
  for (v in intersect(c("degree_violence","police_action_required","weight"), names(d))) print(summary(d[[v]]))
}
