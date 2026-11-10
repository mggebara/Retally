suppressMessages({library(haven); library(dplyr)})
R <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base/"
B <- paste0(R, "admin_data/"); S <- paste0(R, "survey_data/")
options(width=200)
desc <- function(d, nm, vars=names(d)) {
  cat("\n=====", nm, nrow(d), "x", ncol(d), "\n")
  for (v in vars) {
    x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    nu <- length(unique(x))
    ex <- if (is.numeric(x)) paste(signif(head(sort(unique(x)), 5),5), collapse=",") else paste(substr(head(unique(as.character(x)),3),1,18), collapse="|")
    vl <- attr(x, "labels"); vls <- if (!is.null(vl)) paste(paste0(vl, "=", names(vl)), collapse="; ") else ""
    cat(sprintf("%-26s %-6s u=%-5d NA=%-5d [%s] %s {%s}\n", v, substr(class(x)[1],1,6), nu, sum(is.na(x)), substr(lab,1,200), ex, substr(vls,1,150)))
  }
}
ra <- read_dta(paste0(B, "randomization_assignment.dta"))
mid <- read_dta(paste0(S, "midline_noPII.dta"))
cat(attr(mid$visits, "label"), "\n"); cat(attr(mid$visited, "label"), "\n")
cat(attr(mid$visits_other1a, "label"), "\n")
cci <- read_dta(paste0(B, "campaign_collector_info.dta")); desc(cci, "campaign_collector_info")
tp <- read_dta(paste0(B, "tax_payments_noPII.dta"))
tp$trt <- as.numeric(ra$treatment[match(tp$a7, ra$a7)])
print(table(tp$a7[tp$a7 %in% c(639,654,374)], tp$colcode[tp$a7 %in% c(639,654,374)], useNA="always"))
print(head(sort(table(tp$colcode[tp$trt==2]), decreasing=TRUE), 20)); print(head(sort(table(tp$colcode[tp$trt==4]), decreasing=TRUE), 30))
print(table(tp$TDM[tp$a7 %in% c(639,654)], useNA="always"))
e1 <- read_dta(paste0(S, "endline_round1_noPII.dta"))
nm <- names(e1)
cat(paste(nm, collapse=" "), "\n")
