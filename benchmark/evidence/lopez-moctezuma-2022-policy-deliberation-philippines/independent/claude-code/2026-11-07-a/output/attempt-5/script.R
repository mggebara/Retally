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
    idx <- which(df$key == b); r <- a[a$key == b, ]
    p_true <- if (grepl("turn", type)) r$att.prop.turn else r$att.prop
    p_surv <- mean(df$att0[idx])
    if (p_surv > 0) {
      if (grepl("both", type)) w[idx] <- ifelse(df$att0[idx] == 1, p_true / p_surv, (1 - p_true) / (1 - p_surv))
      if (grepl("att", type))  w[idx] <- ifelse(df$att0[idx] == 1, p_true / p_surv, 1)
    }
  }
  if (grepl("pop", type)) {   # inverse sampling probability incl. barangay size
    for (b in unique(df$key)) { idx <- which(df$key == b); r <- a[a$key == b, ]
      w[idx] <- w[idx] * r$reg.num / length(idx) }
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
eff <- s[!is.na(s$turnout_pl), ]
eff$rpoverty <- 6 - eff$poverty; eff$rgap <- 6 - eff$gap; eff$rcorruption <- 6 - eff$corruption
eff$rdiscrimination <- 6 - eff$discrimination
for (wt in c("none", "both", "att", "both_turn", "att_turn", "both_pop", "none_pop")) {
  eff$w <- mkw(eff, wt)
  v <- subset(eff, turnout_pl == 1)
  r <- c(turn = coef(feols(I(100*turnout_pl) ~ assignment | city, data = eff, weights = ~w))[[1]],
         vote = coef(feols(I(100*vote) ~ assignment | city, data = v, weights = ~w))[[1]],
         vak = coef(feols(I(100*vote.akbayan) ~ assignment | city, data = subset(v, partytreat == "Akbayan"), weights = ~w))[[1]],
         vum = coef(feols(I(100*vote.umalabka) ~ assignment | city, data = subset(v, partytreat == "Umalab Ka"), weights = ~w))[[1]])
  for (pt in c("Akbayan", "Umalab Ka")) {
    d <- subset(eff, partytreat == pt); ctrl <- d$assignment == 0
    for (nm in c("pov", "gen")) {
      it <- if (nm == "pov") c("rpoverty", "rgap", "cct", "rcorruption") else c("femhouse", "fempol", "equality", "rdiscrimination", "harassment")
      d$y <- anderson(d, it)$idx
      r[paste(substr(pt,1,2), nm)] <- coef(feols(y ~ assignment | city, data = d, weights = ~w))[[1]]
      for (v1 in it) { x <- d[[v1]]; d$y <- (x - mean(x[ctrl], na.rm=TRUE))/sd(x[ctrl], na.rm=TRUE)
        r[paste(substr(pt,1,2), v1)] <- coef(feols(y ~ assignment | city, data = d, weights = ~w))[[1]] }
    }
  }
  cat("weights:", wt, "\n"); print(round(r, 3))
}
