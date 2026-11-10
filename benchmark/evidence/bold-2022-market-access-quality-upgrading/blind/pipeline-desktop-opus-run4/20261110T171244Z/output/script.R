suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/bold_2022_market_access_quality_upgrading.script-free"
rd <- function(f) {
  d <- haven::read_dta(file.path(base_dir, "data/raw", f))
  d <- haven::zap_labels(d)
  as.data.frame(d)
}
fc <- function(nms, pats, exclude = NULL) {
  for (p in pats) {
    m <- grep(p, nms, ignore.case = TRUE, value = TRUE)
    if (!is.null(exclude)) m <- m[!grepl(exclude, m, ignore.case = TRUE)]
    if (length(m) > 0) return(m[1])
  }
  NA_character_
}
num <- function(x) {
  if (inherits(x, "Date")) return(as.numeric(x))
  suppressWarnings(as.numeric(x))
}
safe <- function(expr, label = "") tryCatch(expr, error = function(e) {
  message("ERROR [", label, "]: ", conditionMessage(e)); NA_real_
})
res <- list()
FX <- 3700  # UGX per USD (approximate rate over the study period)

# =====================================================================
# Returns-to-quality experiment (Table 2)
# =====================================================================
R <- rd("anonym_returns_data.dta")
nR <- names(R)
message("RETURNS columns: ", paste(nR, collapse = " "))
R$treat <- num(R[[fc(nR, c("^treatment$", "treat"))]])
hhc <- fc(nR, c("^hhh_id$", "^hh_id$", "^hhid$", "hhh_id", "^id$", "hhh"))
R$hh <- if (!is.na(hhc)) as.character(R[[hhc]]) else as.character(seq_len(nrow(R)))
vc <- fc(nR, c("^ea_code$", "ea_code", "^village$", "village", "vill", "^lc1"))
R$vill <- if (!is.na(vc)) as.character(R[[vc]]) else "1"
message("hh col: ", hhc, " ; village col: ", vc)

# ---- Column 2: lab defects ----
res$treatment_defects_lab_table2_col2 <- safe({
  totw <- fc(nR, c("^Total_weight_of_maize_g$", "total_weight", "totalweight"))
  good <- fc(nR, c("good_grain", "^good", "clean_grain"))
  cand <- nR[grepl("^[A-Z]", nR)]
  cand <- cand[!grepl("Total_weight|aflatox|moist|^Total_", cand, ignore.case = TRUE)]
  cand <- cand[sapply(cand, function(cc) is.numeric(num(R[[cc]])) && any(!is.na(num(R[[cc]]))))]
  if (!is.na(good)) cand <- character(0)
  # prefer category totals; drop sub-components that share the same leading word as a total
  tots <- cand[grepl("tot", cand, ignore.case = TRUE)]
  if (length(tots) > 0) {
    lead <- function(x) tolower(sub("_.*$", "", x))
    cand <- c(tots, cand[!grepl("tot", cand, ignore.case = TRUE) & !(lead(cand) %in% lead(tots))])
  }
  message("Lab defect columns: ", paste(cand, collapse = ", "), " ; total weight: ", totw, " ; good: ", good)
  W <- if (!is.na(totw)) num(R[[totw]]) else rep(200, nrow(R))
  W[is.na(W) | W <= 0] <- NA
  if (!is.na(good)) {
    dg <- W - num(R[[good]])
  } else {
    M <- sapply(cand, function(cc) num(R[[cc]]))
    if (is.null(dim(M))) M <- matrix(M, ncol = 1)
    allna <- rowSums(!is.na(M)) == 0
    dg <- rowSums(M, na.rm = TRUE); dg[allna] <- NA
  }
  R$lab_def <- 100 * dg / W
  d2 <- R[!is.na(R$lab_def) & !is.na(R$treat), ]
  m2 <- feols(lab_def ~ treat | vill, data = d2, vcov = "hetero")
  message("Lab defects N = ", nobs(m2))
  unname(coef(m2)["treat"])
}, "lab")

# ---- Column 1: visual defects per bag ----
bag_df <- tryCatch({
  kw <- "dirt|cob|stone|dust|insect|broken|immature|damag|rotten|mo[u]?ld|defect"
  a4 <- nR[grepl("^add4_", nR) & grepl("_[0-9]+$", nR)]
  stem <- sub("_[0-9]+$", "", a4)
  idx <- as.integer(sub("^.*_([0-9]+)$", "\\1", a4))
  isdef <- grepl(kw, stem, ignore.case = TRUE) & !grepl("random", stem, ignore.case = TRUE)
  a4 <- a4[isdef]; stem <- stem[isdef]; idx <- idx[isdef]
  message("Visual defect stems: ", paste(unique(stem), collapse = ", "))
  ustem <- unique(stem)
  # a single count variable?
  cnt <- ustem[grepl("count|num|tot|n_def|ndef", ustem, ignore.case = TRUE)]
  out <- list()
  for (k in sort(unique(idx))) {
    cols <- a4[idx == k]; st <- stem[idx == k]
    if (length(cnt) == 1 && cnt %in% st) {
      v <- num(R[[cols[st == cnt]]])
    } else {
      vals <- lapply(cols, function(cc) {
        x <- R[[cc]]
        if (is.character(x)) {
          ifelse(is.na(x) | trimws(x) == "", NA,
                 sapply(strsplit(trimws(x), "\\s+"), function(t) sum(!t %in% c("0", "none", "11", "99"))))
        } else num(x)
      })
      M <- do.call(cbind, vals)
      M[M < 0] <- NA
      allna <- rowSums(!is.na(M)) == 0
      v <- rowSums(M > 0, na.rm = TRUE)
      if (ncol(M) == 1) v <- M[, 1]
      v[allna] <- NA
    }
    out[[length(out) + 1]] <- data.frame(hh = R$hh, vill = R$vill, treat = R$treat, bag = k, vis_def = v)
  }
  bd <- do.call(rbind, out)
  bd[!is.na(bd$vis_def) & !is.na(bd$treat), ]
}, error = function(e) { message("ERROR [bags]: ", conditionMessage(e)); NULL })

res$treatment_defects_visual_table2_col1 <- safe({
  m1 <- feols(vis_def ~ treat | vill, data = bag_df, cluster = ~hh)
  unname(coef(m1)["treat"])
}, "visual")
res$n_obs_table2_col1_bags <- safe(nrow(bag_df), "nbags")

# ---- Columns 3-5: sales ----
sales_df <- tryCatch({
  a5 <- nR[grepl("^add5_", nR) & grepl("_[0-9]+$", nR)]
  stem5 <- sub("_[0-9]+$", "", a5)
  message("add5 stems: ", paste(unique(stem5), collapse = ", "))
  ppk_stem <- "add5_ppk"
  ks <- sort(as.integer(sub("^.*_([0-9]+)$", "\\1", a5[stem5 == ppk_stem])))
  us <- unique(stem5)
  ded_stem <- us[grepl("deduct", us, ignore.case = TRUE)][1]
  date_stem <- us[grepl("date|day|week|when", us, ignore.case = TRUE)][1]
  wt <- us[grepl("kg|weight|wt", us, ignore.case = TRUE) & us != ppk_stem]
  meas_stem <- wt[grepl("meas|enum|weigh|scale|actual|our", wt, ignore.case = TRUE)][1]
  agr_stem <- wt[grepl("agree|sold|paid|trader|buyer|sale", wt, ignore.case = TRUE) & wt != meas_stem][1]
  if (is.na(meas_stem) && length(wt) >= 2) meas_stem <- wt[1]
  if (is.na(agr_stem) && length(wt) >= 2) agr_stem <- setdiff(wt, meas_stem)[1]
  message("ded: ", ded_stem, " date: ", date_stem, " measured: ", meas_stem, " agreed: ", agr_stem)
  getk <- function(s, k) {
    cc <- paste0(s, "_", k)
    if (is.na(s) || !(cc %in% nR)) return(rep(NA, nrow(R)))
    R[[cc]]
  }
  out <- list()
  for (k in ks) {
    p <- num(getk(ppk_stem, k))
    dt <- getk(date_stem, k)
    if (!inherits(dt, "Date")) {
      dn <- num(dt)
      dt <- if (all(is.na(dn))) as.Date(NA) + rep(0, nrow(R)) else as.Date(dn, origin = "1960-01-01")
    }
    y <- num(getk(meas_stem, k)); z <- num(getk(agr_stem, k))
    ded <- if (!is.na(ded_stem)) num(getk(ded_stem, k)) else 100 * (y - z) / y
    if (!is.na(ded_stem) && all(is.na(ded))) ded <- 100 * (y - z) / y
    np <- if (any(!is.na(y) & !is.na(z))) p * z / y else p * (1 - ded / 100)
    out[[length(out) + 1]] <- data.frame(hh = R$hh, vill = R$vill, treat = R$treat, sale = k,
                                         price = p, week = format(dt, "%Y-%U"), ded = ded, netp = np,
                                         stringsAsFactors = FALSE)
  }
  sd <- do.call(rbind, out)
  sd <- sd[!is.na(sd$price) & sd$price > 0 & !is.na(sd$treat), ]
  sd$week[is.na(sd$week)] <- "NA"
  sd
}, error = function(e) { message("ERROR [sales]: ", conditionMessage(e)); NULL })

res$treatment_price_table2_col3 <- safe({
  m <- feols(price ~ treat | vill + week, data = sales_df, cluster = ~hh); unname(coef(m)["treat"])
}, "price")
res$treatment_deductions_table2_col4 <- safe({
  m <- feols(ded ~ treat | vill + week, data = sales_df, cluster = ~hh); unname(coef(m)["treat"])
}, "ded")
res$treatment_net_price_table2_col5 <- safe({
  m <- feols(netp ~ treat | vill + week, data = sales_df, cluster = ~hh); unname(coef(m)["treat"])
}, "netp")
res$n_obs_table2_cols3_5_sales <- safe(nrow(sales_df), "nsales")

# =====================================================================
# Market access experiment (Table 6, Panel A)
# =====================================================================
P <- rd("panel_g1.dta")
nP <- names(P)
message("PANEL_G1 columns: ", paste(nP, collapse = " "))
P$season <- num(P$survey_season)
P$hh <- as.character(P[[fc(nP, c("^hhh_id$", "hhh_id", "^hh_id$", "hhid"))]])
P$vill <- as.character(P[[fc(nP, c("^ea_code$", "ea_code", "village"))]])
tc <- fc(nP, c("^buy_treatment$", "^treatment$", "^treat$", "buy_treat", "treat"))
if (!is.na(tc)) {
  P$treat <- num(P[[tc]])
} else {
  B <- rd("buy_data.dta")
  bt <- B %>% group_by(ea_code) %>% summarise(treat = max(num(buy_treatment), na.rm = TRUE))
  P$treat <- bt$treat[match(P$vill, as.character(bt$ea_code))]
}
# treatment is a village-level time-invariant assignment
vt <- tapply(P$treat, P$vill, function(x) suppressWarnings(max(x, na.rm = TRUE)))
P$treat <- as.numeric(vt[P$vill]); P$treat[!is.finite(P$treat)] <- NA
postc <- fc(nP, c("^season_post$"))
P$post <- if (!is.na(postc)) num(P[[postc]]) else as.numeric(P$season > 3)
P$post[is.na(P$post)] <- as.numeric(P$season[is.na(P$post)] > 3)
message("treat col: ", tc, " ; table(treat, post): ")
print(table(P$treat, P$post, useNA = "ifany"))

fxc <- fc(nP, c("exchange", "^fx", "usd_rate", "ugx_usd"))
if (!is.na(fxc)) { f <- median(num(P[[fxc]]), na.rm = TRUE); if (is.finite(f) && f > 1000) FX <- f }

to_usd <- function(x) { if (median(x, na.rm = TRUE) > 50) x / FX else x }

# price per kg
prc <- fc(nP, c("price.*usd", "^price_avg", "^avg_price", "^price$", "^price_kg", "ppk", "price"), exclude = "cost")
message("price col: ", prc)
price_ugx <- num(P[[prc]])
if (median(price_ugx, na.rm = TRUE) < 50) price_ugx <- price_ugx * FX
P$price_usd <- price_ugx / FX

# harvest and yield
hc <- fc(nP, c("^harvest_kg_tot$", "harvest_kg", "harvest_tot"))
P$harvest <- num(P[[hc]])
ac <- fc(nP, c("^acres_tot", "^plot_size_tot", "area_tot", "^acres$", "acre"))
if (!is.na(ac)) {
  P$area <- num(P[[ac]])
} else {
  pc <- grep("^plot_size_[0-9]+$", nP, value = TRUE)
  M <- sapply(pc, function(cc) num(P[[cc]]))
  a <- rowSums(M, na.rm = TRUE); a[rowSums(!is.na(M)) == 0] <- NA
  P$area <- a
}
message("harvest col: ", hc, " ; area col: ", ac)
P$yield <- ifelse(P$area > 0, P$harvest / P$area, NA)

# harvest value at community-specific market price
hvc <- fc(nP, c("harvest_value", "value_harvest", "harv_val", "harvest_usd"))
if (!is.na(hvc)) {
  P$hvalue <- to_usd(num(P[[hvc]]))
} else {
  cp <- P %>% group_by(vill, season) %>% summarise(cp = median(price_ugx, na.rm = TRUE), .groups = "drop")
  sp <- P %>% group_by(season) %>% summarise(sp = median(price_ugx, na.rm = TRUE), .groups = "drop")
  P <- P %>% left_join(cp, by = c("vill", "season")) %>% left_join(sp, by = "season")
  P$cp[is.na(P$cp)] <- P$sp[is.na(P$cp)]
  P$hvalue <- P$harvest * P$cp / FX
}

# monetary costs
prof_c <- fc(nP, c("^profit"))
costs <- grep("cost|expens", nP, value = TRUE, ignore.case = TRUE)
costs <- costs[sapply(costs, function(cc) is.numeric(num(P[[cc]])))]
stemf <- function(x) sub("(_[0-9]+)+$", "", x)
tots <- costs[grepl("tot", costs)]
totstem <- unique(sub("_?tot(_ps)?$|^tot_", "", sub("(_[0-9]+)+$", "", tots)))
keep <- costs[sapply(costs, function(cc) {
  if (cc %in% tots) return(TRUE)
  st <- stemf(cc)
  !any(sapply(totstem, function(t) grepl(t, st, fixed = TRUE)))
})]
message("cost columns used: ", paste(keep, collapse = ", "))
CM <- sapply(keep, function(cc) num(P[[cc]]))
P$cost_ugx <- rowSums(CM, na.rm = TRUE)
if (!is.na(prof_c)) {
  P$profit_m <- to_usd(num(P[[prof_c]]))
} else {
  P$profit_m <- P$hvalue - P$cost_ugx / FX
}

# own labor hours valued at market wage
own_h <- grep("hours", nP, value = TRUE)
own_h <- own_h[!grepl("hire|^lw_|^lhi", own_h, ignore.case = TRUE)]
fam <- own_h[grepl("^lf_|^fl_|fam|own|^lh_", own_h, ignore.case = TRUE)]
if (length(fam) > 0) own_h <- fam
own_h <- own_h[sapply(own_h, function(cc) is.numeric(num(P[[cc]])))]
message("own-hour columns: ", paste(own_h, collapse = ", "))
wc <- fc(nP, c("wage"))
wage_h <- if (!is.na(wc)) num(P[[wc]]) else rep(NA, nrow(P))
if (all(is.na(wage_h))) wage_h <- rep(5000 / 6, nrow(P))  # UGX per hour (approx. daily wage / 6 hours)
wage_h[is.na(wage_h)] <- median(wage_h, na.rm = TRUE)
if (length(own_h) > 0) {
  HM <- sapply(own_h, function(cc) num(P[[cc]]))
  P$own_hours <- rowSums(HM, na.rm = TRUE)
} else P$own_hours <- 0
P$profit_o <- P$profit_m - P$own_hours * wage_h / FX

ancova <- function(var) {
  d <- P[!is.na(P$treat), c("hh", "vill", "season", "post", "treat", var)]
  names(d)[6] <- "y"
  bl <- d %>% filter(post == 0) %>% group_by(hh) %>% summarise(base = mean(y, na.rm = TRUE), .groups = "drop")
  dp <- d %>% filter(post == 1, !is.na(y)) %>% left_join(bl, by = "hh")
  dp$base_miss <- as.numeric(!is.finite(dp$base))
  dp$base[!is.finite(dp$base)] <- mean(dp$base[is.finite(dp$base)])
  feols(y ~ treat + base + base_miss | season, data = dp, cluster = ~vill)
}
res$market_access_price_table6_panelA_col1 <- safe(unname(coef(ancova("price_usd"))["treat"]), "ma_price")
res$market_access_yield_table6_panelA_col4 <- safe(unname(coef(ancova("yield"))["treat"]), "ma_yield")
res$market_access_harvest_value_table6_panelA_col5 <- safe(unname(coef(ancova("hvalue"))["treat"]), "ma_hv")
res$market_access_profit_monetary_table6_panelA_col7 <- safe(unname(coef(ancova("profit_m"))["treat"]), "ma_pm")
res$market_access_profit_incl_own_hours_table6_panelA_col8 <- safe(unname(coef(ancova("profit_o"))["treat"]), "ma_po")
res$n_obs_table6_panelA_cols3_5 <- safe(nobs(ancova("harvest")), "ma_n")

nm <- c("treatment_defects_visual_table2_col1", "treatment_defects_lab_table2_col2",
        "treatment_price_table2_col3", "treatment_deductions_table2_col4",
        "treatment_net_price_table2_col5", "n_obs_table2_col1_bags", "n_obs_table2_cols3_5_sales",
        "market_access_price_table6_panelA_col1", "market_access_yield_table6_panelA_col4",
        "market_access_harvest_value_table6_panelA_col5", "market_access_profit_monetary_table6_panelA_col7",
        "market_access_profit_incl_own_hours_table6_panelA_col8", "n_obs_table6_panelA_cols3_5")
for (n in nm) {
  v <- res[[n]]
  if (is.null(v) || length(v) == 0) v <- NA
  cat(sprintf("RESULT:%s=%s\n", n, format(as.numeric(v), digits = 10)))
}