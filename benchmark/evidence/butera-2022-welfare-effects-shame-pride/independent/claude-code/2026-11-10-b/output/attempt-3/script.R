suppressMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-b/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
lv <- seq(0, 1700, 100)
dirchanges <- function(x) { s <- sign(diff(x)); s <- s[s != 0]; if (length(s) < 2) 0 else sum(diff(s) != 0) }
nswitch <- function(x) sum(diff(x) != 0)
for (f in c("prolific_survey_data.csv","berkeley_survey_data.csv","bu_qm222_survey_data.csv")) {
  d <- suppressWarnings(read_csv(file.path(base, f), show_col_types = FALSE, guess_max = 5000))
  att <- is.na(d$attention_check)
  P <- as.matrix(d[paste0("preference_", lv)])
  R1 <- as.matrix(d[paste0("pref_rec_", lv, "_1")]); A1 <- as.matrix(d[paste0("pref_anom_", lv, "_1")])
  W <- ifelse(P == 1, R1, -A1)
  ns <- apply(P, 1, nswitch); dcW <- apply(W, 1, dirchanges); dcP <- apply(P, 1, dirchanges)
  first <- P[,1]; last <- P[,18]
  cat("\n=====", f, "\n")
  cat("binary switches (attn pass):\n"); print(table(ns[att]))
  cat("binary switches x first value:\n"); print(table(ns[att], first[att]))
  cat("W direction changes (attn pass):\n"); print(table(dcW[att]))
  cat("cross binary switches x W dirchanges:\n"); print(table(ns[att], pmin(dcW[att], 6)))
  # all-zero WTP / constant
  cst <- apply(W, 1, function(x) length(unique(x)) == 1)
  cat("constant W:", sum(cst[att]), " constant P:", sum(apply(P,1,function(x) length(unique(x))==1)[att]), "\n")
  cat("start 1 end 0 (any path):", sum((first==1 & last==0)[att]), "\n")
}
