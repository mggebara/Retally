suppressMessages(library(dplyr)); library(readr)
d <- read_csv("<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/independent/2026-11-02-c/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv", show_col_types=FALSE, guess_max=10000)
e <- c(129,132,143,115,121,117,135,127)
bal <- d %>% filter(decision_number <= 8)
# is utility_point a permutation of 1..8 within subject?
chk <- bal %>% group_by(tn) %>% summarise(perm = all(sort(utility_point)==1:8), anycorner = any(corner != 0), nc = sum(corner!=0))
print(table(chk$perm)); print(table(chk$anycorner))
s <- d %>% filter(decision_number==9) %>% left_join(chk, by="tn")
print(table(s$anycorner, s$pap_sample, useNA="ifany"))
cat("corner in final by id_stage2 values\n")
print(as.data.frame(s %>% filter(corner != 0) %>% select(tn, treatment, control, corner, utility_point, indifference_point, id_stage2, id_stage2_upper, avg_id_stage2, pap_sample) %>% head(40)))
print(table(s$id_stage2[s$corner==0] >= 62))
print(range(s$id_stage2[s$corner==0], na.rm=TRUE))
print(summary(s$indifference_point - s$id_stage2))
# compare own relative measure with qe_*
w <- bal %>% mutate(et = e[utility_point]) %>% select(tn, utility_point, et, x = indifference_point)
s2 <- s %>% filter(!is.na(id_stage2)) %>% rowwise() %>% mutate(
  r8 = { ww <- w[w$tn==tn,]; mean(id_stage2/(ww$et+ww$x)) },
  r8b = { ww <- w[w$tn==tn,]; id_stage2/mean(ww$et+ww$x) },
  r1 = { ww <- w[w$tn==tn & w$utility_point==utility_point,]; id_stage2/(ww$et+ww$x) }) %>% ungroup()
print(as.data.frame(s2 %>% select(tn, treatment, control, utility_point, id_stage2, qe_ard_lower, qe_rad_lower, r8, r8b, r1) %>% group_by(control) %>% slice(1:6)))
cat("max abs diff r8 vs qe_ard_lower:", max(abs(s2$r8 - s2$qe_ard_lower)), " r8b vs qe_rad_lower:", max(abs(s2$r8b - s2$qe_rad_lower)), "\n")
print(tapply(abs(s2$r8 - s2$qe_ard_lower), s2$control, max)); print(tapply(abs(s2$r1 - s2$qe_ard_lower), s2$control, max))
