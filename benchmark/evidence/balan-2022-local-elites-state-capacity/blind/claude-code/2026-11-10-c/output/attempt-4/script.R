suppressMessages({library(haven); library(dplyr)})
R <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/blind/2026-11-10-c/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base/"
B <- paste0(R, "admin_data/")
options(width=200)
ra <- read_dta(paste0(B, "randomization_assignment.dta"))
rs <- read_dta(paste0(B, "randomization_schedule.dta"))
print(as.data.frame(rs %>% filter(treatment==4 | a7 %in% c(639,654,374)) %>% arrange(chef_code)))
reg <- read_dta(paste0(B, "registration_noPII.dta"))
r3 <- reg %>% filter(a7 %in% ra$a7, pilot==0, tot_complete==1) %>% mutate(trt = as.numeric(ra$treatment[match(a7, ra$a7)]))
r3$sdate <- as.Date(r3$start)
cat("today==sdate:", mean(r3$today == r3$sdate, na.rm=TRUE), "\n")
print(table(format(r3$sdate, "%Y")))
nb <- r3 %>% filter(sdate > as.Date("2018-01-01")) %>% group_by(a7, trt) %>%
  summarise(n=n(), d0=min(sdate), dmed=median(sdate), d1=max(sdate), q05=quantile(sdate, .05, type=1), .groups="drop") %>%
  mutate(month = rs$month[match(a7, rs$a7)])
nb2 <- nb %>% filter(trt %in% c(1,2,3)) %>% arrange(trt, d0)
print(as.data.frame(nb2), row.names=FALSE)
tp <- read_dta(paste0(B, "tax_payments_noPII.dta"))
tp$trt <- as.numeric(ra$treatment[match(tp$a7, ra$a7)])
print(table(tp$endOfCollect, tp$trt))
x <- tp %>% group_by(a7) %>% summarise(e=paste(unique(endOfCollect), collapse=";"))
cat("a7 with >1 endOfCollect:", sum(grepl(";", x$e)), "\n")
nb$eoc <- tp$endOfCollect[match(nb$a7, tp$a7)]
print(as.data.frame(nb %>% filter(trt %in% 1:3) %>% group_by(trt, month, eoc) %>% summarise(k=n(), mind0=min(d0), maxd0=max(d0), .groups="drop")))
