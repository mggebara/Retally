library(haven); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-d/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/"
d <- read_dta(paste0(D,"choice_experiments.dta"))
print(as.data.frame(count(d, treatment, study, wave, incentivedesign, okself = !is.na(selfish) | professionals==1, okage = !is.na(age))))
print(as.data.frame(count(d, study, locatedus, attentionpassed, chooseblindness_na = is.na(chooseblindness))))
