## Exploratory run: inspect data and test coherence definitions (no RESULT lines)
suppressPackageStartupMessages({library(readr); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-d/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(Prolific = "prolific_survey_data.csv", Berkeley = "berkeley_survey_data.csv",
           BU = "bu_qm222_survey_data.csv", QM221 = "bu_qm221_survey_data.csv")
lev <- seq(0, 1700, 100)
mono <- function(w, tol = 0) {
  d <- diff(w)
  inc <- all(d >= -tol); dec <- all(d <= tol)
  # single peaked: weakly increasing up to some k then weakly decreasing
  sp <- any(sapply(seq_along(w), function(k) all(diff(w[1:k]) >= -tol) && all(diff(w[k:length(w)]) <= tol)))
  st <- any(sapply(seq_along(w), function(k) all(diff(w[1:k]) <= tol) && all(diff(w[k:length(w)]) >= tol)))
  c(inc = inc, dec = dec, sp = sp, st = st)
}
for (s in names(files)) {
  x <- read_csv(file.path(D, files[s]), show_col_types = FALSE)
  cat("=====", s, "rows", nrow(x), "\n")
  cat("attention_check table:\n"); print(table(x$attention_check, useNA = "always"))
  cat("Condition:\n"); print(table(x$Condition, useNA = "always"))
  cat("NA pts: anom", sum(is.na(x$AnomPts)), "earn", sum(is.na(x$EarnPts)), "rec", sum(is.na(x$RecogPts)), "\n")
  P <- as.matrix(x[, paste0("preference_", lev)])
  R <- as.matrix(x[, paste0("pref_rec_", lev, "_1")])
  A <- as.matrix(x[, paste0("pref_anom_", lev, "_1")])
  W <- ifelse(P == 1, R, -A)
  cat("NA prefs:", sum(is.na(P)), " NA WTP:", sum(is.na(W)), " rows with any NA WTP:", sum(rowSums(is.na(W)) > 0), "\n")
  cat("max WTP", max(abs(W), na.rm = TRUE), "\n")
  pass <- is.na(x$attention_check)
  ok <- rowSums(is.na(W)) == 0
  for (useW in c("wtp", "pref")) {
    M <- if (useW == "wtp") W else P
    for (rng in c("18", "17")) {
      cols <- if (rng == "18") 1:18 else 1:17
      res <- t(apply(M[, cols, drop = FALSE], 1, function(w) if (any(is.na(w))) c(inc=NA,dec=NA,sp=NA,st=NA) else mono(w)))
      coh1 <- res[, "inc"] | res[, "dec"] | res[, "sp"]
      coh2 <- coh1 | res[, "st"]
      cat(sprintf("%s %s: among pass n=%d; incoherent(inc|dec|sp)=%d; incoherent(+trough)=%d; inc=%d\n",
                  useW, rng, sum(pass), sum(pass & !coh1, na.rm = TRUE), sum(pass & !coh2, na.rm = TRUE),
                  sum(pass & res[, "inc"], na.rm = TRUE)))
      cat(sprintf("   all rows: incoherent(inc|dec|sp)=%d\n", sum(!coh1, na.rm = TRUE)))
    }
  }
}
