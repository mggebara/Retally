suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/settele_2022_gender_wage_gap_beliefs_policy"

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
# Stata-like variable lookup: exact, case-insensitive, then unique abbreviation (prefix)
gc <- function(df, nm) {
  nms <- names(df)
  if (nm %in% nms) return(df[[nm]])
  i <- which(tolower(nms) == tolower(nm))
  if (length(i) >= 1) return(df[[i[1]]])
  i <- which(startsWith(tolower(nms), tolower(nm)))
  if (length(i) >= 1) {
    if (length(i) > 1) message("Ambiguous abbreviation for ", nm, ": using ", nms[i[1]])
    return(df[[i[1]]])
  }
  message("Variable not found: ", nm)
  rep(NA, nrow(df))
}
num <- function(x) {
  x <- haven::zap_labels(x)
  if (is.numeric(x)) return(as.numeric(x))
  if (is.logical(x)) return(as.numeric(x))
  suppressWarnings(as.numeric(as.character(x)))
}
chr <- function(x) {
  x <- haven::zap_labels(x)
  x <- as.character(x)
  x[is.na(x)] <- ""
  trimws(x)
}
recA <- function(x, maxi) {
  x <- haven::zap_labels(x)
  if (is.character(x) || is.factor(x)) {
    s <- trimws(as.character(x))
    out <- rep(NA_real_, length(s))
    for (i in 1:maxi) out[!is.na(s) & s == paste0("A", i)] <- i
    return(out)
  }
  v <- num(x)
  v[!(v %in% 1:maxi)] <- NA
  v
}
idchr <- function(x) {
  x <- haven::zap_labels(x)
  if (is.numeric(x)) return(ifelse(is.na(x), NA_character_, sprintf("%.0f", x)))
  trimws(as.character(x))
}
anderson <- function(M) {
  M <- as.matrix(M)
  cc <- complete.cases(M)
  R <- cor(M[cc, , drop = FALSE])
  w <- rowSums(solve(R))
  as.vector(M %*% w) / sum(w)
}
zctrl <- function(x, ctrl) {
  (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE)
}

# ------------------------------------------------------------------
# Stage I cleaning (03 / 04 do-files)
# ------------------------------------------------------------------
clean1 <- function(d, wv) {
  n <- nrow(d)
  out <- data.frame(panelID = idchr(gc(d, "panelID")), stringsAsFactors = FALSE)
  out$wave <- wv

  employ <- recA(gc(d, "employment"), 7)
  out$fulltime   <- as.numeric(employ %in% 1)
  out$parttime   <- as.numeric(employ %in% 2)
  out$selfemp    <- as.numeric(employ %in% 3)
  out$unemployed <- as.numeric(employ %in% 4)
  out$student    <- as.numeric(employ %in% 5)

  region <- recA(gc(d, "region"), 4)
  out$midwest <- as.numeric(region %in% 2)
  out$south   <- as.numeric(region %in% 3)
  out$west    <- as.numeric(region %in% 4)

  age <- recA(gc(d, "agebracket"), 5)
  out$agecat <- age
  for (k in 1:4) out[[paste0("age", k)]] <- ifelse(is.na(age), NA, as.numeric(age == k))

  hhinc <- recA(gc(d, "hhincbracket"), 8)
  hhv <- c(6735, 19742, 36701, 61275, 86204, 120686, 170381, 327261)
  out$loghhinc <- log(hhv[hhinc])

  g <- recA(gc(d, "gender"), 2)
  out$gender <- g - 1

  dr <- chr(gc(d, "demrep"))
  pol <- rep(NA_real_, n)
  pol[dr == "A1"] <- -2; pol[dr == "A2"] <- -1; pol[dr == "A3"] <- 0
  pol[dr == "A4"] <- 1;  pol[dr == "A5"] <- 2
  oth <- dr == "-oth-"
  out$otherpol <- as.numeric(oth)
  out$democrat <- as.numeric(!is.na(pol) & pol > 0 & !oth)
  out$indep    <- as.numeric(!is.na(pol) & pol == 0 & !oth)

  rand <- num(gc(d, "RAND"))
  out$rand <- rand
  out$T1 <- ifelse(is.na(rand), NA, as.numeric(rand == 1))

  r12 <- num(gc(d, "RAND12"))
  pInc <- num(gc(d, "elicitbgendeMarc"))
  pNo  <- num(gc(d, "elicitbgender"))
  prior <- rep(NA_real_, n)
  prior[r12 %in% 1] <- pInc[r12 %in% 1]
  prior[r12 %in% 0] <- pNo[r12 %in% 0]
  out$prior <- prior

  r4 <- num(gc(d, "RAND4"))
  if (wv == 1) {
    post <- num(gc(d, "extrayoung"))
    hs <- num(gc(d, "extraHS")); oc <- num(gc(d, "extraoccu"))
    post[r4 %in% 10] <- hs[r4 %in% 10]
    post[r4 %in% 11] <- oc[r4 %in% 11]
  } else {
    post <- rep(NA_real_, n)
    ch <- num(gc(d, "extrachild")); sm <- num(gc(d, "extrasame"))
    post[r4 %in% 11] <- ch[r4 %in% 11]
    post[r4 %in% 10] <- sm[r4 %in% 10]
  }
  out$posterior <- post

  out$large   <- recA(gc(d, "manicheckSQ001"), 10)
  out$problem <- recA(gc(d, "manicheckSQ002"), 10)
  out$govmore <- recA(gc(d, "manicheckSQ003"), 10)

  out$quotaanchor       <- recA(gc(d, "quotaanchor"), 5)
  out$AAanchor          <- recA(gc(d, "AAanchor"), 5)
  out$legislationanchor <- recA(gc(d, "legislationanchor"), 5)
  tr                    <- recA(gc(d, "transparencyanchor"), 5)
  out$childcare         <- recA(gc(d, "childcare"), 5)
  if (wv == 1) {
    out$transparencyanchor <- tr
    out$UKtool <- NA_real_
  } else {
    out$transparencyanchor <- NA_real_
    out$UKtool <- tr
  }

  educ <- recA(gc(d, "demo1"), 9)
  out$associatemore <- ifelse(is.na(educ), NA, as.numeric(educ > 4))

  boy  <- recA(gc(d, "childrenSQ001"), 6) - 1
  girl <- recA(gc(d, "childrenSQ002"), 6) - 1
  chn <- boy + girl
  out$anychildren <- as.numeric(!is.na(chn) & chn > 0)

  pwc <- which(tolower(names(d)) == "pweight")
  out$pweight <- if (length(pwc) >= 1) num(d[[pwc[1]]]) else NA_real_
  out
}

rawA <- read_dta(file.path(base, "data/SurveyStageI_WaveA_raw.dta"))
rawB <- read_dta(file.path(base, "data/SurveyStageI_WaveB_raw.dta"))
S1 <- bind_rows(clean1(rawA, 1), clean1(rawB, 2))
cat("Stage I N =", nrow(S1), "\n")
print(table(S1$rand, S1$wave, useNA = "ifany"))

# ------------------------------------------------------------------
# Stage II data (06 do-file)
# ------------------------------------------------------------------
prep <- function(d) as.data.frame(haven::zap_formats(haven::zap_labels(d)))
s2a <- prep(read_dta(file.path(base, "data/SurveyStageII_WaveA_raw.dta")))
s2b <- prep(read_dta(file.path(base, "data/SurveyStageII_WaveB_raw.dta")))
for (v in intersect(names(s2a), names(s2b))) {
  if (!identical(class(s2a[[v]]), class(s2b[[v]]))) {
    s2a[[v]] <- as.character(s2a[[v]]); s2b[[v]] <- as.character(s2b[[v]])
  }
}
S2 <- bind_rows(s2a, s2b)
n2 <- nrow(S2)
wraw <- S2$wave
if (is.character(wraw)) {
  w2 <- ifelse(trimws(wraw) == "A", 1, ifelse(trimws(wraw) == "B", 2, NA))
} else {
  w2 <- num(wraw)
}
isA <- w2 %in% 1; isB <- w2 %in% 2
ro <- num(gc(S2, "randorder2"))
pick6 <- function(a_nm, b1_nm, b2_nm) {
  a  <- recA(gc(S2, a_nm), 6)
  b1 <- recA(gc(S2, b1_nm), 6)
  b2 <- recA(gc(S2, b2_nm), 6)
  out <- rep(NA_real_, n2)
  i1 <- isB & ro %in% 1; out[i1] <- b1[i1]
  i2 <- isB & ro %in% 2; out[i2] <- b2[i2]
  out[isA] <- a[isA]
  out
}
problemII   <- pick6("wageproblemSQ002", "wageproblemSQ002", "wageproblem2SQ002")
problemIIHS <- pick6("wageproblemSQ003", "wageproblemSQ003", "wageproblem2SQ004")
problemIILS <- pick6("wageproblemSQ004", "wageproblemSQ004", "wageproblem2SQ003")
govmoreII   <- recA(gc(S2, "govwomen"), 7)
zs <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
F2 <- data.frame(
  panelID = idchr(gc(S2, "panelID")),
  problemII = zs(problemII), govmoreII = zs(govmoreII),
  problemIIHS = zs(problemIIHS), problemIILS = zs(problemIILS),
  wave2 = as.numeric(w2 == 2),
  rand = num(gc(S2, "rand")),
  pweight = num(gc(S2, "pweight")),
  stringsAsFactors = FALSE
)
for (v in c("gender", "prior", "democrat", "indep", "otherpol", "midwest", "south", "west",
            "age1", "age2", "age3", "age4", "anychildren", "loghhinc", "associatemore",
            "fulltime", "parttime", "selfemp", "unemployed", "student")) {
  F2[[v]] <- num(gc(S2, v))
}
F2$T1 <- as.numeric(F2$rand %in% 1)
F2$z_maniII_index2 <- anderson(F2[, c("problemII", "govmoreII", "problemIIHS", "problemIILS")])
F2$agecat <- with(F2, ifelse(age1 %in% 1, 1, ifelse(age2 %in% 1, 2, ifelse(age3 %in% 1, 3,
                     ifelse(age4 %in% 1, 4, 5)))))

# ------------------------------------------------------------------
# Probability weights for Stage I (constructed in 05, not shipped):
# take them from the follow-up file by panelID, else by gender x age x wave cell
# ------------------------------------------------------------------
if (all(is.na(S1$pweight))) {
  W <- F2[!is.na(F2$pweight), c("panelID", "pweight", "gender", "agecat", "wave2")]
  W$wave <- W$wave2 + 1
  S1$pweight <- W$pweight[match(S1$panelID, W$panelID)]
  cat("Stage I weights matched by panelID:", sum(!is.na(S1$pweight)), "\n")
  W$key3 <- paste(W$gender, W$agecat, W$wave)
  W$key2 <- paste(W$gender, W$agecat)
  cm3 <- tapply(W$pweight, W$key3, mean); cs3 <- tapply(W$pweight, W$key3, sd)
  cm2 <- tapply(W$pweight, W$key2, mean)
  cat("Within gender x age x wave cell SD of pweight (max):", max(cs3, na.rm = TRUE), "\n")
  print(round(cm3, 4))
  k3 <- paste(S1$gender, S1$agecat, S1$wave)
  k2 <- paste(S1$gender, S1$agecat)
  miss <- is.na(S1$pweight)
  S1$pweight[miss] <- cm3[k3[miss]]
  miss <- is.na(S1$pweight)
  S1$pweight[miss] <- cm2[k2[miss]]
  miss <- is.na(S1$pweight)
  if (any(miss)) { cat("Weights set to 1 for", sum(miss), "obs\n"); S1$pweight[miss] <- 1 }
}

# ------------------------------------------------------------------
# z-score outcomes on pure control group; Anderson indices (05)
# ------------------------------------------------------------------
ctrl <- S1$rand %in% 0
for (v in c("large", "problem", "govmore", "quotaanchor", "AAanchor", "legislationanchor",
            "transparencyanchor", "UKtool", "childcare")) {
  S1[[v]] <- zctrl(S1[[v]], ctrl)
}
S1$z_mani_index <- anderson(S1[, c("large", "problem", "govmore")])
S1$transpUK <- ifelse(S1$wave == 1, S1$transparencyanchor, S1$UKtool)
S1$z_lmpolicy_index <- anderson(S1[, c("quotaanchor", "AAanchor", "legislationanchor", "transpUK", "childcare")])
S1$wave2 <- as.numeric(S1$wave == 2)

res <- list()
emit <- function(name, val) {
  if (length(val) == 1 && !is.na(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
}

# ------------------------------------------------------------------
# Tables 3 and 4: control group, trimmed priors
# ------------------------------------------------------------------
C <- S1[ctrl, ]
C$prior <- (C$prior - mean(C$prior, na.rm = TRUE)) / sd(C$prior, na.rm = TRUE)
q <- quantile(C$prior, c(0.05, 0.95), type = 2, na.rm = TRUE)
C <- C[!is.na(C$prior) & C$prior > q[1] & C$prior < q[2], ]
cat("Table 3 sample:", nrow(C), "\n")

t3a <- feols(z_mani_index ~ wave2 + democrat + indep + otherpol + gender, data = C,
             weights = ~pweight, vcov = "hetero")
t3b <- feols(z_mani_index ~ wave2 + prior, data = C, weights = ~pweight, vcov = "hetero")
t4a <- feols(z_lmpolicy_index ~ wave2 + democrat + indep + otherpol + gender, data = C,
             weights = ~pweight, vcov = "hetero")
t4b <- feols(z_lmpolicy_index ~ wave2 + prior, data = C, weights = ~pweight, vcov = "hetero")
print(etable(t3a, t3b, t4a, t4b))

res$perception_index_democrat_table3_panelA_col4 <- unname(coef(t3a)["democrat"])
res$perception_index_female_table3_panelA_col4   <- unname(coef(t3a)["gender"])
res$perception_index_prior_table3_panelB_col4    <- unname(coef(t3b)["prior"])
res$n_obs_table3 <- nobs(t3a)
res$policy_demand_index_democrat_table4_panelA_col7 <- unname(coef(t4a)["democrat"])
res$policy_demand_index_prior_table4_panelB_col7    <- unname(coef(t4b)["prior"])

# ------------------------------------------------------------------
# Table 5: treatment arms
# ------------------------------------------------------------------
Tt <- S1[!(S1$rand %in% 0), ]
ok <- !is.na(Tt$posterior) & !is.na(Tt$pweight)
x <- Tt$posterior[ok]; w <- Tt$pweight[ok]; nn <- length(x)
wm <- sum(w * x) / sum(w)
wsd <- sqrt(sum(w * (x - wm)^2) / sum(w) * nn / (nn - 1))
Tt$zposterior <- (Tt$posterior - wm) / wsd

ctrls <- "wave2 + gender + prior + democrat + indep + otherpol + midwest + south + west + age1 + age2 + age3 + age4 + anychildren + loghhinc + associatemore + fulltime + parttime + selfemp + unemployed + student"
ols <- function(y, d) feols(as.formula(paste(y, "~ T1 +", ctrls)), data = d, weights = ~pweight, vcov = "hetero")
iv  <- function(y, d) feols(as.formula(paste(y, "~", ctrls, "| zposterior ~ T1")), data = d, weights = ~pweight, vcov = "hetero")

m1 <- ols("posterior", Tt)
m2 <- ols("zposterior", Tt)
m6 <- ols("z_mani_index", Tt)
i2 <- iv("AAanchor", Tt)
i3 <- iv("legislationanchor", Tt)
i7 <- iv("z_lmpolicy_index", Tt)
print(etable(m1, m2, m6))
print(etable(i2, i3, i7))

res$first_stage_posterior_raw_t74_table5_panelA_col1 <- unname(coef(m1)["T1"])
res$first_stage_posterior_z_t74_table5_panelA_col2   <- unname(coef(m2)["T1"])
res$perception_index_t74_table5_panelA_col6          <- unname(coef(m6)["T1"])
res$iv_affirmative_action_posterior_table5_panelC_col2       <- unname(coef(i2)["fit_zposterior"])
res$iv_equal_pay_legislation_posterior_table5_panelC_col3    <- unname(coef(i3)["fit_zposterior"])
res$iv_policy_demand_index_posterior_table5_panelC_col7      <- unname(coef(i7)["fit_zposterior"])

# ------------------------------------------------------------------
# Table 6: follow-up
# ------------------------------------------------------------------
G <- F2[!(F2$rand %in% 0) & !is.na(F2$pweight), ]
f7 <- ols("z_maniII_index2", G)
print(etable(f7))
res$followup_perception_index_t74_table6_panelA_col7 <- unname(coef(f7)["T1"])

for (nm in names(res)) emit(nm, res[[nm]])
