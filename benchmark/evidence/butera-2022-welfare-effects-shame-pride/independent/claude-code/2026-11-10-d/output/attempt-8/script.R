## Exploratory run: high-score outliers in Prolific (no RESULT lines)
suppressPackageStartupMessages({library(readr); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-d/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
for (f in c("prolific_survey_data.csv", "berkeley_survey_data.csv", "bu_qm222_survey_data.csv")) {
  x <- read_csv(file.path(D, f), show_col_types = FALSE)
  x$row <- seq_len(nrow(x))
  cat("=====", f, "\n")
  print(as.data.frame(x %>% filter(pmax(AnomPts, EarnPts, RecogPts, PracticePts) > 2200 | is.na(recog_group_assign)) %>%
    select(row, attention_check, recog_group_assign, PracticePts, AnomPts, EarnPts, RecogPts, Condition, Result, FinalPoints)))
}
