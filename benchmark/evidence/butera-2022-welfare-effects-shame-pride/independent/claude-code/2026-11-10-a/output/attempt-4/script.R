suppressPackageStartupMessages(library(readr))
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific="prolific_survey_data.csv", berkeley="berkeley_survey_data.csv", bu222="bu_qm222_survey_data.csv")
lv <- seq(0,1700,100)
turns <- function(x) { s <- sign(diff(x)); s <- s[s!=0]; if (length(s) < 2) 0 else sum(diff(s)!=0) }
nsw <- function(x) { x <- x[x!=0]; if (length(x)<2) 0 else sum(diff(sign(x))!=0) }
for (s in names(files)) {
  d <- suppressWarnings(read_csv(file.path(base, files[s]), show_col_types=FALSE, guess_max=5000))
  att <- is.na(d$attention_check)
  cat("=====", s, "\n")
  pref <- as.matrix(d[, paste0("preference_", lv)])
  rec <- as.matrix(d[, paste0("pref_rec_", lv, "_1")]); an <- as.matrix(d[, paste0("pref_anom_", lv, "_1")])
  w <- ifelse(pref==1, rec, -an)
  for (k in list(a18=1:18, a17=1:17)) {
    tw <- apply(w[att, k], 1, turns); ts <- apply(sign(w[att, k]), 1, turns); tp <- apply(pref[att, k], 1, turns)
    ns <- apply(w[att, k], 1, nsw)
    cat("cols", length(k), "\n")
    cat(" turns(w) >=k: ", sapply(1:12, function(j) sum(tw >= j)), "\n")
    cat(" turns(sign w) >=k: ", sapply(1:12, function(j) sum(ts >= j)), "\n")
    cat(" turns(pref) >=k: ", sapply(1:12, function(j) sum(tp >= j)), "\n")
    cat(" sign switches nonzero w >=k: ", sapply(1:12, function(j) sum(ns >= j)), "\n")
    # per-person correlation of w with level
    x <- lv[k]
    cr <- apply(w[att, k], 1, function(y) if (sd(y)==0) NA else cor(x, y))
    cat(" n sd0:", sum(is.na(cr)), " |cor|<.1:", sum(abs(cr) < .1, na.rm=T), " |cor|<.2:", sum(abs(cr) < .2, na.rm=T), " |cor|<.3:", sum(abs(cr) < .3, na.rm=T), "\n")
    pv <- apply(w[att, k], 1, function(y) if (sd(y)==0) NA else summary(lm(y ~ x))$coefficients[2,4])
    cat(" slope p>.05:", sum(pv > .05, na.rm=T), " p>.1:", sum(pv > .1, na.rm=T), " p>.5:", sum(pv>.5, na.rm=T), "\n")
  }
}
