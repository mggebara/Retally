# Exploratory 3: which Prolific rows look anomalous among the 970 (no estimates)
suppressMessages(library(readr)); suppressMessages(library(dplyr))
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-c/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
lv <- seq(0, 1700, 100)
pat <- function(x) { d <- diff(x); d <- sign(d[d != 0]); if (!length(d)) return("flat"); paste(ifelse(rle(d)$values > 0, "U", "D"), collapse = "") }
d <- suppressMessages(read_csv(file.path(base, "prolific_survey_data.csv"), show_col_types = FALSE, guess_max = 5000))
d$row <- seq_len(nrow(d))
d$pat <- apply(as.matrix(d[, paste0("preference_", lv)]), 1, pat)
f <- d[is.na(d$attention_check) & d$pat %in% c("flat", "U", "UD"), ]
bad <- f %>% mutate(gs = suppressWarnings(as.integer(sub("Prolific-([0-9]+)-.*", "\\1", recog_group_assign))),
                    shared_ok = BadgeGroupShared == BadgeGroupSize / 3 | (BadgeGroupSize == 300 & BadgeGroupShared == 100) | (BadgeGroupSize == 15 & BadgeGroupShared == 5),
                    flag = is.na(recog_group_assign) | is.na(PracticePts) | !shared_ok | (gs != BadgeGroupSize) | is.na(Condition)) %>%
  filter(flag | is.na(flag))
print(as.data.frame(bad[, c("row", "BadgeGroupSize", "BadgeGroupShared", "recog_group_assign", "PracticePts", "AnomPts", "EarnPts", "RecogPts", "Condition", "Result", "CountRound", "FinalPoints", "age", "Clicked")]))
# check FinalPoints consistency with CountRound
f$fp_chk <- with(f, ifelse(CountRound == "Anonymous Effort", AnomPts, ifelse(CountRound == "Publicly-Shared Effort", RecogPts, EarnPts)))
cat("FinalPoints mismatch:", sum(f$fp_chk != f$FinalPoints, na.rm = TRUE), "\n")
print(as.data.frame(f[which(f$fp_chk != f$FinalPoints), c("row", "CountRound", "AnomPts", "EarnPts", "RecogPts", "FinalPoints")]))
cat("Earn own check (EarnOwn vs EarnPts*0.002):", sum(abs(f$EarnOwn - f$EarnPts * 0.002) > 0.02, na.rm = TRUE), "\n")
print(table(f$CountRound, useNA = "always"))
