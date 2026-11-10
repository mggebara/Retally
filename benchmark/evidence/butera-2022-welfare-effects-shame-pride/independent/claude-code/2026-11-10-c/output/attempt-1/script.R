# Exploratory: inspect samples, attention check, preference patterns (no estimates)
suppressMessages(library(readr)); suppressMessages(library(dplyr))
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-c/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(Prolific="prolific_survey_data.csv", Berkeley="berkeley_survey_data.csv",
           QM221="bu_qm221_survey_data.csv", QM222="bu_qm222_survey_data.csv")
lv <- seq(0, 1700, 100)
nsw <- function(x) { x <- x[!is.na(x)]; d <- diff(x); d <- d[d != 0]; sign(d) }
pat <- function(s) {
  if (length(s) == 0) return("flat")
  r <- rle(s)$values
  paste(ifelse(r > 0, "U", "D"), collapse = "")
}
for (nm in names(files)) {
  d <- suppressMessages(read_csv(file.path(base, files[nm]), show_col_types = FALSE, guess_max = 5000))
  cat("=====", nm, "rows", nrow(d), "\n")
  cat("attention_check table:\n"); print(table(d$attention_check, useNA = "always"))
  cat("Condition:\n"); print(table(d$Condition, useNA = "always"))
  cat("Sample:\n"); print(table(d$Sample, useNA = "always"))
  if ("BadgeGroupSize" %in% names(d)) print(table(d$BadgeGroupSize, useNA = "always"))
  cat("NA pts:", sum(is.na(d$AnomPts)), sum(is.na(d$EarnPts)), sum(is.na(d$RecogPts)), "\n")
  P <- as.matrix(d[, paste0("preference_", lv)])
  A <- as.matrix(d[, paste0("pref_anom_", lv, "_1")])
  R <- as.matrix(d[, paste0("pref_rec_", lv, "_1")])
  W <- ifelse(P == 1, R, -A)
  cat("NA in P:", sum(is.na(P)), " NA in W:", sum(is.na(W)), " rows with NA W:", sum(rowSums(is.na(W)) > 0), "\n")
  cat("W range:", range(W, na.rm = TRUE), "\n")
  pass <- is.na(d$attention_check)
  for (excl1700 in c(FALSE, TRUE)) {
    idx <- if (excl1700) 1:17 else 1:18
    pb <- apply(P[, idx, drop = FALSE], 1, function(x) pat(nsw(x)))
    pw <- apply(W[, idx, drop = FALSE], 1, function(x) pat(nsw(x)))
    cat("-- excl1700 =", excl1700, " binary patterns (attention passers):\n"); print(table(pb[pass]))
    cat("   WTP patterns (passers), collapsed:\n")
    pw2 <- ifelse(pw %in% c("flat","U","D","UD","DU"), pw, "other")
    print(table(pw2[pass]))
    print(table(pb[pass], pw2[pass]))
  }
  ord <- table(d$Condition);
}
