suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading/data/raw/"
show <- function(f) {
  d <- read_dta(paste0(D, f))
  cat("=====", f, nrow(d), "x", ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    if (is.numeric(x)) {
      s <- sprintf("n=%d mean=%.4g min=%.4g max=%.4g", sum(!is.na(x)), mean(x, na.rm=TRUE), suppressWarnings(min(x, na.rm=TRUE)), suppressWarnings(max(x, na.rm=TRUE)))
    } else {
      u <- unique(x); s <- sprintf("chr n=%d nuniq=%d ex=%s", sum(!is.na(x) & x != ""), length(u), paste(head(u, 4), collapse="|"))
    }
    cat(v, "|", lab, "|", s, "\n")
  }
}
for (f in c("anonym_returns_data.dta", "panel_g1.dta", "seller_data.dta")) show(f)
