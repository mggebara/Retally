suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/carrera_2022_who_chooses_commitment.script-free/Who_Chooses_Commitment_Replication/Data"
d0 <- read_dta(file.path(base, "cleaned_commitment_study_data.dta"))
nm <- names(d0)
cat("Rows:", nrow(d0), " Cols:", ncol(d0), "\n")
print(nm)

num <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.character(x)) return(suppressWarnings(as.numeric(x)))
  if (is.factor(x)) return(suppressWarnings(as.numeric(as.character(x))))
  as.numeric(zap_labels(x))
}
lab <- function(x) {
  if (is.null(x)) return(rep("", nrow(d0)))
  if (inherits(x, "haven_labelled")) return(as.character(as_factor(x)))
  as.character(x)
}

emit <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0 || is.na(v)) cat(sprintf("RESULT:%s=NA\n", name))
  else cat(sprintf("RESULT:%s=%.6f\n", name, v))
}

wave <- num(d0$wave)
cat("Wave table:\n"); print(table(wave, useNA = "ifany"))

## ---------------- Identify actual attendance variable via daily data -------------
actual_var <- "visits"
dd <- tryCatch(read_dta(file.path(base, "cleaned_commitment_study_daily_data.dta")),
               error = function(e) NULL)
if (!is.null(dd) && "attended" %in% names(dd) &&
    all(c("visits", "visits_next4weeks") %in% names(dd))) {
  keys <- intersect(c("wave", "wtp1", "wtp2", "wtp3", "wtp5", "wtp7", "wtp12", "goal",
                      "visits", "visits_100days", "visits_next4weeks", "past4",
                      "treatment", "incentive"), names(dd))
  ddk <- as.data.frame(lapply(dd[keys], num))
  ddk$att <- num(dd$attended)
  agg <- ddk %>% group_by(across(all_of(keys))) %>%
    summarise(n = n(), s = sum(att, na.rm = TRUE), .groups = "drop") %>%
    filter(n == 28)
  a_v <- mean(agg$s == agg$visits, na.rm = TRUE)
  a_n <- mean(agg$s == agg$visits_next4weeks, na.rm = TRUE)
  cat("Daily agreement: visits =", a_v, " visits_next4weeks =", a_n, "\n")
  if (is.finite(a_n) && is.finite(a_v) && a_n > a_v) actual_var <- "visits_next4weeks"
}
other_var <- setdiff(c("visits", "visits_next4weeks"), actual_var)
cat("Actual attendance variable:", actual_var, "\n")
actual <- num(d0[[actual_var]])

## ---------------- Identify forecast-under-incentive columns -----------------------
rates <- c(1, 2, 3, 5, 7, 12)
cand <- nm[grepl("(?<![0-9])1(?![0-9])", nm, perl = TRUE)]
templates <- unique(sub("(?<![0-9])1(?![0-9])", "%s", cand, perl = TRUE))
templates <- templates[!grepl("%.*%", templates)]
ok <- templates[sapply(templates, function(t) all(sprintf(t, rates) %in% nm))]
ok <- ok[!grepl("wtp|previsit|days_|commit|percent|meet", ok, ignore.case = TRUE)]
cat("Candidate forecast templates:\n"); print(ok)
best_t <- NA; best_s <- -Inf
for (t in ok) {
  M <- tryCatch(sapply(rates, function(p) num(d0[[sprintf(t, p)]])), error = function(e) NULL)
  if (is.null(M) || !is.numeric(M)) next
  inr <- mean(M >= 0 & M <= 28, na.rm = TRUE)
  nonm <- mean(!is.na(M))
  mm <- colMeans(M, na.rm = TRUE)
  cr <- suppressWarnings(cor(rates, mm))
  if (!is.finite(cr)) cr <- 0
  sc <- inr + nonm + cr + 0.5 * grepl("vis|exp|fore|att|pred|guess|est", t, ignore.case = TRUE)
  cat("  template", t, "score", sc, "means", round(mm, 2), "\n")
  if (is.finite(sc) && sc > best_s) { best_s <- sc; best_t <- t }
}
cat("Chosen forecast template:", best_t, "\n")

W <- sapply(rates, function(p) num(d0[[paste0("wtp", p)]]))
if (!is.na(best_t)) {
  Fm <- sapply(rates, function(p) num(d0[[sprintf(best_t, p)]]))
  f0name <- sprintf(best_t, 0)
  F0 <- if (f0name %in% nm) num(d0[[f0name]]) else num(d0[[other_var]])
} else {
  Fm <- matrix(NA_real_, nrow(d0), length(rates))
  F0 <- num(d0[[other_var]])
}
cat("Mean WTP by rate:", round(colMeans(W, na.rm = TRUE), 2), "\n")
cat("Mean forecast by rate:", round(colMeans(Fm, na.rm = TRUE), 2), " F0 mean:", mean(F0, na.rm = TRUE), "\n")

## Behavior change premium: average over adjacent pairs
B <- sapply(1:5, function(i) {
  dlt <- rates[i + 1] - rates[i]
  (W[, i + 1] - W[, i]) / dlt - (Fm[, i + 1] + Fm[, i]) / 2
})
bcp <- rowMeans(B, na.rm = TRUE)
bcp[!is.finite(bcp)] <- NA

## ---------------- Information treatment -------------------------------------------
tr <- num(d0$treatment)
if (is.null(tr) || !all(na.omit(tr) %in% c(0, 1))) {
  if (!is.null(tr) && length(unique(na.omit(tr))) == 2) {
    tr <- as.numeric(tr == max(tr, na.rm = TRUE))
  } else if ("type_of_info" %in% nm) {
    ti <- num(d0$type_of_info)
    if (all(is.na(ti))) {
      tl <- tolower(lab(d0$type_of_info))
      tr <- as.numeric(!(tl %in% c("", "none", "control", "no info", "na")) & !is.na(tl))
    } else tr <- as.numeric(ti > 0)
  }
}
cat("Treatment by wave:\n"); print(table(tr, wave, useNA = "ifany"))
basic <- as.numeric(tr == 1 & wave == 1)
enhanced <- as.numeric(tr == 1 & wave %in% c(2, 3))

## ---------------- Assigned incentive ----------------------------------------------
inc_num <- num(d0$incentive)
inc_lab <- lab(d0$incentive)
itxt <- if ("incentivetext" %in% nm) lab(d0$incentivetext) else rep("", nrow(d0))
cat("Incentive table:\n"); print(table(inc_num, wave, useNA = "ifany"))
print(head(table(paste(inc_lab, "|", itxt)), 40))
alltxt <- paste(inc_lab, itxt)
contract <- grepl("\\$?80|commit|12\\+|least|or more", alltxt, ignore.case = TRUE) |
  (!is.na(inc_num) & inc_num == 80)
contract[is.na(contract)] <- FALSE
if (sum(contract & wave == 3, na.rm = TRUE) == 0) {
  contract <- wave == 3 & !is.na(inc_num) & !(inc_num %in% c(0, 1, 2, 3, 5, 7, 12))
  contract[is.na(contract)] <- FALSE
}
cat("Contract-assigned by wave:\n"); print(table(contract, wave))

pr <- inc_num
if (mean(pr[!contract] %in% c(0, 1, 2, 3, 5, 7, 12), na.rm = TRUE) < 0.9) {
  pt <- suppressWarnings(as.numeric(sub(".*\\$([0-9]+).*", "\\1", itxt)))
  pt[grepl("no incentive|fixed|none", itxt, ignore.case = TRUE)] <- 0
  pr <- pt
}
pr[contract] <- NA
idx <- match(pr, rates)
exp_assigned <- ifelse(!is.na(pr) & pr == 0, F0,
                       Fm[cbind(seq_len(nrow(d0)), ifelse(is.na(idx), 1, idx))])
exp_assigned[!is.na(pr) & pr != 0 & is.na(idx)] <- NA
exp_assigned[is.na(pr)] <- NA

goal <- num(d0$goal)
gap_goal <- goal - F0
gap_act <- actual - exp_assigned

## ---------------- Sample ------------------------------------------------------------
excl <- num(d0$flag_exclude_exog); excl[is.na(excl)] <- 0
s1 <- excl != 1 & !contract
s2 <- excl != 1 & !(contract & wave == 3)
base_ok <- !is.na(bcp) & !is.na(tr) & !is.na(wave)
n1 <- sum(s1 & base_ok); n2 <- sum(s2 & base_ok)
cat("Sample N rule1:", n1, " rule2:", n2, "\n")
samp <- if (abs(n2 - 1126) < abs(n1 - 1126)) s2 else s1
samp <- samp & base_ok

df <- data.frame(id = seq_len(nrow(d0)), wave = wave, basic = basic, enhanced = enhanced,
                 bcp = bcp, gap_goal = gap_goal, gap_act = gap_act)[samp, ]
z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
df$z_goal <- z(df$gap_goal)
df$z_act <- z(df$gap_act)
df$z_bcp <- z(df$bcp)
cat("Mean BCP in sample:", mean(df$bcp), "\n")

getc <- function(m, v) tryCatch(unname(coef(m)[v]), error = function(e) NA)
m1 <- tryCatch(feols(bcp ~ basic + enhanced | wave, data = df, vcov = "hetero"), error = function(e) NULL)
m2 <- tryCatch(feols(bcp ~ basic + enhanced + z_goal | wave, data = df, vcov = "hetero"), error = function(e) NULL)
m3 <- tryCatch(feols(bcp ~ basic + enhanced + z_act | wave, data = df, vcov = "hetero"), error = function(e) NULL)
for (m in list(m1, m2, m3)) if (!is.null(m)) print(summary(m))

## ---------------- Table 4: "more" contract take-up -----------------------------------
findchose <- function(th) {
  c1 <- paste0("chose_commit", th)
  if (c1 %in% nm) return(c1)
  cc <- nm[grepl(paste0("chose.*(?<![0-9])", th, "(?![0-9])"), nm, perl = TRUE, ignore.case = TRUE)]
  cc <- cc[!grepl("less|under|most|fewer|percent|meet", cc, ignore.case = TRUE)]
  if (length(cc)) cc[1] else NA
}
ths <- c(8, 12, 16)
cols <- sapply(ths, findchose)
cat("More-contract columns:", cols, "\n")
raw <- lapply(cols, function(cn) if (is.na(cn)) rep(NA_real_, nrow(d0)) else num(d0[[cn]]))
# orientation
vals <- sort(unique(na.omit(unlist(raw))))
cat("Choice values:", vals, "\n")
if (!all(vals %in% c(0, 1)) && length(vals) == 2) {
  k <- if (mean(raw[[1]] == vals[1], na.rm = TRUE) > 0.5) vals[1] else vals[2]
  if (all(is.na(raw[[1]]))) k <- if (mean(raw[[2]] == vals[1], na.rm = TRUE) > 0.45) vals[1] else vals[2]
  raw <- lapply(raw, function(v) as.numeric(v == k))
}
raw[[1]][wave == 3] <- NA
raw[[3]][wave == 3] <- NA
for (i in 1:3) cat("Take-up at", ths[i], ":", mean(raw[[i]][samp], na.rm = TRUE), "\n")

long <- do.call(rbind, lapply(1:3, function(i) {
  data.frame(id = seq_len(nrow(d0)), th = ths[i], y = raw[[i]])[samp, ]
}))
long <- merge(long, df[, c("id", "wave", "basic", "enhanced", "z_bcp", "z_goal", "z_act")], by = "id")
long <- long[!is.na(long$y), ]
cat("Table 4 N:", nrow(long), "\n")
t1 <- tryCatch(feols(y ~ basic + enhanced | wave + th, data = long, cluster = ~id), error = function(e) NULL)
t2 <- tryCatch(feols(y ~ basic + enhanced + z_bcp | wave + th, data = long, cluster = ~id), error = function(e) NULL)
t3 <- tryCatch(feols(y ~ basic + enhanced + z_goal | wave + th, data = long, cluster = ~id), error = function(e) NULL)
t4 <- tryCatch(feols(y ~ basic + enhanced + z_act | wave + th, data = long, cluster = ~id), error = function(e) NULL)
for (m in list(t1, t2, t3, t4)) if (!is.null(m)) print(summary(m))

emit("bcp_basic_info_treatment_col1", getc(m1, "basic"))
emit("bcp_enhanced_info_treatment_col1", getc(m1, "enhanced"))
emit("bcp_goal_minus_expected_attendance_col2", getc(m2, "z_goal"))
emit("bcp_actual_minus_expected_attendance_col3", getc(m3, "z_act"))
emit("bcp_regression_observations", if (!is.null(m1)) nobs(m1) else nrow(df))
emit("takeup_more_basic_info_treatment_col1", getc(t1, "basic"))
emit("takeup_more_enhanced_info_treatment_col1", getc(t1, "enhanced"))
emit("takeup_more_behavior_change_premium_col2", getc(t2, "z_bcp"))
emit("takeup_more_goal_minus_expected_attendance_col3", getc(t3, "z_goal"))
emit("takeup_more_actual_minus_expected_attendance_col4", getc(t4, "z_act"))
emit("takeup_more_regression_observations", if (!is.null(t1)) nobs(t1) else nrow(long))