library(haven); library(sandwich); library(lmtest)
d <- zap_labels(read_dta("<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-b/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/choice_experiments.dta"))
d <- subset(d, Highx10 == 0 & Highx100 == 0 & (professionals == 1 | !is.na(stdalpha)))
print(with(d, table(study, paste(wave1, wave2, wave3))))
print(with(d, table(study, paste(incentiveshigh, incentiveleft, incentiveshigh_incentiveleft))))
print(with(d, table(study, mturkwave, useNA = "a")))
print(with(d, table(study, paste(prolific, cloudresearch, professionalscloudresearch, professionalsfree))))
specs <- list(
  A = "choicebefore ~ professionals + seeincentivecostly + seequalitycostly + female + age + wave1 + wave2 + wave3 + incentiveshigh + incentiveleft + incentiveshigh_incentiveleft",
  B = "choicebefore ~ professionals + seeincentivecostly + seequalitycostly + female + age + factor(wave) + incentiveshigh + incentiveleft + incentiveshigh_incentiveleft",
  C = "choicebefore ~ professionals + seeincentivecostly + seequalitycostly + female + age + wave2 + wave3 + incentiveshigh + incentiveleft + incentiveshigh_incentiveleft")
for (s in names(specs)) { m <- lm(as.formula(specs[[s]]), d); cat("\nspec", s, "\n"); print(round(coeftest(m, vcov = vcovHC(m, type = "HC3")), 4)) }
