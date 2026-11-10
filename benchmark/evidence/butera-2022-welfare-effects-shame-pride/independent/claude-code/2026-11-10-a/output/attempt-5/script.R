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
sp <- apply(pref, 1, shape)
att <- is.na(d$attention_check)
coh <- sp %in% c("flat","inc","peak")
cat("att fail:", sum(!att), " incoh all:", sum(!coh), " overlap:", sum(!att & !coh), " keep:", sum(att & coh), "\n")
k <- att & coh
print(names(d)[!grepl("pref|timer", names(d))])
for (v in names(d)[!grepl("pref|timer", names(d))]) {
  nm <- sum(is.na(d[[v]][k]))
  if (nm > 0) cat(v, "NA among keep:", nm, "\n")
}
cat("BadgeGroupSize:"); print(table(d$BadgeGroupSize[k], useNA="always"))
cat("recog_group_assign:"); print(table(d$recog_group_assign[k], useNA="always"))
cat("Sample:"); print(table(d$Sample[k], useNA="always"))
cat("pts summaries\n"); print(summary(d$AnomPts[k])); print(summary(d$RecogPts[k])); print(summary(d$EarnPts[k]))
cat("zero pts any:", sum((d$AnomPts==0 | d$RecogPts==0 | d$EarnPts==0)[k]), "\n")
cat("Result:"); print(table(d$Result[k], useNA="always"))
cat("Clicked:"); print(table(d$Clicked[k], useNA="always"))
for (s in c("berkeley_survey_data.csv","bu_qm222_survey_data.csv")) {
  e <- suppressWarnings(read_csv(file.path(base, s), show_col_types=FALSE, guess_max=5000))
  p <- as.matrix(e[, paste0("preference_", lv)]); sh <- apply(p, 1, shape)
  a <- is.na(e$attention_check); ch <- sh %in% c("flat","inc","peak")
  cat(s, " att fail", sum(!a), " incoh all", sum(!ch), " overlap", sum(!a & !ch), " keep", sum(a & ch), "\n")
}
