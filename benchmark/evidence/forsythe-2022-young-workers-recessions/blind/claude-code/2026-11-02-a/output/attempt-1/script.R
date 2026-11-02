suppressMessages(library(data.table))
setDTthreads(1)
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/blind/2026-11-02-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data"
t0 <- Sys.time()
cols <- c("hrmonth","hryear","peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2prernwa","v2prwernal","v2pwsswgt")
x <- fread(file.path(D,"yh_data.csv"), select=cols, showProgress=FALSE)
cat("read secs", as.numeric(difftime(Sys.time(),t0,units="secs")), "\n")
cat("rows", nrow(x), "\n"); print(sapply(x, class))
print(object.size(x), units="MB")
for (v in c("hryear","v2hryear","pemlr","v2pemlr","v2puiodp1","v2peio1cow","peeduca","race","prhspnon","pehspnon","pesex","v2prwernal")) {cat("==",v,"\n"); print(table(x[[v]], useNA="ifany"))}
print(summary(x$peage)); print(summary(x$pwsswgt)); print(summary(x$v2pwsswgt)); print(summary(x$v2prernwa))
x[, gap := (v2hryear*12+v2hrmonth) - (hryear*12+hrmonth)]
print(table(x$gap, useNA="ifany"))
print(table(x$hrmonth[x$hryear %in% c(95,1995)]))
print(table(x$v2puiodp1, x$pemlr %in% 1:2, useNA="ifany"))
print(table(x$prhspnon, x$pehspnon, useNA="ifany"))
cat("total secs", as.numeric(difftime(Sys.time(),t0,units="secs")), "\n")
