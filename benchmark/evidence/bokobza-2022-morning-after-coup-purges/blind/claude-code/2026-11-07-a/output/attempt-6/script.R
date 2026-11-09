suppressMessages({library(dplyr); library(fixest)})
P <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-07-a/mount/bokobza_2022_morning_after_coup_purges"
d <- readRDS(file.path(P, "morning_after_dataset_individuallevel.rds"))
print(summary(d[, c("gdp_cap_pwt_ln", "pop_pwt_ln", "gdp_cap_pwt_ln_lag", "pop_pwt_ln_lag")]))
cy <- d %>% group_by(country_isocode, year) %>% summarise(p = first(pop_pwt_ln), pl = first(pop_pwt_ln_lag),
        g = first(gdp_cap_pwt_ln), gl = first(gdp_cap_pwt_ln_lag), np = n_distinct(pop_pwt_ln_lag), .groups = "drop") %>%
  arrange(country_isocode, year)
print(table(cy$np))
print(as.data.frame(cy %>% filter(country_isocode %in% c("AFG", "CHN")) %>% head(60)))
cat("cor pl,gl:", cor(cy$pl, cy$gl, use = "c"), "\n")
cy2 <- cy %>% group_by(country_isocode) %>% mutate(plag = ifelse(c(NA, diff(year)) == 1, lag(p), NA)) %>% ungroup()
print(summary(cy2$pl - cy2$plag))
a <- d %>% filter(democracy_lag == 0, year >= 1967, year <= 2016, leader == 0)
m <- feols(pop_pwt_ln_lag ~ gdp_cap_pwt_ln_lag | country_isocode + year, a)
cat("within R2 of pop lag on gdp lag + FE:", r2(m, "wr2"), " sd resid:", sd(resid(m)), "\n")
print(sapply(split(a$pop_pwt_ln_lag, a$country_isocode), function(x) sd(x, na.rm = TRUE)) |> summary())
