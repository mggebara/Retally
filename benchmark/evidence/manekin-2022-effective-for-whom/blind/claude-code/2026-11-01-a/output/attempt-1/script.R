d <- "<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/blind/2026-11-01-a/mount/manekin_2022_effective_for_whom/Replication/Data/"
for (f in c("us_survey_wave1","isr_survey_wave1","us_survey_wave2","isr_survey_wave2")) {
  load(paste0(d, f, ".rdata")); x <- get(f)
  cat("=====", f, nrow(x), "\n"); str(x)
  for (v in intersect(names(x), c("identity_protesters","tactic","survey","wave","black","commitment","group_goal","identity_protesters_fac")))
    print(table(x[[v]], useNA="ifany"))
  cat("NA counts:\n"); print(colSums(is.na(x)))
  if ("weight" %in% names(x)) print(summary(x$weight))
}
