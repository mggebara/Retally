suppressMessages({library(haven); library(dplyr); library(xml2)})
M <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-a/mount/settele_2022_gender_wage_gap_beliefs_policy/"
strip <- function(s) { s <- gsub("<[^>]+>", " ", s); s <- gsub("\\{[^}]*\\}", "{..}", s); s <- gsub("[[:space:]]+", " ", s); trimws(s) }
titles <- c("region","agebracket","gender","demrep","hhincbracket","employment","manicheck","quotaanchor","AAanchor",
            "transparencyanchor","legislationanchor","childcare","demo1","demo2","demo3","children","extrayoung","extraHSS",
            "extraoccuu","extrasame","extrachild","elicitbgendeMarc","elicitbgendernoinMar","birthyear","maritalst",
            "wageproblem","wageproblem2","govwomen","govlowskilled","antidiscr","fampolicy","AAanchorII","legislationanchorII","fairness","ageII","genderII","employmentII")
for (f in c("limesurvey_survey_736385.lss","limesurvey_survey_918833.lss","limesurvey_survey_344617.lss","limesurvey_survey_247726.lss")) {
  x <- read_xml(paste0(M, "surveys/", f))
  cat("\n######## ", f, "\n")
  qrows <- xml_find_all(x, "//questions/rows/row")
  q <- data.frame(qid = xml_text(xml_find_first(qrows, "qid")), parent = xml_text(xml_find_first(qrows, "parent_qid")),
                  title = xml_text(xml_find_first(qrows, "title")), text = xml_text(xml_find_first(qrows, "question")),
                  type = xml_text(xml_find_first(qrows, "type")), stringsAsFactors = FALSE)
  sq <- xml_find_all(x, "//subquestions/rows/row")
  s <- data.frame(qid = xml_text(xml_find_first(sq, "qid")), parent = xml_text(xml_find_first(sq, "parent_qid")),
                  title = xml_text(xml_find_first(sq, "title")), text = xml_text(xml_find_first(sq, "question")), stringsAsFactors = FALSE)
  ar <- xml_find_all(x, "//answers/rows/row")
  a <- data.frame(qid = xml_text(xml_find_first(ar, "qid")), code = xml_text(xml_find_first(ar, "code")),
                  ans = xml_text(xml_find_first(ar, "answer")), ord = xml_text(xml_find_first(ar, "sortorder")), stringsAsFactors = FALSE)
  for (t in titles) {
    qq <- q[q$title == t, ]
    if (nrow(qq) == 0) next
    for (i in seq_len(nrow(qq))) {
      cat("---", t, "type", qq$type[i], ":", substr(strip(qq$text[i]), 1, 400), "\n")
      ss <- s[s$parent == qq$qid[i], ]
      if (nrow(ss)) for (j in seq_len(nrow(ss))) cat("   SQ", ss$title[j], ":", substr(strip(ss$text[j]), 1, 150), "\n")
      aa <- a[a$qid == qq$qid[i], ]
      if (nrow(aa)) cat("   ANS:", paste0(aa$code, "=", substr(strip(aa$ans), 1, 40), collapse = " | "), "\n")
    }
  }
}
# cross-tab stage I raw codes vs stage II constructed covariates
D <- paste0(M, "data/")
A1 <- read_dta(paste0(D, "SurveyStageI_WaveA_raw.dta")); B1 <- read_dta(paste0(D, "SurveyStageI_WaveB_raw.dta"))
A2 <- read_dta(paste0(D, "SurveyStageII_WaveA_raw.dta")); B2 <- read_dta(paste0(D, "SurveyStageII_WaveB_raw.dta"))
cat("\nStage II names A:", names(A2), "\n")
for (pair in list(list(A1, A2, "A"), list(B1, B2, "B"))) {
  m <- inner_join(pair[[1]], pair[[2]] %>% select(panelID, rand, fulltime, parttime, selfemp, unemployed, student, midwest, south, west,
                    age1, age2, age3, age4, otherpol, democrat, indep, prior, associatemore, loghhinc, anychildren, pweight),
                  by = "panelID")
  cat("\n==== wave", pair[[3]], "merged n =", nrow(m), "\n")
  print(table(m$RAND, m$rand))
  print(table(m$region, paste(m$midwest, m$south, m$west)))
  print(table(m$agebracket, paste(m$age1, m$age2, m$age3, m$age4)))
  print(table(m$demrep, paste(m$democrat, m$indep, m$otherpol)))
  print(table(m$hhincbracket, round(m$loghhinc, 2)))
  print(table(m$employment, paste(m$fulltime, m$parttime, m$selfemp, m$unemployed, m$student)))
  print(table(m$demo1, m$associatemore))
  print(table(m$childrenSQ001, m$anychildren)); print(table(m$childrenSQ002, m$anychildren))
  print(table(m$gender.x, m$pweight))
  pr <- dplyr::coalesce(m$elicitbgendeMarc, m$elicitbgendernoinMar)
  cat("prior match:", mean(pr == m$prior, na.rm = TRUE), sum(is.na(pr)), "\n")
}
cat("\nSampling counts wave A RAND:"); print(table(A1$RAND)); print(table(B1$RAND))
cat("gender cols in A2:\n"); print(names(A2)[grepl("gender", names(A2))]); print(sapply(A2[grepl("gender", names(A2))], function(v) table(v)))
