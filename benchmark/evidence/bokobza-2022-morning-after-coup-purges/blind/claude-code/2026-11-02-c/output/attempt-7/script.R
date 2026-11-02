suppressMessages({library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-c/mount/bokobza_2022_morning_after_coup_purges"
i <- readRDS(file.path(D, "morning_after_dataset_individuallevel.rds"))
cy <- i %>% filter(country_isocode %in% c("AFG","EGY","CHN")) %>% distinct(country_isocode, year, gdp_cap_pwt_ln, pop_pwt_ln, gdp_cap_pwt_ln_lag, pop_pwt_ln_lag) %>% arrange(country_isocode, year)
print(as.data.frame(cy %>% filter(year %in% 1985:1992)))
w <- i %>% group_by(country_isocode) %>% summarise(sd_pop=sd(pop_pwt_ln, na.rm=T), sd_popl=sd(pop_pwt_ln_lag, na.rm=T), sd_gdpl=sd(gdp_cap_pwt_ln_lag, na.rm=T), nd_popl=n_distinct(pop_pwt_ln_lag))
print(summary(w))
cat("cor pop lag with gdp lag:", cor(i$pop_pwt_ln_lag, i$gdp_cap_pwt_ln_lag, use="complete"), "\n")
cat("rows per country-year with >1 distinct pop lag:", sum((i %>% group_by(country_isocode, year) %>% summarise(k=n_distinct(pop_pwt_ln_lag), .groups="drop"))$k > 1), "\n")
