# Reproduction of Settele (2022, AEJ: Policy) -- Tables 3, 4, 5 and 6
# Implements the cleaning of 03/04 (Stage I) and 06 (Stage II) do-files and the
# regressions of 08_MainTables.do. The append/z-score file (05) is not available,
# so its steps (wave indicator, control-group z-scoring, Anderson indices,
# probability weights) are reconstructed; pweight is recovered from the
# follow-up raw data (which carries pweight) by panelID and by weighting cell.

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/settele_2022_gender_wage_gap_beliefs_policy"

rd <- function(f) {
  d <- haven::read_dta(file.path(base, "data", f))
  d <- haven::zap_labels(d)
  d <- haven::zap_formats(d)
  as.data.frame(d, stringsAsFactors = FALSE)
}
num <- function(x) suppressWarnings(as.numeric(as.character(x)))
chr <- function(x) { x <- as.character(x); x[is.na(x)] <- ""; trimws(x) }
getcol <- function(d, nm) {
  if (nm %in% names(d)) return(d[[nm]])
  hit <- names(d)[tolower(names(d)) == tolower(nm)]
  if (length(hit) >= 1) return(d[[hit[1]]])
  rep(NA, nrow(d))
}
acode <- function(x, maxk) {
  x <- chr(x)
  out <- rep(NA_real_, length(x))
  m <- grepl("^A[0-9]+$", x)
  k <- as.numeric(sub("^A", "", x[m]))
  k[k > maxk | k < 1] <- NA
  out[m] <- k
  out
}
b01 <- function(cond) as.numeric(!is.na(cond) & cond)

# ---------------------------------------------------------------------------
# Stage I cleaning (03 / 04)
# ---------------------------------------------------------------------------
clean_stage1 <- function(d, wv) {
  n <- nrow(d)
  o <- data.frame(panelID = chr(getcol(d, "panelID")), stringsAsFactors = FALSE)
  o$wave <- wv

  emp <- acode(getcol(d, "employment"), 7)
  o$employ <- emp
  o$fulltime <- b01(emp == 1)
  o$parttime <- b01(emp == 2)
  o$selfemp <- b01(emp == 3)
  o$unemployed <- b01(emp == 4)
  o$student <- b01(emp == 5)
  o$oolf <- b01(emp == 6 | emp == 7)

  reg <- acode(getcol(d, "region"), 4)
  o$region <- reg
  o$midwest <- b01(reg == 2)
  o$south <- b01(reg == 3)
  o$west <- b01(reg == 4)

  age <- acode(getcol(d, "agebracket"), 5)
  o$age <- age
  for (k in 1:5) o[[paste0("age", k)]] <- ifelse(is.na(age), NA, as.numeric(age == k))

  hh <- acode(getcol(d, "hhincbracket"), 8)
  vals <- c(6735, 19742, 36701, 61275, 86204, 120686, 170381, 327261)
  o$hhinc <- hh
  o$loghhinc <- log(vals[hh])

  g <- chr(getcol(d, "gender"))
  o$gender <- ifelse(g == "A1", 0, ifelse(g == "A2", 1, NA))

  dr <- chr(getcol(d, "demrep"))
  polmap <- c(A1 = -2, A2 = -1, A3 = 0, A4 = 1, A5 = 2)
  pol <- unname(polmap[dr])
  o$otherpol <- as.numeric(dr == "-oth-")
  o$democrat <- b01(pol > 0)
  o$indep <- b01(pol == 0)
  o$republican <- b01(pol < 0)
  o$democrat[o$otherpol == 1] <- 0
  o$indep[o$otherpol == 1] <- 0
  o$republican[o$otherpol == 1] <- 0

  rand <- num(getcol(d, "RAND"))
  o$rand <- rand
  o$T1 <- ifelse(is.na(rand), NA, as.numeric(rand == 1))

  r12 <- num(getcol(d, "RAND12"))
  pinc <- num(getcol(d, "elicitbgendeMarc"))
  pnoinc <- num(getcol(d, "elicitbgendernoinMar"))
  o$prior1 <- b01(r12 == 1)
  o$prior <- ifelse(!is.na(r12) & r12 == 1, pinc, ifelse(!is.na(r12) & r12 == 0, pnoinc, NA))

  r4 <- num(getcol(d, "RAND4"))
  if (wv == 1) {
    post <- num(getcol(d, "extrayoung"))
    hs <- num(getcol(d, "extraHSS"))
    oc <- num(getcol(d, "extraoccuu"))
    post[!is.na(r4) & r4 == 10] <- hs[!is.na(r4) & r4 == 10]
    post[!is.na(r4) & r4 == 11] <- oc[!is.na(r4) & r4 == 11]
  } else {
    post <- rep(NA_real_, n)
    ch <- num(getcol(d, "extrachild"))
    sa <- num(getcol(d, "extrasame"))
    post[!is.na(r4) & r4 == 11] <- ch[!is.na(r4) & r4 == 11]
    post[!is.na(r4) & r4 == 10] <- sa[!is.na(r4) & r4 == 10]
  }
  o$posterior <- post

  o$large <- acode(getcol(d, "manicheckSQ001"), 10)
  o$problem <- acode(getcol(d, "manicheckSQ002"), 10)
  o$govmore <- acode(getcol(d, "manicheckSQ003"), 10)

  for (v in c("quotaanchor", "AAanchor", "transparencyanchor", "legislationanchor", "childcare")) {
    o[[v]] <- acode(getcol(d, v), 5)
  }
  if (wv == 2) {
    o$UKtool <- o$transparencyanchor
    o$transparencyanchor <- NA_real_
  } else {
    o$UKtool <- NA_real_
  }

  educ <- acode(getcol(d, "demo1"), 9)
  o$associatemore <- ifelse(is.na(educ), NA, as.numeric(educ > 4))

  boy <- acode(getcol(d, "childrenSQ001"), 6) - 1
  girl <- acode(getcol(d, "childrenSQ002"), 6) - 1
  o$anychildren <- b01((boy + girl) > 0)
  o
}

sA <- clean_stage1(rd("SurveyStageI_WaveA_raw.dta"), 1)
sB <- clean_stage1(rd("SurveyStageI_WaveB_raw.dta"), 2)
s1 <- rbind(sA, sB)
message("Stage I N = ", nrow(s1))

# z-score qualitative outcomes on the pure control group (mean / sd, unweighted)
zvars <- c("large", "problem", "govmore", "quotaanchor", "AAanchor",
           "legislationanchor", "transparencyanchor", "UKtool", "childcare")
ctl_idx <- !is.na(s1$rand) & s1$rand == 0
for (v in zvars) {
  m <- mean(s1[[v]][ctl_idx], na.rm = TRUE)
  s <- sd(s1[[v]][ctl_idx], na.rm = TRUE)
  s1[[v]] <- (s1[[v]] - m) / s
}

# Anderson (2008) index as in the 06 do-file: weights = row sums of inverse
# correlation matrix (listwise complete cases), index = weighted mean
anderson <- function(M) {
  M <- as.matrix(M)
  cc <- complete.cases(M)
  C <- cor(M[cc, , drop = FALSE])
  Ci <- solve(C)
  w <- rowSums(Ci)
  as.vector(M %*% w) / sum(w)
}
s1$z_mani_index <- anderson(s1[, c("large", "problem", "govmore")])
transp_uk <- ifelse(is.na(s1$transparencyanchor), s1$UKtool, s1$transparencyanchor)
s1$z_lmpolicy_index <- anderson(cbind(s1$quotaanchor, s1$AAanchor, s1$legislationanchor,
                                      transp_uk, s1$childcare))

# ---------------------------------------------------------------------------
# Stage II (follow-up) data, 06 do-file
# ---------------------------------------------------------------------------
s2cols <- c("panelID", "wave", "rand", "pweight", "prior", "gender", "democrat", "indep",
            "otherpol", "midwest", "south", "west", "age1", "age2", "age3", "age4",
            "anychildren", "loghhinc", "associatemore", "fulltime", "parttime",
            "selfemp", "unemployed", "student", "randorder2", "posteriorII",
            "govwomen", "wageproblemSQ001", "wageproblemSQ002", "wageproblemSQ003",
            "wageproblemSQ004", "wageproblem2SQ001", "wageproblem2SQ002",
            "wageproblem2SQ003", "wageproblem2SQ004")
prep2 <- function(d) {
  o <- data.frame(row = seq_len(nrow(d)))
  for (v in s2cols) {
    x <- getcol(d, v)
    if (v %in% c("panelID", "wave", "govwomen") || grepl("^wageproblem", v)) {
      o[[v]] <- chr(x)
    } else {
      o[[v]] <- num(x)
    }
  }
  o$row <- NULL
  o
}
s2 <- rbind(prep2(rd("SurveyStageII_WaveA_raw.dta")), prep2(rd("SurveyStageII_WaveB_raw.dta")))
wc <- s2$wave
s2$wave <- ifelse(wc %in% c("A", "1"), 1, ifelse(wc %in% c("B", "2"), 2, NA))
wA <- !is.na(s2$wave) & s2$wave == 1
wB <- !is.na(s2$wave) & s2$wave == 2
ro <- s2$randorder2
pick <- function(a_var, b1_var, b2_var) {
  out <- rep(NA_real_, nrow(s2))
  a <- acode(s2[[a_var]], 6); b1 <- acode(s2[[b1_var]], 6); b2 <- acode(s2[[b2_var]], 6)
  i <- wB & !is.na(ro) & ro == 1; out[i] <- b1[i]
  i <- wB & !is.na(ro) & ro == 2; out[i] <- b2[i]
  out[wA] <- a[wA]
  out
}
s2$problemII <- pick("wageproblemSQ002", "wageproblemSQ002", "wageproblem2SQ002")
s2$problemIIHS <- pick("wageproblemSQ003", "wageproblemSQ003", "wageproblem2SQ004")
s2$problemIILS <- pick("wageproblemSQ004", "wageproblemSQ004", "wageproblem2SQ003")
s2$govmoreII <- acode(s2$govwomen, 7)

# fill missing rand / pweight / controls from Stage I if needed
mi <- match(s2$panelID, s1$panelID)
if (all(is.na(s2$rand))) s2$rand <- s1$rand[mi]

for (v in c("problemII", "govmoreII", "problemIIHS", "problemIILS")) {
  s2[[v]] <- (s2[[v]] - mean(s2[[v]], na.rm = TRUE)) / sd(s2[[v]], na.rm = TRUE)
}
s2$T1 <- as.numeric(!is.na(s2$rand) & s2$rand == 1)
s2$z_maniII_index2 <- anderson(s2[, c("problemII", "govmoreII", "problemIIHS", "problemIILS")])

# ---------------------------------------------------------------------------
# Probability weights for Stage I: exact by panelID from follow-up data,
# otherwise the (validated) cell value of the weighting cells
# ---------------------------------------------------------------------------
pwmap <- s2[!is.na(s2$pweight) & s2$panelID != "", c("panelID", "pweight")]
pwmap <- pwmap[!duplicated(pwmap$panelID), ]
s1$pw_exact <- pwmap$pweight[match(s1$panelID, pwmap$panelID)]
message("Stage I respondents with pweight from follow-up: ", sum(!is.na(s1$pw_exact)))

cellkey <- function(df, k) do.call(paste, c(lapply(k, function(z) df[[z]]), sep = "_"))
keys <- list(c("gender", "age"),
             c("wave", "gender", "age"),
             c("gender", "age", "region"),
             c("wave", "gender", "age", "region"),
             c("gender", "age", "region", "employ"),
             c("wave", "gender", "age", "region", "employ"))
matched <- s1[!is.na(s1$pw_exact), ]
chosen <- NULL
for (k in keys) {
  ck <- cellkey(matched, k)
  rng <- tapply(matched$pw_exact, ck, function(z) diff(range(z)))
  covered <- all(unique(cellkey(s1, k)) %in% names(rng))
  message("key ", paste(k, collapse = "+"), ": max within-cell range = ",
          signif(max(rng), 4), ", all cells covered = ", covered)
  if (max(rng) < 1e-6 && covered) { chosen <- k; break }
}
cell_fill <- function(k) {
  ck <- cellkey(matched, k)
  mm <- tapply(matched$pw_exact, ck, mean)
  unname(mm[cellkey(s1, k)])
}
if (!is.null(chosen)) {
  message("pweight constant within cells of: ", paste(chosen, collapse = "+"))
  pw_cell <- cell_fill(chosen)
} else {
  message("pweight not cell-constant; using cell means (fallback hierarchy)")
  pw_cell <- cell_fill(c("wave", "gender", "age"))
  alt <- cell_fill(c("gender", "age"))
  pw_cell[is.na(pw_cell)] <- alt[is.na(pw_cell)]
}
s1$pweight <- ifelse(!is.na(s1$pw_exact), s1$pw_exact, pw_cell)
s1$pweight[is.na(s1$pweight)] <- mean(matched$pw_exact)

# ---------------------------------------------------------------------------
# Tables 3 and 4: trimmed pure control group
# ---------------------------------------------------------------------------
t3 <- s1[!is.na(s1$rand) & s1$rand == 0, ]
t3$prior <- (t3$prior - mean(t3$prior, na.rm = TRUE)) / sd(t3$prior, na.rm = TRUE)
p5 <- quantile(t3$prior, 0.05, type = 2, na.rm = TRUE)
p95 <- quantile(t3$prior, 0.95, type = 2, na.rm = TRUE)
t3 <- t3[!is.na(t3$prior) & t3$prior > p5 & t3$prior < p95, ]

m3a <- feols(z_mani_index ~ factor(wave) + democrat + indep + otherpol + gender,
             data = t3, weights = ~pweight, vcov = "hetero")
m3b <- feols(z_mani_index ~ factor(wave) + prior, data = t3, weights = ~pweight, vcov = "hetero")
m4a <- feols(z_lmpolicy_index ~ factor(wave) + democrat + indep + otherpol + gender,
             data = t3, weights = ~pweight, vcov = "hetero")
m4b <- feols(z_lmpolicy_index ~ factor(wave) + prior, data = t3, weights = ~pweight, vcov = "hetero")

# ---------------------------------------------------------------------------
# Table 5: treatment arms only
# ---------------------------------------------------------------------------
ctrl <- "wave + gender + prior + democrat + indep + otherpol + midwest + south + west + age1 + age2 + age3 + age4 + anychildren + loghhinc + associatemore + fulltime + parttime + selfemp + unemployed + student"
t5 <- s1[!(!is.na(s1$rand) & s1$rand == 0), ]
ok <- !is.na(t5$posterior) & !is.na(t5$pweight)
w <- t5$pweight[ok]; x <- t5$posterior[ok]; nn <- length(x)
mw <- sum(w * x) / sum(w)
sdw <- sqrt(sum(w * (x - mw)^2) / sum(w) * nn / (nn - 1))
t5$zposterior <- (t5$posterior - mw) / sdw

f_ols <- function(y, d) feols(as.formula(paste(y, "~ T1 +", ctrl)), data = d,
                              weights = ~pweight, vcov = "hetero")
f_iv <- function(y, d) feols(as.formula(paste(y, "~", ctrl, "| zposterior ~ T1")), data = d,
                             weights = ~pweight, vcov = "hetero")
m5_post <- f_ols("posterior", t5)
m5_zpost <- f_ols("zposterior", t5)
m5_mani <- f_ols("z_mani_index", t5)
iv_aa <- f_iv("AAanchor", t5)
iv_leg <- f_iv("legislationanchor", t5)
iv_idx <- f_iv("z_lmpolicy_index", t5)

# ---------------------------------------------------------------------------
# Table 6: follow-up, treatment arms
# ---------------------------------------------------------------------------
t6 <- s2[!(!is.na(s2$rand) & s2$rand == 0), ]
m6 <- f_ols("z_maniII_index2", t6)

# ---------------------------------------------------------------------------
out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))
out("perception_index_democrat_table3_panelA_col4", coef(m3a)["democrat"])
out("perception_index_female_table3_panelA_col4", coef(m3a)["gender"])
out("perception_index_prior_table3_panelB_col4", coef(m3b)["prior"])
out("n_obs_table3", nobs(m3a))
out("policy_demand_index_democrat_table4_panelA_col7", coef(m4a)["democrat"])
out("policy_demand_index_prior_table4_panelB_col7", coef(m4b)["prior"])
out("first_stage_posterior_raw_t74_table5_panelA_col1", coef(m5_post)["T1"])
out("first_stage_posterior_z_t74_table5_panelA_col2", coef(m5_zpost)["T1"])
out("perception_index_t74_table5_panelA_col6", coef(m5_mani)["T1"])
out("iv_affirmative_action_posterior_table5_panelC_col2", coef(iv_aa)["fit_zposterior"])
out("iv_equal_pay_legislation_posterior_table5_panelC_col3", coef(iv_leg)["fit_zposterior"])
out("iv_policy_demand_index_posterior_table5_panelC_col7", coef(iv_idx)["fit_zposterior"])
out("followup_perception_index_t74_table6_panelA_col7", coef(m6)["T1"])
