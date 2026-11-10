suppressPackageStartupMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rd <- function(f, ...) read_dta(file.path(base, f), ...)
tb <- function(...) print(table(..., useNA = "ifany"))
labs <- function(x) { l <- attr(x, "labels"); if (!is.null(l)) print(l) }
ra <- rd("admin_data/randomization_assignment.dta") %>% mutate(treatment = as.numeric(zap_labels(treatment)))

mid <- rd("survey_data/midline_noPII.dta", col_select = c(a7, compound, compound2, treatment, month, visited, visits, col_type_fr,
   tot_complete, pilot, dup_real, dup_compound, monitoring_survey_twice, unknown_compound, control, short, first_attempt, present, exempt, new_survey_version))
mid <- mid %>% mutate(across(where(is.labelled), ~as.numeric(zap_labels(.x))))
str(mid[1:2, ])
mid <- left_join(mid, ra %>% select(a7, ra_t = treatment), by = "a7")
cat("midline treatment var vs ra:\n"); tb(mid$treatment, mid$ra_t)
print(mid %>% filter(a7 %in% c(639, 654, 374)) %>% group_by(a7) %>% summarise(n = n(), t = paste(unique(treatment), collapse = "/"),
   coltype = paste(names(table(col_type_fr)), table(col_type_fr), collapse = ";")))
labs(rd("survey_data/midline_noPII.dta", col_select = col_type_fr, n_max = 2)$col_type_fr)
cw <- mid %>% filter(ra_t %in% c(2, 4)) %>% group_by(a7, ra_t) %>% summarise(chef_only = mean(col_type_fr == 2, na.rm = TRUE), both = mean(col_type_fr == 3, na.rm=TRUE), n = sum(!is.na(col_type_fr)), .groups = "drop")
print(as.data.frame(cw %>% filter(ra_t == 4) %>% arrange(desc(chef_only)) %>% head(6)))
for (v in c("tot_complete","pilot","dup_real","dup_compound","monitoring_survey_twice","unknown_compound","control","short","first_attempt","present","new_survey_version")) { cat("--", v, "\n"); tb(mid[[v]]) }
cat("compound unique among tot_complete==1:", n_distinct(mid$compound[mid$tot_complete %in% 1]), " of ", sum(mid$tot_complete %in% 1), "\n")
tb(mid$visited, mid$visits > 1)

e1 <- rd("survey_data/endline_round1_noPII.dta")
e1 <- e1 %>% mutate(across(where(is.labelled), ~as.numeric(zap_labels(.x))))
nm <- names(e1)
print(nm[grepl("tot_|complete|consent|dup|found|attempt|surveyed|resp|replace|round|status|pilot|bribe|transport|treat", nm, ignore.case = TRUE)])
labs(rd("survey_data/endline_round1_noPII.dta", col_select = bribe, n_max = 2)$bribe)
tb(e1$bribe)
e1 <- left_join(e1, ra %>% select(a7, ra_t = treatment), by = "a7")
tb(e1$bribe, e1$ra_t)
tb(e1$treatment, e1$ra_t)
for (v in intersect(c("tot_complete","dup_compound","consent","consent1","found","replacement_possible"), nm)) { cat("--", v, "\n"); tb(e1[[v]]) }
tb(!is.na(e1$bribe), e1$visited)
tb(!is.na(e1$bribe), e1$paid_self)
cat("unique code:", n_distinct(e1$code), " rows ", nrow(e1), "\n")
e2 <- rd("survey_data/endline_round2_noPII.dta", n_max = 5); print(names(e2)[grepl("bribe|transport|tot_|dup|complete", names(e2))])
e3 <- rd("survey_data/endline_2016campaign_noPII.dta", n_max = 5); print(names(e3)[grepl("bribe|transport|tot_|dup|complete|a7|treat", names(e3))])
