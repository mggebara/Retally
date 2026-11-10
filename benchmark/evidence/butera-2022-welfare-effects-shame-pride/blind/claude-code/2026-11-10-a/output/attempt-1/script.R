suppressPackageStartupMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific="prolific_survey_data.csv", berkeley="berkeley_survey_data.csv",
           bu221="bu_qm221_survey_data.csv", bu222="bu_qm222_survey_data.csv")
iv <- seq(0, 1700, 100)
is_mono_inc <- function(x) all(diff(x) >= 0)
is_mono_dec <- function(x) all(diff(x) <= 0)
is_peak <- function(x) { k <- which.max(x); # some argmax: check all
  any(sapply(which(x == max(x)), function(k) all(diff(x[1:k]) >= 0) && all(diff(x[k:length(x)]) <= 0))) }
coh <- function(x) is_mono_inc(x) || is_mono_dec(x) || is_peak(x)
for (nm in names(files)) {
  d <- read_csv(file.path(base, files[nm]), show_col_types = FALSE, guess_max = 5000)
  cat("\n=====", nm, "rows", nrow(d), "\n")
  cat("attention_check table:\n"); print(table(d$attention_check, useNA = "always"))
  cat("Sample:\n"); print(table(d$Sample, useNA="always"))
  cat("Condition:\n"); print(table(d$Condition, useNA="always"))
  cat("NA pts: anom", sum(is.na(d$AnomPts)), "earn", sum(is.na(d$EarnPts)), "recog", sum(is.na(d$RecogPts)), "\n")
  print(summary(d[, c("AnomPts","EarnPts","RecogPts")]))
  P <- as.matrix(d[, paste0("preference_", iv)])
  R <- as.matrix(d[, paste0("pref_rec_", iv, "_1")])
  A <- as.matrix(d[, paste0("pref_anom_", iv, "_1")])
  cat("NA preference cells:", sum(is.na(P)), " rows w/ any NA pref:", sum(rowSums(is.na(P))>0), "\n")
  cat("pref=1 & rec NA:", sum(P==1 & is.na(R), na.rm=TRUE), " pref=0 & anom NA:", sum(P==0 & is.na(A), na.rm=TRUE), "\n")
  cat("pref=1 & anom notNA:", sum(P==1 & !is.na(A), na.rm=TRUE), " pref=0 & rec notNA:", sum(P==0 & !is.na(R), na.rm=TRUE), "\n")
  cat("max rec", max(R, na.rm=TRUE), " max anom", max(A, na.rm=TRUE), " zeros rec", sum(R==0,na.rm=TRUE), " zeros anom", sum(A==0,na.rm=TRUE), "\n")
  W <- ifelse(P == 1, R, -A)
  W0 <- W; W0[is.na(W0)] <- 0
  att_ok <- is.na(d$attention_check)
  cat("attention pass:", sum(att_ok), "\n")
  for (rng in list(1:18, 1:17)) {
    cw <- apply(W0[, rng, drop=FALSE], 1, coh)
    cp <- apply(P[, rng, drop=FALSE], 1, function(x) if (any(is.na(x))) FALSE else coh(x))
    cpinc <- apply(P[, rng, drop=FALSE], 1, function(x) if (any(is.na(x))) FALSE else is_mono_inc(x)||is_mono_dec(x))
    cat(sprintf("intervals %d: incoherent(WTP) all=%d amongpass=%d | incoherent(binary pref, inc/dec/peak) all=%d amongpass=%d | binary inc/dec only amongpass=%d\n",
        length(rng), sum(!cw), sum(!cw & att_ok), sum(!cp), sum(!cp & att_ok), sum(!cpinc & att_ok)))
    cat("  WTP mono-inc among pass&coh:", sum(apply(W0[, rng], 1, is_mono_inc) & cw & att_ok), "\n")
  }
  # single dipped too
  sd <- function(x) any(sapply(which(x == min(x)), function(k) all(diff(x[1:k]) <= 0) && all(diff(x[k:length(x)]) >= 0)))
  cw2 <- apply(W0, 1, function(x) coh(x) || sd(x))
  cat("incoherent WTP allowing U too, among pass:", sum(!cw2 & att_ok), "\n")
  cat("rows with all-NA W:", sum(rowSums(!is.na(W))==0), "\n")
}
