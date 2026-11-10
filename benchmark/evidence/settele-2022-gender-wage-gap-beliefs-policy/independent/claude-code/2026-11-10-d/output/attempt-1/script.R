suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-d/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
options(width = 200)
for (f in c("SurveyStageI_WaveA_raw.dta", "SurveyStageI_WaveB_raw.dta", "SurveyStageII_WaveA_raw.dta", "SurveyStageII_WaveB_raw.dta")) {
  d <- read_dta(paste0(D, f))
  cat("\n=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]
    lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    if (grepl("Time$", v)) { next }
    u <- unique(x)
    nu <- length(u)
    cls <- class(x)[1]
    s <- if (is.numeric(x)) {
      if (nu <= 12) paste(names(table(x, useNA = "ifany")), table(x, useNA = "ifany"), sep = ":", collapse = " ")
      else sprintf("min=%g med=%g max=%g NA=%d", min(x, na.rm = TRUE), median(x, na.rm = TRUE), max(x, na.rm = TRUE), sum(is.na(x)))
    } else {
      if (nu <= 8) paste(substr(names(table(x, useNA = "ifany")), 1, 25), table(x, useNA = "ifany"), sep = ":", collapse = " | ")
      else paste0("nuniq=", nu, " ex=", substr(paste(head(u, 3), collapse = " | "), 1, 80))
    }
    vl <- attr(x, "labels")
    vls <- if (!is.null(vl)) paste0(" LBL{", substr(paste(vl, names(vl), sep = "=", collapse = ";"), 1, 160), "}") else ""
    cat(sprintf("%s [%s] '%s': %s%s\n", v, cls, substr(lab, 1, 70), s, vls))
  }
}
