## Exploratory run: anonymous-round means under alternative exclusion sets (no RESULT lines)
suppressPackageStartupMessages({library(readr); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-d/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(Prolific = "prolific_survey_data.csv", Berkeley = "berkeley_survey_data.csv",
           BU = "bu_qm222_survey_data.csv")
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
  k <- pass & ruleA
  cat("=====", s, " ruleA anon mean", mean(x$AnomPts[k]), " N", sum(k), "\n")
  cat(" all rows anon mean", mean(x$AnomPts), "; pass only", mean(x$AnomPts[pass]), "; ruleA only", mean(x$AnomPts[ruleA]), "\n")
  cat(" pass & pref-shape-only rule:", mean(x$AnomPts[pass & apply(P, 1, shape)]), sum(pass & apply(P, 1, shape)), "\n")
  ex <- which(!k)
  print(data.frame(row = ex, att = x$attention_check[ex], coh = ruleA[ex], anom = x$AnomPts[ex], rec = x$RecogPts[ex], earn = x$EarnPts[ex]))
  nz <- which(k & !incb)
  cat(" coherent non-inc rows:\n"); print(data.frame(row = nz, anom = x$AnomPts[nz]))
  cat(" zero-anom-points in final:", sum(x$AnomPts[k] == 0), " any round <=1 pt:", sum(k & (x$AnomPts <= 1 | x$RecogPts <= 1 | x$EarnPts <= 1)), "\n")
}
