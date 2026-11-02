# Exploration: inspect conjoint columns, response coding, attribute names/levels (no RESULT lines)
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/seeded/2026-10-21-b/mount/arias_2022_changing_tides_climate_migration"
for (f in c("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv",
            "Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")) {
  x <- read.csv(file.path(D, f), stringsAsFactors = FALSE, check.names = FALSE, header = TRUE, encoding = "UTF-8")
  cat("=====", f, nrow(x), "\n")
  print(x[1:3, c("ResponseId", "Finished", "force_choice", "F-1-1", "F-1-1-1")])
  x <- x[-(1:2), ]
  cat("rows after drop 2:", nrow(x), "\n")
  for (q in c("force_choice","Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")) {cat(q, ":"); print(table(x[[q]], useNA="always"))}
  for (a in 1:7) {cat("F-1-",a,":"); print(table(x[[paste0("F-1-",a)]], useNA="always"))}
  for (a in 1:7) {cat("F-1-1-",a,":"); print(table(x[[paste0("F-1-1-",a)]], useNA="always"))}
  cat("task-attr name consistent across tasks within resp? ", all(x[["F-1-1"]] == x[["F-9-1"]]), "\n")
  print(head(x$ResponseId, 8)); print(head(x$Status, 8)); print(table(x$Status)); print(table(x$Finished))
  resp <- x[, c("force_choice","Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")]
  nn <- rowSums(resp != "" & !is.na(resp))
  print(table(nn))
}
