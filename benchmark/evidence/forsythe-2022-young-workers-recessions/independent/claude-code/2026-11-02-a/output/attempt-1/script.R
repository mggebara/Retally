suppressPackageStartupMessages(library(data.table))
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-02-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/"
t0 <- Sys.time()
cols <- c("hrmonth","hryear","peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
          "v2prernwa","v2pwsswgt","v2prwernal")
x <- fread(paste0(D,"yh_data.csv"), select=cols, nThread=1, showProgress=FALSE)
cat("read secs", as.numeric(difftime(Sys.time(),t0,units="secs")), "\n")
print(dim(x)); print(gc())
print(sapply(x, class))
for (v in c("hryear","peeduca","race","prhspnon","pehspnon","pemlr","v2pemlr","v2puiodp1","v2peio1cow","v2prwernal","pesex"))
  { cat("==",v,"\n"); print(table(x[[v]], useNA="ifany")) }
cat("age\n"); print(summary(x$peage)); print(table(x$peage < 16))
x[, gap := (v2hryear*12+v2hrmonth) - (hryear*12+hrmonth)]
print(table(x$gap, useNA="ifany"))
print(table(x$v2gestfips, useNA="ifany"))
cat("1995 by month\n"); print(x[hryear==95, .N, by=hrmonth][order(hrmonth)])
print(x[, .N, by=.(hryear)][order(hryear)])
cat("wage nonmiss", sum(!is.na(x$v2prernwa)), "\n"); print(summary(x$v2prernwa))
print(table(x$v2prwernal, is.na(x$v2prernwa), useNA="ifany"))
print(summary(x$pwsswgt)); print(summary(x$v2pwsswgt))
cat("total secs", as.numeric(difftime(Sys.time(),t0,units="secs")), "\n")
