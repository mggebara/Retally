# Exploratory: index construction variants (no RESULT lines)
suppressPackageStartupMessages({ library(fixest) })
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/independent/2026-11-07-a/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(D, "data_agg.RData")); load(file.path(D, "survey_raw.RData"))
a <- data.all
s <- as.data.frame(survey_raw)
s$city <- as.character(s$city); s$barangay <- as.character(s$barangay)
s <- s[!is.na(s$city) & !is.na(s$barangay) & !is.na(s$assignment), ]
norm <- function(x) tolower(gsub("[^A-Za-z0-9]", "", x))
a$key <- norm(a$barangay); s$key <- norm(s$barangay)
s$key[s$key == "bfhomes"] <- norm("B.F Homes")
s$att0 <- ifelse(is.na(s$attendance), 0, s$attendance)
mkw <- function(df, type) {
  w <- rep(1, nrow(df))
  if (type == "none") return(w)
  for (b in unique(df$key[df$treatment == 1])) {
    idx <- which(df$key == b); p_true <- a$att.prop[a$key == b]; p_surv <- mean(df$att0[idx])
    if (p_surv > 0) {
      if (type == "both") w[idx] <- ifelse(df$att0[idx] == 1, p_true / p_surv, (1 - p_true) / (1 - p_surv))
      if (type == "att")  w[idx] <- ifelse(df$att0[idx] == 1, p_true / p_surv, 1)
    }
  }
  w
}
anderson <- function(df, items, restd = TRUE, wcol = NULL) {
  ctrl <- df$assignment == 0
  Z <- sapply(items, function(v) { x <- df[[v]]; (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE) })
  S <- cov(Z, use = "pairwise.complete.obs"); wt <- rowSums(solve(S))
  idx <- apply(Z, 1, function(z) { ok <- !is.na(z); if (!any(ok)) return(NA_real_); sum(wt[ok] * z[ok]) / sum(wt[ok]) })
  if (restd) idx <- (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
  list(idx = idx, Z = Z)
}
for (sampl in c("eff", "full")) for (wt in c("both", "att", "none")) {
  base <- if (sampl == "eff") s[!is.na(s$turnout_pl), ] else s
  base$w <- mkw(base, wt)
  base$rpoverty <- 6 - base$poverty; base$rgap <- 6 - base$gap; base$rcorruption <- 6 - base$corruption
  base$requality <- 6 - base$equality; base$rdiscrimination <- 6 - base$discrimination; base$rharassment <- 6 - base$harassment
  sets <- list(
    pov_rev = c("rpoverty", "rgap", "cct", "rcorruption"),
    pov_raw = c("poverty", "gap", "cct", "corruption"),
    gen_A = c("femhouse", "fempol", "equality", "rdiscrimination", "harassment"),
    gen_allrev = c("femhouse", "fempol", "requality", "rdiscrimination", "rharassment"),
    gen_raw = c("femhouse", "fempol", "equality", "discrimination", "harassment"))
  for (pt in c("Akbayan", "Umalab Ka")) {
    d <- subset(base, partytreat == pt)
    out <- c()
    for (nm in names(sets)) for (rs in c(TRUE, FALSE)) {
      r <- anderson(d, sets[[nm]], rs); d$y <- r$idx
      out[paste0(nm, ifelse(rs, "", "_nors"))] <- coef(feols(y ~ assignment | city, data = d, weights = ~w))[[1]]
    }
    cat(sampl, wt, pt, "\n"); print(round(out, 3))
    if (sampl == "eff" && wt == "both") {
      allit <- unique(unlist(sets))
      ctrl <- d$assignment == 0
      it <- sapply(allit, function(v) { x <- d[[v]]; d$y <- (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE); coef(feols(y ~ assignment | city, data = d, weights = ~w))[[1]] })
      cat("item ITTs:\n"); print(round(it, 3))
    }
  }
}
