suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-11-07-a/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d) %>% mutate(owner = Expropretario_ISTA, prop = match_id, round = year,
  sy = ifelse(is.na(survey_year), -9, survey_year))
specs <- list(
  sep_fe   = y ~ Above500 + norm_dist + Above500:norm_dist | round,
  sep_nofe = y ~ Above500 + norm_dist + Above500:norm_dist,
  pool_fe  = y ~ Above500 + norm_dist | round,
  pool_nofe= y ~ Above500 + norm_dist,
  nopoly_fe= y ~ Above500 | round,
  nopoly   = y ~ Above500,
  quad_fe  = y ~ Above500*(norm_dist + I(norm_dist^2)) | round,
  sep_syfe = y ~ Above500 + norm_dist + Above500:norm_dist | sy,
  reform_fe= y ~ reform + norm_dist + Above500:norm_dist | round,
  sepA_fe  = y ~ Above500 + norm_dist + norm_dist_Above | round)
for (bw in c(300, 150)) {
  s <- d %>% filter(abs(norm_dist) < bw) %>% mutate(y = hh_income_pc)
  p <- s %>% group_by(prop, round, sy, owner, Above500, norm_dist, norm_dist_Above) %>%
    summarise(reform = max(reform), y = unname(quantile(hh_income_pc, .75, type = 2) - quantile(hh_income_pc, .25, type = 2)),
              y7 = unname(quantile(hh_income_pc, .75, type = 7) - quantile(hh_income_pc, .25, type = 7)), .groups = "drop")
  for (nm in names(specs)) {
    m1 <- feols(specs[[nm]], data = s, cluster = ~owner)
    m2 <- feols(specs[[nm]], data = p, cluster = ~owner)
    cf <- function(m) { k <- grep("^(Above500|reform)$", names(coef(m)), value = TRUE)[1]; c(coef(m)[k], se(m)[k]) }
    cat(sprintf("bw%d %-10s level %8.3f (%6.3f)  iqr %8.3f (%6.3f)\n", bw, nm, cf(m1)[1], cf(m1)[2], cf(m2)[1], cf(m2)[2]))
  }
  m <- feols(y7 ~ Above500 + norm_dist + Above500:norm_dist | round, data = p, cluster = ~owner)
  cat(sprintf("bw%d iqr type7 sep_fe %8.3f\n", bw, coef(m)["Above500"]))
  m <- feols(hh_inc_pc_real ~ Above500 + norm_dist + Above500:norm_dist | round, data = s, cluster = ~owner)
  cat(sprintf("bw%d real level sep_fe %8.3f\n", bw, coef(m)["Above500"]))
}
