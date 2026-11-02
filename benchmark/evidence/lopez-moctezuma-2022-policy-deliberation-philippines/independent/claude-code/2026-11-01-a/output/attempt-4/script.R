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
pov_items <- c("pov_o", "gap_o", "cct_o", "cor_o")
gen_items <- c("femrep_o", "fempol_o", "equal_o", "discr_o", "harass_o")
grid <- expand.grid(samp = c("turnout_nonNA", "all", "voted"), pool = c("party", "pooled"),
                    wt = c("att.prop", "att.prop.turn", "none"), restd = c(TRUE, FALSE), cc = c(FALSE, TRUE),
                    stringsAsFactors = FALSE)
for (flip in list(character(0), c("fempol_o"), c("discr_o"), c("fempol_o", "discr_o"), c("femrep_o"))) {
  cat("=== flip:", if (length(flip)) paste(flip, collapse = ",") else "none", "\n")
  for (g in seq_len(nrow(grid))) {
    G <- grid[g, ]
    d <- sall
    if (G$samp == "turnout_nonNA") d <- d[!is.na(d$turnout_pl), ]
    if (G$samp == "voted") d <- d[d$turnout_pl %in% 1, ]
    d <- orient(d, flip)
    d$wv <- if (G$wt == "none") 1 else mkw(d, G$wt)
    out <- c()
    for (p in c("akbayan", "umalabka")) for (it in list(pov = pov_items, gen = gen_items)) {
      if (G$pool == "pooled") {
        dd <- d; dd$ix <- anderson2(dd, it, dd$assignment == 0, G$restd, G$cc); dd <- dd[dd$party == p, ]
      } else {
        dd <- d[d$party == p, ]; dd$ix <- anderson2(dd, it, dd$assignment == 0, G$restd, G$cc)
      }
      out <- c(out, est(dd, dd$ix, dd$wv))
    }
    cat(sprintf("%-14s %-7s %-14s restd=%d cc=%d | povA %.3f genA %.3f povU %.3f genU %.3f\n",
                G$samp, G$pool, G$wt, G$restd, G$cc, out[1], out[2], out[3], out[4]))
  }
}
cat("=== per-item standardized ITTs (party-specific control mean/sd), turnout_nonNA sample\n")
for (wt in c("att.prop", "att.prop.turn", "none")) for (samp in c("turnout_nonNA", "all")) {
  d <- if (samp == "all") sall else sall[!is.na(sall$turnout_pl), ]
  d <- orient(d, character(0)); d$wv <- if (wt == "none") 1 else mkw(d, wt)
  for (p in c("akbayan", "umalabka")) {
    dd <- d[d$party == p, ]; ctrl <- dd$assignment == 0
    res <- sapply(c(pov_items, gen_items), function(v) { x <- dd[[v]]; z <- (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE); est(dd, z, dd$wv) })
    cat(sprintf("%-14s %-14s %-9s ", wt, samp, p), paste(sprintf("%s=%.3f", c(pov_items, gen_items), res), collapse = " "), "\n")
  }
}
cat("=== F.1 sample variants\n")
for (samp in c("turnout_pl==1", "vote nonNA all")) {
  d <- if (samp == "turnout_pl==1") sall[sall$turnout_pl %in% 1, ] else sall[!is.na(sall$vote), ]
  cat(samp, nrow(d), est(d, 100 * d$vote, rep(1, nrow(d))), est(d[d$party == "akbayan", ], 100 * d$vote.akbayan[d$party == "akbayan"], rep(1, sum(d$party == "akbayan"))), "\n")
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
