suppressMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-b/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
lv <- seq(0, 1700, 100)
mono_inc <- function(x) all(diff(x) >= -1e-9)
mono_dec <- function(x) all(diff(x) <= 1e-9)
single_peak <- function(x) { # weakly increasing then weakly decreasing
  for (k in seq_along(x)) if (mono_inc(x[1:k]) && mono_dec(x[k:length(x)])) return(TRUE)
  FALSE }
single_trough <- function(x) single_peak(-x)
for (f in c("prolific_survey_data.csv","berkeley_survey_data.csv","bu_qm222_survey_data.csv")) {
  d <- suppressWarnings(read_csv(file.path(base, f), show_col_types = FALSE, guess_max = 5000))
  cat("\n=====", f, nrow(d), " unique ids:", length(unique(d$id)), "\n")
  cat("NA pts:", sum(is.na(d$AnomPts)), sum(is.na(d$RecogPts)), sum(is.na(d$EarnPts)), "\n")
  P <- as.matrix(d[paste0("preference_", lv)])
  R1 <- as.matrix(d[paste0("pref_rec_", lv, "_1")]); A1 <- as.matrix(d[paste0("pref_anom_", lv, "_1")])
  W <- ifelse(P == 1, R1, -A1)
  cat("NA in W:", sum(is.na(W)), " rows with any NA W:", sum(rowSums(is.na(W)) > 0), "\n")
  cat("both rec and anom nonmissing cells:", sum(!is.na(R1) & !is.na(A1)), "\n")
  att <- is.na(d$attention_check)
  cat("pass attention:", sum(att), "\n")
  for (nm in c("W18","W17","P18","P17")) {
    M <- switch(nm, W18 = W, W17 = W[, 1:17], P18 = P, P17 = P[, 1:17])
    inc <- apply(M, 1, function(x) !any(is.na(x)) && mono_inc(x))
    dec <- apply(M, 1, function(x) !any(is.na(x)) && mono_dec(x))
    pk  <- apply(M, 1, function(x) !any(is.na(x)) && single_peak(x))
    tr  <- apply(M, 1, function(x) !any(is.na(x)) && single_trough(x))
    coh <- inc | dec | pk
    cat(sprintf("%s: among attn-pass: incoh(inc|dec|peak)=%d  incoh(+trough)=%d  incoh(inc|dec only)=%d  nonincreasing-not-inc=%d | all rows incoh=%d\n",
        nm, sum(att & !coh), sum(att & !(coh | tr)), sum(att & !(inc | dec)), sum(att & !inc), sum(!coh)))
  }
  # Use W18 coherent; final N
  inc <- apply(W, 1, mono_inc); coh <- apply(W, 1, function(x) mono_inc(x) || mono_dec(x) || single_peak(x))
  cat("final N (attn & coh W18):", sum(att & coh), " monotone-inc share among final:", mean(inc[att & coh]), "\n")
  cat("budget-censored share (|W|==max):", mean(abs(W[att & coh, ]) >= max(abs(W), na.rm=TRUE)), " max:", max(abs(W), na.rm=TRUE), "\n")
}
