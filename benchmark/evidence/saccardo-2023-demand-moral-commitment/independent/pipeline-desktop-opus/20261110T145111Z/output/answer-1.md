suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/saccardo_2023_demand_moral_commitment.script-free"
d0 <- haven::read_dta(file.path(base, "Data/Clean Data/choice_experiments.dta"))
d0 <- as.data.frame(d0)
names(d0) <- tolower(names(d0))
cat("Columns:\n"); print(names(d0))
cat("N raw:", nrow(d0), "\n")

has <- function(v) v %in% names(d0)
num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) suppressWarnings(x <- as.numeric(x))
  as.numeric(x)
}
first_col <- function(cands) { for (c in cands) if (has(c)) return(c); NA_character_ }
lab_of <- function(x) {
  if (inherits(x, "haven_labelled")) return(tolower(as.character(haven::as_factor(x, levels = "labels"))))
  tolower(as.character(x))
}

for (v in c("treatment", "study", "sample", "condition", "wave", "professionals", "choice",
            "getyourchoice", "attentionpassed", "inconsistentid", "qualitycostly", "conflict",
            "incentivedesign", "probabilistic_incentive", "incentiveshigh")) {
  if (has(v)) { cat("Table of", v, ":\n"); print(table(lab_of(d0[[v]]), useNA = "ifany")) }
}

# ---------- Core variables ----------
d <- d0

# Preference: prefers to see incentive first
pref_col <- first_col(c("choicebefore", "preferincentivefirst", "prefer_incentivefirst", "choseincentivefirst", "choice_before"))
if (is.na(pref_col)) {
  cb <- grep("^choicebefore", names(d), value = TRUE)
  cb <- cb[!grepl("getyourchoice|noconfl|_x_|det", cb)]
  if (length(cb) > 0) pref_col <- cb[1]
}
if (is.na(pref_col)) pref_col <- "choice"
cat("Preference column:", pref_col, "\n")
d$pref <- num(d[[pref_col]])

# Assigned preference
assign_col <- first_col(c("getyourchoice", "assignedpreference", "gotchoice"))
d$assigned <- if (!is.na(assign_col)) num(d[[assign_col]]) else NA_real_
d$notassigned <- 1 - d$assigned

# Treatment indicators
d$prof <- if (has("professionals")) { x <- num(d$professionals); ifelse(is.na(x), 0, x) } else 0
if (has("professionalsfree")) {
  x <- num(d$professionalsfree); d$prof <- pmax(d$prof, ifelse(is.na(x), 0, x))
}
trt_lab <- if (has("treatment")) lab_of(d$treatment) else rep("", nrow(d))
cond_lab <- if (has("condition")) lab_of(d$condition) else rep("", nrow(d))
alllab <- paste(trt_lab, cond_lab)

if (has("qualitycostly")) {
  d$qualcostly <- num(d$qualitycostly); d$qualcostly[is.na(d$qualcostly)] <- 0
} else {
  d$qualcostly <- as.numeric(grepl("costly", alllab) & grepl("quality", alllab))
}
inc_col <- first_col(c("incentivecostly", "costlyincentive", "incentivefirstcostly", "seeincentivecostly", "getbeforecostly"))
if (!is.na(inc_col)) {
  d$inccostly <- num(d[[inc_col]]); d$inccostly[is.na(d$inccostly)] <- 0
} else {
  d$inccostly <- as.numeric(grepl("costly", alllab) & grepl("incentive", alllab) & !grepl("quality", alllab))
  if (sum(d$inccostly) == 0 && has("costlydemand")) {
    # fallback: costly treatments that are not quality-costly
    cd <- num(d$costlydemand)
    d$inccostly <- as.numeric(!is.na(cd) & cd == 1 & d$qualcostly == 0)
  }
}
d$inccostly[d$prof == 1] <- 0
d$qualcostly[d$prof == 1] <- 0
cat("Treatment indicator sums: prof", sum(d$prof), " inccostly", sum(d$inccostly), " qualcostly", sum(d$qualcostly), "\n")

# Controls
gcol <- first_col(c("gender", "female", "male", "sex"))
if (!is.na(gcol)) {
  g <- lab_of(d[[gcol]]); g[is.na(g) | g == ""] <- "missing"; d$gender_f <- factor(g)
} else d$gender_f <- factor("all")
acol <- first_col(c("age", "age_num", "agenum"))
if (!is.na(acol)) {
  a <- num(d[[acol]]); d$age_miss <- as.numeric(is.na(a)); a[is.na(a)] <- mean(a, na.rm = TRUE); d$age_c <- a
} else { d$age_c <- 0; d$age_miss <- 0 }
if (has("wave")) { w <- lab_of(d$wave); w[is.na(w) | w == ""] <- "none"; d$wave_f <- factor(w) } else d$wave_f <- factor("1")
pcol <- first_col(c("probabilistic_incentive", "incentiveshigh", "incentivedesign"))
d$probab <- if (!is.na(pcol)) { x <- num(d[[pcol]]); ifelse(is.na(x), 0, x) } else 0
lcol <- first_col(c("incentiveleft", "incentive_left", "leftincentive", "incentivedleft"))
d$left <- if (!is.na(lcol)) { x <- num(d[[lcol]]); ifelse(is.na(x), 0, x) } else 0
if (has("incentiveshigh_incentiveleft")) {
  x <- num(d$incentiveshigh_incentiveleft); d$prob_left <- ifelse(is.na(x), 0, x)
} else d$prob_left <- d$probab * d$left

# Selfishness
d$selfish_raw <- if (has("selfish")) num(d$selfish) else NA_real_

# Recommendation / conflict
d$rec <- if (has("recommendincentive")) num(d$recommendincentive) else NA_real_
d$conf <- if (has("conflict")) num(d$conflict) else NA_real_
d$noconf <- 1 - d$conf
ibcol <- first_col(c("incentiveb", "incentive_b", "commissionb"))
if (!is.na(ibcol)) {
  d$incB <- num(d[[ibcol]])
} else if (has("commission")) {
  cl <- lab_of(d$commission); d$incB <- as.numeric(grepl("b", cl))
} else d$incB <- 0
d$incB[is.na(d$incB)] <- 0

# ---------- Sample restriction: choose the one matching N = 5908 ----------
base_ok <- !is.na(d$pref)
att <- if (has("attentionpassed")) num(d$attentionpassed) else rep(1, nrow(d))
inc <- if (has("inconsistentid")) num(d$inconsistentid) else rep(0, nrow(d))
# main Choice treatments only: exclude other studies if identifiable
main_ok <- rep(TRUE, nrow(d))
if (has("study")) {
  sl <- lab_of(d$study)
  bad <- grepl("stake|determin|architect|nochoice|replic|high", sl)
  if (any(bad) && !all(bad)) main_ok <- !bad
}
cands <- list(
  attn_cons = base_ok & (is.na(att) | att == 1) & (is.na(inc) | inc == 0),
  attn_cons_main = base_ok & main_ok & (is.na(att) | att == 1) & (is.na(inc) | inc == 0),
  attn = base_ok & (is.na(att) | att == 1),
  none = base_ok,
  main = base_ok & main_ok
)
ns <- sapply(cands, sum)
print(ns)
pick <- names(ns)[which.min(abs(ns - 5908))]
cat("Chosen sample restriction:", pick, "\n")
s <- d[cands[[pick]], ]

ctrl <- "gender_f + age_c + age_miss + wave_f + probab + left + prob_left"
rhs_drop <- function(df, f) {
  # drop factors with single level to avoid errors
  f
}
hc3 <- function(m) sqrt(diag(sandwich::vcovHC(m, type = "HC3")))
safe_coef <- function(m, v) { cf <- coef(m); if (v %in% names(cf)) unname(cf[v]) else NA_real_ }
one_level_fix <- function(df) {
  for (v in c("gender_f", "wave_f")) df[[v]] <- droplevels(factor(df[[v]]))
  df
}
build_ctrl <- function(df) {
  parts <- c()
  if (nlevels(df$gender_f) > 1) parts <- c(parts, "gender_f")
  parts <- c(parts, "age_c")
  if (length(unique(df$age_miss)) > 1) parts <- c(parts, "age_miss")
  if (nlevels(df$wave_f) > 1) parts <- c(parts, "wave_f")
  for (v in c("probab", "left", "prob_left")) if (length(unique(df[[v]])) > 1) parts <- c(parts, v)
  paste(parts, collapse = " + ")
}

# ---------- Table 2 ----------
s1 <- one_level_fix(s)
f1 <- as.formula(paste("pref ~ prof + inccostly + qualcostly +", build_ctrl(s1)))
m1 <- lm(f1, data = s1)
print(coeftest(m1, vcov = vcovHC(m1, type = "HC3"))[c("prof", "inccostly", "qualcostly"), ])

s2 <- s1 %>% filter(prof == 0, !is.na(selfish_raw))
s2 <- one_level_fix(s2)
s2$selfish_z <- (s2$selfish_raw - mean(s2$selfish_raw)) / sd(s2$selfish_raw)
f2 <- as.formula(paste("pref ~ inccostly + qualcostly + selfish_z +", build_ctrl(s2)))
m2 <- lm(f2, data = s2)
f3 <- as.formula(paste("pref ~ inccostly + qualcostly + selfish_z + inccostly:selfish_z + qualcostly:selfish_z +", build_ctrl(s2)))
m3 <- lm(f3, data = s2)
print(coeftest(m3, vcov = vcovHC(m3, type = "HC3")))

# ---------- Table 3 ----------
t <- s1 %>% filter(!is.na(rec), !is.na(noconf), !is.na(assigned))
t <- one_level_fix(t)
t1 <- one_level_fix(t %>% filter(assigned == 1))
t2 <- one_level_fix(t %>% filter(assigned == 0))
rhs3 <- "pref + noconf + pref:noconf + prof + inccostly + qualcostly + incB"
m31 <- lm(as.formula(paste("rec ~", rhs3, "+", build_ctrl(t1))), data = t1)
m32 <- lm(as.formula(paste("rec ~", rhs3, "+", build_ctrl(t2))), data = t2)
m33 <- lm(as.formula(paste("rec ~", rhs3, "+ notassigned + pref:notassigned + noconf:notassigned +", build_ctrl(t))), data = t)
print(coeftest(m33, vcov = vcovHC(m33, type = "HC3")))

ia <- grep("notassigned", names(coef(m33)), value = TRUE)
ia <- ia[grepl("pref", ia) & !grepl("noconf", ia)]
inter_name <- if (length(ia) > 0) ia[1] else "pref:notassigned"

i3a <- grep("selfish_z", names(coef(m3)), value = TRUE)
inc_int <- i3a[grepl("inccostly", i3a)][1]
qual_int <- i3a[grepl("qualcostly", i3a)][1]

cat(sprintf("RESULT:see_incentive_first_costly_table2_col1=%.6f\n", safe_coef(m1, "inccostly")))
cat(sprintf("RESULT:assess_quality_first_costly_table2_col1=%.6f\n", safe_coef(m1, "qualcostly")))
cat(sprintf("RESULT:choice_free_professionals_table2_col1=%.6f\n", safe_coef(m1, "prof")))
cat(sprintf("RESULT:selfishness_table2_col2=%.6f\n", safe_coef(m2, "selfish_z")))
cat(sprintf("RESULT:selfishness_table2_col3=%.6f\n", safe_coef(m3, "selfish_z")))
cat(sprintf("RESULT:see_incentive_first_costly_x_selfishness_table2_col3=%.6f\n", safe_coef(m3, inc_int)))
cat(sprintf("RESULT:see_quality_first_costly_x_selfishness_table2_col3=%.6f\n", safe_coef(m3, qual_int)))
cat(sprintf("RESULT:n_obs_table2_col1=%d\n", as.integer(nobs(m1))))
cat(sprintf("RESULT:n_obs_table2_cols2_3=%d\n", as.integer(nobs(m2))))
cat(sprintf("RESULT:prefer_see_incentive_first_assigned_table3_col1=%.6f\n", safe_coef(m31, "pref")))
cat(sprintf("RESULT:prefer_see_incentive_first_not_assigned_table3_col2=%.6f\n", safe_coef(m32, "pref")))
cat(sprintf("RESULT:prefer_see_incentive_first_x_not_assigned_table3_col3=%.6f\n", safe_coef(m33, inter_name)))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", as.integer(nobs(m31))))
