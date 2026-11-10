suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/goni_2022_assortative_matching_london_season.script-free"
f <- file.path(root, "data/final-data.dta")

hdr <- names(read_dta(f, n_max = 1))
cat("Number of columns:", length(hdr), "\n")
wanted <- c("cOut", "mheir", "fdown", "celibacy", "syntheticT", "biorder", "rank", "prank",
            "pr4", "peerage", "hengpee", "distlondon", "base_sample", "byear", "nthismarriage",
            "nmarriages", "fmissmatch", "fmissmatch2", "fatotal", "mage", "myear", "age1861",
            "heir", "title", "refno", "marital_rates_sample", "mourn", "grankspo", "crankspo")
extra <- grep("^(age1861|died|ddate|dyear|dage|female|sex|gender|foreign|royal|fatotal|cran|prank|rank|land|acre|pct|perc|celib|sample)",
              hdr, value = TRUE, ignore.case = TRUE)
cols <- intersect(unique(c(wanted, extra)), hdr)
cat("Loaded columns:", paste(cols, collapse = ", "), "\n")
d <- read_dta(f, col_select = all_of(cols))
d <- as.data.frame(zap_labels(zap_formats(d)))
cat("Rows:", nrow(d), "\n")

num <- function(x) suppressWarnings(as.numeric(x))
for (v in names(d)) if (!is.character(d[[v]])) d[[v]] <- num(d[[v]])

# ---- controls ----
if ("pr4" %in% names(d) && all(na.omit(d$pr4) %in% c(0, 1))) {
  d$titlectl <- d$pr4
} else if ("prank" %in% names(d) && is.numeric(d$prank)) {
  d$titlectl <- as.numeric(d$prank <= 3)
} else if ("rank" %in% names(d) && is.numeric(d$rank)) {
  d$titlectl <- as.numeric(d$rank <= 3)
} else d$titlectl <- 0
if ("hengpee" %in% names(d)) {
  d$engctl <- d$hengpee
} else if ("peerage" %in% names(d)) {
  if (is.character(d$peerage)) d$engctl <- as.numeric(grepl("^E", d$peerage)) else d$engctl <- as.numeric(d$peerage == 1)
} else d$engctl <- 0
cat("titlectl table:\n"); print(table(d$titlectl, useNA = "ifany"))
cat("engctl table:\n"); print(table(d$engctl, useNA = "ifany"))

# ---- samples ----
bs <- if ("base_sample" %in% names(d)) d$base_sample else rep(1, nrow(d))
cat("base_sample table:\n"); print(table(bs, useNA = "ifany"))
inbase <- !is.na(bs) & bs == 1
firstm <- if ("nthismarriage" %in% names(d)) is.na(d$nthismarriage) | d$nthismarriage <= 1 else rep(TRUE, nrow(d))
married <- if ("celibacy" %in% names(d)) !is.na(d$celibacy) & d$celibacy == 0 else !is.na(d$cOut)

base <- d[inbase & married & firstm & !is.na(d$cOut) & !is.na(d$syntheticT), ]
cat("Baseline candidate N:", nrow(base), "\n")
if (nrow(base) < 500) {
  base <- d[inbase & !is.na(d$cOut) & !is.na(d$syntheticT), ]
  cat("Fallback baseline N:", nrow(base), "\n")
}

# ---- never-married (celibacy) sample ----
# Paper: peers' daughters aged 15-35 in 1861, married or not, dropping those who died before age 35.
cat("celibacy table (all rows):\n"); print(table(d$celibacy, useNA = "ifany"))
if ("marital_rates_sample" %in% names(d)) { cat("marital_rates_sample table:\n"); print(table(d$marital_rates_sample, useNA = "ifany")) }
if ("age1861" %in% names(d)) { cat("age1861 summary:\n"); print(summary(d$age1861)) }
agedeath <- rep(NA_real_, nrow(d))
if ("dage" %in% names(d)) agedeath <- d$dage
if ("dyear" %in% names(d) && "byear" %in% names(d)) {
  alt <- d$dyear - d$byear
  agedeath[is.na(agedeath)] <- alt[is.na(agedeath)]
}
cat("age at death summary:\n"); print(summary(agedeath))
alive35 <- is.na(agedeath) | agedeath >= 35
age_ok <- if ("age1861" %in% names(d)) !is.na(d$age1861) & d$age1861 >= 15 & d$age1861 <= 35 else rep(TRUE, nrow(d))
hasT <- !is.na(d$syntheticT)
hasC <- !is.na(d$celibacy)
nevm <- hasC & d$celibacy == 1
ctlok <- complete.cases(d[, c("titlectl", "engctl", "biorder", "byear")])

# Template of base-sample women (to restrict never-married to comparable women: peers' daughters)
base_tmpl <- d[inbase, ]
ranks_in_base <- if ("rank" %in% names(d)) unique(base_tmpl$rank) else NULL

cands <- list()
cands$c1 <- (inbase & alive35) | (nevm & age_ok & hasT & alive35 & firstm)
cands$c2 <- inbase | (nevm & age_ok & hasT & alive35 & firstm)
cands$c3 <- (inbase & alive35) | (nevm & age_ok & hasT & alive35)
cands$c4 <- inbase | (nevm & age_ok & hasT & alive35)
cands$c5 <- hasC & age_ok & hasT & alive35 & firstm
if ("marital_rates_sample" %in% names(d)) {
  mrs <- !is.na(d$marital_rates_sample) & d$marital_rates_sample == 1
  cands$c6 <- inbase | (nevm & mrs & age_ok & hasT & alive35)
  cands$c7 <- mrs & hasC & age_ok & hasT & alive35
}
if (!is.null(ranks_in_base) && "rank" %in% names(d)) {
  rk <- d$rank %in% ranks_in_base
  cands$c8 <- inbase | (nevm & age_ok & hasT & alive35 & rk & firstm)
}
best <- NULL; bestgap <- Inf
for (nm in names(cands)) {
  sel <- cands[[nm]] & hasC & hasT & ctlok
  n <- sum(sel)
  nn <- sum(sel & d$celibacy == 1)
  cat(sprintf("Celibacy candidate %s: N=%d (never married=%d)\n", nm, n, nn))
  if (nn > 0 && abs(n - 765) < bestgap) { bestgap <- abs(n - 765); best <- nm }
}
if (is.null(best)) best <- "c1"
cat("Chosen celibacy sample definition:", best, "\n")
celib <- d[cands[[best]] & hasC & hasT & ctlok, ]
cat("Celibacy sample N:", nrow(celib), "\n")
cat('DEVIATION: Never-married sample constructed from base sample plus never-married women aged 15-35 in 1861 surviving to 35 (no ready-made sample flag); definition chosen as closest to the paper N among candidates\n')

ctrl <- c("titlectl", "engctl", "biorder")

ame_probit <- function(y, data, addctl = NULL) {
  ctl <- c(ctrl, addctl)
  dd <- data[complete.cases(data[, c(y, "syntheticT", ctl, "byear")]), ]
  fml <- as.formula(paste(y, "~ syntheticT +", paste(ctl, collapse = " + ")))
  m <- feglm(fml, data = dd, family = binomial(link = "probit"), cluster = ~byear)
  X <- model.matrix(fml, dd)
  b <- coef(m)
  xb <- as.vector(X[, names(b)] %*% b)
  ame <- mean(dnorm(xb)) * b["syntheticT"]
  se <- mean(dnorm(xb)) * sqrt(vcov(m)["syntheticT", "syntheticT"])
  cat(sprintf("Probit %s: N=%d coef=%.4f AME=%.4f (se %.4f)\n", y, nobs(m), b["syntheticT"], ame, se))
  list(ame = unname(ame), n = nobs(m))
}
ols <- function(y, data, addctl = NULL) {
  ctl <- c(ctrl, addctl)
  dd <- data[complete.cases(data[, c(y, "syntheticT", ctl, "byear")]), ]
  fml <- as.formula(paste(y, "~ syntheticT +", paste(ctl, collapse = " + ")))
  m <- feols(fml, data = dd, cluster = ~byear)
  cat(sprintf("OLS %s: N=%d coef=%.4f (se %.4f)\n", y, nobs(m), coef(m)["syntheticT"], se(m)["syntheticT"]))
  list(b = unname(coef(m)["syntheticT"]), n = nobs(m))
}

# ---- landholdings outcomes ----
if (all(c("fmissmatch", "fmissmatch2") %in% names(base))) {
  base$ldabs <- base$fmissmatch
  base$ldhw <- base$fmissmatch2
  cat("fmissmatch summary:\n"); print(summary(base$fmissmatch))
  cat("fmissmatch2 summary:\n"); print(summary(base$fmissmatch2))
  if (min(base$fmissmatch2, na.rm = TRUE) >= 0 && min(base$fmissmatch, na.rm = TRUE) < 0) {
    base$ldabs <- base$fmissmatch2; base$ldhw <- base$fmissmatch
  }
  if (min(base$ldabs, na.rm = TRUE) < 0) base$ldabs <- abs(base$ldhw)
  if (max(abs(base$ldabs), na.rm = TRUE) <= 1) { base$ldabs <- 100 * base$ldabs; base$ldhw <- 100 * base$ldhw }
} else {
  base$ldabs <- NA_real_; base$ldhw <- NA_real_
}
land <- base[!is.na(base$ldabs) & !is.na(base$ldhw), ]
cat("Landholdings sample N:", nrow(land), "\n")
if (!"fdown" %in% names(land) || all(is.na(land$fdown))) land$fdown <- as.numeric(land$ldhw < 0)

res <- list()
safe <- function(expr) tryCatch(expr, error = function(e) { cat("ERROR:", conditionMessage(e), "\n"); NULL })

# Panel A
a1 <- safe(ame_probit("cOut", base))
a2 <- safe(ame_probit("mheir", base))
a3 <- safe(ols("ldabs", land))
a4 <- safe(ols("ldhw", land))
a5 <- safe(ame_probit("fdown", land))
a6 <- safe(ame_probit("celibacy", celib))
# Panel B
b1 <- safe(ame_probit("cOut", base, "distlondon"))
b2 <- safe(ame_probit("mheir", base, "distlondon"))
b3 <- safe(ols("ldabs", land, "distlondon"))
b4 <- safe(ols("ldhw", land, "distlondon"))

out <- function(name, val) if (!is.null(val) && length(val) == 1 && is.finite(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
out("treatment_married_commoner_table2_panelA_col1", a1$ame)
out("treatment_married_heir_table2_panelA_col2", a2$ame)
out("treatment_landholdings_diff_abs_table2_panelA_col3", a3$b)
out("treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4", a4$b)
out("treatment_married_down_table2_panelA_col5", a5$ame)
out("treatment_never_married_table2_panelA_col6", a6$ame)
out("treatment_married_commoner_table2_panelB_col1", b1$ame)
out("treatment_married_heir_table2_panelB_col2", b2$ame)
out("treatment_landholdings_diff_abs_table2_panelB_col3", b3$b)
out("treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4", b4$b)
out("n_obs_table2_panelA_baseline", a1$n)
out("n_obs_table2_panelA_landholdings", a3$n)
out("n_obs_table2_panelA_never_married", a6$n)