# Exploratory: stage II variables and cross-check of stage I covariate construction (no RESULT lines)
suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-c/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
options(width = 250)
desc <- function(d) {
  for (v in names(d)) {
    x <- d[[v]]
    lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
    vl <- attr(x, "labels")
    vls <- if (!is.null(vl)) paste(paste0(vl, "=", names(vl)), collapse="; ") else ""
    x <- zap_labels(x)
    if (is.numeric(x)) {
      u <- sort(unique(x[!is.na(x)]))
      ds <- if (length(u) == 0) "allNA" else if (length(u) <= 12) paste(sapply(u, function(k) paste0(k, ":", sum(x == k, na.rm=TRUE))), collapse=" ") else
        sprintf("n_unique=%d min=%.4g mean=%.4g max=%.4g", length(u), min(u), mean(x, na.rm=TRUE), max(u))
      nna <- sum(is.na(x))
    } else {
      u <- unique(x); ds <- paste0("n_unique=", length(u), " ex: ", paste(head(substr(u,1,30), 6), collapse=" | "))
      nna <- sum(is.na(x) | x == "")
    }
    cat(sprintf("%s NA=%d | %s | %s | %s\n", v, nna, substr(lab,1,60), substr(vls,1,150), substr(ds,1,200)))
  }
}
s2a <- read_dta(paste0(D, "SurveyStageII_WaveA_raw.dta"))
s2b <- read_dta(paste0(D, "SurveyStageII_WaveB_raw.dta"))
cat("=== Stage II A\n"); desc(s2a)
cat("=== Stage II B\n"); desc(s2b)

a <- read_dta(paste0(D, "SurveyStageI_WaveA_raw.dta")) %>% zap_labels()
b <- read_dta(paste0(D, "SurveyStageI_WaveB_raw.dta")) %>% zap_labels()
a$waveB <- 0; b$waveB <- 1
keep <- c("panelID","region","agebracket","gender","demrep","hhincbracket","hhincome","labinc","employment","demo1",
          "childrenSQ001","childrenSQ002","RAND","RAND0","RAND12","elicitbgendeMarc","elicitbgendernoinMar","waveB")
s1 <- bind_rows(a[, keep], b[, keep])
s1 <- s1 %>% mutate(
  prior = coalesce(elicitbgendeMarc, elicitbgendernoinMar),
  female = as.numeric(gender == "A2"),
  democrat = as.numeric(demrep %in% c("A4","A5")),
  republican = as.numeric(demrep %in% c("A1","A2")),
  indep = as.numeric(demrep == "A3"),
  otherpol = as.numeric(!(demrep %in% c("A1","A2","A3","A4","A5"))),
  anych = as.numeric(childrenSQ001 != "A1" | childrenSQ002 != "A1"),
  assoc = as.numeric(demo1 %in% c("A5","A6","A7","A8","A9")),
  inc_mid = c(A1=7500, A2=20000, A3=37500, A4=62500, A5=87500, A6=125000, A7=175000, A8=250000)[hhincbracket]
)
cat("\nStage I N:", nrow(s1), " RAND x wave:\n"); print(table(s1$RAND, s1$waveB))
cat("demrep:\n"); print(table(s1$demrep, s1$waveB))
cat("agebracket x gender wave B:\n"); print(table(s1$agebracket[s1$waveB==1], s1$gender[s1$waveB==1]))
cat("agebracket x gender wave A:\n"); print(table(s1$agebracket[s1$waveB==0], s1$gender[s1$waveB==0]))
cat("prior missing:", sum(is.na(s1$prior)), "\n")
cat("duplicates panelID:", sum(duplicated(s1$panelID)), "\n")

s2 <- bind_rows(zap_labels(s2a) %>% mutate(src="A"), zap_labels(s2b) %>% mutate(src="B"))
m <- inner_join(s2, s1, by = "panelID", suffix = c(".II", ".I"))
cat("\nmerged:", nrow(m), "of", nrow(s2), "\n")
chk <- function(x, y, nm) cat(sprintf("%-12s agree=%d / %d  (NA in y: %d)\n", nm, sum(abs(x - y) < 1e-6, na.rm=TRUE), sum(!is.na(x) & !is.na(y)), sum(is.na(y))))
chk(m$female, m$gender.II, "gender")
chk(m$democrat, m$democrat.II, "democrat")
chk(m$indep, m$indep.II, "indep")
chk(m$otherpol, m$otherpol.II, "otherpol")
chk(m$prior.I, m$prior.II, "prior")
chk(m$waveB, m$wave, "wave(B=1?)")
chk(m$anych, m$anychildren, "anychildren")
chk(m$assoc, m$associatemore, "assocmore")
chk(m$RAND, m$rand, "rand")
chk(as.numeric(m$employment=="A1"), m$fulltime, "fulltime")
chk(as.numeric(m$employment=="A2"), m$parttime, "parttime")
chk(as.numeric(m$employment=="A3"), m$selfemp, "selfemp")
chk(as.numeric(m$employment=="A4"), m$unemployed, "unemployed")
chk(as.numeric(m$employment=="A5"), m$student, "student")
chk(as.numeric(m$region=="A2"), m$midwest, "midwest")
chk(as.numeric(m$region=="A3"), m$south, "south")
chk(as.numeric(m$region=="A4"), m$west, "west")
for (k in 1:4) chk(as.numeric(m$agebracket==paste0("A",k)), m[[paste0("age",k)]], paste0("age",k))
chk(log(m$inc_mid), m$loghhinc, "log inc_mid")
chk(log(m$hhincome), m$loghhinc, "log hhincome")
chk(log(m$hhincome + 1), m$loghhinc, "log hhinc+1")
cat("loghhinc by bracket:\n"); print(m %>% group_by(hhincbracket) %>% summarise(n=n(), mn=min(loghhinc,na.rm=T), mx=max(loghhinc,na.rm=T), mean=mean(loghhinc,na.rm=T), nNA=sum(is.na(loghhinc))))
cat("loghhinc exp sample:\n"); print(head(cbind(m$hhincbracket, m$hhincome, m$labinc, exp(m$loghhinc)), 30))
cat("pweight by wave/age/gender:\n"); print(m %>% group_by(wave, agebracket, gender.II) %>% summarise(n=n(), w=paste(unique(round(pweight,4)), collapse=","), .groups="drop"), n=50)
cat("prior mismatches sample:\n"); print(head(m[abs(m$prior.I - m$prior.II) > 1e-6 | is.na(m$prior.II), c("prior.I","prior.II","elicitbgendeMarc","elicitbgendernoinMar")], 10))
# Control-group prior distribution
ctrl <- s1 %>% filter(RAND == 0)
cat("\ncontrol N:", nrow(ctrl), " prior quantiles:\n"); print(quantile(ctrl$prior, c(.03,.05,.95,.97), type = 2))
