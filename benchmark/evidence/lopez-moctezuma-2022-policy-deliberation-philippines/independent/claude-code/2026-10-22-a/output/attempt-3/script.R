## Independent reproduction: Lopez-Moctezuma et al. (2022), AJPS
## Policy Deliberation and Voter Persuasion (Philippines)
suppressPackageStartupMessages({ library(fixest) })
set.seed(42)
M <- "<repo>/benchmark/.cache/claude-code/lopez-moctezuma-2022-policy-deliberation-philippines/independent/2026-10-22-a/mount/lopez_moctezuma_2022_policy_deliberation_philippines"
load(file.path(M, "data_agg.RData"))
load(file.path(M, "survey_raw.RData"))

## ---------------- Table 1: barangay level, eq. (1) ----------------
agg <- data.all
agg$city <- as.character(agg$city)
m1 <- feols(turnout.party ~ assignment | city, data = agg)
m2 <- feols(share.treated ~ assignment | city, data = agg)
ak <- subset(agg, partytreat == "akbayan")
um <- subset(agg, partytreat == "umalabka")
m3 <- feols(share.akbayan ~ assignment | city, data = ak)
m4 <- feols(share.umalabka ~ assignment | city, data = um)

## permutation p-values: within-municipality re-assignment of the single
## assigned barangay (3 choices per municipality), exhaustive or sampled
perm_p <- function(d, y, B = 5000) {
  obs <- coef(feols(as.formula(paste(y, "~ assignment | city")), data = d))[["assignment"]]
  cities <- unique(d$city)
  draws <- replicate(B, {
    dd <- d
    for (c in cities) {
      idx <- which(dd$city == c)
      dd$assignment[idx] <- sample(dd$assignment[idx])
    }
    coef(feols(as.formula(paste(y, "~ assignment | city")), data = dd))[["assignment"]]
  })
  mean(abs(draws) >= abs(obs) - 1e-12)
}
print(etable(m1, m2, m3, m4))

## ---------------- Individual level ----------------
s <- as.data.frame(survey_raw)
s$city <- as.character(s$city)
s$barangay <- as.character(s$barangay)
s <- s[!is.na(s$city) & !is.na(s$assignment), ]
## effective sample: valid party-list turnout response (paper fn 11: 1,082)
s <- s[!is.na(s$turnout_pl), ]
cat("Effective survey N:", nrow(s), "\n")

## IPW for oversampling of meeting attendees in treated barangays:
## survey attendee share vs. actual attendee share (attendance sheets / registered voters)
att <- agg[agg$att.prop > 0, c("barangay", "att.prop")]
att$barangay <- as.character(att$barangay)
s$w <- 1
for (b in att$barangay) {
  idx <- which(s$barangay == b & !is.na(s$attendance))
  if (length(idx) == 0) { cat("no survey match for", b, "\n"); next }
  ps <- mean(s$attendance[idx])
  pa <- att$att.prop[att$barangay == b]
  s$w[idx] <- ifelse(s$attendance[idx] == 1, pa / ps, (1 - pa) / (1 - ps))
}
print(aggregate(w ~ barangay + attendance, data = s[s$w != 1, ], FUN = mean))

## ---- Table F.1: unweighted vote ITT (among respondents who turned out) ----
v <- s[s$turnout_pl == 1, ]
v$vote100 <- 100 * v$vote
v$vak100 <- 100 * v$vote.akbayan
f2 <- feols(vote100 ~ assignment | city, data = v, cluster = ~barangay)
f3 <- feols(vak100 ~ assignment | city, data = subset(v, partytreat == "Akbayan"), cluster = ~barangay)
print(etable(f2, f3))

## ---- Tables C.3/C.4: Anderson (2008) summary indices ----
rev5 <- function(x) 6 - x
s$o_poverty <- rev5(s$poverty)       # higher = more agreement it is a main problem
s$o_gap <- rev5(s$gap)
s$o_corruption <- rev5(s$corruption)
s$o_cct <- s$cct
s$o_femrep <- s$femhouse             # female rep. does equal/better job
s$o_fempol <- s$fempol
s$o_equality <- s$equality           # disagree that equality demands = special favors
s$o_discrimination <- rev5(s$discrimination) # agree women miss jobs due to discrimination
s$o_harassment <- s$harassment       # disagree that complainants cause problems
pov_items <- c("o_poverty", "o_gap", "o_cct", "o_corruption")
gen_items <- c("o_femrep", "o_fempol", "o_equality", "o_discrimination", "o_harassment")

anderson_index <- function(d, items) {
  ctrl <- d$assignment == 0
  Z <- sapply(items, function(k) {
    x <- d[[k]]
    (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE)
  })
  S <- cov(Z, use = "pairwise.complete.obs")
  wts <- rowSums(solve(S))
  idx <- apply(Z, 1, function(z) {
    ok <- !is.na(z)
    if (!any(ok)) return(NA_real_)
    sum(wts[ok] * z[ok]) / sum(wts[ok])
  })
  (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
}

itt_index <- function(party, items) {
  d <- s[s$partytreat == party, ]
  d$index <- anderson_index(d, items)
  m <- feols(index ~ assignment | city, data = d, weights = ~w, cluster = ~barangay)
  print(summary(m))
  coef(m)[["assignment"]]
}
pov_ak <- itt_index("Akbayan", pov_items)
pov_um <- itt_index("Umalab Ka", pov_items)
gen_ak <- itt_index("Akbayan", gen_items)
gen_um <- itt_index("Umalab Ka", gen_items)

## ---- Diagnostics: sensitivity of the summary indices to construction choices ----
s$w_turn <- 1
att2 <- agg[agg$att.prop > 0, c("barangay", "att.prop.turn")]
for (b in as.character(att2$barangay)) {
  idx <- which(s$barangay == b & !is.na(s$attendance))
  if (length(idx) == 0) next
  ps <- mean(s$attendance[idx]); pa <- att2$att.prop.turn[att2$barangay == b]
  s$w_turn[idx] <- ifelse(s$attendance[idx] == 1, pa / ps, (1 - pa) / (1 - ps))
}
s$w_none <- 1
raw <- c(poverty = "poverty", gap = "gap", cct = "cct", corruption = "corruption",
         femrep = "femhouse", fempol = "fempol", equality = "equality",
         discrimination = "discrimination", harassment = "harassment")
idx_fun <- function(d, items, covctrl, complete) {
  ctrl <- d$assignment == 0
  Z <- sapply(items, function(k) { x <- d[[k]]; (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE) })
  if (complete) Z[!complete.cases(Z), ] <- NA
  S <- if (covctrl) cov(Z[ctrl, ], use = "pairwise.complete.obs") else cov(Z, use = "pairwise.complete.obs")
  wts <- rowSums(solve(S))
  ix <- apply(Z, 1, function(z) { ok <- !is.na(z); if (!any(ok)) NA_real_ else sum(wts[ok] * z[ok]) / sum(wts[ok]) })
  (ix - mean(ix[ctrl], na.rm = TRUE)) / sd(ix[ctrl], na.rm = TRUE)
}
for (orient in c("pos", "raw")) {
  for (k in names(raw)) s[[paste0("g_", k)]] <- s[[raw[[k]]]]
  if (orient == "pos") for (k in c("poverty", "gap", "corruption", "discrimination")) s[[paste0("g_", k)]] <- 6 - s[[paste0("g_", k)]]
  for (wv in c("w", "w_turn", "w_none")) for (covctrl in c(FALSE, TRUE)) for (complete in c(FALSE, TRUE)) {
    out <- c()
    for (party in c("Akbayan", "Umalab Ka")) for (set in list(c("g_poverty","g_gap","g_cct","g_corruption"), c("g_femrep","g_fempol","g_equality","g_discrimination","g_harassment"))) {
      d <- s[s$partytreat == party, ]
      d$ix <- idx_fun(d, set, covctrl, complete)
      d$ww <- d[[wv]]
      out <- c(out, coef(feols(ix ~ assignment | city, data = d, weights = ~ww, notes = FALSE))[["assignment"]])
    }
    cat(sprintf("GRID orient=%s wt=%s covctrl=%s complete=%s | povAk=%.3f genAk=%.3f povUm=%.3f genUm=%.3f\n",
                orient, wv, covctrl, complete, out[1], out[2], out[3], out[4]))
  }
}
## item-level standardized ITTs (raw orientation, main weights)
for (party in c("Akbayan", "Umalab Ka")) {
  d <- s[s$partytreat == party, ]; ctrl <- d$assignment == 0
  for (k in names(raw)) {
    x <- d[[raw[[k]]]]; d$z <- (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE)
    cat(sprintf("ITEM %s %s raw-orient ITT=%.3f\n", party, k, coef(feols(z ~ assignment | city, data = d, weights = ~w, notes = FALSE))[["assignment"]]))
  }
}

cat(sprintf("RESULT:itt_turnout_barangay_table1_col1=%.6f\n", coef(m1)[["assignment"]]))
cat(sprintf("RESULT:itt_vote_overall_barangay_table1_col2=%.6f\n", coef(m2)[["assignment"]]))
cat(sprintf("RESULT:itt_vote_akbayan_barangay_table1_col3=%.6f\n", coef(m3)[["assignment"]]))
cat(sprintf("RESULT:itt_vote_umalabka_barangay_table1_col4=%.6f\n", coef(m4)[["assignment"]]))
cat(sprintf("RESULT:n_obs_barangay_table1_cols1_2=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_barangay_akbayan_table1_col3=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_barangay_umalabka_table1_col4=%d\n", nobs(m4)))
cat(sprintf("RESULT:itt_poverty_index_akbayan_tableC3=%.6f\n", pov_ak))
cat(sprintf("RESULT:itt_poverty_index_umalabka_tableC3=%.6f\n", pov_um))
cat(sprintf("RESULT:itt_gender_index_akbayan_tableC4=%.6f\n", gen_ak))
cat(sprintf("RESULT:itt_gender_index_umalabka_tableC4=%.6f\n", gen_um))
cat(sprintf("RESULT:itt_vote_overall_unweighted_tableF1_col2=%.6f\n", coef(f2)[["assignment"]]))
cat(sprintf("RESULT:itt_vote_akbayan_unweighted_tableF1_col3=%.6f\n", coef(f3)[["assignment"]]))
