# Exploratory: inspect raw files, attention check, WTP construction, coherence classes. No estimates.
suppressPackageStartupMessages({library(readr); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/blind/2026-11-10-d/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
rd <- function(f) read_csv(file.path(D, f), show_col_types = FALSE, guess_max = 10000)
dl <- list(prolific = rd("prolific_survey_data.csv"), berkeley = rd("berkeley_survey_data.csv"),
           bu221 = rd("bu_qm221_survey_data.csv"), bu222 = rd("bu_qm222_survey_data.csv"))
ints <- seq(0, 1700, 100)
for (nm in names(dl)) {
  d <- dl[[nm]]
  cat("\n=====", nm, "rows", nrow(d), "unique ids", length(unique(d$id)), "\n")
  print(table(attention_check = d$attention_check, useNA = "ifany"))
  print(table(Condition = d$Condition, useNA = "ifany"))
  cat("missing pts: Anom", sum(is.na(d$AnomPts)), "Recog", sum(is.na(d$RecogPts)), "Earn", sum(is.na(d$EarnPts)), "\n")
  P <- as.matrix(d[, paste0("preference_", ints)])
  R <- as.matrix(d[, paste0("pref_rec_", ints, "_1")])
  A <- as.matrix(d[, paste0("pref_anom_", ints, "_1")])
  cat("pref NA count:", sum(is.na(P)), " pref values:", paste(names(table(P)), collapse = ","), "\n")
  W <- ifelse(P == 1, R, -A)
  cat("WTP NA cells:", sum(is.na(W)), " rows with any NA WTP:", sum(rowSums(is.na(W)) > 0), "\n")
  cat("rec nonNA while pref==0:", sum(!is.na(R) & P == 0, na.rm = TRUE), " anom nonNA while pref==1:", sum(!is.na(A) & P == 1, na.rm = TRUE), "\n")
  cat("WTP range:", range(W, na.rm = TRUE), "\n")
  att_ok <- is.na(d$attention_check)
  cls <- function(w, use = 1:18) {
    w <- w[use]
    if (any(is.na(w))) return("na")
    dw <- diff(w)
    if (all(dw >= 0)) return("inc")
    if (all(dw <= 0)) return("dec")
    s <- sign(dw); s <- s[s != 0]
    # single-peaked: + ... then - ... ; single-trough: - then +
    r <- rle(s)$values
    if (identical(r, c(1, -1))) return("peak")
    if (identical(r, c(-1, 1))) return("trough")
    return("other")
  }
  c18 <- apply(W, 1, cls); c17 <- apply(W, 1, cls, use = 1:17)
  cat("classes (18 intervals), attention-passers:\n"); print(table(c18[att_ok]))
  cat("classes (17 intervals), attention-passers:\n"); print(table(c17[att_ok]))
  # preference-indicator pattern classes
  cp <- apply(P, 1, cls)
  cat("pref indicator classes, attention-passers:\n"); print(table(cp[att_ok]))
}
