suppressPackageStartupMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-d/mount/bold_2022_market_access_quality_upgrading"
rd <- function(f) zap_labels(read_dta(file.path(base, "data/raw", f)))
p <- rd("panel_g1.dta")
P <- function(stem, k = 1:7) { cols <- paste0(stem, k); cols <- cols[cols %in% names(p)]; m <- as.matrix(p[, cols]); ifelse(rowSums(!is.na(m)) > 0, rowSums(m, na.rm = TRUE), NA) }
hp <- P("harvest_kg_"); hk <- p$harvest_kg
d <- hk - hp
cat("harvest_kg - plotsum by season x arm (n diff>1, mean diff):\n")
print(p %>% mutate(d = d) %>% group_by(survey_season, buy_treatment) %>% summarise(n = sum(!is.na(d)), ndiff = sum(abs(d) > 1, na.rm = TRUE), md = mean(d, na.rm = TRUE), hk = mean(hk, na.rm = TRUE), hp = mean(hp, na.rm = TRUE), .groups = "drop") %>% as.data.frame())
cat("ratio hk/hp where differ:\n"); print(summary((hk / hp)[abs(d) > 1]))
cat("maize_tot_plotn where differ:\n"); print(table(p$maize_tot_plotn[abs(d) > 1 & !is.na(d)], p$survey_season[abs(d) > 1 & !is.na(d)]))
s <- rd("seller_data.dta")
ss <- s %>% group_by(hhh_id, survey_season) %>% summarise(pw = sum(price * sold_kg_p_) / sum(sold_kg_p_), pu = mean(price), n = n(), kgtot = first(sold_kg_tot), kg = sum(sold_kg_p_), .groups = "drop")
p2 <- left_join(p, ss, by = c("hhh_id", "survey_season"))
cat("FU raw means by arm:\n")
print(p2 %>% filter(survey_season >= 4) %>% group_by(buy_treatment) %>% summarise(pw = mean(pw, na.rm = TRUE), pu = mean(pu, na.rm = TRUE), hp = mean(hp[!is.na(hp)]), n_multi = sum(n > 1, na.rm = TRUE)))
cat("kgtot vs kg equal:", mean(abs(p2$kgtot - p2$kg) < 1, na.rm = TRUE), "\n")
cat("seller price==0 rows:", sum(s$price == 0), " name NA rows:", sum(is.na(s$name)), "\n")
print(table(s$survey_season, is.na(s$name)))
