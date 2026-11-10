suppressPackageStartupMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific="prolific_survey_data.csv", berkeley="berkeley_survey_data.csv",
           bu222="bu_qm222_survey_data.csv", bu221="bu_qm221_survey_data.csv")
iv <- seq(0, 1700, 100)
inc <- function(x) all(diff(x) >= 0)
dec <- function(x) all(diff(x) <= 0)
peak <- function(x) any(sapply(which(x == max(x)), function(k) all(diff(x[1:k]) >= 0) && all(diff(x[k:length(x)]) <= 0)))
dip <- function(x) any(sapply(which(x == min(x)), function(k) all(diff(x[1:k]) <= 0) && all(diff(x[k:length(x)]) >= 0)))
nchg <- function(x) { s <- sign(diff(x)); s <- s[s != 0]; if (length(s) < 2) 0 else sum(diff(s) != 0) }
for (nm in names(files)) {
  d <- read_csv(file.path(base, files[nm]), show_col_types = FALSE, guess_max = 5000)
  cat("\n=====", nm, "rows", nrow(d), " dup ids:", sum(duplicated(d$id)), "\n")
  att <- is.na(d$attention_check)
  P <- as.matrix(d[, paste0("preference_", iv)])
  R <- as.matrix(d[, paste0("pref_rec_", iv, "_1")]); A <- as.matrix(d[, paste0("pref_anom_", iv, "_1")])
  W <- ifelse(P == 1, R, -A)
  S <- sign(W)
  for (k in c(18, 17)) {
    rr <- 1:k
    defs <- list(
      bin_incdec = function(i) inc(P[i, rr]) || dec(P[i, rr]),
      bin_incdecpeak = function(i) inc(P[i, rr]) || dec(P[i, rr]) || peak(P[i, rr]),
      bin_inc_only = function(i) inc(P[i, rr]),
      sign_incdec = function(i) inc(S[i, rr]) || dec(S[i, rr]),
      sign_incdecpeak = function(i) inc(S[i, rr]) || dec(S[i, rr]) || peak(S[i, rr]),
      wtp_incdecpeak = function(i) inc(W[i, rr]) || dec(W[i, rr]) || peak(W[i, rr]),
      wtp_le1chg = function(i) nchg(W[i, rr]) <= 1,
      wtp_le2chg = function(i) nchg(W[i, rr]) <= 2,
      wtp_le3chg = function(i) nchg(W[i, rr]) <= 3,
      wtp_corr0 = function(i) { x <- W[i, rr]; if (sd(x) == 0) TRUE else !is.na(cor(x, rr)) }
    )
    for (dn in names(defs)) {
      ok <- sapply(seq_len(nrow(d)), defs[[dn]])
      cat(sprintf("k=%d %-16s incoh all=%4d  among att-pass=%4d  final=%4d\n", k, dn, sum(!ok), sum(!ok & att), sum(ok & att)))
    }
  }
  # binary switches distribution
  sw <- apply(P, 1, function(x) sum(diff(x) != 0))
  cat("binary switch count (att pass):\n"); print(table(sw[att]))
  # correlation of W with interval
  cr <- apply(W[, 1:17], 1, function(x) if (sd(x) == 0) NA else cor(x, 1:17))
  cat("corr W~interval (att pass) quantiles:\n"); print(quantile(cr[att], c(0, .02, .05, .1, .5), na.rm = TRUE))
  cat("n sd0:", sum(is.na(cr) & att), "  n corr<=0:", sum(cr <= 0 & att, na.rm=TRUE), "\n")
  # spearman p-value based?
  pv <- apply(W[, 1:18], 1, function(x) if (sd(x) == 0) NA else suppressWarnings(cor.test(x, 1:18, method = "spearman")$p.value))
  cat("n spearman p>0.05 (att):", sum(pv > 0.05 & att, na.rm = TRUE), " p>0.1:", sum(pv > 0.1 & att, na.rm = TRUE), "\n")
  cat("prolific extra: BadgeGroupSize table\n"); if ("BadgeGroupSize" %in% names(d)) print(table(d$BadgeGroupSize, useNA="always"))
  cat("recog_group_assign NA:", sum(is.na(d$recog_group_assign)), " among att pass:", sum(is.na(d$recog_group_assign) & att), "\n")
}
