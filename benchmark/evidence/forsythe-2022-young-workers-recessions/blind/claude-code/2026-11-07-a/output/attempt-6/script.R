# Exploratory: raw sequential read throughput of yh_data.csv (no parsing, no estimates, no RESULT lines).
f <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/blind/2026-11-07-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/yh_data.csv"
t0 <- proc.time()[3]
con <- file(f, "rb")
tot <- 0
repeat {
  b <- readBin(con, "raw", 64 * 1024^2)
  if (length(b) == 0) break
  tot <- tot + length(b)
  el <- proc.time()[3] - t0
  cat(sprintf("MB %.0f elapsed %.1f MB/s %.1f\n", tot / 1024^2, el, tot / 1024^2 / el)); flush(stdout())
  if (el > 240) break
}
close(con)
print(proc.time())
