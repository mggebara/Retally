# Exploratory: variable names, labels, basic tabulations. No estimates.
suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-b/mount/bold_2022_market_access_quality_upgrading/data/raw/"
desc <- function(f) {
  d <- read_dta(paste0(D, f))
  cat("\n\n######## ", f, nrow(d), "x", ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    nn <- sum(!is.na(x) & !(is.character(x) & x == ""))
    s <- if (is.numeric(x)) sprintf("num nonmiss=%d min=%s max=%s", nn,
           suppressWarnings(min(x, na.rm=TRUE)), suppressWarnings(max(x, na.rm=TRUE)))
         else sprintf("chr nonmiss=%d ex=%s", nn, paste(head(unique(x[x!=""]),3), collapse="|"))
    cat(sprintf("%-40s %-60s %s\n", v, substr(lab,1,60), s))
  }
  invisible(d)
}
r <- desc("anonym_returns_data.dta")
g1 <- desc("panel_g1.dta")
cat("\n## g1 tables\n")
print(table(g1$survey_season, useNA="ifany"))
for (v in intersect(c("buy_treatment","ext_treatment","survey_round","group"), names(g1))) { cat(v,"\n"); print(table(g1$survey_season, g1[[v]], useNA="ifany")) }
desc("seller_data.dta")
desc("buy_data.dta")
