suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
  library(sandwich)
})
set.seed(42)

base <- "<repo>/.cache/datasets/saccardo_2023_demand_moral_commitment.script-free"
d <- read_dta(file.path(base, "Data/Clean Data/choice_experiments.dta"))
cat("Rows in choice_experiments:", nrow(d), "\n")
cat("Columns:\n"); print(names(d))

nm_low <- tolower(names(d))
fv <- function(cands) {
  for (c in cands) {
    i <- which(nm_low == tolower(c))
    if (length(i) > 0) return(names(d)[i[1]])
  }
  NULL
}
num <- function(x) { x <- zap_labels(x); suppressWarnings(as.numeric(x)) }
labtxt <- function(v) {
  x <- d[[v]]
  if (is.labelled(x)) tolower(as.character(as_factor(x))) else tolower(as.character(x))
}
show_tab <- function(v) {
  if (!is.null(v) && v %in% names(d)) {
    cat("\n--- table of", v, "---\n")
    x <- d[[v]]
    if (is.labelled(x)) print(table(as_factor(x), useNA = "ifany")) else
      if (length(unique(x)) < 40) print(table(x, useNA = "ifany")) else print(summary(num(x)))
  }
}
for (v in c("treatment", "condition", "study", "studyg", "sample", "wave", "professionals",
            "professionalsfree", "incentiveshigh", "probabilistic_incentive", "qualitycostly",
            "attentionpassed", "inconsistentid", "choice", "choicebefore", "getyourchoice",
            "flippedorder", "conflict", "noconflict", "commission", "incentiveb", "incentiveleft",
            "incentivedesign", "gender", "prolific", "cloudresearch", "professionalscloudresearch")) {
  vv <- fv(v); if (!is.null(vv)) show_tab(vv)
}

# ---------------- Core variables ----------------
v_pref <- fv(c("choicebefore", "choice"))
cat("\nPreference variable:", v_pref, "\n")
d$prefinc <- num(d[[v_pref]])
if (!all(na.omit(d$prefinc) %in% c(0, 1))) {
  cat("Preference variable not 0/1; recoding (labels):\n")
  lt <- labtxt(v_pref)
  d$prefinc <- ifelse(grepl("incent|before", lt), 1, ifelse(is.na(lt), NA, 0))
}

# professionals
v_prof <- fv(c("professionals", "professionalsfree"))
d$prof <- if (!is.null(v_prof)) { x <- num(d[[v_prof]]); ifelse(is.na(x), 0, x) } else 0
d$prof <- as.numeric(d$prof > 0)

# treatment labels
labcols <- Filter(Negate(is.null), lapply(c("treatment", "condition", "study", "studyg", "sample"), fv))
alllab <- do.call(paste, c(lapply(labcols, labtxt), sep = " | "))
tr_lab <- if (!is.null(fv("treatment"))) labtxt(fv("treatment")) else alllab

v_qc <- fv(c("qualitycostly", "costlyquality", "qualityfirstcostly", "seequalitycostly", "getaftercostly"))
v_ic <- fv(c("incentivecostly", "costlyincentive", "incentivefirstcostly", "seeincentivecostly",
             "getbeforecostly", "beforecostly", "costlybefore"))
d$qcost <- if (!is.null(v_qc)) num(d[[v_qc]]) else
  as.numeric(grepl("cost", tr_lab) & grepl("quality|after", tr_lab))
if (!is.null(v_ic)) {
  d$incost <- num(d[[v_ic]])
} else {
  d$incost <- as.numeric(grepl("cost", tr_lab) & grepl("incent|before", tr_lab) & !grepl("quality|after", tr_lab))
  if (sum(d$incost, na.rm = TRUE) == 0) {
    v_c <- fv(c("costly", "costlytreatment"))
    if (!is.null(v_c)) d$incost <- as.numeric(num(d[[v_c]]) == 1 & d$qcost == 0)
  }
}
d$qcost[is.na(d$qcost)] <- 0
d$incost[is.na(d$incost)] <- 0
cat("\nTreatment indicator counts: prof", sum(d$prof), " incost", sum(d$incost), " qcost", sum(d$qcost), "\n")
print(table(tr_lab, incost = d$incost, useNA = "ifany"))
print(table(tr_lab, qcost = d$qcost, useNA = "ifany"))

# controls
v_gender <- fv(c("gender", "female", "male"))
if (!is.null(v_gender)) {
  g <- d[[v_gender]]
  d$gender_f <- if (is.labelled(g)) as.character(as_factor(g)) else as.character(g)
  d$gender_f[d$gender_f %in% c("", " ")] <- NA
} else d$gender_f <- "all"
v_age <- fv(c("age"))
d$age_c <- if (!is.null(v_age)) num(d[[v_age]]) else 0
v_wave <- fv(c("wave"))
d$wave_f <- if (!is.null(v_wave)) { w <- as.character(num(d[[v_wave]])); w[is.na(w)] <- "none"; w } else "1"
v_prob <- fv(c("probabilistic_incentive", "incentivedesign", "incentiveshigh"))
d$prob <- if (!is.null(v_prob)) { x <- num(d[[v_prob]]); x[is.na(x)] <- 0; x } else 0
v_left <- fv(c("incentiveleft", "incentive_left", "leftincentive", "productleft"))
if (is.null(v_left)) {
  cand <- names(d)[grepl("left", nm_low) & !grepl("_", nm_low)]
  if (length(cand) > 0) v_left <- cand[1]
}
cat("Position variable:", ifelse(is.null(v_left), "NONE", v_left), "\n")
d$left <- if (!is.null(v_left)) { x <- num(d[[v_left]]); x[is.na(x)] <- 0; x } else 0
v_hl <- fv(c("incentiveshigh_incentiveleft"))
d$prob_left <- if (!is.null(v_hl)) { x <- num(d[[v_hl]]); x[is.na(x)] <- 0; x } else d$prob * d$left

cat("\nControl variable level counts (full data):\n")
cat("gender_f:\n"); print(table(d$gender_f, useNA = "ifany"))
cat("wave_f:\n"); print(table(d$wave_f, useNA = "ifany"))

# selfishness
v_self <- fv(c("selfish", "selfishness"))
d$selfraw <- if (!is.null(v_self)) num(d[[v_self]]) else NA_real_

# recommendation / conflict / assignment
d$recinc <- num(d[[fv(c("recommendincentive"))]])
v_nc <- fv(c("noconflict"))
d$noconf <- if (!is.null(v_nc)) num(d[[v_nc]]) else 1 - num(d[[fv(c("conflict"))]])
v_get <- fv(c("getyourchoice"))
d$assigned <- num(d[[v_get]])
d$notassigned <- 1 - d$assigned
v_ib <- fv(c("incentiveb", "incentive_b"))
if (!is.null(v_ib)) {
  d$incB <- num(d[[v_ib]])
} else {
  v_com <- fv(c("commission"))
  x <- d[[v_com]]
  if (is.labelled(x) || is.character(x)) {
    lt <- labtxt(v_com)
    d$incB <- as.numeric(grepl("\\bb\\b|product b|_b$| b$", lt))
    if (length(unique(d$incB)) < 2) d$incB <- as.numeric(num(x) == max(num(x), na.rm = TRUE))
  } else d$incB <- as.numeric(num(x) == max(num(x), na.rm = TRUE))
}

# ---------------- Sample selection ----------------
v_att <- fv(c("attentionpassed", "attentive"))
v_inc <- fv(c("inconsistentid", "inconsistent", "multipleswitcher"))
m_att <- if (!is.null(v_att)) (num(d[[v_att]]) == 1) %in% TRUE else rep(TRUE, nrow(d))
m_cons <- if (!is.null(v_inc)) !((num(d[[v_inc]]) == 1) %in% TRUE) else rep(TRUE, nrow(d))
v_hi <- fv(c("incentiveshigh"))
m_nohigh <- if (!is.null(v_hi)) !((num(d[[v_hi]]) == 1) %in% TRUE) else rep(TRUE, nrow(d))
m_nolab <- !grepl("replic|stake|10x|100x|tenfold|hundred|determin|high", alllab)
v_rep <- names(d)[grepl("replic|stakes", nm_low)]
for (v in v_rep) {
  x <- num(d[[v]]); if (all(na.omit(x) %in% c(0, 1))) m_nolab <- m_nolab & !((x == 1) %in% TRUE)
}

ctrl <- "factor(gender_f) + age_c + factor(wave_f) + prob + left + prob_left"
f1 <- as.formula(paste("prefinc ~ prof + incost + qcost +", ctrl))
vars1 <- c("prefinc", "prof", "incost", "qcost", "gender_f", "age_c", "wave_f", "prob", "left", "prob_left")

grid <- expand.grid(att = c(TRUE, FALSE), cons = c(TRUE, FALSE), nohigh = c(FALSE, TRUE), nolab = c(FALSE, TRUE))
grid$n <- NA
for (i in seq_len(nrow(grid))) {
  m <- rep(TRUE, nrow(d))
  if (grid$att[i]) m <- m & m_att
  if (grid$cons[i]) m <- m & m_cons
  if (grid$nohigh[i]) m <- m & m_nohigh
  if (grid$nolab[i]) m <- m & m_nolab
  grid$n[i] <- sum(m & complete.cases(d[, vars1]))
}
cat("\nCandidate sample sizes (target 5908):\n"); print(grid)
grid$dist <- abs(grid$n - 5908)
best <- grid[order(grid$dist, -(grid$att + grid$cons)), ][1, ]
cat("Chosen sample filters:\n"); print(best)
msel <- rep(TRUE, nrow(d))
if (best$att) msel <- msel & m_att
if (best$cons) msel <- msel & m_cons
if (best$nohigh) msel <- msel & m_nohigh
if (best$nolab) msel <- msel & m_nolab
s <- d[msel, ]
cat("Selected rows:", nrow(s), "\n")

# Drop factor() terms that have fewer than 2 levels in the estimation sample
# (this caused the "contrasts can be applied only to factors with 2 or more levels" error)
fix_formula <- function(f, data) {
  tt <- terms(f)
  tl <- attr(tt, "term.labels")
  resp <- all.vars(f)[1]
  vv <- intersect(all.vars(f), names(data))
  dd <- as.data.frame(data)[, vv, drop = FALSE]
  dd <- dd[complete.cases(dd), , drop = FALSE]
  keep <- vapply(tl, function(t) {
    if (grepl("^factor\\(", t)) {
      v <- sub("^factor\\((.*)\\)$", "\\1", t)
      length(unique(dd[[v]])) >= 2
    } else TRUE
  }, logical(1))
  if (any(!keep)) cat("Dropping single-level factor terms:", paste(tl[!keep], collapse = ", "), "\n")
  reformulate(tl[keep], response = resp)
}

hc3 <- function(f, data) {
  f <- fix_formula(f, data)
  out <- tryCatch({
    m <- lm(f, data = data)
    V <- vcovHC(m, type = "HC3")
    list(b = coef(m), se = sqrt(diag(V))[names(coef(m))], n = nobs(m))
  }, error = function(e) {
    cat("lm/HC3 failed:", conditionMessage(e), "\n")
    m <- feols(f, data = data, vcov = "hetero")
    list(b = coef(m), se = se(m), n = nobs(m))
  })
  print(round(cbind(b = out$b, se = out$se[names(out$b)]), 4))
  cat("N =", out$n, "\n")
  out
}
gb <- function(r, nm) { x <- r$b[nm]; if (is.null(x) || length(x) == 0 || is.na(x)) NA else unname(x) }

res <- list()

# ---------------- Table 2 ----------------
cat("\n==== Table 2 col 1 ====\n")
t21 <- tryCatch(hc3(f1, s), error = function(e) { print(e); NULL })
if (!is.null(t21)) {
  res$see_incentive_first_costly_table2_col1 <- gb(t21, "incost")
  res$assess_quality_first_costly_table2_col1 <- gb(t21, "qcost")
  res$choice_free_professionals_table2_col1 <- gb(t21, "prof")
  res$n_obs_table2_col1 <- t21$n
}

s2 <- s[s$prof == 0 & !is.na(s$selfraw), ]
s2 <- s2[complete.cases(s2[, vars1]), ]
mu <- mean(s2$selfraw); sdv <- sd(s2$selfraw)
cat("\nSelfish raw mean/sd:", mu, sdv, "\n")
s2$selfz <- (s2$selfraw - mu) / sdv
f2 <- as.formula(paste("prefinc ~ incost + qcost + selfz +", ctrl))
cat("\n==== Table 2 col 2 ====\n")
t22 <- tryCatch(hc3(f2, s2), error = function(e) { print(e); NULL })
if (!is.null(t22)) {
  res$selfishness_table2_col2 <- gb(t22, "selfz")
  res$n_obs_table2_cols2_3 <- t22$n
}
f3 <- as.formula(paste("prefinc ~ incost + qcost + selfz + incost:selfz + qcost:selfz +", ctrl))
cat("\n==== Table 2 col 3 ====\n")
t23 <- tryCatch(hc3(f3, s2), error = function(e) { print(e); NULL })
if (!is.null(t23)) {
  res$selfishness_table2_col3 <- gb(t23, "selfz")
  res$see_incentive_first_costly_x_selfishness_table2_col3 <- gb(t23, "incost:selfz")
  res$see_quality_first_costly_x_selfishness_table2_col3 <- gb(t23, "qcost:selfz")
}

# ---------------- Table 3 ----------------
f31 <- as.formula(paste("recinc ~ prefinc + noconf + prefinc:noconf + prof + incost + qcost + incB +", ctrl))
s3 <- s[!is.na(s$assigned), ]
cat("\n==== Table 3 col 1 (assigned) ====\n")
t31 <- tryCatch(hc3(f31, s3[s3$assigned == 1, ]), error = function(e) { print(e); NULL })
if (!is.null(t31)) {
  res$prefer_see_incentive_first_assigned_table3_col1 <- gb(t31, "prefinc")
  res$n_obs_table3_col1 <- t31$n
}
cat("\n==== Table 3 col 2 (not assigned) ====\n")
t32 <- tryCatch(hc3(f31, s3[s3$assigned == 0, ]), error = function(e) { print(e); NULL })
if (!is.null(t32)) res$prefer_see_incentive_first_not_assigned_table3_col2 <- gb(t32, "prefinc")
f33 <- as.formula(paste("recinc ~ prefinc + noconf + prefinc:noconf + notassigned + prefinc:notassigned + noconf:notassigned + prof + incost + qcost + incB +", ctrl))
cat("\n==== Table 3 col 3 (both) ====\n")
t33 <- tryCatch(hc3(f33, s3), error = function(e) { print(e); NULL })
if (!is.null(t33)) {
  b <- gb(t33, "prefinc:notassigned")
  if (is.na(b)) b <- gb(t33, "notassigned:prefinc")
  res$prefer_see_incentive_first_x_not_assigned_table3_col3 <- b
}

cat("\n")
for (n in names(res)) {
  v <- res[[n]]
  if (!is.null(v) && !is.na(v)) cat(sprintf("RESULT:%s=%.6f\n", n, v))
}
