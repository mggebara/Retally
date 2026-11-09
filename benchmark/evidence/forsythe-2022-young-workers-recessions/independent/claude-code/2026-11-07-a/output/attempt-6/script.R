suppressMessages(library(data.table))
setDTthreads(1)
P <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-07-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/"
cols <- c("peage","peeduca","pemlr","pwsswgt","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2pwsswgt","peschft","penlfact")
icols <- setdiff(cols, c("pwsswgt", "v2pwsswgt"))
d <- fread(paste0(P, "yh_data.csv"), select = cols, nThread = 1, showProgress = FALSE,
           colClasses = list(integer = icols, numeric = c("pwsswgt", "v2pwsswgt")))
message("read")
d[, yr := fifelse(v2hryear < 100L, v2hryear + 1900L, v2hryear)]
print(d[, .(n = .N, nast = sum(is.na(v2gestfips))), by = yr][order(yr)])
print(table(miss = is.na(d$v2gestfips), pemlr = d$pemlr))
d <- d[peage >= 16 & peeduca %in% 31:46 & pemlr %in% 1:7 & v2pemlr %in% 1:7 & !is.na(v2gestfips)]
d[, emp1 := pemlr %in% 1:2]
d[, hired := 100 * as.integer(v2pemlr %in% 1:2 & !(v2peio1cow %in% 6:7) & (!emp1 | v2puiodp1 %in% 2L))]
d[, w := (pwsswgt + v2pwsswgt) / 2]
print(d[, .(n = .N, hr = weighted.mean(hired, w)), by = pemlr][order(pemlr)])
d[, ageb := cut(peage, c(15, 16, 17, 19, 24, 64, 69, 74, 79, 80, 84, 85, 89, 90, 99))]
print(d[pemlr >= 5, .N, by = .(ageb, pemlr)][order(ageb, pemlr)])
print(d[pemlr >= 5, .N, by = .(yr, age80p = peage >= 80)][order(yr, age80p)])
print(d[pemlr >= 5, .N, by = .(peschft)])
print(d[pemlr >= 5, .N, by = .(penlfact)][order(penlfact)])
print(d[, .N, by = .(v2pemlr)][order(v2pemlr)])
message("done")
