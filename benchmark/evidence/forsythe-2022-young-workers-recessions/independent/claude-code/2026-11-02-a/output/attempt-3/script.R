suppressPackageStartupMessages({library(data.table); library(fixest)})
setDTthreads(1)
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-02-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/"
t0 <- Sys.time(); el <- function() round(as.numeric(difftime(Sys.time(), t0, units="secs")), 1)
cols <- c("peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
          "v2prernwa","v2pwsswgt","v2prwernal")
x <- fread(paste0(D, "yh_data.csv"), select = cols, nThread = 1, showProgress = FALSE)
cat("read", el(), "rows", nrow(x), "\n")
x[v2hryear < 100L, v2hryear := v2hryear + 1900L]
x[, ym := v2hryear * 12L + v2hrmonth]
edyrs <- c(0, 2.5, 5.5, 7.5, 9, 10, 11, 12, 12, 13, 14, 14, 16, 18, 18, 18)  # peeduca 31..46
ed7m <- c(1L,1L,1L,1L,1L,1L,1L,1L, 2L, 3L,3L,3L, 4L, 5L, 6L, 7L)
x[, pe := peage - edyrs[peeduca - 30L] - 6]
x[, young := pe <= 10]
x[, hisp := fcoalesce(prhspnon, pehspnon) == 1L]
x[, demog := ((pesex - 1L) * 2L + (race != 1L)) * 2L * 7L + hisp * 7L + ed7m[peeduca - 30L]]
x[, status := fifelse(pemlr %in% 1:2, 1L, fifelse(pemlr %in% 3:4, 2L, 3L))]
x[, emp1 := v2pemlr %in% 1:2]
x[, se1 := v2peio1cow %in% 6:7]
x[, hired := 100 * ((status != 1L & emp1 & !se1) | (status == 1L & emp1 & v2puiodp1 == 2L & !se1))]
x[, w := (pwsswgt + v2pwsswgt) / 2]
cat("derived", el(), "\n"); print(gc())
cat("state NA by year\n"); print(x[, .(n = .N, na = sum(is.na(v2gestfips))), by = v2hryear][order(v2hryear)])
cat("state NA by month in 2013\n"); print(x[v2hryear == 2013, .(n = .N, na = sum(is.na(v2gestfips))), by = v2hrmonth][order(v2hrmonth)])
cat("ages\n"); print(table(x$peage))
cat("age among state NA\n"); print(summary(x[is.na(v2gestfips), peage]))
cat("pemlr among state NA\n"); print(table(x[is.na(v2gestfips), pemlr]))
cnt <- function(lbl, cond) cat(sprintf("%-40s %d\n", lbl, sum(cond)))
st <- !is.na(x$v2gestfips)
cnt("state ok", st)
for (a in 15:17) cnt(paste("state ok & age>=", a), st & x$peage >= a)
for (u in c(64, 65, 70, 75, 79, 80, 85)) cnt(paste("state ok & 16<=age<=", u), st & x$peage >= 16 & x$peage <= u)
for (u in c(64, 65, 70, 75, 79, 80, 85)) cnt(paste("all & 16<=age<=", u), x$peage >= 16 & x$peage <= u)
desc <- function(s, lbl) {
  cat("--", lbl, "N", nrow(s), "\n")
  print(s[, .(young = weighted.mean(young, w), pe = weighted.mean(pe, w), age = weighted.mean(peage, w),
              educ = weighted.mean(edyrs[peeduca - 30L], w), female = weighted.mean(pesex == 2L, w),
              nonwhite = weighted.mean(race != 1L, w), hisp = weighted.mean(hisp, w, na.rm = TRUE),
              part = weighted.mean(status != 3L, w), emp = weighted.mean(status == 1L, w),
              hire = weighted.mean(hired, w))])
  print(s[, .(hire = weighted.mean(hired, w), .N), by = status][order(status)])
  print(s[, .(young = mean(young), pe = mean(pe), age = mean(peage), hire = mean(hired))])
}
desc(x[st & peage >= 16], "state ok age>=16")
desc(x[st & peage >= 16 & peage <= 64], "state ok 16-64")
desc(x[peage >= 16], "all age>=16")
cat("hisp NA count", sum(is.na(x$hisp)), "\n")
cat("cow among nonemp->emp\n"); print(table(x[status != 1L & emp1, v2peio1cow]))
cat("puiodp1 among emp->emp\n"); print(table(x[status == 1L & emp1, v2puiodp1]))
# collapse timing
s <- x[st & peage >= 16]
cells <- s[, .(y = sum(hired * w) / sum(w), sw = sum(w), n = .N), by = .(v2gestfips, ym, demog, young, status)]
cat("cells", nrow(cells), "elapsed", el(), "\n")
m <- feols(y ~ young | v2gestfips + demog + ym, data = cells, weights = ~sw, notes = FALSE)
cat("feols timing done", el(), "\n")
wg <- s[hired > 0 & !is.na(v2prernwa)]
cat("hires w/ wage", nrow(wg), "\n"); print(table(wg$v2prwernal, useNA = "ifany"))
cat("hires w/ wage>0 & alloc==0", wg[v2prernwa > 0 & v2prwernal %in% 0L, .N], "\n")
print(wg[, .(n = .N, flagNA = sum(is.na(v2prwernal)), alloc1 = sum(v2prwernal %in% 1L), alloc0 = sum(v2prwernal %in% 0L)), by = v2hryear][order(v2hryear)])
cat("wage hires by status (alloc0)\n"); print(wg[v2prernwa > 0 & v2prwernal %in% 0L, .N, by = status])
cat("icd/ocd range among wage hires\n"); print(summary(wg$v2peio1icd)); print(summary(wg$v2peio1ocd))
cat("done", el(), "\n")
