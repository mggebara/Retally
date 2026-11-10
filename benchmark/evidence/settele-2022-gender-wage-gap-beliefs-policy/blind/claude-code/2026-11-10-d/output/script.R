# Independent, blind reproduction of Settele (2022), "How Do Beliefs About the Gender Wage Gap
# Affect the Demand for Public Policy?" -- Tables 3, 4, 5 and 6 (selected entries).
# Built from the raw LimeSurvey exports; codes mapped with the survey instruments (.lss) and
# the constructed covariates in the follow-up files.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})

D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-d/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
A <- read_dta(paste0(D, "SurveyStageI_WaveA_raw.dta")); A$wave <- "A"
B <- read_dta(paste0(D, "SurveyStageI_WaveB_raw.dta")); B$wave <- "B"
keep <- c("panelID","wave","RAND0","RAND","RAND12","region","agebracket","gender","demrep","hhincbracket","employment",
          "elicitbgendeMarc","elicitbgendernoinMar","manicheckSQ001","manicheckSQ002","manicheckSQ003",
          "quotaanchor","AAanchor","legislationanchor","transparencyanchor","childcare",
          "demo1","childrenSQ001","childrenSQ002")
pv <- c("extrayoung","extraHSS","extraoccuu","extrasame","extrachild")
for (v in pv) { if (!v %in% names(A)) A[[v]] <- NA_real_; if (!v %in% names(B)) B[[v]] <- NA_real_ }
M <- bind_rows(zap_labels(A[, c(keep, pv)]), zap_labels(B[, c(keep, pv)]))

code <- function(x) { x <- as.character(x); x[x == ""] <- NA; as.numeric(sub("^A", "", x)) }

# ---- covariates --------------------------------------------------------------------------
M <- M %>% mutate(
  waveB    = as.numeric(wave == "B"),
  female   = as.numeric(gender == "A2"),
  democrat = as.numeric(demrep %in% c("A4","A5")),      # Democrat incl. Indep. leaning Dem.
  indep    = as.numeric(demrep == "A3"),
  otherpol = as.numeric(demrep == "-oth-"),             # Republican incl. leaning Rep. = reference
  midwest  = as.numeric(region == "A2"), south = as.numeric(region == "A3"), west = as.numeric(region == "A4"),
  age1 = as.numeric(agebracket == "A1"), age2 = as.numeric(agebracket == "A2"),
  age3 = as.numeric(agebracket == "A3"), age4 = as.numeric(agebracket == "A4"),
  anychildren = as.numeric(childrenSQ001 != "A1" | childrenSQ002 != "A1"),
  associatemore = as.numeric(code(demo1) >= 5),
  fulltime = as.numeric(employment == "A1"), parttime = as.numeric(employment == "A2"),
  selfemp = as.numeric(employment == "A3"), unemployed = as.numeric(employment == "A4"),
  student = as.numeric(employment == "A5"),
  prior = ifelse(!is.na(elicitbgendeMarc), elicitbgendeMarc, elicitbgendernoinMar),
  posterior = coalesce(extrayoung, extraHSS, extraoccuu, extrasame, extrachild),
  control = as.numeric(RAND == 0), T74 = as.numeric(RAND == 1)
)
lhh <- c(8.81507301330566, 9.89050388336182, 10.5105590820312, 11.0231275558472,
         11.3644714355469, 11.7009477615356, 12.0457925796509, 12.6985130310059)
M$loghhinc <- lhh[code(M$hhincbracket)]
# probability weights (Wave B: gender x age-bracket cells; Wave A: 1) -- mapping read off the
# pweight variable shipped in the follow-up files
M$pweight <- 1
M$pweight[M$waveB == 1 & M$female == 1 & M$agebracket == "A1"] <- 0.629800021648407
M$pweight[M$waveB == 1 & M$female == 1 & M$agebracket == "A5"] <- 0.869099974632263
M$pweight[M$waveB == 1 & M$female == 0 & M$agebracket == "A1"] <- 1.46150004863739
M$pweight[M$waveB == 1 & M$female == 0 & M$agebracket == "A5"] <- 1.01839995384216

# ---- outcomes ----------------------------------------------------------------------------
M <- M %>% mutate(
  large = code(manicheckSQ001), problem = code(manicheckSQ002), govmore = code(manicheckSQ003),
  quota = code(quotaanchor), affact = code(AAanchor), equalpay = code(legislationanchor),
  transp = ifelse(wave == "A", code(transparencyanchor), NA),   # wage transparency within firms (A)
  website = ifelse(wave == "B", code(transparencyanchor), NA),  # reporting website (B)
  childc = code(childcare)
)
zs <- function(x, ref) (x - mean(x[ref], na.rm = TRUE)) / sd(x[ref], na.rm = TRUE)
ctrl <- M$control == 1
for (v in c("large","problem","govmore","quota","affact","equalpay","transp","website","childc","posterior","prior"))
  M[[paste0(v, "_z")]] <- zs(M[[v]], ctrl)

# Anderson (2008) summary index: inverse-covariance weighted mean of the z-scored items
# (weights = row sums of the inverted covariance matrix, missing items skipped), then
# standardized on the reference group.
anderson <- function(Z, ref) {
  Z <- as.matrix(Z)
  S <- cov(Z, use = "pairwise.complete.obs"); S[is.na(S)] <- 0   # items never jointly observed
  w <- rowSums(solve(S))
  ok <- !is.na(Z); Z0 <- Z; Z0[!ok] <- 0
  idx <- as.vector(Z0 %*% w) / as.vector(ok %*% w)
  idx[rowSums(ok) == 0] <- NA
  (idx - mean(idx[ref], na.rm = TRUE)) / sd(idx[ref], na.rm = TRUE)
}
M$perc_index <- anderson(M[, c("large_z","problem_z","govmore_z")], ctrl)
M$pol_index  <- anderson(M[, c("quota_z","affact_z","equalpay_z","transp_z","website_z","childc_z")], ctrl)

# ---- Tables 3 and 4: trimmed pure control group --------------------------------------------
C <- M[ctrl, ]
p5 <- quantile(C$prior, 0.05, type = 2); p95 <- quantile(C$prior, 0.95, type = 2)
CT <- C[C$prior > p5 & C$prior < p95, ]
cat("Control group N:", nrow(C), " trimming cut-offs:", p5, p95, " trimmed N:", nrow(CT), "\n")

t3a <- feols(perc_index ~ democrat + female + indep + otherpol + waveB, data = CT, weights = ~pweight, vcov = "hetero")
t3b <- feols(perc_index ~ prior_z + waveB, data = CT, weights = ~pweight, vcov = "hetero")
t4a <- feols(pol_index ~ democrat + female + indep + otherpol + waveB, data = CT, weights = ~pweight, vcov = "hetero")
t4b <- feols(pol_index ~ prior_z + waveB, data = CT, weights = ~pweight, vcov = "hetero")
print(etable(t3a, t3b, t4a, t4b, se.below = TRUE))

# ---- Table 5: treatment arms ---------------------------------------------------------------
X <- "female + midwest + south + west + age1 + age2 + age3 + age4 + anychildren + loghhinc + associatemore + fulltime + parttime + selfemp + unemployed + student + prior + waveB + democrat + indep + otherpol"
TR <- M[M$control == 0, ]
cat("Treatment-arm N:", nrow(TR), " with posterior:", sum(!is.na(TR$posterior)), "\n")
fs1 <- feols(as.formula(paste("posterior ~ T74 +", X)), data = TR, weights = ~pweight, vcov = "hetero")
fs2 <- feols(as.formula(paste("posterior_z ~ T74 +", X)), data = TR, weights = ~pweight, vcov = "hetero")
t5p <- feols(as.formula(paste("perc_index ~ T74 +", X)), data = TR, weights = ~pweight, vcov = "hetero")
iv  <- function(y) feols(as.formula(paste(y, "~", X, "| posterior_z ~ T74")), data = TR, weights = ~pweight, vcov = "hetero")
iv_aa <- iv("affact_z"); iv_ep <- iv("equalpay_z"); iv_ix <- iv("pol_index")
print(etable(fs1, fs2, t5p, keep = "T74", se.below = TRUE))
print(etable(iv_aa, iv_ep, iv_ix, keep = "posterior", se.below = TRUE))
cat("First-stage F (posterior_z on T74):", fitstat(iv_ix, "ivf")[[1]]$stat, "\n")

# ---- Table 6: follow-up sample ---------------------------------------------------------------
FA <- zap_labels(read_dta(paste0(D, "SurveyStageII_WaveA_raw.dta")))
FB <- zap_labels(read_dta(paste0(D, "SurveyStageII_WaveB_raw.dta")))
FA <- FA %>% mutate(fu_problem = code(wageproblemSQ002), fu_high = code(wageproblemSQ003), fu_low = code(wageproblemSQ004))
# Wave B: two randomized orderings; in "wageproblem2" sub-items 3/4 are low-/high-skilled (swapped)
FB <- FB %>% mutate(
  fu_problem = ifelse(randorder2 == 1, code(wageproblemSQ002), code(wageproblem2SQ002)),
  fu_high    = ifelse(randorder2 == 1, code(wageproblemSQ003), code(wageproblem2SQ004)),
  fu_low     = ifelse(randorder2 == 1, code(wageproblemSQ004), code(wageproblem2SQ003)))
FU <- bind_rows(FA, FB) %>% mutate(fu_gov = code(govwomen), T74 = as.numeric(rand == 1), waveB = as.numeric(wave == "B"),
                                   female = gender)
allfu <- rep(TRUE, nrow(FU))
for (v in c("fu_problem","fu_gov","fu_high","fu_low")) FU[[paste0(v, "_z")]] <- zs(FU[[v]], allfu)
FU$fu_index <- anderson(FU[, c("fu_problem_z","fu_gov_z","fu_high_z","fu_low_z")], allfu)
cat("Follow-up N:", nrow(FU), "\n")
t6 <- feols(as.formula(paste("fu_index ~ T74 +", X)), data = FU, weights = ~pweight, vcov = "hetero")
print(etable(t6, keep = "T74", se.below = TRUE))

# ---- results -------------------------------------------------------------------------------
out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))
out("perception_index_democrat_table3_panelA_col4", coef(t3a)[["democrat"]])
out("perception_index_female_table3_panelA_col4", coef(t3a)[["female"]])
out("perception_index_prior_table3_panelB_col4", coef(t3b)[["prior_z"]])
cat(sprintf("RESULT:n_obs_table3=%d\n", nobs(t3a)))
out("policy_demand_index_democrat_table4_panelA_col7", coef(t4a)[["democrat"]])
out("policy_demand_index_prior_table4_panelB_col7", coef(t4b)[["prior_z"]])
out("first_stage_posterior_raw_t74_table5_panelA_col1", coef(fs1)[["T74"]])
out("first_stage_posterior_z_t74_table5_panelA_col2", coef(fs2)[["T74"]])
out("perception_index_t74_table5_panelA_col6", coef(t5p)[["T74"]])
out("iv_affirmative_action_posterior_table5_panelC_col2", coef(iv_aa)[["fit_posterior_z"]])
out("iv_equal_pay_legislation_posterior_table5_panelC_col3", coef(iv_ep)[["fit_posterior_z"]])
out("iv_policy_demand_index_posterior_table5_panelC_col7", coef(iv_ix)[["fit_posterior_z"]])
out("followup_perception_index_t74_table6_panelA_col7", coef(t6)[["T74"]])
