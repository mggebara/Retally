suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/blind/2026-11-02-a/mount/dancygier_2022_hate_crimes_gender_imbalances"
s <- read_dta(file.path(D, "survey.dta"))
cat("survey dims", dim(s), "\n"); print(table(s$wave))
w4 <- s[s$wave == 4, ]
cat("w4 rows", nrow(w4), "\n")
for (v in names(s)) {
  x <- w4[[v]]
  cat(sprintf("%-32s class=%-20s NA=%5d nuniq=%4d lab=%s\n", v, paste(class(x), collapse="/"), sum(is.na(x)), length(unique(x)),
      if (!is.null(attr(x, "labels"))) paste(head(paste0(attr(x,"labels"),"=",names(attr(x,"labels"))), 14), collapse="; ") else ""))
  if (is.character(x) || length(unique(x)) <= 16) { print(head(sort(table(x, useNA="ifany"), decreasing=TRUE), 16)) }
}
c1 <- read_dta(file.path(D, "context.dta"))
cat("context dims", dim(c1), "\n"); print(names(c1)); print(table(c1$year))
for (v in names(c1)) { x <- c1[[v]]; cat(sprintf("%-32s class=%-12s NA=%6d nuniq=%6d mean=%s\n", v, class(x)[1], sum(is.na(x)), length(unique(x)), if (is.numeric(x)) format(mean(x, na.rm=TRUE)) else "")) }
cat("rows per muni-year dup:", sum(duplicated(c1[,c("ags_muni","year")])), "\n")
print(head(as.data.frame(c1[order(c1$ags_muni, c1$year), c("ags_muni","ags_county","ags_state","year","Hate_all_muni","Hate_all_muni_bin","pop_15_44_muni_gendergap_2015")]), 12))
print(summary(c1$pop_15_44_muni_gendergap_2015))
