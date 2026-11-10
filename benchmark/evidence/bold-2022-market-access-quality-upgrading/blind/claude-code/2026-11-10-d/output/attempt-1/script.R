suppressMessages({library(haven)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-d/mount/bold_2022_market_access_quality_upgrading/data/raw/"
options(width=250)
desc <- function(f){
  d <- read_dta(paste0(D,f))
  cat("\n\n######## ", f, nrow(d), "x", ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x,"label"); if (is.null(lab)) lab <- ""
    if (is.numeric(x)) {
      nn <- sum(!is.na(x))
      s <- if (nn>0) sprintf("num n=%d mean=%.4g min=%.4g max=%.4g nuniq=%d", nn, mean(x,na.rm=T), min(x,na.rm=T), max(x,na.rm=T), length(unique(x))) else "num all NA"
    } else {
      nn <- sum(!is.na(x) & x!="")
      s <- sprintf("chr n=%d nuniq=%d ex=%s", nn, length(unique(x)), substr(paste(head(unique(x[!is.na(x) & x!=""]),3),collapse="|"),1,80))
    }
    vl <- attr(x,"labels"); vls <- if(!is.null(vl)) paste0(" VL:", paste(paste0(vl,"=",names(vl)),collapse=";")) else ""
    cat(v, " [", lab, "] ", s, substr(vls,1,160), "\n", sep="")
  }
}
for (f in c("anonym_returns_data.dta","maize_quality_gr1.dta","maize_quality_gr0.dta","seller_data.dta","buy_data.dta","panel_g1.dta")) desc(f)
