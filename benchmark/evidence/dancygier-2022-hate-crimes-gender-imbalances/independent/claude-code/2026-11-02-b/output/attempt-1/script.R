library(haven)
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/independent/2026-11-02-b/mount/dancygier_2022_hate_crimes_gender_imbalances"
s <- read_dta(file.path(D,"survey.dta"))
print(dim(s))
for (v in names(s)) { x <- s[[v]]; cat(v, "|", class(x)[1], "|", attr(x,"label"), "| NA:", sum(is.na(x)), "| uniq:", length(unique(x)), "| ", paste(head(unique(x),6), collapse=","), "\n") }
print(table(s$wave))
w4 <- s[s$wave==4,]
cat("wave4 NA counts\n"); print(colSums(is.na(w4)))
c <- read_dta(file.path(D,"context.dta"))
print(dim(c))
for (v in names(c)) { x <- c[[v]]; cat(v, "|", class(x)[1], "|", attr(x,"label"), "| NA:", sum(is.na(x)), "| uniq:", length(unique(x)), "| ", paste(head(unique(x),4), collapse=","), "\n") }
print(table(c$year))
