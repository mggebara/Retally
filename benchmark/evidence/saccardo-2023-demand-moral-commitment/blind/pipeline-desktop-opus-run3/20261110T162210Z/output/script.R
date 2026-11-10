suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/saccardo_2023_demand_moral_commitment.script-free/Data/Clean Data"
d <- as.data.frame(read_dta(file.path(base, "choice_experiments.dta")))
cat("Rows in choice_experiments:", nrow(d), "\n")

nm <- names(d); lnm <- tolower(nm)
fv <- function(cands) {
  for (x in cands) { i <- which(lnm == tolower(x)); if (length(i)) return(nm[i[1]]) }
  NA_character_
}
num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  suppressWarnings(as.numeric(x))
}
labtxt <- function(x) {
  if (inherits(x, "haven_labelled")) as.character(as_factor(x)) else as.character(x)
}
z0 <- function(x) { x <- num(x); x[is.na(x)] <- 0; x }

## ---------------- diagnostics ----------------
cat("Variable names:\n"); print(nm)
for (v in c("treatment", "condition", "sample", "wave", "commission", "professionals",
            "probabilistic_incentive", "incentiveshigh", "incentivedesign", "getyourchoice",
            "flippedorder", "conflict", "qualitycostly", "seequalitycostly", "costly",
            "inconsistentid", "attentive")) {
  vv <- fv(v)
  if (!is.na(vv)) { cat("---", vv, "---\n"); print(table(labtxt(d[[vv]]), useNA = "ifany")) }
}
if (!is.na(fv("incentiveshigh")) && !is.na(fv("probabilistic_incentive"))) {
  cat("incentiveshigh x probabilistic_incentive\n")
  print(table(num(d[[fv("incentiveshigh")]]), num(d[[fv("probabilistic_incentive")]]), useNA = "ifany"))
}

## ---------------- treatment text ----------------
tt <- rep("", nrow(d))
for (v in c("treatment", "condition", "sample")) {
  vv <- fv(v)
  if (!is.na(vv)) tt <- paste(tt, tolower(labtxt(d[[vv]])))
}

## professionals
vp <- fv(c("professionals"))
prof <- if (!is.na(vp)) z0(d[[vp]]) else as.numeric(grepl("prof", tt))

## quality first costly
vq <- fv(c("seequalitycostly", "qualitycostly", "qualityfirstcostly", "costlyquality"))
qfc <- if (!is.na(vq)) z0(d[[vq]]) else as.numeric(grepl("quality.*cost|cost.*quality", tt))

## incentive first costly
vi <- fv(c("seeincentivecostly", "incentivecostly", "seeincentivefirstcostly", "incentivefirstcostly", "costlyincentive"))
if (!is.na(vi)) {
  ifc <- z0(d[[vi]])
} else if (any(grepl("incentive.*cost|cost.*incentive", tt))) {
  ifc <- as.numeric(grepl("incentive.*cost|cost.*incentive", tt) & qfc == 0)
} else if (!is.na(fv("costly"))) {
  ifc <- as.numeric(z0(d[[fv("costly")]]) == 1 & qfc == 0)
} else {
  ifc <- rep(0, nrow(d))
}
ifc[prof == 1] <- 0
qfc[prof == 1] <- 0

## robustness arms
rob <- rep(FALSE, nrow(d))
rv <- nm[grepl("stake|replic|tenfold|hundredfold|determin", lnm)]
cat("Robustness-arm variables found:", paste(rv, collapse = ", "), "\n")
for (v in rv) {
  x <- num(d[[v]])
  if (length(unique(na.omit(x))) <= 2 && all(na.omit(x) %in% c(0, 1))) rob <- rob | (!is.na(x) & x == 1)
}
rob <- rob | grepl("stake|replic|10x|100x|tenfold|hundredfold|determin|10-fold|100-fold", tt)

## outcome: prefer to see incentive first
vy <- fv(c("choicebefore", "choiceincentivebefore", "prefer_incentivefirst", "preferincentivefirst"))
if (is.na(vy)) {
  cand <- nm[grepl("^choicebefore", lnm) & !grepl("_", lnm)]
  vy <- if (length(cand)) cand[1] else NA
}
cat("Preference variable:", vy, "\n")
pref <- num(d[[vy]])
cat("Preference table:\n"); print(table(pref, useNA = "ifany"))

## inconsistency / attention
vinc <- fv(c("inconsistentid", "inconsistent", "multipleswitch"))
incon <- if (!is.na(vinc)) z0(d[[vinc]]) else rep(0, nrow(d))
vat <- fv(c("attentive"))
inatt <- if (!is.na(vat)) { a <- num(d[[vat]]); !is.na(a) & a == 0 } else rep(FALSE, nrow(d))

## controls
vg <- fv(c("gender", "female", "male"))
g <- if (!is.na(vg)) labtxt(d[[vg]]) else rep("missing", nrow(d))
g[is.na(g) | g == ""] <- "missing"
gender_f <- factor(g)

va <- fv(c("age"))
if (!is.na(va)) {
  araw <- d[[va]]; an <- num(araw)
  nonmiss_raw <- sum(!is.na(araw) & as.character(araw) != "")
  if (sum(!is.na(an)) >= 0.5 * max(1, nonmiss_raw)) {
    age_miss <- as.numeric(is.na(an))
    an[is.na(an)] <- mean(an, na.rm = TRUE)
    age_term <- "age_n + age_miss"
  } else {
    at <- labtxt(araw); at[is.na(at) | at == ""] <- "missing"
    age_f <- factor(at); an <- rep(0, nrow(d)); age_miss <- rep(0, nrow(d))
    age_term <- "age_f"
  }
} else {
  an <- rep(0, nrow(d)); age_miss <- rep(0, nrow(d)); age_term <- NULL
}

vw <- fv(c("wave"))
w <- if (!is.na(vw)) labtxt(d[[vw]]) else rep("none", nrow(d))
w[is.na(w) | w == ""] <- "none"
wave_f <- factor(w)

vprob <- fv(c("probabilistic_incentive", "probabilistic", "incentiveshigh"))
prob <- if (!is.na(vprob)) z0(d[[vprob]]) else rep(0, nrow(d))
vl <- fv(c("incentiveleft", "incentive_left", "left", "incentiveonleft"))
if (is.na(vl)) {
  cl <- nm[grepl("left", lnm) & !grepl("_", lnm)]
  vl <- if (length(cl)) cl[1] else fv(c("incentivedesign"))
}
cat("Position variable:", vl, "\n")
left <- if (!is.na(vl)) z0(d[[vl]]) else rep(0, nrow(d))
probleft <- prob * left

## Table 3 variables
rec <- num(d[[fv(c("recommendincentive"))]])
conf <- num(d[[fv(c("conflict"))]])
nocon <- 1 - conf
vb <- fv(c("incentiveB", "incentiveb", "incentiveforb"))
if (!is.na(vb)) {
  incB <- num(d[[vb]])
} else if (!is.na(fv(c("incentiveA", "incentivefora")))) {
  incB <- 1 - num(d[[fv(c("incentiveA", "incentivefora"))]])
} else {
  ct <- tolower(labtxt(d[[fv("commission")]]))
  incB <- as.numeric(grepl("\\bb\\b", ct))
  if (all(incB == 0)) incB <- as.numeric(num(d[[fv("commission")]]) == max(num(d[[fv("commission")]]), na.rm = TRUE))
}

## assigned preferred order: pick candidate with mean closest to 0.75
cands <- list()
if (!is.na(fv("getyourchoice"))) cands$getyourchoice <- num(d[[fv("getyourchoice")]])
if (!is.na(fv("flippedorder"))) cands$notflipped <- 1 - num(d[[fv("flippedorder")]])
if (!is.na(fv("getbefore"))) cands$getbefore_eq_pref <- as.numeric(num(d[[fv("getbefore")]]) == pref)

df <- data.frame(pref = pref, prof = prof, ifc = ifc, qfc = qfc, gender_f = gender_f,
                 age_n = an, age_miss = age_miss, wave_f = wave_f, prob = prob, left = left,
                 probleft = probleft, rec = rec, nocon = nocon, incB = incB)
if (exists("age_f")) df$age_f <- age_f

## sample selection candidates
ih <- if (!is.na(fv("incentiveshigh"))) z0(d[[fv("incentiveshigh")]]) else rep(0, nrow(d))
masks <- list(
  base = !rob,
  base_cons = !rob & incon == 0 & !inatt,
  drop_highnonprob = !rob & !(ih == 1 & prob == 0),
  drop_highnonprob_cons = !rob & !(ih == 1 & prob == 0) & incon == 0 & !inatt
)
target <- 712 + 2574 + 1562 + 1067
best <- NULL; bestdiff <- Inf
for (k in names(masks)) {
  n <- sum(masks[[k]] & !is.na(pref))
  cat("Mask", k, "N =", n, "\n")
  if (abs(n - target) < bestdiff) { bestdiff <- abs(n - target); best <- k }
}
cat("Chosen mask:", best, "\n")
main <- masks[[best]] & !is.na(pref)
cat("Main sample by arm: prof", sum(main & prof == 1), " IFC", sum(main & ifc == 1),
    " QFC", sum(main & qfc == 1), " Free", sum(main & prof == 0 & ifc == 0 & qfc == 0), "\n")

for (k in names(cands)) cat("Assigned candidate", k, "mean:", mean(cands[[k]][main], na.rm = TRUE), "\n")
if (length(cands)) {
  mk <- sapply(cands, function(x) abs(mean(x[main], na.rm = TRUE) - 0.75))
  df$assigned <- cands[[names(which.min(mk))]]
  cat("Assigned-pref variable used:", names(which.min(mk)), "\n")
} else df$assigned <- NA
df$notass <- 1 - df$assigned

## selfishness standardized
vs <- fv(c("selfish", "selfishness", "overallselfishness"))
s <- num(d[[vs]])
amt <- main & prof == 0 & !is.na(s)
cat("Selfish raw mean/sd (AMT main):", mean(s[amt]), sd(s[amt]), "\n")
if (abs(sd(s[amt]) - 1) > 0.1 || abs(mean(s[amt])) > 0.15) {
  s <- (s - mean(s[amt])) / sd(s[amt])
}
df$sel <- s
df$sel_ifc <- df$sel * df$ifc
df$sel_qfc <- df$sel * df$qfc

ctrl <- paste(c("gender_f", age_term, "wave_f", "prob", "left", "probleft"), collapse = " + ")

hc3 <- function(m) sqrt(diag(vcovHC(m, type = "HC3")))
gc <- function(m, n) { b <- coef(m); if (n %in% names(b) && !is.na(b[n])) unname(b[n]) else NA }

## ---------------- Table 2 ----------------
d1 <- df[main, ]
m1 <- lm(as.formula(paste("pref ~ prof + ifc + qfc +", ctrl)), data = d1)
d2 <- df[main & prof == 0 & !is.na(df$sel), ]
m2 <- lm(as.formula(paste("pref ~ ifc + qfc + sel +", ctrl)), data = d2)
m3 <- lm(as.formula(paste("pref ~ ifc + qfc + sel + sel_ifc + sel_qfc +", ctrl)), data = d2)
cat("Table 2 col1:\n"); print(cbind(coef(m1), hc3(m1))[1:4, ])
cat("Table 2 col3:\n"); print(cbind(coef(m3), hc3(m3))[1:6, ])

## ---------------- Table 3 ----------------
t3 <- main & !is.na(rec) & !is.na(df$assigned)
df$pref_nocon <- df$pref * df$nocon
df$pref_notass <- df$pref * df$notass
df$nocon_notass <- df$nocon * df$notass
f3 <- paste("rec ~ pref + nocon + pref_nocon + prof + ifc + qfc + incB +", ctrl)
d31 <- df[t3 & df$assigned == 1, ]
d32 <- df[t3 & df$assigned == 0, ]
d33 <- df[t3, ]
m31 <- lm(as.formula(f3), data = d31)
m32 <- lm(as.formula(f3), data = d32)
m33 <- lm(as.formula(paste(f3, "+ notass + pref_notass + nocon_notass")), data = d33)
cat("Table 3 col1:\n"); print(cbind(coef(m31), hc3(m31))[1:8, ])
cat("Table 3 col3 pref x notass SE:", hc3(m33)["pref_notass"], "\n")

cat(sprintf("RESULT:see_incentive_first_costly_table2_col1=%.6f\n", gc(m1, "ifc")))
cat(sprintf("RESULT:assess_quality_first_costly_table2_col1=%.6f\n", gc(m1, "qfc")))
cat(sprintf("RESULT:choice_free_professionals_table2_col1=%.6f\n", gc(m1, "prof")))
cat(sprintf("RESULT:selfishness_table2_col2=%.6f\n", gc(m2, "sel")))
cat(sprintf("RESULT:selfishness_table2_col3=%.6f\n", gc(m3, "sel")))
cat(sprintf("RESULT:see_incentive_first_costly_x_selfishness_table2_col3=%.6f\n", gc(m3, "sel_ifc")))
cat(sprintf("RESULT:see_quality_first_costly_x_selfishness_table2_col3=%.6f\n", gc(m3, "sel_qfc")))
cat(sprintf("RESULT:n_obs_table2_col1=%d\n", as.integer(nobs(m1))))
cat(sprintf("RESULT:n_obs_table2_cols2_3=%d\n", as.integer(nobs(m2))))
cat(sprintf("RESULT:prefer_see_incentive_first_assigned_table3_col1=%.6f\n", gc(m31, "pref")))
cat(sprintf("RESULT:prefer_see_incentive_first_not_assigned_table3_col2=%.6f\n", gc(m32, "pref")))
cat(sprintf("RESULT:prefer_see_incentive_first_x_not_assigned_table3_col3=%.6f\n", gc(m33, "pref_notass")))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", as.integer(nobs(m31))))