# Exploratory 4: candidate sample-cleaning flags by arm (no estimates)
suppressMessages({library(haven); library(dplyr)})
options(width = 220)
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-a/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rs <- zap_labels(read_dta(file.path(B, "admin_data/randomization_schedule.dta")))
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta")))
tr <- zap_labels(read_dta(file.path(B, "admin_data/taxroll_noPII.dta")))
tr$trstat <- ifelse(grepl("FC", tr$MontantIF) & !grepl("^\\.", tr$MontantIF), "amount", ifelse(tr$MontantIF == "", "blank", tr$MontantIF))
rg <- rg %>% filter(pilot == 0) %>% left_join(rs[, c("a7", "treatment")], by = "a7") %>%
  left_join(tr[, c("compound1", "trstat", "Exempte", "DatePaye", "DateRDV", "Date", "Bonus", "Bonus2")], by = "compound1")
rg$trt <- rg$treatment
rg$trt[rg$a7 %in% c(639, 654)] <- 9
rg$trstat[is.na(rg$trstat)] <- "notinroll"
cat("trstat x trt\n"); print(table(rg$trstat, rg$trt))
cat("house x trstat\n"); print(table(rg$house, rg$trstat))
cat("Date (taxroll) x trt\n"); print(table(rg$Date, rg$trt))
cat("Bonus2 x trt\n"); print(table(rg$Bonus2, rg$trt))
cat("Bonus x trt\n"); print(table(rg$Bonus, rg$trt))
r2 <- rg %>% filter(house != 3, trstat != "Voir le tract")
cat("after villa & voir:\n"); print(table(r2$trt))
flags <- list(
  notinroll = r2$trstat == "notinroll", blank = r2$trstat == "blank", paye = r2$trstat == "Payé",
  chalk0 = r2$chalk_check %in% 0, chalkNA = is.na(r2$chalk_check), endNA = is.na(r2$end), todayNA = is.na(r2$today),
  totc0 = r2$tot_complete == 0, dupc = duplicated(r2$compound1) | duplicated(r2$compound1, fromLast = TRUE),
  c1ne2 = r2$compound1 != r2$compound2, dsensi = r2$double_sensi == 1, firstNA = is.na(r2$first),
  a7ne = r2$a7 != r2$a7_compound, correct0 = r2$correct %in% 0, whoNA = is.na(r2$who), tmtNA = is.na(r2$tmt),
  carto1 = r2$carto_pay %in% 1, presentNA = is.na(r2$present_sensi), dupkey = duplicated(r2$key),
  exempt1 = r2$exempt %in% 1, tmtmis = !is.na(r2$tmt) & r2$tmt != r2$treatment, commNA = is.na(r2$commune),
  a7bNA = is.na(r2$a7b), a7bne = !is.na(r2$a7b) & r2$a7b != r2$a7, oldcode0 = r2$old_code %in% 0
)
res <- sapply(flags, function(f) tapply(f, r2$trt, sum, na.rm = TRUE))
print(t(res))
cat("targets diffs (after villa&voir): ctrl 0, central -96, local(110)+CXLnb -> 14383, CLI -168, CXL(50) -> 6071\n")
