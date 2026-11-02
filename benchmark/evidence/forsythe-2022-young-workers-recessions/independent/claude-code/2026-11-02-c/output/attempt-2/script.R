# Exploratory run 2: sample counts under candidate restrictions (no estimates of listed quantities)
suppressMessages(library(data.table))
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-02-c/mount/forsythe_2022_young_workers_recessions/3 replication package/Data"
cols <- c("hrmonth","peage","peeduca","pemlr","pwsswgt","v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2pwsswgt","v2prernwa","v2prwernal","v2prernhly","v2prhernal")
x <- fread(file.path(D,"yh_data.csv"), select=cols, showProgress=FALSE)
x[, yr := ifelse(v2hryear < 100, v2hryear + 1900L, v2hryear)]
u <- fread(file.path(D,"v2unemp_smy.csv"))
setnames(u, c("v2gestfips","urate","yr","v2hrmonth"))
x[u, urate := i.urate, on=c("v2gestfips","yr","v2hrmonth")]
cat("rows", nrow(x), " with urate", sum(!is.na(x$urate)), "\n")
x <- x[!is.na(urate)]
print(table(x$peage))
for (a in c(15,16,17)) for (amax in c(99, 85, 80, 79, 75, 70, 65, 64)) cat("age>=",a," age<=",amax, sum(x$peage>=a & x$peage<=amax), "\n")
# education years mapping candidates
m1 <- c(`31`=0,`32`=2.5,`33`=5.5,`34`=7.5,`35`=9,`36`=10,`37`=11,`38`=12,`39`=12,`40`=13,`41`=14,`42`=14,`43`=16,`44`=18,`45`=20,`46`=20)
m2 <- c(`31`=0,`32`=4,`33`=6,`34`=8,`35`=9,`36`=10,`37`=11,`38`=12,`39`=12,`40`=13,`41`=14,`42`=14,`43`=16,`44`=18,`45`=19,`46`=21)
m3 <- c(`31`=0,`32`=1,`33`=5,`34`=7,`35`=9,`36`=10,`37`=11,`38`=11,`39`=12,`40`=12,`41`=14,`42`=14,`43`=16,`44`=17,`45`=18,`46`=18)
y <- x[peage>=16]
for (m in list(m1,m2,m3)) {
  ed <- m[as.character(y$peeduca)]; pe <- y$peage - ed - 6
  cat("educ mean", mean(ed), " pe mean", mean(pe), " young share", mean(pe<=10), " pe young", mean(pe[pe<=10]), " pe old", mean(pe[pe>10]), " age young", mean(y$peage[pe<=10]), "\n")
}
emp1 <- y$pemlr %in% 1:2; emp2 <- y$v2pemlr %in% 1:2
se <- y$v2peio1cow %in% 6:7
cat("emp t-1", sum(emp1), " unemp", sum(y$pemlr %in% 3:4), " nilf", sum(y$pemlr %in% 5:7), "\n")
cat("LFPR", mean(y$pemlr %in% 1:4), " EPOP", mean(emp1), "\n")
h1 <- emp2 & !emp1 & !se
h2 <- emp2 & emp1 & y$v2puiodp1==2 & !se
h2b <- emp2 & emp1 & y$v2puiodp1==2
w <- (y$pwsswgt + y$v2pwsswgt)/2
cat("hire rate unw", mean(h1|h2), " w", weighted.mean(h1|h2, w), "\n")
cat("from emp", weighted.mean(h2[emp1], w[emp1]), mean(h2[emp1]), " incl SE", weighted.mean(h2b[emp1], w[emp1]), "\n")
cat("from U", weighted.mean(h1[y$pemlr %in% 3:4], w[y$pemlr %in% 3:4]), " from NILF", weighted.mean(h1[y$pemlr %in% 5:7], w[y$pemlr %in% 5:7]), "\n")
cat("wage obs nonmiss", sum(!is.na(y$v2prernwa)), " nonalloc", sum(!is.na(y$v2prernwa) & y$v2prwernal %in% c(-1,0)), " >0", sum(!is.na(y$v2prernwa) & y$v2prernwa>0), "\n")
print(table(y$v2prwernal[!is.na(y$v2prernwa)], useNA="ifany"))
cat("hires with wage", sum((h1|h2) & !is.na(y$v2prernwa) & y$v2prernwa>0), " nonalloc0", sum((h1|h2) & !is.na(y$v2prernwa) & y$v2prernwa>0 & y$v2prwernal==0), " nonalloc-1or0", sum((h1|h2) & !is.na(y$v2prernwa) & y$v2prernwa>0 & y$v2prwernal %in% c(-1,0)), "\n")
print(table(y$v2prhernal[!is.na(y$v2prernwa)], y$v2prwernal[!is.na(y$v2prernwa)], useNA="ifany"))
print(table(y$v2pemlr[!is.na(y$v2prernwa)]))
