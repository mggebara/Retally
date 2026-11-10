## Exploratory run: dump non-monotone preference profiles (no RESULT lines)
suppressPackageStartupMessages({library(readr); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-d/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(Prolific = "prolific_survey_data.csv", Berkeley = "berkeley_survey_data.csv",
           BU = "bu_qm222_survey_data.csv")
lev <- seq(0, 1700, 100)
for (s in names(files)) {
  x <- read_csv(file.path(D, files[s]), show_col_types = FALSE)
  P <- as.matrix(x[, paste0("preference_", lev)])
  R <- as.matrix(x[, paste0("pref_rec_", lev, "_1")])
  A <- as.matrix(x[, paste0("pref_anom_", lev, "_1")])
  W <- ifelse(P == 1, R, -A)
  pass <- is.na(x$attention_check)
  incb <- apply(P, 1, function(p) all(diff(p) >= 0))
  incw <- apply(W, 1, function(p) all(diff(p) >= 0))
  cat("=====", s, " pass&binary-inc:", sum(pass & incb), " pass&wtp-weakly-inc:", sum(pass & incw), "\n")
  idx <- which(pass & !incb)
  for (i in idx) cat(sprintf("%4d P=%s | W=%s\n", i, paste(P[i, ], collapse = ""), paste(W[i, ], collapse = " ")))
}
