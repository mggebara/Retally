suppressPackageStartupMessages({library(haven); library(dplyr); library(lubridate)})
base <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rd <- function(f, ...) read_dta(file.path(base, f), ...)
tb <- function(...) print(table(..., useNA = "ifany"))
ra <- rd("admin_data/randomization_assignment.dta") %>% mutate(treatment = as.numeric(zap_labels(treatment)))
e1 <- rd("survey_data/endline_round1_noPII.dta", col_select = c(a7, treatment, tot_complete, visited, bribe, dup_compound, code, pilot)) %>%
  mutate(across(where(is.labelled), ~as.numeric(zap_labels(.x)))) %>% left_join(ra %>% select(a7, ra_t = treatment), by = "a7")
print(e1 %>% filter(ra_t == 4, treatment == 2) %>% count(a7))
print(e1 %>% filter(a7 %in% c(639, 654, 374)) %>% count(a7, treatment))
e1c <- e1 %>% filter(tot_complete == 1)
cat("complete endline rows", nrow(e1c), " unique code", n_distinct(e1c$code), "\n"); tb(e1c$pilot); tb(e1c$dup_compound)
tb(e1c$visited, e1c$bribe)
tb(e1c$ra_t, !is.na(e1c$visited))

mid <- rd("survey_data/midline_noPII.dta", col_select = c(a7, compound, tot_complete, pilot, dup_compound, dup_real, monitoring_survey_twice, unknown_compound, visited, visits)) %>%
  mutate(across(where(is.labelled), ~as.numeric(zap_labels(.x))))
mc <- mid %>% filter(tot_complete == 1, pilot == 0)
cat("midline complete nonpilot", nrow(mc), " compound NA", sum(is.na(mc$compound)), " dup compounds", sum(duplicated(mc$compound[!is.na(mc$compound)])), "\n")
tb(mc$dup_compound); tb(mc$monitoring_survey_twice); tb(mc$unknown_compound)
d <- mc %>% filter(!is.na(compound)) %>% group_by(compound) %>% filter(n() > 1) %>% arrange(compound)
print(head(as.data.frame(d), 12))

# neighborhood dates and windows (option N)
reg <- rd("admin_data/registration_noPII.dta", col_select = c(a7, compound1, start, pilot, tot_complete, house)) %>%
  mutate(across(where(is.labelled), ~as.numeric(zap_labels(.x)))) %>% inner_join(ra %>% select(a7, treatment), by = "a7") %>%
  filter(pilot == 0, tot_complete == 1, house != 3)
cat("reg compounds matched by midline:", mean(reg$compound1 %in% mc$compound), "; midline matched to reg:", mean(mc$compound %in% reg$compound1), "\n")
nb <- reg %>% group_by(a7, treatment) %>% summarise(d0 = min(as.Date(start)), n = n(), .groups = "drop")
win <- function(nb, a, b) {
  x <- nb %>% filter(treatment %in% c(a, b))
  f <- x %>% group_by(treatment) %>% summarise(first = min(d0), last = max(d0))
  s <- min(f$first) + floor(as.numeric(diff(range(f$first))) / 2)
  e <- min(f$last) + floor(as.numeric(diff(range(f$last))) / 2)
  keep <- x$d0 >= s & x$d0 <= e
  cat("arms", a, b, " start", format(s), " end", format(e), " clusters kept", sum(keep), "of", nrow(x), " props kept", sum(x$n[keep]), "\n")
  print(table(x$treatment, keep))
}
win(nb, 1, 2); win(nb, 1, 3)
