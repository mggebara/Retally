# Exploratory run 3: binary-preference pattern classes and overlap with other flags.
# Prints no RESULT lines.
suppressPackageStartupMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-b/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific = "prolific_survey_data.csv", berkeley = "berkeley_survey_data.csv",
           bu222 = "bu_qm222_survey_data.csv", bu221 = "bu_qm221_survey_data.csv")
lev <- seq(0, 1700, 100)

pclass <- function(p) {
  s <- paste(rle(p)$values, collapse = "")
  if (s %in% c("0", "1", "01")) return("increasing")
  if (s == "010") return("interior_peak")
  if (s == "10") return("decreasing")
  if (s == "101") return("valley")
  "multi_switch"
}

for (nm in names(files)) {
  df <- read_csv(file.path(base, files[[nm]]), show_col_types = FALSE, guess_max = 5000)
  att_ok <- is.na(df$attention_check)
  P <- as.matrix(df[, paste0("preference_", lev)])
  cls <- apply(P, 1, pclass)
  cls17 <- apply(P[, 1:17], 1, pclass)
  cat("\n=====", nm, "N =", nrow(df), "\n")
  cat("class (18 intervals) x attention pass:\n"); print(table(cls, att_ok))
  cat("class (17 intervals) x attention pass:\n"); print(table(cls17, att_ok))
  inco <- !(cls %in% c("increasing", "interior_peak"))
  cat("incoherent (not increasing / interior peak) among pass:", sum(inco & att_ok), " final N:", sum(!inco & att_ok), "\n")
  cat("NA group assign x att_ok x incoherent:\n"); print(table(group_na = is.na(df$recog_group_assign), att_ok, inco))
  cat("Publicize:\n"); print(table(df$Publicize, useNA = "always"))
  cat("Result:\n"); print(table(df$Result, useNA = "always"))
  cat("zero points rounds (any) among pass&coh:", sum((df$AnomPts == 0 | df$EarnPts == 0 | df$RecogPts == 0) & att_ok & !inco), "\n")
  if ("BadgeGroupSize" %in% names(df)) { cat("BadgeGroupSize among final:\n"); print(table(df$BadgeGroupSize[att_ok & !inco], useNA = "always")) }
  cat("attention_check raw values:\n"); print(table(df$attention_check, useNA = "always"))
}
