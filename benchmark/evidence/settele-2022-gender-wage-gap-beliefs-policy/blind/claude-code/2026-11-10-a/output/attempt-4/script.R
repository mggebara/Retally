# Independent, blind reproduction of Settele (2022, AEJ: Economic Policy),
# "How Do Beliefs About the Gender Wage Gap Affect the Demand for Public Policy?"
# Tables 3-6 selected coefficients, built from the raw LimeSurvey exports.
suppressMessages({library(haven); library(dplyr); library(sandwich); library(lmtest); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-a/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
num <- function(x) as.numeric(sub("^A", "", x))
rd  <- function(f) { d <- read_dta(paste0(D, f)); d[] <- lapply(d, zap_labels); d }

# ------------------------------------------------------------------ main survey
a <- rd("SurveyStageI_WaveA_raw.dta"); b <- rd("SurveyStageI_WaveB_raw.dta")
build <- function(d, w) {
  data.frame(panelID = d$panelID, waveB = as.numeric(w == "B"), RAND = d$RAND,
    female = as.numeric(d$gender == "A2"), demrep = d$demrep, region = d$region,
    agebracket = d$agebracket, hhincbracket = d$hhincbracket, employment = d$employment,
    demo1 = d$demo1, ch1 = d$childrenSQ001, ch2 = d$childrenSQ002,
    prior = ifelse(is.na(d$elicitbgendeMarc), d$elicitbgendernoinMar, d$elicitbgendeMarc),
    large = num(d$manicheckSQ001), problem = num(d$manicheckSQ002), gov = num(d$manicheckSQ003),
    quota = num(d$quotaanchor), aa = num(d$AAanchor), legis = num(d$legislationanchor),
    transp  = if (w == "A") num(d$transparencyanchor) else NA_real_,   # wave A: wage transparency in firms
    website = if (w == "B") num(d$transparencyanchor) else NA_real_,   # wave B: UK-style reporting website
    care = num(d$childcare),
    post = if (w == "A") coalesce(d$extrayoung, d$extraHSS, d$extraoccuu) else coalesce(d$extrasame, d$extrachild),
    stringsAsFactors = FALSE)
}
m <- rbind(build(a, "A"), build(b, "B"))
# covariates (codings verified against the cleaned covariates shipped in the follow-up files)
m <- m %>% mutate(
  control = as.numeric(RAND == 0), T74 = as.numeric(RAND == 1), treated = as.numeric(RAND %in% c(1, 2)),
  democrat = as.numeric(demrep %in% c("A4", "A5")), indep = as.numeric(demrep == "A3"),
  otherpol = as.numeric(demrep == "-oth-"),
  midwest = as.numeric(region == "A2"), south = as.numeric(region == "A3"), west = as.numeric(region == "A4"),
  age1 = as.numeric(agebracket == "A1"), age2 = as.numeric(agebracket == "A2"),
  age3 = as.numeric(agebracket == "A3"), age4 = as.numeric(agebracket == "A4"),
  anychildren = as.numeric(!(ch1 == "A1" & ch2 == "A1")),
  associatemore = as.numeric(demo1 %in% c("A5", "A6", "A7", "A8", "A9")),
  fulltime = as.numeric(employment == "A1"), parttime = as.numeric(employment == "A2"),
  selfemp = as.numeric(employment == "A3"), unemployed = as.numeric(employment == "A4"),
  student = as.numeric(employment == "A5"),
  loghhinc = c(A1 = 8.81507301330566, A2 = 9.89050388336182, A3 = 10.5105590820312, A4 = 11.0231275558472,
               A5 = 11.3644714355469, A6 = 11.7009477615356, A7 = 12.0457925796509, A8 = 12.6985130310059)[hhincbracket],
  pweight = case_when(waveB == 1 & agebracket == "A1" & female == 1 ~ 0.6298,
                      waveB == 1 & agebracket == "A1" & female == 0 ~ 1.4615,
                      waveB == 1 & agebracket == "A5" & female == 1 ~ 0.8691,
                      waveB == 1 & agebracket == "A5" & female == 0 ~ 1.0184,
                      TRUE ~ 1))

zc <- function(x, ref) (x - mean(x[ref], na.rm = TRUE)) / sd(x[ref], na.rm = TRUE)
# Anderson (2008) summary index: inverse-covariance weighted mean of the z-scored items
# (weights = row sums of the inverted covariance matrix; missing items skipped),
# re-standardised on the reference group.  Covariances are pairwise; pairs never
# observed together (wave-A-only vs wave-B-only items) are set to zero.
anderson <- function(Z, ref) {
  S <- cov(Z, use = "pairwise.complete.obs"); S[is.na(S)] <- 0
  w <- rowSums(solve(S))
  W <- matrix(w, nrow(Z), ncol(Z), byrow = TRUE); W[is.na(Z)] <- 0
  idx <- rowSums(W * ifelse(is.na(Z), 0, Z)) / rowSums(W)
  cat("index weights:", paste(colnames(Z), round(w, 4), sep = "=", collapse = " "), "\n")
  zc(idx, ref)
}
ctl <- m$control == 1
# z-score qualitative outcomes on the pure control group (transparency / website on the
# control group of the wave in which each was elicited)
for (v in c("large", "problem", "gov", "quota", "aa", "legis", "transp", "website", "care"))
  m[[paste0(v, "_z")]] <- zc(m[[v]], ctl)
m$perc_index   <- anderson(as.matrix(m[, c("large_z", "problem_z", "gov_z")]), ctl)
m$policy_index <- anderson(as.matrix(m[, c("quota_z", "aa_z", "legis_z", "transp_z", "website_z", "care_z")]), ctl)
m$prior_z <- zc(m$prior, ctl)
m$post_z  <- zc(m$post, ctl)

rob <- function(fit, v) { ct <- coeftest(fit, vcov = vcovHC(fit, type = "HC1")); ct[v, ] }

# ------------------------------------------------------------- Tables 3 and 4
p <- quantile(m$prior, c(.05, .95), type = 2)
cat("prior cutoffs (5th/95th pct of prior distribution):", p, "\n")
t3 <- m[ctl & m$prior > p[1] & m$prior < p[2], ]
cat("Table 3/4 sample:", nrow(t3), "\n")
f3a <- lm(perc_index ~ democrat + female + indep + otherpol + waveB, data = t3, weights = pweight)
f3b <- lm(perc_index ~ prior_z + waveB, data = t3, weights = pweight)
f4a <- lm(policy_index ~ democrat + female + indep + otherpol + waveB, data = t3, weights = pweight)
f4b <- lm(policy_index ~ prior_z + waveB, data = t3, weights = pweight)
for (r in list(rob(f3a, "democrat"), rob(f3a, "female"), rob(f3b, "prior_z"), rob(f4a, "democrat"), rob(f4b, "prior_z")))
  cat(sprintf("  coef %.4f se %.4f\n", r[1], r[2]))

# ------------------------------------------------------------------- Table 5
ctrl <- "female + midwest + south + west + age1 + age2 + age3 + age4 + anychildren + loghhinc + associatemore + fulltime + parttime + selfemp + unemployed + student + prior + waveB + democrat + indep + otherpol"
tr <- m[m$treated == 1, ]
cat("Table 5 sample:", nrow(tr), " with posterior:", sum(!is.na(tr$post)), "\n")
f5_1 <- lm(as.formula(paste("post ~ T74 +", ctrl)), data = tr, weights = pweight)
f5_2 <- lm(as.formula(paste("post_z ~ T74 +", ctrl)), data = tr, weights = pweight)
f5_6 <- lm(as.formula(paste("perc_index ~ T74 +", ctrl)), data = tr, weights = pweight)
iv <- function(y) feols(as.formula(paste(y, "~", ctrl, "| post_z ~ T74")), data = tr, weights = ~pweight, vcov = "hetero")
i2 <- iv("aa_z"); i3 <- iv("legis_z"); i7 <- iv("policy_index")
for (r in list(rob(f5_1, "T74"), rob(f5_2, "T74"), rob(f5_6, "T74"))) cat(sprintf("  coef %.4f se %.4f\n", r[1], r[2]))
for (f in list(i2, i3, i7)) cat(sprintf("  IV coef %.4f se %.4f N %d\n", coef(f)["fit_post_z"], se(f)["fit_post_z"], nobs(f)))

# ------------------------------------------------------------------- Table 6
s2a <- rd("SurveyStageII_WaveA_raw.dta"); s2b <- rd("SurveyStageII_WaveB_raw.dta")
fa <- data.frame(panelID = s2a$panelID, wp_mw = num(s2a$wageproblemSQ002), wp_hi = num(s2a$wageproblemSQ003),
                 wp_lo = num(s2a$wageproblemSQ004), govw = num(s2a$govwomen))
o1 <- s2b$randorder2 == 1   # wageproblem: SQ003 high-skilled, SQ004 low-skilled; wageproblem2 swaps them
fb <- data.frame(panelID = s2b$panelID,
                 wp_mw = num(ifelse(o1, s2b$wageproblemSQ002, s2b$wageproblem2SQ002)),
                 wp_hi = num(ifelse(o1, s2b$wageproblemSQ003, s2b$wageproblem2SQ004)),
                 wp_lo = num(ifelse(o1, s2b$wageproblemSQ004, s2b$wageproblem2SQ003)),
                 govw = num(s2b$govwomen))
fu <- merge(rbind(fa, fb), m[, setdiff(names(m), c("perc_index"))], by = "panelID")
cat("follow-up sample:", nrow(fu), " treated:", sum(fu$treated), "\n")
all_fu <- rep(TRUE, nrow(fu))
for (v in c("wp_mw", "govw", "wp_hi", "wp_lo")) fu[[paste0(v, "_z")]] <- zc(fu[[v]], all_fu)
fu$fu_index <- anderson(as.matrix(fu[, c("wp_mw_z", "govw_z", "wp_hi_z", "wp_lo_z")]), all_fu)
f6 <- lm(as.formula(paste("fu_index ~ T74 +", ctrl)), data = fu, weights = pweight)
r6 <- rob(f6, "T74"); cat(sprintf("  coef %.4f se %.4f N %d\n", r6[1], r6[2], nobs(f6)))

out <- c(
  perception_index_democrat_table3_panelA_col4 = unname(coef(f3a)["democrat"]),
  perception_index_female_table3_panelA_col4 = unname(coef(f3a)["female"]),
  perception_index_prior_table3_panelB_col4 = unname(coef(f3b)["prior_z"]),
  n_obs_table3 = nobs(f3a),
  policy_demand_index_democrat_table4_panelA_col7 = unname(coef(f4a)["democrat"]),
  policy_demand_index_prior_table4_panelB_col7 = unname(coef(f4b)["prior_z"]),
  first_stage_posterior_raw_t74_table5_panelA_col1 = unname(coef(f5_1)["T74"]),
  first_stage_posterior_z_t74_table5_panelA_col2 = unname(coef(f5_2)["T74"]),
  perception_index_t74_table5_panelA_col6 = unname(coef(f5_6)["T74"]),
  iv_affirmative_action_posterior_table5_panelC_col2 = unname(coef(i2)["fit_post_z"]),
  iv_equal_pay_legislation_posterior_table5_panelC_col3 = unname(coef(i3)["fit_post_z"]),
  iv_policy_demand_index_posterior_table5_panelC_col7 = unname(coef(i7)["fit_post_z"]),
  followup_perception_index_t74_table6_panelA_col7 = unname(coef(f6)["T74"]))
cat("DEVIATION: Table 3/4 trimming uses the 5th/95th percentiles of the full main-survey prior distribution (the cutoffs the paper's appendix states), not the control group's own percentiles.\n")
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
