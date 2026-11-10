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
print(table(m$RAND, m$wave))
f <- bind_rows(read_dta(paste0(D, "SurveyStageII_WaveA_raw.dta")) %>% mutate(across(everything(), ~ { attributes(.x) <- NULL; .x })),
               read_dta(paste0(D, "SurveyStageII_WaveB_raw.dta")) %>% mutate(across(everything(), ~ { attributes(.x) <- NULL; .x })))
cat("follow-up names:", names(f), "\n")
j <- inner_join(m, f %>% rename(waveF = wave, priorF = prior), by = "panelID")
cat("matched", nrow(j), "\n")
print(table(j$RAND, j$rand))
print(table(j$demrep, paste0("d", j$democrat, "i", j$indep, "o", j$otherpol)))
print(table(j$agebracket, paste0(j$age1, j$age2, j$age3, j$age4)))
print(table(j$region, paste0(j$midwest, j$south, j$west)))
print(table(j$employment, paste0(j$fulltime, j$parttime, j$selfemp, j$unemployed, j$student)))
print(table(j$demo1, j$associatemore))
print(table(paste(j$ch1, j$ch2), j$anychildren))
print(table(j$hhincbracket, round(j$loghhinc, 4)))
print(table(j$gender, j$gender.y <- f$gender[match(j$panelID, f$panelID)]))
cat("prior diff:", summary(j$prior - j$priorF), "\n")
print(table(j$wave, round(j$pweight, 4), paste(j$agebracket, j$gender)))
cat("posterior vars wave A nonNA:\n")
print(table(a$RAND3, !is.na(a$extrayoung), !is.na(a$extraHSS)))
print(table(b$RAND3, !is.na(b$extrasame)))
print(table(a$RAND3, !is.na(a$extraoccuu)))
print(table(b$RAND3, !is.na(b$extrachild)))
cat("wageproblem B overlap\n")
print(table(f$wageproblemSQ002 == "", f$wageproblem2SQ002 == "", useNA = "ifany"))
