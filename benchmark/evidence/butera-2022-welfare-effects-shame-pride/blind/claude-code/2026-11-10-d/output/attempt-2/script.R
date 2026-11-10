# Exploratory 2: candidate definitions of "incoherent" preferences. No estimates.
suppressPackageStartupMessages({library(readr); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-d/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
rd <- function(f) read_csv(file.path(D, f), show_col_types = FALSE, guess_max = 10000)
dl <- list(prolific = rd("prolific_survey_data.csv"), berkeley = rd("berkeley_survey_data.csv"),
           bu221 = rd("bu_qm221_survey_data.csv"), bu222 = rd("bu_qm222_survey_data.csv"))
ints <- seq(0, 1700, 100)
shape <- function(x) {
  x <- x[!is.na(x)]
  s <- sign(diff(x)); s <- s[s != 0]
  if (length(s) == 0) return("flat")
  r <- rle(s)$values
  key <- paste(ifelse(r > 0, "U", "D"), collapse = "")
  key
}
for (nm in names(dl)) {
  d <- dl[[nm]]
  d <- d[is.na(d$attention_check), ]
  P <- as.matrix(d[, paste0("preference_", ints)])
  R <- as.matrix(d[, paste0("pref_rec_", ints, "_1")])
  A <- as.matrix(d[, paste0("pref_anom_", ints, "_1")])
  W <- ifelse(P == 1, R, -A)
  cat("\n=====", nm, "attention passers", nrow(d), "\n")
  cat("-- indicator shapes (18):\n"); print(table(apply(P, 1, shape)))
  cat("-- indicator shapes (17):\n"); print(table(apply(P[, 1:17], 1, shape)))
  S <- sign(W)
  cat("-- WTP sign shapes (18):\n"); print(table(apply(S, 1, shape)))
  cat("-- WTP shapes (18):\n"); print(sort(table(apply(W, 1, shape)), decreasing = TRUE)[1:12])
  cat("-- WTP n runs (18):\n"); print(table(sapply(apply(W, 1, shape), nchar)))
  cat("-- WTP zero WTP with pref=1 cells:", sum(P == 1 & W == 0), " pref=0 & W==0:", sum(P == 0 & W == 0), "\n")
  cat("BadgeGroupSize:\n"); if ("BadgeGroupSize" %in% names(d)) print(table(d$BadgeGroupSize, useNA = "ifany"))
  cat("Sample:\n"); print(table(d$Sample, useNA = "ifany"))
  cat("recog_group_assign:\n"); print(table(d$recog_group_assign, useNA = "ifany"))
  cat("dup ids:", sum(duplicated(d$id)), " NA age:", sum(is.na(d$age)), "\n")
}
