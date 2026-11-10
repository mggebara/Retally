# Independent reproduction: Settele (2022), "How Do Beliefs About the Gender Wage Gap
# Affect the Demand for Public Policy?" -- Tables 3, 4, 5 and 6 (selected entries).
# Built from the raw LimeSurvey exports; variable construction follows the paper text
# and the survey files (.lss) shipped in the package.
suppressMessages({
  library(haven); library(dplyr); library(fixest); library(sandwich); library(lmtest)
})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-d/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"

num <- function(x) suppressWarnings(as.numeric(sub("^A", "", as.character(x))))
strip <- function(d) { d[] <- lapply(d, function(x) { attributes(x) <- NULL; x }); d }

a <- strip(read_dta(paste0(D, "SurveyStageI_WaveA_raw.dta")))
b <- strip(read_dta(paste0(D, "SurveyStageI_WaveB_raw.dta")))

# log household income: midpoints of the income brackets (values as used in the cleaned
# covariates carried in the follow-up files, which map one-to-one onto hhincbracket)
loginc_map <- c(A1 = 8.81507301330566, A2 = 9.89050388336182, A3 = 10.5105590820312,
                A4 = 11.0231275558472, A5 = 11.3644714355469, A6 = 11.7009477615356,
                A7 = 12.0457925796509, A8 = 12.6985130310059)

build <- function(d, w) {
  post <- if (w == "A") coalesce(d$extrayoung, d$extraHSS, d$extraoccuu) else coalesce(d$extrasame, d$extrachild)
  postver <- if (w == "A") ifelse(!is.na(d$extrayoung), "young", ifelse(!is.na(d$extraHSS), "hs", ifelse(!is.na(d$extraoccuu), "occ", NA)))
             else ifelse(!is.na(d$extrasame), "same", ifelse(!is.na(d$extrachild), "child", NA))
  data.frame(
    panelID = d$panelID, wave = w, waveB = as.numeric(w == "B"),
    RAND = d$RAND,
    prior = coalesce(d$elicitbgendeMarc, d$elicitbgendernoinMar),
    posterior = post, postver = postver,
    female = as.numeric(d$gender == "A2"),
    democrat = as.numeric(d$demrep %in% c("A4", "A5")),
    indep = as.numeric(d$demrep == "A3"),
    otherpol = as.numeric(d$demrep == "-oth-"),
    agebr = d$agebracket,
    midwest = as.numeric(d$region == "A2"), south = as.numeric(d$region == "A3"), west = as.numeric(d$region == "A4"),
    age1 = as.numeric(d$agebracket == "A1"), age2 = as.numeric(d$agebracket == "A2"),
    age3 = as.numeric(d$agebracket == "A3"), age4 = as.numeric(d$agebracket == "A4"),
    fulltime = as.numeric(d$employment == "A1"), parttime = as.numeric(d$employment == "A2"),
    selfemp = as.numeric(d$employment == "A3"), unemployed = as.numeric(d$employment == "A4"),
    student = as.numeric(d$employment == "A5"),
    associatemore = as.numeric(num(d$demo1) >= 5),
    anychildren = as.numeric(!(d$childrenSQ001 == "A1" & d$childrenSQ002 == "A1")),
    loghhinc = unname(loginc_map[as.character(d$hhincbracket)]),
    large = num(d$manicheckSQ001), problem = num(d$manicheckSQ002), gov = num(d$manicheckSQ003),
    quota = num(d$quotaanchor), aa = num(d$AAanchor), legis = num(d$legislationanchor),
    transp = if (w == "A") num(d$transparencyanchor) else NA_real_,
    website = if (w == "B") num(d$transparencyanchor) else NA_real_,
    childcare = num(d$childcare),
    stringsAsFactors = FALSE)
}
m <- bind_rows(build(a, "A"), build(b, "B"))
m$ctrl <- m$RAND == 0
m$treat <- m$RAND %in% c(1, 2)
m$T74 <- as.numeric(m$RAND == 1)   # RAND==1: ACS-based high-wage-gap information (N=1,531)

# probability weights (Appendix G): wave B, ages 18-24 and 55-65
m$pweight <- 1
m$pweight[m$wave == "B" & m$agebr == "A1" & m$female == 1] <- 0.6298
m$pweight[m$wave == "B" & m$agebr == "A1" & m$female == 0] <- 1.4615
m$pweight[m$wave == "B" & m$agebr == "A5" & m$female == 1] <- 0.8691
m$pweight[m$wave == "B" & m$agebr == "A5" & m$female == 0] <- 1.0184

cat("N main:", nrow(m), " control:", sum(m$ctrl), " T74:", sum(m$RAND == 1), " T94:", sum(m$RAND == 2), "\n")

# ---- z-scoring on the pure control group (unweighted mean / sd) ----
zc <- function(x, ref) (x - mean(x[ref], na.rm = TRUE)) / sd(x[ref], na.rm = TRUE)
for (v in c("large", "problem", "gov", "quota", "aa", "legis", "childcare")) m[[paste0(v, "_z")]] <- zc(m[[v]], m$ctrl)
m$transp_z <- zc(m$transp, m$ctrl & m$wave == "A")
m$website_z <- zc(m$website, m$ctrl & m$wave == "B")
m$transpweb_z <- coalesce(m$transp_z, m$website_z)  # wave A: transparency within firms; wave B: reporting website
m$prior_z <- zc(m$prior, m$ctrl)
# posterior: standardized over all respondents with a posterior (zscore-style, full sample)
m$posterior_z <- zc(m$posterior, rep(TRUE, nrow(m)))
cat("posterior sd: full", sd(m$posterior, na.rm = TRUE), " treated", sd(m$posterior[m$treat], na.rm = TRUE), "\n")
cat("control posterior mean/sd:", mean(m$posterior[m$ctrl], na.rm = TRUE), sd(m$posterior[m$ctrl], na.rm = TRUE), "\n")

# ---- Anderson (2008) summary index ----
# inputs: z-scored outcomes; weights = row sums of the inverse covariance matrix of the
# standardized outcomes; the index is the weighted mean (not re-standardized).
anderson <- function(Z, ref) {
  Z <- as.matrix(Z)
  S <- cov(Z, use = "pairwise.complete.obs")
  w <- rowSums(solve(S))
  idx <- apply(Z, 1, function(z) { ok <- !is.na(z); if (!any(ok)) NA else sum(w[ok] * z[ok]) / sum(w[ok]) })
  idx
}
m$perc_index <- anderson(m[, c("large_z", "problem_z", "gov_z")], m$ctrl)
m$policy_index <- anderson(m[, c("quota_z", "aa_z", "legis_z", "transpweb_z", "childcare_z")], m$ctrl)

coefrob <- function(fit, term) {
  V <- vcovHC(fit, type = "HC1")
  c(est = unname(coef(fit)[term]), se = sqrt(V[term, term]))
}

# ---- Tables 3 and 4: trimmed pure control group ----
p <- quantile(m$prior[m$ctrl], c(0.05, 0.95), type = 2)  # pure control group's prior distribution
cat("prior cutoffs (control group):", p, " full sample:", quantile(m$prior, c(.05, .95), type = 2), "\n")
c3 <- m %>% filter(ctrl, prior > p[1], prior < p[2])
cat("N trimmed control:", nrow(c3), "\n")

t3a <- lm(perc_index ~ democrat + female + indep + otherpol + waveB, data = c3, weights = pweight)
t3b <- lm(perc_index ~ prior_z + waveB, data = c3, weights = pweight)
t4a <- lm(policy_index ~ democrat + female + indep + otherpol + waveB, data = c3, weights = pweight)
t4b <- lm(policy_index ~ prior_z + waveB, data = c3, weights = pweight)
r <- list()
r$perception_index_democrat_table3_panelA_col4 <- coefrob(t3a, "democrat")
r$perception_index_female_table3_panelA_col4 <- coefrob(t3a, "female")
r$perception_index_prior_table3_panelB_col4 <- coefrob(t3b, "prior_z")
r$policy_demand_index_democrat_table4_panelA_col7 <- coefrob(t4a, "democrat")
r$policy_demand_index_prior_table4_panelB_col7 <- coefrob(t4b, "prior_z")
cat("N check t3a/t3b/t4a/t4b:", nobs(t3a), nobs(t3b), nobs(t4a), nobs(t4b), "\n")

# ---- Table 5: treatment arms ----
ctrls <- "female + midwest + south + west + age1 + age2 + age3 + age4 + anychildren + loghhinc + associatemore + fulltime + parttime + selfemp + unemployed + student + prior + waveB + democrat + indep + otherpol"
tr <- m %>% filter(treat)
f5 <- function(y) lm(as.formula(paste(y, "~ T74 +", ctrls)), data = tr, weights = pweight)
t5_1 <- f5("posterior"); t5_2 <- f5("posterior_z"); t5_6 <- f5("perc_index")
r$first_stage_posterior_raw_t74_table5_panelA_col1 <- coefrob(t5_1, "T74")
r$first_stage_posterior_z_t74_table5_panelA_col2 <- coefrob(t5_2, "T74")
r$perception_index_t74_table5_panelA_col6 <- coefrob(t5_6, "T74")
cat("N t5 col1/col6:", nobs(t5_1), nobs(t5_6), "\n")

iv <- function(y) feols(as.formula(paste(y, "~", ctrls, "| posterior_z ~ T74")), data = tr, weights = ~pweight, vcov = "hetero")
for (nm in list(c("iv_affirmative_action_posterior_table5_panelC_col2", "aa_z"),
                c("iv_equal_pay_legislation_posterior_table5_panelC_col3", "legis_z"),
                c("iv_policy_demand_index_posterior_table5_panelC_col7", "policy_index"))) {
  fit <- iv(nm[2])
  r[[nm[1]]] <- c(est = unname(coef(fit)["fit_posterior_z"]), se = unname(se(fit)["fit_posterior_z"]))
  cat("N", nm[1], nobs(fit), "\n")
}

# ---- Table 6: follow-up survey (treated respondents who completed it) ----
fa <- strip(read_dta(paste0(D, "SurveyStageII_WaveA_raw.dta")))
fb <- strip(read_dta(paste0(D, "SurveyStageII_WaveB_raw.dta")))
fu <- bind_rows(
  data.frame(panelID = fa$panelID, wp_mw = num(fa$wageproblemSQ002), wp_hs = num(fa$wageproblemSQ003),
             wp_ls = num(fa$wageproblemSQ004), govwomen = num(fa$govwomen), stringsAsFactors = FALSE),
  # wave B: two randomized item orders; in wageproblem2 SQ003 = low-skilled, SQ004 = high-skilled
  data.frame(panelID = fb$panelID,
             wp_mw = coalesce(num(fb$wageproblemSQ002), num(fb$wageproblem2SQ002)),
             wp_hs = coalesce(num(fb$wageproblemSQ003), num(fb$wageproblem2SQ004)),
             wp_ls = coalesce(num(fb$wageproblemSQ004), num(fb$wageproblem2SQ003)),
             govwomen = num(fb$govwomen), stringsAsFactors = FALSE))
fu <- inner_join(fu, m %>% select(panelID, RAND, T74, pweight, female, midwest, south, west, age1, age2, age3, age4,
                                  anychildren, loghhinc, associatemore, fulltime, parttime, selfemp, unemployed,
                                  student, prior, waveB, democrat, indep, otherpol), by = "panelID")
cat("N follow-up matched:", nrow(fu), " arms:", table(fu$RAND), "\n")
allf <- rep(TRUE, nrow(fu))
for (v in c("wp_mw", "govwomen", "wp_hs", "wp_ls")) fu[[paste0(v, "_z")]] <- zc(fu[[v]], allf)
fu$fu_perc_index <- anderson(fu[, c("wp_mw_z", "govwomen_z", "wp_hs_z", "wp_ls_z")], allf)
t6 <- lm(as.formula(paste("fu_perc_index ~ T74 +", ctrls)), data = fu, weights = pweight)
r$followup_perception_index_t74_table6_panelA_col7 <- coefrob(t6, "T74")
cat("N t6:", nobs(t6), "\n")

cat("\nEstimates (robust SE):\n")
for (n in names(r)) cat(sprintf("  %-55s %8.4f (%.4f)\n", n, r[[n]]["est"], r[[n]]["se"]))
cat("\n")
for (n in names(r)) cat(sprintf("RESULT:%s=%.6f\n", n, r[[n]]["est"]))
cat(sprintf("RESULT:n_obs_table3=%d\n", nobs(t3a)))
