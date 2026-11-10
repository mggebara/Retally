suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-b/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
for (f in c("SurveyStageI_WaveA_raw.dta","SurveyStageI_WaveB_raw.dta","SurveyStageII_WaveA_raw.dta","SurveyStageII_WaveB_raw.dta")) {
  d <- read_dta(paste0(D,f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x,"label"); if (is.null(lab)) lab <- ""
    if (is.numeric(x)) {
      u <- length(unique(x)); s <- if (u<=12) paste(names(table(x, useNA="ifany")), table(x,useNA="ifany"), sep=":", collapse=" ") else sprintf("min=%.3g mean=%.3g max=%.3g NA=%d", min(x,na.rm=T), mean(x,na.rm=T), max(x,na.rm=T), sum(is.na(x)))
    } else { u <- length(unique(x)); s <- paste0("chr u=", u, " e.g. ", substr(paste(head(unique(x),3), collapse="|"),1,60)) }
    cat(sprintf("%s [%s] %s\n", v, substr(lab,1,70), s))
  }
}
