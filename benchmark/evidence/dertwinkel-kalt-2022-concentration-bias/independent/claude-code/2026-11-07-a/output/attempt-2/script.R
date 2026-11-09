suppressMessages(library(dplyr))
f <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/independent/2026-11-07-a/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read.csv(f, stringsAsFactors=FALSE)
e <- c(129,132,143,115,121,117,135,127)
d$cond <- with(d, ifelse(pizza==0, "Don", ifelse(main==1,"Main","Mech")))
s9 <- d[d$decision_number==9,]
print(table(s9$cond, s9$control, s9$pap_sample, useNA="a"))
print(table(s9$cond, s9$treatment, useNA="a"))
b <- d[d$decision_number<=8,]
bc <- b %>% group_by(tn) %>% summarise(anycorner=any(corner!=0), nc=sum(corner!=0), mx=max(indifference_point), mn=min(indifference_point))
s9 <- left_join(s9, bc, by="tn")
print(table(s9$anycorner, s9$pap_sample, useNA="a"))
print(table(s9$corner, s9$cond, useNA="a"))
print(s9[s9$corner!=0 & s9$pap_sample %in% 1, c("tn","cond","control","corner","indifference_point","id_stage2","id_stage2_upper","avg_id_stage2")][1:40,])
print(s9[is.na(s9$pap_sample), c("tn","cond","control","corner","indifference_point","anycorner")][1:10,])
# balanced ips by utility point
w <- b %>% mutate(den=e[utility_point]+indifference_point) %>% group_by(tn) %>% summarise(sinv=mean(1/den), mden=mean(den))
s9 <- left_join(s9, w, by="tn")
s9$rad_mid <- s9$avg_id_stage2*s9$sinv
s9$ard_mid <- s9$avg_id_stage2/s9$mden
print(summary(s9$rad_mid - s9$qe_rad)); print(summary(s9$ard_mid - s9$qe_ard))
print(summary(s9$id_stage2*s9$sinv - s9$qe_rad_lower))
# control: x of repeated tradeoff
xj <- b %>% select(tn, utility_point, xj=indifference_point)
s9 <- left_join(s9, xj, by=c("tn","utility_point"))
s9$ctrl_rel <- s9$avg_id_stage2/(e[s9$utility_point]+s9$xj)
cc <- s9[s9$control==1 & s9$pap_sample %in% 1,]
print(summary(cc$ctrl_rel - cc$qe_rad))
print(summary(cc$avg_id_stage2 - cc$indifference_point))
print(s9 %>% filter(pap_sample==1) %>% group_by(cond,control) %>% summarise(n=n(), rad=mean(qe_rad), rad_l=mean(qe_rad_lower), rad_u=mean(qe_rad_upper), ard=mean(qe_ard), dmid=mean(avg_id_stage2), dl=mean(id_stage2), du=mean(id_stage2_upper), mine=mean(rad_mid)))
