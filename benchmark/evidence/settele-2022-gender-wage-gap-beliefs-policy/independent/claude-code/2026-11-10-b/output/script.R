# Independent reproduction: Settele (2022), "How Do Beliefs About the Gender Wage Gap
# Affect the Demand for Public Policy?" -- Tables 3, 4, 5 and 6 (selected entries).
# Built from the raw LimeSurvey exports (Stage I = main survey, Stage II = follow-up).
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
M <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-b/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
num <- function(x) { x <- as.character(x); x[x == ""] <- NA; suppressWarnings(as.numeric(sub("^A", "", x))) }

A <- read_dta(paste0(M, "SurveyStageI_WaveA_raw.dta"))
B <- read_dta(paste0(M, "SurveyStageI_WaveB_raw.dta"))

build <- function(d, w) {
  post <- if (w == "A") cbind(d$extrayoung, d$extraHSS, d$extraoccuu) else cbind(d$extrasame, d$extrachild)
  postver <- apply(!is.na(post), 1, function(r) if (any(r)) which(r)[1] else NA)
  data.frame(
    panelID = d$panelID, waveB = as.numeric(w == "B"),
    RAND = d$RAND,
    prior = ifelse(is.na(d$elicitbgendeMarc), d$elicitbgendernoinMar, d$elicitbgendeMarc),
    posterior = apply(post, 1, function(r) if (all(is.na(r))) NA else r[!is.na(r)][1]),
    postver = ifelse(is.na(postver), NA, paste0(w, postver)),
    female = as.numeric(d$gender == "A2"),
    agecat = num(d$agebracket),
    region = num(d$region),
    demrep = as.character(d$demrep),
    emp = num(d$employment),
    edu = num(d$demo1),
    inc = num(d$hhincbracket),
    kids = as.numeric(num(d$childrenSQ001) > 1 | num(d$childrenSQ002) > 1),
    large = num(d$manicheckSQ001), problem = num(d$manicheckSQ002), gov = num(d$manicheckSQ003),
    quota = num(d$quotaanchor), aa = num(d$AAanchor), transp = num(d$transparencyanchor),
    legis = num(d$legislationanchor), childcare = num(d$childcare),
    stringsAsFactors = FALSE)
}
D <- rbind(build(A, "A"), build(B, "B"))

# covariates (codings verified against the constructed variables in the Stage II files)
D <- D %>% mutate(
  democrat = as.numeric(demrep %in% c("A4", "A5")),
  indep    = as.numeric(demrep == "A3"),
  otherpol = as.numeric(demrep == "-oth-"),
  midwest = as.numeric(region == 2), south = as.numeric(region == 3), west = as.numeric(region == 4),
  age1 = as.numeric(agecat == 1), age2 = as.numeric(agecat == 2), age3 = as.numeric(agecat == 3), age4 = as.numeric(agecat == 4),
  fulltime = as.numeric(emp == 1), parttime = as.numeric(emp == 2), selfemp = as.numeric(emp == 3),
  unemployed = as.numeric(emp == 4), student = as.numeric(emp == 5),
  associatemore = as.numeric(edu >= 5),
  loghhinc = c(8.81507301330566, 9.89050388336182, 10.5105590820312, 11.0231275558472,
               11.3644714355469, 11.7009477615356, 12.0457925796509, 12.6985130310059)[inc],
  anychildren = kids,
  T74 = ifelse(RAND == 1, 1, ifelse(RAND == 2, 0, NA)),
  control = as.numeric(RAND == 0),
  # probability weights (Appendix G.1): wave B, ages 18-24 and 55-65
  pweight = case_when(waveB == 1 & agecat == 1 & female == 1 ~ 0.6298,
                      waveB == 1 & agecat == 1 & female == 0 ~ 1.4615,
                      waveB == 1 & agecat == 5 & female == 1 ~ 0.8691,
                      waveB == 1 & agecat == 5 & female == 0 ~ 1.0184,
                      TRUE ~ 1))

# z-score on the pure control group
zc <- function(x, ctrl) (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE)
ctrl <- D$control == 1
for (v in c("large", "problem", "gov", "quota", "aa", "legis", "childcare")) D[[paste0("z_", v)]] <- zc(D[[v]], ctrl)
# wage transparency (wave A) and reporting website (wave B): z-scored within wave on the control group
D$z_transp <- NA
for (wb in 0:1) { s <- D$waveB == wb; D$z_transp[s] <- zc(D$transp[s], ctrl[s]) }
D$z_transpA <- ifelse(D$waveB == 0, D$z_transp, NA)
D$z_websiteB <- ifelse(D$waveB == 1, D$z_transp, NA)

# Anderson (2008) summary index: inverse-covariance weighted average of standardized items
anderson <- function(Z) {
  Z <- as.matrix(Z)
  S <- cov(Z, use = "pairwise.complete.obs")
  w <- rowSums(solve(S))
  apply(Z, 1, function(z) { k <- !is.na(z); if (!any(k)) NA else sum(w[k] * z[k]) / sum(w[k]) })
}
D$perc_index <- anderson(D[, c("z_large", "z_problem", "z_gov")])
D$pol_index  <- anderson(D[, c("z_quota", "z_aa", "z_legis", "z_transp", "z_childcare")])

# prior z-scored within the pure control group
D$prior_z <- zc(D$prior, ctrl)
# posterior: raw (0-200) and z-scored on the pure control group
# The posterior (pooled across the five randomly assigned wage statistics) is z-scored using the
# mean and SD of the treatment-arm sample (the sample in which it is used as the endogenous regressor).
trt <- D$RAND %in% c(1, 2)
D$posterior_z <- zc(D$posterior, trt)
cat("Posterior SD diagnostics: control pooled", sd(D$posterior[ctrl], na.rm = TRUE),
    "; treatment arms", sd(D$posterior[trt], na.rm = TRUE), "; full sample", sd(D$posterior, na.rm = TRUE), "\n")

## ---------------- Tables 3 and 4: trimmed pure control group ----------------
C <- D[ctrl, ]
q <- quantile(C$prior, c(0.05, 0.95))
C <- C[C$prior > q[1] & C$prior < q[2], ]
cat(sprintf("Control group: %d; trimmed (prior strictly between p5=%g and p95=%g): %d\n", sum(ctrl), q[1], q[2], nrow(C)))

pA <- function(y) feols(as.formula(paste(y, "~ democrat + female + indep + otherpol + waveB")), data = C, weights = ~pweight, vcov = "hetero")
pB <- function(y) feols(as.formula(paste(y, "~ prior_z + waveB")), data = C, weights = ~pweight, vcov = "hetero")
t3A <- pA("perc_index"); t3B <- pB("perc_index")
t4A <- pA("pol_index");  t4B <- pB("pol_index")
cat("\nTable 3 col 4 Panel A:\n"); print(coeftable(t3A)); cat("Table 3 col 4 Panel B:\n"); print(coeftable(t3B))
cat("\nTable 4 col 7 Panel A:\n"); print(coeftable(t4A)); cat("Table 4 col 7 Panel B:\n"); print(coeftable(t4B))
for (y in c("z_large", "z_problem", "z_gov")) { cat("T3 col item", y, ": Dem", round(coef(pA(y))["democrat"], 3), " Fem", round(coef(pA(y))["female"], 3), " Prior", round(coef(pB(y))["prior_z"], 3), "\n") }

## ---------------- Table 5: treatment arms ----------------
X <- "female + midwest + south + west + age1 + age2 + age3 + age4 + anychildren + loghhinc + associatemore + fulltime + parttime + selfemp + unemployed + student + prior + waveB + democrat + indep + otherpol"
Tr <- D[!is.na(D$T74), ]
cat("\nTreatment arms N:", nrow(Tr), " with posterior:", sum(!is.na(Tr$posterior)), "\n")
ols5 <- function(y, dat = Tr) feols(as.formula(paste(y, "~ T74 +", X)), data = dat, weights = ~pweight, vcov = "hetero")
iv5  <- function(y, dat = Tr) feols(as.formula(paste(y, "~", X, "| posterior_z ~ T74")), data = dat, weights = ~pweight, vcov = "hetero")
fs1 <- ols5("posterior"); fs2 <- ols5("posterior_z"); p6 <- ols5("perc_index")
cat("T5 A1:\n"); print(coeftable(fs1)["T74", ]); cat("N", nobs(fs1), "\n")
cat("T5 A2:\n"); print(coeftable(fs2)["T74", ]); cat("N", nobs(fs2), "\n")
cat("T5 A6:\n"); print(coeftable(p6)["T74", ]); cat("N", nobs(p6), "\n")
iv2 <- iv5("z_aa"); iv3 <- iv5("z_legis"); iv7 <- iv5("pol_index")
cat("T5 C2:\n"); print(coeftable(iv2)["fit_posterior_z", ]); cat("N", nobs(iv2), "\n")
cat("T5 C3:\n"); print(coeftable(iv3)["fit_posterior_z", ]); cat("N", nobs(iv3), "\n")
cat("T5 C7:\n"); print(coeftable(iv7)["fit_posterior_z", ]); cat("N", nobs(iv7), "\n")
for (y in c("z_large", "z_problem", "z_gov", "z_quota", "z_aa", "z_legis", "z_transpA", "z_websiteB", "z_childcare", "pol_index"))
  cat("T5 reduced form", y, ":", round(coef(ols5(y))["T74"], 3), "\n")

## ---------------- Table 6: follow-up survey ----------------
A2 <- read_dta(paste0(M, "SurveyStageII_WaveA_raw.dta"))
B2 <- read_dta(paste0(M, "SurveyStageII_WaveB_raw.dta"))
co <- function(a, b) { a <- as.character(a); b <- as.character(b); ifelse(is.na(a) | a == "", b, a) }
fu <- function(d, w) {
  wp2 <- if (w == "B") co(d$wageproblemSQ002, d$wageproblem2SQ002) else d$wageproblemSQ002
  wp3 <- if (w == "B") co(d$wageproblemSQ003, d$wageproblem2SQ003) else d$wageproblemSQ003
  wp4 <- if (w == "B") co(d$wageproblemSQ004, d$wageproblem2SQ004) else d$wageproblemSQ004
  data.frame(T74 = as.numeric(d$rand == 1), waveB = as.numeric(w == "B"),
             female = as.numeric(zap_labels(d$gender)), midwest = d$midwest, south = d$south, west = d$west,
             age1 = d$age1, age2 = d$age2, age3 = d$age3, age4 = d$age4, anychildren = d$anychildren,
             loghhinc = d$loghhinc, associatemore = d$associatemore, fulltime = d$fulltime, parttime = d$parttime,
             selfemp = d$selfemp, unemployed = d$unemployed, student = d$student, prior = d$prior,
             democrat = d$democrat, indep = d$indep, otherpol = d$otherpol, pweight = d$pweight,
             problem = num(wp2), govwomen = num(d$govwomen), probhigh = num(wp3), problow = num(wp4))
}
F <- rbind(fu(A2, "A"), fu(B2, "B"))
zf <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
for (v in c("problem", "govwomen", "probhigh", "problow")) F[[paste0("z_", v)]] <- zf(F[[v]])
F$fu_index <- anderson(F[, c("z_problem", "z_govwomen", "z_probhigh", "z_problow")])
t6 <- feols(as.formula(paste("fu_index ~ T74 +", X)), data = F, weights = ~pweight, vcov = "hetero")
cat("\nFollow-up N:", nrow(F), "\nT6 A7:\n"); print(coeftable(t6)[c("T74", "female", "democrat"), ]); cat("N", nobs(t6), "\n")
for (y in c("z_problem", "z_govwomen", "z_probhigh", "z_problow")) cat("T6 item", y, ":", round(coef(feols(as.formula(paste(y, "~ T74 +", X)), data = F, weights = ~pweight))["T74"], 3), "\n")

## ---------------- RESULTS ----------------
r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("perception_index_democrat_table3_panelA_col4", coef(t3A)["democrat"])
r("perception_index_female_table3_panelA_col4", coef(t3A)["female"])
r("perception_index_prior_table3_panelB_col4", coef(t3B)["prior_z"])
r("n_obs_table3", nobs(t3A))
r("policy_demand_index_democrat_table4_panelA_col7", coef(t4A)["democrat"])
r("policy_demand_index_prior_table4_panelB_col7", coef(t4B)["prior_z"])
r("first_stage_posterior_raw_t74_table5_panelA_col1", coef(fs1)["T74"])
r("first_stage_posterior_z_t74_table5_panelA_col2", coef(fs2)["T74"])
r("perception_index_t74_table5_panelA_col6", coef(p6)["T74"])
r("iv_affirmative_action_posterior_table5_panelC_col2", coef(iv2)["fit_posterior_z"])
r("iv_equal_pay_legislation_posterior_table5_panelC_col3", coef(iv3)["fit_posterior_z"])
r("iv_policy_demand_index_posterior_table5_panelC_col7", coef(iv7)["fit_posterior_z"])
r("followup_perception_index_t74_table6_panelA_col7", coef(t6)["T74"])
