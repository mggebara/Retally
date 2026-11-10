suppressMessages({library(haven)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-b/mount/bold_2022_market_access_quality_upgrading/data/raw"
options(width = 250)
desc <- function(f) {
  d <- read_dta(file.path(D, f))
  cat("\n\n######## ", f, " nrow=", nrow(d), " ncol=", ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]
    lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    nn <- sum(!is.na(x))
    if (is.numeric(x)) {
      s <- if (nn > 0) sprintf("mean=%.4g min=%.4g max=%.4g nuniq=%d", mean(x, na.rm=TRUE), min(x, na.rm=TRUE), max(x, na.rm=TRUE), length(unique(x[!is.na(x)]))) else ""
    } else {
      u <- unique(x[!is.na(x) & x != ""]); s <- paste0("chr nuniq=", length(u), " ex=", paste(head(u, 3), collapse="|"))
    }
    cat(sprintf("%-40s n=%4d %s :: %s\n", v, nn, s, substr(lab, 1, 90)))
  }
}
for (f in c("anonym_returns_data.dta", "panel_g1.dta", "seller_data.dta", "buy_data.dta", "maize_quality_gr1.dta", "maize_quality_gr0.dta")) desc(f)
