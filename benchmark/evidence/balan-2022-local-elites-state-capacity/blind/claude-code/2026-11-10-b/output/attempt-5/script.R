suppressPackageStartupMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-b/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rd <- function(f, ...) read_dta(file.path(base, f), ...)
lab <- function(x) { l <- attr(x, "labels"); if (!is.null(l)) print(l) }
rs <- rd("admin_data/randomization_schedule.dta") %>% mutate(tr = as.numeric(treatment))
reg <- rd("admin_data/registration_noPII.dta") %>% filter(a7 %in% rs$a7, tot_complete == 1) %>% left_join(rs[, c("a7", "tr", "month")], by = "a7")
reg$sd <- as.Date(reg$start)
cat("--- today vs start date diff\n"); print(summary(as.numeric(reg$today - reg$sd)))
print(table(format(reg$sd, "%Y-%m"), reg$tr))
nb <- reg %>% group_by(a7) %>% summarise(tr = first(tr), month = first(month), n = n(), sd0 = min(sd), sd1 = max(sd), td0 = suppressWarnings(min(today, na.rm = TRUE)))
cat("--- neighborhoods with sd span > 20 days or sd0 != td0\n"); print(as.data.frame(nb %>% filter(as.numeric(sd1 - sd0) > 20 | (is.finite(td0) & sd0 != td0))))
cat("--- sd0 month x schedule month\n"); print(table(nb$month, format(nb$sd0, "%m")))
cat("--- CXL neighborhoods\n"); print(as.data.frame(nb %>% filter(tr == 4)))
ml <- rd("survey_data/midline_noPII.dta", col_select = c(a7, compound, compound2, today, treatment, tmt, month, visited, visits, bribe, sample_select, tot_complete, tot_complete_short, tot_complete_long, tot_complete_control, tot_complete_temp, survey1))
cat("\n=== midline\n"); print(dim(ml))
for (v in c("treatment", "tmt", "month", "visited", "visits", "bribe", "sample_select", "tot_complete", "tot_complete_short", "tot_complete_long", "tot_complete_control", "tot_complete_temp", "survey1")) { cat(v, attr(ml[[v]], "label"), "\n"); print(table(as.numeric(ml[[v]]), useNA = "ifany")); lab(ml[[v]]) }
ml$trs <- rs$tr[match(ml$a7, rs$a7)]
cat("midline treatment vs schedule\n"); print(table(mt = as.numeric(ml$treatment), sch = ml$trs, useNA = "ifany"))
cat("midline tmt by a7 for CXL nbhds\n"); print(as.data.frame(ml %>% filter(trs == 4) %>% group_by(a7) %>% summarise(n = n(), t = paste(names(table(as.numeric(treatment))), table(as.numeric(treatment)), sep = ":", collapse = ";"), tm = paste(names(table(tmt)), table(tmt), sep = ":", collapse = ";"))))
cat("compound in reg:", mean(ml$compound %in% reg$compound1), " dup compound:", sum(duplicated(ml$compound)), "\n")
cat("visited x tot_complete\n"); print(table(vis = as.numeric(ml$visited), tc = ml$tot_complete, useNA = "ifany"))
el <- rd("survey_data/endline_round1_noPII.dta", col_select = c(a7, compound_code, today, treatment, transport, bribe, bribe_freq, tot_complete, tot_complete_titling, tot_complete_monitoring, code_found, code_erased, identity_post_tax))
cat("\n=== endline r1\n"); print(dim(el))
for (v in c("treatment", "transport", "bribe", "bribe_freq", "tot_complete", "tot_complete_titling", "tot_complete_monitoring", "code_found", "identity_post_tax")) { cat(v, attr(el[[v]], "label"), "\n"); print(table(as.numeric(el[[v]]), useNA = "ifany")); lab(el[[v]]) }
el$trs <- rs$tr[match(el$a7, rs$a7)]
print(table(et = as.numeric(el$treatment), sch = el$trs, useNA = "ifany"))
print(table(format(el$today, "%Y-%m"), useNA = "ifany"))
print(table(transport = as.numeric(el$transport), tc = el$tot_complete, useNA = "ifany"))
e2 <- rd("survey_data/endline_round2_noPII.dta", col_select = c(a7, today, treatment, transport, tot_complete))
cat("\n=== endline r2\n"); print(dim(e2)); print(table(as.numeric(e2$transport), useNA = "ifany")); lab(e2$transport); cat(attr(e2$transport, "label"), "\n")
print(table(format(e2$today, "%Y-%m"), useNA = "ifany"))
