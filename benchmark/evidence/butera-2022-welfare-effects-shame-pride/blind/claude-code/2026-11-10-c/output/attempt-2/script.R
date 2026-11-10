suppressPackageStartupMessages({library(readr); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-c/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific="prolific_survey_data.csv", berkeley="berkeley_survey_data.csv", bu222="bu_qm222_survey_data.csv")
lv <- seq(0, 1700, 100)
classify <- function(w) {
  s <- sign(diff(w)); s <- s[s != 0]
  if (length(s) == 0) return("flat")
  if (all(s > 0)) return("inc")
  if (all(s < 0)) return("dec")
  ch <- sum(diff(s) != 0)
  if (ch == 1 && s[1] > 0) return("peak")
  if (ch == 1 && s[1] < 0) return("valley")
  return(paste0("multi", min(ch, 4)))
}
for (nm in names(files)) {
  x <- read_csv(file.path(D, files[nm]), show_col_types = FALSE, guess_max = 5000)
  cat("=====", nm, "rows", nrow(x), " unique ids", length(unique(x$id)), "\n")
  P <- as.matrix(x[paste0("preference_", lv)])
  W <- sapply(lv, function(l) { p <- x[[paste0("preference_", l)]]
    ifelse(p == 1, x[[paste0("pref_rec_", l, "_1")]], -x[[paste0("pref_anom_", l, "_1")]]) })
  pass <- is.na(x$attention_check)
  cb <- apply(P, 1, classify); cw <- apply(W, 1, classify)
  cat("binary-preference class among attention passers:\n"); print(table(cb[pass]))
  cat("binary class x WTP class (passers):\n"); print(table(cb[pass], cw[pass]))
  cat("NA in points (passers):", sum(is.na(x$AnomPts[pass]) | is.na(x$EarnPts[pass]) | is.na(x$RecogPts[pass])), "\n")
  cat("zero WTP cells (passers):", sum((W == 0)[pass, ]), "\n")
}
