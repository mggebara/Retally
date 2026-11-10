suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading/data/raw/"
desc <- function(f){
  d <- read_dta(paste0(D,f)); cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x,"label"); if(is.null(lab)) lab <- ""
    if (is.numeric(x)) s <- sprintf("num nNA=%d mean=%.4g min=%.4g max=%.4g nuniq=%d", sum(is.na(x)), mean(x,na.rm=T), suppressWarnings(min(x,na.rm=T)), suppressWarnings(max(x,na.rm=T)), length(unique(x)))
    else s <- sprintf("chr nuniq=%d ex=%s", length(unique(x)), paste(head(unique(x),3),collapse="|"))
    cat(v, ":", lab, ":", s, "\n")
  }
}
for (f in c("anonym_returns_data.dta","panel_g1.dta","seller_data.dta","buy_data.dta","maize_quality_gr1.dta","maize_quality_gr0.dta")) desc(f)
