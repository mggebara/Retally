suppressMessages({library(haven); library(dplyr); library(readxl)})
M <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading/"
D <- paste0(M, "data/raw/")
options(width=250)
s <- as.data.frame(read_excel(paste0(M, "survey_materials/main_survey/survey_instrument_main.xlsx"), sheet=1))
lab <- s[[grep("^label", names(s))[1]]]
keep <- grepl("chem|transport|labor_cost|labour|otherph|drying_cost|storage_cost|equipment|harvest_cost|booster|fert_cost|seeds_cost|manure_cost|decob|winnow|sort|bag_|tot_lab_costs|lc_tot|kgs_measure|harvest_kg|sold_kg|tot_rev", s$name)
for (i in which(keep)) cat(i, "|", s$type[i], "|", s$name[i], "|", substr(gsub("\n"," ",lab[i]),1,130), "|", substr(s$calculation[i],1,300), "\n")
g1 <- read_dta(paste0(D,"panel_g1.dta"))
f <- g1 %>% filter(survey_season>=5)
for (a in c("prep","plant","weed","spray","harv")) {
  u <- f[[paste0("lc_",a,"_unit1")]]; cst <- f[[paste0("lc_",a,"_costs_unit1")]]
  cat(a, "hired cost per hour (unit hours): "); print(summary(cst[u=="hours"]))
  cat(a, "hired cost per day: "); print(summary(cst[u=="days"]))
  hu <- f[[paste0("lh_",a,"_unit1")]]; hh <- f[[paste0("lh_",a,"_hours_unit1")]]
  cat(a, "family hours per day: "); print(summary(hh[hu=="days"]))
}
cat("harvest_kg vs sum plots\n"); hp <- rowSums(as.matrix(g1[,paste0("harvest_kg_",1:6)]), na.rm=TRUE); print(summary(g1$harvest_kg - hp))
print(tapply(is.na(g1$harvest_kg) & hp>0, g1$survey_season, sum))
sd <- read_dta(paste0(D,"seller_data.dta"))
x <- sd %>% group_by(hhh_id, survey_season) %>% summarise(n=n(), kg=sum(sold_kg_p_), tot=first(sold_kg_tot), .groups="drop")
print(summary(x$kg - x$tot)); print(table(x$survey_season))
m <- merge(g1[,c("hhh_id","survey_season","sold_kg_p_1","harvest_kg","buy_treatment")], x, all.x=TRUE)
print(tapply(!is.na(m$n), m$survey_season, sum))
print(tapply(!is.na(m$sold_kg_p_1) & is.na(m$n), m$survey_season, sum))
print(tapply(sd$price, list(sd$survey_season, sd$buy_treatment), median))
