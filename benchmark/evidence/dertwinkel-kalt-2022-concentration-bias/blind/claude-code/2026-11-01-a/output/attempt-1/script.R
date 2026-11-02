suppressMessages(library(tidyverse))
p <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/blind/2026-11-01-a/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read_csv(p, show_col_types = FALSE)
print(dim(d)); print(names(d))
options(width = 250)
print(head(as.data.frame(d), 22))
for (v in c("treatment","decision_number","corner","chose_corner","pizza","control","main","dispersed","utility_point")) { cat("==", v, "\n"); print(table(d[[v]], useNA="ifany")) }
cat("n subjects:", n_distinct(d$tn), "\n")
print(as.data.frame(d %>% count(treatment, pizza, control, main, dispersed)))
print(summary(d))
