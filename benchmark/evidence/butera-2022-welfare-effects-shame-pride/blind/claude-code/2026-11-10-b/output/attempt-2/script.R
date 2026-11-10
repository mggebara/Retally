# Exploratory run 2: alternative definitions of "incoherent" preferences.
# Prints no RESULT lines.
suppressPackageStartupMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-b/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific = "prolific_survey_data.csv", berkeley = "berkeley_survey_data.csv",
           bu222 = "bu_qm222_survey_data.csv", bu221 = "bu_qm221_survey_data.csv")
lev <- seq(0, 1700, 100)

shape <- function(w) {
  inc <- all(diff(w) >= 0); dec <- all(diff(w) <= 0)
  sp <- FALSE; sv <- FALSE
  for (k in seq_along(w)) {
    if (all(diff(w[1:k]) >= 0) && all(diff(w[k:length(w)]) <= 0)) sp <- TRUE
    if (all(diff(w[1:k]) <= 0) && all(diff(w[k:length(w)]) >= 0)) sv <- TRUE
  }
  c(inc = inc, dec = dec, sp = sp, sv = sv)
}
nsw <- function(s) { s <- s[s != 0]; if (length(s) < 2) 0 else sum(diff(s) != 0) }

report <- function(lbl, M, att_ok) {
  cl <- t(apply(M, 1, shape))
  c1 <- cl[, "inc"] | cl[, "dec"] | cl[, "sp"]
  c2 <- c1 | cl[, "sv"]
  c3 <- cl[, "inc"] | cl[, "dec"]
  cat(sprintf("%-28s incoh(inc/dec/peak): pass=%d all=%d | +valley: pass=%d all=%d | inc/dec only: pass=%d all=%d | nonincreasing share among pass&c1=%.3f\n",
              lbl, sum(!c1 & att_ok), sum(!c1), sum(!c2 & att_ok), sum(!c2), sum(!c3 & att_ok), sum(!c3),
              mean(!cl[att_ok & c1, "inc"])))
}

for (nm in names(files)) {
  df <- read_csv(file.path(base, files[[nm]]), show_col_types = FALSE, guess_max = 5000)
  att_ok <- is.na(df$attention_check)
  cat("\n=====", nm, "N =", nrow(df), " att fail =", sum(!att_ok), "\n")
  P <- as.matrix(df[, paste0("preference_", lev)])
  R <- as.matrix(df[, paste0("pref_rec_", lev, "_1")])
  A <- as.matrix(df[, paste0("pref_anom_", lev, "_1")])
  W <- ifelse(P == 1, R, -A)
  S <- sign(W)
  report("binary pref, 18 int", P, att_ok)
  report("binary pref, 17 int", P[, 1:17], att_ok)
  report("sign WTP, 18 int", S, att_ok)
  report("sign WTP, 17 int", S[, 1:17], att_ok)
  report("WTP, 18 int", W, att_ok)
  # number of strict sign switches ignoring zeros
  sw <- apply(S, 1, nsw)
  cat("switch counts (sign ignoring 0) among pass:\n"); print(table(sw[att_ok]))
  swp <- apply(2 * P - 1, 1, nsw)
  cat("switch counts (binary pref) among pass:\n"); print(table(swp[att_ok]))
  # count of zero-WTP intervals
  cat("share of WTP==0 cells:", mean(W == 0), "\n")
  # Spearman correlation of WTP with interval
  rho <- apply(W, 1, function(w) if (sd(w) == 0) NA else cor(w, seq_along(w), method = "spearman"))
  cat("NA (constant) WTP rows among pass:", sum(is.na(rho) & att_ok), "\n")
  cat("rho<=0 among pass:", sum(rho <= 0 & att_ok, na.rm = TRUE), "\n")
  # regression slope sign / significance
  pv <- apply(W, 1, function(w) { if (sd(w) == 0) return(NA); x <- seq_along(w); s <- summary(lm(w ~ x))$coefficients; if (nrow(s) < 2) NA else s[2, 4] })
  cat("non-significant (p>0.05) linear slope among pass (excl constant):", sum(pv > 0.05 & att_ok, na.rm = TRUE), " p>0.1:", sum(pv > 0.1 & att_ok, na.rm = TRUE), "\n")
}
