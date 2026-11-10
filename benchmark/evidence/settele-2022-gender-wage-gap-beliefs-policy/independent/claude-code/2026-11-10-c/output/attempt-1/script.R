# Exploratory: inspect variables (no RESULT lines)
suppressMessages(library(haven))
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-c/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
options(width = 250)
for (f in c("SurveyStageI_WaveA_raw.dta","SurveyStageI_WaveB_raw.dta","SurveyStageII_WaveA_raw.dta","SurveyStageII_WaveB_raw.dta")) {
  d <- read_dta(paste0(D, f))
  cat("\n\n=========== ", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]
    lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    vl <- attr(x, "labels")
    vls <- if (!is.null(vl)) paste(paste0(vl, "=", names(vl)), collapse="; ") else ""
    cls <- class(x)[1]
    nna <- sum(is.na(x) | (is.character(x) & x == ""))
    if (is.numeric(x)) {
      u <- sort(unique(x[!is.na(x)]))
      desc <- if (length(u) == 0) "allNA" else if (length(u) <= 12) paste(sapply(u, function(k) paste0(k, ":", sum(x == k, na.rm=TRUE))), collapse=" ") else
        sprintf("n_unique=%d min=%.3g mean=%.4g max=%.3g", length(u), min(u), mean(x, na.rm=TRUE), max(u))
    } else {
      u <- unique(x); desc <- paste0("n_unique=", length(u), " ex: ", paste(head(substr(u,1,30), 4), collapse=" | "))
    }
    cat(sprintf("%s [%s] NA=%d | %s | %s | %s\n", v, cls, nna, substr(lab,1,80), substr(vls,1,200), substr(desc,1,250)))
  }
}
