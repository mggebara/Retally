suppressPackageStartupMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(berkeley="berkeley_survey_data.csv", bu222="bu_qm222_survey_data.csv", prolific="prolific_survey_data.csv")
iv <- seq(0, 1700, 100)
inc <- function(x) all(diff(x) >= 0)
for (nm in names(files)) {
  d <- read_csv(file.path(base, files[nm]), show_col_types = FALSE, guess_max = 5000)
  att <- is.na(d$attention_check)
  P <- as.matrix(d[, paste0("preference_", iv)])
  R <- as.matrix(d[, paste0("pref_rec_", iv, "_1")]); A <- as.matrix(d[, paste0("pref_anom_", iv, "_1")])
  W <- ifelse(P == 1, R, -A)
  ni <- which(att & !apply(P, 1, inc))
  cat("\n=====", nm, " non-increasing (binary) among att pass:", length(ni), "\n")
  for (i in ni) {
    cat(sprintf("row %4d grpNA=%d P=%s\n   W=%s\n", i, is.na(d$recog_group_assign[i]), paste(P[i, ], collapse = ""),
                paste(W[i, ], collapse = " ")))
  }
  cat("rows with NA recog_group_assign (att pass):", which(att & is.na(d$recog_group_assign)), "\n")
}
