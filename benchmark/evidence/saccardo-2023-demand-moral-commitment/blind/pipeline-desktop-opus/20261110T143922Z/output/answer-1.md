suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/saccardo_2023_demand_moral_commitment.script-free"
d <- haven::read_dta(file.path(base, "Data/Clean Data/choice_experiments.dta"))
cat("Rows:", nrow(d), " Cols:", ncol(d), "\n")
cat("Columns:", paste(names(d), collapse = ", "), "\n")

nms <- names(d)
getcol <- function(cands) {
  for (c in cands) {
    i <- which(tolower(nms) == tolower(c))
    if (length(i) > 0) return(nms[i[1]])
  }
  NULL
}
num <- function(x) as.numeric(haven::zap_labels(x))
labstr <- function(x) {
  if (inherits(x, "haven_labelled")) as.character(haven::as_factor(x, levels = "default"))
  else as.character(x)
}

# ---- diagnostics ----
for (v in c("treatment", "condition", "sample", "wave", "professionals", "choice",
            "getyourchoice", "choicebefore", "incentiveshigh", "probabilistic_incentive",
            "seequalitycostly", "qualitycostly", "commission", "conflict", "gender")) {
  cv <- getcol(v)
  if (!is.null(cv)) {
    cat("\n== table of", cv, "==\n")
    print(table(labstr(d[[cv]]), useNA = "ifany"))
  }
}

# ---- treatment string ----
tcol <- getcol(c("treatment"))
tl <- if (!is.null(tcol)) labstr(d[[tcol]]) else rep("", nrow(d))
tl[is.na(tl)] <- ""

fill0 <- function(x) { x <- num(x); x[is.na(x)] <- 0; x }

# Professionals
pcol <- getcol(c("professionals"))
prof <- if (!is.null(pcol)) fill0(d[[pcol]]) == 1 else grepl("prof", tl, ignore.case = TRUE)

# Incentive-first costly
icol <- getcol(c("seeincentivecostly", "incentivecostly", "incentivefirstcostly", "costlyincentive",
                 "seeincentivefirstcostly"))
incost <- if (!is.null(icol)) fill0(d[[icol]]) == 1 else
  (grepl("incent", tl, ignore.case = TRUE) & grepl("cost", tl, ignore.case = TRUE))

# Quality-first costly
qcol <- getcol(c("seequalitycostly", "qualitycostly", "qualityfirstcostly"))
qcost <- if (!is.null(qcol)) fill0(d[[qcol]]) == 1 else
  (grepl("qual", tl, ignore.case = TRUE) & grepl("cost", tl, ignore.case = TRUE))

# Exclusions (robustness arms)
excl <- grepl("high|stake|replic|determ|10", tl, ignore.case = TRUE) & !incost & !qcost & !prof
nochoice <- grepl("no ?choice", tl, ignore.case = TRUE)
excl <- excl | nochoice
attcol <- getcol(c("attentive"))
if (!is.null(attcol)) excl <- excl | (fill0(d[[attcol]]) == 0)

d$prof <- as.numeric(prof)
d$incost <- as.numeric(incost & !prof)
d$qcost <- as.numeric(qcost & !prof)
d$main <- !excl
cat("\nArm counts (main):\n")
print(table(prof = d$prof[d$main], incost = d$incost[d$main], qcost = d$qcost[d$main]))

# ---- outcome: prefer to see incentive first ----
ycol <- getcol(c("choicebefore", "preferincentivefirst", "choice"))
d$pref <- num(d[[ycol]])
cat("\nPreference variable:", ycol, "\n"); print(table(d$pref, useNA = "ifany"))

# ---- controls ----
gcol <- getcol(c("gender", "female", "male"))
acol <- getcol(c("age"))
d$gender_f <- if (!is.null(gcol)) factor(ifelse(is.na(num(d[[gcol]])), -9, num(d[[gcol]]))) else factor(0)
d$age_n <- if (!is.null(acol)) num(d[[acol]]) else 0
if (!is.null(acol)) { cat("Age NA:", sum(is.na(d$age_n)), "\n") }
wcol <- getcol(c("wave"))
d$wave_f <- if (!is.null(wcol)) factor(ifelse(is.na(num(d[[wcol]])), -9, num(d[[wcol]]))) else factor(0)
d$prob_c <- if (!is.null(getcol("probabilistic_incentive"))) fill0(d[[getcol("probabilistic_incentive")]]) else 0
d$ihigh_c <- if (!is.null(getcol("incentiveshigh"))) fill0(d[[getcol("incentiveshigh")]]) else 0
lcol <- getcol(c("incentiveleft", "incentive_left", "incentiveonleft", "left", "positionleft"))
d$left_c <- if (!is.null(lcol)) fill0(d[[lcol]]) else 0
d$ihl_c <- if (!is.null(getcol("incentiveshigh_incentiveleft"))) fill0(d[[getcol("incentiveshigh_incentiveleft")]]) else d$ihigh_c * d$left_c
d$probleft_c <- d$prob_c * d$left_c

ctrl <- "gender_f + age_n + wave_f + prob_c + ihigh_c + left_c + ihl_c + probleft_c"

# ---- Table 2 ----
s1 <- d[d$main & !is.na(d$pref), ]
m1 <- feols(as.formula(paste("pref ~ prof + incost + qcost +", ctrl)), data = s1, vcov = "hetero")
print(summary(m1))

scol <- getcol(c("selfish", "selfishness"))
s2 <- s1[s1$prof == 0 & !is.na(num(s1[[scol]])), ]
sraw <- num(s2[[scol]])
s2$selfz <- (sraw - mean(sraw)) / sd(sraw)
s2$self_incost <- s2$selfz * s2$incost
s2$self_qcost <- s2$selfz * s2$qcost
m2 <- feols(as.formula(paste("pref ~ incost + qcost + selfz +", ctrl)), data = s2, vcov = "hetero")
m3 <- feols(as.formula(paste("pref ~ incost + qcost + selfz + self_incost + self_qcost +", ctrl)),
            data = s2, vcov = "hetero")
print(summary(m2)); print(summary(m3))

# ---- Table 3 ----
gyc <- getcol(c("getyourchoice"))
d$assigned <- num(d[[gyc]])
d$rec <- num(d[[getcol(c("recommendincentive"))]])
ccol <- getcol(c("conflict"))
d$noconf <- 1 - num(d[[ccol]])
ibcol <- getcol(c("incentiveB", "incentiveb", "incentiveforb"))
if (!is.null(ibcol)) {
  d$incB <- num(d[[ibcol]])
} else {
  cm <- getcol(c("commission"))
  cl <- labstr(d[[cm]])
  if (any(grepl("B", cl))) d$incB <- as.numeric(grepl("B", cl)) else d$incB <- num(d[[cm]])
}
cat("\nIncentive for B:\n"); print(table(d$incB, useNA = "ifany"))
d$notassigned <- 1 - d$assigned
d$pref_x_noconf <- d$pref * d$noconf
d$pref_x_notassigned <- d$pref * d$notassigned
d$noconf_x_notassigned <- d$noconf * d$notassigned

s3 <- d[d$main & !is.na(d$pref) & !is.na(d$rec) & !is.na(d$assigned) & !is.na(d$noconf), ]
f3 <- paste("rec ~ pref + noconf + pref_x_noconf + prof + incost + qcost + incB +", ctrl)
t3a <- feols(as.formula(f3), data = s3[s3$assigned == 1, ], vcov = "hetero")
t3b <- feols(as.formula(f3), data = s3[s3$assigned == 0, ], vcov = "hetero")
t3c <- feols(as.formula(paste(f3, "+ notassigned + pref_x_notassigned + noconf_x_notassigned")),
             data = s3, vcov = "hetero")
print(summary(t3a)); print(summary(t3b)); print(summary(t3c))

g <- function(m, v) { x <- coef(m)[v]; if (is.null(x) || is.na(x)) NA else unname(x) }

cat(sprintf("RESULT:see_incentive_first_costly_table2_col1=%.6f\n", g(m1, "incost")))
cat(sprintf("RESULT:assess_quality_first_costly_table2_col1=%.6f\n", g(m1, "qcost")))
cat(sprintf("RESULT:choice_free_professionals_table2_col1=%.6f\n", g(m1, "prof")))
cat(sprintf("RESULT:selfishness_table2_col2=%.6f\n", g(m2, "selfz")))
cat(sprintf("RESULT:selfishness_table2_col3=%.6f\n", g(m3, "selfz")))
cat(sprintf("RESULT:see_incentive_first_costly_x_selfishness_table2_col3=%.6f\n", g(m3, "self_incost")))
cat(sprintf("RESULT:see_quality_first_costly_x_selfishness_table2_col3=%.6f\n", g(m3, "self_qcost")))
cat(sprintf("RESULT:n_obs_table2_col1=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_obs_table2_cols2_3=%d\n", nobs(m2)))
cat(sprintf("RESULT:prefer_see_incentive_first_assigned_table3_col1=%.6f\n", g(t3a, "pref")))
cat(sprintf("RESULT:prefer_see_incentive_first_not_assigned_table3_col2=%.6f\n", g(t3b, "pref")))
cat(sprintf("RESULT:prefer_see_incentive_first_x_not_assigned_table3_col3=%.6f\n", g(t3c, "pref_x_notassigned")))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", nobs(t3a)))
