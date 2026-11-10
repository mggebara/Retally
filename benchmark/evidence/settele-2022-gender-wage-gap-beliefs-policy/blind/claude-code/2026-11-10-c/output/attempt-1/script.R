suppressMessages(library(haven))
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-c/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
for (f in c("SurveyStageI_WaveA_raw.dta","SurveyStageI_WaveB_raw.dta","SurveyStageII_WaveA_raw.dta","SurveyStageII_WaveB_raw.dta")) {
  d <- read_dta(paste0(D,f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x,"label"); if (is.null(lab)) lab <- ""
    if (is.numeric(x)) {
      u <- length(unique(x)); s <- sprintf("num nuniq=%d na=%d min=%s max=%s mean=%s", u, sum(is.na(x)), format(suppressWarnings(min(x,na.rm=TRUE))), format(suppressWarnings(max(x,na.rm=TRUE))), format(round(mean(x,na.rm=TRUE),3)))
    } else s <- sprintf("chr nuniq=%d ex=%s", length(unique(x)), substr(paste(head(unique(x),3),collapse="|"),1,60))
    vl <- attr(x,"labels"); vls <- if (!is.null(vl)) substr(paste(paste0(vl,"=",names(vl)),collapse=";"),1,150) else ""
    cat(v, "|", substr(lab,1,90), "|", s, "|", vls, "\n")
  }
}
