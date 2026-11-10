# Settele (2022, AEJ: Economic Policy) -- reproduction of Tables 3-6 claims
# Translates dofiles 03/04/05 (main survey cleaning, z-scoring, Anderson indices),
# 06 (follow-up cleaning) and 08 (Tables 3, 4, 5, 6) into R.
suppressPackageStartupMessages({library(haven); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-a/mount/settele_2022_gender_wage_gap_beliefs_policy/data"

ch <- function(x) { x <- as.character(x); x[is.na(x)] <- ""; x }
# map "A1".."Ak" -> 1..k, otherwise NA
codeA <- function(x, k) { x <- ch(x); out <- rep(NA_real_, length(x))
  for (i in 1:k) out[x == paste0("A", i)] <- i; out }
num <- function(x) as.numeric(zap_labels(x))

clean_stageI <- function(f, waveB) {
  d <- read_dta(file.path(D, f))
  o <- data.frame(row = seq_len(nrow(d)))
  employ <- codeA(d$employment, 7)
  o$fulltime <- as.numeric(!is.na(employ) & employ == 1)
  o$parttime <- as.numeric(!is.na(employ) & employ == 2)
  o$selfemp <- as.numeric(!is.na(employ) & employ == 3)
  o$unemployed <- as.numeric(!is.na(employ) & employ == 4)
  o$student <- as.numeric(!is.na(employ) & employ == 5)
  region <- codeA(d$region, 4)
  o$midwest <- as.numeric(!is.na(region) & region == 2)
  o$south <- as.numeric(!is.na(region) & region == 3)
  o$west <- as.numeric(!is.na(region) & region == 4)
  age <- codeA(d$agebracket, 5)
  for (i in 1:5) o[[paste0("age", i)]] <- ifelse(is.na(age), NA, as.numeric(age == i))
  hhinc <- codeA(d$hhincbracket, 8)
  cont <- c(6735, 19742, 36701, 61275, 86204, 120686, 170381, 327261)
  o$loghhinc <- log(cont[hhinc])
  g <- ch(d$gender); o$gender <- ifelse(g == "A1", 0, ifelse(g == "A2", 1, NA))
  dr <- ch(d$demrep)
  pol <- ifelse(dr == "A1", -2, ifelse(dr == "A2", -1, ifelse(dr == "A3", 0, ifelse(dr == "A4", 1, ifelse(dr == "A5", 2, NA)))))
  o$otherpol <- as.numeric(dr == "-oth-")
  o$democrat <- as.numeric(!is.na(pol) & pol > 0); o$democrat[o$otherpol == 1] <- 0
  o$indep <- as.numeric(!is.na(pol) & pol == 0); o$indep[o$otherpol == 1] <- 0
  o$rand <- num(d$RAND)
  o$T1 <- ifelse(is.na(o$rand), NA, as.numeric(o$rand == 1))
  r12 <- num(d$RAND12)
  o$prior1 <- as.numeric(!is.na(r12) & r12 == 1)
  o$prior <- ifelse(!is.na(r12) & r12 == 1, num(d$elicitbgendeMarc),
                    ifelse(!is.na(r12) & r12 == 0, num(d$elicitbgendernoinMar), NA))
  r4 <- num(d$RAND4)
  if (!waveB) {
    post <- num(d$extrayoung)
    post[!is.na(r4) & r4 == 10] <- num(d$extraHSS)[!is.na(r4) & r4 == 10]
    post[!is.na(r4) & r4 == 11] <- num(d$extraoccuu)[!is.na(r4) & r4 == 11]
  } else {
    post <- rep(NA_real_, nrow(d))
    post[!is.na(r4) & r4 == 11] <- num(d$extrachild)[!is.na(r4) & r4 == 11]
    post[!is.na(r4) & r4 == 10] <- num(d$extrasame)[!is.na(r4) & r4 == 10]
  }
  o$posterior <- post
  o$large <- codeA(d$manicheckSQ001, 10)
  o$problem <- codeA(d$manicheckSQ002, 10)
  o$govmore <- codeA(d$manicheckSQ003, 10)
  for (v in c("quotaanchor", "AAanchor", "transparencyanchor", "legislationanchor", "childcare"))
    o[[v]] <- codeA(d[[v]], 5)
  if (waveB) { o$UKtool <- o$transparencyanchor; o$transparencyanchor <- NA_real_ } else o$UKtool <- NA_real_
  educ <- codeA(d$demo1, 9)
  o$associatemore <- ifelse(is.na(educ), NA, as.numeric(educ > 4))
  boy <- codeA(d$childrenSQ001, 6) - 1; girl <- codeA(d$childrenSQ002, 6) - 1
  children <- boy + girl
  o$anychildren <- as.numeric(!is.na(children) & children > 0)
  o$wave <- if (waveB) 2 else 1
  o$row <- NULL
  o
}

A <- clean_stageI("SurveyStageI_WaveA_raw.dta", FALSE)
B <- clean_stageI("SurveyStageI_WaveB_raw.dta", TRUE)
S <- rbind(A, B)

# weights for oversampled women (05_SurveyStageIAB_append.do)
S$pweight <- 1
a1 <- !is.na(S$age1) & S$age1 == 1; a5 <- !is.na(S$age5) & S$age5 == 1
g0 <- !is.na(S$gender) & S$gender == 0; g1 <- !is.na(S$gender) & S$gender == 1
S$pweight[S$wave == 2 & g0 & a1] <- 1.4615
S$pweight[S$wave == 2 & g1 & a1] <- 0.6298
S$pweight[S$wave == 2 & g0 & a5] <- 1.0184
S$pweight[S$wave == 2 & g1 & a5] <- 0.8691

# z-score on the pure control group (unweighted, both waves)
ctrl <- !is.na(S$rand) & S$rand == 0
for (v in c("large", "problem", "govmore", "quotaanchor", "AAanchor", "legislationanchor",
            "transparencyanchor", "UKtool", "childcare")) {
  m <- mean(S[[v]][ctrl], na.rm = TRUE); s <- sd(S[[v]][ctrl], na.rm = TRUE)
  S[[v]] <- (S[[v]] - m) / s
}

# Anderson (2008)-style index as in the do-files: weights = row sums of inverse correlation matrix
anderson <- function(M) {
  C <- cor(M, use = "complete.obs")
  w <- rowSums(solve(C))
  list(index = as.vector(as.matrix(M) %*% w) / sum(w), w = w)
}
mi <- anderson(S[, c("large", "problem", "govmore")])
S$z_mani_index <- mi$index
y4 <- ifelse(is.na(S$transparencyanchor), S$UKtool, S$transparencyanchor)
li <- anderson(data.frame(S$quotaanchor, S$AAanchor, S$legislationanchor, y4, S$childcare))
S$z_lmpolicy_index <- li$index
cat("Index weights (perception):", round(mi$w, 6), "\n")
cat("Index weights (policy):", round(li$w, 6), "\n")
cat("Stage I rows:", nrow(S), " control:", sum(ctrl), "\n")

# ---------------- Tables 3 and 4: trimmed pure control group ----------------
C3 <- S[ctrl, ]
C3$prior <- (C3$prior - mean(C3$prior, na.rm = TRUE)) / sd(C3$prior, na.rm = TRUE)
p5 <- quantile(C3$prior, 0.05, type = 2, na.rm = TRUE)
p95 <- quantile(C3$prior, 0.95, type = 2, na.rm = TRUE)
C3 <- C3[!is.na(C3$prior) & C3$prior > p5 & C3$prior < p95, ]
C3$waveB <- as.numeric(C3$wave == 2)

t3a <- feols(z_mani_index ~ waveB + democrat + indep + otherpol + gender, C3, weights = ~pweight, vcov = "hetero")
t3b <- feols(z_mani_index ~ waveB + prior, C3, weights = ~pweight, vcov = "hetero")
t4a <- feols(z_lmpolicy_index ~ waveB + democrat + indep + otherpol + gender, C3, weights = ~pweight, vcov = "hetero")
t4b <- feols(z_lmpolicy_index ~ waveB + prior, C3, weights = ~pweight, vcov = "hetero")
cat("Table 3 N (index non-missing):", sum(!is.na(C3$z_mani_index)), " nobs reg:", nobs(t3a), "\n")
cat("Table 4 N reg:", nobs(t4a), "\n")

# ---------------- Table 5: treatment arms ----------------
controls <- c("wave", "gender", "prior", "democrat", "indep", "otherpol", "midwest", "south", "west",
              "age1", "age2", "age3", "age4", "anychildren", "loghhinc", "associatemore", "fulltime",
              "parttime", "selfemp", "unemployed", "student")
T5 <- S[!is.na(S$rand) & S$rand != 0, ]
# zscore posterior [aweight=pweight]: weighted mean, Stata aweight sd
ok <- !is.na(T5$posterior)
wv <- T5$pweight[ok]; xv <- T5$posterior[ok]
mw <- sum(wv * xv) / sum(wv); n <- length(xv)
sdw <- sqrt(sum(wv * (xv - mw)^2) / sum(wv) * n / (n - 1))
T5$zposterior <- (T5$posterior - mw) / sdw

rhs <- paste(c("T1", controls), collapse = " + ")
f5 <- function(y) feols(as.formula(paste(y, "~", rhs)), T5, weights = ~pweight, vcov = "hetero")
m51 <- f5("posterior"); m52 <- f5("zposterior"); m56 <- f5("z_mani_index")
cat("Table 5 N col1:", nobs(m51), " col6:", nobs(m56), "\n")
fiv <- function(y) feols(as.formula(paste(y, "~", paste(controls, collapse = " + "), "| zposterior ~ T1")),
                         T5, weights = ~pweight, vcov = "hetero")
iv2 <- fiv("AAanchor"); iv3 <- fiv("legislationanchor"); iv7 <- fiv("z_lmpolicy_index")
cat("Table 5 IV N:", nobs(iv2), nobs(iv3), nobs(iv7), "\n")

# ---------------- Table 6: follow-up survey ----------------
FA <- read_dta(file.path(D, "SurveyStageII_WaveA_raw.dta"))
FB <- read_dta(file.path(D, "SurveyStageII_WaveB_raw.dta"))
getc <- function(d, v) if (v %in% names(d)) ch(d[[v]]) else rep("", nrow(d))
getn <- function(d, v) if (v %in% names(d)) num(d[[v]]) else rep(NA_real_, nrow(d))
keepv <- c(controls[controls != "wave"], "rand", "pweight")
mk2 <- function(d, waveB) {
  o <- as.data.frame(lapply(keepv, function(v) getn(d, v))); names(o) <- keepv
  ro <- getn(d, "randorder2")
  pick <- function(sq1, sq2) {
    if (!waveB) return(codeA(getc(d, sq1), 6))
    out <- rep(NA_real_, nrow(d))
    a <- codeA(getc(d, sq1), 6); b <- codeA(getc(d, sq2), 6)
    i1 <- !is.na(ro) & ro == 1; i2 <- !is.na(ro) & ro == 2
    out[i1] <- a[i1]; out[i2] <- b[i2]; out
  }
  o$problemII <- pick("wageproblemSQ002", "wageproblem2SQ002")
  o$problemIIHS <- pick("wageproblemSQ003", "wageproblem2SQ004")
  o$problemIILS <- pick("wageproblemSQ004", "wageproblem2SQ003")
  o$govmoreII <- codeA(getc(d, "govwomen"), 7)
  o$wave <- if (waveB) 2 else 1
  o$wavestr <- ch(d$wave)
  o
}
F2 <- rbind(mk2(FA, FALSE), mk2(FB, TRUE))
cat("Follow-up wave strings:", paste(unique(F2$wavestr)), "\n")
for (v in c("problemII", "govmoreII", "problemIIHS", "problemIILS"))
  F2[[v]] <- (F2[[v]] - mean(F2[[v]], na.rm = TRUE)) / sd(F2[[v]], na.rm = TRUE)
fi <- anderson(F2[, c("problemII", "govmoreII", "problemIIHS", "problemIILS")])
F2$z_maniII_index2 <- fi$index
cat("Index weights (follow-up perception):", round(fi$w, 6), "\n")
F2$T1 <- as.numeric(!is.na(F2$rand) & F2$rand == 1)
T6 <- F2[!(!is.na(F2$rand) & F2$rand == 0), ]
m67 <- feols(as.formula(paste("z_maniII_index2 ~", rhs)), T6, weights = ~pweight, vcov = "hetero")
cat("Table 6 N col7:", nobs(m67), "\n")

res <- c(
  perception_index_democrat_table3_panelA_col4 = unname(coef(t3a)["democrat"]),
  perception_index_female_table3_panelA_col4 = unname(coef(t3a)["gender"]),
  perception_index_prior_table3_panelB_col4 = unname(coef(t3b)["prior"]),
  n_obs_table3 = nobs(t3a),
  policy_demand_index_democrat_table4_panelA_col7 = unname(coef(t4a)["democrat"]),
  policy_demand_index_prior_table4_panelB_col7 = unname(coef(t4b)["prior"]),
  first_stage_posterior_raw_t74_table5_panelA_col1 = unname(coef(m51)["T1"]),
  first_stage_posterior_z_t74_table5_panelA_col2 = unname(coef(m52)["T1"]),
  perception_index_t74_table5_panelA_col6 = unname(coef(m56)["T1"]),
  iv_affirmative_action_posterior_table5_panelC_col2 = unname(coef(iv2)["fit_zposterior"]),
  iv_equal_pay_legislation_posterior_table5_panelC_col3 = unname(coef(iv3)["fit_zposterior"]),
  iv_policy_demand_index_posterior_table5_panelC_col7 = unname(coef(iv7)["fit_zposterior"]),
  followup_perception_index_t74_table6_panelA_col7 = unname(coef(m67)["T1"])
)
for (k in names(res)) cat(sprintf("RESULT:%s=%.6f\n", k, res[[k]]))
