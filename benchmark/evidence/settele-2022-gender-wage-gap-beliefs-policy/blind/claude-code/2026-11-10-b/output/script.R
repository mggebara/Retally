# Settele (2022) "How Do Beliefs About the Gender Wage Gap Affect the Demand for Public Policy?"
# Independent, blind reproduction of selected Table 3-6 quantities from the raw LimeSurvey exports.
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-b/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
num <- function(x) { x <- as.character(x); x[x == ""] <- NA; suppressWarnings(as.numeric(sub("^A", "", x))) }

# ---------------- Main survey (Stage I), both waves ----------------
build <- function(d, w) {
  d <- zap_labels(d)
  post <- if (w == "A") dplyr::coalesce(d$extrayoung, d$extraHSS, d$extraoccuu) else dplyr::coalesce(d$extrasame, d$extrachild)
  data.frame(panelID = d$panelID, wave = w, waveB = as.numeric(w == "B"),
    RAND = d$RAND,                                   # 0 = pure control, 1 = T74 (ACS), 2 = T94 (CPS)
    prior = ifelse(d$RAND12 == 1, d$elicitbgendeMarc, d$elicitbgendernoinMar),
    posterior = post,
    female = as.numeric(d$gender == "A2"),
    demrep = d$demrep, region = d$region, agebracket = d$agebracket, employment = d$employment,
    hhincbracket = d$hhincbracket, demo1 = num(d$demo1), ch1 = num(d$childrenSQ001), ch2 = num(d$childrenSQ002),
    large = num(d$manicheckSQ001), problem = num(d$manicheckSQ002), gov = num(d$manicheckSQ003),
    quota = num(d$quotaanchor), aa = num(d$AAanchor), transp = num(d$transparencyanchor),
    legis = num(d$legislationanchor), childcare = num(d$childcare), stringsAsFactors = FALSE)
}
m <- rbind(build(read_dta(paste0(D, "SurveyStageI_WaveA_raw.dta")), "A"),
           build(read_dta(paste0(D, "SurveyStageI_WaveB_raw.dta")), "B"))

# Covariates
m <- m %>% mutate(
  democrat = as.numeric(demrep %in% c("A4", "A5")),     # Democrat incl. Independent leaning Democrat
  indep    = as.numeric(demrep == "A3"),
  otherpol = as.numeric(demrep == "-oth-"),             # reference: Republican incl. leaning Republican
  midwest = as.numeric(region == "A2"), south = as.numeric(region == "A3"), west = as.numeric(region == "A4"),
  age1 = as.numeric(agebracket == "A1"), age2 = as.numeric(agebracket == "A2"),
  age3 = as.numeric(agebracket == "A3"), age4 = as.numeric(agebracket == "A4"),   # ref: 55-65
  fulltime = as.numeric(employment == "A1"), parttime = as.numeric(employment == "A2"),
  selfemp = as.numeric(employment == "A3"), unemployed = as.numeric(employment == "A4"),
  student = as.numeric(employment == "A5"),            # ref: retired / out of labor force
  associatemore = as.numeric(demo1 >= 5),              # at least 2-year college degree
  anychildren = as.numeric(ch1 > 1 | ch2 > 1),
  T74 = as.numeric(RAND == 1),
  pweight = case_when(wave == "B" & agebracket == "A1" & female == 1 ~ 0.6298,
                      wave == "B" & agebracket == "A1" & female == 0 ~ 1.4615,
                      wave == "B" & agebracket == "A5" & female == 1 ~ 0.8691,
                      wave == "B" & agebracket == "A5" & female == 0 ~ 1.0184,
                      TRUE ~ 1))

# Follow-up surveys (Stage II) carry the author-coded covariates of follow-up participants;
# use them to obtain the log household income value attached to each income bracket.
s2A <- zap_labels(read_dta(paste0(D, "SurveyStageII_WaveA_raw.dta")))
s2B <- zap_labels(read_dta(paste0(D, "SurveyStageII_WaveB_raw.dta")))
inc_map <- rbind(s2A[, c("panelID", "loghhinc")], s2B[, c("panelID", "loghhinc")]) %>%
  inner_join(m[, c("panelID", "hhincbracket")], by = "panelID") %>%
  group_by(hhincbracket) %>% summarise(loghhinc = first(loghhinc), nval = n_distinct(loghhinc), .groups = "drop")
stopifnot(all(inc_map$nval == 1), nrow(inc_map) == 8)
m <- m %>% left_join(inc_map[, c("hhincbracket", "loghhinc")], by = "hhincbracket")

# ---------------- Standardisation and Anderson (2008) indices ----------------
ctrl <- m$RAND == 0
zc <- function(x, ref) (x - mean(x[ref], na.rm = TRUE)) / sd(x[ref], na.rm = TRUE)
anderson <- function(Z, covrows, refrows) {
  Z <- as.matrix(Z)
  S <- cov(Z[covrows, , drop = FALSE], use = "complete.obs")
  w <- rowSums(solve(S))
  W <- matrix(w, nrow(Z), ncol(Z), byrow = TRUE); W[is.na(Z)] <- 0
  Z0 <- Z; Z0[is.na(Z0)] <- 0
  idx <- rowSums(Z0 * W) / rowSums(W)
  idx[rowSums(!is.na(Z)) == 0] <- NA
  zc(idx, refrows)
}
for (v in c("large", "problem", "gov", "quota", "aa", "legis", "childcare")) m[[paste0("z_", v)]] <- zc(m[[v]], ctrl)
# Wage transparency (wave A) and reporting website (wave B): each z-scored on its own wave's pure
# control group; they occupy the same slot in the policy index because they were never elicited jointly.
m$z_transp <- NA_real_
for (w in c("A", "B")) { r <- m$wave == w; m$z_transp[r] <- zc(m$transp[r], ctrl[r]) }
allrows <- rep(TRUE, nrow(m))
m$perc_index   <- anderson(m[, c("z_large", "z_problem", "z_gov")], allrows, ctrl)
m$policy_index <- anderson(m[, c("z_quota", "z_aa", "z_legis", "z_transp", "z_childcare")], allrows, ctrl)
m$prior_z      <- zc(m$prior, ctrl)
m$posterior_z  <- zc(m$posterior, ctrl)

# ---------------- Tables 3 and 4: trimmed pure control group ----------------
cut <- quantile(m$prior, c(0.05, 0.95), type = 2)   # 5th / 95th percentile of the prior distribution
cat("Trimming cut-offs (prior):", cut, "\n")
cg <- m[ctrl & m$prior > cut[1] & m$prior < cut[2], ]
t3a <- feols(perc_index ~ democrat + female + indep + otherpol + waveB, data = cg, weights = ~pweight, vcov = "hetero")
t3b <- feols(perc_index ~ prior_z + waveB, data = cg, weights = ~pweight, vcov = "hetero")
t4a <- feols(policy_index ~ democrat + female + indep + otherpol + waveB, data = cg, weights = ~pweight, vcov = "hetero")
t4b <- feols(policy_index ~ prior_z + waveB, data = cg, weights = ~pweight, vcov = "hetero")
print(etable(t3a, t3b, t4a, t4b))

# ---------------- Table 5: treatment arms ----------------
ctrls <- "waveB + female + prior + midwest + south + west + age1 + age2 + age3 + age4 + anychildren + loghhinc + associatemore + fulltime + parttime + selfemp + unemployed + student + democrat + indep + otherpol"
tr <- m[m$RAND %in% c(1, 2), ]
f <- function(y) as.formula(paste(y, "~ T74 +", ctrls))
t5_1 <- feols(f("posterior"),   data = tr, weights = ~pweight, vcov = "hetero")
t5_2 <- feols(f("posterior_z"), data = tr, weights = ~pweight, vcov = "hetero")
t5_6 <- feols(f("perc_index"),  data = tr, weights = ~pweight, vcov = "hetero")
iv <- function(y) feols(as.formula(paste(y, "~", ctrls, "| posterior_z ~ T74")), data = tr, weights = ~pweight, vcov = "hetero")
iv_aa <- iv("z_aa"); iv_legis <- iv("z_legis"); iv_idx <- iv("policy_index")
print(etable(t5_1, t5_2, t5_6)); print(etable(iv_aa, iv_legis, iv_idx))
cat("First-stage F (IV):", fitstat(iv_idx, "ivf")[[1]]$stat, "\n")

# ---------------- Table 6: follow-up survey ----------------
fu_vars <- c("panelID", "wave", "rand", "gender", "prior", "midwest", "south", "west", "age1", "age2", "age3", "age4",
             "anychildren", "loghhinc", "associatemore", "fulltime", "parttime", "selfemp", "unemployed", "student",
             "democrat", "indep", "otherpol", "pweight", "govwomen")
fA <- s2A[, fu_vars]; fA$wp_mw <- num(s2A$wageproblemSQ002); fA$wp_high <- num(s2A$wageproblemSQ003); fA$wp_low <- num(s2A$wageproblemSQ004)
fB <- s2B[, fu_vars]
# Wave B: two randomised item orders; in 'wageproblem2' SQ003 = low-skilled and SQ004 = high-skilled.
fB$wp_mw   <- dplyr::coalesce(num(s2B$wageproblemSQ002), num(s2B$wageproblem2SQ002))
fB$wp_high <- dplyr::coalesce(num(s2B$wageproblemSQ003), num(s2B$wageproblem2SQ004))
fB$wp_low  <- dplyr::coalesce(num(s2B$wageproblemSQ004), num(s2B$wageproblem2SQ003))
fu <- rbind(fA, fB)
fu$female <- fu$gender; fu$waveB <- as.numeric(fu$wave == "B"); fu$T74 <- as.numeric(fu$rand == 1)
fu$govw <- num(fu$govwomen)
cat("Follow-up N:", nrow(fu), " missing items:", colSums(is.na(fu[, c("wp_mw", "govw", "wp_high", "wp_low")])), "\n")
allfu <- rep(TRUE, nrow(fu))
for (v in c("wp_mw", "govw", "wp_high", "wp_low")) fu[[paste0("z_", v)]] <- zc(fu[[v]], allfu)
fu$perc_index_fu <- anderson(fu[, c("z_wp_mw", "z_govw", "z_wp_high", "z_wp_low")], allfu, allfu)
t6_7 <- feols(f("perc_index_fu"), data = fu, weights = ~pweight, vcov = "hetero")
print(etable(t6_7))

# ---------------- Results ----------------
r <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))
r("perception_index_democrat_table3_panelA_col4", coef(t3a)[["democrat"]])
r("perception_index_female_table3_panelA_col4", coef(t3a)[["female"]])
r("perception_index_prior_table3_panelB_col4", coef(t3b)[["prior_z"]])
cat(sprintf("RESULT:n_obs_table3=%d\n", nobs(t3a)))
r("policy_demand_index_democrat_table4_panelA_col7", coef(t4a)[["democrat"]])
r("policy_demand_index_prior_table4_panelB_col7", coef(t4b)[["prior_z"]])
r("first_stage_posterior_raw_t74_table5_panelA_col1", coef(t5_1)[["T74"]])
r("first_stage_posterior_z_t74_table5_panelA_col2", coef(t5_2)[["T74"]])
r("perception_index_t74_table5_panelA_col6", coef(t5_6)[["T74"]])
r("iv_affirmative_action_posterior_table5_panelC_col2", coef(iv_aa)[["fit_posterior_z"]])
r("iv_equal_pay_legislation_posterior_table5_panelC_col3", coef(iv_legis)[["fit_posterior_z"]])
r("iv_policy_demand_index_posterior_table5_panelC_col7", coef(iv_idx)[["fit_posterior_z"]])
r("followup_perception_index_t74_table6_panelA_col7", coef(t6_7)[["T74"]])
