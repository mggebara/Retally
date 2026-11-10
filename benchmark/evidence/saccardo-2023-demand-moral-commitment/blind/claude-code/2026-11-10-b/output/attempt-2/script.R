suppressMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/blind/2026-11-10-b/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/"
d <- read_dta(paste0(base, "choice_experiments.dta"))
d$selfNA <- is.na(d$selfish)
print(as.data.frame(d %>% count(condition, study, wave, Highx10, Highx100, incentivedesign, selfNA)))
print(as.data.frame(d %>% count(wave, probabilistic_incentive, incentiveshigh, incentiveleft, flippedorder, incentiveshigh_incentiveleft)))
print(as.data.frame(d %>% count(condition, treatment, seeincentivecostly, seequalitycostly, professionalsfree, incentivecostly, qualitycostly)))
cat("choicebefore vs committ / choiceafter:\n"); print(table(d$choicebefore, d$committ)); print(table(d$choicebefore, d$getbefore, d$getyourchoice))
cat("conflict vs incentive/signal\n"); print(as.data.frame(d %>% count(conflict, noconflict, incentiveB, signalblue)))
cat("selfish vs alphavaluefinal\n"); print(table(d$alphavaluefinal, d$selfish, useNA="ifany"))
cat("age NA by condition\n"); print(table(d$condition, is.na(d$age)))
summary(d$age)
# other files
for (f in c("Choice_coding_explanations.dta","professionals.dta","stakes.dta","Choice_Deterministic.dta")) {
  x <- read_dta(paste0(base, f)); cat("\n====", f, dim(x), "\n"); cat(names(x), "\n")
}
x <- read_dta(paste0(base, "Choice_coding_explanations.dta"))
nm <- setdiff(names(x), names(d)); cat("extra in coding:", nm, "\n")
print(as.data.frame(x %>% count(condition, wave, study)))
