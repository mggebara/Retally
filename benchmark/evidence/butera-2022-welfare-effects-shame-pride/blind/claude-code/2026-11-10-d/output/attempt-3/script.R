# Exploratory 3: sample counts under the indicator-shape coherence rule; group sizes; odd rows. No estimates.
suppressPackageStartupMessages({library(readr); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-d/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
rd <- function(f) read_csv(file.path(D, f), show_col_types = FALSE, guess_max = 10000)
dl <- list(prolific = rd("prolific_survey_data.csv"), berkeley = rd("berkeley_survey_data.csv"),
           bu222 = rd("bu_qm222_survey_data.csv"))
ints <- seq(0, 1700, 100)
shape <- function(x) {
  s <- sign(diff(x)); s <- s[s != 0]
  if (length(s) == 0) return("flat")
  paste(ifelse(rle(s)$values > 0, "U", "D"), collapse = "")
}
for (nm in names(dl)) {
  d <- dl[[nm]]
  P <- as.matrix(d[, paste0("preference_", ints)])
  d$shape <- apply(P, 1, shape)
  d$att_ok <- is.na(d$attention_check)
  d$coh <- d$shape %in% c("flat", "U", "UD")
  cat("\n=====", nm, "\n"); print(table(att_ok = d$att_ok, coh = d$coh))
  f <- d[d$att_ok & d$coh, ]
  cat("final N:", nrow(f), "\n")
  print(table(f$recog_group_assign, useNA = "ifany"))
  na <- d[is.na(d$recog_group_assign), c("id", "attention_check", "shape", "AnomPts", "RecogPts", "EarnPts", "Result", "CountRound", "Publicize", "Clicked", "age")]
  print(as.data.frame(na))
  cat("Pts summaries (final):\n"); print(summary(f[, c("AnomPts", "RecogPts", "EarnPts", "PracticePts")]))
  cat("Result:\n"); print(table(f$Result, useNA = "ifany"))
  cat("Publicize:\n"); print(table(f$Publicize, useNA = "ifany"))
  cat("Clicked:\n"); print(table(f$Clicked, useNA = "ifany"))
  cat("zero-point rounds (final): anom", sum(f$AnomPts == 0), "rec", sum(f$RecogPts == 0), "earn", sum(f$EarnPts == 0), "\n")
  cat("EarnOwn/EarnPts ratio range:", range(f$EarnOwn / pmax(f$EarnPts, 1), na.rm = TRUE), "\n")
}
