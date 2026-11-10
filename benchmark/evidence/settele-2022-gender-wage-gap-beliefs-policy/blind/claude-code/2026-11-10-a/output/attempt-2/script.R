suppressMessages(library(haven))
M <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-a/mount/settele_2022_gender_wage_gap_beliefs_policy/"
D <- paste0(M, "data/")
# ---- Stage II full listing
for (f in c("SurveyStageII_WaveA_raw.dta","SurveyStageII_WaveB_raw.dta")) {
  d <- read_dta(paste0(D,f))
  cat("=====", f, nrow(d), ncol(d), "\n")
  for (v in names(d)) {
    x <- d[[v]]; lab <- attr(x,"label"); if (is.null(lab)) lab <- ""
    vl <- attr(x,"labels"); vls <- if (!is.null(vl)) paste(paste0(vl,"=",names(vl)), collapse="; ") else ""
    x <- zap_labels(x)
    nm <- if (is.character(x)) sum(!is.na(x) & x!="") else sum(!is.na(x))
    sm <- if (is.numeric(x)) paste(round(quantile(as.numeric(x), c(0,.25,.5,.75,1), na.rm=TRUE),3), collapse="/") else paste(head(unique(x),4),collapse="|")
    tb <- if (length(unique(x)) <= 12) paste(names(table(x, useNA="ifany")), table(x, useNA="ifany"), sep=":", collapse=" ") else ""
    cat(sprintf("%s | %s | n=%d | %s | %s | %s | %s\n", v, class(x)[1], nm, substr(lab,1,60), substr(sm,1,60), substr(vls,1,120), tb))
  }
}
# ---- LSS parsing
getf <- function(row, f) { m <- regmatches(row, regexpr(paste0("<",f,">(<!\\[CDATA\\[)?[\\s\\S]*?(\\]\\]>)?</",f,">"), row, perl=TRUE)); if (length(m)==0) return(""); m <- sub(paste0("^<",f,">(<!\\[CDATA\\[)?"),"",m, perl=TRUE); m <- sub(paste0("(\\]\\]>)?</",f,">$"),"",m, perl=TRUE); m }
strip <- function(s) { s <- gsub("<[^>]+>"," ",s); s <- gsub("&nbsp;|\\s+"," ",s); trimws(s) }
section <- function(txt, name) { m <- regmatches(txt, regexpr(paste0("<",name,">[\\s\\S]*?</",name,">"), txt, perl=TRUE)); if (length(m)==0) return(character(0)); rows <- regmatches(m, gregexpr("<row>[\\s\\S]*?</row>", m, perl=TRUE))[[1]]; rows }
for (f in list.files(paste0(M,"surveys"), full.names=TRUE)) {
  txt <- paste(readLines(f, warn=FALSE), collapse="\n")
  cat("\n\n##########", basename(f), "\n")
  g <- section(txt, "groups")
  cat("--- groups\n")
  for (r in g) cat(sprintf("G gid=%s order=%s name=%s | rel=%s\n", getf(r,"gid"), getf(r,"group_order"), substr(strip(getf(r,"group_name")),1,60), substr(getf(r,"grelevance"),1,200)))
  q <- section(txt, "questions")
  a <- section(txt, "answers")
  aq <- sapply(a, getf, f="qid"); ac <- sapply(a, getf, f="code"); aa <- sapply(a, function(r) strip(getf(r,"answer")))
  sq <- section(txt, "subquestions")
  sqp <- sapply(sq, getf, f="parent_qid"); sqt <- sapply(sq, getf, f="title"); sqq <- sapply(sq, function(r) strip(getf(r,"question")))
  cat("--- questions\n")
  for (r in q) {
    qid <- getf(r,"qid")
    cat(sprintf("Q qid=%s gid=%s title=%s type=%s | rel=%s\n   TEXT: %s\n", qid, getf(r,"gid"), getf(r,"title"), getf(r,"type"), substr(getf(r,"relevance"),1,200), substr(strip(getf(r,"question")),1,400)))
    ii <- which(aq==qid); if (length(ii)) cat("   ANS:", paste(ac[ii], substr(aa[ii],1,40), sep="=", collapse="; "), "\n")
    jj <- which(sqp==qid); if (length(jj)) cat("   SUB:", paste(sqt[jj], substr(sqq[jj],1,80), sep="=", collapse="; "), "\n")
  }
}
