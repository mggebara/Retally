## Exploratory run: duplicates and candidate coherence rules (no RESULT lines)
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
  pconst <- apply(P, 1, function(p) length(unique(p)) == 1)
  cat("=====", s, "n", nrow(x), " unique ids", length(unique(x$id)), " dup ids", sum(duplicated(x$id)), "\n")
  cat(" pass", sum(pass), " pass&incb", sum(pass & incb), "\n")
  cat(" pass&incb&allzeroW", sum(pass & incb & zero), " of which P nonconstant", sum(pass & incb & zero & !pconst), "\n")
  ruleA <- incb | (wsh & !zero)
  ruleB <- incb | wsh
  ruleZ <- (incb & !(zero & !pconst)) | (wsh & !zero)
  cat(" final N ruleA", sum(pass & ruleA), " ruleB", sum(pass & ruleB), " ruleZ", sum(pass & ruleZ), "\n")
  cat(" all rows ruleA coherent", sum(ruleA), " incoherent all rows", sum(!ruleA), "\n")
  cat(" Sample var:"); print(table(x$Sample, useNA = "always"))
  if ("recog_group_assign" %in% names(x)) { cat(" groups:"); print(table(x$recog_group_assign[pass & ruleA], useNA = "always")) }
  cat(" points summary anom/earn/rec:\n"); print(summary(x[, c("AnomPts", "EarnPts", "RecogPts")]))
}
