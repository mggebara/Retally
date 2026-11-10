library(haven)
M <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-b/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
for (f in c("SurveyStageI_WaveA_raw.dta","SurveyStageI_WaveB_raw.dta","SurveyStageII_WaveA_raw.dta","SurveyStageII_WaveB_raw.dta")) {
  d <- read_dta(paste0(M,f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x,"label"); if (is.null(lab)) lab <- ""
    vl <- attr(x,"labels")
    vls <- if (!is.null(vl)) paste(paste0(vl,"=",names(vl)), collapse="; ") else ""
    ux <- unique(x); nu <- length(ux)
    smp <- if (is.numeric(x)) paste(head(sort(ux),8),collapse=",") else paste(substr(head(as.character(ux),4),1,30),collapse="|")
    cat(sprintf("%s [%s] lab='%s' nu=%d NA=%d smp=%s VL=%s\n", v, class(x)[1], substr(lab,1,80), nu, sum(is.na(x)), smp, substr(vls,1,200)))
  }
}
