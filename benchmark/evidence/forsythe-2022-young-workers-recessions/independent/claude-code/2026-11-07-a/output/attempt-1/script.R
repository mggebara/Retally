suppressMessages(library(data.table))
t0 <- Sys.time()
P <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-07-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/"
d <- fread(paste0(P,"yh_data.csv"), select=c("hrmonth","hryear","peage","peeduca","race","prhspnon","pehspnon","pemlr","v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2prwernal","v2prernwa"), nThread=1)
cat("read secs", as.numeric(Sys.time()-t0,units="secs"), "nrow", nrow(d), "\n")
print(sapply(d, function(x) sum(is.na(x))))
d[, yr := ifelse(hryear<100, hryear+1900, hryear)]
print(d[, .(n=.N, nastate=sum(is.na(v2gestfips)), nahisp1=sum(is.na(prhspnon)), nahisp2=sum(is.na(pehspnon))), by=yr][order(yr)])
print(table(d$v2hryear)[1:5])
for (v in c("pemlr","v2pemlr","race","peeduca","prhspnon","pehspnon","v2puiodp1","v2peio1cow","v2prwernal")) {cat(v,"\n"); print(table(d[[v]], useNA="ifany"))}
d[, cons := ((v2hrmonth - hrmonth) %% 12)==1]
print(table(d$cons)); print(summary(d$peage))
print(table(d[yr==1995, hrmonth]))
print(summary(d$v2prernwa))
print(table(d$pemlr, d$v2pemlr))
cat("total secs", as.numeric(Sys.time()-t0,units="secs"),"\n")
