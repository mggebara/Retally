# Exploratory run: inspect variable coding; prints no estimates.
suppressPackageStartupMessages(library(data.table))
t0 <- Sys.time()
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/blind/2026-11-02-c/mount/forsythe_2022_young_workers_recessions/3 replication package/Data"
u <- fread(file.path(D, "v2unemp_smy.csv"))
cat("unemp rows", nrow(u), "\n"); print(range(u$v2hryear)); print(table(u$v2gestfips)[1:5]); print(u[, .N, by = v2hryear])
cpi <- fread(file.path(D, "wage_deflation_1994_2016.csv")); print(summary(cpi$cpi))
cols <- c("hrmonth","hryear","peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
          "v2prernwa","v2prwernal","v2pwsswgt")
x <- fread(file.path(D, "yh_data.csv"), select = cols, showProgress = FALSE)
cat("read secs", as.numeric(difftime(Sys.time(), t0, units = "secs")), "\n")
cat("nrow", nrow(x), "\n")
print(x[, .N, by = .(hryear)][order(hryear)])
print(x[, .N, by = .(v2hryear)][order(v2hryear)])
x[, yr := fifelse(v2hryear < 100, 1900 + v2hryear, v2hryear)]
print(x[, .(N = .N, miss_state = sum(is.na(v2gestfips))), by = yr][order(yr)])
print(x[yr == 1995, .N, by = v2hrmonth][order(v2hrmonth)])
print(table(consec = (x$hrmonth %% 12) + 1 == x$v2hrmonth, useNA = "ifany"))
for (v in c("pemlr","v2pemlr","v2puiodp1","v2peio1cow","peeduca","race","prhspnon","pehspnon","pesex","v2prwernal")) {
  cat("==", v, "\n"); print(table(x[[v]], useNA = "ifany"))
}
print(summary(x$peage)); print(summary(x$pwsswgt)); print(summary(x$v2pwsswgt))
print(table(x$peage < 16, useNA = "ifany"))
print(summary(x$v2prernwa))
print(x[, .(n_wage = sum(!is.na(v2prernwa) & v2prernwa > 0)), by = yr][order(yr)])
print(table(x$pemlr, x$v2puiodp1, useNA = "ifany"))
print(x[, .(minicd = min(v2peio1icd, na.rm=TRUE), maxicd = max(v2peio1icd, na.rm=TRUE), minocd = min(v2peio1ocd, na.rm=TRUE), maxocd = max(v2peio1ocd, na.rm=TRUE)), by = yr][order(yr)])
print(table(hisp_both_na = is.na(x$prhspnon) & is.na(x$pehspnon)))
cat("total secs", as.numeric(difftime(Sys.time(), t0, units = "secs")), "\n")
