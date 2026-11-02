suppressMessages(library(data.table))
D <- "<repo>/benchmark/.cache/claude-code/forsythe-2022-young-workers-recessions/seeded/2026-11-02-a/mount/forsythe_2022_young_workers_recessions/3 replication package/Data"
f <- file.path(D,"yh_data.csv")
cat("threads", getDTthreads(), "\n")
t0 <- Sys.time()
sel <- c(peage="integer",pesex="integer",peeduca="integer",race="integer",prhspnon="integer",pemlr="integer",pwsswgt="numeric",
         v2hrmonth="integer",v2hryear="integer",v2gestfips="integer",v2pemlr="integer",v2puiodp1="integer",v2peio1cow="integer",
         v2peio1icd="integer",v2peio1ocd="integer",v2prernwa="numeric",v2pwsswgt="numeric",v2prwernal="integer",pehspnon="integer")
dt <- fread(f, select=sel, nThread=3, showProgress=FALSE, verbose=TRUE)
cat("fread secs", as.numeric(Sys.time()-t0,units="secs"), "\n")
print(gc())
