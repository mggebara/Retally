suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/goni_2022_assortative_matching_london_season.script-free"
d <- haven::read_dta(file.path(base_dir, "data/final-data.dta"))
d <- haven::zap_labels(d)
d <- as.data.frame(d)
nm <- names(d)
cat("Rows:", nrow(d), " Cols:", ncol(d), "\n")

has <- function(v) v %in% nm
first_has <- function(cands) { x <- cands[cands %in% nm]; if (length(x)) x[1] else NA_character_ }
num <- function(x) suppressWarnings(as.numeric(x))

# ---------------- Variables ----------------
v_T     <- first_has(c("syntheticT", "synthetic"))
v_com   <- first_has(c("cOut", "commoner", "mcommoner"))
v_heir  <- first_has(c("mheir", "heirspo"))
v_down  <- first_has(c("fdown", "mdown"))
v_cel   <- first_has(c("celibacy", "never_married"))
v_abs   <- first_has(c("fmissmatch", "fdiff_abs"))
v_sgn   <- first_has(c("fmissmatch2", "fdiff"))
v_by    <- first_has(c("byear", "birthyear", "byr"))
v_eng   <- first_has(c("hengpee", "engpeer", "english", "peerage_eng"))
v_bio   <- first_has(c("biorder", "birthorder"))
v_dist  <- first_has(c("distlondon", "dist_london"))
cat("Using:", v_T, v_com, v_heir, v_down, v_cel, v_abs, v_sgn, v_by, v_eng, v_bio, v_dist, "\n")

d$T <- num(d[[v_T]])
d$byear_cl <- if (!is.na(v_by)) num(d[[v_by]]) else NA

# Family title indicator (duke/marquess/earl daughter)
title_ind <- NULL
if (has("pr4")) {
  u <- sort(unique(na.omit(num(d$pr4))))
  cat("pr4 values:", head(u, 10), "\n")
  if (all(u %in% c(0, 1))) title_ind <- num(d$pr4)
}
if (is.null(title_ind) && has("prank")) {
  pr <- num(d$prank)
  cat("prank values:", head(sort(unique(na.omit(pr))), 10), "\n")
  title_ind <- as.numeric(pr <= 3)
}
if (is.null(title_ind)) title_ind <- 0
d$title_c <- title_ind

# English peerage indicator
if (!is.na(v_eng)) {
  e <- num(d[[v_eng]])
  d$eng_c <- if (all(na.omit(e) %in% c(0, 1))) e else as.numeric(e == 1)
} else if (has("peerage")) {
  p <- d$peerage
  d$eng_c <- if (is.character(p)) as.numeric(grepl("^E", p, ignore.case = TRUE)) else as.numeric(num(p) == 1)
} else d$eng_c <- 0
d$bio_c <- num(d[[v_bio]])
d$dist_c <- if (!is.na(v_dist)) num(d[[v_dist]]) else NA

d$y_com  <- num(d[[v_com]])
d$y_heir <- num(d[[v_heir]])
d$y_down <- num(d[[v_down]])
d$y_cel  <- num(d[[v_cel]])
d$y_abs  <- if (!is.na(v_abs)) num(d[[v_abs]]) else NA
d$y_sgn  <- if (!is.na(v_sgn)) num(d[[v_sgn]]) else NA

# If difference variables are on a 0-1 scale, convert to percentile ranks (0-100)
if (all(is.na(d$y_abs)) == FALSE && max(abs(d$y_abs), na.rm = TRUE) <= 1.0001) {
  d$y_abs <- 100 * d$y_abs; d$y_sgn <- 100 * d$y_sgn
}
# If abs/sgn are swapped (abs should be nonnegative)
if (!all(is.na(d$y_abs)) && min(d$y_abs, na.rm = TRUE) < 0 && !all(is.na(d$y_sgn)) && min(d$y_sgn, na.rm = TRUE) >= 0) {
  tmp <- d$y_abs; d$y_abs <- d$y_sgn; d$y_sgn <- tmp
}
if (!all(is.na(d$y_sgn)) && all(is.na(d$y_abs))) d$y_abs <- abs(d$y_sgn)

# ---------------- Samples ----------------
bs <- if (has("base_sample")) num(d$base_sample) else rep(NA, nrow(d))
cat("base_sample table:\n"); print(table(bs, useNA = "ifany"))

# age in 1861
d$age1861 <- if (has("age1861")) num(d$age1861) else 1861 - d$byear_cl

ctrl_ok <- with(d, !is.na(T) & !is.na(title_c) & !is.na(eng_c) & !is.na(bio_c) & !is.na(byear_cl))

base <- d[!is.na(bs) & bs == 1 & ctrl_ok & !is.na(d$y_com), ]
if (nrow(base) == 0) {
  base <- d[ctrl_ok & d$age1861 >= 15 & d$age1861 <= 35 & !is.na(d$y_com), ]
  if (has("nthismarriage")) base <- base[is.na(base$nthismarriage) | base$nthismarriage <= 1, ]
}
cat("Baseline N:", nrow(base), "\n")

land <- base[!is.na(base$y_abs) & !is.na(base$y_sgn), ]
cat("Landholdings N:", nrow(land), "\n")

# Celibacy sample: women aged 15-35 in 1861 (married or not), excluding those who died before 35
cel_name <- nm[grepl("cel", nm, ignore.case = TRUE) & grepl("sample|samp", nm, ignore.case = TRUE)]
cel <- NULL
if (length(cel_name)) {
  cs <- num(d[[cel_name[1]]])
  cel <- d[!is.na(cs) & cs == 1 & ctrl_ok & !is.na(d$y_cel), ]
  cat("Celibacy sample via", cel_name[1], ":", nrow(cel), "\n")
}
if (is.null(cel) || nrow(cel) == 0) {
  # identify women
  fem <- rep(TRUE, nrow(d))
  v_sex <- first_has(c("female", "woman", "women", "sex", "gender", "male"))
  if (!is.na(v_sex)) {
    s <- d[[v_sex]]
    if (v_sex %in% c("female", "woman", "women")) fem <- num(s) == 1
    else if (v_sex == "male") fem <- num(s) == 0
    else if (is.character(s)) fem <- toupper(substr(s, 1, 1)) == "F"
    else fem <- num(s) == 2 | num(s) == 0
    fem[is.na(fem)] <- FALSE
  }
  # death age
  dage <- rep(NA_real_, nrow(d))
  v_dage <- first_has(c("dage", "agedeath", "death_age", "age_death", "ageatdeath"))
  v_dy   <- first_has(c("dyear", "deathyear", "dyr"))
  if (!is.na(v_dage)) dage <- num(d[[v_dage]]) else if (!is.na(v_dy)) dage <- num(d[[v_dy]]) - d$byear_cl
  alive35 <- is.na(dage) | dage >= 35
  married_ok <- !is.na(bs) & bs == 1
  never <- !is.na(d$y_cel) & d$y_cel == 1
  # restrict never-married to same population as baseline: peers' daughters (women, cohort)
  in_cohort <- !is.na(d$age1861) & d$age1861 >= 15 & d$age1861 <= 35
  cand <- ctrl_ok & in_cohort & alive35 & (married_ok | (never & fem))
  cel <- d[cand, ]
  cel$y_cel <- ifelse(cel$y_cel == 1, 1, 0)
  cat("Celibacy sample constructed:", nrow(cel), "\n")
}
cel <- cel[!is.na(cel$y_cel), ]

# ---------------- Estimation helpers ----------------
probit_me <- function(df, y, ctrls) {
  f <- as.formula(paste(y, "~ T +", paste(ctrls, collapse = " + ")))
  m <- glm(f, data = df, family = binomial(link = "probit"))
  b <- coef(m)
  X <- model.matrix(m)
  xb <- as.vector(X %*% b)
  me <- mean(dnorm(xb)) * b["T"]
  V <- tryCatch(sandwich::vcovCL(m, cluster = df$byear_cl[as.integer(rownames(X))], type = "HC0"),
                error = function(e) sandwich::vcovCL(m, cluster = ~byear_cl))
  # delta-method gradient of AME wrt b
  phi <- dnorm(xb)
  g <- colMeans(phi * (-xb) * X) * b["T"]
  g["T"] <- g["T"] + mean(phi)
  se <- sqrt(as.numeric(t(g) %*% V %*% g))
  pc <- mean((fitted(m) > 0.5) == (m$y == 1))
  list(me = unname(me), se = se, n = nobs(m), coef = unname(b["T"]), pc = pc)
}
ols_fit <- function(df, y, ctrls) {
  f <- as.formula(paste(y, "~ T +", paste(ctrls, collapse = " + ")))
  m <- lm(f, data = df)
  V <- sandwich::vcovCL(m, cluster = ~byear_cl, type = "HC1")
  list(b = unname(coef(m)["T"]), se = unname(sqrt(diag(V))["T"]), n = nobs(m))
}

ctrlA <- c("title_c", "eng_c", "bio_c")
ctrlB <- c(ctrlA, "dist_c")
rownames(base) <- NULL; rownames(land) <- NULL; rownames(cel) <- NULL

res <- list()
r <- probit_me(base, "y_com", ctrlA);  res$treatment_married_commoner_table2_panelA_col1 <- r$me; cat("A1 se", r$se, "N", r$n, "\n")
r <- probit_me(base, "y_heir", ctrlA); res$treatment_married_heir_table2_panelA_col2 <- r$me; cat("A2 se", r$se, "N", r$n, "\n")
r <- ols_fit(land, "y_abs", ctrlA);    res$treatment_landholdings_diff_abs_table2_panelA_col3 <- r$b; cat("A3 se", r$se, "N", r$n, "\n")
r <- ols_fit(land, "y_sgn", ctrlA);    res$treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4 <- r$b; cat("A4 se", r$se, "N", r$n, "\n")
landd <- land[!is.na(land$y_down), ]; rownames(landd) <- NULL
r <- probit_me(landd, "y_down", ctrlA); res$treatment_married_down_table2_panelA_col5 <- r$me; cat("A5 se", r$se, "N", r$n, "\n")
r <- probit_me(cel, "y_cel", ctrlA);   res$treatment_never_married_table2_panelA_col6 <- r$me; cat("A6 se", r$se, "N", r$n, "\n")

baseB <- base[!is.na(base$dist_c), ]; rownames(baseB) <- NULL
landB <- land[!is.na(land$dist_c), ]; rownames(landB) <- NULL
cat("Panel B Ns:", nrow(baseB), nrow(landB), "\n")
if (nrow(baseB) > 20) {
  r <- probit_me(baseB, "y_com", ctrlB);  res$treatment_married_commoner_table2_panelB_col1 <- r$me
  r <- probit_me(baseB, "y_heir", ctrlB); res$treatment_married_heir_table2_panelB_col2 <- r$me
  r <- ols_fit(landB, "y_abs", ctrlB);    res$treatment_landholdings_diff_abs_table2_panelB_col3 <- r$b
  r <- ols_fit(landB, "y_sgn", ctrlB);    res$treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4 <- r$b
}

res$n_obs_table2_panelA_baseline <- nrow(base)
res$n_obs_table2_panelA_landholdings <- nrow(land)
res$n_obs_table2_panelA_never_married <- nrow(cel)

for (k in names(res)) cat(sprintf("RESULT:%s=%.6f\n", k, as.numeric(res[[k]])))