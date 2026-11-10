# Independent reproduction: Settele (2022) "How Do Beliefs About the Gender Wage Gap Affect
# the Demand for Public Policy?"  Tables 3, 4, 5 and 6 (selected coefficients).
# Built from the raw LimeSurvey exports; answer codes decoded with the .lss survey files.
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/independent/2026-11-10-c/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"
options(width = 200)

num_code <- function(x) { x <- as.character(x); x[x == ""] <- NA; as.numeric(sub("^A", "", x)) }

# ---------------------------------------------------------------- main survey (stage I)
a <- read_dta(paste0(D, "SurveyStageI_WaveA_raw.dta")) %>% zap_labels() %>% mutate(waveB = 0)
b <- read_dta(paste0(D, "SurveyStageI_WaveB_raw.dta")) %>% zap_labels() %>% mutate(waveB = 1)
a <- a %>% mutate(posterior = coalesce(extrayoung, extraHSS, extraoccuu),
                  post_version = case_when(!is.na(extrayoung) ~ "young", !is.na(extraHSS) ~ "hs", !is.na(extraoccuu) ~ "occ"))
b <- b %>% mutate(posterior = coalesce(extrasame, extrachild),
                  post_version = case_when(!is.na(extrasame) ~ "same", !is.na(extrachild) ~ "child"))
keep <- c("panelID","waveB","region","agebracket","gender","demrep","hhincbracket","employment","demo1",
          "childrenSQ001","childrenSQ002","RAND","elicitbgendeMarc","elicitbgendernoinMar",
          "manicheckSQ001","manicheckSQ002","manicheckSQ003",
          "quotaanchor","AAanchor","transparencyanchor","legislationanchor","childcare","posterior","post_version")
s1 <- bind_rows(a[, keep], b[, keep])

s1 <- s1 %>% mutate(
  prior      = coalesce(elicitbgendeMarc, elicitbgendernoinMar),
  control    = as.numeric(RAND == 0),
  T74        = as.numeric(RAND == 1),            # RAND0 1-4 -> ACS ($74) information
  female     = as.numeric(gender == "A2"),
  democrat   = as.numeric(demrep %in% c("A4","A5")),   # incl. independents leaning Democrat
  indep      = as.numeric(demrep == "A3"),
  otherpol   = as.numeric(!(demrep %in% c("A1","A2","A3","A4","A5"))),
  midwest    = as.numeric(region == "A2"), south = as.numeric(region == "A3"), west = as.numeric(region == "A4"),
  age1 = as.numeric(agebracket == "A1"), age2 = as.numeric(agebracket == "A2"),
  age3 = as.numeric(agebracket == "A3"), age4 = as.numeric(agebracket == "A4"),
  anychildren   = as.numeric(childrenSQ001 != "A1" | childrenSQ002 != "A1"),
  associatemore = as.numeric(demo1 %in% c("A5","A6","A7","A8","A9")),
  fulltime   = as.numeric(employment == "A1"), parttime = as.numeric(employment == "A2"),
  selfemp    = as.numeric(employment == "A3"), unemployed = as.numeric(employment == "A4"),
  student    = as.numeric(employment == "A5"),
  # probability weights (Appendix G.1): wave B, age 18-24 and 55-65 cells
  pweight = case_when(waveB == 1 & agebracket == "A1" & gender == "A2" ~ 0.6298,
                      waveB == 1 & agebracket == "A1" & gender == "A1" ~ 1.4615,
                      waveB == 1 & agebracket == "A5" & gender == "A2" ~ 0.8691,
                      waveB == 1 & agebracket == "A5" & gender == "A1" ~ 1.0184,
                      TRUE ~ 1),
  large = num_code(manicheckSQ001), problem = num_code(manicheckSQ002), govmit = num_code(manicheckSQ003),
  quota = num_code(quotaanchor), aa = num_code(AAanchor), legis = num_code(legislationanchor),
  transp = ifelse(waveB == 0, num_code(transparencyanchor), NA),
  website = ifelse(waveB == 1, num_code(transparencyanchor), NA),
  childc = num_code(childcare)
)

# ---------------------------------------------------------------- follow-up survey (stage II)
s2a <- read_dta(paste0(D, "SurveyStageII_WaveA_raw.dta")) %>% zap_labels()
s2b <- read_dta(paste0(D, "SurveyStageII_WaveB_raw.dta")) %>% zap_labels()
s2a <- s2a %>% mutate(fu_problem = num_code(wageproblemSQ002), fu_high = num_code(wageproblemSQ003),
                      fu_low = num_code(wageproblemSQ004))
s2b <- s2b %>% mutate(fu_problem = ifelse(randorder2 == 1, num_code(wageproblemSQ002), num_code(wageproblem2SQ002)),
                      fu_high    = ifelse(randorder2 == 1, num_code(wageproblemSQ003), num_code(wageproblem2SQ004)),
                      fu_low     = ifelse(randorder2 == 1, num_code(wageproblemSQ004), num_code(wageproblem2SQ003)))
s2 <- bind_rows(s2a, s2b) %>% mutate(fu_govwomen = num_code(govwomen))
names(s2) <- trimws(names(s2))
s2 <- s2[, !duplicated(names(s2))]

# log household income: per-bracket values as used in the package's follow-up files
mm <- inner_join(s2 %>% select(panelID, loghhinc), s1 %>% select(panelID, hhincbracket), by = "panelID")
incmap <- mm %>% group_by(hhincbracket) %>% summarise(v = mean(loghhinc), nv = n_distinct(round(loghhinc, 6)), .groups = "drop")
cat("Income bracket -> log income map:\n"); print(as.data.frame(incmap))
s1$loghhinc <- incmap$v[match(s1$hhincbracket, incmap$hhincbracket)]

# ---------------------------------------------------------------- standardisation helpers
zc <- function(x, ref) (x - mean(x[ref], na.rm = TRUE)) / sd(x[ref], na.rm = TRUE)
# Anderson (2008) summary index: weights = row sums of the inverse covariance matrix of the
# standardised inputs; weighted mean over non-missing inputs.
anderson <- function(Z) {
  Z <- as.matrix(Z)
  S <- cov(Z, use = "pairwise.complete.obs")
  w <- rowSums(solve(S))
  num <- apply(Z, 1, function(r) sum(w * r, na.rm = TRUE))
  den <- apply(Z, 1, function(r) sum(w[!is.na(r)]))
  cat("  index weights:", paste(names(w), round(w / sum(w), 3), collapse = " "), "\n")
  out <- num / den; out[den == 0] <- NA; out
}

ctl <- s1$control == 1
s1 <- s1 %>% mutate(
  prior_z = zc(prior, ctl),
  posterior_z = zc(posterior, ctl),
  large_z = zc(large, ctl), problem_z = zc(problem, ctl), govmit_z = zc(govmit, ctl),
  quota_z = zc(quota, ctl), aa_z = zc(aa, ctl), legis_z = zc(legis, ctl),
  transp_z = zc(transp, ctl & waveB == 0), website_z = zc(website, ctl & waveB == 1),
  childc_z = zc(childc, ctl),
  transpweb_z = coalesce(transp_z, website_z)
)
cat("Perception index (main survey):\n")
s1$perc_index <- anderson(s1[, c("large_z","problem_z","govmit_z")])
cat("Policy demand index (main survey; wage transparency (A) / reporting website (B) share one slot):\n")
s1$policy_index <- anderson(s1[, c("quota_z","aa_z","legis_z","transpweb_z","childc_z")])

# ---------------------------------------------------------------- Tables 3 and 4: trimmed pure control group
cg <- s1 %>% filter(control == 1)
p <- quantile(cg$prior, c(0.05, 0.95), type = 2)
cat("Control-group prior 5th/95th percentiles:", p, "\n")
t3 <- cg %>% filter(prior > p[1], prior < p[2])
cat("Table 3/4 sample N:", nrow(t3), "\n")

m3a <- feols(perc_index ~ democrat + female + indep + otherpol + waveB, data = t3, weights = ~pweight, vcov = "hetero")
m3b <- feols(perc_index ~ prior_z + waveB, data = t3, weights = ~pweight, vcov = "hetero")
m4a <- feols(policy_index ~ democrat + female + indep + otherpol + waveB, data = t3, weights = ~pweight, vcov = "hetero")
m4b <- feols(policy_index ~ prior_z + waveB, data = t3, weights = ~pweight, vcov = "hetero")

# ---------------------------------------------------------------- Table 5: treatment arms
ctrls <- "female + midwest + south + west + age1 + age2 + age3 + age4 + anychildren + loghhinc + associatemore + fulltime + parttime + selfemp + unemployed + student + prior + waveB + democrat + indep + otherpol"
tr <- s1 %>% filter(RAND > 0)
cat("Treatment sample N:", nrow(tr), " with posterior:", sum(!is.na(tr$posterior)), "\n")
f <- function(y) as.formula(paste(y, "~ T74 +", ctrls))
m5_1 <- feols(f("posterior"), data = tr, weights = ~pweight, vcov = "hetero")
m5_2 <- feols(f("posterior_z"), data = tr, weights = ~pweight, vcov = "hetero")
m5_6 <- feols(f("perc_index"), data = tr, weights = ~pweight, vcov = "hetero")
iv <- function(y) feols(as.formula(paste(y, "~", ctrls, "| posterior_z ~ T74")), data = tr, weights = ~pweight, vcov = "hetero")
m5c_2 <- iv("aa_z"); m5c_3 <- iv("legis_z"); m5c_7 <- iv("policy_index")

# ---------------------------------------------------------------- Table 6: follow-up sample
fu <- s2 %>% mutate(T74 = as.numeric(rand == 1), female = gender, waveB = as.numeric(wave == "B"))
cat("Follow-up N:", nrow(fu), " T74:", sum(fu$T74), "\n")
allfu <- rep(TRUE, nrow(fu))
fu <- fu %>% mutate(fu_problem_z = zc(fu_problem, allfu), fu_govwomen_z = zc(fu_govwomen, allfu),
                    fu_high_z = zc(fu_high, allfu), fu_low_z = zc(fu_low, allfu))
cat("Follow-up perception index:\n")
fu$fu_perc_index <- anderson(fu[, c("fu_problem_z","fu_govwomen_z","fu_high_z","fu_low_z")])
m6 <- feols(as.formula(paste("fu_perc_index ~ T74 +", ctrls)), data = fu, weights = ~pweight, vcov = "hetero")

# ---------------------------------------------------------------- diagnostics (not scored)
tryCatch({
  chkm <- inner_join(fu %>% select(panelID, prior, democrat, indep, otherpol, female, pweight, associatemore, anychildren),
                     s1 %>% select(panelID, prior, democrat, indep, otherpol, female, pweight, associatemore, anychildren),
                     by = "panelID", suffix = c(".fu", ".s1"))
  for (v in c("prior","democrat","indep","otherpol","female","pweight","associatemore","anychildren"))
    cat(sprintf("check %-14s agree %d / %d\n", v, sum(abs(chkm[[paste0(v, ".fu")]] - chkm[[paste0(v, ".s1")]]) < 1e-3, na.rm = TRUE), nrow(chkm)))
  cat("Table 5 N (posterior, index):", nobs(m5_1), nobs(m5_6), " IV N:", nobs(m5c_7), " Table 6 N:", nobs(m6), "\n")
  cat("First-stage F (IV):", fitstat(m5c_7, "ivf")[[1]]$stat, "\n")
}, error = function(e) cat("diagnostic error:", conditionMessage(e), "\n"))

etable(m3a, m3b, m4a, m4b, se.below = TRUE)
etable(m5_1, m5_2, m5_6, keep = "T74", se.below = TRUE)
etable(m5c_2, m5c_3, m5c_7, keep = "posterior", se.below = TRUE)
etable(m6, keep = "T74", se.below = TRUE)

# ---------------------------------------------------------------- results
r <- function(nm, v) cat(sprintf("RESULT:%s=%.6f\n", nm, v))
r("perception_index_democrat_table3_panelA_col4", coef(m3a)[["democrat"]])
r("perception_index_female_table3_panelA_col4", coef(m3a)[["female"]])
r("perception_index_prior_table3_panelB_col4", coef(m3b)[["prior_z"]])
r("n_obs_table3", nobs(m3a))
r("policy_demand_index_democrat_table4_panelA_col7", coef(m4a)[["democrat"]])
r("policy_demand_index_prior_table4_panelB_col7", coef(m4b)[["prior_z"]])
r("first_stage_posterior_raw_t74_table5_panelA_col1", coef(m5_1)[["T74"]])
r("first_stage_posterior_z_t74_table5_panelA_col2", coef(m5_2)[["T74"]])
r("perception_index_t74_table5_panelA_col6", coef(m5_6)[["T74"]])
r("iv_affirmative_action_posterior_table5_panelC_col2", coef(m5c_2)[["fit_posterior_z"]])
r("iv_equal_pay_legislation_posterior_table5_panelC_col3", coef(m5c_3)[["fit_posterior_z"]])
r("iv_policy_demand_index_posterior_table5_panelC_col7", coef(m5c_7)[["fit_posterior_z"]])
r("followup_perception_index_t74_table6_panelA_col7", coef(m6)[["T74"]])
