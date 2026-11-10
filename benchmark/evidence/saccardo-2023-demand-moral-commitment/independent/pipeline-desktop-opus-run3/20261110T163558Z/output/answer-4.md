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
cat("Column names:\n"); print(names(d))

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
  if (is.null(x)) return(NULL)
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  suppressWarnings(as.numeric(x))
}
getv <- function(cands) { v <- pick(cands); if (is.null(v)) NULL else d[[v]] }

# Diagnostics of key categorical variables
for (v in c("treatment", "study", "sample", "condition", "wave", "incentivedesign", "year",
            "highx10", "highx100", "seeincentivecostly", "seequalitycostly", "professionalsfree")) {
  vv <- pick(v)
  if (!is.null(vv)) { cat("Table of", vv, ":\n"); print(table(lbl(d[[vv]]), useNA = "ifany")) }
}

tl <- tolower(paste(lbl(getv("treatment")), lbl(getv("study")), lbl(getv("sample")),
                    lbl(getv("condition")), lbl(getv("incentivedesign")), sep = " ; "))

# ---- Treatment indicators (use the dataset's own treatment dummies) ----
prof_v <- getv(c("professionalsfree", "professionals"))
d_prof <- if (!is.null(prof_v)) as.integer(num(prof_v) %in% 1) else as.integer(grepl("prof", tl))

aq_v <- getv(c("seequalitycostly", "qualitycostly"))
d_aqfc <- if (!is.null(aq_v)) as.integer(num(aq_v) %in% 1) else as.integer(grepl("quality[^;]*cost|cost[^;]*quality", tl))

si_v <- getv(c("seeincentivecostly", "incentivecostly"))
d_sifc <- if (!is.null(si_v)) as.integer(num(si_v) %in% 1) else as.integer(grepl("incentive[^;]*cost|cost[^;]*incentive", tl))
d_sifc[d_prof == 1 | d_aqfc == 1] <- 0L

# ---- Main sample restriction: drop robustness arms (high stakes, replication, deterministic) ----
h10 <- num(getv(c("highx10")))
h100 <- num(getv(c("highx100")))
robust <- grepl("stake|x10|x100|10-fold|100-fold|replic|determin", tl)
if (!is.null(h10)) robust <- robust | (h10 %in% 1)
if (!is.null(h100)) robust <- robust | (h100 %in% 1)
cat("Robustness-arm rows flagged:", sum(robust), "\n")
cat("DEVIATION: Excluded robustness arms (high-stakes x10/x100, replication, deterministic) from the main sample via Highx10/Highx100 dummies and treatment labels\n")

att_v <- getv(c("attentionpassed", "attentive", "attention_passed"))
att_ok <- if (is.null(att_v)) rep(TRUE, nrow(d)) else (num(att_v) %in% 1 | is.na(num(att_v)))
inc_v <- getv(c("inconsistentid", "inconsistent", "multipleswitch", "multipleswitcher"))
cons_ok <- if (is.null(inc_v)) rep(TRUE, nrow(d)) else !(num(inc_v) %in% 1)

# ---- Outcomes and key regressors ----
pref_v <- pick(c("choicebefore", "prefer_incentivefirst", "preferincentivefirst", "chooseincentivefirst", "choice"))
cat("Preference variable used:", pref_v, "\n")
pref_if <- num(d[[pref_v]])

assigned <- num(getv(c("getyourchoice", "assignedpreference", "gotchoice")))
rec <- num(getv(c("recommendincentive", "recommend_incentive")))
nc_v <- getv(c("noconflict"))
nocon <- if (!is.null(nc_v)) num(nc_v) else 1 - num(getv(c("conflict")))
incB <- num(getv(c("incentiveB", "incentiveb")))

# ---- Selfishness: the dataset's own 'selfish' measure (its interactions with the
# costly arms are stored as selfishseeincentivecostly / selfishseequalitycostly),
# standardised within the estimation sample ----
self_choice <- pick(c("selfish", "selfishness"))
cat("Selfishness variable used:", self_choice, "\n")
self_raw <- num(d[[self_choice]])
cat("Selfish summary:\n"); print(summary(self_raw)); cat("sd:", sd(self_raw, na.rm = TRUE), "\n")
print(table(self_raw, useNA = "ifany"))

# Multiple switchers in the MPL have no selfishness measure; professionals had no MPL.
mpl_ok <- d_prof == 1 | !is.na(num(getv(c("selfish", "selfishness"))))
cat("DEVIATION: Identified multiple switchers (excluded per preregistration) as non-professional advisors with missing MPL selfishness measure\n")

# ---- Controls: design-variation controls only (fn. 14) ----
# Use the dataset's own design dummies (incentiveshigh, incentiveleft and their stored interaction)
prob <- num(getv(c("incentiveshigh", "probabilistic_incentive")))
prob_alt <- num(getv(c("probabilistic_incentive")))
if (!is.null(prob_alt)) { cat("Cross-tab incentiveshigh vs probabilistic_incentive:\n"); print(table(prob, prob_alt, useNA = "ifany")) }
prob[is.na(prob)] <- 0
pos <- num(getv(c("incentiveleft")))
if (is.null(pos)) pos <- rep(0, nrow(d))
pos[is.na(pos)] <- 0
inter <- num(getv(c("incentiveshigh_incentiveleft")))
if (is.null(inter) || all(is.na(inter))) inter <- prob * pos
inter[is.na(inter)] <- 0

df <- data.frame(pref_if, assigned, rec, nocon, incB, self_raw,
                 prob, pos, inter, d_prof, d_sifc, d_aqfc,
                 robust, att_ok, cons_ok, mpl_ok)
df$notassigned <- 1 - df$assigned

main <- df[!df$robust & df$att_ok & (df$cons_ok | df$d_prof == 1) & df$mpl_ok, ]
cat("Main sample rows:", nrow(main), "\n")
cat("Treatment counts in main (prof, SIFC, AQFC):", sum(main$d_prof), sum(main$d_sifc), sum(main$d_aqfc), "\n")
cat("Mean preference by arm (base, prof, SIFC, AQFC):",
    mean(main$pref_if[main$d_prof == 0 & main$d_sifc == 0 & main$d_aqfc == 0], na.rm = TRUE),
    mean(main$pref_if[main$d_prof == 1], na.rm = TRUE),
    mean(main$pref_if[main$d_sifc == 1], na.rm = TRUE),
    mean(main$pref_if[main$d_aqfc == 1], na.rm = TRUE), "\n")

ctrl <- "prob + pos + inter"
fit <- function(f, data) {
  m <- lm(as.formula(f), data = data)
  V <- sandwich::vcovHC(m, type = "HC1")
  print(lmtest::coeftest(m, vcov. = V))
  m
}
cf <- function(m, v) { x <- coef(m)[v]; if (is.na(x)) NA else unname(x) }

# Table 2
m1 <- fit(paste("pref_if ~ d_prof + d_sifc + d_aqfc +", ctrl), main)
s2 <- main[main$d_prof == 0 & !is.na(main$self_raw), ]
s2$selfish_z <- (s2$self_raw - mean(s2$self_raw)) / sd(s2$self_raw)
cat("Standardised selfishness within the Table 2 cols 2-3 sample\n")
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
