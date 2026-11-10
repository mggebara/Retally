suppressPackageStartupMessages({library(readr); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-c/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific="prolific_survey_data.csv", berkeley="berkeley_survey_data.csv",
           bu221="bu_qm221_survey_data.csv", bu222="bu_qm222_survey_data.csv")
lv <- seq(0, 1700, 100)
classify <- function(w) {
  d <- diff(w); s <- sign(d); s <- s[s != 0]
  if (length(s) == 0) return("flat")
  if (all(s > 0)) return("inc")
  if (all(s < 0)) return("dec")
  ch <- sum(diff(s) != 0)
  if (ch == 1 && s[1] > 0) return("peak")
  if (ch == 1 && s[1] < 0) return("valley")
  return(paste0("multi", ch))
}
for (nm in names(files)) {
  x <- read_csv(file.path(D, files[nm]), show_col_types = FALSE, guess_max = 5000)
  cat("=====", nm, "rows", nrow(x), "\n")
  print(table(is.na(x$attention_check)))
  print(table(x$Condition, useNA = "ifany"))
  print(summary(x[, c("AnomPts", "EarnPts", "RecogPts")]))
  W <- sapply(lv, function(l) {
    p <- x[[paste0("preference_", l)]]
    ifelse(p == 1, x[[paste0("pref_rec_", l, "_1")]], -x[[paste0("pref_anom_", l, "_1")]])
  })
  cat("pref values:\n"); print(table(unlist(x[paste0("preference_", lv)]), useNA = "ifany"))
  cat("NA in W per row:\n"); print(table(rowSums(is.na(W))))
  cl <- apply(W, 1, function(w) if (any(is.na(w))) "NA" else classify(w))
  print(table(cl, attfail = !is.na(x$attention_check)))
  cl17 <- apply(W[, 1:17], 1, function(w) if (any(is.na(w))) "NA" else classify(w))
  print(table(cl17, attfail = !is.na(x$attention_check)))
  cat("max WTP:", max(W, na.rm = TRUE), " min:", min(W, na.rm = TRUE), "\n")
  if ("BadgeGroupSize" %in% names(x)) print(table(x$BadgeGroupSize))
}
