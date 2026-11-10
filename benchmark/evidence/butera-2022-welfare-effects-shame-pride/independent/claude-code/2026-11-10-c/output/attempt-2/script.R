# Exploratory 2: Prolific sample size details after attention + binary-coherence exclusions (no estimates)
suppressMessages(library(readr)); suppressMessages(library(dplyr))
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-c/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
lv <- seq(0, 1700, 100)
pat <- function(x) { d <- diff(x); d <- sign(d[d != 0]); if (!length(d)) return("flat"); paste(ifelse(rle(d)$values > 0, "U", "D"), collapse = "") }
d <- suppressMessages(read_csv(file.path(base, "prolific_survey_data.csv"), show_col_types = FALSE, guess_max = 5000))
P <- as.matrix(d[, paste0("preference_", lv)])
d$pat <- apply(P, 1, pat)
d$coh <- d$pat %in% c("flat", "U", "UD")
d$pass <- is.na(d$attention_check)
cat("dup ids all:", sum(duplicated(d$id)), "\n")
f <- d[d$pass & d$coh, ]
cat("final n:", nrow(f), " dup ids:", sum(duplicated(f$id)), "\n")
cat("group assign missing:", sum(is.na(f$recog_group_assign)), "\n")
g <- table(f$recog_group_assign); print(sort(g))
cat("n groups:", length(g), "\n")
print(table(f$BadgeGroupSize, useNA = "always"))
print(table(f$BadgeGroupShared, useNA = "always"))
print(table(f$Result, useNA = "always"))
print(table(f$Publicize, useNA = "always"))
print(summary(f[, c("AnomPts", "EarnPts", "RecogPts", "PracticePts", "age")]))
cat("prolific_experience NA:", sum(is.na(f$prolific_experience)), "\n")
cat("gender table\n"); print(table(f$gender, useNA = "always"))
cat("Clicked\n"); print(table(f$Clicked, useNA = "always"))
# group prefix vs BadgeGroupSize
f$gp <- sub("-[0-9]+$", "", f$recog_group_assign)
print(table(f$gp, f$BadgeGroupSize, useNA = "always"))
# timers: which order timers nonmissing vs Condition
tm <- grep("timer_PageSubmit", names(f), value = TRUE)
f$tord <- apply(!is.na(as.matrix(f[, tm])), 1, function(z) paste(unique(toupper(sub("^[a-z]+_([a-z]+)_timer.*", "\\1", tm[z]))), collapse = "/"))
print(table(f$Condition, f$tord, useNA = "always"))
cat("rows with zero points any round:", sum(f$AnomPts == 0 | f$EarnPts == 0 | f$RecogPts == 0), "\n")
# Berkeley / BU group counts for check
for (fn in c("berkeley_survey_data.csv", "bu_qm222_survey_data.csv")) {
  b <- suppressMessages(read_csv(file.path(base, fn), show_col_types = FALSE, guess_max = 5000))
  b$coh <- apply(as.matrix(b[, paste0("preference_", lv)]), 1, pat) %in% c("flat", "U", "UD")
  bf <- b[is.na(b$attention_check) & b$coh, ]
  cat(fn, "final n:", nrow(bf), " dup:", sum(duplicated(bf$id)), "\n"); print(table(bf$recog_group_assign, useNA = "always"))
}
