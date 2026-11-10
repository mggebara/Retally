suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
})
set.seed(42)

root <- "<repo>/.cache/datasets/saccardo_2023_demand_moral_commitment.script-free"
cdir <- file.path(root, "Data", "Clean Data")

# ---------------------------------------------------------------- helpers
num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- as.vector(zap_labels(x))
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) return(suppressWarnings(as.numeric(x)))
  as.numeric(x)
}
lab <- function(x) {
  if (inherits(x, "haven_labelled")) as.character(as_factor(x, levels = "default")) else as.character(x)
}
gcol <- function(df, cands) {
  low <- tolower(names(df))
  for (c in cands) {
    i <- which(low == tolower(c))
    if (length(i)) return(names(df)[i[1]])
  }
  NULL
}
z0 <- function(x) { x <- num(x); x[is.na(x)] <- 0; x }
tb <- function(x, nmx) { cat("---", nmx, "\n"); print(table(x, useNA = "ifany")) }
fmt <- function(v) if (is.null(v) || length(v) == 0 || is.na(v)) "NA" else format(round(as.numeric(v), 6), scientific = FALSE)

d <- as.data.frame(read_dta(file.path(cdir, "choice_experiments.dta")))
nm <- names(d)
cat("Rows in choice_experiments:", nrow(d), "\n")
print(nm)

treat_col <- gcol(d, c("treatment"))
tl <- if (!is.null(treat_col)) tolower(lab(d[[treat_col]])) else rep(NA_character_, nrow(d))
tb(tl, "treatment (labels)")
for (v in c("sample", "condition", "wave", "professionals", "professionalsfree", "professionalscloudresearch",
            "prolific", "cloudresearch", "seequalitycostly", "qualitycostly", "seeincentivecostly",
            "incentiveshigh", "probabilistic_incentive", "incentivedesign", "choice", "getyourchoice",
            "flippedorder", "conflict", "noconflict", "inconsistentid", "attentive", "commission")) {
  cc <- gcol(d, v)
  if (!is.null(cc)) tb(lab(d[[cc]]), cc)
}
cat("Candidate columns:\n")
print(grep("costly|left|gender|female|age|selfish|choicebefore|incentiveb|noconflict|replic|stake|determ|high|attent|consist",
           nm, value = TRUE, ignore.case = TRUE))

# ---------------------------------------------------------------- treatment indicators
pc <- gcol(d, c("professionals"))
prof <- if (!is.null(pc)) as.numeric(z0(d[[pc]]) > 0) else as.numeric(grepl("prof", tl))

ic <- gcol(d, c("seeincentivecostly", "incentivecostly", "seeincentivefirstcostly", "incentivefirstcostly",
                "costlyincentive", "incentivecostlytreat"))
if (is.null(ic)) {
  cand <- grep("incentive.*costly|costly.*incentive", nm, ignore.case = TRUE, value = TRUE)
  cand <- cand[!grepl("selfish|quality|_", cand, ignore.case = TRUE)]
  if (length(cand)) ic <- cand[1]
}
inc <- if (!is.null(ic)) as.numeric(z0(d[[ic]]) > 0) else
  as.numeric(grepl("cost", tl) & grepl("incent", tl) & !grepl("qual", tl))

qc <- gcol(d, c("seequalitycostly", "assessqualitycostly", "qualityfirstcostly", "qualitycostly", "costlyquality"))
qual <- if (!is.null(qc)) as.numeric(z0(d[[qc]]) > 0) else
  as.numeric(grepl("cost", tl) & grepl("qual", tl))
cat("Treatment dummy columns used: prof =", pc, " inc =", ic, " qual =", qc, "\n")

# robustness arms to exclude (high stakes, replication, deterministic)
rob <- !is.na(tl) & grepl("stake|replic|determ|fold|10x|100x|x10|high ?10|robust", tl)
rcols <- grep("stake|replic|determ", nm, ignore.case = TRUE, value = TRUE)
for (rc in rcols) {
  v <- num(d[[rc]])
  if (all(v %in% c(0, 1, NA)) && any(v == 1, na.rm = TRUE)) {
    cat("Robustness flag column:", rc, "\n")
    rob <- rob | (!is.na(v) & v == 1)
  }
}
cat("Robustness rows flagged:", sum(rob), "\n")

# ---------------------------------------------------------------- outcome / key variables
prefc <- gcol(d, c("choicebefore", "preferincentivefirst", "prefer_incentivefirst", "prefseeincentivefirst"))
if (is.null(prefc)) {
  cand <- grep("^choicebefore", nm, value = TRUE, ignore.case = TRUE)
  cand <- cand[!grepl("_", cand)]
  if (length(cand)) prefc <- cand[1]
}
cat("Preference column:", prefc, "\n")
pref <- num(d[[prefc]])

ac <- gcol(d, c("getyourchoice"))
assigned <- if (!is.null(ac)) num(d[[ac]]) else {
  fc <- gcol(d, c("flippedorder")); 1 - num(d[[fc]])
}

ncc <- gcol(d, c("noconflict"))
noconf <- if (!is.null(ncc)) num(d[[ncc]]) else 1 - num(d[[gcol(d, c("conflict"))]])

ibc <- gcol(d, c("incentiveB", "incentiveforB", "incentive_b"))
incB <- if (!is.null(ibc)) num(d[[ibc]]) else {
  cm <- tolower(lab(d[[gcol(d, c("commission"))]]))
  as.numeric(grepl("(^| )b($| )|product b", cm))
}

recc <- gcol(d, c("recommendincentive"))
rec <- num(d[[recc]])

sc <- gcol(d, c("selfish", "selfishness", "overallselfish"))
selfraw <- if (!is.null(sc)) num(d[[sc]]) else rep(NA_real_, nrow(d))

# ---------------------------------------------------------------- controls
gnc <- gcol(d, c("gender", "female", "male"))
gender <- if (!is.null(gnc)) lab(d[[gnc]]) else rep(NA_character_, nrow(d))
agec <- gcol(d, c("age"))
age <- if (!is.null(agec)) num(d[[agec]]) else rep(NA_real_, nrow(d))
wc <- gcol(d, c("wave"))
wave <- if (!is.null(wc)) num(d[[wc]]) else rep(NA_real_, nrow(d))
probc <- gcol(d, c("incentiveshigh", "probabilistic_incentive", "probabilistic"))
prob <- if (!is.null(probc)) z0(d[[probc]]) else rep(0, nrow(d))
lc <- gcol(d, c("incentiveleft", "incentive_left", "incentiveonleft", "left", "productleft"))
if (is.null(lc)) {
  cand <- grep("left", nm, value = TRUE, ignore.case = TRUE)
  cand <- cand[!grepl("_", cand)]
  if (length(cand)) lc <- cand[1]
}
left <- if (!is.null(lc)) z0(d[[lc]]) else rep(0, nrow(d))
ilc <- gcol(d, c("incentiveshigh_incentiveleft"))
probleft <- if (!is.null(ilc)) z0(d[[ilc]]) else prob * left
cat("Controls: gender =", gnc, " age =", agec, " wave =", wc, " prob =", probc, " left =", lc, " inter =", ilc, "\n")

# exclusion flags
keep <- rep(TRUE, nrow(d))
icc <- gcol(d, c("inconsistentid", "inconsistent"))
if (!is.null(icc)) {
  v <- num(d[[icc]])
  if (all(v %in% c(0, 1, NA))) { cat("Dropping inconsistent:", sum(v == 1, na.rm = TRUE), "\n"); keep <- keep & !(v %in% 1) }
}
atc <- gcol(d, c("attentive"))
if (!is.null(atc)) {
  v <- num(d[[atc]])
  if (all(v %in% c(0, 1, NA)) && any(v == 1, na.rm = TRUE)) { cat("Dropping inattentive:", sum(v == 0, na.rm = TRUE), "\n"); keep <- keep & !(v %in% 0) }
}

X <- data.frame(pref = pref, rec = rec, assigned = assigned, noconf = noconf, incB = incB,
                prof = prof, inc = inc, qual = qual, selfraw = selfraw,
                gender = gender, age = age, wave = wave, prob = prob, left = left, probleft = probleft,
                main = keep & !rob, stringsAsFactors = FALSE)

# fallback: append professionals if not present in the choice file
if (sum(X$prof[X$main]) == 0) {
  cat("No professionals in choice_experiments; appending professionals.dta\n")
  p <- as.data.frame(read_dta(file.path(cdir, "professionals.dta")))
  cb <- num(p[[gcol(p, c("choicebefore"))]])
  gb <- gcol(p, c("getbefore"))
  pa <- if (!is.null(gb)) as.numeric(num(p[[gb]]) == cb) else rep(NA_real_, nrow(p))
  pg <- gcol(p, c("gender"))
  pX <- data.frame(pref = cb, rec = num(p[[gcol(p, c("recommendincentive"))]]), assigned = pa,
                   noconf = 1 - num(p[[gcol(p, c("conflict"))]]),
                   incB = num(p[[gcol(p, c("incentiveB"))]]),
                   prof = 1, inc = 0, qual = 0, selfraw = NA_real_,
                   gender = if (!is.null(pg)) lab(p[[pg]]) else NA_character_,
                   age = if (!is.null(gcol(p, "age"))) num(p[[gcol(p, "age")]]) else NA_real_,
                   wave = NA_real_, prob = 0, left = 0, probleft = 0, main = TRUE, stringsAsFactors = FALSE)
  X <- rbind(X, pX)
}

S <- X[X$main, ]
S$free <- as.numeric(S$prof == 0 & S$inc == 0 & S$qual == 0)
cat("Main sample size:", nrow(S), " prof:", sum(S$prof), " inc:", sum(S$inc), " qual:", sum(S$qual),
    " free:", sum(S$free), "\n")
if (!all(is.na(tl))) { cat("Treatment labels in main sample:\n"); print(table(tl[X$main[seq_len(nrow(d))]], useNA = "ifany")) }

# build control columns
g <- S$gender
g[is.na(g) | g == ""] <- "missing"
gf <- factor(g)
gf <- relevel(gf, ref = names(sort(table(gf), decreasing = TRUE))[1])
gm <- model.matrix(~ gf)[, -1, drop = FALSE]
gnames <- if (ncol(gm)) paste0("gd", seq_len(ncol(gm))) else character(0)
if (ncol(gm)) { colnames(gm) <- gnames; S <- cbind(S, gm) }
S$agemiss <- as.numeric(is.na(S$age))
S$age[is.na(S$age)] <- mean(S$age, na.rm = TRUE)
wl <- sort(unique(S$wave[!is.na(S$wave)]))
wnames <- character(0)
if (length(wl) > 1) for (w in wl[-1]) {
  nmw <- paste0("wv", w); S[[nmw]] <- as.numeric(!is.na(S$wave) & S$wave == w); wnames <- c(wnames, nmw)
}
ctrl <- c(gnames, "age", if (any(S$agemiss == 1)) "agemiss", wnames, "prob", "left", "probleft")
ctrl <- ctrl[sapply(ctrl, function(v) length(unique(S[[v]])) > 1)]
cat("Control terms:", paste(ctrl, collapse = ", "), "\n")

fit <- function(lhs, rhs, data) {
  f <- as.formula(paste(lhs, "~", paste(rhs, collapse = " + ")))
  m <- lm(f, data = data)
  se <- tryCatch({
    keepc <- !is.na(coef(m))
    V <- vcovHC(m, type = "HC3")
    sqrt(diag(V))
  }, error = function(e) rep(NA_real_, sum(!is.na(coef(m)))))
  cat("\n==== ", deparse(f, width.cutoff = 500), " | N =", nobs(m), "\n")
  cf <- coef(m)
  print(cbind(coef = cf[!is.na(cf)], se_hc3 = se[names(cf[!is.na(cf)])]))
  m
}

# ---------------------------------------------------------------- Table 2
T2 <- S[!is.na(S$pref), ]
m1 <- fit("pref", c("prof", "inc", "qual", ctrl), T2)

T2b <- T2[T2$prof == 0 & !is.na(T2$selfraw), ]
mu <- mean(T2b$selfraw); sdv <- sd(T2b$selfraw)
cat("Selfish raw mean/sd in col2 sample:", mu, sdv, "\n")
T2b$selfz <- if (abs(mu) < 0.2 && abs(sdv - 1) < 0.2) T2b$selfraw else (T2b$selfraw - mu) / sdv
T2b$sxi <- T2b$selfz * T2b$inc
T2b$sxq <- T2b$selfz * T2b$qual
m2 <- fit("pref", c("inc", "qual", "selfz", ctrl), T2b)
m3 <- fit("pref", c("inc", "qual", "selfz", "sxi", "sxq", ctrl), T2b)

# ---------------------------------------------------------------- Table 3
T3 <- S[!is.na(S$rec) & !is.na(S$pref) & !is.na(S$assigned) & !is.na(S$noconf) & !is.na(S$incB), ]
T3$pxn <- T3$pref * T3$noconf
T3$notass <- 1 - T3$assigned
T3$pxna <- T3$pref * T3$notass
T3$nxna <- T3$noconf * T3$notass
rhs3 <- c("pref", "noconf", "pxn", "prof", "inc", "qual", "incB", ctrl)
t1 <- fit("rec", rhs3, T3[T3$assigned == 1, ])
t2 <- fit("rec", rhs3, T3[T3$assigned == 0, ])
t3 <- fit("rec", c(rhs3, "notass", "pxna", "nxna"), T3)

# ---------------------------------------------------------------- results
cat("RESULT:see_incentive_first_costly_table2_col1=", fmt(coef(m1)["inc"]), "\n", sep = "")
cat("RESULT:assess_quality_first_costly_table2_col1=", fmt(coef(m1)["qual"]), "\n", sep = "")
cat("RESULT:choice_free_professionals_table2_col1=", fmt(coef(m1)["prof"]), "\n", sep = "")
cat("RESULT:selfishness_table2_col2=", fmt(coef(m2)["selfz"]), "\n", sep = "")
cat("RESULT:selfishness_table2_col3=", fmt(coef(m3)["selfz"]), "\n", sep = "")
cat("RESULT:see_incentive_first_costly_x_selfishness_table2_col3=", fmt(coef(m3)["sxi"]), "\n", sep = "")
cat("RESULT:see_quality_first_costly_x_selfishness_table2_col3=", fmt(coef(m3)["sxq"]), "\n", sep = "")
cat("RESULT:n_obs_table2_col1=", nobs(m1), "\n", sep = "")
cat("RESULT:n_obs_table2_cols2_3=", nobs(m2), "\n", sep = "")
cat("RESULT:prefer_see_incentive_first_assigned_table3_col1=", fmt(coef(t1)["pref"]), "\n", sep = "")
cat("RESULT:prefer_see_incentive_first_not_assigned_table3_col2=", fmt(coef(t2)["pref"]), "\n", sep = "")
cat("RESULT:prefer_see_incentive_first_x_not_assigned_table3_col3=", fmt(coef(t3)["pxna"]), "\n", sep = "")
cat("RESULT:n_obs_table3_col1=", nobs(t1), "\n", sep = "")