# Ambuehl, Bernheim & Lusardi (2022) - independent blind reproduction of Table 4 and Table 7 (col 1-2)
# Built from raw Qualtrics exports only.
set.seed(42)
suppressPackageStartupMessages({library(readr); library(dplyr); library(fixest)})
base <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-c/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) suppressWarnings(suppressMessages(read_csv(f, col_types = cols(.default = "c"), progress = FALSE, name_repair = "minimal")))

# ---------------- Load Experiment A (legacy Qualtrics export: 1 label row) ----------------
A <- list()
for (b in 1:8) {
  d <- rd(file.path(base, sprintf("expAbatch%d.csv", b)))
  names(d)[1] <- "V1"
  d <- d[-1, ]; d$batch <- b
  A[[b]] <- d[, c("V1", "treatment", "amt_id", "batch", paste0("test", 1:10), grep("^iMPL", names(d), value = TRUE))]
}
A <- bind_rows(A)
# Arms: batches 1,2,4,5 randomize full Treatment (treatment=1; compound-interest video, attention word "compounding")
# vs Control (treatment=0; index-fund video, attention word "funds").  Batches 3,6,7 randomize two compound-interest
# videos: treatment=1 subjects overwhelmingly report knowing the rule of 72 -> Substance-Only; treatment=0 -> Rhetoric-Only
# (no rule of 72).  Batch 8 only uses the Rhetoric-Only video slot.
A$arm <- with(A, ifelse(batch %in% c(1, 2, 4, 5), ifelse(treatment == "1", "Treatment", "Control"),
                 ifelse(batch == 8, "RhetoricOnly", ifelse(treatment == "1", "SubstanceOnly", "RhetoricOnly"))))
A$id <- A$V1

# ---------------- Load Experiment B (new Qualtrics export: 2 label rows) ----------------
B <- list()
for (b in 1:2) {
  d <- rd(file.path(base, sprintf("expBbatch%d.csv", b)))
  d <- d[-(1:2), ]; d$batch <- b
  B[[b]] <- d[, c("ResponseId", "DistributionChannel", "treatment", "amt_id", "batch", paste0("test", 1:10), grep("^iMPL", names(d), value = TRUE))]
}
B <- bind_rows(B) %>% filter(is.na(DistributionChannel) | DistributionChannel != "preview")
B$arm <- ifelse(B$treatment == "1", "Treatment", "Control")
B$id <- B$ResponseId

# completed the study = reached and answered the final exam-style test
A <- A[rowSums(!is.na(A[, paste0("test", 1:10)])) > 0, ]
B <- B[rowSums(!is.na(B[, paste0("test", 1:10)])) > 0, ]
cat("Completed: A", nrow(A), " B", nrow(B), "\n")

l1 <- function(exp, k, j) if (exp == "A") sprintf("iMPL%d_1_%d: 1", k, j) else sprintf("iMPL%d-1#1_iMPL%d-1_%d", k, k, j)
l2 <- function(exp, k, j) if (exp == "A") sprintf("iMPL%d_2_%d: 1", k, j) else sprintf("iMPL%d-2#1_iMPL%d-2_%d", k, k, j)
mat <- function(d, cols) { m <- sapply(d[, cols], as.numeric); if (is.null(dim(m))) m <- matrix(m, nrow = 1); m }

# Price lists: 0 = immediate amount (left), 1 = future reward (right).
# List 1 lines 1..11: immediate $20,$18,...,$0.  List 2 lines 3..12: x+1.8,...,x+0, x = 2*(#future choices in list 1) - 2.
# Valuation = midpoint of the indifference interval = x + 0.2*(#future choices in list 2) - 0.1.
# Multiple switching: any list with two or more switches, or any switch from right (future) to left (immediate).
proc <- function(d, exp) {
  n <- nrow(d); ms <- rep(FALSE, n); vals <- matrix(NA_real_, n, 20)
  for (k in 1:20) {
    m1 <- mat(d, l1(exp, k, 1:11)); m2 <- mat(d, l2(exp, k, 3:12))
    c1 <- rowSums(m1[, -1] != m1[, -11]); c2 <- rowSums(m2[, -1] != m2[, -10])
    r1 <- rowSums(m1[, -11] > m1[, -1]) > 0; r2 <- rowSums(m2[, -10] > m2[, -1]) > 0
    ms <- ms | c1 >= 2 | c2 >= 2 | r1 | r2
    vals[, k] <- 2 * rowSums(m1) - 2 + 0.2 * rowSums(m2) - 0.1
  }
  list(ms = ms, vals = vals)
}
pA <- proc(A, "A"); pB <- proc(B, "B")
cat("Multiple switchers: A", sum(pA$ms), "of", nrow(A), "; B", sum(pB$ms), "of", nrow(B), "\n")

# ---------------- Test scores ----------------
# Compound interest (test1-5): 7.2 yrs (2); 18% (4, rule of 72); about 20 yrs (4); by 36% (7); $250 (6).
# Control module A (test6-10): Franklin "Money makes money..." (3); 90% (4); Sinclair "difficult to get a man..." (2);
#   50-70% (3); market portfolio (3).  (This key reproduces Qualtrics' own Score-sum for all 504 A subjects.)
# Control module B (test6-10): GM & Microsoft (4); 0.7 (5); stocks (5); stocks (5); 1 (1).
score <- function(d, key) sapply(1:5, function(q) as.numeric(!is.na(d[[paste0("test", q)]]) & d[[paste0("test", q)]] == as.character(key[q])))
kA <- c(2, 4, 4, 7, 6, 3, 4, 2, 3, 3); kB <- c(2, 4, 4, 7, 6, 4, 5, 5, 5, 1)
sc <- function(d, key) {
  ok <- sapply(1:10, function(q) as.numeric(!is.na(d[[paste0("test", q)]]) & d[[paste0("test", q)]] == as.character(key[q])))
  data.frame(comp = rowSums(ok[, 1:5]), ctrl = rowSums(ok[, 6:10]))
}
A <- bind_cols(A[, c("id", "arm", "batch")], sc(A, kA)); A$ms <- pA$ms
B <- bind_cols(B[, c("id", "arm", "batch")], sc(B, kB)); B$ms <- pB$ms
A$id <- make.unique(A$id); B$id <- make.unique(B$id)
cat("A arms (non-switchers):\n"); print(table(A$arm[!A$ms])); cat("B arms (non-switchers):\n"); print(table(B$arm[!B$ms]))

# ---------------- Table 4 ----------------
A4 <- A %>% filter(!ms, arm %in% c("Treatment", "Control")) %>% mutate(treat = as.numeric(arm == "Treatment"))
B4 <- B %>% filter(!ms) %>% mutate(treat = as.numeric(arm == "Treatment"))
t4 <- list(
  c1 = feols(comp ~ treat, data = A4, cluster = ~id),
  c2 = feols(comp ~ treat, data = B4, cluster = ~id),
  c3 = feols(ctrl ~ treat, data = A4, cluster = ~id),
  c4 = feols(ctrl ~ treat, data = B4, cluster = ~id))
for (nm in names(t4)) cat("Table4", nm, ": const", round(coef(t4[[nm]])[1], 3), " diff", round(coef(t4[[nm]])[2], 3), " se", round(se(t4[[nm]])[2], 3), " N", nobs(t4[[nm]]), "\n")

# ---------------- Table 7 ----------------
R <- rep(c(20, 18, 16, 14, 12), 2); delay <- rep(c(72, 36), each = 5)
cpx <- c(12, 14, 16, 18, 20, 11, 13, 15, 17, 19)  # complex list paired with simple list k = 1..10
dcomp <- function(d, p) {
  out <- list()
  for (k in 1:10) {
    rs <- p$vals[, k] / R[k] * 100; rc <- p$vals[, cpx[k]] / R[k] * 100
    out[[k]] <- data.frame(id = d$id, arm = d$arm, ms = d$ms, R = R[k], delay = delay[k], dc = -abs(rc - rs))
  }
  bind_rows(out) %>% filter(!ms)
}
DA <- dcomp(A, pA); DB <- dcomp(B, pB)
m7A <- feols(dc ~ 0 + i(arm), data = DA, cluster = ~id)
m7B <- feols(dc ~ 0 + i(arm), data = DB, cluster = ~id)
print(coeftable(m7A)); print(coeftable(m7B))
cat("Table7 N: A", nobs(m7A), " B", nobs(m7B), "\n")
cA <- coef(m7A); cB <- coef(m7B)

cat(sprintf("RESULT:test_score_compounding_treatment_minus_control_expA_table4_col1=%.6f\n", coef(t4$c1)["treat"]))
cat(sprintf("RESULT:test_score_compounding_treatment_minus_control_expB_table4_col2=%.6f\n", coef(t4$c2)["treat"]))
cat(sprintf("RESULT:test_score_control_module_treatment_minus_control_expA_table4_col3=%.6f\n", coef(t4$c3)["treat"]))
cat(sprintf("RESULT:test_score_control_module_treatment_minus_control_expB_table4_col4=%.6f\n", coef(t4$c4)["treat"]))
cat(sprintf("RESULT:n_obs_table4_expA_cols1_3=%d\n", nobs(t4$c1)))
cat(sprintf("RESULT:n_obs_table4_expB_cols2_4=%d\n", nobs(t4$c2)))
cat(sprintf("RESULT:deliberative_competence_control_expA_table7_col1=%.6f\n", cA["arm::Control"]))
cat(sprintf("RESULT:deliberative_competence_treatment_expA_table7_col1=%.6f\n", cA["arm::Treatment"]))
cat(sprintf("RESULT:deliberative_competence_substance_only_expA_table7_col1=%.6f\n", cA["arm::SubstanceOnly"]))
cat(sprintf("RESULT:deliberative_competence_rhetoric_only_expA_table7_col1=%.6f\n", cA["arm::RhetoricOnly"]))
cat(sprintf("RESULT:deliberative_competence_control_expB_table7_col2=%.6f\n", cB["arm::Control"]))
cat(sprintf("RESULT:deliberative_competence_treatment_expB_table7_col2=%.6f\n", cB["arm::Treatment"]))
cat(sprintf("RESULT:n_obs_table7_expA_col1=%d\n", nobs(m7A)))
