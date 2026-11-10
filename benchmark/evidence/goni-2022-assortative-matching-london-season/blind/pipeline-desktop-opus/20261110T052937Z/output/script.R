suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/goni_2022_assortative_matching_london_season.script-free"
f_main <- file.path(base_dir, "data/final-data.dta")

hdr <- names(haven::read_dta(f_main, n_max = 0))
cat("Number of columns:", length(hdr), "\n")

wanted <- c("base_sample", "marital_rates_sample", "cOut", "mheir", "fdown",
            "fmissmatch", "fmissmatch2", "syntheticT", "distlondon", "biorder",
            "hengpee", "pr4", "prank", "rank", "peerage", "byear", "bdate",
            "nmarriages", "nthismarriage", "myear", "mage", "age1861",
            "countryseat", "refno", "female", "sex", "dage", "dyear")
nm_cands <- hdr[grepl("^(never|nevermar|nmarried|single|spinster|celib)", hdr, ignore.case = TRUE)]
eng_cands <- hdr[grepl("eng", hdr, ignore.case = TRUE) & grepl("pee", hdr, ignore.case = TRUE)]
dme_cands <- hdr[grepl("^(pr4|dme|duke|prank)", hdr, ignore.case = TRUE)]
cat("never-married candidates:", paste(nm_cands, collapse = ", "), "\n")
cat("english-peerage candidates:", paste(eng_cands, collapse = ", "), "\n")
cat("rank candidates:", paste(dme_cands, collapse = ", "), "\n")

sel <- unique(intersect(c(wanted, nm_cands, eng_cands, dme_cands), hdr))
df <- haven::read_dta(f_main, col_select = all_of(sel))
df <- haven::zap_labels(df)
df <- as.data.frame(df)
cat("Rows read:", nrow(df), "\n")

num <- function(x) suppressWarnings(as.numeric(x))
for (v in names(df)) if (!is.character(df[[v]])) df[[v]] <- num(df[[v]])

# ---------------- Controls ----------------
is_binary <- function(x) { u <- unique(x[!is.na(x)]); length(u) > 0 && all(u %in% c(0, 1)) }

# Duke/marquess/earl daughter indicator
if ("pr4" %in% names(df) && is_binary(df$pr4)) {
  df$dme <- df$pr4
} else if ("prank" %in% names(df)) {
  # assume prank coded 1=duke,2=marquess,3=earl,... (lower = higher rank)
  df$dme <- as.numeric(df$prank <= 3)
} else if ("pr4" %in% names(df)) {
  df$dme <- as.numeric(df$pr4 == 1)
} else {
  df$dme <- 0
}

# English peerage indicator
if ("hengpee" %in% names(df)) {
  df$engpeer <- df$hengpee
} else if (length(eng_cands) > 0) {
  df$engpeer <- num(df[[eng_cands[1]]])
} else if ("peerage" %in% names(df)) {
  df$engpeer <- as.numeric(grepl("^E", as.character(df$peerage)))
} else {
  df$engpeer <- 0
}

# Cluster variable: birth year
if (!"byear" %in% names(df)) {
  if ("bdate" %in% names(df)) df$byear <- floor(df$bdate) else df$byear <- NA
}

# Landholding sorting outcomes: identify absolute vs signed difference
abs_var <- NULL; sgn_var <- NULL
if (all(c("fmissmatch", "fmissmatch2") %in% names(df))) {
  neg1 <- any(df$fmissmatch < 0, na.rm = TRUE)
  neg2 <- any(df$fmissmatch2 < 0, na.rm = TRUE)
  if (neg1 && !neg2) { abs_var <- "fmissmatch2"; sgn_var <- "fmissmatch" } else { abs_var <- "fmissmatch"; sgn_var <- "fmissmatch2" }
  if (!neg1 && !neg2) { df$fm_signed_tmp <- df$fmissmatch2; sgn_var <- "fmissmatch2" }
} else if ("fmissmatch" %in% names(df)) {
  if (any(df$fmissmatch < 0, na.rm = TRUE)) {
    sgn_var <- "fmissmatch"; df$fm_abs <- abs(df$fmissmatch); abs_var <- "fm_abs"
  } else abs_var <- "fmissmatch"
}
cat("abs diff var:", abs_var, " signed diff var:", sgn_var, "\n")

# Never-married outcome
if (length(nm_cands) > 0 && is_binary(df[[nm_cands[1]]])) {
  df$nevermar <- df[[nm_cands[1]]]
} else if ("nmarriages" %in% names(df)) {
  df$nevermar <- as.numeric(is.na(df$nmarriages) | df$nmarriages == 0)
} else {
  df$nevermar <- NA
}

# ---------------- Samples ----------------
base <- df %>% filter(base_sample == 1)
cat("Base sample rows:", nrow(base), "\n")

if ("marital_rates_sample" %in% names(df)) {
  nmsamp <- df %>% filter(marital_rates_sample == 1)
} else {
  nmsamp <- df %>% filter(!is.na(syntheticT))
}
cat("Never-married sample rows:", nrow(nmsamp), "\n")

controls <- c("dme", "engpeer", "biorder")

# Probit with average marginal effect of syntheticT
probit_me <- function(data, y, ctrls) {
  vars <- c(y, "syntheticT", ctrls, "byear")
  d <- data[complete.cases(data[, intersect(vars, names(data)), drop = FALSE]), , drop = FALSE]
  # drop constant controls
  ctrls <- ctrls[sapply(ctrls, function(v) length(unique(d[[v]])) > 1)]
  fml <- as.formula(paste(y, "~ syntheticT", if (length(ctrls)) paste("+", paste(ctrls, collapse = " + ")) else ""))
  m <- glm(fml, data = d, family = binomial(link = "probit"))
  xb <- predict(m, type = "link")
  me <- mean(dnorm(xb)) * coef(m)["syntheticT"]
  # clustered SE of raw coefficient (for information)
  se <- tryCatch(sqrt(diag(sandwich::vcovCL(m, cluster = d$byear)))["syntheticT"], error = function(e) NA)
  cat(sprintf("Probit %s: N=%d, coef=%.5f (cl.SE %.5f), AME=%.5f\n", y, nrow(d), coef(m)["syntheticT"], se, me))
  list(me = unname(me), n = nrow(d))
}

ols_b <- function(data, y, ctrls) {
  vars <- c(y, "syntheticT", ctrls, "byear")
  d <- data[complete.cases(data[, intersect(vars, names(data)), drop = FALSE]), , drop = FALSE]
  ctrls <- ctrls[sapply(ctrls, function(v) length(unique(d[[v]])) > 1)]
  fml <- as.formula(paste(y, "~ syntheticT", if (length(ctrls)) paste("+", paste(ctrls, collapse = " + ")) else ""))
  m <- feols(fml, data = d, cluster = ~byear)
  cat(sprintf("OLS %s: N=%d, coef=%.5f (cl.SE %.5f)\n", y, nobs(m), coef(m)["syntheticT"], se(m)["syntheticT"]))
  list(b = unname(coef(m)["syntheticT"]), n = nobs(m))
}

safe <- function(expr) tryCatch(expr, error = function(e) { cat("ERROR:", conditionMessage(e), "\n"); NULL })
getv <- function(x, f) if (is.null(x)) NA else x[[f]]

# Landholdings sample: both spouses' landholdings present
land <- base
if (!is.null(abs_var)) land <- land[!is.na(land[[abs_var]]), , drop = FALSE]

# ---------------- Panel A ----------------
A1 <- safe(probit_me(base, "cOut", controls))
A2 <- safe(probit_me(base, "mheir", controls))
A3 <- if (!is.null(abs_var)) safe(ols_b(land, abs_var, controls)) else NULL
A4 <- if (!is.null(sgn_var)) safe(ols_b(land, sgn_var, controls)) else NULL
A5 <- safe(probit_me(land, "fdown", controls))
A6 <- safe(probit_me(nmsamp, "nevermar", controls))

# ---------------- Panel B ----------------
ctrlB <- c(controls, "distlondon")
baseB <- base[!is.na(base$distlondon), , drop = FALSE]
landB <- land[!is.na(land$distlondon), , drop = FALSE]
B1 <- safe(probit_me(baseB, "cOut", ctrlB))
B2 <- safe(probit_me(baseB, "mheir", ctrlB))
B3 <- if (!is.null(abs_var)) safe(ols_b(landB, abs_var, ctrlB)) else NULL
B4 <- if (!is.null(sgn_var)) safe(ols_b(landB, sgn_var, ctrlB)) else NULL

n_base <- getv(A1, "n")
n_land <- if (!is.null(A3)) getv(A3, "n") else getv(A5, "n")
n_nm <- getv(A6, "n")

cat(sprintf("RESULT:treatment_married_commoner_table2_panelA_col1=%.6f\n", getv(A1, "me")))
cat(sprintf("RESULT:treatment_married_heir_table2_panelA_col2=%.6f\n", getv(A2, "me")))
cat(sprintf("RESULT:treatment_landholdings_diff_abs_table2_panelA_col3=%.6f\n", getv(A3, "b")))
cat(sprintf("RESULT:treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4=%.6f\n", getv(A4, "b")))
cat(sprintf("RESULT:treatment_married_down_table2_panelA_col5=%.6f\n", getv(A5, "me")))
cat(sprintf("RESULT:treatment_never_married_table2_panelA_col6=%.6f\n", getv(A6, "me")))
cat(sprintf("RESULT:treatment_married_commoner_table2_panelB_col1=%.6f\n", getv(B1, "me")))
cat(sprintf("RESULT:treatment_married_heir_table2_panelB_col2=%.6f\n", getv(B2, "me")))
cat(sprintf("RESULT:treatment_landholdings_diff_abs_table2_panelB_col3=%.6f\n", getv(B3, "b")))
cat(sprintf("RESULT:treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4=%.6f\n", getv(B4, "b")))
cat(sprintf("RESULT:n_obs_table2_panelA_baseline=%d\n", as.integer(n_base)))
cat(sprintf("RESULT:n_obs_table2_panelA_landholdings=%d\n", as.integer(n_land)))
cat(sprintf("RESULT:n_obs_table2_panelA_never_married=%d\n", as.integer(n_nm)))