# Exploratory run 1: inspect variables (no RESULT lines)
suppressMessages({library(haven); library(dplyr)})
options(width = 250)
M <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-c/mount/bold_2022_market_access_quality_upgrading/data/raw/"
desc <- function(f) {
  d <- read_dta(paste0(M, f))
  cat("\n==========", f, nrow(d), "x", ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]
    lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    if (is.numeric(x)) {
      s <- sprintf("num n=%d mean=%.4g min=%.4g max=%.4g", sum(!is.na(x)), mean(x, na.rm=TRUE), suppressWarnings(min(x, na.rm=TRUE)), suppressWarnings(max(x, na.rm=TRUE)))
    } else {
      u <- unique(x); s <- sprintf("chr n=%d nuniq=%d ex=%s", sum(!is.na(x) & x != ""), length(u), paste(head(u, 4), collapse="|"))
    }
    vl <- attr(x, "labels")
    vls <- if (!is.null(vl)) paste0(" VL{", paste(paste0(vl, "=", names(vl)), collapse=";"), "}") else ""
    cat(sprintf("%-40s %-60s %s%s\n", v, substr(lab, 1, 60), s, substr(vls, 1, 200)))
  }
  invisible(d)
}
for (f in c("anonym_returns_data.dta", "panel_g1.dta", "seller_data.dta", "buy_data.dta", "maize_quality_gr1.dta", "maize_quality_gr0.dta")) desc(f)
d <- read_dta(paste0(M, "panel_g1.dta"))
cat("\nseason x buy_treatment table (g1)\n"); print(table(d$survey_season, d$buy_treatment, useNA = "ifany"))
