suppressMessages(library(haven))
M <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-c/mount/settele_2022_gender_wage_gap_beliefs_policy/"
D <- paste0(M, "data/")
strip <- function(x) { x <- gsub("<[^>]+>", " ", x); x <- gsub("&nbsp;|\\s+", " ", x); trimws(x) }
getsec <- function(txt, sec) {
  m <- regmatches(txt, regexpr(paste0("<", sec, ">.*?</", sec, ">"), txt, perl = TRUE))
  if (length(m) == 0) return(list())
  rows <- regmatches(m, gregexpr("<row>.*?</row>", m, perl = TRUE))[[1]]
  lapply(rows, function(r) {
    f <- regmatches(r, gregexpr("<([a-z_]+)><!\\[CDATA\\[(.*?)\\]\\]></\\1>", r, perl = TRUE))[[1]]
    nm <- sub("^<([a-z_]+)>.*", "\\1", f); val <- sub("^<[a-z_]+><!\\[CDATA\\[(.*?)\\]\\]></[a-z_]+>$", "\\1", f)
    setNames(as.list(val), nm)
  })
}
want <- c("region","agebracket","gender","demrep","hhincbracket","employment","demo1","demo3","children","manicheck",
          "quotaanchor","AAanchor","transparencyanchor","legislationanchor","childcare","wageproblem","wageproblem2",
          "govwomen","govlowskilled","antidiscr","fampolicy","age","employment","extrayoung","extraHSS","extraoccuu",
          "extrasame","extrachild","elicitbgendeMarc","elicitbgendernoinMar","elicitbgende","hrsweek","fairness","RAND","RAND12","RAND6","RAND2","RAND3","RAND0","fillRAND")
for (f in list.files(paste0(M, "surveys"), full.names = TRUE)) {
  txt <- paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  cat("\n######## ", basename(f), "\n")
  qs <- getsec(txt, "questions"); sq <- getsec(txt, "subquestions"); an <- getsec(txt, "answers")
  qdf <- do.call(rbind, lapply(qs, function(r) data.frame(qid = r$qid, title = r$title, type = if (is.null(r$type)) "" else r$type, q = strip(if (is.null(r$question)) "" else r$question), stringsAsFactors = FALSE)))
  sdf <- do.call(rbind, lapply(sq, function(r) data.frame(qid = r$qid, parent = r$parent_qid, title = r$title, q = strip(if (is.null(r$question)) "" else r$question), stringsAsFactors = FALSE)))
  adf <- do.call(rbind, lapply(an, function(r) data.frame(qid = r$qid, code = r$code, a = strip(r$answer), stringsAsFactors = FALSE)))
  qdf <- qdf[!duplicated(qdf$qid), ]
  for (i in which(qdf$title %in% want)) {
    cat("--", qdf$title[i], "[", qdf$type[i], "]:", substr(qdf$q[i], 1, 400), "\n")
    s <- sdf[sdf$parent == qdf$qid[i], ]; s <- s[!duplicated(s$title), ]
    if (nrow(s)) for (j in seq_len(nrow(s))) cat("   sq", s$title[j], ":", substr(s$q[j], 1, 150), "\n")
    a <- adf[adf$qid == qdf$qid[i], ]; a <- a[!duplicated(a$code), ]
    if (nrow(a)) cat("   ans:", paste(paste0(a$code, "=", substr(a$a, 1, 40)), collapse = " ; "), "\n")
  }
}
A <- read_dta(paste0(D, "SurveyStageI_WaveA_raw.dta")); B <- read_dta(paste0(D, "SurveyStageI_WaveB_raw.dta"))
for (nm in c("A","B")) {
  d <- get(nm); cat("\n==== wave", nm, "\n")
  tr <- with(d, ifelse(!is.na(groupTime502) | !is.na(groupTime747), "ACS", ifelse(!is.na(groupTime505) | !is.na(groupTime748), "CPS", "C")))
  print(table(tr, RAND = d$RAND)); print(table(tr, RAND12 = d$RAND12)); print(table(tr, ctrlnote = !is.na(d$groupTime548)))
  print(table(inc = !is.na(d$elicitbgendeMarc), noinc = !is.na(d$elicitbgendernoinMar)))
  for (v in c("region","agebracket","gender","demrep","hhincbracket","employment","demo1","demo3","childrenSQ001","childrenSQ002","manicheckSQ001","quotaanchor","transparencyanchor","childcare","hrsweek")) { cat(v, ":"); print(table(d[[v]], useNA = "ifany")) }
  post <- if (nm == "A") cbind(d$extrayoung, d$extraHSS, d$extraoccuu) else cbind(d$extrasame, d$extrachild)
  cat("posterior n nonmiss per row:"); print(table(rowSums(!is.na(post)), tr))
}
# compare follow-up constructed covariates with raw codes
FA <- read_dta(paste0(D, "SurveyStageII_WaveA_raw.dta")); FB <- read_dta(paste0(D, "SurveyStageII_WaveB_raw.dta"))
for (nm in c("A","B")) {
  d <- get(nm); f <- get(paste0("F", nm)); m <- merge(f, d, by = "panelID", suffixes = c("", ".main"))
  cat("\n==== followup merge wave", nm, nrow(f), nrow(m), "\n")
  m$priorraw <- ifelse(is.na(m$elicitbgendeMarc), m$elicitbgendernoinMar, m$elicitbgendeMarc)
  cat("prior match:", sum(m$prior == m$priorraw, na.rm = TRUE), "\n")
  print(table(m$demrep, paste(m$democrat, m$indep, m$otherpol)))
  print(table(m$region, paste(m$midwest, m$south, m$west)))
  print(table(m$agebracket, paste(m$age1, m$age2, m$age3, m$age4)))
  print(table(m$gender.main, m$gender))
  print(table(m$employment, paste(m$fulltime, m$parttime, m$selfemp, m$unemployed, m$student)))
  print(table(m$demo1, m$associatemore))
  print(table(m$hhincbracket, round(m$loghhinc, 3)))
  print(table(paste(m$childrenSQ001, m$childrenSQ002), m$anychildren))
  print(table(paste(m$agebracket, m$gender.main), m$pweight))
  tr <- with(m, ifelse(!is.na(groupTime502) | !is.na(groupTime747), "ACS", ifelse(!is.na(groupTime505) | !is.na(groupTime748), "CPS", "C")))
  print(table(tr, m$rand))
}
cat("pweight in main B by age x gender would be derived from age1/gender\n")
