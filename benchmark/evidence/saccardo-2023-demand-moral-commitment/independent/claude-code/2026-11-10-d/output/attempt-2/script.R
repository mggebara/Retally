library(haven); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-d/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/"
d <- read_dta(paste0(D,"choice_experiments.dta"))
print(as.data.frame(count(d, condition, treatment, wave, incentivedesign, Highx10, Highx100, study, year)))
print(as.data.frame(count(d, wave, is.na(selfish), is.na(stdalpha), is.na(age), attentionpassed)))
print(as.data.frame(count(d, wave, incentiveshigh, incentiveleft, probabilistic_incentive, flippedorder)))
print(as.data.frame(count(d, treatment, seeincentivecostly, seequalitycostly, professionalsfree, incentivecostly, qualitycostly)))
print(as.data.frame(count(d, choicebefore, getbefore, getyourchoice, notgetyourchoice)))
print(table(d$alphavaluefinal, d$selfish, useNA="ifany"))
