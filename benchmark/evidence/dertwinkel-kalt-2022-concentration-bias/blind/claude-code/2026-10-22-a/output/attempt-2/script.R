suppressMessages(library(tidyverse))
f <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/blind/2026-10-22-a/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read_csv(f, show_col_types=FALSE)
u <- d %>% filter(decision_number==9)
cat("interior id_stage2 range by corner\n"); print(u %>% group_by(corner) %>% summarise(mn=min(id_stage2,na.rm=T), mx=max(id_stage2,na.rm=T), mnip=min(indifference_point), mxip=max(indifference_point), n=n(), nNAid=sum(is.na(id_stage2))))
print(table(u$id_stage2[u$corner==0] %in% c(-63,62,63)))
print(table(u$id_stage2[u$corner==0 & abs(u$id_stage2)>=60]))
b <- d %>% filter(decision_number<=8)
cat("balanced IP range by corner\n"); print(b %>% group_by(corner) %>% summarise(mn=min(indifference_point), mx=max(indifference_point), n=n()))
bc <- b %>% group_by(tn) %>% summarise(anycorner=any(corner!=0), nutil=n_distinct(utility_point))
u <- u %>% left_join(bc, by="tn")
print(table(u$anycorner, u$pap_sample, useNA="a"))
print(table(u$corner, u$pap_sample, useNA="a"))
print(table(bc$nutil))
# check qe_ard construction
e <- c(129,132,143,115,121,117,135,127)
xb <- b %>% select(tn, t=utility_point, x=indifference_point) %>% mutate(et=e[t])
chk <- u %>% select(tn, control, ut=utility_point, idl=id_stage2, idu=id_stage2_upper, idm=avg_id_stage2, qe_ard, qe_ard_lower, qe_ard_upper, qe_rad) %>% left_join(xb, by="tn") %>%
  group_by(tn, control, ut, idl, idu, idm, qe_ard, qe_ard_lower, qe_ard_upper, qe_rad) %>%
  summarise(r8m = mean(idm/(et+x)), r8l=mean(idl/(et+x)), r8u=mean(idu/(et+x)),
            r1m = idm[1]/(et[t==ut[1]][1]+x[t==ut[1]][1]), radm = idm/mean(et+x), .groups="drop") %>% filter(!is.na(qe_ard))
chk <- chk %>% mutate(dev8=abs(r8m-qe_ard), dev1=abs(r1m-qe_ard), devl=abs(r8l-qe_ard_lower), devu=abs(r8u-qe_ard_upper), devrad=abs(radm-qe_rad))
print(chk %>% group_by(control) %>% summarise(max8=max(dev8), max1=max(dev1), maxl=max(devl), maxu=max(devu), maxrad=max(devrad), n=n()))
print(as.data.frame(head(chk %>% filter(control==1),5)))
# avg_id_stage2 vs midpoint
print(summary(u$avg_id_stage2 - (u$id_stage2+u$id_stage2_upper)/2))
print(table(u$chose_corner, useNA="a"))
