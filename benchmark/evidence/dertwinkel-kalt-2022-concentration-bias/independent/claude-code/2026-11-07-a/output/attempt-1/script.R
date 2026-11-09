suppressMessages(library(dplyr))
f <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/independent/2026-11-07-a/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read.csv(f, stringsAsFactors=FALSE)
str(d[, c(1:3,10:31,52,53)])
print(table(d$treatment, d$dispersed, useNA="a"))
print(with(d, table(pizza, control, main, useNA="a")))
print(table(d$decision_number, d$utility_point, useNA="a"))
print(table(d$pap_sample, d$decision_number, useNA="a"))
print(table(d$corner, d$chose_corner, useNA="a"))
s <- d[d$decision_number==9,]
print(nrow(s)); print(summary(s[,c("indifference_point","id_stage2","id_stage2_upper","avg_id_stage2","qe_ard","qe_ard_lower","qe_ard_upper","qe_rad","qe_rad_lower","qe_rad_upper","cb_effect","id_stage2_sign")]))
print(head(d[d$tn %in% unique(d$tn)[1:3], c("tn","decision_number","utility_point","corner","chose_corner","indifference_point","id_stage2","id_stage2_upper","pap_sample","qe_ard","qe_rad","average_ip")], 30))
print(with(d[d$decision_number==1,], table(pizza,control,main,pap_sample)))
