# Independent reproduction: Settele (2022), AEJ: Economic Policy
# "How Do Beliefs About the Gender Wage Gap Affect the Demand for Public Policy?"
# Tables 3, 4, 5, 6 (selected coefficients), built from the raw LimeSurvey exports.
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-a/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"

A1 <- read_dta(paste0(D, "SurveyStageI_WaveA_raw.dta"))
B1 <- read_dta(paste0(D, "SurveyStageI_WaveB_raw.dta"))
A2 <- read_dta(paste0(D, "SurveyStageII_WaveA_raw.dta"))
B2 <- read_dta(paste0(D, "SurveyStageII_WaveB_raw.dta"))

code_num <- function(x) { x <- as.character(x); x[x == ""] <- NA; as.numeric(sub("^A", "", x)) }
lhh <- c(8.81507301330566, 9.89050388336182, 10.5105590820312, 11.0231275558472,
         11.3644714355469, 11.7009477615356, 12.0457925796509, 12.6985130310059)

build_main <- function(d, wave) {
  emp <- as.character(d$employment); reg <- as.character(d$region); age <- as.character(d$agebracket)
  dr <- as.character(d$demrep)
  edu <- code_num(d$demo1)
  boys <- code_num(d$childrenSQ001); girls <- code_num(d$childrenSQ002)
  post <- if (wave == "A") {
    cbind(young = d$extrayoung, hs = d$extraHSS, occ = d$extraoccuu)
  } else cbind(same = d$extrasame, child = d$extrachild)
  version <- apply(post, 1, function(r) { w <- which(!is.na(r)); if (length(w)) colnames(post)[w[1]] else NA })
  posterior <- apply(post, 1, function(r) { w <- which(!is.na(r)); if (length(w)) r[w[1]] else NA })
  out <- data.frame(
    panelID = d$panelID, wave = wave, waveB = as.numeric(wave == "B"),
    arm = as.numeric(d$RAND),
    female = as.numeric(as.character(d$gender) == "A2"),
    prior = dplyr::coalesce(as.numeric(d$elicitbgendeMarc), as.numeric(d$elicitbgendernoinMar)),
    midwest = as.numeric(reg == "A2"), south = as.numeric(reg == "A3"), west = as.numeric(reg == "A4"),
    age1 = as.numeric(age == "A1"), age2 = as.numeric(age == "A2"), age3 = as.numeric(age == "A3"), age4 = as.numeric(age == "A4"),
    agegrp = age,
    democrat = as.numeric(dr %in% c("A4", "A5")), indep = as.numeric(dr == "A3"), otherpol = as.numeric(dr == "-oth-"),
    loghhinc = lhh[code_num(d$hhincbracket)],
    fulltime = as.numeric(emp == "A1"), parttime = as.numeric(emp == "A2"), selfemp = as.numeric(emp == "A3"),
    unemployed = as.numeric(emp == "A4"), student = as.numeric(emp == "A5"),
    associatemore = as.numeric(edu >= 5),
    anychildren = as.numeric((boys + girls) > 2),  # A1 = 0 children for each
    large = code_num(d$manicheckSQ001), problem = code_num(d$manicheckSQ002), gov = code_num(d$manicheckSQ003),
    quota = code_num(d$quotaanchor), aa = code_num(d$AAanchor), legis = code_num(d$legislationanchor),
    transp = code_num(d$transparencyanchor), childcare = code_num(d$childcare),
    posterior = as.numeric(posterior), version = paste(wave, version),
    stringsAsFactors = FALSE)
  out
}
dat <- bind_rows(build_main(A1, "A"), build_main(B1, "B"))
# probability weights (Appendix G.1): wave B only, age 18-24 and 55-65 by gender
dat$pweight <- 1
dat$pweight[dat$wave == "B" & dat$agegrp == "A1" & dat$female == 1] <- 0.6298
dat$pweight[dat$wave == "B" & dat$agegrp == "A1" & dat$female == 0] <- 1.4615
dat$pweight[dat$wave == "B" & dat$agegrp == "A5" & dat$female == 1] <- 0.8691
dat$pweight[dat$wave == "B" & dat$agegrp == "A5" & dat$female == 0] <- 1.0184
dat$T74 <- as.numeric(dat$arm == 1)
dat$control <- dat$arm == 0
cat("N total:", nrow(dat), " arms:", paste(names(table(dat$arm)), table(dat$arm), collapse = "; "), "\n")

# --- consistency checks against the constructed covariates in the follow-up files
chk <- bind_rows(A2 %>% mutate(wave = "A"), B2 %>% mutate(wave = "B")) %>%
  select(panelID, rand, democrat, indep, otherpol, prior, associatemore, loghhinc, anychildren, pweight, fulltime, student, age1, west) %>%
  inner_join(dat, by = "panelID", suffix = c(".fu", ""))
for (v in c("democrat", "indep", "otherpol", "prior", "associatemore", "loghhinc", "anychildren", "pweight", "fulltime", "student", "age1", "west"))
  cat(sprintf("check %-14s agreement = %.4f\n", v, mean(abs(chk[[paste0(v, ".fu")]] - chk[[v]]) < 1e-3, na.rm = TRUE)))
cat("check arm agreement =", mean(chk$rand == chk$arm), "\n")

# --- z-scoring on the pure control group
zc <- function(x, ref) (x - mean(x[ref], na.rm = TRUE)) / sd(x[ref], na.rm = TRUE)
ctrl <- dat$control
for (v in c("large", "problem", "gov", "quota", "aa", "legis", "childcare")) dat[[paste0("z_", v)]] <- zc(dat[[v]], ctrl)
# wage transparency (wave A) and reporting website (wave B) share one survey slot: standardise per wave
dat$z_transp <- NA_real_
for (w in c("A", "B")) { i <- dat$wave == w; dat$z_transp[i] <- zc(dat$transp[i], ctrl[i]) }
dat$z_transpA <- ifelse(dat$wave == "A", dat$z_transp, NA); dat$z_website <- ifelse(dat$wave == "B", dat$z_transp, NA)

# Anderson (2008) inverse-covariance-weighted index; weights from covariance in reference sample,
# missing components handled by using the available ones; final index re-standardised on reference.
anderson <- function(Z, ref) {
  S <- cov(Z[ref, , drop = FALSE], use = "pairwise.complete.obs")
  W <- solve(S)
  wts <- rowSums(W)
  idx <- apply(Z, 1, function(z) { ok <- !is.na(z); if (!any(ok)) NA else sum(wts[ok] * z[ok]) / sum(wts[ok]) })
  (idx - mean(idx[ref], na.rm = TRUE)) / sd(idx[ref], na.rm = TRUE)
}
dat$perc_index <- anderson(as.matrix(dat[, c("z_large", "z_problem", "z_gov")]), ctrl)
dat$pol_index <- anderson(as.matrix(dat[, c("z_quota", "z_aa", "z_legis", "z_transp", "z_childcare")]), ctrl)

# --- Tables 3 and 4: pure control group, prior strictly inside (p5, p95)
cd <- dat[ctrl, ]
q <- quantile(cd$prior, c(.05, .95), type = 2, na.rm = TRUE)
cat("control n =", nrow(cd), " p5/p95 =", q, "\n")
cat("n strict:", sum(cd$prior > q[1] & cd$prior < q[2]), " n weak:", sum(cd$prior >= q[1] & cd$prior <= q[2]), "\n")
cs <- cd[cd$prior > q[1] & cd$prior < q[2], ]
cs$prior_z <- (cs$prior - mean(cs$prior)) / sd(cs$prior)

t3a <- feols(perc_index ~ democrat + female + indep + otherpol + waveB, data = cs, weights = ~pweight, vcov = "hetero")
t3b <- feols(perc_index ~ prior_z + waveB, data = cs, weights = ~pweight, vcov = "hetero")
t4a <- feols(pol_index ~ democrat + female + indep + otherpol + waveB, data = cs, weights = ~pweight, vcov = "hetero")
t4b <- feols(pol_index ~ prior_z + waveB, data = cs, weights = ~pweight, vcov = "hetero")
for (m in list(t3a, t3b, t4a, t4b)) print(coeftable(m))
# individual columns for diagnostics
for (v in c("z_large", "z_problem", "z_gov", "z_quota", "z_aa", "z_legis", "z_transpA", "z_website", "z_childcare")) {
  m <- feols(as.formula(paste(v, "~ democrat + female + indep + otherpol + waveB")), data = cs, weights = ~pweight, vcov = "hetero")
  m2 <- feols(as.formula(paste(v, "~ prior_z + waveB")), data = cs, weights = ~pweight, vcov = "hetero")
  cat(sprintf("diag T3/4 %-12s dem=%.3f fem=%.3f prior=%.3f n=%d\n", v, coef(m)["democrat"], coef(m)["female"], coef(m2)["prior_z"], nobs(m)))
}

# --- Table 5: treatment arms
td <- dat[!ctrl, ]
# posterior z-scored within statistic version using the pure-control mean and sd
dat$post_z <- NA_real_
for (vv in unique(dat$version)) { i <- dat$version == vv; dat$post_z[i] <- zc(dat$posterior[i], ctrl[i]) }
td <- dat[!ctrl, ]
X <- "female + prior + midwest + south + west + age1 + age2 + age3 + age4 + anychildren + loghhinc + associatemore + fulltime + parttime + selfemp + unemployed + student + democrat + indep + otherpol + waveB"
f5 <- function(y) feols(as.formula(paste(y, "~ T74 +", X)), data = td, weights = ~pweight, vcov = "hetero")
t5_1 <- f5("posterior"); t5_2 <- f5("post_z"); t5_6 <- f5("perc_index")
iv <- function(y) feols(as.formula(paste(y, "~", X, "| post_z ~ T74")), data = td, weights = ~pweight, vcov = "hetero")
t5c_2 <- iv("z_aa"); t5c_3 <- iv("z_legis"); t5c_7 <- iv("pol_index")
for (m in list(t5_1, t5_2, t5_6)) cat(sprintf("diag T5A coef=%.3f se=%.3f n=%d\n", coef(m)["T74"], se(m)["T74"], nobs(m)))
for (m in list(t5c_2, t5c_3, t5c_7)) cat(sprintf("diag T5C coef=%.3f se=%.3f n=%d\n", coef(m)["fit_post_z"], se(m)["fit_post_z"], nobs(m)))
rf <- f5("pol_index"); cat(sprintf("diag T5B pol index RF = %.3f\n", coef(rf)["T74"]))

# --- Table 6: follow-up survey
fa <- A2 %>% transmute(panelID, w_mw = code_num(wageproblemSQ002), w_high = code_num(wageproblemSQ003),
                       w_low = code_num(wageproblemSQ004), govw = code_num(govwomen))
fb <- B2 %>% transmute(panelID,
                       w_mw = coalesce(code_num(wageproblemSQ002), code_num(wageproblem2SQ002)),
                       w_high = coalesce(code_num(wageproblemSQ003), code_num(wageproblem2SQ004)),
                       w_low = coalesce(code_num(wageproblemSQ004), code_num(wageproblem2SQ003)),
                       govw = code_num(govwomen))
fu <- bind_rows(fa, fb) %>% inner_join(dat %>% select(-starts_with("z_")), by = "panelID")
cat("follow-up n =", nrow(fu), " arms:", table(fu$arm), "\n")
allfu <- rep(TRUE, nrow(fu))
for (v in c("w_mw", "govw", "w_high", "w_low")) fu[[paste0("z_", v)]] <- zc(fu[[v]], allfu)
fu$fu_index <- anderson(as.matrix(fu[, c("z_w_mw", "z_govw", "z_w_high", "z_w_low")]), allfu)
t6 <- feols(as.formula(paste("fu_index ~ T74 +", X)), data = fu, weights = ~pweight, vcov = "hetero")
for (v in c("z_w_mw", "z_govw", "z_w_high", "z_w_low")) {
  m <- feols(as.formula(paste(v, "~ T74 +", X)), data = fu, weights = ~pweight, vcov = "hetero")
  cat(sprintf("diag T6 %-8s T74=%.3f n=%d\n", v, coef(m)["T74"], nobs(m)))
}
cat(sprintf("diag T6 index T74=%.3f se=%.3f n=%d\n", coef(t6)["T74"], se(t6)["T74"], nobs(t6)))

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("perception_index_democrat_table3_panelA_col4", coef(t3a)["democrat"])
r("perception_index_female_table3_panelA_col4", coef(t3a)["female"])
r("perception_index_prior_table3_panelB_col4", coef(t3b)["prior_z"])
r("n_obs_table3", nobs(t3a))
r("policy_demand_index_democrat_table4_panelA_col7", coef(t4a)["democrat"])
r("policy_demand_index_prior_table4_panelB_col7", coef(t4b)["prior_z"])
r("first_stage_posterior_raw_t74_table5_panelA_col1", coef(t5_1)["T74"])
r("first_stage_posterior_z_t74_table5_panelA_col2", coef(t5_2)["T74"])
r("perception_index_t74_table5_panelA_col6", coef(t5_6)["T74"])
r("iv_affirmative_action_posterior_table5_panelC_col2", coef(t5c_2)["fit_post_z"])
r("iv_equal_pay_legislation_posterior_table5_panelC_col3", coef(t5c_3)["fit_post_z"])
r("iv_policy_demand_index_posterior_table5_panelC_col7", coef(t5c_7)["fit_post_z"])
r("followup_perception_index_t74_table6_panelA_col7", coef(t6)["T74"])
