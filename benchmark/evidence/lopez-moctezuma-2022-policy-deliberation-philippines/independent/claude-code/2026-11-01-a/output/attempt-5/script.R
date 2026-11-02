suppressPackageStartupMessages({library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/independent/2026-11-01-a/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D, "data_agg.RData")); load(file.path(D, "survey_raw.RData"))

## ---------------- Table 1: barangay level, eq. (1) ----------------
a <- data.all
a$city <- factor(a$city)
m1 <- lm(turnout.party ~ assignment + city, data = a)
m2 <- lm(share.treated ~ assignment + city, data = a)
aA <- subset(a, partytreat == "akbayan"); aU <- subset(a, partytreat == "umalabka")
m3 <- lm(share.akbayan ~ assignment + city, data = droplevels(aA))
m4 <- lm(share.umalabka ~ assignment + city, data = droplevels(aU))

## ---------------- Survey data ----------------
s <- as.data.frame(survey_raw)
s$barangay <- as.character(s$barangay); s$city <- as.character(s$city)
s <- s[!is.na(s$barangay) & !is.na(s$city), ]
# effective sample: valid turnout response (paper fn. 11: 1,082)
s <- s[!is.na(s$turnout_pl), ]
s$party <- gsub("[^a-z]", "", tolower(s$partytreat))
cat("party values:", unique(s$party), "\n")

# attendance weights: match survey barangay names to aggregate names
fix <- c("B. F. Homes" = "B.F Homes", "Escopa IV" = "Escopa 4",
         "Barangay Zone VI (Pob.)" = "Barangay Zone VI", "Putho Tuntungin" = "Putho",
         "Santo Rosario-Silangan" = "San Rosario-Silangan")
s$brgy_agg <- ifelse(s$barangay %in% names(fix), fix[s$barangay], s$barangay)
s$att_true <- a$att.prop[match(s$brgy_agg, a$barangay)]
s$w <- 1
for (b in unique(s$barangay)) {
  idx <- which(s$barangay == b & !is.na(s$attendance))
  pt <- s$att_true[idx][1]
  ps <- mean(s$attendance[idx])
  if (!is.na(pt) && pt > 0 && ps > 0 && ps < 1) {
    s$w[idx] <- ifelse(s$attendance[idx] == 1, pt / ps, (1 - pt) / (1 - ps))
  }
}

## ---------------- Anderson (2008) summary index ----------------
anderson <- function(df, items, ctrl) {
  Z <- sapply(items, function(v) {
    x <- df[[v]]; (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE)
  })
  S <- cov(Z, use = "pairwise.complete.obs")
  wts <- rowSums(solve(S))
  idx <- apply(Z, 1, function(z) { ok <- !is.na(z); if (!any(ok)) NA else sum(wts[ok] * z[ok]) / sum(wts[ok]) })
  (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
}
# orientation: higher = more agreement with party's concern
s$pov_o <- 6 - s$poverty; s$gap_o <- 6 - s$gap; s$cor_o <- 6 - s$corruption; s$cct_o <- s$cct
s$femrep_o <- s$femhouse; s$fempol_o <- s$fempol
s$equal_o <- s$equality; s$harass_o <- s$harassment; s$discr_o <- 6 - s$discrimination

att_fit <- function(party, items) {
  d <- s[s$party == party, ]
  ctrl <- d$assignment == 0
  d$idx <- anderson(d, items, ctrl)
  feols(idx ~ assignment | city, data = d, weights = ~w, cluster = ~barangay)
}
pov_items <- c("pov_o", "gap_o", "cct_o", "cor_o")
gen_items <- c("femrep_o", "fempol_o", "equal_o", "discr_o", "harass_o")
pA <- att_fit("akbayan", pov_items); pU <- att_fit("umalabka", pov_items)
gA <- att_fit("akbayan", gen_items); gU <- att_fit("umalabka", gen_items)

## ---------------- Table F.1 unweighted vote ----------------
sv <- s[s$turnout_pl == 1, ]
f2 <- feols(I(100 * vote) ~ assignment | city, data = sv, cluster = ~barangay)
f3 <- feols(I(100 * vote.akbayan) ~ assignment | city, data = sv[sv$party == "akbayan", ], cluster = ~barangay)


## ---------------- DIAGNOSTIC GRID (not RESULT lines) ----------------
sall <- as.data.frame(survey_raw)
sall$barangay <- as.character(sall$barangay); sall$city <- as.character(sall$city)
sall <- sall[!is.na(sall$barangay) & !is.na(sall$city), ]
sall$party <- gsub("[^a-z]", "", tolower(sall$partytreat))
sall$brgy_agg <- ifelse(sall$barangay %in% names(fix), fix[sall$barangay], sall$barangay)
mkw <- function(d, col) {
  tru <- a[[col]][match(d$brgy_agg, a$barangay)]
  w <- rep(1, nrow(d))
  for (b in unique(d$barangay)) {
    idx <- which(d$barangay == b & !is.na(d$attendance))
    pt <- tru[idx][1]; ps <- mean(d$attendance[idx])
    if (length(idx) && !is.na(pt) && pt > 0 && ps > 0 && ps < 1)
      w[idx] <- ifelse(d$attendance[idx] == 1, pt / ps, (1 - pt) / (1 - ps))
  }
  w
}
orient <- function(d, flip) {
  d$pov_o <- 6 - d$poverty; d$gap_o <- 6 - d$gap; d$cor_o <- 6 - d$corruption; d$cct_o <- d$cct
  d$femrep_o <- d$femhouse; d$fempol_o <- d$fempol
  d$equal_o <- d$equality; d$harass_o <- d$harassment; d$discr_o <- 6 - d$discrimination
  for (v in flip) d[[v]] <- if (all(d[[v]] %in% c(0, 1, NA))) 1 - d[[v]] else 6 - d[[v]]
  d
}
anderson2 <- function(df, items, ctrl, restd = TRUE, cc = FALSE) {
  Z <- sapply(items, function(v) { x <- df[[v]]; (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE) })
  S <- if (cc) cov(Z, use = "complete.obs") else cov(Z, use = "pairwise.complete.obs")
  wts <- rowSums(solve(S))
  idx <- apply(Z, 1, function(z) { ok <- !is.na(z); if (cc && !all(ok)) return(NA); if (!any(ok)) NA else sum(wts[ok] * z[ok]) / sum(wts[ok]) })
  if (restd) (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE) else idx
}
est <- function(d, y, wv) {
  d$.y <- y; d$.w <- wv
  if (all(is.na(y))) return(NA)
  coef(feols(.y ~ assignment | city, data = d, weights = ~.w, notes = FALSE))["assignment"]
}

## ---------------- DIAGNOSTIC: weight schemes (not RESULT lines) ----------------
sall <- as.data.frame(survey_raw)
sall$barangay <- as.character(sall$barangay); sall$city <- as.character(sall$city)
sall <- sall[!is.na(sall$barangay) & !is.na(sall$city), ]
sall$party <- gsub("[^a-z]", "", tolower(sall$partytreat))
sall$brgy_agg <- ifelse(sall$barangay %in% names(fix), fix[sall$barangay], sall$barangay)
sall$reg <- a$reg.num[match(sall$brgy_agg, a$barangay)]
sall$vtot <- a$vote.num.party[match(sall$brgy_agg, a$barangay)]
cat("unmatched barangays:", unique(sall$barangay[is.na(sall$reg)]), "\n")
mkw2 <- function(d, scheme, col, basis) {
  tru <- a[[col]][match(d$brgy_agg, a$barangay)]
  pop <- if (col == "att.prop") d$reg else d$vtot
  w <- rep(1, nrow(d))
  for (b in unique(d$barangay)) {
    all_b <- which(d$barangay == b)
    idx <- all_b[!is.na(d$attendance[all_b])]
    base <- if (basis == "full") sall[sall$barangay == b & !is.na(sall$attendance), ] else d[idx, ]
    pt <- tru[idx][1]; ps <- mean(base$attendance); n <- nrow(base)
    N <- pop[idx][1]; Na <- pt * N; na <- sum(base$attendance)
    att <- d$attendance[idx] == 1
    if (scheme == "D") { w[all_b] <- N / n }
    if (length(idx) && !is.na(pt) && pt > 0 && ps > 0 && ps < 1) {
      w[idx] <- switch(scheme,
        A = ifelse(att, pt / ps, (1 - pt) / (1 - ps)),
        B = ifelse(att, pt / ps, 1),
        C = ifelse(att, ps / pt, 1),
        D = ifelse(att, Na / na, (N - Na) / (n - na)),
        E = ifelse(att, Na / na, 1))
    }
  }
  w
}
pov_items <- c("pov_o", "gap_o", "cct_o", "cor_o")
gen_items <- c("femrep_o", "fempol_o", "equal_o", "discr_o", "harass_o")
d0 <- orient(sall[!is.na(sall$turnout_pl), ], character(0))
for (col in c("att.prop", "att.prop.turn")) for (basis in c("analysis", "full")) for (sc in c("A", "B", "C", "D", "E")) {
  d <- d0; d$wv <- mkw2(d, sc, col, basis)
  dv <- d[d$turnout_pl == 1, ]
  vo <- est(dv, 100 * dv$vote, dv$wv)
  va <- est(dv[dv$party == "akbayan", ], 100 * dv$vote.akbayan[dv$party == "akbayan"], dv$wv[dv$party == "akbayan"])
  vu <- est(dv[dv$party == "umalabka", ], 100 * dv$vote.umalabka[dv$party == "umalabka"], dv$wv[dv$party == "umalabka"])
  tu <- est(d, 100 * d$turnout_pl, d$wv)
  ix <- c()
  for (pool in c("party", "pooled")) for (p in c("akbayan", "umalabka")) for (it in list(pov_items, gen_items)) {
    if (pool == "pooled") { dd <- d; dd$ix <- anderson2(dd, it, dd$assignment == 0); dd <- dd[dd$party == p, ] }
    else { dd <- d[d$party == p, ]; dd$ix <- anderson2(dd, it, dd$assignment == 0) }
    ix <- c(ix, est(dd, dd$ix, dd$wv))
  }
  items <- c()
  dd <- d[d$party == "akbayan", ]; ctrl <- dd$assignment == 0
  for (v in c("fempol_o", "discr_o")) { x <- dd[[v]]; items <- c(items, est(dd, (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE), dd$wv)) }
  dd <- d[d$party == "umalabka", ]; ctrl <- dd$assignment == 0
  x <- dd$cct_o; items <- c(items, est(dd, (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE), dd$wv))
  cat(sprintf("%-13s %-8s %s | turn %.2f vote %.2f vA %.2f vU %.2f | party: povA %.3f genA %.3f povU %.3f genU %.3f | pooled: povA %.3f genA %.3f povU %.3f genU %.3f | A.fempol %.2f A.discr %.2f U.cct %.2f\n",
              col, basis, sc, tu, vo, va, vu, ix[1], ix[2], ix[3], ix[4], ix[5], ix[6], ix[7], ix[8], items[1], items[2], items[3]))
}
cat("Survey effective sample:", nrow(s), " voters:", nrow(sv), "\n")
cat("N F1 col2:", nobs(f2), " col3:", nobs(f3), "\n")
cat("N attitudes:", nobs(pA), nobs(pU), nobs(gA), nobs(gU), "\n")

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("itt_turnout_barangay_table1_col1", coef(m1)["assignment"])
r("itt_vote_overall_barangay_table1_col2", coef(m2)["assignment"])
r("itt_vote_akbayan_barangay_table1_col3", coef(m3)["assignment"])
r("itt_vote_umalabka_barangay_table1_col4", coef(m4)["assignment"])
r("n_obs_barangay_table1_cols1_2", nobs(m2))
r("n_obs_barangay_akbayan_table1_col3", nobs(m3))
r("n_obs_barangay_umalabka_table1_col4", nobs(m4))
r("itt_poverty_index_akbayan_tableC3", coef(pA)["assignment"])
r("itt_poverty_index_umalabka_tableC3", coef(pU)["assignment"])
r("itt_gender_index_akbayan_tableC4", coef(gA)["assignment"])
r("itt_gender_index_umalabka_tableC4", coef(gU)["assignment"])
r("itt_vote_overall_unweighted_tableF1_col2", coef(f2)["assignment"])
r("itt_vote_akbayan_unweighted_tableF1_col3", coef(f3)["assignment"])
