suppressMessages({library(haven); library(dplyr); library(readxl)})
M <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading/"
D <- paste0(M, "data/raw/")
options(width=250)
# survey instrument rows of interest
sv <- paste0(M, "survey_materials/main_survey/survey_instrument_main.xlsx")
cat("sheets:", excel_sheets(sv), "\n")
s <- read_excel(sv, sheet=1)
cat("cols:", names(s), "\n")
s <- as.data.frame(s)
nm <- s$name; ty <- s$type; lab <- s[[grep("^label", names(s))[1]]]
calc <- if ("calculation" %in% names(s)) s$calculation else NA
keep <- grepl("^(lh_|lc_|tot_lab|hired|wage|fh_|harvest_kg|sold_kg|ppk|price|tot_rev|acres|plot_size|own_|cons)", nm) | grepl("wage|hours|price", lab, ignore.case=TRUE)
for (i in which(keep)) cat(i, "|", ty[i], "|", nm[i], "|", substr(gsub("\n"," ",lab[i]),1,150), "|", substr(calc[i],1,200), "\n")
# returns survey add5
for (f in c("add4_measuring_bags.xlsx","add5_bags_sales.xlsx")) {
  sv2 <- paste0(M, "survey_materials/return_survey/", f)
  s2 <- as.data.frame(read_excel(sv2, sheet=1)); cat("=====", f, names(s2), "\n")
  lab2 <- s2[[grep("^label", names(s2))[1]]]; calc2 <- if ("calculation" %in% names(s2)) s2$calculation else NA
  for (i in seq_len(nrow(s2))) if (!is.na(s2$name[i])) cat(i, "|", s2$type[i], "|", s2$name[i], "|", substr(gsub("\n"," ",lab2[i]),1,140), "|", substr(calc2[i],1,150), "\n")
}
g1 <- read_dta(paste0(D,"panel_g1.dta"))
cat("season x treat\n"); print(table(g1$survey_season, g1$buy_treatment))
print(table(g1$form_used, g1$survey_season))
for (v in c("lh_prep_unit1","lc_prep_unit1","lh_harv_unit1","lc_harv_unit1")) print(table(g1[[v]], g1$survey_season))
cat("dups hh-season:", sum(duplicated(g1[,c("hhh_id","survey_season")])), "\n")
sd <- read_dta(paste0(D,"seller_data.dta")); print(head(as.data.frame(sd), 20)); print(table(sd$survey_season))
print(summary(sd$price)); print(tapply(sd$price, sd$survey_season, median))
r <- read_dta(paste0(D,"anonym_returns_data.dta"))
cat("n bags per hh:\n"); nb <- rowSums(!is.na(as.matrix(r[, paste0("add4_weight_",1:20)]))); print(table(nb)); cat("total", sum(nb), "\n")
for (s_ in 1:4) cat("sale", s_, "ppk nonNA", sum(!is.na(r[[paste0("add5_ppk_",s_)]])), "date nonNA", sum(!is.na(r[[paste0("add5_sold_when_e_",s_)]]) & r[[paste0("add5_sold_when_e_",s_)]]!=""), "bagweights any", sum(rowSums(!is.na(as.matrix(r[, paste0("add5_ind_weight",1:20,"_",s_)])))>0), "\n")
print(table(r$add4_random_bag))
print(head(as.data.frame(r[, c("treatment","ea_code","add5_ppk_1","add5_sold_when_e_1","add5_ppk_2","add5_sold_when_e_2","add5_ppk_3","add5_ppk_4")]), 30))
