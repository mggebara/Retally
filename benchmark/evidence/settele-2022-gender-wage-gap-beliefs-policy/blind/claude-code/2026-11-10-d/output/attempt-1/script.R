suppressMessages(library(haven))
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-d/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
for (f in c("SurveyStageI_WaveA_raw.dta","SurveyStageI_WaveB_raw.dta","SurveyStageII_WaveA_raw.dta","SurveyStageII_WaveB_raw.dta")) {
  d <- read_dta(paste0(D,f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x,"label"); if (is.null(lab)) lab <- ""
    if (is.numeric(x)) {
      u <- unique(x)
      cat(sprintf("%s | %s | num nNA=%d nuniq=%d min=%s max=%s mean=%s", v, substr(lab,1,60), sum(is.na(x)), length(u), format(suppressWarnings(min(x,na.rm=TRUE))), format(suppressWarnings(max(x,na.rm=TRUE))), format(mean(x,na.rm=TRUE),digits=4)))
      vl <- attr(x,"labels"); if (!is.null(vl) && length(vl)<12) cat(" labels:", paste(names(vl),vl,sep="=",collapse="; "))
      if (length(u)<=8) cat(" tab:", paste(names(table(x,useNA="ifany")), table(x,useNA="ifany"), sep=":", collapse=" "))
      cat("\n")
    } else {
      cat(sprintf("%s | %s | chr nuniq=%d ex=%s\n", v, substr(lab,1,60), length(unique(x)), substr(paste(head(unique(x),3),collapse=" || "),1,80)))
    }
  }
}
