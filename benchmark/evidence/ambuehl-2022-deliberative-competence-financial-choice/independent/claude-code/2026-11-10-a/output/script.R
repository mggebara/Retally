## Ambuehl, Bernheim & Lusardi (2022), "Evaluating Deliberative Competence"
## Independent reproduction (R) of Table 4 (cols 1-4) and Table 7 (cols 1-2) from the raw Qualtrics exports.
##
## Construction (reconstructed from the paper text only):
##  * Completed subjects: answered the exam-style test and all 20 x 2 price lists.
##    Exp A: 504 subjects. Exp B: 402 rows, minus one Qualtrics "survey preview" row (Status == 1) = 401.
##  * Conditions. Exp A: batches 1,2,4,5 = Treatment ("code treat" video) / Control (Q130 video);
##    batches 3,6,7,8 = Substance-Only ("code treat" video) / Rhetoric-Only (Q130 video).
##    Exp B: variable `treatment` (1 = Treatment with practice/feedback, 0 = diversification Control).
##  * Price lists: list 1 offers $20,$18,...,$0 now vs the future reward (0 = immediate, 1 = future);
##    list 2 offers x+1.8,...,x (step 0.2), x+2 = smallest immediate amount chosen in list 1.
##    Valuation = midpoint of the $0.20 interval: v = 2*s - 0.2*n2 - 0.1, s = # future choices in list 1,
##    n2 = # immediate choices in list 2.
##  * Multiple switchers (excluded): any non-monotone choice in any of the 40 lists, i.e. choosing the
##    future reward at a higher immediate amount and the immediate amount at a lower one
##    ("we focus attention on the subjects who respected monotonicity").
##  * Tasks: T1-T10 simply framed (R = 20,18,16,14,12 at 72 days, then at 36 days);
##    T11-T20 complexly framed (R from Table 2 by the rule of 72), paired by (R, delay).
##  * Deliberative competence d = -100 * |v_c - v_s| / R; one obs per subject x task pair.
##  * Test scores: 5 compound-interest questions (test1-test5) and 5 control-module questions (test6-test10);
##    answer keys derived from the question texts in the paper/data.
suppressPackageStartupMessages({ library(fixest) })
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-a/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"

## ---------------- Experiment A (legacy Qualtrics export: one description row) ----------------
A <- list()
for (b in 1:8) {
  x <- read.csv(file.path(D, sprintf("expAbatch%d.csv", b)), check.names = FALSE,
                stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM", colClasses = "character")
  x <- x[-1, ]
  x <- x[, names(x) != "" & !duplicated(names(x)) & names(x) != "excluded"]
  x$batch <- b
  A[[b]] <- x
}
common <- Reduce(intersect, lapply(A, names))
a <- do.call(rbind, lapply(A, function(x) x[, common]))
getA <- function(k, l, j) paste0("iMPL", k, "_", l, "_", j, ": 1")
im <- grep("^iMPL", names(a), value = TRUE)
a <- a[a$test1 != "" & rowSums(a[, im] != "") == length(im), ]
a$cond <- ifelse(a$batch %in% c(1, 2, 4, 5),
                 ifelse(a[["code treat"]] != "", "Treatment", ifelse(a$Q130 != "", "Control", NA)),
                 ifelse(a[["code treat"]] != "", "SubstanceOnly", ifelse(a$Q130 != "", "RhetoricOnly", NA)))
a$sid <- paste0("A", seq_len(nrow(a)))

## ---------------- Experiment B (new Qualtrics export: two description rows) ----------------
B <- list()
for (b in 1:2) {
  x <- read.csv(file.path(D, sprintf("expBbatch%d.csv", b)), check.names = FALSE,
                stringsAsFactors = FALSE, colClasses = "character")
  x <- x[-(1:2), ]
  x <- x[, names(x) != "" & !duplicated(names(x))]
  x$batch <- b
  B[[b]] <- x
}
bb <- rbind(B[[1]], B[[2]][, names(B[[1]])])
getB <- function(k, l, j) paste0("iMPL", k, "-", l, "#1_iMPL", k, "-", l, "_", j)
imb <- grep("^iMPL", names(bb), value = TRUE)
bb <- bb[bb$test1 != "" & rowSums(bb[, imb] != "") == length(imb) & bb$Status != "1", ]
bb$cond <- ifelse(bb$treatment == "1", "Treatment", "Control")
bb$sid <- paste0("B", seq_len(nrow(bb)))
cat("Completed subjects: Exp A", nrow(a), " Exp B", nrow(bb), "\n")

## ---------------- valuations and monotonicity ----------------
tasks <- data.frame(k = 1:20, frame = rep(c("s", "c"), each = 10),
  R = c(20, 18, 16, 14, 12, 20, 18, 16, 14, 12, 20, 20, 18, 18, 16, 16, 14, 14, 12, 12),
  t = c(rep(72, 5), rep(36, 5), 36, 72, 36, 72, 36, 72, 36, 72, 36, 72))
process <- function(df, get) {
  n <- nrow(df); V <- matrix(NA_real_, n, 20); bad <- matrix(FALSE, n, 20)
  rev <- function(m) rowSums(m[, -ncol(m), drop = FALSE] == 1 & m[, -1, drop = FALSE] == 0) > 0
  for (k in 1:20) {
    l1 <- sapply(1:11, function(j) as.integer(df[[get(k, 1, j)]]))   # $20 ... $0
    l2 <- sapply(3:12, function(j) as.integer(df[[get(k, 2, j)]]))   # x+1.8 ... x
    bad[, k] <- rev(l1) | rev(l2)
    V[, k] <- 2 * rowSums(l1 == 1) - 0.2 * rowSums(l2 == 0) - 0.1
  }
  list(V = V, ms = rowSums(bad) > 0)
}
pa <- process(a, getA); pb <- process(bb, getB)
cat("Multiple switchers: Exp A", sum(pa$ms), "of", nrow(a), "; Exp B", sum(pb$ms), "of", nrow(bb), "\n")
ka <- !pa$ms; kb <- !pb$ms
print(table(a$cond[ka])); print(table(bb$cond[kb]))

## ---------------- Table 4: test scores ----------------
scoreA <- function(x) data.frame(
  comp = (x$test1 == "2") + (x$test2 == "4") + (x$test3 == "4") + (x$test4 == "7") + (x$test5 == "6"),
  ctrl = (x$test6 == "3") + (x$test7 == "4") + (x$test8 == "2") + (x$test9 == "3") + (x$test10 == "3"))
scoreB <- function(x) data.frame(
  comp = (x$test1 == "2") + (x$test2 == "4") + (x$test3 == "4") + (x$test4 == "7") + (x$test5 == "6"),
  ctrl = (x$test6 == "4") + (x$test7 == "5") + (x$test8 == "5") + (x$test9 == "5") + (x$test10 == "1"))
ta <- cbind(a[ka, c("sid", "cond")], scoreA(a[ka, ])); ta <- ta[ta$cond %in% c("Control", "Treatment"), ]
tb <- cbind(bb[kb, c("sid", "cond")], scoreB(bb[kb, ]))
ta$treat <- as.integer(ta$cond == "Treatment"); tb$treat <- as.integer(tb$cond == "Treatment")
t4 <- list(c1 = feols(comp ~ treat, ta), c2 = feols(comp ~ treat, tb),
           c3 = feols(ctrl ~ treat, ta), c4 = feols(ctrl ~ treat, tb))
cat("\nTable 4 (iid SEs)\n")
for (nm in names(t4)) {
  m <- t4[[nm]]; ct <- coeftable(m)
  cat(sprintf("%s: Control %.3f (%.3f)  Difference %.3f (%.3f)  Treatment level %.3f  N=%d\n", nm,
      ct[1, 1], ct[1, 2], ct[2, 1], ct[2, 2], sum(coef(m)), nobs(m)))
}

## ---------------- Table 7: deliberative competence ----------------
mkpairs <- function(df, p, keep) {
  out <- list()
  for (R in c(20, 18, 16, 14, 12)) for (t in c(36, 72)) {
    ks <- tasks$k[tasks$frame == "s" & tasks$R == R & tasks$t == t]
    kc <- tasks$k[tasks$frame == "c" & tasks$R == R & tasks$t == t]
    out[[length(out) + 1]] <- data.frame(sid = df$sid[keep], cond = df$cond[keep], R = R, t = t,
      vs = p$V[keep, ks], vc = p$V[keep, kc])
  }
  o <- do.call(rbind, out)
  o$dc <- -100 * abs(o$vc - o$vs) / o$R
  o
}
da <- mkpairs(a, pa, ka); db <- mkpairs(bb, pb, kb)
da$cond <- factor(da$cond, levels = c("Control", "Treatment", "SubstanceOnly", "RhetoricOnly"))
db$cond <- factor(db$cond, levels = c("Control", "Treatment"))
m7a <- feols(dc ~ 0 + cond, da, cluster = ~sid)
m7b <- feols(dc ~ 0 + cond, db, cluster = ~sid)
cat("\nTable 7 col 1 (Exp A, both delays), SEs clustered by subject\n"); print(coeftable(m7a))
cat("N obs", nobs(m7a), " subjects", length(unique(da$sid)), "\n")
cat("\nTable 7 col 2 (Exp B, both delays)\n"); print(coeftable(m7b))
cat("N obs", nobs(m7b), " subjects", length(unique(db$sid)), "\n")
# p-values of differences to Control
ma <- feols(dc ~ i(cond, ref = "Control"), da, cluster = ~sid); print(coeftable(ma))
mb <- feols(dc ~ i(cond, ref = "Control"), db, cluster = ~sid); print(coeftable(mb))

## ---------------- results ----------------
cA <- coef(m7a); cB <- coef(m7b)
res <- c(
  test_score_compounding_treatment_minus_control_expA_table4_col1 = unname(coef(t4$c1)["treat"]),
  test_score_compounding_treatment_minus_control_expB_table4_col2 = unname(coef(t4$c2)["treat"]),
  test_score_control_module_treatment_minus_control_expA_table4_col3 = unname(coef(t4$c3)["treat"]),
  test_score_control_module_treatment_minus_control_expB_table4_col4 = unname(coef(t4$c4)["treat"]),
  n_obs_table4_expA_cols1_3 = nobs(t4$c1),
  n_obs_table4_expB_cols2_4 = nobs(t4$c2),
  deliberative_competence_control_expA_table7_col1 = unname(cA["condControl"]),
  deliberative_competence_treatment_expA_table7_col1 = unname(cA["condTreatment"]),
  deliberative_competence_substance_only_expA_table7_col1 = unname(cA["condSubstanceOnly"]),
  deliberative_competence_rhetoric_only_expA_table7_col1 = unname(cA["condRhetoricOnly"]),
  deliberative_competence_control_expB_table7_col2 = unname(cB["condControl"]),
  deliberative_competence_treatment_expB_table7_col2 = unname(cB["condTreatment"]),
  n_obs_table7_expA_col1 = nobs(m7a))
cat("\n")
for (nm in names(res)) cat(sprintf("RESULT:%s=%.6f\n", nm, res[[nm]]))
