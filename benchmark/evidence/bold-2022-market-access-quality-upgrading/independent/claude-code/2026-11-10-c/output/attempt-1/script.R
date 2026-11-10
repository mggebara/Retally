suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-c/mount/bold_2022_market_access_quality_upgrading/data/raw/"
desc <- function(f) {
  d <- read_dta(paste0(D, f))
  cat("\n=====", f, nrow(d), "x", ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    s <- if (is.numeric(x)) sprintf("num nNA=%d mean=%.4g min=%.4g max=%.4g", sum(is.na(x)), mean(x, na.rm=TRUE), suppressWarnings(min(x, na.rm=TRUE)), suppressWarnings(max(x, na.rm=TRUE))) else sprintf("chr nuniq=%d ex=%s", length(unique(x)), paste(head(unique(x),3), collapse="|"))
    cat(v, " [", lab, "] ", s, "\n", sep="")
  }
  invisible(d)
}
r <- desc("anonym_returns_data.dta")
g1 <- desc("panel_g1.dta")
s <- desc("seller_data.dta")
print(table(g1$survey_season, useNA="ifany"))
