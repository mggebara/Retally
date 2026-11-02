suppressPackageStartupMessages(library(data.table))
setDTthreads(1)
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/independent/2026-11-02-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data/"
t0 <- Sys.time(); el <- function() round(as.numeric(difftime(Sys.time(), t0, units="secs")), 1)
f <- paste0(D, "yh_data.csv")
con <- file(f, "rb")
hdr <- readLines(con, n=1)
allcols <- strsplit(hdr, ",")[[1]]
cols <- c("hrmonth","hryear","peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","pwsswgt",
          "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
          "v2prernwa","v2pwsswgt","v2prwernal")
idx <- match(cols, allcols)
CH <- 64e6
left <- raw(0); out <- list(); k <- 0; tread <- 0; tparse <- 0
repeat {
  ta <- Sys.time()
  buf <- readBin(con, "raw", n=CH)
  tread <- tread + as.numeric(difftime(Sys.time(), ta, units="secs"))
  eof <- length(buf) == 0
  if (eof && length(left) == 0) break
  buf <- c(left, buf)
  n <- length(buf)
  if (eof) {
    cut <- n
  } else {
    lo <- max(1, n - 20000)
    nl <- which(buf[lo:n] == as.raw(10))
    if (length(nl) == 0) stop("no newline")
    cut <- lo - 1 + max(nl)
  }
  left <- if (cut < n) buf[(cut+1):n] else raw(0)
  tb <- Sys.time()
  x <- fread(text = rawToChar(buf[1:cut]), header = FALSE, select = idx, col.names = cols, showProgress = FALSE, nThread = 1)
  rm(buf)
  k <- k + 1
  out[[k]] <- x
  tparse <- tparse + as.numeric(difftime(Sys.time(), tb, units="secs"))
  if (k %% 5 == 0) cat("chunk", k, "elapsed", el(), "read", round(tread,1), "parse", round(tparse,1), "\n")
}
close(con)
cat("chunks", k, "elapsed", el(), "read", round(tread,1), "parse", round(tparse,1), "\n")
x <- rbindlist(out, use.names = TRUE, fill = TRUE); rm(out); invisible(gc())
cat("rows", nrow(x), "elapsed", el(), "\n"); print(gc())
x[hryear < 100, hryear := hryear + 1900L]; x[v2hryear < 100, v2hryear := v2hryear + 1900L]
x[, gap := (v2hryear*12L + v2hrmonth) - (hryear*12L + hrmonth)]
print(table(gap = x$gap, stNA = is.na(x$v2gestfips)))
cat("state NA by year\n"); print(x[, .(n=.N, na=sum(is.na(v2gestfips))), by=v2hryear][order(v2hryear)])
cat("age<16 ", sum(x$peage < 16), " age<16&stNA ", sum(x$peage < 16 & is.na(x$v2gestfips)), "\n")
cat("N age>=16 & state ok & gap1: ", sum(x$peage >= 16 & !is.na(x$v2gestfips) & x$gap == 1), "\n")
cat("N state ok & gap1: ", sum(!is.na(x$v2gestfips) & x$gap == 1), "\n")
cat("N state ok: ", sum(!is.na(x$v2gestfips)), "\n")
cat("N age>=16: ", sum(x$peage >= 16), "\n")
cat("N age>=16 & state ok: ", sum(x$peage >= 16 & !is.na(x$v2gestfips)), "\n")
cat("N age 16-64 & state ok: ", sum(x$peage >= 16 & x$peage <= 64 & !is.na(x$v2gestfips)), "\n")
print(table(x$peage[x$peage < 18]))
# hires
x[, emp0 := pemlr %in% 1:2][, emp1 := v2pemlr %in% 1:2]
x[, se1 := v2peio1cow %in% 6:7]
x[, hired := 100 * ((!emp0 & emp1 & !se1) | (emp0 & emp1 & v2puiodp1 == 2L & !se1))]
x[, w := (pwsswgt + v2pwsswgt) / 2]
s <- x[peage >= 16 & !is.na(v2gestfips)]
cat("hire rate all", s[, weighted.mean(hired, w)], "\n")
cat("hire rate emp", s[emp0==TRUE, weighted.mean(hired, w)], "\n")
cat("hire rate unemp", s[pemlr %in% 3:4, weighted.mean(hired, w)], "\n")
cat("hire rate nilf", s[pemlr %in% 5:7, weighted.mean(hired, w)], "\n")
cat("N emp", s[emp0==TRUE, .N], " unemp ", s[pemlr %in% 3:4, .N], " nilf ", s[pemlr %in% 5:7, .N], "\n")
cat("cow among new emp from nonemp\n"); print(table(s[!emp0 & emp1, v2peio1cow]))
cat("puiodp1 among emp-emp\n"); print(table(s[emp0 & emp1, v2puiodp1]))
cat("v2puiodp1==2 & cow8 ", s[emp0 & emp1 & v2puiodp1==2L & v2peio1cow==8L, .N], "\n")
# wage sample
cat("hires with wage nonNA", s[hired > 0 & !is.na(v2prernwa), .N], "\n")
print(s[hired > 0 & !is.na(v2prernwa), table(v2prwernal, useNA="ifany")])
cat("hires wage >0 notalloc", s[hired > 0 & !is.na(v2prernwa) & v2prernwa > 0 & v2prwernal %in% 0L, .N], "\n")
cat("hires wage >0 alloc0 or NA", s[hired > 0 & !is.na(v2prernwa) & v2prernwa > 0 & (v2prwernal %in% 0L | is.na(v2prwernal)), .N], "\n")
cat("wage NA-flag by year\n"); print(s[!is.na(v2prernwa), .(n=.N, flagNA=sum(is.na(v2prwernal)), alloc=sum(v2prwernal %in% 1L)), by=v2hryear][order(v2hryear)])
cat("all wage obs notalloc >0", s[!is.na(v2prernwa) & v2prernwa>0 & v2prwernal %in% 0L, .N], "\n")
cat("elapsed", el(), "\n")
