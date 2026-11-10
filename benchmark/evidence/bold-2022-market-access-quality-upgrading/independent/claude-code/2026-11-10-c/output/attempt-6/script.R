# Exploration: which pre-treatment control reproduces the (unlisted) harvest and acreage columns of Table 6
suppressMessages({library(haven); library(dplyr); library(tidyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-c/mount/bold_2022_market_access_quality_upgrading/data/raw/"
g <- zap_labels(read_dta(paste0(D, "panel_g1.dta")))
g$ea_code <- as.character(g$ea_code)
rsum <- function(p) { v <- grep(p, names(g), value = TRUE); x <- as.matrix(g[, v, drop = FALSE])
  list(s = rowSums(x, na.rm = TRUE), n = rowSums(!is.na(x))) }
ps <- rsum("^plot_size_[0-9]+$"); hk <- rsum("^harvest_kg_[0-9]+$")
g$acreage <- ifelse(!is.na(g$acres_tot), g$acres_tot, ps$s)
g$acreage_ps <- ps$s
g$harvest <- ifelse(g$survey_season >= 4, g$harvest_kg, ifelse(hk$n > 0, hk$s, NA))
g$harvest_raw <- g$harvest_kg
g$harvest_hk <- ifelse(hk$n > 0, hk$s, NA)
post <- g %>% filter(survey_season >= 4)
run <- function(v, pre, lab) {
  d <- post %>% left_join(pre, by = "hhh_id")
  d$pre_miss <- as.integer(!is.finite(d$pre)); d$pre0 <- ifelse(is.finite(d$pre), d$pre, 0)
  d <- d %>% filter(is.finite(.data[[v]]))
  m1 <- feols(as.formula(paste(v, "~ buy_treatment + pre | survey_season")), data = d %>% filter(pre_miss == 0), cluster = ~ea_code)
  m2 <- feols(as.formula(paste(v, "~ buy_treatment + pre0 + pre_miss | survey_season")), data = d, cluster = ~ea_code)
  cat(sprintf("%-10s %-38s drop: %8.3f N %d R2 %.2f | impute0: %8.3f N %d R2 %.2f\n", v, lab, coef(m1)[1], nobs(m1), r2(m1, "r2"), coef(m2)[1], nobs(m2), r2(m2, "r2")))
}
pm <- function(v, seasons) g %>% filter(survey_season %in% seasons) %>% group_by(hhh_id) %>%
  summarise(pre = mean(.data[[v]][is.finite(.data[[v]])]), .groups = "drop")
for (v in c("harvest", "acreage")) {
  run(v, pm(v, 1:3), "mean s1-3")
  run(v, pm(v, 3), "s3 only")
  run(v, pm(v, 2:3), "mean s2-3")
  run(v, pm(v, 1), "s1 only")
}
run("harvest", pm("harvest_raw", 1:3), "raw harvest_kg mean s1-3")
run("harvest", pm("harvest_hk", 1:3), "plot-sum mean s1-3")
run("acreage", pm("acreage_ps", 1:3), "plot-size sum mean s1-3")
run("acreage", pm("acres_tot", 1:3), "acres_tot mean (s3)")
# pre = mean of all baseline values incl. zeros for missing
d0 <- post; m0 <- feols(harvest ~ buy_treatment | survey_season, data = d0, cluster = ~ea_code); cat("harvest no lag:", coef(m0)[1], nobs(m0), "\n")
m0 <- feols(acreage ~ buy_treatment | survey_season, data = d0, cluster = ~ea_code); cat("acreage no lag:", coef(m0)[1], nobs(m0), "\n")
# households: treatment constant within hh? replaced households?
cat("hh with varying treatment:", sum(tapply(g$buy_treatment, g$hhh_id, function(x) length(unique(x))) > 1), "\n")
cat("post hh without any baseline row:", length(setdiff(unique(post$hhh_id), unique(g$hhh_id[g$survey_season <= 3]))), "\n")
# baseline rows per hh
print(table(table(g$hhh_id[g$survey_season <= 3])))
