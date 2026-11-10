suppressPackageStartupMessages(library(readr))
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific="prolific_survey_data.csv", berkeley="berkeley_survey_data.csv", bu222="bu_qm222_survey_data.csv")
target <- c(prolific=968, berkeley=384, bu222=118)
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
  att <- is.na(d$attention_check)
  cat("=====", s, "pass", sum(att), "need incoherent", sum(att)-target[s], "\n")
  pref <- as.matrix(d[, paste0("preference_", lv)])
  rec <- as.matrix(d[, paste0("pref_rec_", lv, "_1")]); an <- as.matrix(d[, paste0("pref_anom_", lv, "_1")])
  w <- ifelse(pref==1, rec, -an)
  for (k in list(all18=1:18, no1700=1:17)) {
    cat("-- cols", length(k), "\n")
    sp <- apply(pref[, k], 1, shape); sw <- apply(sign(w[, k]), 1, shape); ww <- apply(w[, k], 1, shape)
    cat("pref shape:"); print(table(sp[att]))
    cat("sign(w) shape:"); print(table(sw[att]))
    cat("w shape:"); print(table(ww[att]))
    cat("cross pref x sign(w):\n"); print(table(sp[att], sw[att]))
  }
  # zero WTP counts
  cat("n zero WTP cells among pass:", sum(w[att,]==0), " persons with all zero:", sum(apply(w[att,]==0,1,all)), "\n")
}
