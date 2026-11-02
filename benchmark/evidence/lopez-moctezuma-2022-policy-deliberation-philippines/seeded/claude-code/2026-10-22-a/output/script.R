## Reproduction of Lopez-Moctezuma et al. (2022), seeded mode.
## Follows tables_figures_agg.R (Table 1), survey_clean.R + tables_fig_ind.R
## (Tables C.3/C.4) and tables_fig_ind_unweighted.R (Table F.1).
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/2026-10-22-a/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D, "data_agg.RData"))    # data.all
load(file.path(D, "survey_raw.RData"))  # survey_raw

## Exact assignment probability in a blocked, cluster-randomized design
## (share of clusters treated within each block), as ri::genprobexact.
probexact <- function(Z, block, cluster) {
  out <- rep(NA_real_, length(Z))
  ok <- !is.na(Z) & !is.na(block) & !is.na(cluster)
  cl <- unique(data.frame(b = block[ok], c = cluster[ok], z = Z[ok]))
  pb <- tapply(cl$z, cl$b, mean)
  out[ok] <- pb[as.character(block[ok])]
  out
}

res <- list()

## ---------------- Table 1: barangay-level ITT ----------------
agg <- data.all
vars <- c("turnout.party", "share.treated", "share.akbayan", "share.umalabka")
nm   <- c("itt_turnout_barangay_table1_col1", "itt_vote_overall_barangay_table1_col2",
          "itt_vote_akbayan_barangay_table1_col3", "itt_vote_umalabka_barangay_table1_col4")
nobs <- numeric(4)
for (i in seq_along(vars)) {
  d <- agg[!is.na(agg[[vars[i]]]), ]
  if (vars[i] == "share.akbayan")  d <- d[d$partytreat == "akbayan", ]
  if (vars[i] == "share.umalabka") d <- d[d$partytreat == "umalabka", ]
  p <- probexact(d$assignment, d$city, d$barangay)
  d$w <- d$assignment / p + (1 - d$assignment) / (1 - p)
  d$y <- d[[vars[i]]]
  ## ri::estate with covariates X (city dummies) and prob: IPW-weighted OLS
  fit <- lm(y ~ assignment + factor(city), data = d, weights = w)
  res[[nm[i]]] <- unname(coef(fit)["assignment"])
  nobs[i] <- nobs(fit)
}
res[["n_obs_barangay_table1_cols1_2"]] <- nobs[2]
res[["n_obs_barangay_akbayan_table1_col3"]] <- nobs[3]
res[["n_obs_barangay_umalabka_table1_col4"]] <- nobs[4]
cat("N turnout:", nobs[1], " N overall vote:", nobs[2], "\n")

## ---------------- Survey indices (survey_clean.R) ----------------
s <- as.data.frame(survey_raw)
standard <- function(v, treat) (v - mean(v, na.rm = TRUE)) / sd(v[treat == 0], na.rm = TRUE)
icw_index <- function(M) {
  cc <- complete.cases(M)
  Mc <- M[cc, , drop = FALSE]
  Si <- solve(cov(Mc)); one <- rep(1, ncol(Mc))
  wv <- as.vector(Si %*% one) / as.numeric(t(one) %*% Si %*% one)
  out <- rep(NA_real_, nrow(M)); out[cc] <- as.vector(Mc %*% wv); out
}
for (v in c("femhouse", "fempol", "equality", "discrimination", "harassment",
            "poverty", "corruption", "gap", "cct"))
  s[[paste0(v, ".est")]] <- standard(s[[v]], s$treatment)
s$sexism <- icw_index(as.matrix(s[, c("femhouse.est", "fempol.est", "equality.est",
                                       "discrimination.est", "harassment.est")]))
s$poverty.all <- icw_index(as.matrix(s[, c("poverty.est", "cct.est", "gap.est", "corruption.est")]))

## ---------------- Attendance weights (tables_fig_ind.R) ----------------
## survey.agg: self-reported attendance share per surveyed barangay (x100)
sa <- aggregate(cbind(obs = 1, att = ifelse(is.na(s$attendance), 0, s$attendance)),
                by = list(city = s$city, barangay = s$barangay), FUN = sum)
sa$attendance.agg <- sa$att / sa$obs * 100
## Link survey barangays to official barangays (authors used fastLink on names);
## treated barangay names are unique and identical across the two files.
off <- data.all[data.all$treatment == 1, c("barangay", "city", "att.prop")]
off$att.prop <- off$att.prop * 100
sa_t <- merge(sa, off, by = "barangay", suffixes = c("", ".official"))
cat("Treated surveyed barangays linked:", nrow(sa_t), "\n"); print(sa_t)
sa_t$weight.att <- ifelse(sa_t$attendance.agg > 0, sa_t$att.prop / sa_t$attendance.agg, 1)
s <- merge(s, sa_t[, c("city", "barangay", "weight.att")], by = c("city", "barangay"), all.x = TRUE)
s$weight.att <- ifelse(s$treatment == 0, 1, s$weight.att)

## Weighted city-FE regression on assignment, SE clustered by barangay
itt_ind <- function(y, party, wvar, data) {
  d <- data[data$partytreat %in% party, c(y, "barangay", "assignment", "treatment", "city", wvar)]
  d <- d[complete.cases(d), ]
  names(d)[1] <- "y"; d$w <- d[[wvar]]
  fit <- lm(y ~ assignment + city, data = d, weights = w)
  V <- sandwich::vcovCL(fit, cluster = ~barangay, type = "HC1")
  ct <- lmtest::coeftest(fit, V)
  cat(sprintf("%s [%s] N=%d b=%.4f se=%.4f p=%.4f\n", y, paste(party, collapse = "+"),
              nrow(d), ct["assignment", 1], ct["assignment", 2], ct["assignment", 4]))
  unname(coef(fit)["assignment"])
}
res[["itt_poverty_index_akbayan_tableC3"]]  <- itt_ind("poverty.all", "Akbayan", "weight.att", s)
res[["itt_poverty_index_umalabka_tableC3"]] <- itt_ind("poverty.all", "Umalab Ka", "weight.att", s)
res[["itt_gender_index_akbayan_tableC4"]]   <- itt_ind("sexism", "Akbayan", "weight.att", s)
res[["itt_gender_index_umalabka_tableC4"]]  <- itt_ind("sexism", "Umalab Ka", "weight.att", s)

## ---------------- Table F.1: unweighted (assignment-IPW only) ----------------
s$probs.assign <- probexact(s$assignment, s$city, s$barangay)
s$weight.assign <- s$assignment / s$probs.assign + (1 - s$assignment) / (1 - s$probs.assign)
s$vote100 <- s$vote * 100
s$vote.akbayan100 <- s$vote.akbayan * 100
res[["itt_vote_overall_unweighted_tableF1_col2"]] <- itt_ind("vote100", c("Akbayan", "Umalab Ka"), "weight.assign", s)
res[["itt_vote_akbayan_unweighted_tableF1_col3"]] <- itt_ind("vote.akbayan100", "Akbayan", "weight.assign", s)

for (k in names(res)) cat(sprintf("RESULT:%s=%.6f\n", k, res[[k]]))
