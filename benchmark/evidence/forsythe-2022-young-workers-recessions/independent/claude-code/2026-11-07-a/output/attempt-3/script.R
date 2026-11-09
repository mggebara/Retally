suppressMessages(library(data.table))
t0 <- proc.time()[["elapsed"]]
el <- function() round(proc.time()[["elapsed"]] - t0, 1)
P <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-07-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/"
f <- paste0(P, "yh_data.csv")
icols <- c("hryear","peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow")
d <- fread(f, select = c(icols, "pwsswgt", "v2pwsswgt"), colClasses = list(integer = icols, numeric = c("pwsswgt","v2pwsswgt")), nThread = 1, showProgress = FALSE)
message("full read: ", el(), " rows ", nrow(d))
d[, yr := fifelse(hryear < 100L, hryear + 1900L, hryear)]
print(d[, .(n = .N, nast = sum(is.na(v2gestfips)), nah1 = sum(is.na(prhspnon)), nah2 = sum(is.na(pehspnon)), age15 = sum(peage < 16), lf = sum(pemlr < 1 | v2pemlr < 1)), by = yr][order(yr)])
print(table(is.na(d$v2gestfips), d$v2pemlr))
print(d[is.na(v2gestfips)][1:5])
cat("N age>=16 & pemlr>0 both:", d[peage >= 16 & pemlr > 0 & v2pemlr > 0, .N], "\n")
cat("N + state nonmissing:", d[peage >= 16 & pemlr > 0 & v2pemlr > 0 & !is.na(v2gestfips), .N], "\n")
cat("1995 May-Aug pairs:", d[yr == 1995 & v2hrmonth %in% 5:9, .N], "\n")
print(table(d[yr == 1995 | v2hryear %in% c(95L, 1995L), v2hrmonth]))
message("done: ", el())
