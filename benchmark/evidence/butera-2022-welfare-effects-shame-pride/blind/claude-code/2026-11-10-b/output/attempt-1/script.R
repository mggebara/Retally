# Exploratory run: sample sizes, attention check, WTP construction, coherence rules.
# Prints no RESULT lines.
suppressPackageStartupMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-b/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific = "prolific_survey_data.csv", berkeley = "berkeley_survey_data.csv",
           bu222 = "bu_qm222_survey_data.csv", bu221 = "bu_qm221_survey_data.csv")
lev <- seq(0, 1700, 100)

classify <- function(w) {
  # w: numeric vector of 18 WTPs (ordered by interval)
  d <- diff(w)
  inc <- all(d >= 0); dec <- all(d <= 0)
  # single-peaked (weakly increasing then weakly decreasing)
  sp <- FALSE; sv <- FALSE
  for (k in seq_along(w)) {
    if (all(diff(w[1:k]) >= 0) && all(diff(w[k:length(w)]) <= 0)) sp <- TRUE
    if (all(diff(w[1:k]) <= 0) && all(diff(w[k:length(w)]) >= 0)) sv <- TRUE
  }
  c(inc = inc, dec = dec, sp = sp, sv = sv)
}

for (nm in names(files)) {
  df <- read_csv(file.path(base, files[[nm]]), show_col_types = FALSE, guess_max = 5000)
  cat("\n=====", nm, "rows:", nrow(df), " unique id:", length(unique(df$id)), "\n")
  cat("attention_check table:\n"); print(table(df$attention_check, useNA = "always"))
  cat("Condition table:\n"); print(table(df$Condition, useNA = "always"))
  cat("Sample:\n"); print(table(df$Sample, useNA = "always"))
  if ("BadgeGroupSize" %in% names(df)) print(table(df$BadgeGroupSize, useNA = "always"))
  cat("recog_group_assign:\n"); print(table(df$recog_group_assign, useNA = "always"))
  cat("missing pts: anom", sum(is.na(df$AnomPts)), "earn", sum(is.na(df$EarnPts)), "rec", sum(is.na(df$RecogPts)), "\n")
  print(summary(df[, c("AnomPts", "EarnPts", "RecogPts")]))
  P <- as.matrix(df[, paste0("preference_", lev)])
  R <- as.matrix(df[, paste0("pref_rec_", lev, "_1")])
  A <- as.matrix(df[, paste0("pref_anom_", lev, "_1")])
  cat("pref NA count:", sum(is.na(P)), " pref values:"); print(table(P, useNA = "always"))
  cat("pref=1 & rec missing:", sum(P == 1 & is.na(R), na.rm = TRUE),
      " pref=1 & anom nonmissing:", sum(P == 1 & !is.na(A), na.rm = TRUE), "\n")
  cat("pref=0 & anom missing:", sum(P == 0 & is.na(A), na.rm = TRUE),
      " pref=0 & rec nonmissing:", sum(P == 0 & !is.na(R), na.rm = TRUE), "\n")
  cat("range rec:", range(R, na.rm = TRUE), " range anom:", range(A, na.rm = TRUE), "\n")
  W <- ifelse(P == 1, R, -A)
  W0 <- W; W0[!is.na(P) & is.na(W0)] <- 0
  att_ok <- is.na(df$attention_check)
  cl <- t(apply(W0, 1, function(w) if (any(is.na(w))) c(inc = NA, dec = NA, sp = NA, sv = NA) else classify(w)))
  cat("rows with any NA WTP after fill:", sum(is.na(cl[, 1])), "\n")
  coh1 <- cl[, "inc"] | cl[, "dec"] | cl[, "sp"]
  coh2 <- coh1 | cl[, "sv"]
  cat("incoherent (inc/dec/peak) all:", sum(!coh1, na.rm = TRUE), " among att-pass:", sum(!coh1 & att_ok, na.rm = TRUE), "\n")
  cat("incoherent (inc/dec/peak/valley) all:", sum(!coh2, na.rm = TRUE), " among att-pass:", sum(!coh2 & att_ok, na.rm = TRUE), "\n")
  cat("final (att pass & coh1):", sum(att_ok & coh1, na.rm = TRUE), " (att pass & coh2):", sum(att_ok & coh2, na.rm = TRUE), "\n")
  cat("among final coh1: monotone inc share:", mean(cl[att_ok & coh1 & !is.na(coh1), "inc"]), "\n")
  # alternative: coherence on the binary preference only
  clp <- t(apply(P, 1, function(w) if (any(is.na(w))) c(inc = NA, dec = NA, sp = NA, sv = NA) else classify(w)))
  cohp <- clp[, "inc"] | clp[, "dec"] | clp[, "sp"]
  cat("incoherent on binary pref (inc/dec/peak) among att-pass:", sum(!cohp & att_ok, na.rm = TRUE), "\n")
  # excluding 1700 interval
  cl17 <- t(apply(W0[, 1:17], 1, function(w) if (any(is.na(w))) c(inc = NA, dec = NA, sp = NA, sv = NA) else classify(w)))
  coh17 <- cl17[, "inc"] | cl17[, "dec"] | cl17[, "sp"]
  cat("incoherent excl 1700 (inc/dec/peak) among att-pass:", sum(!coh17 & att_ok, na.rm = TRUE), "\n")
}
