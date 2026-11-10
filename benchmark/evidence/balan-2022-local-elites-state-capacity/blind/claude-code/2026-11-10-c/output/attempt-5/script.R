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
    cat(sprintf("%-26s %-6s u=%-5d NA=%-5d [%s] %s {%s}\n", v, substr(class(x)[1],1,6), nu, sum(is.na(x)), substr(lab,1,70), ex, substr(vls,1,150)))
  }
}
ra <- read_dta(paste0(B, "randomization_assignment.dta"))
mid <- read_dta(paste0(S, "midline_noPII.dta"))
mid$rtrt <- as.numeric(ra$treatment[match(mid$a7, ra$a7)])
print(table(mid$treatment, mid$rtrt, useNA="always"))
print(table(mid$a7[mid$a7 %in% c(639,654,374)], mid$treatment[mid$a7 %in% c(639,654,374)], useNA="always"))
print(table(mid$a7[mid$a7 %in% c(639,654,374)], mid$col_type_fr[mid$a7 %in% c(639,654,374)]))
desc(mid, "mid", c("visited","visits","tot_complete","pilot","dup_real","monitoring_survey_twice","unknown_compound","dup_compound","new_survey_version","short","control","exempt","present","first_attempt","bribe","tot_complete_temp","survey1","month","treatment","sample_select","long_select","tot_complete_short","short_empty","_long"))
print(table(visited=mid$visited, tc=mid$tot_complete, useNA="always"))
m2 <- mid %>% filter(tot_complete==1, pilot==0)
cat("m2", nrow(m2), " uniq compound", length(unique(m2$compound)), " dup_real:", sum(m2$dup_real), "\n")
print(table(m2$dup_compound, useNA="always"))
print(table(m2$visited, m2$visits > 0, useNA="always"))
for (f in c("endline_round1_noPII.dta","endline_round2_noPII.dta")) {
  e <- read_dta(paste0(S, f))
  nm <- names(e)
  keep <- nm[grepl("transport|bribe|a7|compound|treat|stratum|tot_comp|pilot|dup|round|survey1|code|key|today|respond|replace|paid|visit|tax|_e$", nm)]
  desc(e, f, head(keep, 120))
}
cc <- read_dta(paste0(S, "chief_consultations.dta"))
desc(cc, "chief_consultations")
