suppressPackageStartupMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-d/mount/bold_2022_market_access_quality_upgrading"
rd <- function(f) zap_labels(read_dta(file.path(base, "data/raw", f)))
tc <- function(expr, tag) tryCatch(expr, error = function(e) cat("ERR", tag, conditionMessage(e), "\n"))
r <- rd("anonym_returns_data.dta")
tc({
  out <- list()
  for (s in 2:4) {
    ppk <- r[[paste0("add5_ppk_", s)]]; dt <- r[[paste0("add5_sold_when_e_", s)]]
    iw <- sapply(1:20, function(b) r[[paste0("add5_ind_weight", b, "_", s)]])
    dw <- sapply(1:20, function(b) r[[paste0("add5_ind_ded_weight", b, "_", s)]])
    ew <- sapply(1:20, function(b) r[[paste0("add4_weight_", b)]])
    sel <- !is.na(iw)
    y <- rowSums(ifelse(sel, ew, 0), na.rm = TRUE); yb <- rowSums(iw, na.rm = TRUE); z <- rowSums(ifelse(sel, dw, NA), na.rm = TRUE)
    miss_ew <- rowSums(sel & is.na(ew)); miss_dw <- rowSums(sel & is.na(dw))
    out[[s]] <- data.frame(hh = r$hhh_id, tr = r$treatment, ea = r$ea_code, s = s, ppk = ppk, date = as.numeric(dt), y = y, yb = yb, z = z, nb = rowSums(sel), miss_ew = miss_ew, miss_dw = miss_dw)
  }
  sa <- bind_rows(out) %>% filter(!is.na(ppk))
  cat("sales:", nrow(sa), " hh:", n_distinct(sa$hh), " date NA:", sum(is.na(sa$date)), " miss_ew:", sum(sa$miss_ew), " miss_dw:", sum(sa$miss_dw), "\n")
  print(summary(sa$date)); cat("date range:", format(as.Date(range(sa$date, na.rm=TRUE), origin = "1970-01-01")), "\n")
  sa$ded <- 100 * (sa$y - sa$z) / sa$y; sa$dedb <- 100 * (sa$yb - sa$z) / sa$yb; sa$cheat <- 100 * (sa$y - sa$yb) / sa$y
  sa$np <- sa$ppk * sa$z / sa$y
  print(sa %>% group_by(tr) %>% summarise(n = n(), ppk = mean(ppk), ded = mean(ded), dedb = mean(dedb), cheat = mean(cheat), np = mean(np), share_gt5 = mean(ded > 5)))
  print(summary(sa$ded))
  sa$week <- as.numeric(format(as.Date(sa$date, origin = "1970-01-01"), "%U")); sa$doy <- as.numeric(format(as.Date(sa$date, origin = "1970-01-01"), "%j"))
  sa$wk_stata <- floor((sa$doy - 1) / 7) + 1
  cat("weeks:\n"); print(table(sa$wk_stata))
}, "ret")
p <- rd("panel_g1.dta"); p$fu <- p$survey_season >= 4
P <- function(stem, k = 1:6) { cols <- paste0(stem, k); cols <- cols[cols %in% names(p)]; m <- as.matrix(p[, cols]); ifelse(rowSums(!is.na(m)) > 0, rowSums(m, na.rm = TRUE), NA) }
tc({
  comp <- data.frame(
    seeds = P("seeds_cost_"), fert = P("fert_cost_"), boost = P("booster_cost_"), chem = P("tot_chem_costs_"), manure = P("manure_cost_"), equip = P("equipment_cost_"),
    totlab = P("tot_lab_costs_"), lcprep = P("lc_prep_costs_season"), lcplant = P("lc_plant_costs_season"), lcweed = P("lc_weed_costs_season"), lcspray = P("lc_spray_costs_season"), lcharv = P("lc_harv_costs_season"),
    harvc = P("harvest_cost_"), decobc = P("decobbing_cost_"), phlab = p$labor_cost_ph, photh = p$otherph_cost, dry = p$drying_cost, stor = p$storage_cost, labdry = p$labor_cost_dry, labstor = p$labor_cost_store,
    trtot = p$tot_transport_cost, trpre = p$cost_transportpre, trpost = p$cost_transportpost, saletr = P("sale_transport_cost_", 1:7),
    dec_lab = p$lc_decob_labour_costs, dec_oth = p$lc_decob_other_costs, win_lab = p$lc_winnow_labour_costs, win_oth = p$lc_winnow_other_costs,
    sort_lab = p$lc_sort_labour_costs, sort_oth = p$lc_sort_other_costs, bag_lab = p$lc_bag_labour_costs, bag_oth = p$lc_bag_other_costs,
    lhprep = P("lh_prep_hours_season"), lhplant = P("lh_plant_hours_season"), lhweed = P("lh_weed_hours_season"), lhspray = P("lh_spray_hours_season"), lhharv = P("lh_harv_hours_season"),
    lhdec = p$lh_decob_hours, lhwin = p$lh_winnow_hours, lhsort = p$lh_sort_hours, lhbag = p$lh_bag_hours)
  cat("\nControl follow-up means (UGX) and n by season (all arms):\n")
  for (v in names(comp)) cat(sprintf("%-9s ctlFU=%10.1f  allFU=%10.1f  n_by_season=%s\n", v, mean(comp[[v]][p$fu & p$buy_treatment == 0], na.rm = TRUE), mean(comp[[v]][p$fu], na.rm = TRUE), paste(tapply(!is.na(comp[[v]]), p$survey_season, sum), collapse = ",")))
  lcsum <- with(comp, lcprep + lcplant + lcweed + lcspray + lcharv)
  cat("totlab - lcsum by season:\n"); print(tapply(comp$totlab - lcsum, p$survey_season, function(x) round(c(n = sum(!is.na(x)), zero = mean(abs(x) < 1, na.rm = TRUE), m = mean(x, na.rm = TRUE)), 3)))
  ph4 <- with(comp, rowSums(cbind(dec_lab, win_lab, sort_lab, bag_lab), na.rm = TRUE))
  cat("phlab - (dec+win+sort+bag lab) by season:\n"); print(tapply(comp$phlab - ph4, p$survey_season, function(x) round(c(zero = mean(abs(x) < 1, na.rm = TRUE), m = mean(x, na.rm = TRUE)), 3)))
  ph4b <- ph4 + ifelse(is.na(comp$labdry), 0, comp$labdry) + ifelse(is.na(comp$labstor), 0, comp$labstor)
  cat("phlab - (4 lab + dry + store lab):\n"); print(tapply(comp$phlab - ph4b, p$survey_season, function(x) round(c(zero = mean(abs(x) < 1, na.rm = TRUE), m = mean(x, na.rm = TRUE)), 3)))
  ph4c <- ph4b + ifelse(is.na(comp$harvc), 0, comp$harvc) + ifelse(is.na(comp$decobc), 0, comp$decobc)
  cat("phlab - (above + harvc + decobc):\n"); print(tapply(comp$phlab - ph4c, p$survey_season, function(x) round(c(zero = mean(abs(x) < 1, na.rm = TRUE), m = mean(x, na.rm = TRUE)), 3)))
  oth4 <- with(comp, rowSums(cbind(dec_oth, win_oth, sort_oth, bag_oth), na.rm = TRUE))
  cat("photh - other4:\n"); print(tapply(comp$photh - oth4, p$survey_season, function(x) round(c(zero = mean(abs(x) < 1, na.rm = TRUE), m = mean(x, na.rm = TRUE)), 3)))
  oth4b <- oth4 + ifelse(is.na(comp$dry), 0, comp$dry) + ifelse(is.na(comp$stor), 0, comp$stor)
  cat("photh - (other4 + drying + storage):\n"); print(tapply(comp$photh - oth4b, p$survey_season, function(x) round(c(zero = mean(abs(x) < 1, na.rm = TRUE), m = mean(x, na.rm = TRUE)), 3)))
  cat("trtot - (pre+post):\n"); print(tapply(comp$trtot - comp$trpre - comp$trpost, p$survey_season, function(x) round(c(n = sum(!is.na(x)), zero = mean(abs(x) < 1, na.rm = TRUE)), 3)))
  # labour units
  for (t in c("prep","plant","weed","spray","harv")) {
    u <- p[[paste0("lc_", t, "_unit1")]]; cu <- p[[paste0("lc_", t, "_costs_unit1")]]
    cat("lc", t, "cost per unit by unit (seasons>=5):\n"); print(tapply(cu[p$survey_season >= 5], u[p$survey_season >= 5], function(x) round(c(n = sum(!is.na(x)), med = median(x, na.rm = TRUE), mean = mean(x, na.rm = TRUE)))))
    hu <- p[[paste0("lh_", t, "_unit1")]]; hh <- p[[paste0("lh_", t, "_hours_unit1")]]
    cat("lh", t, "hours per unit by unit:\n"); print(tapply(hh, hu, function(x) round(c(n = sum(!is.na(x)), med = median(x, na.rm = TRUE), mean = mean(x, na.rm = TRUE)), 2)))
  }
  # revenue & price
  revp <- P("tot_rev_combined_", 1:7); kgp <- P("sold_kg_p_", 1:7)
  cat("panel rev/kg control FU mean:", mean((revp / kgp)[p$fu & p$buy_treatment == 0 & kgp > 0], na.rm = TRUE), " n FU:", sum(!is.na(revp / kgp) & p$fu & kgp > 0), "\n")
  cat("sold kg > 0 FU n:", sum(kgp > 0 & p$fu, na.rm = TRUE), "\n")
  s <- rd("seller_data.dta")
  ss <- s %>% group_by(hhh_id, survey_season) %>% summarise(rev = sum(price * sold_kg_p_), kg = sum(sold_kg_p_), kgtot = first(sold_kg_tot), npos = sum(price > 0), n = n(), .groups = "drop")
  ss$pr <- ifelse(ss$kg > 0, ss$rev / ss$kg, NA)
  pm <- left_join(p %>% select(hhh_id, survey_season, buy_treatment, ea_code, fu), ss, by = c("hhh_id", "survey_season"))
  pm$H <- ifelse(!is.na(p$harvest_kg), p$harvest_kg, P("harvest_kg_"))
  pm$revp <- revp; pm$kgp <- kgp
  cat("seller kg vs panel kg equal share:", mean(abs(pm$kg - pm$kgp) < 1, na.rm = TRUE), " seller rev vs panel rev equal share:", mean(abs(pm$rev - pm$revp) < 5, na.rm = TRUE), "\n")
  cat("FU price nonNA:", sum(pm$fu & !is.na(pm$pr)), " control mean:", mean(pm$pr[pm$fu & pm$buy_treatment == 0], na.rm = TRUE), "\n")
  cat("FU with H nonNA & price NA:", sum(pm$fu & !is.na(pm$H) & is.na(pm$pr)), "; H==0:", sum(pm$fu & pm$H == 0, na.rm = TRUE), "; sold>harvest:", sum(pm$fu & pm$kg > pm$H, na.rm = TRUE), "\n")
  # baseline availability of price per hh
  bp <- pm %>% filter(!fu, !is.na(pr)) %>% distinct(hhh_id)
  cat("FU price obs whose hh has baseline price:", sum(pm$fu & !is.na(pm$pr) & pm$hhh_id %in% bp$hhh_id), "\n")
  bh <- pm %>% filter(!fu, !is.na(H)) %>% distinct(hhh_id)
  cat("FU H obs whose hh has baseline H:", sum(pm$fu & !is.na(pm$H) & pm$hhh_id %in% bh$hhh_id), "\n")
  # village-season prices
  vp <- pm %>% filter(!is.na(pr)) %>% group_by(ea_code, survey_season) %>% summarise(vmean = mean(pr), vmed = median(pr), vw = sum(rev) / sum(kg), .groups = "drop")
  pm <- left_join(pm, vp, by = c("ea_code", "survey_season"))
  cat("vp missing in FU with H:", sum(pm$fu & !is.na(pm$H) & is.na(pm$vmean)), "\n")
  rev0 <- ifelse(is.na(pm$rev), 0, pm$rev); kg0 <- ifelse(is.na(pm$kg), 0, pm$kg)
  hv <- list(hv_vmean = pm$H * pm$vmean, hv_vmed = pm$H * pm$vmed, hv_vw = pm$H * pm$vw,
             hv_own = ifelse(!is.na(pm$pr), pm$H * pm$pr, pm$H * pm$vmean),
             hv_revplus = rev0 + pmax(pm$H - kg0, 0) * pm$vmean, hv_revplus_med = rev0 + pmax(pm$H - kg0, 0) * pm$vmed)
  for (k in names(hv)) cat(k, " ctlFU mean UGX:", mean(hv[[k]][pm$fu & pm$buy_treatment == 0 & !is.na(pm$H)], na.rm = TRUE), " n FU:", sum(!is.na(hv[[k]]) & pm$fu), " implied rate (/286.17):", mean(hv[[k]][pm$fu & pm$buy_treatment == 0 & !is.na(pm$H)], na.rm = TRUE) / 286.17, "\n")
  cat("price by season control FU UGX:\n"); print(tapply(pm$pr[pm$buy_treatment == 0], pm$survey_season[pm$buy_treatment == 0], mean, na.rm = TRUE))
  cat("treat constant within village:", all(tapply(p$buy_treatment, p$ea_code, function(x) length(unique(x))) == 1), "  hh in one village:", all(tapply(p$ea_code, p$hhh_id, function(x) length(unique(x))) == 1), "\n")
  cat("acres: plot sum vs acres_tot FU; A NA rows FU:", sum(p$fu & is.na(P("plot_size_")) & is.na(p$acres_tot)), "\n")
  print(table(season = p$survey_season, plotn0 = p$maize_tot_plotn == 0, useNA = "ifany"))
}, "panel")
