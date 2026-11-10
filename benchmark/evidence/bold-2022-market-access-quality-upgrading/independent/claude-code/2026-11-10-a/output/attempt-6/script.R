suppressMessages({library(haven); library(dplyr); library(tidyr)})
B <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading/"
D <- paste0(B, "data/raw/")
options(width=250)
XR <- 3700  # UGX per US dollar (not stated in paper; chosen so baseline mean price ~ US$0.20/kg as in Table 3)
WAGE_USD <- 26 / 118  # hourly market wage implied by text: US$26 of hired labour = 118 hours
g <- read_dta(paste0(D, "panel_g1.dta"))
g$ea_code <- as.character(g$ea_code); g$survey_season <- as.numeric(g$survey_season)
num <- function(v) if (v %in% names(g)) as.numeric(g[[v]]) else rep(NA_real_, nrow(g))
rs <- function(vs) { m <- sapply(vs, num); if (is.null(dim(m))) m <- matrix(m, ncol = 1)
  ifelse(rowSums(!is.na(m)) > 0, rowSums(m, na.rm = TRUE), NA) }
z0 <- function(x) ifelse(is.na(x), 0, x)

# harvest (kg) and acreage
harv_plots <- rs(paste0("harvest_kg_", 1:9)); acres_plots <- rs(paste0("plot_size_", 1:12))
g$harvest <- ifelse(g$survey_season == 2 | is.na(g$harvest_kg), harv_plots, g$harvest_kg)
g$acres <- ifelse(is.na(g$acres_tot), acres_plots, g$acres_tot)
g$yield <- ifelse(!is.na(g$harvest) & !is.na(g$acres) & g$acres > 0, g$harvest / g$acres, NA)

# prices from sale-level data
s <- read_dta(paste0(D, "seller_data.dta"))
hs <- s %>% filter(price > 0, sold_kg_p_ > 0) %>% mutate(survey_season = as.numeric(survey_season)) %>%
  group_by(hhh_id, survey_season) %>% summarise(rev = sum(price * sold_kg_p_), kg_sold = sum(sold_kg_p_), .groups = "drop")
g <- g %>% left_join(hs, by = c("hhh_id", "survey_season"))
g$price_ugx <- g$rev / g$kg_sold
comm <- g %>% filter(!is.na(price_ugx)) %>% group_by(ea_code, survey_season) %>% summarise(p_comm = median(price_ugx), .groups = "drop")
seas <- g %>% filter(!is.na(price_ugx)) %>% group_by(survey_season) %>% summarise(p_seas = median(price_ugx), .groups = "drop")
g <- g %>% left_join(comm, by = c("ea_code", "survey_season")) %>% left_join(seas, by = "survey_season") %>%
  mutate(p_comm = ifelse(is.na(p_comm), p_seas, p_comm))
g$price <- g$price_ugx / XR
g$hvalue <- ifelse(is.na(g$harvest), NA, (z0(g$rev) + pmax(g$harvest - z0(g$kg_sold), 0) * g$p_comm) / XR)

# monetary expenses: inputs, equipment, hired labour (pre-harvest + harvest), post-harvest labour & other costs, drying, storage, transport
inputs <- rs(c(paste0("seeds_cost_", 1:6), paste0("fert_cost_", 1:5), paste0("booster_cost_", 1:5), paste0("manure_cost_", 1:3),
               paste0("tot_chem_costs_", 1:6), "seeds_cost", "fert_cost", "booster_cost"))
equip <- rs(paste0("equipment_cost_", 1:5))
hired <- rs(paste0("tot_lab_costs_", 1:6))
post <- rs(c("labor_cost_ph", "otherph_cost", "drying_cost", "storage_cost", "labor_cost_store", paste0("harvest_cost_", 1:5), paste0("decobbing_cost_", 1:5)))
transport <- ifelse(!is.na(g$tot_transport_cost), g$tot_transport_cost, rs(c("cost_transportpre", "cost_transportpost")))
g$expenses <- ifelse(is.na(inputs), NA, (inputs + z0(equip) + z0(hired) + z0(post) + z0(transport)) / XR)
g$profit <- g$hvalue - g$expenses
own_hours <- rs(c(paste0("lh_", rep(c("prep", "plant", "weed", "spray", "harv"), each = 6), "_hours_season", 1:6),
                  "lh_decob_hours", "lh_winnow_hours", "lh_sort_hours", "lh_bag_hours"))
g$own_hours <- ifelse(g$survey_season >= 5, own_hours, NA)
g$profit_own <- g$profit - WAGE_USD * g$own_hours


g$acres_plots <- acres_plots
g$yield_p <- ifelse(!is.na(g$harvest) & !is.na(acres_plots) & acres_plots > 0, g$harvest / acres_plots, NA)
g$seedsok <- !is.na(rs(paste0("seeds_cost_", 1:6)))
cat("baseline descriptives (Table 3 targets: harvest 2.10t n499, yield 2.09 t/ha n499, price .20 n470, HV 433.2 n499, exp 146.3 n363, profit 263.7 n363)\n")
b <- g %>% filter(survey_season <= 3)
f <- function(x) sprintf("%.3f (n=%d)", mean(x, na.rm=TRUE), sum(!is.na(x)))
cat("harvest t", f(b$harvest/1000), " yield t/ha", f(b$yield*2.471/1000), " yield_p", f(b$yield_p*2.471/1000), " price", f(b$price), " HV", f(b$hvalue), "\n")
cat("exp (seeds ok)", f(b$expenses[b$seedsok]), " profit", f(b$profit[b$seedsok]), " acres", f(b$acres), "\n")
for (s in 1:3) { bb <- b[b$survey_season==s,]; cat("season", s, "harv", f(bb$harvest), "acres", f(bb$acres), "HV", f(bb$hvalue), "exp", f(bb$expenses[bb$seedsok]), "\n") }
fc <- g %>% filter(survey_season >= 4, buy_treatment == 0)
cat("followup control (targets price .15 n617, acreage 2.29 n677, harvest 1887.52 n658, yield 791.97, HV 286.17, exp 106.38 n640, profit 177.23 n640, profit_own 120.25 n464)\n")
cat("acres", f(fc$acres), " acres_plots", f(fc$acres_plots), " yield", f(fc$yield), " yield_p", f(fc$yield_p), " HV", f(fc$hvalue), "\n")
cat("exp", f(fc$expenses[fc$seedsok]), " profit", f(fc$profit[fc$seedsok]), " profit_own", f(fc$profit_own), " own hours", f(fc$own_hours), "\n")
fa <- g %>% filter(survey_season >= 4)
cat("all followup N: acres", sum(!is.na(fa$acres)), " yield", sum(!is.na(fa$yield)), " seedsok", sum(fa$seedsok), " seedsok&HV", sum(fa$seedsok & !is.na(fa$hvalue)), " own", sum(!is.na(fa$profit_own) & fa$seedsok), "\n")
# households with any baseline price
pb <- b %>% group_by(hhh_id) %>% summarise(any = any(!is.na(price)))
cat("followup price obs with no baseline price:", sum(!is.na(fa$price) & fa$hhh_id %in% pb$hhh_id[!pb$any]), "\n")
# yield distribution tails
print(quantile(fa$yield, c(0, .01, .5, .99, 1), na.rm=TRUE)); print(quantile(fa$yield_p, c(0, .01, .5, .99, 1), na.rm=TRUE))
cat("followup obs with acres_tot != plot sum:", sum(abs(fa$acres - fa$acres_plots) > 0.01, na.rm=TRUE), "\n")
