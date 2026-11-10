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

# ---------------- Core variables ----------------
v_pref <- fv(c("choicebefore", "choice"))
d$prefinc <- num(d[[v_pref]])
if (!all(na.omit(d$prefinc) %in% c(0, 1))) {
  lt <- labtxt(v_pref)
  d$prefinc <- ifelse(grepl("incent|before", lt), 1, ifelse(is.na(lt), NA, 0))
}

v_prof <- fv(c("professionals", "professionalsfree"))
d$prof <- if (!is.null(v_prof)) { x <- num(d[[v_prof]]); ifelse(is.na(x), 0, x) } else 0
d$prof <- as.numeric(d$prof > 0)

labcols <- Filter(Negate(is.null), lapply(c("treatment", "condition", "study", "sample"), fv))
alllab <- do.call(paste, c(lapply(labcols, labtxt), sep = " | "))

v_ic <- fv(c("seeincentivecostly", "incentivecostly"))
v_qc <- fv(c("seequalitycostly", "qualitycostly"))
d$incost <- num(d[[v_ic]]); d$incost[is.na(d$incost)] <- 0
d$qcost <- num(d[[v_qc]]); d$qcost[is.na(d$qcost)] <- 0

v_prob <- fv(c("incentiveshigh", "probabilistic_incentive", "incentivedesign"))
d$prob <- { x <- num(d[[v_prob]]); x[is.na(x)] <- 0; x }
v_left <- fv(c("incentiveleft"))
d$left <- { x <- num(d[[v_left]]); x[is.na(x)] <- 0; x }
v_hl <- fv(c("incentiveshigh_incentiveleft"))
d$prob_left <- if (!is.null(v_hl)) { x <- num(d[[v_hl]]); x[is.na(x)] <- 0; x } else d$prob * d$left

v_self <- fv(c("selfish", "selfishness"))
d$selfraw <- num(d[[v_self]])
cat("\nSelfish summary (full data):\n"); print(summary(d$selfraw))

# ---------------- Standardised selfishness ----------------
# The dataset ships the paper's interaction terms (standardised selfishness x costly
# treatment). Recover the underlying standardised selfishness for ALL advisors by
# finding the raw MPL-based measure that maps exactly onto those interactions.
v_sic <- fv(c("selfishseeincentivecostly"))
v_sqc <- fv(c("selfishseequalitycostly"))
d$selfstd <- NA_real_
self_exact <- FALSE
if (!is.null(v_sic) && !is.null(v_sqc)) {
  t_ic <- num(d[[v_sic]]); t_qc <- num(d[[v_sqc]])
  ref <- ifelse(d$incost == 1, t_ic, ifelse(d$qcost == 1, t_qc, NA))
  ri <- which(!is.na(ref))
  cat("Values of standardised selfishness in costly arms:\n"); print(table(round(ref[ri], 3)))
  free <- which(d$incost == 0 & d$qcost == 0 & d$prof == 0 & !is.na(d$selfraw))
  skip <- c(v_sic, v_sqc, "prefinc", "prof", "incost", "qcost", "prob", "left", "prob_left", "selfraw", "selfstd")
  best_x <- NULL; best_r <- 0; best_nm <- NULL
  test_x <- function(x, nmx) {
    if (all(is.na(x))) return(invisible(NULL))
    ok <- ri[!is.na(x[ri])]
    if (length(ok) < 200) return(invisible(NULL))
    if (sd(x[ok]) == 0) return(invisible(NULL))
    xf <- x[free]
    if (sum(!is.na(xf)) < 0.9 * length(free)) return(invisible(NULL))
    if (isTRUE(sd(xf, na.rm = TRUE) == 0)) return(invisible(NULL))
    r <- suppressWarnings(cor(x[ok], ref[ok]))
    if (!is.na(r) && abs(r) > best_r) {
      best_r <<- abs(r); best_x <<- x; best_nm <<- nmx
    }
  }
  for (cn in setdiff(names(d), skip)) {
    x <- tryCatch(num(d[[cn]]), error = function(e) NULL)
    if (is.null(x) || !is.numeric(x)) next
    test_x(x, cn)
  }
  cat("Best single-variable match:", best_nm, " |r| =", round(best_r, 4), "\n")
  if (best_r < 0.98) {
    # Try sums over MPL decision batteries (columns sharing a stem with trailing digits)
    stems <- sub("_?[0-9]+$", "", names(d))
    has_digit <- grepl("[0-9]+$", names(d))
    for (st in unique(stems[has_digit])) {
      cols <- names(d)[stems == st & has_digit]
      if (length(cols) < 4 || length(cols) > 6) next
      X <- tryCatch(sapply(cols, function(c) num(d[[c]])), error = function(e) NULL)
      if (is.null(X) || !is.matrix(X)) next
      uv <- unique(na.omit(as.vector(X)))
      if (length(uv) < 2 || length(uv) > 3) next
      test_x(rowSums(X), paste0("sum(", st, ")"))
      test_x(rowSums(X == max(uv)), paste0("count_max(", st, ")"))
    }
    cat("Best match after MPL battery search:", best_nm, " |r| =", round(best_r, 4), "\n")
  }
  if (best_r >= 0.98) {
    ok <- ri[!is.na(best_x[ri])]
    mp <- lm(ref[ok] ~ best_x[ok])
    cat("Mapping raw -> standardised: a =", round(coef(mp)[1], 5), " b =", round(coef(mp)[2], 5),
        " R2 =", round(summary(mp)$r.squared, 5), "\n")
    d$selfstd <- coef(mp)[1] + coef(mp)[2] * best_x
    self_exact <- TRUE
    cat("Using standardised selfishness reconstructed from", best_nm, "(paper's own standardisation)\n")
  }
}
if (!self_exact) {
  d$selfstd <- d$selfraw
  cat("DEVIATION: Could not recover continuous MPL selfishness; using binary 'selfish' standardised on the estimation sample\n")
}
d$selfmeas <- d$selfstd

d$recinc <- num(d[[fv(c("recommendincentive"))]])
v_nc <- fv(c("noconflict"))
d$noconf <- if (!is.null(v_nc)) num(d[[v_nc]]) else 1 - num(d[[fv(c("conflict"))]])
d$assigned <- num(d[[fv(c("getyourchoice"))]])
d$notassigned <- 1 - d$assigned

# ---------------- Sample selection ----------------
# Attention: professionals have NA (screened separately) -> keep them
v_att <- fv(c("attentionpassed", "attentive"))
m_att <- if (!is.null(v_att)) { a <- num(d[[v_att]]); is.na(a) | a == 1 } else rep(TRUE, nrow(d))
cat("DEVIATION: Advisors with missing attention flag (Professionals sample) treated as attentive so that professionals are retained\n")

# Multiple switchers: explicit flag if present, else missing MPL-based selfishness among non-professionals
v_inc <- fv(c("inconsistentid", "inconsistent", "multipleswitcher", "multipleswitch", "multiple_switcher"))
v_con <- fv(c("consistent", "consistentmpl"))
if (!is.null(v_inc)) {
  m_cons <- !((num(d[[v_inc]]) == 1) %in% TRUE)
  cat("Multiple-switcher flag:", v_inc, "\n")
} else if (!is.null(v_con)) {
  m_cons <- (num(d[[v_con]]) == 1) %in% TRUE | d$prof == 1
  cat("Consistency flag:", v_con, "\n")
} else {
  m_cons <- !(d$prof == 0 & is.na(d$selfraw))
  cat("DEVIATION: Multiple switchers identified as non-professional advisors with missing selfishness (MPL) measure\n")
}
m_nohx <- rep(TRUE, nrow(d))
for (v in c("highx10", "highx100")) {
  vv <- fv(v); if (!is.null(vv)) m_nohx <- m_nohx & !((num(d[[vv]]) == 1) %in% TRUE)
}
m_nolab <- !grepl("replic|determin|x10|x100|10x|100x|tenfold|hundred", alllab)
cat("Excluded: inattentive", sum(!m_att), " multiple switchers", sum(!m_cons), " high stakes", sum(!m_nohx), " labels", sum(!m_nolab), "\n")

ctrl <- "prob + left + prob_left"
cat("DEVIATION: Controls restricted to design-variation controls (probabilistic payment, left position, their interaction) per fn. 14\n")
f1 <- as.formula(paste("prefinc ~ prof + incost + qcost +", ctrl))
vars1 <- c("prefinc", "prof", "incost", "qcost", "prob", "left", "prob_left")

msel <- m_att & m_cons & m_nohx & m_nolab
s <- d[msel, ]
cat("Selected rows:", nrow(s), " professionals:", sum(s$prof), "\n")
grp <- ifelse(s$prof == 1, "prof", ifelse(s$incost == 1, "incost", ifelse(s$qcost == 1, "qcost", "free")))
cat("Share preferring incentive first by arm:\n"); print(round(tapply(s$prefinc, grp, mean, na.rm = TRUE), 4))

hc3 <- function(f, data) {
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

s2 <- s[s$prof == 0 & !is.na(s$selfmeas), ]
s2 <- s2[complete.cases(s2[, vars1]), ]
if (self_exact) {
  s2$selfz <- s2$selfmeas
  cat("Selfishness uses the paper's standardisation; sample mean", round(mean(s2$selfz), 4), " sd", round(sd(s2$selfz), 4), "\n")
} else {
  s2$selfz <- (s2$selfmeas - mean(s2$selfmeas)) / sd(s2$selfmeas)
  cat("Selfishness standardised on the estimation sample (mean 0, sd 1)\n")
}
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
f31 <- as.formula(paste("recinc ~ prefinc + noconf + prefinc:noconf + prof + incost + qcost +", ctrl))
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
f33 <- as.formula(paste("recinc ~ prefinc + noconf + prefinc:noconf + notassigned + prefinc:notassigned + noconf:notassigned + prof + incost + qcost +", ctrl))
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