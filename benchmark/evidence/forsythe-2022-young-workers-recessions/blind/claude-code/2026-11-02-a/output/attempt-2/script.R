suppressMessages(library(data.table))
setDTthreads(1)
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/blind/2026-11-02-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data"
f <- file.path(D,"yh_data.csv")
t0 <- Sys.time()
con <- file(f, "rb"); n <- 0
repeat { b <- readBin(con, "raw", 2^27); if (!length(b)) break; n <- n + length(b) }
close(con)
cat("raw read bytes", n, "secs", as.numeric(difftime(Sys.time(),t0,units="secs")), "\n")
t0 <- Sys.time()
x <- fread(f, select=c("peage","v2pemlr"), showProgress=FALSE)
cat("fread 2 cols secs", as.numeric(difftime(Sys.time(),t0,units="secs")), "\n")
print(table(x$peage < 16)); print(table(x$peage[x$peage < 18]))
print(table(cut(x$peage, c(0,15,64,200))))
