## Reproduction: Lopez-Moctezuma et al. (2022), Table 1, SI Tables C.3, C.4, F.1
## Follows tables_figures_agg.R, survey_clean.R, tables_fig_ind.R, tables_fig_ind_unweighted.R
suppressPackageStartupMessages({library(dplyr)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/seeded/2026-11-02-b/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D, "data_agg.RData"))     # data.all
load(file.path(D, "survey_raw.RData"))   # survey_raw

## exact assignment probability within block (city), clusters = barangays (as ri::genprobexact)
probexact <- function(Z, block, clust) {
  df <- data.frame(Z = Z, b = as.character(block), c = as.character(clust))
  cl <- unique(df[, c("b", "c", "Z")])
  pb <- tapply(cl$Z, cl$b, mean)
  unname(pb[df$b])
}

## ---------------- Table 1: barangay-level ITT (ri::estate = IPW-weighted lm with city dummies)
res <- list()
vars <- c("turnout.party", "share.treated", "share.akbayan", "share.umalabka")
for (v in vars) {
  d <- data.all[complete.cases(data.all[v]), ]
  if (v == "share.akbayan")  d <- d[d$partytreat == "akbayan", ]
  if (v == "share.umalabka") d <- d[d$partytreat == "umalabka", ]
  p <- probexact(d$assignment, d$city, d$barangay)
  w <- d$assignment / p + (1 - d$assignment) / (1 - p)
  d$city <- factor(as.character(d$city))
  m <- lm(d[[v]] ~ d$assignment + d$city, weights = w)
  res[[v]] <- list(b = unname(coef(m)[2]), n = nrow(d))
  cat(sprintf("Table1 %s: ITT=%.4f N=%d\n", v, res[[v]]$b, nrow(d)))
}

## ---------------- survey_clean.R: summary indices
standard <- function(var, treat) (var - mean(var, na.rm = TRUE)) / sd(var[treat == 0], na.rm = TRUE)
wmean <- function(y, sigma, k) { one <- rep(1, k); solve(t(one) %*% solve(sigma) %*% one) %*% (t(one) %*% solve(sigma) %*% y) }
s <- as.data.frame(survey_raw)
for (x in c("femhouse", "fempol", "equality", "discrimination", "harassment", "poverty", "corruption", "gap", "cct"))
  s[[paste0(x, ".est")]] <- standard(s[[x]], s$treatment)
mk_index <- function(cols) {
  o <- as.matrix(s[, cols]); cc <- complete.cases(o)
  sig <- cov(o[cc, ]); out <- rep(NA_real_, nrow(s))
  out[cc] <- apply(o[cc, ], 1, wmean, sig, ncol(o)); out
}
s$sexism <- mk_index(c("femhouse.est", "fempol.est", "equality.est", "discrimination.est", "harassment.est"))
s$poverty.all <- mk_index(c("poverty.est", "cct.est", "gap.est", "corruption.est"))

## ---------------- attendance weights (survey_agg merge; fastLink replaced by exact barangay-name match)
sagg <- s %>% filter(!is.na(barangay)) %>% group_by(barangay) %>%
  summarise(obs = n(), attendance = sum(attendance, na.rm = TRUE), .groups = "drop") %>%
  mutate(attendance.agg = attendance / obs * 100, barangay = as.character(barangay))
off <- data.all %>% filter(treatment == 1) %>% mutate(barangay = as.character(barangay), att.prop = att.prop * 100) %>%
  select(barangay, att.prop)
wt <- inner_join(sagg, off, by = "barangay") %>%
  mutate(weight.att = ifelse(attendance.agg > 0, att.prop / attendance.agg, 1))
print(as.data.frame(wt))
wt <- wt %>% select(barangay, weight.att)
s$barangay_chr <- as.character(s$barangay)
s <- left_join(s, wt, by = c("barangay_chr" = "barangay"))
s$weight.att <- ifelse(s$treatment == 0, 1, s$weight.att)
cat("treated rows missing weight:", sum(is.na(s$weight.att) & s$treatment == 1, na.rm = TRUE), "\n")

## ---------------- SI Tables C.3 / C.4: indices by party, weighted, city FE
fit_w <- function(v, party, wvar) {
  d <- s[s$partytreat == party, c(v, "barangay", "assignment", "treatment", "city", wvar)]
  d <- d[complete.cases(d), ]; d$city <- factor(as.character(d$city))
  m <- lm(as.formula(paste(v, "~ assignment + city")), weights = d[[wvar]], data = d)
  list(b = unname(coef(m)["assignment"]), n = nrow(d))
}
pov_ak <- fit_w("poverty.all", "Akbayan", "weight.att")
pov_um <- fit_w("poverty.all", "Umalab Ka", "weight.att")
sex_ak <- fit_w("sexism", "Akbayan", "weight.att")
sex_um <- fit_w("sexism", "Umalab Ka", "weight.att")
cat(sprintf("C3/C4 N: %d %d %d %d\n", pov_ak$n, pov_um$n, sex_ak$n, sex_um$n))

## ---------------- SI Table F.1: unweighted (assignment-probability weights only)
s$turnout_pl <- s$turnout_pl * 100; s$vote <- s$vote * 100
s$vote.akbayan <- s$vote.akbayan * 100; s$vote.umalabka <- s$vote.umalabka * 100
ok <- !is.na(s$city) & !is.na(s$barangay)
s$weight.assign <- NA_real_
pa <- probexact(s$assignment[ok], s$city[ok], s$barangay[ok])
s$weight.assign[ok] <- s$assignment[ok] / pa + (1 - s$assignment[ok]) / (1 - pa)
fit_f <- function(v, party = NULL) {
  d <- if (is.null(party)) s else s[s$partytreat == party, ]
  d <- d[, c(v, "barangay", "city", "assignment", "treatment", "weight.assign")]
  d <- d[complete.cases(d), ]; d$city <- factor(as.character(d$city))
  m <- lm(as.formula(paste(v, "~ assignment + city")), weights = weight.assign, data = d)
  list(b = unname(coef(m)["assignment"]), n = nrow(d))
}
f_vote <- fit_f("vote"); f_ak <- fit_f("vote.akbayan", "Akbayan")
cat(sprintf("F1 N: %d %d\n", f_vote$n, f_ak$n))

cat(sprintf("RESULT:itt_turnout_barangay_table1_col1=%.6f\n", res[["turnout.party"]]$b))
cat(sprintf("RESULT:itt_vote_overall_barangay_table1_col2=%.6f\n", res[["share.treated"]]$b))
cat(sprintf("RESULT:itt_vote_akbayan_barangay_table1_col3=%.6f\n", res[["share.akbayan"]]$b))
cat(sprintf("RESULT:itt_vote_umalabka_barangay_table1_col4=%.6f\n", res[["share.umalabka"]]$b))
cat(sprintf("RESULT:n_obs_barangay_table1_cols1_2=%d\n", res[["share.treated"]]$n))
cat(sprintf("RESULT:n_obs_barangay_akbayan_table1_col3=%d\n", res[["share.akbayan"]]$n))
cat(sprintf("RESULT:n_obs_barangay_umalabka_table1_col4=%d\n", res[["share.umalabka"]]$n))
cat(sprintf("RESULT:itt_poverty_index_akbayan_tableC3=%.6f\n", pov_ak$b))
cat(sprintf("RESULT:itt_poverty_index_umalabka_tableC3=%.6f\n", pov_um$b))
cat(sprintf("RESULT:itt_gender_index_akbayan_tableC4=%.6f\n", sex_ak$b))
cat(sprintf("RESULT:itt_gender_index_umalabka_tableC4=%.6f\n", sex_um$b))
cat(sprintf("RESULT:itt_vote_overall_unweighted_tableF1_col2=%.6f\n", f_vote$b))
cat(sprintf("RESULT:itt_vote_akbayan_unweighted_tableF1_col3=%.6f\n", f_ak$b))
cat("DEVIATION: fastLink record linkage of survey to official barangays replaced by exact barangay-name match (treated barangays share names in both files); ri::estate/genprobexact computed directly.\n")
