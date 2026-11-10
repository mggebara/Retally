suppressPackageStartupMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-b/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rd <- function(f, ...) read_dta(file.path(base, f), ...)
lab <- function(x) { l <- attr(x, "labels"); if (!is.null(l)) print(l) }
rs <- rd("admin_data/randomization_schedule.dta") %>% mutate(tr = as.numeric(treatment))
cat("arms of 507, 653:", rs$tr[match(c(507, 653), rs$a7)], "\n")
reg <- rd("admin_data/registration_noPII.dta", col_select = c(a7, compound1, tot_complete, house, who)) %>% filter(a7 %in% rs$a7, tot_complete == 1)
el <- rd("survey_data/endline_round1_noPII.dta")
el$trs <- rs$tr[match(el$a7, rs$a7)]
cat("endline et=2 & sch=4 a7:\n"); print(table(el$a7[as.numeric(el$treatment) %in% 2 & el$trs %in% 4]))
cat("endline treatment by a7 for 639, 654:\n"); print(table(el$a7[el$a7 %in% c(639, 654)], as.numeric(el$treatment[el$a7 %in% c(639, 654)]), useNA = "ifany"))
cat("midline treatment for 639/654 and others:\n")
ml <- rd("survey_data/midline_noPII.dta", col_select = c(a7, compound, treatment, visited, visits, tot_complete, survey_chef, compound_chef, compound_assis))
for (v in c("survey_chef", "compound_chef", "compound_assis")) { cat(v, attr(ml[[v]], "label"), "\n"); print(head(table(as.numeric(ml[[v]]), useNA = "ifany"), 10)); lab(ml[[v]]) }
print(table(ml$a7[ml$a7 %in% c(639, 654, 204, 505, 507, 532, 673)], as.numeric(ml$treatment[ml$a7 %in% c(639, 654, 204, 505, 507, 532, 673)]), useNA = "ifany"))
m1 <- ml %>% filter(tot_complete == 1)
cat("midline complete:", nrow(m1), " compound in reg:", mean(m1$compound %in% reg$compound1), " NA compound:", sum(is.na(m1$compound)), " dup:", sum(duplicated(m1$compound[!is.na(m1$compound)])), "\n")
print(table(vis = as.numeric(m1$visited), visits = pmin(as.numeric(m1$visits), 5), useNA = "ifany"))
# endline vars around bribe
nm <- names(el); i <- which(nm == "bribe"); cat("vars around bribe:", nm[max(1, i - 12):min(length(nm), i + 6)], "\n")
for (v in nm[max(1, i - 12):min(length(nm), i + 6)]) { x <- el[[v]]; cat("\n#", v, ":", attr(x, "label"), "\n"); if (length(unique(x)) < 15) print(table(as.numeric(x), useNA = "ifany")) }
e1 <- el %>% filter(tot_complete == 1)
cat("\ncomplete endline:", nrow(e1), "\n"); print(table(bribe = as.numeric(e1$bribe), visited = as.numeric(e1$visited), useNA = "ifany"))
cat("visited label:", attr(el$visited, "label"), "\n"); lab(el$visited)
cat("dup check vars:\n"); for (v in grep("dup|baseline|replace|same_resp|resp_same|tracked|found", nm, value = TRUE)) { x <- el[[v]]; cat(v, ":", attr(x, "label"), "\n"); if (length(unique(x)) < 10) print(table(as.numeric(x), useNA = "ifany")) }
print(table(trs = e1$trs, bribe = as.numeric(e1$bribe), useNA = "ifany"))
tp <- rd("admin_data/tax_payments_noPII.dta")
cat("payments by arm:\n"); print(table(rs$tr[match(tp$compound1 %/% 1000, rs$a7)], useNA = "ifany"))
