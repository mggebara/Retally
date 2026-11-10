# Exploratory: variable names, labels, basic tabulations. No estimates.
suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-b/mount/bold_2022_market_access_quality_upgrading/data/raw/"
desc <- function(f) {
  d <- read_dta(paste0(D, f))
  cat("\n\n######## ", f, nrow(d), "x", ncol(d), "\n")
  for (v in names(d)) {
    x0 <- d[[v]]; lab <- attr(x0, "label"); if (is.null(lab)) lab <- ""
    x <- as.vector(zap_labels(x0))
    nn <- if (is.character(x)) sum(!is.na(x) & x != "") else sum(!is.na(x))
    s <- if (is.numeric(x)) sprintf("num nonmiss=%d min=%s max=%s", nn,
           suppressWarnings(min(x, na.rm=TRUE)), suppressWarnings(max(x, na.rm=TRUE)))
         else sprintf("chr nonmiss=%d ex=%s", nn, paste(head(unique(x[!is.na(x) & x!=""]),3), collapse="|"))
    vl <- attr(x0, "labels")
    vls <- if (!is.null(vl) && length(vl) < 12) paste0(" {", paste(names(vl), vl, sep="=", collapse="; "), "}") else ""
    cat(sprintf("%-40s %-60s %s%s\n", v, substr(lab,1,60), s, vls))
  }
  invisible(d)
}
r <- desc("anonym_returns_data.dta")
g1 <- desc("panel_g1.dta")
cat("\n## g1 tables\n")
print(table(zap_labels(g1$survey_season), useNA="ifany"))
for (v in intersect(c("buy_treatment","ext_treatment","survey_round","group"), names(g1))) { cat(v,"\n"); print(table(zap_labels(g1$survey_season), zap_labels(g1[[v]]), useNA="ifany")) }
desc("seller_data.dta")
desc("buy_data.dta")
