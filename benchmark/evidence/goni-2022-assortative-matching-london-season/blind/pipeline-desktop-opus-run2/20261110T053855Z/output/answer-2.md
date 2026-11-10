suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/goni_2022_assortative_matching_london_season.script-free"
d <- haven::read_dta(file.path(base_dir, "data/final-data.dta"))
d <- haven::zap_labels(d)
d <- as.data.frame(d)
nm <- names(d)
message("N rows final-data: ", nrow(d), "; cols: ", ncol(d))

findcol <- function(cands) {
  for (c in cands) {
    idx <- match(tolower(c), tolower(nm))
    if (!is.na(idx)) return(nm[idx])
  }
  NULL
}
num <- function(x) suppressWarnings(as.numeric(x))

message("Columns matching dif/land/acre/tot/pct/rank: ",
        paste(nm[grepl("dif|land|acre|tot|pct|pctile|perc|rank|never|single|death|dyear|dage|female|sex|gender|age1861|byear|sample",
                       nm, ignore.case = TRUE)], collapse = ", "))

# ---------------- core variables ----------------
v_T     <- findcol(c("syntheticT", "synthetic"))
v_com   <- findcol(c("cOut", "commoner"))
v_heir  <- findcol(c("mheir"))
v_down  <- findcol(c("fdown", "mdown", "marrieddown"))
v_dist  <- findcol(c("distlondon"))
v_bio   <- findcol(c("biorder"))
v_base  <- findcol(c("base_sample"))

d$T_ <- num(d[[v_T]])
d$commoner_ <- num(d[[v_com]])
d$heir_ <- num(d[[v_heir]])
d$biorder_ <- num(d[[v_bio]])
d$dist_ <- if (!is.null(v_dist)) num(d[[v_dist]]) else NA_real_

# birth year (cluster)
v_byear <- findcol(c("byear", "birthyear", "yob"))
if (!is.null(v_byear)) {
  d$byear_ <- num(d[[v_byear]])
} else {
  v_bdate <- findcol(c("bdate"))
  bd <- d[[v_bdate]]
  if (inherits(bd, "Date")) d$byear_ <- as.numeric(format(bd, "%Y")) else d$byear_ <- floor(num(bd) / 365.25) + 1960
}

# duke/marquess/earl daughter
v_pr4 <- findcol(c("pr4"))
if (!is.null(v_pr4)) {
  d$dme_ <- num(d[[v_pr4]])
} else {
  v_prank <- findcol(c("prank"))
  pr <- num(d[[v_prank]])
  d$dme_ <- ifelse(is.na(pr), NA, as.numeric(pr < 4))
}
# English peerage
v_eng <- findcol(c("hengpee", "engpee", "english"))
if (!is.null(v_eng)) {
  d$eng_ <- num(d[[v_eng]])
} else {
  v_pee <- findcol(c("peerage"))
  pe <- tolower(as.character(d[[v_pee]]))
  d$eng_ <- ifelse(is.na(pe) | pe == "", NA, as.numeric(grepl("^e", pe)))
}

# age in 1861
v_age61 <- findcol(c("age1861"))
d$age61_ <- if (!is.null(v_age61)) num(d[[v_age61]]) else 1861 - d$byear_

# ---------------- landholdings ----------------
v_absdif <- findcol(c("absdif", "absdiff", "dif_abs", "diff_abs", "adif", "adiff", "fdifabs", "difabs", "diffabs"))
v_sdif   <- findcol(c("dif", "diff", "fdif", "fdiff", "difhw", "dif_hw", "landdif"))
if (!is.null(v_absdif) && !is.null(v_sdif)) {
  d$sdif_ <- num(d[[v_sdif]])
  d$absdif_ <- num(d[[v_absdif]])
  message("Using landholding diff vars: ", v_sdif, ", ", v_absdif)
} else if (!is.null(v_sdif)) {
  d$sdif_ <- num(d[[v_sdif]])
  d$absdif_ <- abs(d$sdif_)
  message("Using signed diff var: ", v_sdif)
} else {
  v_wacres <- findcol(c("fatotal", "ATotal", "ATot"))
  v_hacres <- findcol(c("sfatotal", "sfATot"))
  if (is.null(v_hacres)) {
    cand_h <- nm[grepl("fatotal|atot", nm, ignore.case = TRUE) & grepl("^s|spo|husb|^h", nm, ignore.case = TRUE)]
    v_hacres <- if (length(cand_h) > 0) cand_h[1] else NULL
  }
  message("Constructing ranks from: wife=", v_wacres, " husband=", ifelse(is.null(v_hacres), "NONE", v_hacres))
  w <- num(d[[v_wacres]]); h <- if (!is.null(v_hacres)) num(d[[v_hacres]]) else rep(NA_real_, nrow(d))
  w[!is.na(w) & w <= 0] <- NA; h[!is.na(h) & h <= 0] <- NA
  pooled <- c(w[!is.na(w)], h[!is.na(h)])
  Fn <- ecdf(pooled)
  d$wpct_ <- ifelse(is.na(w), NA, 100 * Fn(w))
  d$hpct_ <- ifelse(is.na(h), NA, 100 * Fn(h))
  d$sdif_ <- d$hpct_ - d$wpct_
  d$absdif_ <- abs(d$sdif_)
}
if (!is.null(v_down)) {
  d$down_ <- num(d[[v_down]])
} else {
  d$down_ <- ifelse(is.na(d$sdif_), NA, as.numeric(d$sdif_ < 0))
}

# ---------------- baseline sample ----------------
ctrl <- c("dme_", "eng_", "biorder_")
if (!is.null(v_base)) {
  base <- d[!is.na(num(d[[v_base]])) & num(d[[v_base]]) == 1, ]
} else {
  base <- d[!is.na(d$age61_) & d$age61_ >= 15 & d$age61_ <= 35, ]
}
message("base_sample rows: ", nrow(base))

# ---------------- estimators ----------------
probit_ame <- function(df, y, xs) {
  f <- as.formula(paste(y, "~ T_ +", paste(xs, collapse = " + ")))
  df <- df[complete.cases(df[, c(y, "T_", xs, "byear_")]), ]
  if (nrow(df) < 10 || length(unique(df[[y]])) < 2) stop("insufficient data for probit")
  m <- glm(f, data = df, family = binomial(link = "probit"))
  X <- model.matrix(m)
  xb <- as.vector(X %*% coef(m))
  ame <- mean(dnorm(xb)) * coef(m)["T_"]
  list(ame = unname(ame), n = nrow(df), b = coef(m)["T_"])
}
ols_b <- function(df, y, xs) {
  f <- as.formula(paste(y, "~ T_ +", paste(xs, collapse = " + ")))
  df <- df[complete.cases(df[, c(y, "T_", xs, "byear_")]), ]
  if (nrow(df) < 10) stop("insufficient data for OLS")
  m <- feols(f, data = df, cluster = ~byear_)
  list(b = unname(coef(m)["T_"]), n = nobs(m))
}
safe <- function(expr) tryCatch(expr, error = function(e) { message("ERROR: ", conditionMessage(e)); NULL })

res <- list()

# Panel A
a1 <- safe(probit_ame(base, "commoner_", ctrl))
a2 <- safe(probit_ame(base, "heir_", ctrl))
land <- base[!is.na(base$sdif_) & !is.na(base$absdif_), ]
message("landholdings rows: ", nrow(land))
a3 <- safe(ols_b(land, "absdif_", ctrl))
a4 <- safe(ols_b(land, "sdif_", ctrl))
a5 <- safe(probit_ame(land, "down_", ctrl))

# Never married sample
nm_res <- safe({
  v_never <- nm[grepl("never|spinster|unmarr", nm, ignore.case = TRUE)]
  v_nmarr <- findcol(c("nmarriages"))
  v_nthis <- findcol(c("nthismarriage"))
  nmarr <- num(d[[v_nmarr]])
  if (length(v_never) > 0) {
    d$never_ <- num(d[[v_never[1]]])
  } else {
    d$never_ <- ifelse(is.na(nmarr), NA, as.numeric(nmarr == 0))
  }
  # one row per woman: first marriage or never married
  keep <- rep(TRUE, nrow(d))
  if (!is.null(v_nthis)) {
    nth <- num(d[[v_nthis]])
    keep <- (d$never_ == 1) | (!is.na(nth) & nth == 1)
    keep[is.na(keep)] <- FALSE
  }
  # women only
  v_fem <- findcol(c("female", "woman", "women", "daughter"))
  v_male <- findcol(c("male", "man"))
  v_sex <- findcol(c("sex", "gender"))
  if (!is.null(v_fem)) {
    fem <- num(d[[v_fem]]) == 1
  } else if (!is.null(v_male)) {
    fem <- num(d[[v_male]]) == 0
  } else if (!is.null(v_sex)) {
    s <- tolower(as.character(d[[v_sex]]))
    fem <- s %in% c("f", "female", "2", "0") & !(s %in% c("m", "male"))
    if (all(s %in% c("1", "2", NA))) fem <- s == "2"
  } else {
    fem <- rep(TRUE, nrow(d))
  }
  fem[is.na(fem)] <- FALSE
  # death before 35
  v_dage <- findcol(c("dage", "agedeath", "age_death", "deathage"))
  v_dyear <- findcol(c("dyear", "deathyear", "yod"))
  alive35 <- rep(TRUE, nrow(d))
  if (!is.null(v_dage)) {
    da <- num(d[[v_dage]]); alive35 <- is.na(da) | da >= 35
  } else if (!is.null(v_dyear)) {
    dy <- num(d[[v_dyear]]); alive35 <- is.na(dy) | (dy - d$byear_) >= 35
  } else {
    v_ddate <- findcol(c("ddate", "deathdate"))
    if (!is.null(v_ddate)) {
      dd <- d[[v_ddate]]
      dy <- if (inherits(dd, "Date")) as.numeric(format(dd, "%Y")) else floor(num(dd) / 365.25) + 1960
      alive35 <- is.na(dy) | (dy - d$byear_) >= 35
    }
  }
  # peers' daughters: father's rank observed
  pd <- !is.na(d$dme_) & !is.na(d$eng_)
  samp <- d[keep & fem & alive35 & pd & !is.na(d$age61_) & d$age61_ >= 15 & d$age61_ <= 35, ]
  if (!is.null(v_base)) {
    # exclude women married to foreigners / royals / second marriages as in the baseline:
    # married women must belong to the baseline sample
    bs <- num(samp[[v_base]])
    samp <- samp[samp$never_ == 1 | (!is.na(bs) & bs == 1), ]
  }
  message("never-married sample rows: ", nrow(samp), "; never=1: ", sum(samp$never_ == 1, na.rm = TRUE))
  probit_ame(samp, "never_", ctrl)
})

# Panel B
ctrlB <- c(ctrl, "dist_")
baseB <- base[!is.na(base$dist_), ]
landB <- land[!is.na(land$dist_), ]
b1 <- safe(probit_ame(baseB, "commoner_", ctrlB))
b2 <- safe(probit_ame(baseB, "heir_", ctrlB))
b3 <- safe(ols_b(landB, "absdif_", ctrlB))
b4 <- safe(ols_b(landB, "sdif_", ctrlB))

g <- function(x, field) if (is.null(x)) NA else x[[field]]

out <- c(
  treatment_married_commoner_table2_panelA_col1 = g(a1, "ame"),
  treatment_married_heir_table2_panelA_col2 = g(a2, "ame"),
  treatment_landholdings_diff_abs_table2_panelA_col3 = g(a3, "b"),
  treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4 = g(a4, "b"),
  treatment_married_down_table2_panelA_col5 = g(a5, "ame"),
  treatment_never_married_table2_panelA_col6 = g(nm_res, "ame"),
  treatment_married_commoner_table2_panelB_col1 = g(b1, "ame"),
  treatment_married_heir_table2_panelB_col2 = g(b2, "ame"),
  treatment_landholdings_diff_abs_table2_panelB_col3 = g(b3, "b"),
  treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4 = g(b4, "b"),
  n_obs_table2_panelA_baseline = g(a1, "n"),
  n_obs_table2_panelA_landholdings = g(a3, "n"),
  n_obs_table2_panelA_never_married = g(nm_res, "n")
)

for (k in names(out)) cat(sprintf("RESULT:%s=%s\n", k, format(out[[k]], digits = 8)))
