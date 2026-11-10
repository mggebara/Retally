suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/saccardo_2023_demand_moral_commitment.script-free"
d <- haven::read_dta(file.path(base, "Data/Clean Data/choice_experiments.dta"))
d <- as.data.frame(d)
cat("Rows:", nrow(d), "Cols:", ncol(d), "\n")
cat("Columns:\n"); print(names(d))

nm_lc <- tolower(names(d))
pick <- function(cands) {
  for (c in cands) {
    i <- which(nm_lc == tolower(c))
    if (length(i) > 0) return(names(d)[i[1]])
  }
  NULL
}
lbl <- function(x) {
  if (is.null(x)) return(rep("", nrow(d)))
  if (inherits(x, "haven_labelled")) {
    out <- as.character(haven::as_factor(x, levels = "both"))
  } else {
    out <- as.character(x)
  }
  out[is.na(out)] <- ""
  out
}
num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  suppressWarnings(as.numeric(x))
}
getv <- function(cands) { v <- pick(cands); if (is.null(v)) NULL else d[[v]] }

# Diagnostics of key categorical variables
for (v in c("treatment", "study", "sample", "condition", "wave", "studyg", "incentivedesign")) {
  vv <- pick(v)
  if (!is.null(vv)) { cat("Table of", vv, ":\n"); print(table(lbl(d[[vv]]), useNA = "ifany")) }
}

tl <- tolower(paste(lbl(getv("treatment")), lbl(getv("study")), lbl(getv("sample"))))

# ---- Treatment indicators ----
prof_v <- getv(c("professionals", "professionalsfree"))
if (!is.null(prof_v)) {
  d_prof <- as.integer(num(prof_v) %in% 1)
  pf2 <- getv(c("professionalsfree"))
  if (!is.null(pf2)) d_prof <- as.integer(d_prof == 1 | num(pf2) %in% 1)
} else {
  d_prof <- as.integer(grepl("prof", tl))
}

aq_v <- getv(c("qualitycostly", "qualityfirstcostly", "costlyquality"))
if (!is.null(aq_v)) {
  d_aqfc <- as.integer(num(aq_v) %in% 1)
} else {
  d_aqfc <- as.integer(grepl("quality[^;]*cost|cost[^;]*quality", tl))
}

si_v <- getv(c("incentivecostly", "beforecostly", "costlyincentive", "seeincentivecostly",
               "incentivefirstcostly", "commissioncostly", "costlybefore"))
if (!is.null(si_v)) {
  d_sifc <- as.integer(num(si_v) %in% 1)
} else {
  d_sifc <- as.integer(grepl("(incentive|before|commission)[^;]*cost|cost[^;]*(incentive|before|commission)", tl) &
                         !grepl("quality[^;]*cost|cost[^;]*quality", tl) & d_aqfc == 0)
}
d_sifc[d_prof == 1 | d_aqfc == 1] <- 0L

# ---- Main sample restriction: drop robustness arms ----
robust <- grepl("stake|10x|100x|10-fold|100-fold|replic|determin", tl)
cat("Robustness-arm rows flagged:", sum(robust), "\n")

att_v <- getv(c("attentionpassed", "attentive", "attention_passed"))
att_ok <- if (is.null(att_v)) rep(TRUE, nrow(d)) else (num(att_v) %in% 1 | is.na(num(att_v)))
inc_v <- getv(c("inconsistentid", "inconsistent", "multipleswitch", "multipleswitcher"))
cons_ok <- if (is.null(inc_v)) rep(TRUE, nrow(d)) else !(num(inc_v) %in% 1)

# ---- Outcomes and key regressors ----
pref_v <- pick(c("choicebefore", "prefer_incentivefirst", "preferincentivefirst", "chooseincentivefirst", "choice"))
cat("Preference variable used:", pref_v, "\n")
pref_if <- num(d[[pref_v]])
if (!all(pref_if %in% c(0, 1, NA))) {
  cat("Preference variable not 0/1; values:\n"); print(table(lbl(d[[pref_v]])))
  pref_if <- as.integer(grepl("before|incentive|first", tolower(lbl(d[[pref_v]]))))
}

assigned <- num(getv(c("getyourchoice", "assignedpreference", "gotchoice")))
rec <- num(getv(c("recommendincentive", "recommend_incentive")))
nc_v <- getv(c("noconflict"))
nocon <- if (!is.null(nc_v)) num(nc_v) else 1 - num(getv(c("conflict")))

ib_v <- getv(c("incentiveB", "incentiveb", "incentive_b", "commissionb"))
if (!is.null(ib_v)) {
  incB <- num(ib_v)
} else {
  cm <- getv(c("commission"))
  cl <- tolower(lbl(cm))
  incB <- if (any(grepl("b", cl))) as.integer(grepl("\\bb\\b|product b|on b|_b|=b", cl)) else num(cm)
}

self_raw <- num(getv(c("selfish", "selfishness")))

# ---- Controls ----
g <- getv(c("female", "gender"))
gl <- tolower(lbl(g))
female <- if (any(grepl("^f|female|woman", gl))) as.integer(grepl("^f|female|woman", gl)) else num(g)
female[gl == ""] <- NA
if (all(is.na(female))) female <- rep(0, nrow(d))
age <- num(getv(c("age")))
if (all(is.na(age))) age <- rep(0, nrow(d))
wv <- lbl(getv(c("wave")))
wv[wv == ""] <- "missing"
prob <- num(getv(c("probabilistic_incentive", "incentiveshigh")))
prob[is.na(prob)] <- 0
pos_v <- pick(c("incentiveleft", "incentive_left", "leftincentive", "incentivepositionleft", "positionleft", "left"))
pos <- if (is.null(pos_v)) rep(0, nrow(d)) else num(d[[pos_v]])
pos[is.na(pos)] <- 0
inter <- num(getv(c("incentiveshigh_incentiveleft")))
if (is.null(inter) || all(is.na(inter))) inter <- prob * pos
inter[is.na(inter)] <- 0

df <- data.frame(pref_if, assigned, rec, nocon, incB, self_raw, female, age,
                 wave = factor(wv), prob, pos, inter, d_prof, d_sifc, d_aqfc,
                 robust, att_ok, cons_ok)
df$notassigned <- 1 - df$assigned

cat("Treatment counts (prof, SIFC, AQFC):", sum(d_prof), sum(d_sifc), sum(d_aqfc), "\n")

main <- df[!df$robust & df$att_ok & (df$cons_ok | df$d_prof == 1), ]
cat("Main sample rows:", nrow(main), "\n")

ctrl <- "female + age + wave + prob + pos + inter"
fit <- function(f, data) {
  m <- lm(as.formula(f), data = data)
  V <- sandwich::vcovHC(m, type = "HC3")
  print(lmtest::coeftest(m, vcov. = V))
  m
}
cf <- function(m, v) { x <- coef(m)[v]; if (is.na(x)) NA else unname(x) }

# Table 2
m1 <- fit(paste("pref_if ~ d_prof + d_sifc + d_aqfc +", ctrl), main)
s2 <- main[main$d_prof == 0 & !is.na(main$self_raw), ]
s2$selfish_z <- (s2$self_raw - mean(s2$self_raw)) / sd(s2$self_raw)
m2 <- fit(paste("pref_if ~ d_sifc + d_aqfc + selfish_z +", ctrl), s2)
m3 <- fit(paste("pref_if ~ d_sifc + d_aqfc + selfish_z + d_sifc:selfish_z + d_aqfc:selfish_z +", ctrl), s2)

# Table 3
t3x <- paste("pref_if + nocon + pref_if:nocon + d_prof + d_sifc + d_aqfc + incB +", ctrl)
a1 <- main[main$assigned %in% 1, ]
a2 <- main[main$assigned %in% 0, ]
r1 <- fit(paste("rec ~", t3x), a1)
r2 <- fit(paste("rec ~", t3x), a2)
r3 <- fit(paste("rec ~", t3x, "+ notassigned + pref_if:notassigned + nocon:notassigned"),
          main[!is.na(main$assigned), ])

get_int <- function(m, a, b) {
  n <- names(coef(m))
  k <- n[n == paste0(a, ":", b) | n == paste0(b, ":", a)]
  if (length(k) == 0) NA else unname(coef(m)[k[1]])
}

cat(sprintf("RESULT:see_incentive_first_costly_table2_col1=%.6f\n", cf(m1, "d_sifc")))
cat(sprintf("RESULT:assess_quality_first_costly_table2_col1=%.6f\n", cf(m1, "d_aqfc")))
cat(sprintf("RESULT:choice_free_professionals_table2_col1=%.6f\n", cf(m1, "d_prof")))
cat(sprintf("RESULT:selfishness_table2_col2=%.6f\n", cf(m2, "selfish_z")))
cat(sprintf("RESULT:selfishness_table2_col3=%.6f\n", cf(m3, "selfish_z")))
cat(sprintf("RESULT:see_incentive_first_costly_x_selfishness_table2_col3=%.6f\n", get_int(m3, "d_sifc", "selfish_z")))
cat(sprintf("RESULT:see_quality_first_costly_x_selfishness_table2_col3=%.6f\n", get_int(m3, "d_aqfc", "selfish_z")))
cat(sprintf("RESULT:n_obs_table2_col1=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_obs_table2_cols2_3=%d\n", nobs(m2)))
cat(sprintf("RESULT:prefer_see_incentive_first_assigned_table3_col1=%.6f\n", cf(r1, "pref_if")))
cat(sprintf("RESULT:prefer_see_incentive_first_not_assigned_table3_col2=%.6f\n", cf(r2, "pref_if")))
cat(sprintf("RESULT:prefer_see_incentive_first_x_not_assigned_table3_col3=%.6f\n", get_int(r3, "pref_if", "notassigned")))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", nobs(r1)))