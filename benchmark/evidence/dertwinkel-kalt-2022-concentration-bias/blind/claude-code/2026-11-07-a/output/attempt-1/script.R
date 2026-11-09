suppressMessages(library(tidyverse))
f <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/blind/2026-11-07-a/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read_csv(f, show_col_types=FALSE)
print(dim(d)); options(width=200)
print(table(d$decision_number, useNA="a"))
print(d %>% count(dispersed, pizza, control, main, treatment))
for (v in c("utility_point","corner","chose_corner","pap_sample","id_stage2_sign","cb_effect")) {cat(v,"\n"); print(table(d[[v]], useNA="a"))}
print(summary(d %>% select(indifference_point, id_stage2_upper, id_stage2, avg_id_stage2, qe_ard, qe_ard_lower, qe_ard_upper, qe_rad, qe_rad_lower, qe_rad_upper, average_ip)))
print(as.data.frame(d %>% filter(tn %in% unique(tn)[1:3])  %>% select(tn,treatment,decision_number,utility_point,corner,chose_corner,indifference_point,id_stage2_upper,pap_sample,id_stage2,avg_id_stage2,qe_ard,qe_ard_lower,qe_ard_upper,qe_rad,qe_rad_lower,id_stage2_sign,cb_effect)))
print(as.data.frame(d %>% filter(!is.na(id_stage2_upper)) %>% select(tn,treatment,decision_number,utility_point,corner,chose_corner,indifference_point,id_stage2_upper,id_stage2,qe_ard,qe_ard_lower,qe_ard_upper) %>% head(30)))
print(d %>% group_by(tn) %>% summarise(n=n()) %>% count(n))
