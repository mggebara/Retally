suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/saccardo_2023_demand_moral_commitment.script-free"
d <- haven::read_dta(file.path(base, "Data/Clean Data/choice_experiments.dta"))
d <- as.data.frame(d)
cat("Rows loaded:", nrow(d), "\n")
cat("Columns:", paste(names(d), collapse = ", "), "\n")

pick <- function(df, cands) {
  nm <- names(df)
  for (c in cands) {
    idx <- which(tolower(nm) == tolower(c))
    if (length(idx) > 0) return(nm[idx[1]])
  }
  NULL
}
num <- function(x) suppressWarnings(as.numeric(haven::zap_labels(x)))
lab <- function(x) {
  if (inherits(x, "haven_labelled")) tolower(as.character(haven::as_factor(x)))
  else tolower(as.character(x))
}
ind <- function(x) { v <- num(x); v[is.na(v)] <- 0; as.numeric(v == 1) }

# ---------------- Diagnostics on treatment variables ----------------
v_treat <- pick(d, c("treatment"))
v_cond <- pick(d, c("condition"))
v_sample <- pick(d, c("sample"))
tr <- if (!is.null(v_treat)) lab(d[[v_treat]]) else rep("", nrow(d))
cnd <- if (!is.null(v_cond)) lab(d[[v_cond]]) else rep("", nrow(d))
smp <- if (!is.null(v_sample)) lab(d[[v_sample]]) else rep("", nrow(d))
cat("Treatment table:\n"); print(table(tr, useNA = "ifany"))
cat("Sample table:\n"); print(table(smp, useNA = "ifany"))
for (v in c("wave", "professionals", "professionalsfree", "seequalitycostly", "qualitycostly",
            "seeincentivecostly", "incentivecostly", "incentiveshigh", "probabilistic_incentive",
            "incentivedesign", "flippedorder", "getyourchoice", "choicebefore", "inconsistentid",
            "attentive", "costlydemand")) {
  p <- pick(d, v)
  if (!is.null(p)) { cat("Table of", p, ":\n"); print(table(lab(d[[p]]), useNA = "ifany")) }
}

# ---------------- Treatment indicators ----------------
v_prof <- pick(d, c("professionalsfree", "professionals"))
prof <- if (!is.null(v_prof)) ind(d[[v_prof]]) else as.numeric(grepl("prof", smp) | grepl("prof", tr))
prof <- as.numeric(prof == 1 | grepl("prof", smp))

v_inc <- pick(d, c("seeincentivecostly", "incentivecostly", "incentivefirstcostly", "costlyincentive", "seeincentivefirstcostly"))
inccost <- if (!is.null(v_inc)) ind(d[[v_inc]]) else
  as.numeric(grepl("incentive", tr) & grepl("cost", tr) & !grepl("quality", tr))
v_qual <- pick(d, c("seequalitycostly", "qualitycostly", "qualityfirstcostly", "costlyquality"))
qualcost <- if (!is.null(v_qual)) ind(d[[v_qual]]) else
  as.numeric(grepl("quality", tr) & grepl("cost", tr))
prof[inccost == 1 | qualcost == 1] <- 0

# robustness arms to exclude (high stakes, replication, deterministic)
robust <- grepl("high|stake|replic|determin|10x|100x|10-fold|100-fold", tr) |
  grepl("high|stake|replic|determin", cnd)
robust[prof == 1] <- FALSE
cat("Robustness-arm rows flagged:", sum(robust), "\n")

main <- !robust
d$prof <- prof; d$inccost <- inccost; d$qualcost <- qualcost

# attentive / consistent MPL exclusions if available
v_incons <- pick(d, c("inconsistent", "inconsistentmpl", "multipleswitch", "inconsistentid"))
if (!is.null(v_incons)) {
  iv <- num(d[[v_incons]])
  if (all(iv[!is.na(iv)] %in% c(0, 1))) main <- main & !(iv %in% 1)
}
v_att <- pick(d, c("attentive"))
if (!is.null(v_att)) {
  av <- num(d[[v_att]])
  if (all(av[!is.na(av)] %in% c(0, 1))) main <- main & !(av %in% 0)
}

# ---------------- Outcome / key variables ----------------
v_pref <- pick(d, c("choicebefore", "preferincentivefirst", "prefer_incentivefirst", "choiceincentivefirst"))
d$pref <- num(d[[v_pref]])
v_rec <- pick(d, c("recommendincentive"))
d$rec <- num(d[[v_rec]])

v_flip <- pick(d, c("flippedorder"))
v_get <- pick(d, c("getyourchoice"))
notassigned <- NULL
if (!is.null(v_flip)) {
  fv <- num(d[[v_flip]]); m <- mean(fv[main], na.rm = TRUE)
  cat("Mean flippedorder in main:", m, "\n")
  if (is.finite(m) && m > 0.1 && m < 0.4) notassigned <- fv
}
if (is.null(notassigned) && !is.null(v_get)) {
  gv <- num(d[[v_get]]); notassigned <- 1 - gv
  cat("Using 1 - getyourchoice; mean:", mean(notassigned[main], na.rm = TRUE), "\n")
}
d$notassigned <- notassigned

v_conf <- pick(d, c("conflict"))
v_nocon <- pick(d, c("noconflict"))
d$noconflict <- if (!is.null(v_nocon)) num(d[[v_nocon]]) else 1 - num(d[[v_conf]])

v_incB <- pick(d, c("incentiveB", "incentiveforB", "incentive_b", "incentiveb"))
if (!is.null(v_incB)) {
  d$incB <- num(d[[v_incB]])
} else {
  v_com <- pick(d, c("commission", "incentive"))
  cv <- lab(d[[v_com]])
  d$incB <- as.numeric(grepl("b", cv))
}

# ---------------- Controls ----------------
ctrl_names <- c()
add_ctrl <- function(name, x) {
  x <- as.numeric(x)
  if (all(is.na(x))) return(invisible())
  if (any(is.na(x))) {
    d[[paste0(name, "_miss")]] <<- as.numeric(is.na(x))
    x[is.na(x)] <- 0
    ctrl_names <<- c(ctrl_names, paste0(name, "_miss"))
  }
  d[[name]] <<- x
  ctrl_names <<- c(ctrl_names, name)
}
v_gender <- pick(d, c("female", "gender", "male"))
if (!is.null(v_gender)) {
  g <- d[[v_gender]]
  gl <- lab(g); gn <- num(g)
  if (any(grepl("female|woman", gl))) gfem <- ifelse(is.na(gl) | gl %in% c("", "na"), NA, as.numeric(grepl("female|woman", gl)))
  else gfem <- gn
  add_ctrl("c_gender", gfem)
}
v_age <- pick(d, c("age"))
if (!is.null(v_age)) add_ctrl("c_age", num(d[[v_age]]))
v_prob <- pick(d, c("probabilistic_incentive", "probabilistic", "incentiveshigh"))
if (!is.null(v_prob)) add_ctrl("c_prob", num(d[[v_prob]]))
v_left <- pick(d, c("incentiveleft", "incentive_left", "incentiveonleft", "leftincentive", "productleft", "left"))
if (!is.null(v_left)) add_ctrl("c_left", num(d[[v_left]]))
v_int <- pick(d, c("incentiveshigh_incentiveleft"))
if (!is.null(v_int)) {
  add_ctrl("c_probleft", num(d[[v_int]]))
} else if (!is.null(v_prob) && !is.null(v_left)) {
  add_ctrl("c_probleft", d$c_prob * d$c_left)
}
v_wave <- pick(d, c("wave"))
wv <- lab(d[[v_wave]]); wv[is.na(wv)] <- "missing"
d$c_wave <- factor(wv)
cat("Controls used:", paste(ctrl_names, collapse = ", "), "+ wave FE\n")

wave_term <- function(dd) if (length(unique(dd$c_wave)) > 1) " + factor(c_wave)" else ""
fit <- function(fml_rhs, dd, y) {
  dd <- dd[complete.cases(dd[, c(y, all.vars(as.formula(paste("~", fml_rhs))))]), ]
  dd$c_wave <- droplevels(dd$c_wave)
  ctr <- ctrl_names[sapply(ctrl_names, function(v) length(unique(dd[[v]])) > 1)]
  f <- as.formula(paste(y, "~", fml_rhs, if (length(ctr)) paste("+", paste(ctr, collapse = " + ")) else "",
                        wave_term(dd)))
  m <- lm(f, data = dd)
  ct <- coeftest(m, vcov = vcovHC(m, type = "HC3"))
  list(model = m, ct = ct, n = nobs(m))
}
gc <- function(r, v) { x <- coef(r$model)[v]; if (is.null(x) || is.na(x)) NA else unname(x) }

# ---------------- Table 2 ----------------
dm <- d[main, ]
cat("Main sample N:", nrow(dm), " prof:", sum(dm$prof), " inccost:", sum(dm$inccost),
    " qualcost:", sum(dm$qualcost), "\n")
t2c1 <- fit("prof + inccost + qualcost", dm, "pref")
print(t2c1$ct)

v_self <- pick(d, c("selfish", "selfishness", "overallselfish"))
d2 <- dm[dm$prof == 0, ]
d2$selfraw <- num(d2[[v_self]])
d2 <- d2[!is.na(d2$selfraw) & !is.na(d2$pref), ]
d2$selfz <- (d2$selfraw - mean(d2$selfraw)) / sd(d2$selfraw)
t2c2 <- fit("inccost + qualcost + selfz", d2, "pref")
print(t2c2$ct)
t2c3 <- fit("inccost + qualcost + selfz + inccost:selfz + qualcost:selfz", d2, "pref")
print(t2c3$ct)

# ---------------- Table 3 ----------------
d3 <- dm[!is.na(dm$notassigned) & !is.na(dm$rec) & !is.na(dm$pref), ]
rhs3 <- "pref + noconflict + pref:noconflict + prof + inccost + qualcost + incB"
t3c1 <- fit(rhs3, d3[d3$notassigned == 0, ], "rec")
print(t3c1$ct)
t3c2 <- fit(rhs3, d3[d3$notassigned == 1, ], "rec")
print(t3c2$ct)
t3c3 <- fit(paste(rhs3, "+ notassigned + pref:notassigned + noconflict:notassigned"), d3, "rec")
print(t3c3$ct)

cat(sprintf("RESULT:see_incentive_first_costly_table2_col1=%.6f\n", gc(t2c1, "inccost")))
cat(sprintf("RESULT:assess_quality_first_costly_table2_col1=%.6f\n", gc(t2c1, "qualcost")))
cat(sprintf("RESULT:choice_free_professionals_table2_col1=%.6f\n", gc(t2c1, "prof")))
cat(sprintf("RESULT:selfishness_table2_col2=%.6f\n", gc(t2c2, "selfz")))
cat(sprintf("RESULT:selfishness_table2_col3=%.6f\n", gc(t2c3, "selfz")))
cat(sprintf("RESULT:see_incentive_first_costly_x_selfishness_table2_col3=%.6f\n", gc(t2c3, "inccost:selfz")))
cat(sprintf("RESULT:see_quality_first_costly_x_selfishness_table2_col3=%.6f\n", gc(t2c3, "qualcost:selfz")))
cat(sprintf("RESULT:n_obs_table2_col1=%d\n", as.integer(t2c1$n)))
cat(sprintf("RESULT:n_obs_table2_cols2_3=%d\n", as.integer(t2c2$n)))
cat(sprintf("RESULT:prefer_see_incentive_first_assigned_table3_col1=%.6f\n", gc(t3c1, "pref")))
cat(sprintf("RESULT:prefer_see_incentive_first_not_assigned_table3_col2=%.6f\n", gc(t3c2, "pref")))
cat(sprintf("RESULT:prefer_see_incentive_first_x_not_assigned_table3_col3=%.6f\n", gc(t3c3, "pref:notassigned")))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", as.integer(t3c1$n)))
