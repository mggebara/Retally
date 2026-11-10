# Independent reproduction: Ambuehl, Bernheim & Lusardi (2022), "Evaluating Deliberative Competence"
# Table 4 (exam-style test scores) and Table 7 (deliberative competence), Experiments A and B.
set.seed(42)
suppressMessages(library(readr)); suppressMessages(library(dplyr)); suppressMessages(library(tidyr))
suppressMessages(library(fixest))

D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-b/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) read_csv(file.path(D, f), col_types = cols(.default = "c"), show_col_types = FALSE, name_repair = "unique_quiet")
num <- function(v) suppressWarnings(as.numeric(v))

# ---------------------------------------------------------------- load raw Qualtrics exports
# Experiment A (2014, legacy Qualtrics export): row 1 of each file holds question labels.
A <- list()
for (b in 1:8) { x <- rd(sprintf("expAbatch%d.csv", b))[-1, ]; x$batch <- b; A[[b]] <- x }
common <- Reduce(intersect, lapply(A, names))
A <- bind_rows(lapply(A, function(x) x[, common]))
# Conditions in A: batches 1,2,4,5 randomise Treatment (full video; first-slide check word "compounding")
# vs Control (index-funds video; check word "funds"). Batches 3,6,7,8 randomise the two dissected videos:
# treatment==1 -> Substance-Only, treatment==0 -> Rhetoric-Only (identified from attention-check
# words and from the test-score pattern described in Section 2.4 / Table 6).
A$cond <- ifelse(A$batch %in% c(1, 2, 4, 5), ifelse(A$treatment == "1", "Control_T", "Control_C"),
                 ifelse(A$treatment == "1", "Substance", "Rhetoric"))
A$cond <- recode(A$cond, Control_T = "Treatment", Control_C = "Control")
# Experiment B (2018, new Qualtrics export): rows 1-2 hold labels and import ids.
B <- bind_rows(lapply(1:2, function(b) { x <- rd(sprintf("expBbatch%d.csv", b))[-(1:2), ]; x$batch <- b; x }))
B <- B[B$Status != "1", ]   # drop the survey-preview response
B$cond <- ifelse(B$treatment == "1", "Treatment", "Control")

# ---------------------------------------------------------------- price lists -> valuations
# 20 tasks per subject: tasks 1-10 simply framed, 11-20 complexly framed (embedded fields T1..T20).
# List 1: lines 1..11 = immediate $20,$18,...,$0 (1 = future reward chosen, 0 = immediate amount).
# List 2: lines 3..12 = immediate x+1.8, x+1.6, ..., x with x = 2*(#future choices in list 1) - 2.
# Valuation = midpoint of the switching interval = x + 0.2*(#future choices in list 2) - 0.1.
Rv <- c(20, 18, 16, 14, 12, 20, 18, 16, 14, 12, 20, 20, 18, 18, 16, 16, 14, 14, 12, 12)
tv <- c(72, 72, 72, 72, 72, 36, 36, 36, 36, 36, 36, 72, 36, 72, 36, 72, 36, 72, 36, 72)
colname <- function(k, l, j, exp) if (exp == "A") paste0("iMPL", k, "_", l, "_", j, ": 1") else paste0("iMPL", k, "-", l, "#1_iMPL", k, "-", l, "_", j)
build <- function(x, exp) {
  res <- list()
  for (k in 1:20) {
    L1 <- sapply(1:11, function(j) num(x[[colname(k, 1, j, exp)]]))
    L2 <- sapply(3:12, function(j) num(x[[colname(k, 2, j, exp)]]))
    res[[k]] <- data.frame(id = seq_len(nrow(x)), task = k,
      o1 = rowSums(L1 == 1), o2 = rowSums(L2 == 1),
      nonmono = apply(L1, 1, function(r) any(diff(r) < 0)) | apply(L2, 1, function(r) any(diff(r) < 0)),
      complete = rowSums(is.na(L1)) == 0 & rowSums(is.na(L2)) == 0)
  }
  r <- bind_rows(res)
  r$R <- Rv[r$task]; r$t <- tv[r$task]; r$frame <- ifelse(r$task <= 10, "s", "c")
  r$val <- 2 * r$o1 - 2 + 0.2 * r$o2 - 0.1
  r$r <- 100 * r$val / r$R           # normalized valuation, percent of the future reward
  r
}

# ---------------------------------------------------------------- test scores
tst <- paste0("test", 1:10)
# test1-5: compound interest questions (same in both experiments); test6-10: control-module questions.
keyA <- c(2, 4, 4, 7, 6, 3, 4, 2, 3, 3)   # A key; reproduces Qualtrics' own score (SC0_0) exactly
keyB <- c(2, 4, 4, 7, 6, 4, 5, 5, 5, 1)   # B control key from question content (Table C.2)
score <- function(X, key) {
  M <- sapply(tst, function(t) num(X[[t]]))
  data.frame(comp = rowSums(sweep(M[, 1:5], 2, key[1:5], "==") * 1, na.rm = TRUE),
             ctrl = rowSums(sweep(M[, 6:10], 2, key[6:10], "==") * 1, na.rm = TRUE))
}
A <- cbind(A, score(A, keyA)); B <- cbind(B, score(B, keyB))

# ---------------------------------------------------------------- sample
prep <- function(X, exp) {
  p <- build(X, exp)
  s <- p %>% group_by(id) %>% summarise(complete = all(complete), multi = any(nonmono, na.rm = TRUE), .groups = "drop")
  X$id <- seq_len(nrow(X)); X$complete <- s$complete; X$multi <- s$multi
  list(X = X, p = p)
}
pa <- prep(A, "A"); pb <- prep(B, "B")
for (e in c("A", "B")) {
  X <- if (e == "A") pa$X else pb$X
  cat(sprintf("Experiment %s: completed (all 20 price lists answered) = %d; multiple switchers = %d; analysis sample = %d\n",
              e, sum(X$complete), sum(X$complete & X$multi), sum(X$complete & !X$multi)))
}
SA <- pa$X[pa$X$complete & !pa$X$multi, ]
SB <- pb$X[pb$X$complete & !pb$X$multi, ]
print(table(SA$cond)); print(table(SB$cond))

# ---------------------------------------------------------------- Table 4
t4 <- function(S, y) {
  S <- S[S$cond %in% c("Control", "Treatment"), ]
  S$treat <- as.integer(S$cond == "Treatment")
  m <- feols(as.formula(paste(y, "~ treat")), data = S, vcov = "iid")
  list(coef = unname(coef(m)["treat"]), se = unname(se(m)["treat"]), n = nobs(m), ctrl = unname(coef(m)[1]))
}
c1 <- t4(SA, "comp"); c2 <- t4(SB, "comp"); c3 <- t4(SA, "ctrl"); c4 <- t4(SB, "ctrl")
cat(sprintf("Table 4: (1) A comp diff %.3f (%.3f) ctrl-level %.3f N=%d\n", c1$coef, c1$se, c1$ctrl, c1$n))
cat(sprintf("         (2) B comp diff %.3f (%.3f) ctrl-level %.3f N=%d\n", c2$coef, c2$se, c2$ctrl, c2$n))
cat(sprintf("         (3) A ctrl-module diff %.3f (%.3f) ctrl-level %.3f N=%d\n", c3$coef, c3$se, c3$ctrl, c3$n))
cat(sprintf("         (4) B ctrl-module diff %.3f (%.3f) ctrl-level %.3f N=%d\n", c4$coef, c4$se, c4$ctrl, c4$n))

# ---------------------------------------------------------------- Table 7
dcdata <- function(pp, S) {
  q <- pp[pp$id %in% S$id, ]
  w <- q %>% select(id, R, t, frame, r) %>% pivot_wider(names_from = frame, values_from = r)
  w$d <- -abs(w$c - w$s)
  w$cond <- S$cond[match(w$id, S$id)]
  w
}
wa <- dcdata(pa$p, SA); wb <- dcdata(pb$p, SB)
for (cn in c("Control", "Treatment", "Substance", "Rhetoric")) wa[[paste0("I_", cn)]] <- as.integer(wa$cond == cn)
for (cn in c("Control", "Treatment")) wb[[paste0("I_", cn)]] <- as.integer(wb$cond == cn)
m7a <- feols(d ~ 0 + I_Control + I_Treatment + I_Substance + I_Rhetoric, data = wa, cluster = ~id)
m7b <- feols(d ~ 0 + I_Control + I_Treatment, data = wb, cluster = ~id)
print(summary(m7a)); print(summary(m7b))

cat(sprintf("RESULT:test_score_compounding_treatment_minus_control_expA_table4_col1=%.4f\n", c1$coef))
cat(sprintf("RESULT:test_score_compounding_treatment_minus_control_expB_table4_col2=%.4f\n", c2$coef))
cat(sprintf("RESULT:test_score_control_module_treatment_minus_control_expA_table4_col3=%.4f\n", c3$coef))
cat(sprintf("RESULT:test_score_control_module_treatment_minus_control_expB_table4_col4=%.4f\n", c4$coef))
cat(sprintf("RESULT:n_obs_table4_expA_cols1_3=%d\n", c1$n))
cat(sprintf("RESULT:n_obs_table4_expB_cols2_4=%d\n", c2$n))
cat(sprintf("RESULT:deliberative_competence_control_expA_table7_col1=%.4f\n", coef(m7a)["I_Control"]))
cat(sprintf("RESULT:deliberative_competence_treatment_expA_table7_col1=%.4f\n", coef(m7a)["I_Treatment"]))
cat(sprintf("RESULT:deliberative_competence_substance_only_expA_table7_col1=%.4f\n", coef(m7a)["I_Substance"]))
cat(sprintf("RESULT:deliberative_competence_rhetoric_only_expA_table7_col1=%.4f\n", coef(m7a)["I_Rhetoric"]))
cat(sprintf("RESULT:deliberative_competence_control_expB_table7_col2=%.4f\n", coef(m7b)["I_Control"]))
cat(sprintf("RESULT:deliberative_competence_treatment_expB_table7_col2=%.4f\n", coef(m7b)["I_Treatment"]))
cat(sprintf("RESULT:n_obs_table7_expA_col1=%d\n", nobs(m7a)))
cat("DEVIATION: multiple switching operationalised as any non-monotone choice pattern (a later line returning to the immediate option) within either list of any of the 20 tasks; this flags 53 of 504 (A) and 54 of 401 (B) subjects vs. 49 and 53 reported, so samples are 451 (A) and 347 (B) instead of 455 and 348.\n")
