suppressPackageStartupMessages(library(readr))
base <- "<repo>/benchmark/.cache/claude-code/butera-2022-welfare-effects-shame-pride/independent/2026-11-10-a/mount/butera_2022_welfare_effects_shame_pride/Packet/Raw Data"
files <- c(prolific="prolific_survey_data.csv", berkeley="berkeley_survey_data.csv", bu221="bu_qm221_survey_data.csv", bu222="bu_qm222_survey_data.csv")
lv <- seq(0,1700,100)
for (s in names(files)) {
  d <- suppressWarnings(read_csv(file.path(base, files[s]), show_col_types=FALSE, guess_max=5000))
  cat("=====", s, nrow(d), "\n")
  cat("attention_check table:\n"); print(table(d$attention_check, useNA="always"))
  cat("Sample:"); print(table(d$Sample, useNA="always"))
  cat("Condition:"); print(table(d$Condition, useNA="always"))
  cat("missing pts:", sum(is.na(d$AnomPts)), sum(is.na(d$RecogPts)), sum(is.na(d$EarnPts)), "\n")
  pref <- as.matrix(d[, paste0("preference_", lv)])
  rec <- as.matrix(d[, paste0("pref_rec_", lv, "_1")]); an <- as.matrix(d[, paste0("pref_anom_", lv, "_1")])
  cat("pref NA:", sum(is.na(pref)), " rec nonNA when pref0:", sum(!is.na(rec) & pref==0, na.rm=T), " an nonNA when pref1:", sum(!is.na(an) & pref==1, na.rm=T), "\n")
  cat("rec NA when pref1:", sum(is.na(rec) & pref==1, na.rm=T), " an NA when pref0:", sum(is.na(an) & pref==0, na.rm=T), "\n")
  w <- ifelse(pref==1, rec, -an)
  print(summary(as.vector(w)))
  att <- is.na(d$attention_check)
  cls <- function(w) {
    dw <- diff(w); dw <- dw[!is.na(dw)]
    inc <- all(dw >= 0); dec <- all(dw <= 0)
    s <- sign(dw); s <- s[s!=0]
    peak <- length(s)==0 || all(diff(s) <= 0)
    dip <- length(s)==0 || all(diff(s) >= 0)
    c(inc=inc, dec=dec, peak=peak, dip=dip)
  }
  for (k in list(1:18, 1:17)) {
    cm <- t(apply(w[, k, drop=FALSE], 1, cls))
    coh1 <- cm[, "inc"] | cm[, "dec"] | cm[, "peak"]
    coh2 <- coh1 | cm[, "dip"]
    cat("cols", length(k), " among attention-pass n=", sum(att), ": inc", sum(cm[att,"inc"]), " dec", sum(cm[att,"dec"]), " incoh(inc/dec/peak)", sum(!coh1[att]), " incoh(+dip)", sum(!coh2[att]), " incoh(inc only)", sum(!cm[att,"inc"]), "\n")
    cat("   all n: incoh(inc/dec/peak)", sum(!coh1), "\n")
  }
  pw <- apply(pref, 1, function(p) sum(diff(p)!=0))
  cat("pref switches among att-pass:"); print(table(pw[att]))
}
