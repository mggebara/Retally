## Exploratory run: group membership of borderline participants (no RESULT lines)
suppressPackageStartupMessages({library(readr); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-d/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(Prolific = "prolific_survey_data.csv", Berkeley = "berkeley_survey_data.csv")
lev <- seq(0, 1700, 100)
shape <- function(w) {
  inc <- all(diff(w) >= 0); dec <- all(diff(w) <= 0)
  sp <- any(sapply(seq_along(w), function(k) all(diff(w[1:k]) >= 0) && all(diff(w[k:length(w)]) <= 0)))
  inc | dec | sp
}
for (s in names(files)) {
  x <- read_csv(file.path(D, files[s]), show_col_types = FALSE)
  P <- as.matrix(x[, paste0("preference_", lev)])
  R <- as.matrix(x[, paste0("pref_rec_", lev, "_1")])
  A <- as.matrix(x[, paste0("pref_anom_", lev, "_1")])
  W <- ifelse(P == 1, R, -A)
  pass <- is.na(x$attention_check)
  incb <- apply(P, 1, function(p) all(diff(p) >= 0))
  wsh <- apply(W, 1, shape)
  zero <- apply(W, 1, function(w) all(w == 0))
  ruleA <- incb | (wsh & !zero)
  cat("=====", s, "\n")
  cat("NA group rows:\n"); print(which(is.na(x$recog_group_assign)))
  print(as.data.frame(x[is.na(x$recog_group_assign), c("attention_check", "Condition", "Result", "Publicize", "AnomPts", "EarnPts", "RecogPts")]))
  cat("NA-group ruleA:", ruleA[is.na(x$recog_group_assign)], "\n")
  ex <- which(pass & !ruleA)
  cat("excluded passers and groups:\n")
  print(data.frame(row = ex, group = x$recog_group_assign[ex], zero = zero[ex], P = apply(P[ex, , drop = FALSE], 1, paste, collapse = "")))
  cat("attention failers groups:\n")
  print(data.frame(row = which(!pass), group = x$recog_group_assign[!pass], att = x$attention_check[!pass], coh = ruleA[!pass]))
}
