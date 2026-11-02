library(haven)
d <- "<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-c/mount/hollyer_2022_parties_as_disciplinarians"
x <- read_dta(file.path(d,"cross-national-data.dta"))
for (v in names(x)) { cat("----", v, "label:", attr(x[[v]],"label"), "\n"); print(summary(as.numeric(x[[v]]))); lb <- attr(x[[v]],"labels"); if(!is.null(lb)) print(lb); if(length(unique(x[[v]]))<12) print(table(x[[v]],useNA="a")) }
cat("countries:", length(unique(x$ccode)), "\n")
print(head(as.data.frame(x),5))
cc <- complete.cases(x); cat("complete all:", sum(cc), length(unique(x$ccode[cc])), "\n")
r <- read_dta(file.path(d,"brazil-RD-data.dta"))
for (v in names(r)) { cat("----", v, "label:", attr(r[[v]],"label"), "\n"); print(summary(as.numeric(r[[v]]))); if(length(unique(r[[v]]))<12) print(table(r[[v]],useNA="a")) }
print(table(r$dlameduck_runs, is.na(r$youngF_inc_for1), useNA="a"))
