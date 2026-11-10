suppressMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-b/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
lv <- seq(0, 1700, 100)
nswitch <- function(x) sum(diff(x) != 0)
options(width = 250)
for (f in c("bu_qm222_survey_data.csv","berkeley_survey_data.csv","prolific_survey_data.csv")) {
  d <- suppressWarnings(read_csv(file.path(base, f), show_col_types = FALSE, guess_max = 5000))
  att <- is.na(d$attention_check)
  P <- as.matrix(d[paste0("preference_", lv)])
  R1 <- as.matrix(d[paste0("pref_rec_", lv, "_1")]); A1 <- as.matrix(d[paste0("pref_anom_", lv, "_1")])
  W <- ifelse(P == 1, R1, -A1)
  ns <- apply(P, 1, nswitch)
  inc <- apply(P, 1, function(x) all(diff(x) >= 0))
  sel <- which(att & !inc)
  cat("\n=====", f, " non-increasing binary among attn-pass:", length(sel), "\n")
  for (i in sel) cat(sprintf("sw=%2d grp=%-15s P=%s | W=%s\n", ns[i], d$recog_group_assign[i], paste(P[i,], collapse=""), paste(W[i,], collapse=" ")))
  # also: who in attention-pass has NA group assignment
  cat("attn-pass with NA group:", sum(att & is.na(d$recog_group_assign)), "\n")
  cat("attn-fail groups:", paste(d$recog_group_assign[!att], collapse=","), "\n")
}
