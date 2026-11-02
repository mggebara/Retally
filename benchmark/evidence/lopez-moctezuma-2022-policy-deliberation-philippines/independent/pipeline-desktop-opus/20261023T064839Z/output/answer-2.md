suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines.script-free"
load(file.path(base, "data_agg.RData"))
load(file.path(base, "survey_raw.RData"))

emit <- function(name, val) {
  if (length(val) == 1 && !is.na(val) && is.finite(val)) {
    cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
  }
}

unlab <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  x
}

normtxt <- function(x) gsub("[^a-z]", "", tolower(as.character(unlab(x))))

to01 <- function(x) {
  x <- unlab(x)
  if (is.logical(x)) return(as.numeric(x))
  if (is.character(x)) {
    lx <- tolower(trimws(x))
    num <- suppressWarnings(as.numeric(lx))
    out <- ifelse(!is.na(num), num,
           ifelse(lx %in% c("yes", "y", "true", "treatment", "treated", "assigned", "voted", "attended", "t"), 1,
           ifelse(lx %in% c("no", "n", "false", "control", "not voted", "did not vote", "didn't vote", "not assigned", "c"), 0, NA)))
    return(as.numeric(out))
  }
  as.numeric(x)
}

likert <- function(x) {
  x <- unlab(x)
  if (is.character(x)) {
    lx <- tolower(trimws(x))
    num <- suppressWarnings(as.numeric(lx))
    out <- rep(NA_real_, length(lx))
    out[!is.na(num)] <- num[!is.na(num)]
    nn <- is.na(num)
    out[nn & grepl("strongly disagree", lx)] <- 1
    out[nn & is.na(out) & grepl("disagree", lx)] <- 2
    out[nn & is.na(out) & grepl("neither|neutral|undecided", lx)] <- 3
    out[nn & is.na(out) & grepl("strongly agree", lx)] <- 5
    out[nn & is.na(out) & grepl("agree", lx)] <- 4
    out[nn & is.na(out) & lx %in% c("yes", "y")] <- 1
    out[nn & is.na(out) & lx %in% c("no", "n")] <- 0
    x <- out
  }
  x <- as.numeric(x)
  ok <- x[!is.na(x)]
  if (length(ok) > 0) {
    dk <- c(88, 97, 98, 99, 999)
    if (mean(ok <= 7) > 0.8) dk <- c(dk, 8, 9)
    x[x %in% dk] <- NA
  }
  x
}

# ---------------------------------------------------------------
# Barangay-level analysis (Table 1)
# ---------------------------------------------------------------
agg <- as.data.frame(data.all)
agg$cityf <- factor(normtxt(agg$city))
agg$z <- to01(agg$assignment)
agg$tr <- to01(agg$treatment)

pt <- unlab(agg$partytreat)
if (is.character(pt)) {
  agg$akb <- as.numeric(grepl("akb", tolower(pt)))
} else {
  pt <- as.numeric(pt)
  tb <- table(pt)
  lv <- as.numeric(names(tb))
  if (length(lv) == 2 && any(tb == 18)) {
    agg$akb <- as.numeric(pt == lv[tb == 18][1])
  } else {
    agg$akb <- as.numeric(pt == 1)
  }
}

sa <- as.numeric(unlab(agg$share.akbayan))
su <- as.numeric(unlab(agg$share.umalabka))
if (max(c(sa, su), na.rm = TRUE) <= 1) { sa <- sa * 100; su <- su * 100 }
agg$share_akb <- sa
agg$share_uma <- su
agg$vote_overall <- ifelse(agg$akb == 1, sa, su)
to <- as.numeric(unlab(agg$turnout.party))
if (max(to, na.rm = TRUE) <= 1.5) to <- to * 100
agg$turnout <- to

fit_b <- function(f, d) feols(f, data = d)
m1 <- fit_b(turnout ~ z | cityf, agg)
m2 <- fit_b(vote_overall ~ z | cityf, agg)
dA <- agg[agg$akb == 1, ]
dU <- agg[agg$akb == 0, ]
m3 <- fit_b(share_akb ~ z | cityf, dA)
m4 <- fit_b(share_uma ~ z | cityf, dU)

emit("itt_turnout_barangay_table1_col1", coef(m1)["z"])
emit("itt_vote_overall_barangay_table1_col2", coef(m2)["z"])
emit("itt_vote_akbayan_barangay_table1_col3", coef(m3)["z"])
emit("itt_vote_umalabka_barangay_table1_col4", coef(m4)["z"])
emit("n_obs_barangay_table1_cols1_2", nobs(m2))
emit("n_obs_barangay_akbayan_table1_col3", nobs(m3))
emit("n_obs_barangay_umalabka_table1_col4", nobs(m4))
emit("control_mean_vote_overall_barangay", mean(agg$vote_overall[agg$z == 0], na.rm = TRUE))
emit("r2_vote_overall_barangay", tryCatch(r2(m2, "r2"), error = function(e) NA))

# CACE
tryCatch({
  c1 <- feols(turnout ~ 1 | cityf | tr ~ z, data = agg)
  c2 <- feols(vote_overall ~ 1 | cityf | tr ~ z, data = agg)
  c3 <- feols(share_akb ~ 1 | cityf | tr ~ z, data = dA)
  c4 <- feols(share_uma ~ 1 | cityf | tr ~ z, data = dU)
  emit("cace_turnout_barangay", coef(c1)["fit_tr"])
  emit("cace_vote_overall_barangay", coef(c2)["fit_tr"])
  emit("cace_vote_akbayan_barangay", coef(c3)["fit_tr"])
  emit("cace_vote_umalabka_barangay", coef(c4)["fit_tr"])
}, error = function(e) NULL)

# Permutation p-value (within municipality) for pooled vote share
tryCatch({
  perm_p <- function(d, y, R = 2000) {
    d <- d[!is.na(d[[y]]), ]
    obs <- coef(feols(as.formula(paste(y, "~ z | cityf")), data = d))["z"]
    sims <- replicate(R, {
      dd <- d
      dd$z <- ave(dd$z, dd$cityf, FUN = function(v) v[sample.int(length(v))])
      coef(feols(as.formula(paste(y, "~ z | cityf")), data = dd))["z"]
    })
    mean(abs(sims) >= abs(obs) - 1e-12)
  }
  emit("perm_p_vote_overall_barangay", perm_p(agg, "vote_overall", 1000))
}, error = function(e) NULL)

# ---------------------------------------------------------------
# Individual-level data
# ---------------------------------------------------------------
sv <- as.data.frame(survey_raw)
sv$cnorm <- normtxt(sv$city)
sv$bnorm <- normtxt(sv$barangay)
sv <- sv[!(sv$cnorm %in% c("imus", "pateros", "santamaria") |
             grepl("imus|pateros|santamaria", sv$cnorm)), ]
sv$cityf <- factor(sv$cnorm)
sv$z <- to01(sv$assignment)
sv$tr <- to01(sv$treatment)

# party of municipality: map from aggregate data by city, fallback on partytreat
citymap <- tapply(agg$akb, normtxt(agg$city), function(v) v[1])
sv$akb <- as.numeric(citymap[sv$cnorm])
spt <- unlab(sv$partytreat)
if (is.character(spt)) {
  alt <- as.numeric(grepl("akb", tolower(spt)))
} else {
  alt <- as.numeric(as.numeric(spt) == 1)
}
sv$akb[is.na(sv$akb)] <- alt[is.na(sv$akb)]

# Attendance-oversampling weights
sv$att <- to01(sv$attendance)
agg$bnorm <- normtxt(agg$barangay)
ap <- as.numeric(unlab(agg$att.prop))
if (max(ap, na.rm = TRUE) > 1) ap <- ap / 100
pmap <- setNames(ap, agg$bnorm)
sv$w <- 1
for (b in unique(sv$bnorm)) {
  p <- pmap[b]
  if (length(p) == 0 || is.na(p) || p <= 0) next
  idx <- which(sv$bnorm == b & !is.na(sv$att))
  if (length(idx) == 0) next
  s <- mean(sv$att[idx])
  if (s <= 0 || s >= 1) next
  sv$w[idx] <- ifelse(sv$att[idx] == 1, p / s, (1 - p) / (1 - s))
}

# turnout and vote
tcol <- if ("turnout_pl" %in% names(sv)) "turnout_pl" else "turnout_all"
sv$turn <- to01(sv[[tcol]])
if (all(is.na(sv$turn)) && "turnout_all" %in% names(sv)) sv$turn <- to01(sv$turnout_all)
sv$turn[!(sv$turn %in% c(0, 1))] <- NA

vt <- to01(sv$vote)
vt[!(vt %in% c(0, 1))] <- NA
va <- to01(sv$vote.akbayan); va[!(va %in% c(0, 1))] <- NA
vu <- to01(sv$vote.umalabka); vu[!(vu %in% c(0, 1))] <- NA
vparty <- ifelse(sv$akb == 1, va, vu)
if (sum(!is.na(vt)) < 0.5 * sum(!is.na(vparty))) vt <- vparty
vt[is.na(vt)] <- vparty[is.na(vt)]
sv$vote_t <- vt * 100
sv$vote_akb <- va * 100

svt <- sv[!is.na(sv$turn), ]
emit("n_obs_individual_turnout", nrow(svt))
voters <- svt[svt$turn == 1, ]

tryCatch({
  f2 <- feols(vote_t ~ z | cityf, data = voters, cluster = ~barangay)
  emit("itt_vote_overall_unweighted_tableF1_col2", coef(f2)["z"])
}, error = function(e) NULL)
tryCatch({
  vA <- voters[voters$akb == 1, ]
  f3 <- feols(vote_akb ~ z | cityf, data = vA, cluster = ~barangay)
  emit("itt_vote_akbayan_unweighted_tableF1_col3", coef(f3)["z"])
}, error = function(e) NULL)
tryCatch({
  fw <- feols(vote_t ~ z | cityf, data = voters, weights = ~w, cluster = ~barangay)
  emit("itt_vote_overall_weighted_individual", coef(fw)["z"])
  ft <- feols(I(turn * 100) ~ z | cityf, data = svt, weights = ~w, cluster = ~barangay)
  emit("itt_turnout_weighted_individual", coef(ft)["z"])
}, error = function(e) NULL)

# ---------------------------------------------------------------
# Anderson (2008) summary indices
# ---------------------------------------------------------------
make_index <- function(d, items) {
  ctrl <- d$z == 0 & !is.na(d$z)
  Z <- list()
  for (v in items) {
    if (!(v %in% names(d))) next
    x <- likert(d[[v]])
    m <- mean(x[ctrl], na.rm = TRUE)
    s <- sd(x[ctrl], na.rm = TRUE)
    if (is.na(s) || s == 0) next
    Z[[v]] <- (x - m) / s
  }
  Z <- as.matrix(as.data.frame(Z))
  S <- cov(Z, use = "pairwise.complete.obs")
  Si <- tryCatch(solve(S), error = function(e) MASS::ginv(S))
  W <- rowSums(Si)
  idx <- apply(Z, 1, function(r) {
    ok <- !is.na(r)
    if (!any(ok)) return(NA_real_)
    sum(W[ok] * r[ok]) / sum(W[ok])
  })
  m <- mean(idx[ctrl], na.rm = TRUE)
  s <- sd(idx[ctrl], na.rm = TRUE)
  (idx - m) / s
}

find_items <- function(d, base_items, pats) {
  nm <- names(d)
  hits <- unique(c(intersect(base_items, nm),
                   unlist(lapply(pats, function(p) grep(p, nm, value = TRUE, ignore.case = TRUE, perl = TRUE)))))
  hits <- hits[!grepl("index|idx|_std$|_z$|^female$|^gender$|_imp|imputed", hits, ignore.case = TRUE)]
  keep <- vapply(hits, function(v) {
    x <- likert(d[[v]])
    u <- unique(x[!is.na(x)])
    length(u) >= 2 && length(u) <= 11
  }, logical(1))
  hits[keep]
}

pov_items <- find_items(sv, c("poverty", "gap", "cct", "corruption"),
                        c("^pover", "^gap", "^cct", "^corrupt"))
gen_items <- find_items(sv, c("femhouse", "fempol", "equality", "discrimination", "harassment"),
                        c("^fem(?!ale)", "^equal", "^discrim", "^harass"))
message("poverty items: ", paste(pov_items, collapse = ", "))
message("gender items: ", paste(gen_items, collapse = ", "))
cat("DEVIATION: Index items located by name pattern (gender index has 6 items per paper) and mechanism sample restricted to respondents with valid turnout (effective N = 1,082)\n")

run_index <- function(d, items) {
  d$idx <- make_index(d, items)
  m <- feols(idx ~ z | cityf, data = d, weights = ~w, cluster = ~barangay)
  coef(m)["z"]
}

svA <- svt[svt$akb == 1, ]
svU <- svt[svt$akb == 0, ]
tryCatch(emit("itt_poverty_index_akbayan_tableC3", run_index(svA, pov_items)), error = function(e) NULL)
tryCatch(emit("itt_poverty_index_umalabka_tableC3", run_index(svU, pov_items)), error = function(e) NULL)
tryCatch(emit("itt_gender_index_akbayan_tableC4", run_index(svA, gen_items)), error = function(e) NULL)
tryCatch(emit("itt_gender_index_umalabka_tableC4", run_index(svU, gen_items)), error = function(e) NULL)
