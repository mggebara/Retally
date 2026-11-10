suppressMessages(library(haven))
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-a/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
for (f in c("SurveyStageI_WaveA_raw.dta","SurveyStageI_WaveB_raw.dta","SurveyStageII_WaveA_raw.dta","SurveyStageII_WaveB_raw.dta")) {
  d <- read_dta(paste0(D,f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x,"label"); if (is.null(lab)) lab <- ""
    vl <- attr(x,"labels"); vls <- if (!is.null(vl)) paste(paste0(vl,"=",names(vl)), collapse="; ") else ""
    nm <- sum(!is.na(x) & !(is.character(x) & x==""))
    sm <- if (is.numeric(x)) paste(round(quantile(as.numeric(x), c(0,.5,1), na.rm=TRUE),3), collapse="/") else paste(head(unique(x),3),collapse="|")
    cat(sprintf("%s | %s | n=%d | %s | %s | %s\n", v, class(x)[1], nm, substr(lab,1,80), substr(sm,1,60), substr(vls,1,150)))
  }
}
