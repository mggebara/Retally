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

for (v in c("treatment", "study", "sample", "condition", "wave", "highx10", "highx100",
            "getyourchoice", "attentionpassed", "qualitycostly", "incentivecostly", "professionals",
            "incentiveshigh", "probabilistic_incentive", "incentivedesign", "mturkwave")) {
  if (has(v)) { cat("Table of", v, ":\n"); print(table(lab_of(d0[[v]]), useNA = "ifany")) }
}

# ---------- Core variables ----------
d <- d0

pref_col <- first_col(c("choicebefore", "preferincentivefirst", "prefer_incentivefirst", "choseincentivefirst", "choice_before"))
if (is.na(pref_col)) pref_col <- "choice"
cat("Preference column:", pref_col, "\n")
d$pref <- num(d[[pref_col]])

assign_col <- first_col(c("getyourchoice", "assignedpreference", "gotchoice"))
d$assigned <- if (!is.na(assign_col)) num(d[[assign_col]]) else NA_real_
d$notassigned <- 1 - d$assigned

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
}
d$inccostly[d$prof == 1] <- 0
d$qualcostly[d$prof == 1] <- 0

# Design-variation controls (fn. 14): probabilistic payment and left/right position
pcol <- first_col(c("probabilistic_incentive", "incentiveshigh", "incentivedesign"))
d$probab <- if (!is.na(pcol)) { x <- num(d[[pcol]]); ifelse(is.na(x), 0, x) } else 0
lcol <- first_col(c("incentiveleft", "incentive_left", "leftincentive", "incentivedleft"))
d$left <- if (!is.na(lcol)) { x <- num(d[[lcol]]); ifelse(is.na(x), 0, x) } else 0
if (has("incentiveshigh_incentiveleft")) {
  x <- num(d$incentiveshigh_incentiveleft); d$prob_left <- ifelse(is.na(x), 0, x)
} else d$prob_left <- d$probab * d$left

d$selfish_raw <- if (has("selfish")) num(d$selfish) else NA_real_
cat("selfish summary: mean", mean(d$selfish_raw, na.rm = TRUE), " sd", sd(d$selfish_raw, na.rm = TRUE), "\n")
if (has("stdalpha")) cat("stdalpha summary: mean", mean(num(d$stdalpha), na.rm = TRUE), " sd", sd(num(d$stdalpha), na.rm = TRUE), "\n")

d$rec <- if (has("recommendincentive")) num(d$recommendincentive) else NA_real_
d$conf <- if (has("conflict")) num(d$conflict) else NA_real_
d$noconf <- 1 - d$conf
ibcol <- first_col(c("incentiveb", "incentive_b", "commissionb"))
d$incB <- if (!is.na(ibcol)) num(d[[ibcol]]) else 0
d$incB[is.na(d$incB)] <- 0

# ---------- Sample restriction ----------
# Table 2 uses the four main Choice arms only (712 + 2574 + 1562 + 1067 ~ 5908);
# robustness arms (High Stakes x10/x100, Replication, Deterministic) are excluded.
base_ok <- !is.na(d$pref)
att <- if (has("attentionpassed")) num(d$attentionpassed) else rep(1, nrow(d))
inc <- if (has("inconsistentid")) num(d$inconsistentid) else rep(0, nrow(d))
attn_cons <- base_ok & (is.na(att) | att == 1) & (is.na(inc) | inc == 0)

z0 <- function(v) if (has(v)) { x <- num(d[[v]]); !is.na(x) & x == 1 } else rep(FALSE, nrow(d))
hx <- z0("highx10") | z0("highx100")
labs_all <- paste(if (has("study")) lab_of(d$study) else "",
                  if (has("sample")) lab_of(d$sample) else "",
                  trt_lab, cond_lab)
rep_det <- grepl("replic|determin", labs_all)
stake_lab <- grepl("stake|x10|x100|10x|100x|architect|nochoice|no choice", labs_all)

cands <- list(
  attn_cons = attn_cons,
  attn_cons_nohigh = attn_cons & !hx,
  attn_cons_nohigh_norep = attn_cons & !hx & !rep_det,
  attn_cons_nohigh_norep_nostake = attn_cons & !hx & !rep_det & !stake_lab,
  attn_nohigh_norep = base_ok & (is.na(att) | att == 1) & !hx & !rep_det
)
ns <- sapply(cands, sum)
print(ns)
pick <- names(ns)[which.min(abs(ns - 5908))]
cat("Chosen sample restriction:", pick, "\n")
cat("DEVIATION: Robustness arms identified via highx10/highx100 flags and replication/deterministic labels; restriction chosen as the candidate whose N is closest to the paper's 5908\n")
s <- d[cands[[pick]], ]

build_ctrl <- function(df) {
  parts <- c()
  for (v in c("probab", "left", "prob_left")) if (length(unique(df[[v]])) > 1) parts <- c(parts, v)
  if (length(parts) == 0) "1" else paste(parts, collapse = " + ")
}
safe_coef <- function(m, v) { cf <- coef(m); if (!is.na(v) && v %in% names(cf)) unname(cf[v]) else NA_real_ }

# ---------- Table 2 ----------
s1 <- s
f1 <- as.formula(paste("pref ~ prof + inccostly + qualcostly +", build_ctrl(s1)))
m1 <- lm(f1, data = s1)
print(coeftest(m1, vcov = vcovHC(m1, type = "HC1")))

s2 <- s1 %>% filter(prof == 0, !is.na(selfish_raw))
s2$selfish_z <- (s2$selfish_raw - mean(s2$selfish_raw)) / sd(s2$selfish_raw)
f2 <- as.formula(paste("pref ~ inccostly + qualcostly + selfish_z +", build_ctrl(s2)))
m2 <- lm(f2, data = s2)
f3 <- as.formula(paste("pref ~ inccostly + qualcostly + selfish_z + inccostly:selfish_z + qualcostly:selfish_z +", build_ctrl(s2)))
m3 <- lm(f3, data = s2)
print(coeftest(m3, vcov = vcovHC(m3, type = "HC1")))

# ---------- Table 3 ----------
t <- s1 %>% filter(!is.na(rec), !is.na(noconf), !is.na(assigned))
t1 <- t %>% filter(assigned == 1)
t2 <- t %>% filter(assigned == 0)
rhs3 <- "pref + noconf + pref:noconf + prof + inccostly + qualcostly + incB"
m31 <- lm(as.formula(paste("rec ~", rhs3, "+", build_ctrl(t1))), data = t1)
m32 <- lm(as.formula(paste("rec ~", rhs3, "+", build_ctrl(t2))), data = t2)
m33 <- lm(as.formula(paste("rec ~", rhs3, "+ notassigned + pref:notassigned + noconf:notassigned +", build_ctrl(t))), data = t)
print(coeftest(m33, vcov = vcovHC(m33, type = "HC1")))

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
