# Exploratory 6: neighborhood-level timing variables (no estimates)
suppressMessages({library(haven); library(dplyr)})
options(width = 250)
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-a/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
rs <- zap_labels(read_dta(file.path(B, "admin_data/randomization_schedule.dta")))
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta")))
tp <- zap_labels(read_dta(file.path(B, "admin_data/tax_payments_noPII.dta")))
mid <- zap_labels(read_dta(file.path(B, "survey_data/midline_noPII.dta"), col_select = any_of(c("a7", "compound1", "today", "start", "month", "date", "month_tmp_fr"))))
cat("midline cols:", names(mid), "\n")
md <- function(x) { x <- x[!is.na(x) & x != ""]; if (!length(x)) return(NA_character_); names(sort(table(x), decreasing = TRUE))[1] }
rg <- rg %>% filter(pilot == 0)
nb <- rg %>% group_by(a7) %>% summarise(n = n(), rmin = min(as.Date(start)), rmed = as.Date(median(as.numeric(as.Date(start))), origin = "1970-01-01"),
  tmin = suppressWarnings(min(today, na.rm = TRUE)), mfr = md(month_tmp_fr), nNAtoday = sum(is.na(today)), .groups = "drop")
pe <- tp %>% group_by(a7) %>% summarise(eoc = md(as.character(endOfCollect)), pmin = min(date, na.rm = TRUE), np = n(), .groups = "drop")
nb <- rs[, c("a7", "treatment", "month")] %>% left_join(nb, by = "a7") %>% left_join(pe, by = "a7")
if ("today" %in% names(mid)) {
  mm <- mid %>% group_by(a7) %>% summarise(midmin = min(as.Date(today), na.rm = TRUE), midmed = as.Date(median(as.numeric(as.Date(today)), na.rm = TRUE), origin = "1970-01-01"), nmid = n(), .groups = "drop")
  nb <- nb %>% left_join(mm, by = "a7")
}
if ("month" %in% names(mid)) { cat("midline month var:\n"); print(table(mid$month, useNA = "ifany")); mm2 <- mid %>% group_by(a7) %>% summarise(midmonth = md(as.character(month))); nb <- nb %>% left_join(mm2, by = "a7") }
nb <- nb %>% arrange(treatment, rmin)
print(as.data.frame(nb %>% filter(treatment %in% 1:3)), row.names = FALSE)
cat("month_tmp_fr by treatment\n"); print(table(rg$month_tmp_fr, rg$a7 %in% rs$a7[rs$treatment == 1]))
