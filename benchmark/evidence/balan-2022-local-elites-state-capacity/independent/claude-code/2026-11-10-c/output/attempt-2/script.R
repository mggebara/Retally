# Exploratory run 2: registration, consultations, midline, endline structure (no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
dv <- function(d, vs) {
  for (v in vs) {
    x <- d[[v]]
    lab <- attr(x, "label", exact = TRUE); if (is.null(lab)) lab <- ""
    vl <- attr(x, "labels", exact = TRUE)
    nu <- length(unique(x))
    if (inherits(x, c("Date","POSIXct"))) s <- paste("date min", min(x,na.rm=TRUE), "max", max(x,na.rm=TRUE), "NA", sum(is.na(x)))
    else if (is.numeric(x)) s <- if (all(is.na(x))) "all NA" else sprintf("num min=%s max=%s mean=%s NA=%d", signif(min(x, na.rm=TRUE),5), signif(max(x, na.rm=TRUE),5), signif(mean(x, na.rm=TRUE),5), sum(is.na(x)))
    else { ux <- head(unique(as.character(x)), 4); s <- paste0("chr ex: ", paste(substr(ux,1,25), collapse=" | "), " empty=", sum(is.na(x) | as.character(x) == "")) }
    cat(sprintf("%-30s nu=%-6d %s | %s", v, nu, substr(lab[1],1,70), s))
    if (!is.null(vl) && length(vl) <= 12) cat(" | labels:", paste(names(vl), vl, sep="=", collapse="; "))
    cat("\n")
  }
}
desc <- function(f, pat = NULL) {
  cat("\n\n==========", f, "==========\n")
  d <- read_dta(file.path(B, f))
  cat("dim:", dim(d), "\n")
  vs <- names(d); if (!is.null(pat)) vs <- grep(pat, vs, value = TRUE, ignore.case = TRUE)
  dv(d, vs); invisible(d)
}
options(warn = -1)
reg <- desc("admin_data/registration_noPII.dta")
desc("admin_data/tax_payment_timing_noPII.dta")
desc("survey_data/chief_consultations.dta")
mid <- desc("survey_data/midline_noPII.dta")
pat <- "a7|compound|code|treat|strat|transport|bribe|paid|visit|tmt|local|central|month|date|today|house|exempt|id$|respondent|tracked|replace|round"
desc("survey_data/endline_round1_noPII.dta", pat)
desc("survey_data/endline_round2_noPII.dta", pat)
desc("survey_data/baseline_noPII.dta", "a7|compound|code|treat|strat|tmt|id$|respondent|today|date|month")
