suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-d/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
A <- read_dta(paste0(D, "SurveyStageI_WaveA_raw.dta")); A$wave <- "A"
B <- read_dta(paste0(D, "SurveyStageI_WaveB_raw.dta")); B$wave <- "B"
keep <- c("panelID","wave","RAND0","RAND","RAND12","region","agebracket","gender","demrep","hhincbracket","employment",
          "elicitbgendeMarc","elicitbgendernoinMar","manicheckSQ001","manicheckSQ002","manicheckSQ003",
          "quotaanchor","AAanchor","legislationanchor","transparencyanchor","childcare",
          "demo1","childrenSQ001","childrenSQ002","birthyear","hhincome")
pv <- c("extrayoung","extraHSS","extraoccuu","extrasame","extrachild")
for (v in pv) { if (!v %in% names(A)) A[[v]] <- NA_real_; if (!v %in% names(B)) B[[v]] <- NA_real_ }
M <- bind_rows(zap_labels(A[, c(keep, pv)]), zap_labels(B[, c(keep, pv)]))
cat("N main:", nrow(M), "\n"); print(table(M$wave, M$RAND))
for (v in c("region","agebracket","gender","demrep","hhincbracket","employment","demo1","childrenSQ001","childrenSQ002",
            "manicheckSQ001","manicheckSQ002","manicheckSQ003","quotaanchor","AAanchor","legislationanchor","transparencyanchor","childcare")) {
  cat("--", v, "\n"); print(table(M$wave, M[[v]], useNA = "ifany"))
}
M$prior <- ifelse(!is.na(M$elicitbgendeMarc), M$elicitbgendeMarc, M$elicitbgendernoinMar)
cat("both prior nonNA:", sum(!is.na(M$elicitbgendeMarc) & !is.na(M$elicitbgendernoinMar)), " none:", sum(is.na(M$prior)), "\n")
print(table(inc = M$RAND12, nonNAinc = !is.na(M$elicitbgendeMarc)))
M$npost <- rowSums(!is.na(M[, pv])); print(table(M$wave, M$npost))
# follow-up
FA <- zap_labels(read_dta(paste0(D, "SurveyStageII_WaveA_raw.dta")))
FB <- zap_labels(read_dta(paste0(D, "SurveyStageII_WaveB_raw.dta")))
F <- bind_rows(FA, FB)
cat("N followup:", nrow(F), " matched:", sum(F$panelID %in% M$panelID), " dup ids main:", sum(duplicated(M$panelID)), "\n")
J <- inner_join(F, M, by = "panelID", suffix = c(".f", ".m"))
cat("wave agree:"); print(table(J$wave.f, J$wave.m))
cat("rand vs RAND:\n"); print(table(J$rand, J$RAND))
cat("rand vs RAND0:\n"); print(table(J$rand, J$RAND0))
cat("prior equal:", sum(abs(J$prior.f - J$prior.m) < 1e-6, na.rm = TRUE), "of", nrow(J), "\n")
print(table(J$gender.f, J$gender.m))
print(table(dem = J$democrat, ind = J$indep, oth = J$otherpol, J$demrep))
print(table(J$region, paste(J$midwest, J$south, J$west)))
print(table(J$agebracket, paste(J$age1, J$age2, J$age3, J$age4)))
print(table(J$hhincbracket, round(J$loghhinc, 6)))
print(table(J$demo1, J$associatemore))
print(table(paste(J$childrenSQ001, J$childrenSQ002), J$anychildren))
print(table(J$employment, paste(J$fulltime, J$parttime, J$selfemp, J$unemployed, J$student)))
cat("pweight cells wave B:\n"); JB <- J[J$wave.f == "B", ]
print(table(paste(JB$gender.m, JB$agebracket), round(JB$pweight, 4)))
print(table(FB$genderII, FB$gender)); print(table(FB$ageII, round(FB$pweight, 4)))
cat("followup items:\n")
for (v in c("wageproblemSQ001","wageproblemSQ002","wageproblemSQ003","wageproblemSQ004","wageproblem2SQ001","wageproblem2SQ002","wageproblem2SQ003","wageproblem2SQ004","govwomen")) {
  if (v %in% names(F)) { cat("--", v, "\n"); print(table(F$wave, F[[v]], useNA = "ifany")) }
}
print(table(FB$randorder2, FB$wageproblemSQ002 == ""))
cat("posteriorII NA:", sum(is.na(F$posteriorII)), "\n")
