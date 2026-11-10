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
extra <- grep("^(age1861|died|ddate|dyear|dage|female|sex|gender|foreign|royal|fatotal|cran|prank|rank|land|acre|pct|perc)",
              hdr, value = TRUE, ignore.case = TRUE)
cols <- intersect(unique(c(wanted, extra)), hdr)
cat("Loaded columns:", paste(cols, collapse = ", "), "\n")
d <- read_dta(f, col_select = all_of(cols))
d <- as.data.frame(zap_labels(zap_formats(d)))
cat("Rows:", nrow(d), "\n")

num <- function(x) suppressWarnings(as.numeric(x))
for (v in names(d)) if (!is.character(d[[v]])) d[[v]] <- num(d[[v]])

# ---- controls ----
# Indicator for duke/marquess/earl daughter
if ("pr4" %in% names(d) && all(na.omit(d$pr4) %in% c(0, 1))) {
  d$titlectl <- d$pr4
} else if ("prank" %in% names(d) && is.numeric(d$prank)) {
  d$titlectl <- as.numeric(d$prank <= 3)
} else if ("rank" %in% names(d) && is.numeric(d$rank)) {
  d$titlectl <- as.numeric(d$rank <= 3)
} else d$titlectl <- 0
# Indicator for English peerage
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
# Never-married sample: base sample women married or not
celib <- d[inbase & firstm & !is.na(d$celibacy) & !is.na(d$syntheticT), ]
cat("Celibacy candidate N:", nrow(celib), "\n")

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
  # If fmissmatch2 is nonnegative and fmissmatch is signed, swap
  if (min(base$fmissmatch2, na.rm = TRUE) >= 0 && min(base$fmissmatch, na.rm = TRUE) < 0) {
    base$ldabs <- base$fmissmatch2; base$ldhw <- base$fmissmatch
  }
  if (min(base$ldabs, na.rm = TRUE) < 0) base$ldabs <- abs(base$ldhw)
  # Rescale proportions to percentile points
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