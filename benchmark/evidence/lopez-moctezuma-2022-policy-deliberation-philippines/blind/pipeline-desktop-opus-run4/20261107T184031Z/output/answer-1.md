suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_moctezuma_2022_policy_deliberation_philippines.script-free"
load(file.path(base, "data_agg.RData"))
load(file.path(base, "survey_raw.RData"))

results <- list()
emit <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0 || is.na(v[1])) v <- NA
  results[[name]] <<- v[1]
}

norm_name <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x <- gsub("[^a-z0-9]", "", x)
  x
}

to01 <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  if (is.logical(x)) return(as.numeric(x))
  if (is.character(x)) {
    xl <- tolower(trimws(x))
    num <- suppressWarnings(as.numeric(xl))
    out <- rep(NA_real_, length(xl))
    out[grepl("^(yes|y|si|true|voted|treat|treated|attended)", xl)] <- 1
    out[grepl("^(no|n|false|did not|didn|not|control)", xl)] <- 0
    out[is.na(out) & !is.na(num)] <- num[is.na(out) & !is.na(num)]
    x <- out
  }
  x <- as.numeric(x)
  u <- sort(unique(x[!is.na(x)]))
  if (length(u) > 0 && all(u %in% c(0, 1))) return(x)
  if (length(u) > 0 && all(u %in% c(1, 2))) return(ifelse(is.na(x), NA, ifelse(x == 1, 1, 0)))
  x[!(x %in% c(0, 1))] <- NA
  x
}

likert <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  if (is.factor(x)) {
    lab <- as.character(x)
    num <- suppressWarnings(as.numeric(lab))
    if (sum(!is.na(num)) >= 0.5 * sum(!is.na(lab))) return(num)
    mapped <- likert(lab)
    if (sum(!is.na(mapped)) > 0) return(mapped)
    return(as.numeric(x))
  }
  xl <- tolower(trimws(as.character(x)))
  num <- suppressWarnings(as.numeric(xl))
  out <- rep(NA_real_, length(xl))
  out[grepl("strongly disagree|completely disagree|totally disagree", xl)] <- 1
  out[is.na(out) & grepl("disagree", xl)] <- 2
  out[is.na(out) & grepl("neither|neutral|undecided|not sure", xl)] <- 3
  out[is.na(out) & grepl("strongly agree|completely agree|totally agree", xl)] <- 5
  out[is.na(out) & grepl("agree", xl)] <- 4
  out[is.na(out) & !is.na(num)] <- num[is.na(out) & !is.na(num)]
  out
}

pct <- function(x) {
  x <- as.numeric(x)
  if (max(x, na.rm = TRUE) <= 1) x <- 100 * x
  x
}

# ---------------- Barangay level ----------------
da <- as.data.frame(data.all)
da$Z <- to01(da$assignment)
da$city_f <- factor(da$city)

# Party identification
pt <- da$partytreat
if (is.factor(pt)) pt <- as.character(pt)
if (is.character(pt) && any(grepl("akb", tolower(pt)))) {
  da$akb <- as.integer(grepl("akb", tolower(pt)))
} else {
  tab <- table(pt)
  akb_val <- names(tab)[tab == 18]
  if (length(akb_val) == 1) {
    da$akb <- as.integer(as.character(pt) == akb_val)
  } else {
    da$akb <- as.integer(!is.na(da$share.akbayan) & is.na(da$share.umalabka))
  }
}

# Turnout (% of registered voters)
turn <- as.numeric(da$turnout.party)
if (max(turn, na.rm = TRUE) > 100 && !is.null(da$reg.num)) {
  turn <- 100 * turn / as.numeric(da$reg.num)
} else if (max(turn, na.rm = TRUE) <= 1) {
  turn <- 100 * turn
}
da$turnout_pct <- turn
da$share_treated_pct <- pct(da$share.treated)
da$share_akb_pct <- pct(da$share.akbayan)
da$share_uml_pct <- pct(da$share.umalabka)

tryCatch({
  m1 <- feols(turnout_pct ~ Z | city_f, data = da)
  emit("itt_turnout_barangay_table1_col1", coef(m1)["Z"])
  emit("n_obs_barangay_table1_cols1_2", nobs(m1))
}, error = function(e) {
  emit("itt_turnout_barangay_table1_col1", NA)
  emit("n_obs_barangay_table1_cols1_2", NA)
})
tryCatch({
  m2 <- feols(share_treated_pct ~ Z | city_f, data = da)
  emit("itt_vote_overall_barangay_table1_col2", coef(m2)["Z"])
  if (is.na(results[["n_obs_barangay_table1_cols1_2"]])) emit("n_obs_barangay_table1_cols1_2", nobs(m2))
}, error = function(e) emit("itt_vote_overall_barangay_table1_col2", NA))
tryCatch({
  m3 <- feols(share_akb_pct ~ Z | city_f, data = da[da$akb == 1, ])
  emit("itt_vote_akbayan_barangay_table1_col3", coef(m3)["Z"])
  emit("n_obs_barangay_akbayan_table1_col3", nobs(m3))
}, error = function(e) {
  emit("itt_vote_akbayan_barangay_table1_col3", NA)
  emit("n_obs_barangay_akbayan_table1_col3", sum(da$akb == 1))
})
tryCatch({
  m4 <- feols(share_uml_pct ~ Z | city_f, data = da[da$akb == 0, ])
  emit("itt_vote_umalabka_barangay_table1_col4", coef(m4)["Z"])
  emit("n_obs_barangay_umalabka_table1_col4", nobs(m4))
}, error = function(e) {
  emit("itt_vote_umalabka_barangay_table1_col4", NA)
  emit("n_obs_barangay_umalabka_table1_col4", sum(da$akb == 0))
})

# ---------------- Individual level ----------------
sv <- as.data.frame(survey_raw)
sv <- sv[!grepl("imus|pateros|santa ?maria|sta\\.? ?maria", tolower(as.character(sv$city))), ]
sv$Z <- to01(sv$assignment)
sv$city_f <- factor(as.character(sv$city))
sv$brgy_f <- factor(paste(as.character(sv$city), as.character(sv$barangay), sep = "::"))

# Party of the municipality
spt <- sv$partytreat
if (is.factor(spt)) spt <- as.character(spt)
if (is.character(spt) && any(grepl("akb", tolower(spt)))) {
  sv$akb <- as.integer(grepl("akb", tolower(spt)))
} else {
  city_akb <- tapply(da$akb, norm_name(da$city), max)
  sv$akb <- as.integer(city_akb[norm_name(sv$city)])
  if (all(is.na(sv$akb))) {
    aa <- to01(sv$assign.akbayan)
    ca <- tapply(aa, sv$city_f, function(v) max(v, na.rm = TRUE))
    sv$akb <- as.integer(ca[as.character(sv$city_f)] == 1)
  }
}

sv$turn <- to01(sv$turnout_pl)
va <- to01(sv$vote.akbayan)
vu <- to01(sv$vote.umalabka)
sv$vote_t <- ifelse(sv$akb == 1, va, vu)
if (all(is.na(sv$vote_t))) sv$vote_t <- to01(sv$vote)
sv$vote_pct <- 100 * sv$vote_t
sv$att <- to01(sv$attendance)

# IPW weights for oversampling of attendees in treatment barangays
sv$w <- 1
tryCatch({
  ap <- as.numeric(da$att.prop)
  if (max(ap, na.rm = TRUE) > 1) ap <- ap / 100
  key_da <- norm_name(da$barangay)
  ap_map <- setNames(ap, key_da)
  sv$p_a <- ap_map[norm_name(sv$barangay)]
  ps <- tapply(sv$att, sv$brgy_f, function(v) mean(v, na.rm = TRUE))
  sv$p_s <- as.numeric(ps[as.character(sv$brgy_f)])
  tr <- !is.na(sv$Z) & sv$Z == 1 & !is.na(sv$p_a) & !is.na(sv$p_s) &
    sv$p_s > 0 & sv$p_s < 1 & !is.na(sv$att)
  sv$w[tr & sv$att == 1] <- sv$p_a[tr & sv$att == 1] / sv$p_s[tr & sv$att == 1]
  sv$w[tr & sv$att == 0] <- (1 - sv$p_a[tr & sv$att == 0]) / (1 - sv$p_s[tr & sv$att == 0])
}, error = function(e) NULL)

# Anderson (2008) summary index
anderson_index <- function(d, items) {
  X <- sapply(items, function(v) likert(d[[v]]))
  X <- as.matrix(X)
  ctrl <- !is.na(d$Z) & d$Z == 0
  Zs <- X
  for (j in seq_len(ncol(X))) {
    mu <- mean(X[ctrl, j], na.rm = TRUE)
    s <- sd(X[ctrl, j], na.rm = TRUE)
    Zs[, j] <- (X[, j] - mu) / s
  }
  S <- cov(Zs, use = "pairwise.complete.obs")
  Sinv <- tryCatch(solve(S), error = function(e) MASS::ginv(S))
  wts <- rowSums(Sinv)
  idx <- apply(Zs, 1, function(r) {
    ok <- !is.na(r)
    if (!any(ok)) return(NA_real_)
    sum(wts[ok] * r[ok]) / sum(wts[ok])
  })
  mu <- mean(idx[ctrl], na.rm = TRUE)
  s <- sd(idx[ctrl], na.rm = TRUE)
  (idx - mu) / s
}

pov_items <- c("poverty", "gap", "cct", "corruption")
gen_items <- c("femhouse", "fempol", "equality", "discrimination", "harassment")

run_index <- function(party, items, name) {
  tryCatch({
    d <- sv[!is.na(sv$akb) & sv$akb == party, ]
    d$idx <- anderson_index(d, items)
    m <- feols(idx ~ Z | city_f, data = d, weights = ~w, cluster = ~brgy_f)
    emit(name, coef(m)["Z"])
  }, error = function(e) emit(name, NA))
}
run_index(1, pov_items, "itt_poverty_index_akbayan_tableC3")
run_index(0, pov_items, "itt_poverty_index_umalabka_tableC3")
run_index(1, gen_items, "itt_gender_index_akbayan_tableC4")
run_index(0, gen_items, "itt_gender_index_umalabka_tableC4")

# Unweighted individual-level vote ITT (SI Table F.1)
tryCatch({
  d <- sv[!is.na(sv$turn) & sv$turn == 1, ]
  m <- feols(vote_pct ~ Z | city_f, data = d, cluster = ~brgy_f)
  emit("itt_vote_overall_unweighted_tableF1_col2", coef(m)["Z"])
}, error = function(e) emit("itt_vote_overall_unweighted_tableF1_col2", NA))
tryCatch({
  d <- sv[!is.na(sv$turn) & sv$turn == 1 & !is.na(sv$akb) & sv$akb == 1, ]
  m <- feols(vote_pct ~ Z | city_f, data = d, cluster = ~brgy_f)
  emit("itt_vote_akbayan_unweighted_tableF1_col3", coef(m)["Z"])
}, error = function(e) emit("itt_vote_akbayan_unweighted_tableF1_col3", NA))

out_names <- c(
  "itt_turnout_barangay_table1_col1",
  "itt_vote_overall_barangay_table1_col2",
  "itt_vote_akbayan_barangay_table1_col3",
  "itt_vote_umalabka_barangay_table1_col4",
  "n_obs_barangay_table1_cols1_2",
  "n_obs_barangay_akbayan_table1_col3",
  "n_obs_barangay_umalabka_table1_col4",
  "itt_poverty_index_akbayan_tableC3",
  "itt_poverty_index_umalabka_tableC3",
  "itt_gender_index_akbayan_tableC4",
  "itt_gender_index_umalabka_tableC4",
  "itt_vote_overall_unweighted_tableF1_col2",
  "itt_vote_akbayan_unweighted_tableF1_col3"
)
for (nm in out_names) {
  v <- results[[nm]]
  if (is.null(v)) v <- NA
  cat(sprintf("RESULT:%s=%s\n", nm, ifelse(is.na(v), "NA", format(v, digits = 10))))
}
