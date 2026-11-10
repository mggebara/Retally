suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-b/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
num <- function(x) { x <- as.character(x); x[x == ""] <- NA; suppressWarnings(as.numeric(sub("^A", "", x))) }
build <- function(d, w) {
  d <- zap_labels(d)
  post <- if (w == "A") dplyr::coalesce(d$extrayoung, d$extraHSS, d$extraoccuu) else dplyr::coalesce(d$extrasame, d$extrachild)
  postver <- if (w == "A") ifelse(!is.na(d$extrayoung), "young", ifelse(!is.na(d$extraHSS), "hs", ifelse(!is.na(d$extraoccuu), "occ", NA))) else ifelse(!is.na(d$extrasame), "same", ifelse(!is.na(d$extrachild), "child", NA))
  data.frame(panelID = d$panelID, wave = w, waveB = as.numeric(w == "B"), RAND = d$RAND, RAND3 = d$RAND3, RAND4 = d$RAND4,
    incent = d$RAND12,
    prior = ifelse(d$RAND12 == 1, d$elicitbgendeMarc, d$elicitbgendernoinMar),
    posterior = post, postver = postver,
    female = as.numeric(d$gender == "A2"), gender_raw = d$gender,
    demrep = d$demrep, region = d$region, agebracket = d$agebracket, employment = d$employment,
    hhincbracket = d$hhincbracket, demo1 = d$demo1, ch1 = d$childrenSQ001, ch2 = d$childrenSQ002,
    large = num(d$manicheckSQ001), problem = num(d$manicheckSQ002), gov = num(d$manicheckSQ003),
    quota = num(d$quotaanchor), aa = num(d$AAanchor), transp = num(d$transparencyanchor),
    legis = num(d$legislationanchor), childcare = num(d$childcare), stringsAsFactors = FALSE)
}
A <- build(read_dta(paste0(D, "SurveyStageI_WaveA_raw.dta")), "A")
B <- build(read_dta(paste0(D, "SurveyStageI_WaveB_raw.dta")), "B")
m <- rbind(A, B)
cat("N main", nrow(m), "\n"); print(table(m$wave, m$RAND))
for (v in c("demrep","region","agebracket","employment","hhincbracket","demo1","ch1","ch2","gender_raw","postver")) { cat(v, "\n"); print(table(m[[v]], m$wave, useNA = "ifany")) }
for (v in c("prior","posterior","large","problem","gov","quota","aa","transp","legis","childcare")) cat(v, "NA by wave:", tapply(is.na(m[[v]]), m$wave, sum), " range", range(m[[v]], na.rm=TRUE), "\n")
cat("posterior NA among treated:", sum(is.na(m$posterior[m$RAND > 0])), "\n")
ctrl <- m[m$RAND == 0, ]
cat("control N", nrow(ctrl), "\n")
for (ty in c(1, 2, 6, 7)) cat("type", ty, quantile(ctrl$prior, c(.05, .95), type = ty), "\n")
cat("full-sample p5/p95 type2", quantile(m$prior, c(.05,.95), type=2), "\n")
q <- quantile(ctrl$prior, c(.05, .95), type = 2)
cat("n strict", sum(ctrl$prior > q[1] & ctrl$prior < q[2]), " n weak", sum(ctrl$prior >= q[1] & ctrl$prior <= q[2]), "\n")
cat("sd prior control", sd(ctrl$prior), " sd posterior control", sd(ctrl$posterior, na.rm=TRUE), " sd posterior treated", sd(m$posterior[m$RAND>0], na.rm=TRUE), "\n")
# Compare to stage II covariates
s2 <- rbind(
  zap_labels(read_dta(paste0(D, "SurveyStageII_WaveA_raw.dta")))[, c("panelID","wave","rand","gender","democrat","indep","otherpol","prior","associatemore","loghhinc","anychildren","fulltime","parttime","selfemp","unemployed","student","midwest","south","west","age1","age2","age3","age4","pweight")],
  zap_labels(read_dta(paste0(D, "SurveyStageII_WaveB_raw.dta")))[, c("panelID","wave","rand","gender","democrat","indep","otherpol","prior","associatemore","loghhinc","anychildren","fulltime","parttime","selfemp","unemployed","student","midwest","south","west","age1","age2","age3","age4","pweight")])
j <- merge(s2, m, by = "panelID", suffixes = c(".s2", ""))
cat("merged", nrow(j), "of", nrow(s2), " dup panelIDs main:", sum(duplicated(m$panelID)), "\n")
print(table(j$rand, j$RAND)); print(table(j$gender, j$gender_raw)); print(table(j$demrep, paste(j$democrat, j$indep, j$otherpol)))
cat("prior equal:", sum(j$prior == j$prior.s2, na.rm=TRUE), "\n")
print(table(j$demo1, j$associatemore)); print(table(j$hhincbracket, round(j$loghhinc, 4)))
print(table(paste(j$ch1, j$ch2) , j$anychildren)[1:10, ])
print(table(j$employment, paste(j$fulltime, j$parttime, j$selfemp, j$unemployed, j$student)))
print(table(j$region, paste(j$midwest, j$south, j$west))); print(table(j$agebracket, paste(j$age1, j$age2, j$age3, j$age4)))
print(table(paste(j$wave, j$agebracket, j$gender_raw), round(j$pweight, 4)))
