suppressPackageStartupMessages(library(readr))
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific="prolific_survey_data.csv", berkeley="berkeley_survey_data.csv", bu222="bu_qm222_survey_data.csv")
lv <- seq(0,1700,100)
shape <- function(x) {
  dx <- diff(x); s <- sign(dx); s <- s[s!=0]
  if (length(s)==0) return("flat")
  if (all(s>0)) return("inc")
  if (all(s<0)) return("dec")
  if (all(diff(s) <= 0)) return("peak")
  if (all(diff(s) >= 0)) return("dip")
  "other"
}
for (s in names(files)) {
  d <- suppressWarnings(read_csv(file.path(base, files[s]), show_col_types=FALSE, guess_max=5000))
  cat("=====", s, " dup ids:", sum(duplicated(d$id)), "\n")
  att <- is.na(d$attention_check)
  pref <- as.matrix(d[, paste0("preference_", lv)])
  rec <- as.matrix(d[, paste0("pref_rec_", lv, "_1")]); an <- as.matrix(d[, paste0("pref_anom_", lv, "_1")])
  w <- ifelse(pref==1, rec, -an)
  sw <- apply(sign(w), 1, shape)
  sel <- which(att & sw %in% c("other","dip"))
  if (s == "prolific") sel <- which(att & sw %in% c("other"))
  for (i in sel) {
    cat(sprintf("%-6s pref=%s | w=%s\n", sw[i], paste(pref[i,], collapse=""), paste(w[i,], collapse=" ")))
  }
}
