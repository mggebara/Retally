suppressPackageStartupMessages({library(haven); library(readxl)})
base <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-d/mount/bold_2022_market_access_quality_upgrading"
desc <- function(f) {
  d <- read_dta(file.path(base, "data/raw", f))
  cat("\n\n######## FILE", f, "dim", dim(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; vl <- attr(x, "labels"); x <- zap_labels(x)
    lab <- attr(x, "label"); if (is.null(lab)) lab <- ""

    nn <- sum(!is.na(x) & !(is.character(x) & x == ""))
    if (is.numeric(x)) {
      ux <- unique(x[!is.na(x)])
      s <- if (length(ux) <= 8) paste0("vals{", paste(sort(ux), collapse=","), "}") else
        sprintf("mean=%.4g sd=%.4g min=%.4g max=%.4g nuniq=%d", mean(x, na.rm=TRUE), sd(x, na.rm=TRUE), min(x, na.rm=TRUE), max(x, na.rm=TRUE), length(ux))
    } else {
      ux <- unique(x)
      s <- paste0("chr nuniq=", length(ux), " e.g. ", paste(head(ux, 5), collapse="|"))
    }
    vls <- if (!is.null(vl)) paste0(" LBL[", paste(paste0(vl, "=", names(vl)), collapse=";"), "]") else ""
    cat(sprintf("%s | %s | n=%d | %s%s\n", v, lab, nn, s, substr(vls, 1, 300)))
  }
}
for (f in c("anonym_returns_data.dta", "panel_g1.dta", "seller_data.dta", "buy_data.dta", "maize_quality_gr1.dta", "maize_quality_gr0.dta")) desc(f)
# key cross-tabs for panel_g1
d <- read_dta(file.path(base, "data/raw/panel_g1.dta"))
for (v in intersect(c("survey_season","buy_treatment","survey_round","ext_treatment"), names(d))) { cat("\nTAB", v, "\n"); print(table(d[[v]], useNA="ifany")) }
if (all(c("survey_season","buy_treatment") %in% names(d))) print(table(d$survey_season, d$buy_treatment, useNA="ifany"))
# survey forms (XLSForm) of returns survey
for (f in c("survey_materials/return_survey/add4_measuring_bags.xlsx", "survey_materials/return_survey/add5_bags_sales.xlsx")) {
  p <- file.path(base, f); cat("\n\n######## XLSX", f, excel_sheets(p), "\n")
  s <- read_excel(p, sheet = 1)
  cols <- intersect(c("type","name","label","label::English","calculation","relevant"), names(s))
  s <- as.data.frame(s[, cols]); s <- s[!is.na(s$name), ]
  for (i in seq_len(nrow(s))) cat(paste(substr(as.character(unlist(s[i, ])), 1, 120), collapse=" | "), "\n")
}
