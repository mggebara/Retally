suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-d/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
options(width = 200)
num <- function(x) suppressWarnings(as.numeric(sub("^A", "", x)))
prep <- function(d, w) {
  d %>% transmute(panelID, wave = w,
    region = as.character(region), agebracket = as.character(agebracket), gender = as.character(gender),
    demrep = as.character(demrep), hhincbracket = as.character(hhincbracket), employment = as.character(employment),
    demo1 = as.character(demo1), ch1 = as.character(childrenSQ001), ch2 = as.character(childrenSQ002),
    RAND = RAND, RAND3 = RAND3,
    prior = coalesce(elicitbgendeMarc, elicitbgendernoinMar))
}
a <- read_dta(paste0(D, "SurveyStageI_WaveA_raw.dta")); b <- read_dta(paste0(D, "SurveyStageI_WaveB_raw.dta"))
m <- bind_rows(prep(a, "A"), prep(b, "B"))
cat("N", nrow(m), " prior NA", sum(is.na(m$prior)), "\n")
for (ty in c(2, 6, 7)) {
  cat("type", ty, "\n")
  print(quantile(m$prior, c(.05, .95), type = ty))
  print(quantile(m$prior[m$RAND == 0], c(.05, .95), type = ty))
  print(quantile(m$prior[m$RAND != 0], c(.05, .95), type = ty))
}
inc <- c(!is.na(a$elicitbgendeMarc), !is.na(b$elicitbgendeMarc))
cat("incentivized only\n")
print(quantile(m$prior[inc], c(.05, .95), type = 2))
print(quantile(m$prior[inc & m$RAND == 0], c(.05, .95), type = 2))
