suppressMessages(library(readr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-d/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
tl <- function(x, n=40) { x <- gsub("\\s+"," ",x); substr(x, pmax(1,nchar(x)-n+1), nchar(x)) }
for (b in c(1,5,8)) {
  d <- suppressMessages(read_csv(file.path(D, sprintf("expAbatch%d.csv", b)), col_types=cols(.default="c"), n_max=2, show_col_types=FALSE, name_repair="minimal"))
  cat("== A batch", b, "\n")
  for (v in grep("^iMPL", names(d), value=TRUE)) cat(v, "=>", tl(d[[v]][1]), "\n")
}
d <- read_csv(file.path(D, "expBbatch1.csv"), col_types=cols(.default="c"), n_max=3, show_col_types=FALSE)
cat("== B\n")
for (v in grep("^iMPL", names(d), value=TRUE)) cat(v, "=>", tl(d[[v]][1], 50), "\n")
