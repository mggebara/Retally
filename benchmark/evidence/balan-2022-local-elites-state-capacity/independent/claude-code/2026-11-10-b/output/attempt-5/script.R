# Exploratory: de facto treatment, time-window hypotheses (counts only), survey outcome coding (no estimates)
suppressMessages({library(haven); library(dplyr)})
options(width = 220)
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-b/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
tb <- function(...) print(table(..., useNA = "ifany"))
rg <- read_dta(file.path(B, "admin_data/registration_noPII.dta"),
  col_select = c(start, a7, a7b, tmt, who, house, compound1, compound2, exempt, collect_success, amt_paid, tot_complete, double_sensi, pilot, read_which_chef, collect_who, chief_asst_pres))
ra <- read_dta(file.path(B, "admin_data/randomization_assignment.dta")) %>% select(a7, treatment, stratum) %>% mutate(treatment = as.vector(treatment))
rs <- read_dta(file.path(B, "admin_data/randomization_schedule.dta")) %>% select(a7, month, chef_code, agent1_code, agent2_code, agent_code)
r <- rg %>% inner_join(ra, by = "a7") %>% left_join(rs, by = "a7") %>% filter(as.vector(house) != 3) %>% mutate(sdate = as.Date(start))
print(attr(rg$who, "labels"))
cat("who by treatment\n"); tb(r$treatment, as.vector(r$who))
cat("CXL nbhds: who distribution, chief_asst_pres\n")
print(r %>% filter(treatment == 4) %>% group_by(a7) %>% summarise(n = n(), who1 = sum(who == 1, na.rm=TRUE), who2 = sum(who == 2, na.rm=TRUE), who3 = sum(who == 3, na.rm=TRUE), whoNA = sum(is.na(who)), casst = sum(!is.na(chief_asst_pres)), chef = first(chef_code), ag1 = first(agent1_code), ag2 = first(agent2_code), ag = first(agent_code)) %>% as.data.frame())
cat("schedule codes by treatment (non-missing counts)\n")
print(rs %>% left_join(ra, by = "a7") %>% group_by(treatment) %>% summarise(chef = sum(!is.na(chef_code)), ag1 = sum(!is.na(agent1_code)), ag2 = sum(!is.na(agent2_code)), ag = sum(!is.na(agent_code))))
rd <- r %>% arrange(compound1, start) %>% distinct(compound1, .keep_all = TRUE)
# window hypotheses using property-level start date
win <- function(d, a, b, label) {
  x <- d %>% filter(treatment %in% c(a, b))
  f1 <- min(x$sdate[x$treatment == a]); f2 <- min(x$sdate[x$treatment == b])
  l1 <- max(x$sdate[x$treatment == a]); l2 <- max(x$sdate[x$treatment == b])
  s <- f1 + (f2 - f1) / 2; e <- l1 + (l2 - l1) / 2
  inw <- x$sdate >= s & x$sdate <= e
  cat(label, "first", format(f1), format(f2), "last", format(l1), format(l2), "window", format(s), format(e),
      " N all", nrow(x), " N in", sum(inw), " clusters all", n_distinct(x$a7), " clusters in", n_distinct(x$a7[inw]), "\n")
  # neighborhood-level (min date) version
  nb <- x %>% group_by(a7) %>% summarise(d0 = min(sdate), n = n())
  inn <- nb$d0 >= s & nb$d0 <= e
  cat("   nbhd-min version: N in", sum(nb$n[inn]), " clusters in", sum(inn), "\n")
  nb2 <- x %>% group_by(a7) %>% summarise(d0 = median(sdate), n = n())
  inn2 <- nb2$d0 >= s & nb2$d0 <= e
  cat("   nbhd-median version: N in", sum(nb2$n[inn2]), " clusters in", sum(inn2), "\n")
}
win(rd, 1, 2, "C vs L")
win(rd, 1, 3, "C vs CLI")
cat("dedup sample counts by treatment:\n"); tb(rd$treatment)
# registration payment vs receipts
pay <- read_dta(file.path(B, "admin_data/tax_payments_noPII.dta"))
cs <- rd %>% filter(collect_success == 1)
cat("reg collect_success==1:", nrow(cs), " of which in receipts:", sum(cs$compound1 %in% pay$compound1), "\n")
cat("payments by treatment (matched to dedup sample):\n")
pp <- pay %>% inner_join(rd %>% select(compound1, treatment, house), by = "compound1")
tb(pp$treatment); tb(pp$treatment, as.vector(pp$house)); tb(pp$amountCF, pp$treatment)
# endline round1
e1 <- read_dta(file.path(B, "survey_data/endline_round1_noPII.dta"), col_select = c(a7, treatment, today, code, compound_code, bribe, bribe_amt, visited, paid_self, dup_respondent, dup_compound, transport))
cat("\nendline1 rows", nrow(e1), "\n"); tb(as.vector(e1$bribe)); print(attr(e1$bribe, "labels")); tb(e1$dup_respondent); tb(e1$dup_compound); tb(as.vector(e1$visited))
tb(as.vector(e1$treatment)); print(summary(e1$today))
e1j <- e1 %>% inner_join(ra %>% rename(atr = treatment), by = "a7")
cat("bribe by assigned arm\n"); tb(e1j$atr, as.vector(e1j$bribe))
cat("bribe x visited\n"); tb(as.vector(e1j$visited), as.vector(e1j$bribe))
cat("bribe x paid_self\n"); tb(as.vector(e1j$paid_self), as.vector(e1j$bribe))
cat("endline treatment vs assigned\n"); tb(e1j$atr, as.vector(e1j$treatment))
e2 <- read_dta(file.path(B, "survey_data/endline_round2_noPII.dta"), col_select = c(a7, treatment, today, code))
cat("endline2 rows", nrow(e2), "\n"); print(summary(e2$today)); cat("codes overlap r1:", sum(e2$code %in% e1$code), "\n")
# midline coding
ml <- read_dta(file.path(B, "survey_data/midline_noPII.dta"), col_select = c(a7, compound, today, visited, visits, tot_complete, pilot, dup_compound, first_attempt, present, exempt))
ml <- ml %>% inner_join(ra, by = "a7") %>% filter(treatment %in% c(1,2))
cat("\nmidline C/L rows", nrow(ml), "\n")
tb(as.vector(ml$visited), ml$visits > 1)
tb(ml$tot_complete, is.na(ml$visited)); tb(as.vector(ml$dup_compound)); tb(as.vector(ml$present), is.na(ml$visited))
cat("midline compound in reg:", sum(ml$compound %in% rd$compound1), " dup compound:", sum(duplicated(ml$compound)), "\n")
mlv <- ml %>% filter(!is.na(visited))
cat("C/L midline with visited nonmissing:", nrow(mlv), " in reg:", sum(mlv$compound %in% rd$compound1), " dup:", sum(duplicated(mlv$compound)), "\n")
# chief consultations
cc <- read_dta(file.path(B, "survey_data/chief_consultations.dta")) %>% select(a7, compound1, pay_ease, willingness)
ccr <- cc %>% inner_join(rd %>% select(compound1, treatment, house), by = "compound1")
cat("consultations merged to reg:", nrow(ccr), " pay_ease 0-2:", sum(ccr$pay_ease %in% 0:2), "\n"); tb(ccr$treatment)
