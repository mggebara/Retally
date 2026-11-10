suppressPackageStartupMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific="prolific_survey_data.csv", berkeley="berkeley_survey_data.csv", bu222="bu_qm222_survey_data.csv")
iv <- seq(0, 1700, 100)
inc <- function(x) length(x) < 2 || all(diff(x) >= 0)
nzs <- function(x) { s <- sign(x); s[s != 0] }
for (nm in names(files)) {
  d <- read_csv(file.path(base, files[nm]), show_col_types = FALSE, guess_max = 5000)
  P <- as.matrix(d[, paste0("preference_", iv)])
  R <- as.matrix(d[, paste0("pref_rec_", iv, "_1")]); A <- as.matrix(d[, paste0("pref_anom_", iv, "_1")])
  W <- ifelse(P == 1, R, -A)
  att <- is.na(d$attention_check)
  nzinc <- apply(W, 1, function(x) inc(nzs(x)))
  fin <- d[att & nzinc, ]
  cat("\n=====", nm, "final", nrow(fin), "\n")
  tcols <- grep("timer_PageSubmit$", names(d), value = TRUE)
  # timers for own ordering
  own <- sapply(seq_len(nrow(fin)), function(i) { cond <- tolower(fin$Condition[i]); cols <- grep(paste0("_", cond, "_timer"), tcols, value = TRUE); sum(!is.na(unlist(fin[i, cols]))) })
  cat("n own-order timers non-missing:\n"); print(table(own))
  othert <- sapply(seq_len(nrow(fin)), function(i) { cond <- tolower(fin$Condition[i]); cols <- tcols[!grepl(paste0("_", cond, "_timer"), tcols)]; sum(!is.na(unlist(fin[i, cols]))) })
  cat("other-order timers non-missing:\n"); print(table(othert))
  cat("any pts > 2500:", sum(pmax(fin$AnomPts, fin$EarnPts, fin$RecogPts) > 2500), "\n")
  cat("NA counts in demog: age", sum(is.na(fin$age)), " gender", sum(is.na(fin$gender)), " race", sum(is.na(fin$race)), " Clicked", sum(is.na(fin$Clicked)), " PracticePts NA", sum(is.na(fin$PracticePts)), "\n")
  cat("Result table:\n"); print(table(fin$Result, useNA = "always"))
  cat("Publicize:\n"); print(table(fin$Publicize, useNA = "always"))
  if ("prolific_experience" %in% names(fin)) { cat("prolific_experience <15 or NA:", sum(is.na(fin$prolific_experience)), sum(fin$prolific_experience < 15, na.rm=TRUE), "\n") }
  cat("age range:", range(fin$age, na.rm=TRUE), " age<18:", sum(fin$age < 18, na.rm=TRUE), "\n")
  # check point/donation consistency
  rate <- if (nm == "prolific") 0.002 else 0.005
  cat("AnomDon mismatch:", sum(abs(fin$AnomDon - fin$AnomPts * rate) > 0.06), " RecogDon mismatch:", sum(abs(fin$RecogDon - fin$RecogPts * rate) > 0.06), " EarnDon mismatch:", sum(abs(fin$EarnDon - fin$EarnPts * rate) > 0.06), "\n")
  cat("PracticePts summary:\n"); print(summary(fin$PracticePts))
  cat("rows with group NA: ", which(is.na(fin$recog_group_assign)), "\n")
  print(as.data.frame(fin[is.na(fin$recog_group_assign), c("Condition","AnomPts","EarnPts","RecogPts","Result","Publicize","age")]))
}
