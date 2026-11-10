suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/blind/2026-11-10-a/mount/goni_2022_assortative_matching_london_season"
d <- read_dta(file.path(D, "data/final-data.dta"))
d <- zap_labels(d)
chk <- function(s, nm) {
  cat("=====", nm, "n=", nrow(s), " unique refno=", length(unique(s$refno)), "\n")
  for (v in c("syntheticT","cOut","mheir","fmissmatch","fmissmatch2","fdown","distlondon","celibacy","pr4","hengpee","biorder","byear","age1861","nthismarriage","wom","hforeign","dage","myear")) {
    x <- s[[v]]; cat(sprintf("%-14s NA=%4d mean=%9.3f min=%8.2f max=%8.2f nuniq=%d\n", v, sum(is.na(x)), mean(x, na.rm=TRUE), min(x, na.rm=TRUE), max(x, na.rm=TRUE), length(unique(x))))
  }
  cat("byear clusters:", length(unique(s$byear)), "\n")
  print(table(s$age1861, useNA="a"))
}
b <- d %>% filter(base_sample == 1); chk(b, "base")
m <- d %>% filter(marital_rates_sample == 1); chk(m, "marital")
cat("base w/ fmissmatch nonNA:", sum(!is.na(b$fmissmatch)), " & dist:", sum(!is.na(b$fmissmatch) & !is.na(b$distlondon)), "\n")
cat("base w/ dist:", sum(!is.na(b$distlondon)), " marital w/ dist:", sum(!is.na(m$distlondon)), "\n")
print(table(m$celibacy, m$base_sample, useNA="a"))
print(table(b$crankspo, b$cOut, useNA="a"))
# syntheticT by age1861
print(b %>% group_by(age1861) %>% summarise(T = mean(syntheticT), sdT = sd(syntheticT), n = n()), n = 30)
cat("sd T base:", sd(b$syntheticT), "\n")
