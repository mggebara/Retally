suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

base <- "<repo>/.cache/datasets/settele_2022_gender_wage_gap_beliefs_policy"

results <- list()
emit <- function(name, value) {
  results[[name]] <<- value
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
rd_char <- function(f) {
  d <- read_dta(file.path(base, "data", f))
  d <- zap_labels(d)
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  for (nm in names(d)) d[[nm]] <- as.character(d[[nm]])
  d
}
num <- function(x) suppressWarnings(as.numeric(as.character(x)))
getcol <- function(d, nm) if (nm %in% names(d)) d[[nm]] else rep(NA_character_, nrow(d))
codeA <- function(x, n) {
  x <- trimws(as.character(x))
  out <- rep(NA_real_, length(x))
  for (i in seq_len(n)) out[!is.na(x) & x == paste0("A", i)] <- i
  out
}
dummy_na <- function(cond, base_var) ifelse(is.na(base_var), NA_real_, as.numeric(cond))

# Anderson (2008)-style index exactly as in the authors' code:
# weights = row sums of the inverse correlation matrix (listwise sample),
# index = sum(w_k * y_k) / sum(w_k)  (missing if any component missing)
make_index <- function(df, vars) {
  M <- as.matrix(df[, vars])
  storage.mode(M) <- "double"
  cc <- complete.cases(M)
  C <- cor(M[cc, , drop = FALSE])
  Cinv <- solve(C)
  w <- rowSums(Cinv)
  as.vector(M %*% w) / sum(w)
}

# Stata summarize [aweight] mean / sd
wzscore <- function(x, w) {
  ok <- !is.na(x) & !is.na(w)
  X <- x[ok]; W <- w[ok]; n <- length(X)
  m <- sum(W * X) / sum(W)
  v <- sum(W * (X - m)^2) / sum(W) * n / (n - 1)
  (x - m) / sqrt(v)
}

controls <- c("wave", "gender", "prior", "democrat", "indep", "otherpol",
              "midwest", "south", "west", "age1", "age2", "age3", "age4",
              "anychildren", "loghhinc", "associatemore", "fulltime",
              "parttime", "selfemp", "unemployed", "student")

# ---------------------------------------------------------------------------
# Follow-up survey (Stage II): also used to recover the probability weights
# ---------------------------------------------------------------------------
S2 <- NULL
tryCatch({
  s2a <- rd_char("SurveyStageII_WaveA_raw.dta"); s2a$src <- "A"
  s2b <- rd_char("SurveyStageII_WaveB_raw.dta"); s2b$src <- "B"
  S2 <- bind_rows(s2a, s2b)
  S2$wave <- ifelse(S2$src == "A", 1, 2)
  ro <- num(getcol(S2, "randorder2"))
  isA <- S2$src == "A"; isB <- S2$src == "B"

  pick <- function(a_var, b1_var, b2_var, n) {
    out <- rep(NA_real_, nrow(S2))
    va <- codeA(getcol(S2, a_var), n)
    vb1 <- codeA(getcol(S2, b1_var), n)
    vb2 <- codeA(getcol(S2, b2_var), n)
    out[isA] <- va[isA]
    sel1 <- isB & !is.na(ro) & ro == 1
    sel2 <- isB & !is.na(ro) & ro == 2
    out[sel1] <- vb1[sel1]
    out[sel2] <- vb2[sel2]
    out
  }
  S2$problemII   <- pick("wageproblemSQ002", "wageproblemSQ002", "wageproblem2SQ002", 6)
  S2$problemIIHS <- pick("wageproblemSQ003", "wageproblemSQ003", "wageproblem2SQ004", 6)
  S2$problemIILS <- pick("wageproblemSQ004", "wageproblemSQ004", "wageproblem2SQ003", 6)
  S2$govmoreII   <- codeA(getcol(S2, "govwomen"), 7)

  for (v in c("problemII", "govmoreII", "problemIIHS", "problemIILS")) {
    m <- mean(S2[[v]], na.rm = TRUE); s <- sd(S2[[v]], na.rm = TRUE)
    S2[[v]] <- (S2[[v]] - m) / s
  }
  S2$z_maniII_index2 <- make_index(S2, c("problemII", "govmoreII", "problemIIHS", "problemIILS"))

  for (v in setdiff(c(controls, "pweight", "rand"), "wave")) S2[[v]] <- num(getcol(S2, v))
  S2$T1 <- as.numeric(!is.na(S2$rand) & S2$rand == 1)
  S2$agecat <- ifelse(S2$age1 %in% 1, 1, ifelse(S2$age2 %in% 1, 2,
               ifelse(S2$age3 %in% 1, 3, ifelse(S2$age4 %in% 1, 4,
               ifelse(is.na(S2$age1), NA, 5)))))
}, error = function(e) message("Stage II error: ", conditionMessage(e)))

# Weight lookup by (wave, gender, age bracket) learned from Stage II
wmap_w <- NULL; wmap_g <- NULL
tryCatch({
  if (!is.null(S2)) {
    wk <- S2 %>% filter(!is.na(pweight), !is.na(gender), !is.na(agecat))
    wmap_w <- wk %>% group_by(wave, gender, agecat) %>%
      summarise(pw_w = mean(pweight), sd_w = sd(pweight), n = n(), .groups = "drop")
    wmap_g <- wk %>% group_by(gender, agecat) %>%
      summarise(pw_g = mean(pweight), .groups = "drop")
    message("Weight cells (from follow-up data):")
    print(as.data.frame(wmap_w))
  }
}, error = function(e) message("Weight map error: ", conditionMessage(e)))

# ---------------------------------------------------------------------------
# Main survey (Stage I) cleaning
# ---------------------------------------------------------------------------
clean_stage1 <- function(d, wave) {
  o <- data.frame(id = seq_len(nrow(d)))
  o$wave <- wave
  emp <- codeA(getcol(d, "employment"), 7)
  o$fulltime <- as.numeric(emp %in% 1)
  o$parttime <- as.numeric(emp %in% 2)
  o$selfemp <- as.numeric(emp %in% 3)
  o$unemployed <- as.numeric(emp %in% 4)
  o$student <- as.numeric(emp %in% 5)
  reg <- codeA(getcol(d, "region"), 4)
  o$midwest <- as.numeric(reg %in% 2)
  o$south <- as.numeric(reg %in% 3)
  o$west <- as.numeric(reg %in% 4)
  age <- codeA(getcol(d, "agebracket"), 5)
  o$agecat <- age
  for (k in 1:4) o[[paste0("age", k)]] <- dummy_na(age == k, age)
  hh <- codeA(getcol(d, "hhincbracket"), 8)
  hcont <- c(6735, 19742, 36701, 61275, 86204, 120686, 170381, 327261)
  o$loghhinc <- log(hcont[hh])
  o$gender <- codeA(getcol(d, "gender"), 2) - 1
  dr <- trimws(as.character(getcol(d, "demrep")))
  pol <- rep(NA_real_, nrow(d))
  pol[!is.na(dr) & dr == "A1"] <- -2
  pol[!is.na(dr) & dr == "A2"] <- -1
  pol[!is.na(dr) & dr == "A3"] <- 0
  pol[!is.na(dr) & dr == "A4"] <- 1
  pol[!is.na(dr) & dr == "A5"] <- 2
  o$otherpol <- as.numeric(!is.na(dr) & dr == "-oth-")
  o$democrat <- as.numeric(!is.na(pol) & pol > 0)
  o$indep <- as.numeric(!is.na(pol) & pol == 0)
  o$republican <- as.numeric(!is.na(pol) & pol < 0)
  o$democrat[o$otherpol == 1] <- 0
  o$indep[o$otherpol == 1] <- 0
  o$republican[o$otherpol == 1] <- 0
  RAND <- num(getcol(d, "RAND"))
  o$rand <- RAND
  o$T1 <- ifelse(is.na(RAND), NA, as.numeric(RAND == 1))
  r12 <- num(getcol(d, "RAND12"))
  pinc <- num(getcol(d, "elicitbgendeMarc"))
  pno <- num(getcol(d, "elicitbgendernoinMar"))
  pr <- rep(NA_real_, nrow(d))
  pr[!is.na(r12) & r12 == 1] <- pinc[!is.na(r12) & r12 == 1]
  pr[!is.na(r12) & r12 == 0] <- pno[!is.na(r12) & r12 == 0]
  o$prior <- pr
  r4 <- num(getcol(d, "RAND4"))
  if (wave == 1) {
    post <- num(getcol(d, "extrayoung"))
    s10 <- !is.na(r4) & r4 == 10; s11 <- !is.na(r4) & r4 == 11
    post[s10] <- num(getcol(d, "extraHS"))[s10]
    post[s11] <- num(getcol(d, "extraoccu"))[s11]
  } else {
    post <- rep(NA_real_, nrow(d))
    s10 <- !is.na(r4) & r4 == 10; s11 <- !is.na(r4) & r4 == 11
    post[s11] <- num(getcol(d, "extrachild"))[s11]
    post[s10] <- num(getcol(d, "extrasame"))[s10]
  }
  # Each respondent states a posterior on exactly one of the five related
  # statistics: fill remaining missing posteriors from whichever posterior
  # question the respondent actually answered.
  for (cn in c("extrayoung", "extraHS", "extraoccu", "extrachild", "extrasame")) {
    v <- num(getcol(d, cn))
    fill <- is.na(post) & !is.na(v)
    post[fill] <- v[fill]
  }
  message("Wave ", wave, ": non-missing posteriors = ", sum(!is.na(post)))
  o$posterior <- post
  o$large <- codeA(getcol(d, "manicheckSQ001"), 10)
  o$problem <- codeA(getcol(d, "manicheckSQ002"), 10)
  o$govmore <- codeA(getcol(d, "manicheckSQ003"), 10)
  for (v in c("quotaanchor", "AAanchor", "transparencyanchor", "legislationanchor", "childcare"))
    o[[v]] <- codeA(getcol(d, v), 5)
  if (wave == 2) {
    o$UKtool <- o$transparencyanchor
    o$transparencyanchor <- NA_real_
  } else {
    o$UKtool <- NA_real_
  }
  educ <- codeA(getcol(d, "demo1"), 9)
  o$associatemore <- dummy_na(educ > 4, educ)
  boy <- codeA(getcol(d, "childrenSQ001"), 6) - 1
  girl <- codeA(getcol(d, "childrenSQ002"), 6) - 1
  ch <- boy + girl
  o$anychildren <- as.numeric(!is.na(ch) & ch > 0)
  o$pweight_raw <- if ("pweight" %in% names(d)) num(d$pweight) else NA_real_
  o
}

S1 <- NULL
tryCatch({
  d1a <- rd_char("SurveyStageI_WaveA_raw.dta")
  d1b <- rd_char("SurveyStageI_WaveB_raw.dta")
  S1 <- bind_rows(clean_stage1(d1a, 1), clean_stage1(d1b, 2))
  message("Stage I N = ", nrow(S1))

  # Probability weights
  if (all(is.na(S1$pweight_raw))) {
    S1 <- S1 %>% left_join(wmap_w %>% dplyr::select(wave, gender, agecat, pw_w),
                           by = c("wave", "gender", "agecat")) %>%
      left_join(wmap_g, by = c("gender", "agecat"))
    S1$pweight <- ifelse(!is.na(S1$pw_w), S1$pw_w, ifelse(!is.na(S1$pw_g), S1$pw_g, 1))
  } else {
    S1$pweight <- S1$pweight_raw
  }

  # z-score qualitative outcomes on the pure control group (pooled waves)
  for (v in c("large", "problem", "govmore", "quotaanchor", "AAanchor",
              "legislationanchor", "transparencyanchor", "UKtool", "childcare")) {
    cg <- S1[[v]][!is.na(S1$rand) & S1$rand == 0]
    m <- mean(cg, na.rm = TRUE); s <- sd(cg, na.rm = TRUE)
    S1[[v]] <- (S1[[v]] - m) / s
  }
  S1$transpUK <- ifelse(S1$wave == 1, S1$transparencyanchor, S1$UKtool)
  S1$z_mani_index <- make_index(S1, c("large", "problem", "govmore"))
  S1$z_lmpolicy_index <- make_index(S1, c("quotaanchor", "AAanchor", "legislationanchor",
                                          "transpUK", "childcare"))
}, error = function(e) message("Stage I error: ", conditionMessage(e)))

# ---------------------------------------------------------------------------
# Tables 3 and 4: correlates in trimmed pure control group
# ---------------------------------------------------------------------------
tryCatch({
  cg <- S1 %>% filter(!is.na(rand), rand == 0)
  cg$prior <- (cg$prior - mean(cg$prior, na.rm = TRUE)) / sd(cg$prior, na.rm = TRUE)
  q <- quantile(cg$prior, c(0.05, 0.95), type = 2, na.rm = TRUE)
  cg <- cg %>% filter(!is.na(prior), prior > q[1], prior < q[2])
  emit("n_obs_table3", nrow(cg))
  cgw <- cg %>% filter(!is.na(pweight))

  mA <- feols(z_mani_index ~ factor(wave) + democrat + indep + otherpol + gender,
              data = cgw, weights = ~pweight, vcov = "hetero")
  emit("perception_index_democrat_table3_panelA_col4", coef(mA)["democrat"])
  emit("perception_index_female_table3_panelA_col4", coef(mA)["gender"])
  mB <- feols(z_mani_index ~ factor(wave) + prior, data = cgw, weights = ~pweight, vcov = "hetero")
  emit("perception_index_prior_table3_panelB_col4", coef(mB)["prior"])

  pA <- feols(z_lmpolicy_index ~ factor(wave) + democrat + indep + otherpol + gender,
              data = cgw, weights = ~pweight, vcov = "hetero")
  emit("policy_demand_index_democrat_table4_panelA_col7", coef(pA)["democrat"])
  pB <- feols(z_lmpolicy_index ~ factor(wave) + prior, data = cgw, weights = ~pweight, vcov = "hetero")
  emit("policy_demand_index_prior_table4_panelB_col7", coef(pB)["prior"])
}, error = function(e) message("Tables 3/4 error: ", conditionMessage(e)))

# ---------------------------------------------------------------------------
# Table 5: treatment effects, first stage and 2SLS
# ---------------------------------------------------------------------------
tryCatch({
  tr <- S1 %>% filter(!is.na(rand), rand != 0, !is.na(pweight))
  tr$zposterior <- wzscore(tr$posterior, tr$pweight)
  ctrl <- paste(controls, collapse = " + ")

  f1 <- feols(as.formula(paste("posterior ~ T1 +", ctrl)), data = tr, weights = ~pweight, vcov = "hetero")
  emit("first_stage_posterior_raw_t74_table5_panelA_col1", coef(f1)["T1"])
  f2 <- feols(as.formula(paste("zposterior ~ T1 +", ctrl)), data = tr, weights = ~pweight, vcov = "hetero")
  emit("first_stage_posterior_z_t74_table5_panelA_col2", coef(f2)["T1"])
  f6 <- feols(as.formula(paste("z_mani_index ~ T1 +", ctrl)), data = tr, weights = ~pweight, vcov = "hetero")
  emit("perception_index_t74_table5_panelA_col6", coef(f6)["T1"])

  iv <- function(y) {
    m <- feols(as.formula(paste(y, "~", ctrl, "| zposterior ~ T1")), data = tr,
               weights = ~pweight, vcov = "hetero")
    coef(m)["fit_zposterior"]
  }
  emit("iv_affirmative_action_posterior_table5_panelC_col2", iv("AAanchor"))
  emit("iv_equal_pay_legislation_posterior_table5_panelC_col3", iv("legislationanchor"))
  emit("iv_policy_demand_index_posterior_table5_panelC_col7", iv("z_lmpolicy_index"))
}, error = function(e) message("Table 5 error: ", conditionMessage(e)))

# ---------------------------------------------------------------------------
# Table 6: follow-up perception index
# ---------------------------------------------------------------------------
tryCatch({
  fu <- S2 %>% filter(!(rand %in% 0), !is.na(pweight))
  ctrl <- paste(controls, collapse = " + ")
  m <- feols(as.formula(paste("z_maniII_index2 ~ T1 +", ctrl)), data = fu,
             weights = ~pweight, vcov = "hetero")
  emit("followup_perception_index_t74_table6_panelA_col7", coef(m)["T1"])
}, error = function(e) message("Table 6 error: ", conditionMessage(e)))

cat("DEVIATION: Posterior belief filled from whichever of the five posterior questions (extrayoung/extraHS/extraoccu/extrachild/extrasame) the respondent answered when the RAND4-based mapping left it missing\n")

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
for (nm in names(results)) {
  v <- as.numeric(results[[nm]])
  if (length(v) == 1 && is.finite(v)) cat(sprintf("RESULT:%s=%.6f\n", nm, v))
}
