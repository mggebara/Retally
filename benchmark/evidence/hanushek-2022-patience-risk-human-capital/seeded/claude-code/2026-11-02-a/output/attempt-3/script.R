# Exploratory: raw I/O speed and .dta header of the big file (no RESULT lines)
f <- "<repo>/benchmark/.cache/claude-code/hanushek-2022-patience-risk-human-capital/seeded/2026-11-02-a/mount/hanushek_2022_patience_risk_human_capital/Replication/Data/Working/pisa_full_gps_final.dta"
message("size ", file.size(f))
con <- file(f, "rb")
hdr <- readBin(con, "raw", 400000)
close(con)
txt <- rawToChar(hdr[1:300][hdr[1:300] != as.raw(0)])
cat(txt, "\n")
# locate tags
findtag <- function(tag) { p <- grepRaw(tag, hdr, fixed = TRUE); p }
for (tg in c("<map>","<variable_types>","<varnames>","<sortlist>","<formats>","<data>")) cat(tg, findtag(tg), "\n")
t0 <- Sys.time(); con <- file(f, "rb"); tot <- 0
repeat { b <- readBin(con, "raw", 128e6); if (!length(b)) break; tot <- tot + length(b)
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs")); message("read ", round(tot/1e6), "MB in ", round(el,1), "s")
  if (el > 240) break }
close(con)
