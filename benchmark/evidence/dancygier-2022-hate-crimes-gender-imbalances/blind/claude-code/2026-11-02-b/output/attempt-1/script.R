suppressMessages(library(haven))
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/blind/2026-11-02-b/mount/dancygier_2022_hate_crimes_gender_imbalances"
desc <- function(d, k=15) for (v in names(d)) {
  x <- d[[v]]; lab <- attr(x,"label")
  cat(sprintf("%-35s %-10s lab=%s nNA=%d nuniq=%d ", v, class(x)[1], ifelse(is.null(lab),"",lab), sum(is.na(x)), length(unique(x))))
  if (length(unique(x))<=k) { tb <- table(x, useNA="ifany"); cat(paste(names(tb), tb, sep=":", collapse=" ")) } else if (is.numeric(x)) cat("range", signif(range(x,na.rm=TRUE),4))
  cat("\n")
}
s <- read_dta(file.path(D,"survey.dta"))
cat("SURVEY", dim(s), "\n"); desc(s)
for (v in names(s)) if (!is.null(attr(s[[v]],"labels"))) {cat(v,": "); print(attr(s[[v]],"labels"))}
cat("by wave NA counts\n")
print(aggregate(. ~ wave, data=data.frame(wave=s$wave, lapply(s[,-1], function(z) as.numeric(is.na(z)))), FUN=sum, na.action=na.pass))
cc <- read_dta(file.path(D,"context.dta"))
cat("CONTEXT", dim(cc), "\n"); desc(cc, 10)
print(table(cc$year))
