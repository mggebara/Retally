suppressMessages({library(haven); library(dplyr)})
M <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-b/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
A <- read_dta(paste0(M,"SurveyStageI_WaveA_raw.dta")); B <- read_dta(paste0(M,"SurveyStageI_WaveB_raw.dta"))
f <- function(d, w) data.frame(wave=w, RAND=d$RAND, gender=d$gender, age=d$agebracket,
  prior=ifelse(is.na(d$elicitbgendeMarc), d$elicitbgendernoinMar, d$elicitbgendeMarc))
d <- rbind(f(A,"A"), f(B,"B"))
cat("wave B age x gender\n"); print(table(d$age[d$wave=="B"], d$gender[d$wave=="B"]))
c <- d[d$RAND==0,]
cat("control n", nrow(c), "\n")
for (t in 1:9) { q <- quantile(c$prior, c(.05,.95), type=t)
  cat("type", t, "q", q, " incl", sum(c$prior>=q[1] & c$prior<=q[2]), " strict", sum(c$prior>q[1] & c$prior<q[2]),
      " lo-incl/hi-strict", sum(c$prior>=q[1] & c$prior<q[2]), " lo-strict/hi-incl", sum(c$prior>q[1] & c$prior<=q[2]), "\n") }
cat("count prior==50:", sum(c$prior==50), " ==116:", sum(c$prior==116), "\n")
print(table(c$prior[c$prior<=55 | c$prior>=110]))
cat("full-sample quantiles type2:", quantile(d$prior, c(.05,.95), type=2), "\n")
