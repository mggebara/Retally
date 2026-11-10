# Exploratory run 4: find the property universe (no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr); library(readr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
ra <- zap_labels(read_dta(file.path(B, "admin_data/randomization_assignment.dta")))
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta"), col_select = c(a7, compound1, house, today, tmt, who, exempt, tot_complete, double_sensi, a7_compound)))
rg <- merge(rg, ra[, c("a7","treatment")], by = "a7")
d <- rg[rg$house %in% c(1,2), ]
e1 <- zap_labels(read_dta(file.path(B, "survey_data/endline_round1_noPII.dta"), col_select = c(a7, treatment)))
e1 <- merge(e1, ra[, c("a7","treatment")], by = "a7", suffixes = c("", ".ra"))
cat("endline Local but assigned CXL a7:\n"); print(table(e1$a7[e1$treatment %in% 2 & e1$treatment.ra == 4]))
cat("endline CXL but assigned Local a7:\n"); print(table(e1$a7[e1$treatment %in% 4 & e1$treatment.ra == 2]))
for (a in c(639, 654)) { cat("who in", a, ":\n"); print(table(rg$who[rg$a7 == a], useNA="a")) }
cat("who by treatment:\n"); print(table(rg$treatment, rg$who, useNA="a"))

f <- function(name, df) {
  cat("\n=====", name, "rows", nrow(df), "\n"); print(names(df)[1:min(60, ncol(df))])
}
ml <- read_csv(file.path(B, "admin_data/property_values_MLestimates.csv"), show_col_types = FALSE)
f("ML", ml)
cat("ML compound dup:", sum(duplicated(ml$compound1)), "\n")
ml2 <- merge(ml[, c("compound1","a7")], ra[, c("a7","treatment")], by = "a7")
print(table(ml2$treatment))
print(table(ml2$treatment, ml2$compound1 %in% d$compound1))
cat("training:\n"); print(table(ml$training, useNA="a"))
hd <- zap_labels(read_dta(file.path(B, "admin_data/hh_distances.dta")))
f("hh_distances", hd)
fl <- zap_labels(read_dta(file.path(B, "admin_data/fliers_campaign.dta")))
f("fliers", fl)
for (nm in c("compound1","compound","a7")) if (nm %in% names(fl)) cat("fl has", nm, "\n")
if ("compound1" %in% names(fl)) {
  fl2 <- merge(fl[, c("compound1"), drop=FALSE] %>% mutate(a7 = compound1 %/% 1000), ra[, c("a7","treatment")], by = "a7")
  cat("fliers by trt:\n"); print(table(fl2$treatment)); cat("dup:", sum(duplicated(fl$compound1)), "\n")
  print(table(fl2$treatment, fl2$compound1 %in% d$compound1))
}
if ("compound1" %in% names(hd)) {
  hd2 <- merge(hd[, "compound1", drop=FALSE] %>% mutate(a7 = compound1 %/% 1000), ra[, c("a7","treatment")], by = "a7")
  cat("hh_distances by trt:\n"); print(table(hd2$treatment)); cat("dup:", sum(duplicated(hd$compound1)), "\n")
}
cc <- read_dta(file.path(B, "admin_data/campaign_collector_info.dta")); f("campaign_collector_info", cc)
