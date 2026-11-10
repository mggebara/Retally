suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-a/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
num <- function(x) as.numeric(sub("^A","",x))
rd <- function(f) { d <- read_dta(paste0(D,f)); d[] <- lapply(d, function(x) zap_labels(x)); d }
a <- rd("SurveyStageI_WaveA_raw.dta"); b <- rd("SurveyStageI_WaveB_raw.dta")
build <- function(d, w) {
  data.frame(panelID=d$panelID, waveB=as.numeric(w=="B"), RAND0=d$RAND0, RAND=d$RAND,
    female=as.numeric(d$gender=="A2"), demrep=d$demrep, region=d$region, agebracket=d$agebracket,
    hhincbracket=d$hhincbracket, employment=d$employment, demo1=d$demo1,
    ch1=d$childrenSQ001, ch2=d$childrenSQ002,
    prior=ifelse(is.na(d$elicitbgendeMarc), d$elicitbgendernoinMar, d$elicitbgendeMarc),
    large=num(d$manicheckSQ001), problem=num(d$manicheckSQ002), gov=num(d$manicheckSQ003),
    quota=num(d$quotaanchor), aa=num(d$AAanchor), legis=num(d$legislationanchor), care=num(d$childcare),
    transp=if (w=="A") num(d$transparencyanchor) else NA, website=if (w=="B") num(d$transparencyanchor) else NA,
    post=if (w=="A") dplyr::coalesce(d$extrayoung, d$extraHSS, d$extraoccuu) else dplyr::coalesce(d$extrasame, d$extrachild),
    stringsAsFactors=FALSE)
}
m <- rbind(build(a,"A"), build(b,"B"))
cat("N", nrow(m), "dup ids", sum(duplicated(m$panelID)), "\n")
print(table(m$RAND0, m$RAND, m$waveB))
print(table(m$demrep, useNA="ifany")); print(table(m$agebracket, m$waveB)); print(table(m$employment)); print(table(m$demo1)); print(table(m$ch1, m$ch2))
print(summary(m[,c("prior","large","problem","gov","quota","aa","legis","care","transp","website","post")]))
cat("post missing by RAND:\n"); print(table(is.na(m$post), m$RAND))
ctl <- m[m$RAND==0,]
for (t in c(1,2,7)) cat("type",t, quantile(ctl$prior, c(.05,.95), type=t), " full:", quantile(m$prior, c(.05,.95), type=t), "\n")
# merge with stage II
s2a <- rd("SurveyStageII_WaveA_raw.dta"); s2b <- rd("SurveyStageII_WaveB_raw.dta")
cols <- c("panelID","gender","democrat","indep","otherpol","prior","associatemore","loghhinc","anychildren","fulltime","parttime","selfemp","unemployed","student","midwest","south","west","age1","age2","age3","age4","pweight","rand","wave")
s2 <- rbind(s2a[,cols], s2b[,cols])
mm <- merge(m, s2, by="panelID")
cat("followup merged", nrow(mm), "of", nrow(s2), "\n"); print(table(mm$RAND, mm$rand))
print(table(mm$demrep, mm$democrat, mm$indep, mm$otherpol)[, , , ] |> ftable())
print(table(mm$hhincbracket, round(mm$loghhinc,4)))
print(table(mm$agebracket, paste(mm$age1,mm$age2,mm$age3,mm$age4)))
print(table(mm$employment, paste(mm$fulltime,mm$parttime,mm$selfemp,mm$unemployed,mm$student)))
print(table(mm$demo1, mm$associatemore)); print(table(paste(mm$ch1,mm$ch2)=="A1 A1", mm$anychildren))
print(table(mm$region, paste(mm$midwest,mm$south,mm$west)))
cat("prior equal:", sum(mm$prior.x==mm$prior.y, na.rm=TRUE), "\n"); cat("female eq:", sum(mm$female==mm$gender), "\n")
print(table(mm$agebracket, mm$female, round(mm$pweight,4), mm$wave))
