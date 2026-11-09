suppressMessages(library(data.table))
t0 <- proc.time()[["elapsed"]]
el <- function() round(proc.time()[["elapsed"]] - t0, 1)
P <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-07-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/"
f <- paste0(P, "yh_data.csv")
message("start ", el(), " cores ", parallel::detectCores())
x <- fread(f, nrows = 1e6, select = c("peage","pemlr","pwsswgt"), nThread = 1, showProgress = FALSE)
message("fread 1e6 rows 3 cols: ", el())
con <- file(f, "rb")
tot <- 0
for (i in 1:40) {
  b <- readBin(con, "raw", n = 64e6)
  if (length(b) == 0) break
  tot <- tot + length(b)
  message("raw read MB ", round(tot / 1e6), " at ", el())
}
close(con)
message("done ", el())
