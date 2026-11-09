suppressMessages({library(haven); library(dplyr)})
P <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-07-a/mount/bokobza_2022_morning_after_coup_purges"
c <- read_dta(file.path(P, "morning_after_dataset_countrylevel.dta"))
c <- c %>% arrange(COUNTRY_ID, YEAR_DATA) %>% group_by(COUNTRY_ID) %>%
  mutate(ldem1 = ifelse(dplyr::lag(YEAR_DATA) == YEAR_DATA - 1, dplyr::lag(democracy1), NA),
         lpolity = lpolity2) %>% ungroup()
for (dv in c("ldem1", "ldemocracy_br")) for (yr in list(c(1967, 2016), c(1966, 2017), c(1963, 2017))) {
  s <- c %>% filter(.data[[dv]] == 0, YEAR_DATA >= yr[1], YEAR_DATA <= yr[2], !is.na(replacement_rateadj_minister))
  cat(dv, yr, ": coup table "); print(table(s$coupattempt_whogov, useNA = "a"))
  s <- c %>% filter(.data[[dv]] == 0, YEAR_DATA >= yr[1], YEAR_DATA <= yr[2])
  cat("   any-row coups", sum(s$coupattempt_whogov, na.rm = TRUE), "countries", n_distinct(s$COUNTRY_ID), "\n")
}
s <- c %>% filter(democracy1 == 0, YEAR_DATA >= 1967, YEAR_DATA <= 2016, !is.na(replacement_rateadj_minister))
cat("contemporaneous democracy1: "); print(table(s$coupattempt_whogov, useNA = "a"))
