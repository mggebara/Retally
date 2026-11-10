suppressPackageStartupMessages(library(readr))
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
lv <- seq(0,1700,100)
shape <- function(x) {
  s <- sign(diff(x)); s <- s[s!=0]
  if (length(s)==0) return("flat")
  if (all(s>0)) return("inc")
  if (all(s<0)) return("dec")
  if (all(diff(s) <= 0)) return("peak")
  if (all(diff(s) >= 0)) return("dip")
  "other"
}
d <- suppressWarnings(read_csv(file.path(base, "prolific_survey_data.csv"), show_col_types=FALSE, guess_max=5000))
pref <- as.matrix(d[, paste0("preference_", lv)])
k <- is.na(d$attention_check) & apply(pref, 1, shape) %in% c("flat","inc","peak")
dk <- d[k, ]
sel <- which(is.na(dk$PracticePts) | is.na(dk$recog_group_assign))
print(as.data.frame(dk[sel, c("id","PracticePts","recog_group_assign","BadgeGroupSize","BadgeGroupShared","AnomPts","RecogPts","EarnPts","Condition","Result","Publicize","FinalPoints","age")]))
cat("top AnomPts/RecogPts/EarnPts:\n")
print(head(sort(dk$AnomPts, decreasing=TRUE), 8)); print(head(sort(dk$RecogPts, decreasing=TRUE), 8)); print(head(sort(dk$EarnPts, decreasing=TRUE), 8))
cat("Publicize:"); print(table(dk$Publicize, useNA="always"))
cat("CountRound:"); print(table(dk$CountRound, useNA="always"))
