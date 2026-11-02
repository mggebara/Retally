suppressMessages(library(data.table))
t0 <- Sys.time()
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-02-b/mount/forsythe_2022_young_workers_recessions/3 replication package/Data"
cols <- c("hrmonth","hryear","peage","peeduca","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow",
          "v2prernwa","v2pwsswgt","v2prwernal")
x <- fread(file.path(D,"yh_data.csv"), select=cols, showProgress=FALSE)
cat("read secs", as.numeric(Sys.time()-t0, units="secs"), "\n")
x[, v2yr := ifelse(v2hryear < 100, 1900L + v2hryear + ifelse(v2hryear<50,100L,0L), v2hryear)]
x[, c("hryear","hrmonth") := NULL]
x <- x[!is.na(v2gestfips) & pemlr >= 1 & peeduca > 0]
cat("base N", nrow(x), "\n")
ed <- c(`31`=0,`32`=2.5,`33`=5.5,`34`=7.5,`35`=9,`36`=10,`37`=11,`38`=12,`39`=12,`40`=13,`41`=14,`42`=14,`43`=16,`44`=18,`45`=20,`46`=20)
x[, educ := ed[as.character(peeduca)]]
x[, pe := peage - educ - 6]
x[, st := fifelse(pemlr<=2, 1L, fifelse(pemlr<=4, 2L, 3L))]
print(table(x$peage[x$peage<20]))
cnt <- function(lab, cond) { s <- x[cond]; cat(sprintf("%-30s N=%d  E=%d U=%d N=%d\n", lab, nrow(s), sum(s$st==1), sum(s$st==2), sum(s$st==3))) }
cnt("all", rep(TRUE,nrow(x)))
cnt("age>=16", x$peage>=16)
cnt("age>=17", x$peage>=17)
cnt("age16-64", x$peage>=16 & x$peage<=64)
cnt("age16-65", x$peage>=16 & x$peage<=65)
cnt("age16-79", x$peage>=16 & x$peage<=79)
cnt("age16-74", x$peage>=16 & x$peage<=74)
cnt("age<=64", x$peage<=64)
cnt("age<=65", x$peage<=65)
cnt("pe>=0", x$pe>=0)
cnt("pe>=0 age<=64", x$pe>=0 & x$peage<=64)
cnt("v2pemlr in1-7 age<=64", x$v2pemlr>=1 & x$peage<=64)
cnt("age 16-70", x$peage>=16 & x$peage<=70)
cnt("age 18-64", x$peage>=18 & x$peage<=64)
cnt("age 16-69", x$peage>=16 & x$peage<=69)
cnt("age 16-75", x$peage>=16 & x$peage<=75)
print(x[, .N, by=.(a=pmin(peage, 99L) %/% 5L * 5L, st)][order(a, st)])
# hires
x[, hired := 100 * as.integer( (pemlr >= 3 & v2pemlr %in% 1:2 & !(v2peio1cow %in% 6:7)) |
                               (pemlr %in% 1:2 & v2pemlr %in% 1:2 & v2puiodp1 == 2 & !(v2peio1cow %in% 6:7)) )]
x[, w := (pwsswgt + v2pwsswgt)/2]
cat("hire rate all", x[, weighted.mean(hired, w)], " young ", x[pe<=10, weighted.mean(hired, w)], " exp ", x[pe>10, weighted.mean(hired, w)], "\n")
cat("hire rate age<=64 young", x[pe<=10 & peage<=64, weighted.mean(hired, w)], " exp ", x[pe>10 & peage<=64, weighted.mean(hired, w)], "\n")
print(x[, .(rate = weighted.mean(hired, w)), by = st])
h <- x[hired > 0]
cat("hires", nrow(h), "\n")
print(table(h$v2prwernal, !is.na(h$v2prernwa) & h$v2prernwa > 0, useNA="ifany"))
print(h[, .(n=.N, nwage=sum(!is.na(v2prernwa) & v2prernwa>0), nna_flag=sum(is.na(v2prwernal))), by=v2yr][order(v2yr)])
cat("wage cand: wage>0 & flag==0:", h[v2prernwa>0 & v2prwernal==0, .N], " flag!=1:", h[v2prernwa>0 & (is.na(v2prwernal) | v2prwernal!=1), .N], "\n")
cat("wage cand age<=64: ", h[v2prernwa>0 & v2prwernal==0 & peage<=64, .N], h[v2prernwa>0 & (is.na(v2prwernal) | v2prwernal!=1) & peage<=64, .N], "\n")
cat("by status flag==0:"); print(h[v2prernwa>0 & v2prwernal==0, .N, by=st])
cat("total secs", as.numeric(Sys.time()-t0, units="secs"), "\n")
