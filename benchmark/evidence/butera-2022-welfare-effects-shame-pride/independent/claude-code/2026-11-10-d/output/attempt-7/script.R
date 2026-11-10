## Exploratory run: attention-check raw values and preference-pattern coherence rule (no RESULT lines)
suppressPackageStartupMessages({library(readr); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-d/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(Prolific = "prolific_survey_data.csv", Berkeley = "berkeley_survey_data.csv",
           BU = "bu_qm222_survey_data.csv")
lev <- seq(0, 1700, 100)
for (s in names(files)) {
  x <- read_csv(file.path(D, files[s]), col_types = cols(.default = col_character()))
  cat("=====", s, "\n")
  cat(" raw attention_check values:\n"); print(table(x$attention_check, useNA = "always"))
  cat(" raw values with whitespace/odd chars:", sum(!is.na(x$attention_check) & !grepl("^[0-9]+$", x$attention_check)), "\n")
  P <- as.matrix(x[, paste0("preference_", lev)])
  ps <- apply(P, 1, paste, collapse = "")
  cat(" NA in P:", sum(is.na(P)), "\n")
  coh <- grepl("^0*1*$", ps) | grepl("^0+1+0+$", ps)
  pass <- is.na(x$attention_check)
  k <- pass & coh
  cat(" incoherent (all rows):", sum(!coh), " among passers:", sum(pass & !coh), " final:", sum(k), "\n")
  cat(" anon mean final:", mean(as.numeric(x$AnomPts[k])), "\n")
  if (s != "BU") { cat(" group counts final:\n"); print(table(x$recog_group_assign[k], useNA = "always")) }
  cat(" passers with NA group:", which(pass & is.na(x$recog_group_assign)), "\n")
  # other potential flags: missing points, missing condition, duplicated
  cat(" NA points/cond among final:", sum(k & (is.na(x$AnomPts) | is.na(x$EarnPts) | is.na(x$RecogPts) | is.na(x$Condition))), "\n")
  cat(" Result values:\n"); print(table(x$Result[k], useNA = "always"))
}
