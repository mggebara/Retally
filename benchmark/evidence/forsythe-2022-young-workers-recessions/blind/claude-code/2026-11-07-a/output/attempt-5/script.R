# Exploratory: time a chunked sequential read (readBin blocks parsed in memory by fread) of yh_data.csv.
# No estimates, no RESULT lines.
suppressPackageStartupMessages(library(data.table))
setDTthreads(1)
f <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/blind/2026-11-07-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/yh_data.csv"
t0 <- proc.time()
cols <- c("hrmonth","peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
          "v2prernwa","v2prwernal","v2pwsswgt")
con <- file(f, "rb")
hdr <- strsplit(readLines(con, n = 1), ",")[[1]]
idx <- match(cols, hdr)
cc <- ifelse(cols %in% c("pwsswgt", "v2pwsswgt", "v2prernwa"), "double", "integer")
cs <- 128 * 1024^2
carry <- raw(0); parts <- list(); k <- 0; tread <- 0; tparse <- 0
repeat {
  a <- proc.time()[3]
  b <- readBin(con, "raw", cs)
  tread <- tread + proc.time()[3] - a
  if (length(b) == 0) break
  b <- c(carry, b)
  n <- length(b); lo <- max(1L, n - 1048575L)
  nl <- lo - 1L + max(which(b[lo:n] == as.raw(10L)))
  carry <- if (nl < n) b[(nl + 1L):n] else raw(0)
  a <- proc.time()[3]
  d <- fread(text = rawToChar(b[1:nl]), header = FALSE, select = idx, colClasses = setNames(cc, paste0("V", idx)),
             nThread = 1, showProgress = FALSE, sep = ",")
  setnames(d, hdr[as.integer(sub("V", "", names(d)))]); setcolorder(d, cols)
  tparse <- tparse + proc.time()[3] - a
  rm(b)
  k <- k + 1; parts[[k]] <- d
}
close(con)
x <- rbindlist(parts); rm(parts); gc()
cat("chunks", k, "rows", nrow(x), "elapsed read", tread, "elapsed parse", tparse, "\n")
print(proc.time() - t0)
print(sapply(x, class))
print(head(x, 2)); print(tail(x, 2))
print(gc())
