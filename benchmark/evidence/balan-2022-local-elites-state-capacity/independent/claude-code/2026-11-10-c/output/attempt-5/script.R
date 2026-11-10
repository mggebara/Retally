# Exploratory run 5: other property-level files (no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr); library(readr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
options(width = 200, warn = -1)
ra <- read_dta(file.path(B, "admin_data/randomization_assignment.dta")) %>% zap_labels()
f <- function(t, lab) { tt <- table(factor(t, levels = 0:4)); cat(sprintf("%-55s N=%6d | %s\n", lab, sum(tt), paste(names(tt), tt, sep="=", collapse=" "))) }
dv <- function(d) {
  for (v in names(d)) { x <- d[[v]]; lab <- attr(x, "label", exact=TRUE); if (is.null(lab)) lab <- ""
    s <- if (inherits(x, c("Date","POSIXct"))) paste("date", min(x,na.rm=T), max(x,na.rm=T), "NA", sum(is.na(x))) else if (is.numeric(x)) { if (all(is.na(x))) "all NA" else sprintf("num %s..%s mean=%s NA=%d", signif(min(x,na.rm=T),5), signif(max(x,na.rm=T),5), signif(mean(x,na.rm=T),5), sum(is.na(x))) } else paste0("chr ", paste(head(unique(substr(as.character(x),1,20)),4), collapse=" | "))
    cat(sprintf("  %-28s nu=%-6d %s | %s\n", v, length(unique(x)), substr(lab,1,50), s)) }
}
cat("TARGET: 0=797 1=14489 2=14383 3=9422 4=6071 total 45162 ; high band 4979\n")
for (fn in c("admin_data/hh_distances.dta", "admin_data/fliers_campaign.dta", "admin_data/campaign_collector_info.dta", "survey_data/chief_info.dta", "admin_data/chief_collector_candidates_campaignupdated.dta", "survey_data/chief_knowledge.dta")) {
  cat("\n=====", fn, "\n")
  d <- tryCatch(read_dta(file.path(B, fn)), error = function(e) {cat("ERR", conditionMessage(e), "\n"); NULL})
  if (is.null(d)) next
  cat("dim", dim(d), "\n")
  if (ncol(d) <= 80) dv(d) else { cat(paste(names(d), collapse=" "), "\n"); dv(d[, grep("a7|compound|treat|tmt|house|paid|date|today|month|start|polygon|code", names(d))]) }
  a <- intersect(c("a7", "polygon", "a7_compound"), names(d))
  if (length(a)) { t <- ra$treatment[match(zap_labels(d[[a[1]]]), ra$a7)]; f(t, paste(fn, "by", a[1])) }
}
cat("\n===== property_values_MLestimates.csv\n")
pv <- read_csv(file.path(B, "admin_data/property_values_MLestimates.csv"), show_col_types = FALSE)
cat("dim", dim(pv), "\n"); print(names(pv)); dv(pv[, 1:min(20, ncol(pv))])
f(ra$treatment[match(pv$a7, ra$a7)], "pv by a7")
