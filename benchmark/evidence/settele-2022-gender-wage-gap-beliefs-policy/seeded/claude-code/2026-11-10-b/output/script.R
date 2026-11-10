# Retally reproduction: Settele (2022), "How Do Beliefs About the Gender Wage Gap
# Affect the Demand for Public Policy?" -- seeded mode.
# Translates the authors' cleaning (03, 04, 05, 06) and Table 3-6 code (08) into R.
suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/seeded/2026-11-10-b/mount/settele_2022_gender_wage_gap_beliefs_policy/data"

num <- function(x) as.numeric(zap_labels(x))
chr <- function(x) { x <- as.character(zap_labels(x)); x[is.na(x)] <- ""; x }
# "A1".."An" -> 1..n, else NA (Stata loops of replace var=i if varstring=="Ai")
code <- function(x, n) {
  x <- chr(x); out <- rep(NA_real_, length(x))
  for (i in seq_len(n)) out[x == paste0("A", i)] <- i
  out
}

stage1_vars <- c("RAND", "RAND12", "RAND4", "elicitbgendeMarc", "elicitbgendernoinMar",
                 "extrayoung", "extraHSS", "extraoccuu", "extrasame", "extrachild",
                 "manicheckSQ001", "manicheckSQ002", "manicheckSQ003",
                 "quotaanchor", "AAanchor", "transparencyanchor", "legislationanchor", "childcare",
                 "region", "agebracket", "gender", "employment", "hhincbracket", "demrep",
                 "demo1", "childrenSQ001", "childrenSQ002")

clean_stage1 <- function(path, wave) {
  r <- read_dta(path, col_select = tidyselect::any_of(stage1_vars))
  d <- data.frame(rand = num(r$RAND))
  # employment
  employ <- code(r$employment, 7)
  d$fulltime   <- as.numeric(employ %in% 1)
  d$parttime   <- as.numeric(employ %in% 2)
  d$selfemp    <- as.numeric(employ %in% 3)
  d$unemployed <- as.numeric(employ %in% 4)
  d$student    <- as.numeric(employ %in% 5)
  # region
  region <- code(r$region, 4)
  d$midwest <- as.numeric(region %in% 2)
  d$south   <- as.numeric(region %in% 3)
  d$west    <- as.numeric(region %in% 4)
  # age group dummies (tab age, gen(age))
  age <- code(r$agebracket, 5)
  for (k in 1:5) d[[paste0("age", k)]] <- ifelse(is.na(age), NA, as.numeric(age == k))
  # household income
  hhinc <- code(r$hhincbracket, 8)
  hhcont <- c(6735, 19742, 36701, 61275, 86204, 120686, 170381, 327261)
  d$loghhinc <- log(hhcont[hhinc])
  # gender
  g <- chr(r$gender)
  d$gender <- ifelse(g == "A1", 0, ifelse(g == "A2", 1, NA))
  # political orientation
  dr <- chr(r$demrep)
  pol <- c(A1 = -2, A2 = -1, A3 = 0, A4 = 1, A5 = 2)[dr]
  d$otherpol   <- as.numeric(dr == "-oth-")
  d$democrat   <- as.numeric(!is.na(pol) & pol > 0)
  d$indep      <- as.numeric(!is.na(pol) & pol == 0)
  d$republican <- as.numeric(!is.na(pol) & pol < 0)
  d$democrat[d$otherpol == 1] <- 0; d$indep[d$otherpol == 1] <- 0; d$republican[d$otherpol == 1] <- 0
  # treatment
  d$T1 <- as.numeric(d$rand == 1)
  # prior belief
  rand12 <- num(r$RAND12)
  d$prior1 <- as.numeric(rand12 == 1)
  d$prior <- ifelse(rand12 == 1, num(r$elicitbgendeMarc),
                    ifelse(rand12 == 0, num(r$elicitbgendernoinMar), NA))
  # posterior belief
  rand4 <- num(r$RAND4)
  if (wave == 1) {
    post <- num(r$extrayoung)
    post[rand4 %in% 10] <- num(r$extraHSS)[rand4 %in% 10]
    post[rand4 %in% 11] <- num(r$extraoccuu)[rand4 %in% 11]
  } else {
    post <- rep(NA_real_, nrow(d))
    post[rand4 %in% 11] <- num(r$extrachild)[rand4 %in% 11]
    post[rand4 %in% 10] <- num(r$extrasame)[rand4 %in% 10]
  }
  d$posterior <- post
  # perceptions
  d$large   <- code(r$manicheckSQ001, 10)
  d$problem <- code(r$manicheckSQ002, 10)
  d$govmore <- code(r$manicheckSQ003, 10)
  # specific policies
  for (v in c("quotaanchor", "AAanchor", "transparencyanchor", "legislationanchor", "childcare"))
    d[[v]] <- code(r[[v]], 5)
  if (wave == 2) {
    d$UKtool <- d$transparencyanchor
    d$transparencyanchor <- NA_real_
  } else {
    d$UKtool <- NA_real_
  }
  # education
  educ <- code(r$demo1, 9)
  d$associatemore <- ifelse(is.na(educ), NA, as.numeric(educ > 4))
  # children
  boy <- code(r$childrenSQ001, 6) - 1
  girl <- code(r$childrenSQ002, 6) - 1
  children <- boy + girl
  d$anychildren <- as.numeric(!is.na(children) & children > 0)
  d$wave <- wave
  d
}

A <- clean_stage1(file.path(base, "SurveyStageI_WaveA_raw.dta"), 1)
B <- clean_stage1(file.path(base, "SurveyStageI_WaveB_raw.dta"), 2)
s1 <- rbind(A, B)
cat("Stage I rows:", nrow(A), nrow(B), nrow(s1), " control:", sum(s1$rand == 0), "\n")

# probability weights (wave B oversampling correction)
s1$pweight <- 1
s1$pweight[s1$wave == 2 & s1$gender == 0 & s1$age1 == 1] <- 1.4615
s1$pweight[s1$wave == 2 & s1$gender == 1 & s1$age1 == 1] <- 0.6298
s1$pweight[s1$wave == 2 & s1$gender == 0 & s1$age5 == 1] <- 1.0184
s1$pweight[s1$wave == 2 & s1$gender == 1 & s1$age5 == 1] <- 0.8691

# z-score on the pure control group (unweighted mean/sd)
zctrl <- function(x, ctrl) (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE)
ctrl <- s1$rand == 0
for (v in c("large", "problem", "govmore", "quotaanchor", "AAanchor", "legislationanchor",
            "transparencyanchor", "UKtool", "childcare"))
  s1[[v]] <- zctrl(s1[[v]], ctrl)

# Anderson (2008)-style index as in the do-files: weights = row sums of the inverse
# correlation matrix (complete cases, full sample, unweighted)
anderson <- function(M) {
  M <- as.matrix(M)
  cc <- complete.cases(M)
  C <- cor(M[cc, , drop = FALSE])
  w <- rowSums(solve(C))
  cat("  index corr obs:", sum(cc), " weights:", round(w, 4), "\n")
  as.vector(M %*% w) / sum(w)
}
s1$z_mani_index <- anderson(s1[, c("large", "problem", "govmore")])
dm4 <- ifelse(is.na(s1$transparencyanchor), s1$UKtool, s1$transparencyanchor)
s1$z_lmpolicy_index <- anderson(cbind(s1$quotaanchor, s1$AAanchor, s1$legislationanchor, dm4, s1$childcare))

# ---------------- Tables 3 and 4: pure control group, trimmed prior ----------------
cg <- s1[s1$rand == 0, ]
cg$prior <- (cg$prior - mean(cg$prior, na.rm = TRUE)) / sd(cg$prior, na.rm = TRUE)
pr <- cg$prior[!is.na(cg$prior)]
p5  <- quantile(pr, 0.05, type = 2, names = FALSE)   # Stata summarize, detail percentiles
p95 <- quantile(pr, 0.95, type = 2, names = FALSE)
cg <- cg[!is.na(cg$prior) & cg$prior > p5 & cg$prior < p95, ]
cat("Table 3 sample:", nrow(cg), "\n")

fA <- function(y, dat) feols(as.formula(paste(y, "~ i(wave) + democrat + indep + otherpol + gender")),
                             data = dat, weights = ~pweight, vcov = "hetero")
fB <- function(y, dat) feols(as.formula(paste(y, "~ i(wave) + prior")),
                             data = dat, weights = ~pweight, vcov = "hetero")
t3A <- fA("z_mani_index", cg)
t3B <- fB("z_mani_index", cg)
t4A <- fA("z_lmpolicy_index", cg)
t4B <- fB("z_lmpolicy_index", cg)
print(coeftable(t3A)); print(coeftable(t3B)); print(coeftable(t4A)); print(coeftable(t4B))
cat("Table 3 nobs:", nobs(t3A), nobs(t3B), " Table 4 nobs:", nobs(t4A), nobs(t4B), "\n")

# ---------------- Table 5: treatment arms ----------------
controls <- c("wave", "gender", "prior", "democrat", "indep", "otherpol", "midwest", "south", "west",
              "age1", "age2", "age3", "age4", "anychildren", "loghhinc", "associatemore",
              "fulltime", "parttime", "selfemp", "unemployed", "student")
ctl <- paste(controls, collapse = " + ")
tr <- s1[s1$rand != 0, ]
# zscore posterior [aweight=pweight]: weighted mean and aweight sd
ok <- !is.na(tr$posterior)
w <- tr$pweight[ok]; x <- tr$posterior[ok]
wm <- sum(w * x) / sum(w)
wsd <- sqrt(sum(w * (x - wm)^2) / sum(w) * length(x) / (length(x) - 1))
tr$zposterior <- (tr$posterior - wm) / wsd

ols5 <- function(y) feols(as.formula(paste(y, "~ T1 +", ctl)), data = tr, weights = ~pweight, vcov = "hetero")
iv5 <- function(y) feols(as.formula(paste(y, "~", ctl, "| zposterior ~ T1")), data = tr,
                         weights = ~pweight, vcov = "hetero")
t5_post  <- ols5("posterior")
t5_zpost <- ols5("zposterior")
t5_mani  <- ols5("z_mani_index")
iv_AA    <- iv5("AAanchor")
iv_leg   <- iv5("legislationanchor")
iv_idx   <- iv5("z_lmpolicy_index")
cat("Table 5 nobs:", nobs(t5_post), nobs(t5_zpost), nobs(t5_mani), nobs(iv_AA), nobs(iv_leg), nobs(iv_idx), "\n")
print(coeftable(t5_post)["T1", ]); print(coeftable(t5_zpost)["T1", ]); print(coeftable(t5_mani)["T1", ])
print(coeftable(iv_AA)["fit_zposterior", ]); print(coeftable(iv_leg)["fit_zposterior", ]); print(coeftable(iv_idx)["fit_zposterior", ])

# ---------------- Table 6: follow-up survey ----------------
s2a <- read_dta(file.path(base, "SurveyStageII_WaveA_raw.dta"))
s2b <- read_dta(file.path(base, "SurveyStageII_WaveB_raw.dta"))
s2vars <- c("wave", "rand", "pweight", "randorder2", "wageproblemSQ002", "wageproblemSQ003",
            "wageproblemSQ004", "wageproblem2SQ002", "wageproblem2SQ003", "wageproblem2SQ004",
            "govwomen", setdiff(controls, "wave"))
pick <- function(df) {
  out <- data.frame(row = seq_len(nrow(df)))
  for (v in s2vars) {
    if (v %in% names(df)) {
      out[[v]] <- if (is.character(df[[v]])) chr(df[[v]]) else num(df[[v]])
    } else out[[v]] <- if (grepl("^wageproblem|^govwomen|^wave$", v)) "" else NA_real_
  }
  out$row <- NULL
  out
}
s2 <- rbind(pick(s2a), pick(s2b))
cat("Follow-up rows:", nrow(s2a), nrow(s2b), nrow(s2), "\n")
wv <- s2$wave
ro <- s2$randorder2
recode6 <- function(a, bro1, bro2) {
  out <- rep(NA_real_, nrow(s2))
  for (i in 1:6) {
    lab <- paste0("A", i)
    out[wv == "B" & bro1 == lab & ro %in% 1] <- i
    out[wv == "B" & bro2 == lab & ro %in% 2] <- i
    out[wv == "A" & a == lab] <- i
  }
  out
}
s2$problemII   <- recode6(s2$wageproblemSQ002, s2$wageproblemSQ002, s2$wageproblem2SQ002)
s2$problemIIHS <- recode6(s2$wageproblemSQ003, s2$wageproblemSQ003, s2$wageproblem2SQ004)
s2$problemIILS <- recode6(s2$wageproblemSQ004, s2$wageproblemSQ004, s2$wageproblem2SQ003)
s2$govmoreII   <- code(s2$govwomen, 7)
zfull <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
for (v in c("problemII", "govmoreII", "problemIIHS", "problemIILS")) s2[[v]] <- zfull(s2[[v]])
s2$wave <- ifelse(wv == "A", 1, ifelse(wv == "B", 2, NA))
s2$T1 <- as.numeric(s2$rand == 1)
s2$z_maniII_index2 <- anderson(s2[, c("problemII", "govmoreII", "problemIIHS", "problemIILS")])
s2t <- s2[s2$rand != 0, ]
t6 <- feols(as.formula(paste("z_maniII_index2 ~ T1 +", ctl)), data = s2t, weights = ~pweight, vcov = "hetero")
cat("Table 6 nobs:", nobs(t6), "\n")
print(coeftable(t6)["T1", ])

# ---------------- RESULTS ----------------
res <- c(
  perception_index_democrat_table3_panelA_col4 = coef(t3A)[["democrat"]],
  perception_index_female_table3_panelA_col4 = coef(t3A)[["gender"]],
  perception_index_prior_table3_panelB_col4 = coef(t3B)[["prior"]],
  n_obs_table3 = nobs(t3A),
  policy_demand_index_democrat_table4_panelA_col7 = coef(t4A)[["democrat"]],
  policy_demand_index_prior_table4_panelB_col7 = coef(t4B)[["prior"]],
  first_stage_posterior_raw_t74_table5_panelA_col1 = coef(t5_post)[["T1"]],
  first_stage_posterior_z_t74_table5_panelA_col2 = coef(t5_zpost)[["T1"]],
  perception_index_t74_table5_panelA_col6 = coef(t5_mani)[["T1"]],
  iv_affirmative_action_posterior_table5_panelC_col2 = coef(iv_AA)[["fit_zposterior"]],
  iv_equal_pay_legislation_posterior_table5_panelC_col3 = coef(iv_leg)[["fit_zposterior"]],
  iv_policy_demand_index_posterior_table5_panelC_col7 = coef(iv_idx)[["fit_zposterior"]],
  followup_perception_index_t74_table6_panelA_col7 = coef(t6)[["T1"]]
)
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
