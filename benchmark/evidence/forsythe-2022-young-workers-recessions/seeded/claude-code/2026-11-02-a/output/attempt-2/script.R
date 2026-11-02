suppressMessages(library(data.table))
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/seeded/2026-11-02-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data"
f <- file.path(D,"yh_data.csv")
t0 <- Sys.time()
con <- file(f, "rb"); tot <- 0
repeat { b <- readBin(con, "raw", 64*1024^2); if (length(b)==0) break; tot <- tot + length(b) }
close(con); rm(b)
cat("raw read secs", as.numeric(Sys.time()-t0,units="secs"), "bytes", tot, "\n")
cat("threads", getDTthreads(), "\n")
t0 <- Sys.time()
cc <- list(integer=c("peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr","v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd","v2prwernal"), numeric=c("pwsswgt","v2prernwa","v2pwsswgt"))
dt <- fread(f, select=unlist(cc), colClasses=cc, nThread=1, showProgress=FALSE, verbose=TRUE)
cat("fread secs", as.numeric(Sys.time()-t0,units="secs"), "\n")
