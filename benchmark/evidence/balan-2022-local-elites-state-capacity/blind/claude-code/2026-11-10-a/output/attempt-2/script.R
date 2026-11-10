suppressMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-a/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
desc <- function(d, maxlev = 12) {
  for (v in names(d)) {
    x <- d[[v]]
    lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    nu <- length(unique(x))
    cat(sprintf("  %-30s %-10s nuniq=%-6d NA=%-6d | %s\n", v, class(x)[1], nu, sum(is.na(x)), substr(lab, 1, 90)))
    if (nu <= maxlev) {
      xx <- if (inherits(x, "haven_labelled")) as_factor(x, levels = "both") else as.character(x)
      tb <- table(xx, useNA = "ifany"); cat("     ", paste(names(tb), tb, sep = ":", collapse = "  "), "\n") }
    else if (is.numeric(x)) cat("      range", paste(signif(range(x, na.rm = TRUE), 6), collapse = " .. "), "\n")
    else cat("      e.g.", paste(head(unique(as.character(x)), 4), collapse = " | "), "\n")
  }
}
f <- function(p, ...) { cat("\n=====", p, "\n"); d <- read_dta(file.path(B, p), ...); cat("rows", nrow(d), "cols", ncol(d), "\n"); d }
d <- f("admin_data/taxroll_noPII.dta"); desc(d)
d <- f("survey_data/chief_consultations.dta"); desc(d)
d <- f("admin_data/tax_payments_neighborhoods.dta"); desc(d)
# survey files: list names + labels only, and describe key-looking vars
pat <- "a7|compound|tmt|treat|visit|bribe|transport|house|month|today|date|paid|strat|exempt|id$|code"
for (p in c("survey_data/midline_noPII.dta", "survey_data/endline_round1_noPII.dta", "survey_data/endline_round2_noPII.dta", "survey_data/endline_2016campaign_noPII.dta")) {
  d <- f(p)
  labs <- sapply(d, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
  keep <- grepl(pat, names(d), ignore.case = TRUE) | grepl("bribe|transport|visit|polygon|compound|treatment", labs, ignore.case = TRUE)
  cat("all names:\n"); print(names(d))
  desc(d[, keep])
  rm(d); gc()
}
