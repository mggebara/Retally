# Exploratory run 19: Table 6 outcome/sample variants (N and Central mean only; no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
ra <- zap_labels(read_dta(file.path(B, "admin_data/randomization_assignment.dta")))
ra$trt <- ra$treatment; ra$trt[ra$a7 == 654] <- 2
hd <- zap_labels(read_dta(file.path(B, "admin_data/hh_distances.dta")))
hd <- merge(hd[!is.na(hd$compound1), c("compound1","a7")], ra[, c("a7","trt")], by = "a7")
rg <- zap_labels(read_dta(file.path(B, "admin_data/registration_noPII.dta"), col_select = c(compound1, start, tot_complete)))
rg <- rg[rg$compound1 %in% hd$compound1, ] %>% arrange(compound1, desc(tot_complete), start) %>% filter(!duplicated(compound1))
u <- merge(hd, rg[, c("compound1","start")], by = "compound1"); u$d <- as.Date(u$start)
u <- u[u$trt %in% c(1,2), ]
u$win <- u$d >= as.Date("2018-06-19") & u$d <= as.Date("2018-12-11")
md <- zap_labels(read_dta(file.path(B, "survey_data/midline_noPII.dta"),
  col_select = c(a7, compound, visited, visits, tot_complete, start, treatment, dup_compound, dup_real, short, long_select, pilot, present, first_attempt, exempt, tot_complete_short, tot_complete_long, sample_select)))
md$compound1 <- ifelse(md$compound < 1e5, md$a7 * 1000 + md$compound, md$compound)
cat("midline rows", nrow(md), "\n")
print(table(md$present, md$visited, useNA = "a"))
print(table(md$tot_complete, md$visited, useNA = "a"))
md$tr_a7 <- ra$trt[match(md$a7, ra$a7)]
cat("rows with a7 in C/L:", sum(md$tr_a7 %in% c(1,2)), " visited nonNA:", sum(md$tr_a7 %in% c(1,2) & !is.na(md$visited)), "\n")
cat("rows with compound1 in C/L universe:", sum(md$compound1 %in% u$compound1), " visited nonNA:", sum(md$compound1 %in% u$compound1 & !is.na(md$visited)), "\n")
cat("... in window:", sum(md$compound1 %in% u$compound1[u$win] & !is.na(md$visited)), "\n")
cat("visits nonNA by visited:\n"); print(table(md$visited, !is.na(md$visits), useNA = "a"))
m <- merge(md, u[, c("compound1","trt","win")], by = "compound1")
m <- m[m$win, ]
def <- list(
  post_naNA = ifelse(m$visited %in% 0, 0, ifelse(is.na(m$visits) | m$visits >= 90, NA, as.numeric(m$visits >= 2))),
  post_na0  = ifelse(is.na(m$visited), NA, as.numeric(m$visited %in% c(1,2) & !is.na(m$visits) & m$visits >= 2 & m$visits < 90)),
  post_v1   = ifelse(is.na(m$visited), NA, as.numeric(m$visited %in% 1 & !is.na(m$visits) & m$visits >= 2 & m$visits < 90)),
  any_v1    = ifelse(is.na(m$visited), NA, as.numeric(m$visited == 1)),
  any_v12   = ifelse(is.na(m$visited), NA, as.numeric(m$visited %in% c(1,2))),
  post_ge1  = ifelse(m$visited %in% 0, 0, ifelse(is.na(m$visits) | m$visits >= 90, NA, as.numeric(m$visits >= 1)))
)
for (nm in names(def)) {
  y <- def[[nm]]
  k <- !is.na(y)
  dd <- !duplicated(m$compound1[k])
  cat(sprintf("%-10s N=%d (unique %d) Central mean=%.3f Local mean=%.3f\n", nm, sum(k), sum(dd), mean(y[k & m$trt == 1]), mean(y[k & m$trt == 2])))
}
