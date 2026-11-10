suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/goni_2022_assortative_matching_london_season.script-free"
df <- haven::read_dta(file.path(base_dir, "data/final-data.dta"))
df <- haven::zap_labels(df)
df <- as.data.frame(df)
nms <- names(df)
cat("Loaded final-data.dta:", nrow(df), "rows,", ncol(df), "cols\n")

find_col <- function(cands, required = FALSE) {
  for (c in cands) if (c %in% nms) return(c)
  low <- tolower(nms)
  for (c in cands) {
    hit <- which(low == tolower(c))
    if (length(hit) > 0) return(nms[hit[1]])
  }
  if (required) stop(paste("None of the columns found:", paste(cands, collapse = ", ")))
  NA_character_
}
num <- function(x) suppressWarnings(as.numeric(x))

# ---- Key variables ----
v_T      <- find_col(c("syntheticT", "synthetic", "synthT"), TRUE)
v_com    <- find_col(c("cOut", "commoner", "mcommoner"), TRUE)
v_heir   <- find_col(c("mheir", "marriedheir"), TRUE)
v_down   <- find_col(c("fdown", "mdown", "down"))
v_cel    <- find_col(c("celibacy", "nevermarried", "never_married"))
v_dist   <- find_col(c("distlondon", "dist_london"))
v_base   <- find_col(c("base_sample", "sample0"))
v_byear  <- find_col(c("byear", "birthyear", "yob"), TRUE)
v_pr4    <- find_col(c("pr4", "hpr4", "dme"))
v_eng    <- find_col(c("hengpee", "engpee", "english"))
v_bio    <- find_col(c("biorder", "birthorder"))
v_crank  <- find_col(c("crank", "rank_acres", "prank_acres"))
v_cranks <- find_col(c("crankspo", "crank_spo", "rankspo_acres"))
v_age61  <- find_col(c("age1861", "age_1861"))

cat("Variables:", v_T, v_com, v_heir, v_down, v_cel, v_dist, v_base, v_byear,
    v_pr4, v_eng, v_bio, v_crank, v_cranks, v_age61, "\n")

df$T  <- num(df[[v_T]])
df$by <- num(df[[v_byear]])
if (!is.na(v_age61)) df$age61 <- num(df[[v_age61]]) else df$age61 <- 1861 - df$by

# Controls
if (is.na(v_pr4)) {
  v_rank <- find_col(c("prank", "rank"))
  if (!is.na(v_rank)) {
    r <- df[[v_rank]]
    if (is.numeric(r)) df$pr4 <- as.numeric(r <= 3) else
      df$pr4 <- as.numeric(grepl("duke|marquess|earl", tolower(as.character(r))))
  } else df$pr4 <- 0
} else df$pr4 <- num(df[[v_pr4]])
if (is.na(v_eng)) {
  v_pe <- find_col(c("peerage"))
  df$eng <- if (!is.na(v_pe)) as.numeric(grepl("^e|engl", tolower(as.character(df[[v_pe]])))) else 0
} else df$eng <- num(df[[v_eng]])
df$bio <- if (!is.na(v_bio)) num(df[[v_bio]]) else 0
df$dist <- if (!is.na(v_dist)) num(df[[v_dist]]) else NA_real_

# Landholdings ranks (percentile)
if (!is.na(v_crank) && !is.na(v_cranks)) {
  wr <- num(df[[v_crank]]); hr <- num(df[[v_cranks]])
  sc <- max(c(wr, hr), na.rm = TRUE)
  if (is.finite(sc) && sc <= 1.0001) { wr <- 100 * wr; hr <- 100 * hr }
  df$wrank <- wr; df$hrank <- hr
} else {
  v_fa  <- find_col(c("fatotal"))
  v_fas <- find_col(c("fatotalspo", "fatotal_spo", "spofatotal"))
  if (!is.na(v_fa) && !is.na(v_fas)) {
    a <- num(df[[v_fa]]); b <- num(df[[v_fas]])
    allv <- c(a, b); allv <- allv[!is.na(allv)]
    Fn <- ecdf(allv)
    df$wrank <- ifelse(is.na(a), NA, 100 * Fn(a))
    df$hrank <- ifelse(is.na(b), NA, 100 * Fn(b))
  } else { df$wrank <- NA_real_; df$hrank <- NA_real_ }
}
df$diff_hw  <- df$hrank - df$wrank
df$diff_abs <- abs(df$diff_hw)
if (!is.na(v_down)) df$down <- num(df[[v_down]]) else df$down <- as.numeric(df$hrank < df$wrank)

df$com  <- num(df[[v_com]])
df$heir <- num(df[[v_heir]])
df$cel  <- if (!is.na(v_cel)) num(df[[v_cel]]) else NA_real_

ctrl_ok <- !is.na(df$T) & !is.na(df$pr4) & !is.na(df$eng) & !is.na(df$bio) & !is.na(df$by)

# ---- Samples ----
base_flag <- if (!is.na(v_base)) num(df[[v_base]]) == 1 else (df$age61 >= 15 & df$age61 <= 35)
base_flag[is.na(base_flag)] <- FALSE
s_base <- base_flag & ctrl_ok & !is.na(df$com) & !is.na(df$heir)
s_land <- s_base & !is.na(df$wrank) & !is.na(df$hrank)

# Celibacy sample: choose among candidate sample definitions
cel_cands <- list()
samp_vars <- grep("sample", nms, value = TRUE, ignore.case = TRUE)
for (sv in samp_vars) {
  x <- num(df[[sv]])
  if (all(is.na(x))) next
  if (all(x[!is.na(x)] %in% c(0, 1))) {
    f <- x == 1; f[is.na(f)] <- FALSE
    cel_cands[[sv]] <- f & ctrl_ok & !is.na(df$cel)
  }
}
cel_cands[["base_cel"]] <- base_flag & ctrl_ok & !is.na(df$cel)
age_ok <- !is.na(df$age61) & df$age61 >= 15 & df$age61 <= 35
cel_cands[["age_cel"]] <- age_ok & ctrl_ok & !is.na(df$cel) & !is.na(df$T)
cand_n <- sapply(cel_cands, sum)
print(cand_n)
cand_n_valid <- cand_n[cand_n > 0]
best <- names(cand_n_valid)[which.min(abs(cand_n_valid - 765))]
s_cel <- cel_cands[[best]]
cat("Celibacy sample definition:", best, "N =", sum(s_cel), "\n")

# ---- Estimation helpers ----
ame_probit <- function(y, d, ctrls) {
  f <- as.formula(paste(y, "~ T +", paste(ctrls, collapse = " + ")))
  m <- glm(f, data = d, family = binomial(link = "probit"))
  b <- coef(m)
  X <- model.matrix(m)
  xb <- as.vector(X %*% b)
  ame <- mean(dnorm(xb)) * b["T"]
  V <- sandwich::vcovCL(m, cluster = d$by)
  # delta method gradient for AME
  g <- sapply(seq_along(b), function(k) {
    mean(-xb * dnorm(xb) * X[, k]) * b["T"] + ifelse(names(b)[k] == "T", mean(dnorm(xb)), 0)
  })
  se <- sqrt(as.numeric(t(g) %*% V %*% g))
  cat(sprintf("Probit %s: AME=%.5f (SE %.5f), raw coef=%.5f, N=%d\n", y, ame, se, b["T"], nobs(m)))
  list(ame = as.numeric(ame), se = se, n = nobs(m))
}
ols <- function(y, d, ctrls) {
  f <- as.formula(paste(y, "~ T +", paste(ctrls, collapse = " + ")))
  m <- lm(f, data = d)
  V <- sandwich::vcovCL(m, cluster = d$by)
  cat(sprintf("OLS %s: b=%.4f (SE %.4f), N=%d\n", y, coef(m)["T"], sqrt(V["T", "T"]), nobs(m)))
  list(b = as.numeric(coef(m)["T"]), n = nobs(m))
}

ctrlA <- c("pr4", "eng", "bio")
ctrlB <- c(ctrlA, "dist")

dA  <- df[s_base, ]
dAL <- df[s_land, ]
dAC <- df[s_cel, ]
dB  <- dA[!is.na(dA$dist), ]
dBL <- dAL[!is.na(dAL$dist), ]

cat("N base =", nrow(dA), "; N land =", nrow(dAL), "; N cel =", nrow(dAC), "\n")
cat("N base B =", nrow(dB), "; N land B =", nrow(dBL), "\n")

safe <- function(expr) tryCatch(expr, error = function(e) { cat("ERROR:", conditionMessage(e), "\n"); NULL })

a1 <- safe(ame_probit("com", dA, ctrlA))
a2 <- safe(ame_probit("heir", dA, ctrlA))
a3 <- safe(ols("diff_abs", dAL, ctrlA))
a4 <- safe(ols("diff_hw", dAL, ctrlA))
a5 <- safe(ame_probit("down", dAL[!is.na(dAL$down), ], ctrlA))
a6 <- safe(ame_probit("cel", dAC, ctrlA))
b1 <- safe(ame_probit("com", dB, ctrlB))
b2 <- safe(ame_probit("heir", dB, ctrlB))
b3 <- safe(ols("diff_abs", dBL, ctrlB))
b4 <- safe(ols("diff_hw", dBL, ctrlB))

out <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
}
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
out("n_obs_table2_panelA_baseline", nrow(dA))
out("n_obs_table2_panelA_landholdings", nrow(dAL))
out("n_obs_table2_panelA_never_married", nrow(dAC))
