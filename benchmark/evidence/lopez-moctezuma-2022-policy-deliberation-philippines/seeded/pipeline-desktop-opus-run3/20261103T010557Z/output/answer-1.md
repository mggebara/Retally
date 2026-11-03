suppressPackageStartupMessages({
  library(dplyr)
  library(sandwich)
  library(lmtest)
  library(AER)
})

set.seed(42)

data.dir <- "<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines"

results <- list()
emit <- function(name, value) {
  results[[name]] <<- value
}

## ------------------------------------------------------------------
## Helpers
## ------------------------------------------------------------------

## Cluster-robust vcov exactly as in functions_ind.R
varcov.cluster <- function(data, fm, cluster1) {
  est.fun <- estfun(fm)
  N <- dim(fm$model)[1]
  NROW <- NROW(est.fun)
  K <- fm$rank
  cl <- factor(data[[cluster1]])
  u <- apply(est.fun, 2, function(x) tapply(x, cl, sum))
  meat <- crossprod(u) / N
  M <- length(levels(cl))
  dfc <- M / (M - 1) * (N - 1) / (N - K)
  dfc * NROW / N * sandwich(fm, meat = meat)
}

## IPW-weighted ATE with block dummies (ri::estate equivalent)
est_ate <- function(Y, Z, X, prob) {
  w <- Z / prob + (1 - Z) / (1 - prob)
  M <- cbind(1, Z, X)
  fit <- lm.wfit(M, Y, w)
  unname(fit$coefficients[2])
}

## Block-level probability of assignment (genprobexact with cluster = unit)
block_prob <- function(Z, block, cluster) {
  df <- data.frame(Z = Z, block = block, cluster = cluster, stringsAsFactors = FALSE)
  cl <- unique(df[, c("block", "cluster", "Z")])
  pb <- tapply(cl$Z, cl$block, mean)
  as.numeric(pb[as.character(block)])
}

## Permute assignment within block
perm_within <- function(Z, block) {
  Zp <- Z
  for (b in unique(block)) {
    idx <- which(block == b)
    if (length(idx) > 1) Zp[idx] <- Z[idx][sample.int(length(idx))]
  }
  Zp
}

## ------------------------------------------------------------------
## Part 1: Barangay-level Table 1
## ------------------------------------------------------------------
tryCatch({
  load(file.path(data.dir, "data_agg.RData"))  # data.all
  data.all <- as.data.frame(data.all)
  data.all$city <- as.character(data.all$city)
  data.all$barangay <- as.character(data.all$barangay)
  data.all$partytreat <- as.character(data.all$partytreat)

  vars <- c("turnout.party", "share.treated", "share.akbayan", "share.umalabka")
  itt.names <- c("itt_turnout_barangay_table1_col1",
                 "itt_vote_overall_barangay_table1_col2",
                 "itt_vote_akbayan_barangay_table1_col3",
                 "itt_vote_umalabka_barangay_table1_col4")
  n.names <- c("n_obs_barangay_table1_cols1_2",
               "n_obs_barangay_table1_cols1_2",
               "n_obs_barangay_akbayan_table1_col3",
               "n_obs_barangay_umalabka_table1_col4")
  short <- c("turnout", "vote_overall", "vote_akbayan", "vote_umalabka")

  n.perm <- 10000

  for (i in seq_along(vars)) {
    v <- vars[i]
    if (v %in% c("turnout.party", "share.treated")) {
      d <- data.all[!is.na(data.all[[v]]), ]
    } else if (v == "share.akbayan") {
      d <- data.all[!is.na(data.all[[v]]) & tolower(data.all$partytreat) == "akbayan", ]
    } else {
      d <- data.all[!is.na(data.all[[v]]) & tolower(data.all$partytreat) == "umalabka", ]
    }
    Y <- as.numeric(d[[v]])
    Z <- as.numeric(d$assignment)
    D <- as.numeric(d$treatment)
    block <- d$city
    X <- model.matrix(~ factor(block))[, -1, drop = FALSE]
    probs <- block_prob(Z, block, d$barangay)
    w <- Z / probs + (1 - Z) / (1 - probs)

    ate <- est_ate(Y, Z, X, probs)
    ## CACE (ri::estlate): ITT_Y / ITT_D
    itt.d <- est_ate(D, Z, X, probs)
    cace <- ate / itt.d

    ## Control mean: intercept of weighted regression w/o FE
    ctrl <- unname(coef(lm(Y ~ Z, weights = w))[1])

    ## R^2 of weighted lm with FE
    fit <- lm(Y ~ Z + X, weights = w)
    r2 <- summary(fit)$r.squared

    ## Randomization inference under sharp null of zero effect
    dist <- numeric(n.perm)
    for (k in seq_len(n.perm)) {
      Zp <- perm_within(Z, block)
      dist[k] <- est_ate(Y, Zp, X, probs)
    }
    if (v == "turnout.party") {
      p.ri <- 2 * min(mean(ate <= dist), mean(ate >= dist))
    } else {
      p.ri <- mean(ate <= dist)
    }

    emit(itt.names[i], ate)
    emit(n.names[i], nrow(d))
    emit(paste0("cace_", short[i], "_barangay_table1"), cace)
    emit(paste0("control_mean_", short[i], "_barangay_table1"), ctrl)
    emit(paste0("r2_", short[i], "_barangay_table1"), r2)
    emit(paste0("perm_p_", short[i], "_barangay_table1"), p.ri)
  }
}, error = function(e) message("Barangay-level part failed: ", conditionMessage(e)))

## ------------------------------------------------------------------
## Part 2: Individual-level survey data
## ------------------------------------------------------------------
tryCatch({
  load(file.path(data.dir, "survey_raw.RData"))  # survey_raw
  survey_raw <- as.data.frame(survey_raw)
  survey_raw$city <- as.character(survey_raw$city)
  survey_raw$barangay <- as.character(survey_raw$barangay)
  survey_raw$partytreat <- as.character(survey_raw$partytreat)

  ## --- Build indices as in survey_clean.R ---
  standard <- function(var, treat) {
    (var - mean(var, na.rm = TRUE)) / sd(var[which(treat == 0)], na.rm = TRUE)
  }
  icw_index <- function(outcomes) {
    cc <- complete.cases(outcomes)
    oc <- outcomes[cc, , drop = FALSE]
    sigma <- cov(oc)
    one <- rep(1, ncol(oc))
    sinv <- solve(sigma)
    wts <- as.numeric(sinv %*% one) / as.numeric(t(one) %*% sinv %*% one)
    s <- rep(NA_real_, nrow(outcomes))
    s[cc] <- as.numeric(oc %*% wts)
    s
  }

  sr <- survey_raw
  tr <- sr$treatment
  sr$femhouse.est <- standard(as.numeric(sr$femhouse), tr)
  sr$fempol.est <- standard(as.numeric(sr$fempol), tr)
  sr$equality.est <- standard(as.numeric(sr$equality), tr)
  sr$discrimination.est <- standard(as.numeric(sr$discrimination), tr)
  sr$harassment.est <- standard(as.numeric(sr$harassment), tr)
  sr$sexism <- icw_index(cbind(sr$femhouse.est, sr$fempol.est, sr$equality.est,
                               sr$discrimination.est, sr$harassment.est))

  sr$poverty.est <- standard(as.numeric(sr$poverty), tr)
  sr$corruption.est <- standard(as.numeric(sr$corruption), tr)
  sr$gap.est <- standard(as.numeric(sr$gap), tr)
  sr$cct.est <- standard(as.numeric(sr$cct), tr)
  sr$poverty.all <- icw_index(cbind(sr$poverty.est, sr$cct.est, sr$gap.est, sr$corruption.est))

  ## --- Attendance weights (survey.agg + link to official data) ---
  survey.agg <- sr %>%
    group_by(city, barangay) %>%
    summarise(obs = n(),
              attendance = sum(attendance, na.rm = TRUE),
              treatment = suppressWarnings(max(treatment, na.rm = TRUE)),
              .groups = "drop") %>%
    mutate(attendance.agg = attendance / obs * 100)

  load(file.path(data.dir, "data_agg.RData"))
  data.all <- as.data.frame(data.all)
  data.all$city <- as.character(data.all$city)
  data.all$barangay <- as.character(data.all$barangay)
  official.t <- data.all[data.all$treatment == 1, ]
  official.t$att.prop100 <- official.t$att.prop * 100

  norm_str <- function(x) {
    x <- tolower(x)
    x <- gsub("\\b(barangay|brgy|city|of|sta|santa|sto|santo|san)\\b", " ", x)
    x <- gsub("[^a-z0-9]", "", x)
    x
  }
  numx <- function(x) suppressWarnings(as.numeric(stringr::str_extract(x, "\\d+")))

  st <- survey.agg[survey.agg$treatment == 1, ]
  st$weight.att <- NA_real_
  if (nrow(st) > 0) {
    oc <- norm_str(official.t$city)
    ob <- norm_str(official.t$barangay)
    on <- numx(official.t$barangay)
    for (r in seq_len(nrow(st))) {
      sc <- norm_str(st$city[r])
      sb <- norm_str(st$barangay[r])
      sn <- numx(st$barangay[r])
      cd <- as.numeric(adist(sc, oc)) / pmax(nchar(sc), nchar(oc), 1)
      cd[mapply(function(a, b) nchar(a) > 0 && nchar(b) > 0 && (grepl(a, b, fixed = TRUE) || grepl(b, a, fixed = TRUE)), sc, oc)] <- 0
      bd <- as.numeric(adist(sb, ob)) / pmax(nchar(sb), nchar(ob), 1)
      bd[mapply(function(a, b) nchar(a) > 0 && nchar(b) > 0 && (grepl(a, b, fixed = TRUE) || grepl(b, a, fixed = TRUE)), sb, ob)] <- 0
      npen <- ifelse(!is.na(sn) & !is.na(on) & sn != on, 0.5, 0)
      score <- 2 * cd + bd + npen
      j <- which.min(score)
      att.agg <- st$attendance.agg[r]
      st$weight.att[r] <- ifelse(att.agg > 0, official.t$att.prop100[j] / att.agg, 1)
    }
  }

  data <- left_join(sr, st[, c("city", "barangay", "weight.att")], by = c("city", "barangay"))
  data$weight.att <- ifelse(data$treatment == 0, 1, data$weight.att)

  data$turnout_pl <- data$turnout_pl * 100
  data$vote <- data$vote * 100
  data$vote.akbayan <- data$vote.akbayan * 100
  data$vote.umalabka <- data$vote.umalabka * 100

  ## --- Attitude indices: Tables C.3 / C.4 (weighted ITT, city FE, cluster barangay) ---
  run_itt <- function(dat, y, wvar) {
    d <- dat[, c(y, "barangay", "assignment", "treatment", "city", wvar)]
    d <- d[complete.cases(d), ]
    d$city <- factor(d$city)
    d$w__ <- d[[wvar]]
    f <- as.formula(paste0("`", y, "` ~ assignment + city"))
    fit <- lm(f, weights = w__, data = d)
    vc <- varcov.cluster(d, fit, "barangay")
    b <- unname(coef(fit)["assignment"])
    se <- sqrt(vc["assignment", "assignment"])
    p <- coeftest(fit, vc)["assignment", 4]
    list(b = b, se = se, p = p, n = nrow(d))
  }

  parties <- c("Akbayan", "Umalab Ka")
  pnames <- c("akbayan", "umalabka")
  for (p in seq_along(parties)) {
    dp <- data[data$partytreat == parties[p], ]
    rp <- run_itt(dp, "poverty.all", "weight.att")
    emit(paste0("itt_poverty_index_", pnames[p], "_tableC3"), rp$b)
    emit(paste0("se_poverty_index_", pnames[p], "_tableC3"), rp$se)
    emit(paste0("p_poverty_index_", pnames[p], "_tableC3"), rp$p)
    rg <- run_itt(dp, "sexism", "weight.att")
    emit(paste0("itt_gender_index_", pnames[p], "_tableC4"), rg$b)
    emit(paste0("se_gender_index_", pnames[p], "_tableC4"), rg$se)
    emit(paste0("p_gender_index_", pnames[p], "_tableC4"), rg$p)
  }

  ## --- Unweighted Table F.1 (assignment-probability weights) ---
  du <- sr
  du$probs.assign <- block_prob(du$assignment, du$city, du$barangay)
  du$weight.assign <- (du$assignment / du$probs.assign) + ((1 - du$assignment) / (1 - du$probs.assign))
  du$turnout_pl <- du$turnout_pl * 100
  du$vote <- du$vote * 100
  du$vote.akbayan <- du$vote.akbayan * 100
  du$vote.umalabka <- du$vote.umalabka * 100

  rv <- run_itt(du, "vote", "weight.assign")
  emit("itt_vote_overall_unweighted_tableF1_col2", rv$b)
  emit("n_vote_overall_unweighted_tableF1_col2", rv$n)
  ra <- run_itt(du[du$partytreat == "Akbayan", ], "vote.akbayan", "weight.assign")
  emit("itt_vote_akbayan_unweighted_tableF1_col3", ra$b)
  emit("n_vote_akbayan_unweighted_tableF1_col3", ra$n)
  rt <- run_itt(du, "turnout_pl", "weight.assign")
  emit("itt_turnout_unweighted_tableF1_col1", rt$b)
  emit("n_turnout_unweighted_tableF1_col1", rt$n)
}, error = function(e) message("Individual-level part failed: ", conditionMessage(e)))

## ------------------------------------------------------------------
## Output
## ------------------------------------------------------------------
for (nm in names(results)) {
  val <- results[[nm]]
  if (length(val) == 1 && is.finite(val)) {
    cat(sprintf("RESULT:%s=%.6f\n", nm, val))
  }
}
