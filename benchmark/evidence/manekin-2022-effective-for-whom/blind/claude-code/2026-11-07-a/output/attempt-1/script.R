D <- "<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/blind/2026-11-07-a/mount/manekin_2022_effective_for_whom/Replication/Data/"
for (f in c("us_survey_wave1","isr_survey_wave1","us_survey_wave2","isr_survey_wave2")) {
  load(paste0(D, f, ".rdata")); d <- get(f)
  cat("=====", f, nrow(d), "\n"); str(d, list.len=30, vec.len=3)
  for (v in intersect(c("identity_protesters","tactic","survey","wave","black","commitment","group_goal","identity_protesters_fac"), names(d))) print(table(d[[v]], useNA="a"))
  print(summary(d[, intersect(c("degree_violence","police_action_required","recall_violence2","weight"), names(d)), drop=FALSE]))
  if ("survey" %in% names(d) && "wave" %in% names(d)) print(table(d$survey, d$wave, useNA="a"))
  print(sum(duplicated(d[[intersect(c("ResponseId","caseid"), names(d))[1]]])))
}
