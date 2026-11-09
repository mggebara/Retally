suppressMessages({library(haven); library(dplyr)})
P <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-07-a/mount/bokobza_2022_morning_after_coup_purges"
c <- read_dta(file.path(P, "morning_after_dataset_countrylevel.dta"))
c <- c %>% arrange(COUNTRY_ID, YEAR_DATA) %>% group_by(COUNTRY_ID) %>%
  mutate(ldem1 = ifelse(dplyr::lag(YEAR_DATA) == YEAR_DATA - 1, dplyr::lag(democracy1), NA),
         lgdp = ifelse(dplyr::lag(YEAR_DATA) == YEAR_DATA - 1, dplyr::lag(gdp_cap_pwt_ln), NA)) %>% ungroup()
d <- readRDS(file.path(P, "morning_after_dataset_individuallevel.rds"))
di <- d %>% group_by(country_name, year) %>% summarise(dl = first(democracy_lag), dlbr = first(democracy_lag_br),
   coup = first(as.integer(coupattempt_presentyear == "Coup attempt")), coupbr = first(coupattempt_presentyear_br),
   lg = first(gdp_cap_pwt_ln_lag), .groups = "drop")
m <- c %>% inner_join(di, by = c("COUNTRY_DATA" = "country_name", "YEAR_DATA" = "year"))
cat("matched", nrow(m), "of", nrow(di), "\n")
print(table(ind_dl = m$dl, ldem1 = m$ldem1, useNA = "a"))
print(table(ind_dl = m$dl, ldembr = m$ldemocracy_br, useNA = "a"))
print(table(ind_dlbr = m$dlbr, ldembr = m$ldemocracy_br, useNA = "a"))
print(table(ind_coup = m$coup, cl = m$coupattempt_whogov, useNA = "a"))
print(table(ind_coupbr = m$coupbr, cl = m$coupattempt_whogov_br, useNA = "a"))
cat("gdp lag diff summary\n"); print(summary(m$lg - m$lgdp))
for (indep in c(FALSE, TRUE)) {
 for (dv in c("ldem1", "ldemocracy_br")) {
  s <- c %>% filter(.data[[dv]] == 0, YEAR_DATA >= 1967, YEAR_DATA <= 2016, !is.na(replacement_rateadj_minister), !is.na(coupattempt_whogov), !is.na(lgdp), !is.na(pop_pwt_ln))
  if (indep) s <- s %>% filter(independent == 1)
  cat(dv, "indep", indep, ": n", nrow(s), "countries", n_distinct(s$COUNTRY_ID), "coups", sum(s$coupattempt_whogov), "\n")
 }
}
