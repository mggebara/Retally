suppressPackageStartupMessages(library(data.table))
setDTthreads(1)
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/blind/2026-11-07-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/"
t0 <- proc.time()
cols <- c("hrmonth","hryear","peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
          "v2prernwa","v2prwernal","v2pwsswgt")
x <- fread(paste0(D,"yh_data.csv"), select=cols, nThread=1, showProgress=FALSE)
cat("read cpu", (proc.time()-t0)[1:3], "nrow", nrow(x), "\n")
print(sapply(x, class))
for (v in c("hryear","v2hryear","pemlr","v2pemlr","v2puiodp1","v2peio1cow","race","prhspnon","pehspnon","peeduca","pesex","v2prwernal")) {cat("==",v,"\n"); print(table(x[[v]], useNA="ifany"))}
print(summary(x$peage)); print(summary(x[, .(pwsswgt, v2pwsswgt, v2prernwa)]))
print(table(paste(x$hrmonth, x$v2hrmonth))[1:30])
print(table(x$v2hryear - x$hryear))
print(x[v2hryear %in% c(95,1995), .N, by=.(v2hrmonth)][order(v2hrmonth)])
print(table(x$pemlr, x$v2puiodp1, useNA="ifany"))
print(table(x$v2pemlr, x$v2peio1cow, useNA="ifany"))
print(table(is.na(x$v2gestfips)))
print(x[, .(minicd=min(v2peio1icd), maxicd=max(v2peio1icd), minocd=min(v2peio1ocd), maxocd=max(v2peio1ocd)), by=v2hryear][order(v2hryear)])
print(x[!is.na(v2prernwa), .N, by=.(v2prwernal)])
print(quantile(x$v2prernwa, c(0,.01,.1,.5,.9,.99,1), na.rm=TRUE))
print(table(x$peage < 16))
cat("total cpu", (proc.time()-t0)[1:3], "\n")
