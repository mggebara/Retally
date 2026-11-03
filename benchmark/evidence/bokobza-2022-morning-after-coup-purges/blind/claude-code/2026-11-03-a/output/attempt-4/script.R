D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-03-a/mount/bokobza_2022_morning_after_coup_purges"
suppressMessages({library(dplyr)})
i <- readRDS(file.path(D,"morning_after_dataset_individuallevel.rds"))
cy <- i %>% distinct(country_isocode, year, gdp_cap_pwt_ln, pop_pwt_ln, democracy_lag, coupattempt_presentyear)
cat("country-year rows", nrow(cy), " dup cy:", sum(duplicated(cy[,c("country_isocode","year")])), "\n")
cy <- cy %>% distinct(country_isocode, year, .keep_all=TRUE) %>% arrange(country_isocode, year) %>%
  group_by(country_isocode) %>% mutate(gap = year - lag(year),
    gdp_l = ifelse(gap==1, lag(gdp_cap_pwt_ln), NA), pop_l = ifelse(gap==1, lag(pop_pwt_ln), NA)) %>% ungroup()
i2 <- i %>% left_join(cy %>% select(country_isocode, year, gdp_l, pop_l), by=c("country_isocode","year"))
cat("gdp lag provided vs mine: max abs diff", max(abs(i2$gdp_l - i2$gdp_cap_pwt_ln_lag), na.rm=TRUE),
    " NA mine", sum(is.na(i2$gdp_l)), " NA provided", sum(is.na(i2$gdp_cap_pwt_ln_lag)),
    " NA mismatch", sum(is.na(i2$gdp_l) != is.na(i2$gdp_cap_pwt_ln_lag)), "\n")
a <- i2 %>% filter(democracy_lag==0, leader==0)
print(table(a$year, is.na(a$coupattempt_presentyear)))
print(round(tapply(a$purged_y1, a$year, mean),2))
b <- a %>% filter(year>=1967, year<=2016, !is.na(coupattempt_presentyear), !is.na(gdp_l), !is.na(pop_l), !is.na(purged_y1))
cat("base N", nrow(b), "coup", sum(b$coupattempt_presentyear=="Coup attempt"), " countries", length(unique(b$country_isocode)), "\n")
cat("excl junior N", sum(b$importance_numeric!="0.5" | is.na(b$importance_numeric)), "\n")
cat("excl junior & imp NA N", sum(!is.na(b$importance_numeric) & b$importance_numeric!="0.5"), "\n")
b15 <- b %>% filter(year<=2015)
cat("<=2015 N", nrow(b15), "\n")
print(table(b$importance_factor, useNA="a"))
print(table(b$party_group, b$importance_numeric=="0.5", useNA="a"))
