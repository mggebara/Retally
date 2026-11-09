D <- "<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/blind/2026-11-07-a/mount/manekin_2022_effective_for_whom/Replication/Data/"
for (f in c("isr_survey_text_analysis_eth","isr_survey_text_analysis_arab")) {
  load(paste0(D, f, ".rdata")); x <- get(f)
  cat("=====", f, "\n"); print(names(x))
  for (n in names(x)) {
    el <- x[[n]]
    if (is.data.frame(el)) {
      cat("--", n, nrow(el), "\n"); print(names(el))
      for (v in intersect(c("identity_protesters","survey","tactic"), names(el))) print(table(el[[v]], useNA="a"))
    } else cat("--", n, class(el), length(el), "\n")
  }
}
