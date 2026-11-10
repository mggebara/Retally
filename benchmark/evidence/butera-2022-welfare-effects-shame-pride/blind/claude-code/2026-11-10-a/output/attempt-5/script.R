suppressPackageStartupMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(berkeley="berkeley_survey_data.csv", bu222="bu_qm222_survey_data.csv", prolific="prolific_survey_data.csv")
iv <- seq(0, 1700, 100)
inc <- function(x) length(x) < 2 || all(diff(x) >= 0)
nzs <- function(x) { s <- sign(x); s[s != 0] }
for (nm in names(files)) {
  d <- read_csv(file.path(base, files[nm]), show_col_types = FALSE, guess_max = 5000)
  d$row <- seq_len(nrow(d))
  P <- as.matrix(d[, paste0("preference_", iv)])
  R <- as.matrix(d[, paste0("pref_rec_", iv, "_1")]); A <- as.matrix(d[, paste0("pref_anom_", iv, "_1")])
  W <- ifelse(P == 1, R, -A)
  att <- is.na(d$attention_check)
  nzinc <- apply(W, 1, function(x) inc(nzs(x)))
  bininc <- apply(P, 1, inc)
  cat("\n=====", nm, "\n")
  cat("incoherent (nzsign) all rows:", sum(!nzinc), " among att-fail:", sum(!nzinc & !att), " final:", sum(att & nzinc), "\n")
  sel <- which(att & nzinc & !bininc)
  for (i in sel) cat(sprintf("row %4d grp=%s P=%s sw=%d\n   W=%s\n", i, d$recog_group_assign[i], paste(P[i, ], collapse=""),
                             sum(diff(P[i, ]) != 0), paste(W[i, ], collapse=" ")))
  fin <- d[att & nzinc, ]
  cat("group sizes in final sample:\n"); print(sort(table(fin$recog_group_assign, useNA = "always")))
  cat("Final N:", nrow(fin), " NA group:", sum(is.na(fin$recog_group_assign)), "\n")
  cat("pts zero in all rounds:", sum(fin$AnomPts == 0 & fin$EarnPts == 0 & fin$RecogPts == 0), "\n")
  if (nm == "prolific") { cat("BadgeGroupSize x grp prefix (final):\n"); print(table(fin$BadgeGroupSize, sub("-[0-9]+$", "", fin$recog_group_assign), useNA="always")) }
  cat("mean AnomPts final:", mean(fin$AnomPts), " sd:", sd(fin$AnomPts), "\n")
}
