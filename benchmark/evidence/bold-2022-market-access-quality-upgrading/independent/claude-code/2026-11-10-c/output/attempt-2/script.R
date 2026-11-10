suppressMessages({library(haven); library(dplyr); library(readxl); library(tidyr)})
B <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-c/mount/bold_2022_market_access_quality_upgrading/"
D <- paste0(B, "data/raw/")
options(width = 200)
# survey form for sales
x <- read_excel(paste0(B, "survey_materials/return_survey/add5_bags_sales.xlsx"), sheet = 1)
cat("add5 sheets:", excel_sheets(paste0(B, "survey_materials/return_survey/add5_bags_sales.xlsx")), "\n")
x <- as.data.frame(x)
cols <- intersect(c("type","name","label","label::English","relevance","calculation","constraint"), names(x))
cat("cols:", names(x), "\n")
for (i in seq_len(nrow(x))) {
  r <- x[i, cols]; r[is.na(r)] <- ""
  cat(paste(substr(as.character(r), 1, 110), collapse=" | "), "\n")
}
x <- as.data.frame(read_excel(paste0(B, "survey_materials/return_survey/add4_measuring_bags.xlsx"), sheet = 1))
cols <- intersect(c("type","name","label","label::English","relevance","calculation"), names(x))
cat("\n==== add4\n")
for (i in seq_len(nrow(x))) { r <- x[i, cols]; r[is.na(r)] <- ""; cat(paste(substr(as.character(r), 1, 110), collapse=" | "), "\n") }

r <- read_dta(paste0(D, "anonym_returns_data.dta"))
dvars <- c("insect","insect_live","dirty","cobs","stones","dust","broken","immature","damage","rot","mould")
nb <- 0; nw <- 0
for (b in 1:20) {
  m <- sapply(dvars, function(v) r[[paste0("add4_", v, "_", b)]])
  anyd <- rowSums(!is.na(m)) > 0
  nb <- nb + sum(anyd); nw <- nw + sum(!is.na(r[[paste0("add4_weight_", b)]]))
}
cat("bags any defect nonNA:", nb, " bags with weight:", nw, "\n")
for (k in 1:4) {
  w <- sapply(1:20, function(j) r[[paste0("add5_ind_weight", j, "_", k)]])
  has <- rowSums(!is.na(w)) > 0
  cat("sale", k, ": hh with bag weights", sum(has), " ppk nonNA", sum(!is.na(r[[paste0("add5_ppk_", k)]])),
      " date nonNA", sum(!is.na(r[[paste0("add5_sold_when_e_", k)]]) & r[[paste0("add5_sold_when_e_", k)]] != ""),
      " ppk&date", sum(!is.na(r[[paste0("add5_ppk_", k)]]) & !is.na(r[[paste0("add5_sold_when_e_", k)]]) & r[[paste0("add5_sold_when_e_", k)]] != ""), "\n")
}
print(head(as.data.frame(r[, c("hhh_id","treatment","ea_code","add4_random_bag","add5_ppk_1","add5_ppk_2","add5_ppk_3","add5_sold_when_e_1","add5_sold_when_e_2","add5_sold_when_e_3","add5_ind_weight1_1","add5_ind_ded_weight1_1","add5_ind_weight1_2","add5_ind_ded_weight1_2","add4_weight_1","add4_weight_2")]), 25))
print(table(r$treatment, r$ea_code))
print(table(r$Total_aflatoxins))
