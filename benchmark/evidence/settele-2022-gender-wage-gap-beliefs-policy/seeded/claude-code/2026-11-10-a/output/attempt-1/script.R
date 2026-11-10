suppressPackageStartupMessages({library(haven)})
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-a/mount/settele_2022_gender_wage_gap_beliefs_policy/data"
v1 <- c("region","agebracket","gender","employment","hhincbracket","demrep","RAND","RAND12","RAND4",
 "elicitbgendeMarc","elicitbgendernoinMar","manicheckSQ001","quotaanchor","AAanchor","transparencyanchor",
 "legislationanchor","childcare","extrayoung","extraHSS","extraoccuu","extrasame","extrachild","demo1",
 "hhincome","childrenSQ001","childrenSQ002","submitdate","lastpage")
for (f in c("SurveyStageI_WaveA_raw.dta","SurveyStageI_WaveB_raw.dta")) {
  d <- read_dta(file.path(D,f)); cat("====",f,nrow(d),"\n")
  for (v in v1) if (v %in% names(d)) { x <- d[[v]]; cat(v, class(x)[1], ":");
    if (is.numeric(x)) cat(" NA=",sum(is.na(x))," range=",range(x,na.rm=TRUE)," nuniq=",length(unique(x)),"\n") else {print(head(sort(table(x,useNA="ifany"),decreasing=TRUE),12))} } else cat(v,"MISSING\n")
}
for (f in c("SurveyStageII_WaveA_raw.dta","SurveyStageII_WaveB_raw.dta")) {
  d <- read_dta(file.path(D,f)); cat("====",f,nrow(d),"\n"); print(names(d))
  for (v in c("wave","rand","pweight","wageproblemSQ002","govwomen","randorder2","submitdateII","posteriorII","unemployed","gender","prior")) if (v %in% names(d)) {x<-d[[v]]; cat(v,class(x)[1],":"); if (is.numeric(x)) cat(" NA=",sum(is.na(x))," range=",range(x,na.rm=TRUE),"\n") else print(head(table(x,useNA="ifany"),10))}
}
