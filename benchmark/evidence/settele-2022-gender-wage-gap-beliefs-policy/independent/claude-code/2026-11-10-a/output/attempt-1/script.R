suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-a/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
for (f in c("SurveyStageI_WaveA_raw.dta","SurveyStageI_WaveB_raw.dta","SurveyStageII_WaveA_raw.dta","SurveyStageII_WaveB_raw.dta")) {
  d <- read_dta(paste0(D,f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  nm <- names(d); nm <- nm[!grepl("Time$", nm)]
  for (v in nm) {
    x <- d[[v]]; lab <- attr(x,"label"); if (is.null(lab)) lab <- ""
    if (is.numeric(x)) {
      u <- unique(x)
      s <- if (length(u) <= 12) paste(sort(u), collapse=",") else sprintf("min=%.3g mean=%.4g max=%.3g", min(x,na.rm=T), mean(x,na.rm=T), max(x,na.rm=T))
      cat(sprintf("%s [%s] NA=%d %s | %s\n", v, class(x)[1], sum(is.na(x)), s, substr(lab,1,80)))
    } else {
      u <- unique(as.character(x)); cat(sprintf("%s [%s] nuniq=%d e.g. %s | %s\n", v, class(x)[1], length(u), paste(head(u,4),collapse=" ; "), substr(lab,1,60)))
    }
  }
}
