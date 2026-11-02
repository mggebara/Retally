suppressMessages(library(data.table))
t0 <- Sys.time()
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-02-b/mount/forsythe_2022_young_workers_recessions/3 replication package/Data"
cols <- c("hrmonth","hryear","peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
          "v2prernwa","v2pwsswgt","v2prwernal")
x <- fread(file.path(D,"yh_data.csv"), select=cols, showProgress=FALSE)
cat("read secs", as.numeric(Sys.time()-t0, units="secs"), "rows", nrow(x), "\n")
print(sapply(x, class))
tb <- function(v) print(table(x[[v]], useNA="ifany"))
for (v in c("hryear","v2hryear","pemlr","v2pemlr","v2puiodp1","v2peio1cow","race","prhspnon","pehspnon","pesex","peeduca","v2prwernal")) {cat("==",v,"\n"); tb(v)}
cat("missing state", sum(is.na(x$v2gestfips)), "\n")
print(summary(x$peage)); print(summary(x$pwsswgt)); print(summary(x$v2pwsswgt)); print(summary(x$v2prernwa))
x[, yr := ifelse(hryear < 100, 1900 + hryear + ifelse(hryear<50,100,0), hryear)]
x[, v2yr := ifelse(v2hryear < 100, 1900 + v2hryear + ifelse(v2hryear<50,100,0), v2hryear)]
x[, gap := (v2yr*12+v2hrmonth) - (yr*12+hrmonth)]
print(table(x$gap, useNA="ifany"))
print(x[, .N, by=.(v2yr)][order(v2yr)])
cat("N pemlr>=1 & age nonmiss & educ>0 & state nonmiss & v2 <=2014m5:",
    x[pemlr>=1 & !is.na(peage) & peeduca>0 & !is.na(v2gestfips) & (v2yr*12+v2hrmonth) <= 2014*12+5, .N], "\n")
cat("same with v2pemlr>=1:", x[pemlr>=1 & v2pemlr>=1 & !is.na(peage) & peeduca>0 & !is.na(v2gestfips) & (v2yr*12+v2hrmonth) <= 2014*12+5, .N], "\n")
cat("state nonmiss by v2yr:\n"); print(x[!is.na(v2gestfips), .N, by=v2yr][order(v2yr)])
cat("age>=16 ", x[peage>=16, .N], " age<16 ", x[peage<16, .N], "\n")
print(table(x$pemlr, x$v2puiodp1, useNA="ifany"))
cat("wage nonmiss by v2 month:\n"); print(x[!is.na(v2prernwa), .N, by=v2hrmonth][order(v2hrmonth)])
cat("total secs", as.numeric(Sys.time()-t0, units="secs"), "\n")
