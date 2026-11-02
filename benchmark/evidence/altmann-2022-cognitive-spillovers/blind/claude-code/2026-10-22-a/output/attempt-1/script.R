suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/altmann-2022-cognitive-spillovers/blind/2026-10-22-a/mount/altmann_2022_cognitive_spillovers/ReplicationPackage/EmpiricalAnalysis/original_data/"
d <- read_dta(paste0(D,"formatted_data_replication.dta"))
cat(dim(d),"\n"); print(names(d))
for (v in names(d)) { x <- d[[v]]; lab <- attr(x,"label")
  cat("----", v, "|", ifelse(is.null(lab),"",lab), "| class", class(x)[1], "| NA", sum(is.na(x)), "| nuniq", length(unique(x)), "\n")
  if (length(unique(x)) <= 15) print(table(as_factor(x), useNA="ifany")) else print(summary(as.numeric(x)))
}
cat("subjects:", length(unique(d$subject_id)), "\n")
print(table(d$round))
m <- read_dta(paste0(D,"formatted_data_long_mturk.dta"))
cat(dim(m),"\n")
for (v in names(m)) { x <- m[[v]]; lab <- attr(x,"label")
  cat("----", v, "|", ifelse(is.null(lab),"",lab), "| NA", sum(is.na(x)), "| nuniq", length(unique(x)), "\n")
  if (length(unique(x)) <= 15) print(table(as_factor(x), useNA="ifany")) else print(summary(as.numeric(x)))
}
cat("mturk subjects:", length(unique(m$subject_id)), "\n"); print(table(m$round))
