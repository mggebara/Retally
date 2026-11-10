suppressMessages({library(readr); library(dplyr); library(readxl)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-b/mount/butera_2022_welfare_effects_shame_pride/Packet"
dd <- file.path(base, "data dictionary.xlsx")
for (s in excel_sheets(dd)) {
  cat("==== SHEET", s, "\n")
  x <- read_excel(dd, sheet = s, col_names = FALSE)
  x <- as.data.frame(x)
  for (i in seq_len(nrow(x))) cat(paste(ifelse(is.na(unlist(x[i,])), "", unlist(x[i,])), collapse=" | "), "\n")
}
files <- c("prolific_survey_data.csv","berkeley_survey_data.csv","bu_qm221_survey_data.csv","bu_qm222_survey_data.csv")
for (f in files) {
  d <- suppressWarnings(read_csv(file.path(base, "Raw Data", f), show_col_types = FALSE, guess_max = 5000))
  cat("\n==== FILE", f, nrow(d), "rows,", ncol(d), "cols\n")
  cat(paste(names(d), collapse=","), "\n")
  cat("attention_check:\n"); print(table(d$attention_check, useNA="always"))
  for (v in intersect(c("Sample","Condition","Result","CountRound","Publicize","recog_group_assign","Clicked","group","Group"), names(d))) {cat(v, ":\n"); print(head(sort(table(d[[v]], useNA="always"), decreasing=TRUE), 15))}
  for (v in grep("Pts$|Points", names(d), value=TRUE)) {cat(v, ": "); print(summary(d[[v]]))}
  pc <- grep("^pref_", names(d), value=TRUE)
  cat("nonmissing counts of pref_ cols:\n"); print(sapply(d[pc], function(z) sum(!is.na(z))))
  cat("preference_ table:\n"); print(table(unlist(d[grep("^preference_", names(d))]), useNA="always"))
  print(as.data.frame(head(d[, c("id", grep("^preference_|^pref_", names(d), value=TRUE))], 3)))
}
