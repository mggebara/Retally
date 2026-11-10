# Settele (2022) "How Do Beliefs About the Gender Wage Gap Affect the Demand for Public Policy?"
# Independent, blind reproduction of selected Table 3-6 quantities from the raw LimeSurvey exports.
suppressMessages({ library(haven); library(fixest) })
set.seed(42)
M <- "<repo>/benchmark/.cache/claude-code/settele-2022-gender-wage-gap-beliefs-policy/blind/2026-11-10-c/mount/settele_2022_gender_wage_gap_beliefs_policy/data/"

code <- function(x) { x <- as.character(x); x[x == "" | is.na(x)] <- NA; suppressWarnings(as.numeric(sub("^A", "", x))) }
# column of the LimeSurvey group timer that precedes a question's own timer column
gt <- function(d, q) { n <- names(d); i <- which(n == paste0(q, "Time")); rev(grep("^groupTime", n[1:i], value = TRUE))[1] }

build_main <- function(d, wave) {
  shown <- function(q) !is.na(d[[gt(d, q)]])
  acs <- shown("treatmentACS") | shown("treatmentACSnoinc")
  cps <- shown("treatmentCPS") | shown("treatmentCPSnoin")
  stopifnot(all(!(acs & cps)))
  stopifnot(all((d$RAND == 1) == acs), all((d$RAND == 2) == cps))
  dr <- as.character(d$demrep); age <- code(d$agebracket); emp <- code(d$employment); reg <- code(d$region)
  edu <- code(d$demo1)
  post <- if (wave == "A") cbind(d$extrayoung, d$extraHSS, d$extraoccuu) else cbind(d$extrasame, d$extrachild)
  stopifnot(all(rowSums(!is.na(post)) <= 1))
  out <- data.frame(
    panelID = d$panelID, waveB = as.integer(wave == "B"),
    group = ifelse(d$RAND == 0, "C", ifelse(d$RAND == 1, "T74", "T94")),
    female = as.integer(d$gender == "A2"),
    democrat = as.integer(dr %in% c("A4", "A5")), indep = as.integer(dr == "A3"),
    otherpol = as.integer(dr == "-oth-"),
    prior = ifelse(is.na(d$elicitbgendeMarc), d$elicitbgendernoinMar, d$elicitbgendeMarc),
    posterior = apply(post, 1, function(r) if (all(is.na(r))) NA_real_ else r[!is.na(r)][1]),
    midwest = as.integer(reg == 2), south = as.integer(reg == 3), west = as.integer(reg == 4),
    age1 = as.integer(age == 1), age2 = as.integer(age == 2), age3 = as.integer(age == 3), age4 = as.integer(age == 4),
    agecat = age,
    anychildren = as.integer(code(d$childrenSQ001) > 1 | code(d$childrenSQ002) > 1),
    hhbr = code(d$hhincbracket),
    associatemore = as.integer(edu >= 5),
    fulltime = as.integer(emp == 1), parttime = as.integer(emp == 2), selfemp = as.integer(emp == 3),
    unemployed = as.integer(emp == 4), student = as.integer(emp == 5),
    large = code(d$manicheckSQ001), problem = code(d$manicheckSQ002), govmit = code(d$manicheckSQ003),
    quota = code(d$quotaanchor), aa = code(d$AAanchor), legis = code(d$legislationanchor),
    transp = code(d$transparencyanchor), childcare = code(d$childcare),
    stringsAsFactors = FALSE)
  # probability weights (Appendix G): wave B oversampling in youngest / oldest age group
  out$pweight <- 1
  if (wave == "B") {
    out$pweight[out$agecat == 1 & out$female == 1] <- 0.6298
    out$pweight[out$agecat == 1 & out$female == 0] <- 1.4615
    out$pweight[out$agecat == 5 & out$female == 1] <- 0.8691
    out$pweight[out$agecat == 5 & out$female == 0] <- 1.0184
  }
  out
}
A <- build_main(read_dta(paste0(M, "SurveyStageI_WaveA_raw.dta")), "A")
B <- build_main(read_dta(paste0(M, "SurveyStageI_WaveB_raw.dta")), "B")
FA <- read_dta(paste0(M, "SurveyStageII_WaveA_raw.dta")); FB <- read_dta(paste0(M, "SurveyStageII_WaveB_raw.dta"))

# log household income: bracket -> value as coded in the authors' follow-up files (all 8 brackets observed there)
FF0 <- rbind(data.frame(panelID = FA$panelID, loghhinc = as.numeric(FA$loghhinc)),
             data.frame(panelID = FB$panelID, loghhinc = as.numeric(FB$loghhinc)))
tmp <- merge(rbind(A, B)[, c("panelID", "hhbr")], FF0, by = "panelID")
map <- tapply(tmp$loghhinc, tmp$hhbr, function(v) { stopifnot(length(unique(round(v, 6))) == 1); v[1] })
cat("loghhinc map:", paste(names(map), round(map, 4), collapse = "; "), "\n")
D <- rbind(A, B)
D$loghhinc <- as.numeric(map[as.character(D$hhbr)])
D$T74 <- as.integer(D$group == "T74")
D$ctrl <- D$group == "C"
cat("N main:", nrow(D), " by group:", paste(names(table(D$group)), table(D$group), collapse = " "), "\n")

# check own construction of covariates against the authors' constructed covariates in the follow-up files
chk <- merge(D, rbind(as.data.frame(FA[, c("panelID","democrat","indep","otherpol","prior","midwest","south","west","age1","age2","age3","age4","anychildren","associatemore","fulltime","parttime","selfemp","unemployed","student","gender","pweight")]),
                      as.data.frame(FB[, c("panelID","democrat","indep","otherpol","prior","midwest","south","west","age1","age2","age3","age4","anychildren","associatemore","fulltime","parttime","selfemp","unemployed","student","gender","pweight")])),
             by = "panelID", suffixes = c("", ".fu"))
for (v in c("democrat","indep","otherpol","prior","midwest","south","west","age1","age2","age3","age4","anychildren","associatemore","fulltime","parttime","selfemp","unemployed","student","pweight"))
  cat(sprintf("check %-13s mismatches: %d of %d\n", v, sum(abs(chk[[v]] - as.numeric(chk[[paste0(v, ".fu")]])) > 1e-4, na.rm = TRUE), nrow(chk)))
cat("check female mismatches:", sum(chk$female != as.numeric(chk$gender)), "\n")

# ---------- standardization on the pure control group ----------
zc <- function(x, ref) (x - mean(x[ref], na.rm = TRUE)) / sd(x[ref], na.rm = TRUE)
for (v in c("large","problem","govmit","quota","aa","legis","childcare","posterior")) D[[paste0("z_", v)]] <- zc(D[[v]], D$ctrl)
# wage transparency (wave A) / reporting website (wave B): z-scored within wave on the control group, then one slot
D$z_transp <- NA_real_
for (w in 0:1) { s <- D$waveB == w; D$z_transp[s] <- zc(D$transp[s], D$ctrl[s]) }

# Anderson (2008) summary index: inverse-covariance weighted mean of standardized outcomes
# (covariance over the full sample used to build the index), re-standardized on the reference group
anderson <- function(Z, ref) {
  Z <- as.matrix(Z)
  S <- cov(Z, use = "pairwise.complete.obs")
  w <- rowSums(solve(S))
  idx <- apply(Z, 1, function(r) { ok <- !is.na(r); if (!any(ok)) NA_real_ else sum(w[ok] * r[ok]) / sum(w[ok]) })
  cat("  index weights:", paste(round(w / sum(w), 3), collapse = " "), "\n")
  (idx - mean(idx[ref], na.rm = TRUE)) / sd(idx[ref], na.rm = TRUE)
}
cat("perception index\n");  D$perc_idx <- anderson(D[, c("z_large","z_problem","z_govmit")], D$ctrl)
cat("policy index\n");      D$pol_idx  <- anderson(D[, c("z_quota","z_aa","z_legis","z_transp","z_childcare")], D$ctrl)

# ---------- Tables 3 and 4: trimmed pure control group ----------
C <- D[D$ctrl, ]
q <- quantile(C$prior, c(0.05, 0.95), type = 2, na.rm = TRUE)
cat("control prior p5/p95:", q, "\n")
C$prior_z <- (C$prior - mean(C$prior)) / sd(C$prior)     # z-scored within the (full) pure control group
CT <- C[C$prior > q[1] & C$prior < q[2], ]
cat("trimmed control N:", nrow(CT), " waveA:", sum(CT$waveB == 0), " waveB:", sum(CT$waveB == 1), "\n")
cat("missing outcomes in trimmed control:", sum(is.na(CT$perc_idx)), sum(is.na(CT$pol_idx)), "\n")

t3a <- feols(perc_idx ~ democrat + female + indep + otherpol + waveB, data = CT, weights = ~pweight, vcov = "hetero")
t3b <- feols(perc_idx ~ prior_z + waveB, data = CT, weights = ~pweight, vcov = "hetero")
t4a <- feols(pol_idx ~ democrat + female + indep + otherpol + waveB, data = CT, weights = ~pweight, vcov = "hetero")
t4b <- feols(pol_idx ~ prior_z + waveB, data = CT, weights = ~pweight, vcov = "hetero")
for (m in list(t3a, t3b, t4a, t4b)) print(coeftable(m))

# ---------- Table 5: treatment arms, both waves ----------
TR <- D[!D$ctrl, ]
ctr <- "female + prior + midwest + south + west + age1 + age2 + age3 + age4 + anychildren + loghhinc + associatemore + fulltime + parttime + selfemp + unemployed + student + waveB + democrat + indep + otherpol"
f <- function(y) as.formula(paste(y, "~ T74 +", ctr))
t5_1 <- feols(f("posterior"), data = TR, weights = ~pweight, vcov = "hetero")
t5_2 <- feols(f("z_posterior"), data = TR, weights = ~pweight, vcov = "hetero")
t5_6 <- feols(f("perc_idx"), data = TR, weights = ~pweight, vcov = "hetero")
ivf <- function(y) as.formula(paste(y, "~", ctr, "| z_posterior ~ T74"))
iv2 <- feols(ivf("z_aa"), data = TR, weights = ~pweight, vcov = "hetero")
iv3 <- feols(ivf("z_legis"), data = TR, weights = ~pweight, vcov = "hetero")
iv7 <- feols(ivf("pol_idx"), data = TR, weights = ~pweight, vcov = "hetero")
cat("Table 5 N: col1", nobs(t5_1), " col6", nobs(t5_6), " IV", nobs(iv7), "\n")
for (m in list(t5_1, t5_2, t5_6)) print(coeftable(m)["T74", ])
for (m in list(iv2, iv3, iv7)) print(coeftable(m)["fit_z_posterior", ])

# ---------- Table 6: follow-up sample ----------
fu_prep <- function(F, wave) {
  wp2 <- if (wave == "B") TRUE else FALSE
  g <- function(v) code(F[[v]])
  prob_mw <- g("wageproblemSQ002"); prob_hi <- g("wageproblemSQ003"); prob_lo <- g("wageproblemSQ004")
  if (wp2) {  # alternative order version: in wageproblem2 SQ003 = low-skilled, SQ004 = high-skilled
    use2 <- is.na(prob_mw) & is.na(prob_hi) & is.na(prob_lo)
    prob_mw[use2] <- g("wageproblem2SQ002")[use2]
    prob_lo[use2] <- g("wageproblem2SQ003")[use2]
    prob_hi[use2] <- g("wageproblem2SQ004")[use2]
  }
  data.frame(panelID = F$panelID, waveB = as.integer(wave == "B"), T74 = as.integer(F$rand == 1),
             female = as.numeric(F$gender), prior = as.numeric(F$prior),
             midwest = F$midwest, south = F$south, west = F$west, age1 = F$age1, age2 = F$age2, age3 = F$age3, age4 = F$age4,
             anychildren = F$anychildren, loghhinc = as.numeric(F$loghhinc), associatemore = F$associatemore,
             fulltime = F$fulltime, parttime = F$parttime, selfemp = F$selfemp, unemployed = F$unemployed, student = F$student,
             democrat = F$democrat, indep = F$indep, otherpol = F$otherpol, pweight = as.numeric(F$pweight),
             prob_mw = prob_mw, govwomen = g("govwomen"), prob_hi = prob_hi, prob_lo = prob_lo,
             stringsAsFactors = FALSE)
}
FU <- rbind(fu_prep(FA, "A"), fu_prep(FB, "B"))
# T74 check against main-survey assignment
mm <- merge(FU[, c("panelID","T74")], D[, c("panelID","T74","group")], by = "panelID", suffixes = c("", ".main"))
cat("FU N:", nrow(FU), " T74 mismatches vs main:", sum(mm$T74 != mm$T74.main), " controls in FU:", sum(mm$group == "C"), "\n")
cat("FU missing items:", sapply(FU[, c("prob_mw","govwomen","prob_hi","prob_lo")], function(v) sum(is.na(v))), "\n")
all_fu <- rep(TRUE, nrow(FU))
for (v in c("prob_mw","govwomen","prob_hi","prob_lo")) FU[[paste0("z_", v)]] <- zc(FU[[v]], all_fu)
cat("follow-up perception index\n")
FU$fu_perc_idx <- anderson(FU[, c("z_prob_mw","z_govwomen","z_prob_hi","z_prob_lo")], all_fu)
t6_7 <- feols(f("fu_perc_idx"), data = FU, weights = ~pweight, vcov = "hetero")
cat("Table 6 col7 N:", nobs(t6_7), "\n"); print(coeftable(t6_7)[c("T74","female","democrat"), ])

out <- c(
  perception_index_democrat_table3_panelA_col4 = coef(t3a)[["democrat"]],
  perception_index_female_table3_panelA_col4 = coef(t3a)[["female"]],
  perception_index_prior_table3_panelB_col4 = coef(t3b)[["prior_z"]],
  n_obs_table3 = nobs(t3a),
  policy_demand_index_democrat_table4_panelA_col7 = coef(t4a)[["democrat"]],
  policy_demand_index_prior_table4_panelB_col7 = coef(t4b)[["prior_z"]],
  first_stage_posterior_raw_t74_table5_panelA_col1 = coef(t5_1)[["T74"]],
  first_stage_posterior_z_t74_table5_panelA_col2 = coef(t5_2)[["T74"]],
  perception_index_t74_table5_panelA_col6 = coef(t5_6)[["T74"]],
  iv_affirmative_action_posterior_table5_panelC_col2 = coef(iv2)[["fit_z_posterior"]],
  iv_equal_pay_legislation_posterior_table5_panelC_col3 = coef(iv3)[["fit_z_posterior"]],
  iv_policy_demand_index_posterior_table5_panelC_col7 = coef(iv7)[["fit_z_posterior"]],
  followup_perception_index_t74_table6_panelA_col7 = coef(t6_7)[["T74"]]
)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
