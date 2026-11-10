# Exploratory run 2: survey instruments + data structure checks (no RESULT lines)
suppressMessages({library(haven); library(dplyr); library(readxl)})
options(width = 250)
B <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-c/mount/bold_2022_market_access_quality_upgrading/"
M <- paste0(B, "data/raw/")
for (f in c("survey_materials/return_survey/add5_bags_sales.xlsx", "survey_materials/return_survey/add4_measuring_bags.xlsx")) {
  cat("\n#####", f, "\n"); sh <- excel_sheets(paste0(B, f)); print(sh)
  s <- read_excel(paste0(B, f), sheet = sh[1])
  cols <- intersect(c("type", "name", "label::English", "label", "relevance", "calculation", "constraint"), names(s))
  s <- as.data.frame(s[, cols]); s <- s[!is.na(s$name) | !is.na(s$type), ]
  for (i in seq_len(nrow(s))) cat(paste(substr(ifelse(is.na(unlist(s[i, ])), "", unlist(s[i, ])), 1, 110), collapse = " | "), "\n")
}
f <- "survey_materials/main_survey/survey_instrument_main.xlsx"
cat("\n#####", f, "\n"); sh <- excel_sheets(paste0(B, f)); print(sh)
s <- read_excel(paste0(B, f), sheet = sh[1]); cat("cols:", names(s), "\n")
cols <- intersect(c("type", "name", "label::English", "label", "relevance", "calculation"), names(s))
s <- as.data.frame(s[, cols]); s <- s[!is.na(s$name), ]
keep <- grepl("harvest|acres|plot_size|sold|price|rev|cost|wage|lh_|lc_|hours|exchange|usd|dollar|consum|lab", s$name, ignore.case = TRUE)
for (i in which(keep)) cat(paste(substr(ifelse(is.na(unlist(s[i, ])), "", unlist(s[i, ])), 1, 140), collapse = " | "), "\n")

r <- read_dta(paste0(M, "anonym_returns_data.dta"))
cat("\nreturns: treatment table\n"); print(table(r$treatment))
for (s_ in 1:4) {
  nb <- rowSums(!is.na(as.matrix(r[, paste0("add5_ind_weight", 1:20, "_", s_)])))
  cat("sale", s_, "ppk nonNA", sum(!is.na(r[[paste0("add5_ppk_", s_)]])), " date nonNA", sum(!is.na(r[[paste0("add5_sold_when_e_", s_)]]) & r[[paste0("add5_sold_when_e_", s_)]] != ""), " hh with >=1 bag weight", sum(nb > 0), " ppk&nobag", sum(nb == 0 & !is.na(r[[paste0("add5_ppk_", s_)]])), "\n")
}
cat("class of sold_when:", class(r$add5_sold_when_e_1), "\n"); print(head(r$add5_sold_when_e_1, 10))
nbag <- rowSums(!is.na(as.matrix(r[, paste0("add4_weight_", 1:20)])))
cat("bags (weight nonNA) total", sum(nbag), " by treatment:", tapply(nbag, r$treatment, sum), "\n")
cat("hh with any ppk:", sum(rowSums(!is.na(as.matrix(r[, paste0("add5_ppk_", 1:4)]))) > 0), "\n")
# visual item missingness pattern by treatment for bag 1
for (it in c("dirty", "cobs", "stones", "dust", "insect", "insect_live", "broken", "immature", "damage", "rot", "mould")) {
  x <- r[[paste0("add4_", it, "_1")]]
  cat(sprintf("%-12s bag1: NA by T: %s  values: %s\n", it, paste(tapply(is.na(x), r$treatment, sum), collapse = "/"), paste(names(table(x, useNA = "ifany")), table(x, useNA = "ifany"), collapse = " ")))
}
# compare random bag vs ind weights
cat("random bag in sale weights? \n")
rb <- r$add4_random_bag
inS <- sapply(seq_len(nrow(r)), function(i) any(!is.na(unlist(r[i, paste0("add5_ind_weight", rb[i], "_", 1:4)]))))
print(table(inS))
# example hh rows: bag weights vs sale weights
for (i in 1:6) {
  cat("hh", i, "T", r$treatment[i], "rb", rb[i], "\n  add4 w:", unlist(r[i, paste0("add4_weight_", 1:12)]), "\n")
  for (s_ in 1:4) cat("  s", s_, "ppk", r[[paste0("add5_ppk_", s_)]][i], "w:", unlist(r[i, paste0("add5_ind_weight", 1:12, "_", s_)]), " dw:", unlist(r[i, paste0("add5_ind_ded_weight", 1:12, "_", s_)]), "\n")
}

g <- read_dta(paste0(M, "panel_g1.dta"))
cat("\npanel_g1 first columns:\n"); print(names(g)[1:40])
cat("hh per season:\n"); print(table(g$survey_season))
cat("n unique hh:", length(unique(g$hhh_id)), "\n")
chk <- c("harvest_kg", "harvest_kg_1", "acres_tot", "plot_size_1", "sold_kg_p_1", "tot_rev_combined_1", "tot_lab_costs_1", "labor_cost_ph", "otherph_cost", "tot_transport_cost", "cost_transportpre", "cost_transportpost", "tot_chem_costs_1", "lh_prep_hours_season1", "lc_prep_costs_season1", "decob", "equipment_cost_1", "harvest_cost_1", "drying_cost", "storage_cost", "decobbing_cost_1", "seeds_cost_1", "fert_cost_1", "booster_cost_1", "manure_cost_1")
for (v in chk) if (v %in% names(g)) cat(sprintf("%-25s nonNA by season: %s\n", v, paste(tapply(!is.na(g[[v]]), g$survey_season, sum), collapse = " ")))
cat("form_used by season\n"); print(table(g$form_used, g$survey_season))
sd <- read_dta(paste0(M, "seller_data.dta"))
cat("\nseller rows by season:\n"); print(table(sd$survey_season)); print(head(as.data.frame(sd), 15))
cat("price==0 count:", sum(sd$price == 0), " sold_kg_p_==0:", sum(sd$sold_kg_p_ == 0), "\n")
