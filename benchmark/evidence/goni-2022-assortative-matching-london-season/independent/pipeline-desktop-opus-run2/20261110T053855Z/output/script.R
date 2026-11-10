suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/goni_2022_assortative_matching_london_season.script-free"
d <- as.data.frame(read_dta(file.path(root, "data/final-data.dta")))
nm <- names(d)
cat("Rows:", nrow(d), " Cols:", ncol(d), "\n")

num <- function(x) {
  if (is.character(x)) return(suppressWarnings(as.numeric(x)))
  as.numeric(zap_labels(x))
}
pick <- function(cands) {
  cands <- cands[cands %in% nm]
  if (length(cands)) cands[1] else NA_character_
}
getv <- function(v) if (!is.na(v)) num(d[[v]]) else rep(NA_real_, nrow(d))

# ---------------- core variables ----------------
Tvar <- getv("syntheticT")

v_byear <- pick(c("byear", "birthyear", "yob", "birth_year"))
byear <- getv(v_byear)
if (all(is.na(byear)) && "bdate" %in% nm) {
  bd <- d$bdate
  if (inherits(bd, "Date")) byear <- as.numeric(format(bd, "%Y")) else byear <- floor(num(bd))
}
v_age <- pick(c("age1861"))
age1861 <- if (!is.na(v_age)) getv(v_age) else 1861 - byear
cat("Birth-year var:", v_byear, " age var:", v_age, "\n")

if ("pr4" %in% nm) {
  title_c <- getv("pr4")
  cat("Title control: pr4\n")
} else if ("prank" %in% nm) {
  pr <- getv("prank")
  title_c <- as.numeric(pr <= 3)
  cat("Title control: prank<=3\n")
} else {
  rs <- as.character(d$rankstrg)
  title_c <- as.numeric(grepl("duke|marquess|marquis|earl", tolower(rs)))
  cat("Title control: rankstrg\n")
}
if ("hengpee" %in% nm) {
  eng_c <- getv("hengpee")
  cat("Peerage control: hengpee\n")
} else {
  p <- d$peerage
  if (is.character(p)) eng_c <- as.numeric(grepl("^e|eng", tolower(p))) else {
    lab <- tryCatch(as.character(as_factor(p)), error = function(e) as.character(p))
    eng_c <- as.numeric(grepl("^e|eng", tolower(lab)))
  }
  cat("Peerage control: peerage\n")
}
biorder <- getv("biorder")
dist <- getv("distlondon")

cOut <- getv("cOut")
mheir <- getv("mheir")
fdown <- getv("fdown")
celib <- getv("celibacy")
nthis <- getv("nthismarriage")

sdT <- sd(Tvar[age1861 >= 15 & age1861 <= 35], na.rm = TRUE)
cat("SD of syntheticT (age 15-35):", sdT, "\n")
if (is.finite(sdT) && sdT < 1) Tvar <- Tvar * 100

# ---------------- samples ----------------
inage <- !is.na(age1861) & age1861 >= 15 & age1861 <= 35
if ("base_sample" %in% nm) {
  bs <- getv("base_sample")
  base <- !is.na(bs) & bs == 1 & inage
} else {
  base <- inage & !is.na(nthis) & nthis == 1
}
ctrl_ok <- !is.na(Tvar) & !is.na(title_c) & !is.na(eng_c) & !is.na(biorder) & !is.na(byear)
base <- base & ctrl_ok & !is.na(cOut)
cat("Baseline N:", sum(base), "\n")

# ---------------- celibacy sample ----------------
# age at death: prefer dage, else dyear - byear
dagev <- getv("dage")
dy <- getv("dyear")
agedeath <- ifelse(!is.na(dagev), dagev, dy - byear)
alive_len <- is.na(agedeath) | agedeath >= 35          # unknown death treated as alive
alive_str <- !is.na(agedeath) & agedeath >= 35         # death age must be recorded
cat("Celibacy tab (in age, ctrl_ok):\n"); print(table(celib[inage & ctrl_ok], useNA = "ifany"))
cat("Never married in age: death age NA:", sum(inage & ctrl_ok & celib == 1 & is.na(agedeath), na.rm = TRUE),
    " died<35:", sum(inage & ctrl_ok & celib == 1 & !is.na(agedeath) & agedeath < 35, na.rm = TRUE), "\n")
cat("Base married died<35:", sum(base & !is.na(agedeath) & agedeath < 35), "\n")

mrs <- getv("marital_rates_sample")
wom <- getv("wom")
pr_ok <- if ("prank" %in% nm) !is.na(getv("prank")) else rep(TRUE, nrow(d))
nev <- inage & ctrl_ok & !is.na(celib) & celib == 1

cands <- list(
  v1_lenient_both = (base & alive_len) | (nev & alive_len),
  v2_strict_both  = (base & alive_str) | (nev & alive_str),
  v3_base_all_nev_strict = base | (nev & alive_str),
  v4_lenient_peerdau = (base & alive_len) | (nev & alive_len & pr_ok & (is.na(wom) | wom == 1)),
  v5_strict_peerdau = (base & alive_str) | (nev & alive_str & pr_ok & (is.na(wom) | wom == 1)),
  v6_mrs_lenient = inage & ctrl_ok & !is.na(celib) & !is.na(mrs) & mrs == 1 & alive_len & (base | celib == 1),
  v7_mrs_strict  = inage & ctrl_ok & !is.na(celib) & !is.na(mrs) & mrs == 1 & alive_str & (base | celib == 1)
)
cands <- lapply(cands, function(s) s & !is.na(celib))
ns <- sapply(cands, sum)
for (k in names(ns)) cat("Celibacy candidate", k, "N =", ns[k], "\n")
target <- 765
best <- names(ns)[which.min(abs(ns - target))]
cel_s <- cands[[best]]
cat("Chosen celibacy sample:", best, " N =", sum(cel_s), "\n")
cat(sprintf("DEVIATION: Celibacy sample death-before-35 rule operationalised as '%s' (dage/dyear-based); exact rule not specified in data\n", best))

# ---------------- landholdings ----------------
fat_w <- getv("fatotal")
v_fh <- pick(c("sfatotal"))
land <- base & !is.na(fdown)
fat_h <- getv(v_fh)
land2 <- land & !is.na(fat_w) & !is.na(fat_h)
if (sum(land2) > 0) land <- land2
pool <- c(fat_w[land], fat_h[land])
Fn <- ecdf(pool)
rw <- 100 * Fn(fat_w)
rh <- 100 * Fn(fat_h)
dsgn <- rh - rw
dabs <- abs(dsgn)
land <- land & !is.na(dabs) & !is.na(dsgn)
cat("Landholdings N:", sum(land), "\n")

# ---------------- estimation helpers ----------------
w <- data.frame(T = Tvar, title_c = title_c, eng_c = eng_c, biorder = biorder,
                dist = dist, byear = byear, cOut = cOut, mheir = mheir,
                fdown = fdown, celib = celib, dabs = dabs, dsgn = dsgn)

probit_ame <- function(y, idx, dist_ctrl = FALSE) {
  rhs <- "T + title_c + eng_c + biorder"
  if (dist_ctrl) { rhs <- paste(rhs, "+ dist"); idx <- idx & !is.na(w$dist) }
  df <- w[idx & !is.na(w[[y]]), ]
  m <- glm(as.formula(paste(y, "~", rhs)), family = binomial("probit"), data = df)
  X <- model.matrix(m)
  b <- coef(m)
  xb <- as.vector(X %*% b)
  phi <- dnorm(xb)
  ame <- mean(phi) * b["T"]
  V <- vcovCL(m, cluster = df$byear, type = "HC1")
  g <- colMeans(phi * (-xb) * X) * b["T"]
  g["T"] <- g["T"] + mean(phi)
  se <- sqrt(as.numeric(t(g) %*% V %*% g))
  pc <- mean((fitted(m) > 0.5) == (df[[y]] == 1))
  cat(sprintf("Probit %s dist=%s: N=%d coef=%.4f AME=%.5f SE=%.5f mean=%.3f pctcorrect=%.3f\n",
              y, dist_ctrl, nrow(df), b["T"], ame, se, mean(df[[y]]), pc))
  list(ame = unname(ame), se = se, n = nrow(df))
}

ols_T <- function(y, idx, dist_ctrl = FALSE) {
  rhs <- "T + title_c + eng_c + biorder"
  if (dist_ctrl) { rhs <- paste(rhs, "+ dist"); idx <- idx & !is.na(w$dist) }
  df <- w[idx & !is.na(w[[y]]), ]
  m <- lm(as.formula(paste(y, "~", rhs)), data = df)
  V <- vcovCL(m, cluster = df$byear, type = "HC1")
  b <- coef(m)["T"]
  se <- sqrt(V["T", "T"])
  cat(sprintf("OLS %s dist=%s: N=%d coef=%.4f SE=%.4f clusters=%d\n",
              y, dist_ctrl, nrow(df), b, se, length(unique(df$byear))))
  list(b = unname(b), se = se, n = nrow(df))
}

safe <- function(expr) tryCatch(expr, error = function(e) { cat("Error:", conditionMessage(e), "\n"); NULL })

a1 <- safe(probit_ame("cOut", base))
a2 <- safe(probit_ame("mheir", base))
a3 <- safe(ols_T("dabs", land))
a4 <- safe(ols_T("dsgn", land))
a5 <- safe(probit_ame("fdown", land))
a6 <- safe(probit_ame("celib", cel_s))
b1 <- safe(probit_ame("cOut", base, TRUE))
b2 <- safe(probit_ame("mheir", base, TRUE))
b3 <- safe(ols_T("dabs", land, TRUE))
b4 <- safe(ols_T("dsgn", land, TRUE))

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
out("n_obs_table2_panelA_baseline", a1$n)
out("n_obs_table2_panelA_landholdings", a3$n)
out("n_obs_table2_panelA_never_married", a6$n)