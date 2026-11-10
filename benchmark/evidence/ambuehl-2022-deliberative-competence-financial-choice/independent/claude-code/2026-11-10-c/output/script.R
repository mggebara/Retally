# Independent reproduction: Ambuehl, Bernheim & Lusardi (2022),
# "Evaluating Deliberative Competence: A Simple Method with an Application to Financial Choice"
# Table 4 (exam-style test scores) and Table 7 col. 1-2 (deliberative competence), built from raw Qualtrics CSVs.
suppressMessages({library(readr); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-c/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) suppressMessages(read_csv(file.path(D, f), col_types = cols(.default = "c"), name_repair = "minimal", progress = FALSE))

# ---------------- Load Experiment A (8 sessions; row 1 after header = question text) ----------------
A <- bind_rows(lapply(1:8, function(i) {
  x <- rd(sprintf("expAbatch%d.csv", i)); names(x)[1] <- "V1"
  x <- x[-1, !duplicated(names(x)) & names(x) != ""]; x$batch <- i; x }))
A <- A[!is.na(A$test1), ]                      # completed the study (reached and answered the final test): 504
# Conditions: sessions 1,2,4,5 ran Treatment (full video) vs Control (index funds video);
# sessions 3,6,7,8 ran the two modified compound-interest videos. The video whose first slide reads
# "interest" (treatment==1 in those sessions) produces high Q1 scores (the rule-of-72 answer is in the
# substantive material) -> Substance-Only; the other ("compounding" title, treatment==0) -> Rhetoric-Only.
A$arm <- ifelse(A$batch %in% c(1, 2, 4, 5), ifelse(A$treatment == "1", "Treatment", "Control"),
                ifelse(A$treatment == "1", "SubstanceOnly", "RhetoricOnly"))
A$sid <- paste0("A", seq_len(nrow(A)))

# ---------------- Load Experiment B (2 sessions; rows 1-2 after header = question text / import ids) ----------------
B <- bind_rows(lapply(1:2, function(i) { x <- rd(sprintf("expBbatch%d.csv", i)); x <- x[-(1:2), ]; x$batch <- i; x }))
B <- B[!is.na(B$test1) & B$DistributionChannel != "preview", ]   # 401 completers
names(B) <- sub("^iMPL(\\d+)-(\\d)#1_iMPL\\d+-\\d_(\\d+)$", "iMPL\\1_\\2_\\3: 1", names(B))
B$arm <- ifelse(B$treatment == "1", "Treatment", "Control")
B$sid <- paste0("B", seq_len(nrow(B)))

# ---------------- Price lists ----------------
# First list (lines 1..11): immediate $20,$18,...,$0 vs future reward; coded 0 = immediate (left), 1 = future (right).
# Second list (items 3..12): immediate x+1.8, x+1.6, ..., x, with x = 2*switch - 2 (switch = # future choices in list 1),
# i.e. x+2 = smallest amount chosen over the future reward in list 1 (paper App. C; confirmed by the piped labels).
nsw <- function(z) sum(diff(z) != 0)
mpl <- function(df) {
  out <- vector("list", 20)
  flags <- matrix(FALSE, nrow(df), 4, dimnames = list(NULL, c("sw2", "frev_mid", "frev_bot", "srev")))
  for (r in 1:20) {
    f <- sapply(1:11, function(k) as.integer(df[[sprintf("iMPL%d_1_%d: 1", r, k)]]))
    s <- sapply(3:12, function(k) as.integer(df[[sprintf("iMPL%d_2_%d: 1", r, k)]]))
    n1 <- rowSums(f); n1s <- rowSums(s)
    x <- 2 * n1 - 2
    val <- x - 0.1 + 0.2 * n1s           # midpoint of the interval implied by the second list
    out[[r]] <- data.frame(sid = df$sid, round = r, val = val)
    for (i in seq_len(nrow(df))) {
      fi <- f[i, ]; si <- s[i, ]
      flags[i, "sw2"] <- flags[i, "sw2"] | nsw(fi) >= 2 | nsw(si) >= 2
      rp <- which(diff(fi) < 0)            # 1 -> 0 reversal (right before left) in list 1
      if (nsw(fi) == 1 && length(rp)) {
        flags[i, "frev_mid"] <- flags[i, "frev_mid"] | any(!(rp %in% c(1, 10)))
        flags[i, "frev_bot"] <- flags[i, "frev_bot"] | any(rp == 10)
      }
      if (any(diff(si) < 0)) flags[i, "srev"] <- TRUE
    }
  }
  list(val = bind_rows(out), flags = as.data.frame(flags))
}
mA <- mpl(A); mB <- mpl(B)
# Multiple switching ("did not respect monotonicity"): >= 2 switches in a list, or switching the wrong way.
# Single wrong-way switches confined to the top line of list 1 are not counted; in Experiment A neither are those
# confined to the bottom ($0) line. This reproduces the paper's counts: 49 of 504 (A) and 53 of 401 (B).
A$multi <- with(mA$flags, sw2 | frev_mid | srev)
B$multi <- with(mB$flags, sw2 | frev_mid | frev_bot | srev)
cat("Exp A multiple switchers:", sum(A$multi), "of", nrow(A), "\n")
cat("Exp B multiple switchers:", sum(B$multi), "of", nrow(B), "\n")
Ak <- A[!A$multi, ]; Bk <- B[!B$multi, ]
cat("Exp A kept by arm:\n"); print(table(Ak$arm)); cat("Exp B kept by arm:\n"); print(table(Bk$arm))

# ---------------- Test scores ----------------
# Compound interest (data test1..test5): Q1 7.2 yrs (code 2), Q2 18% (4), Q3 about 20 yrs (4),
# growth at 8% for 4 yrs = 36% (7), Paul's investment $250 (6).
comp_key <- c(test1 = "2", test2 = "4", test3 = "4", test4 = "7", test5 = "6")
# Control module A (index funds): Franklin "Money makes money..." (3), professional investors 90% (4),
# Sinclair "It is difficult to get a man..." (2), funds outperformed 50-70% (3), indexing = market portfolio (3).
ctrlA_key <- c(test6 = "3", test7 = "4", test8 = "2", test9 = "3", test10 = "3")
# Control module B (diversification): GM & Microsoft (4), Coke-Pepsi relation 0.7 (5), stocks (5), stocks (5), 1 (1).
ctrlB_key <- c(test6 = "4", test7 = "5", test8 = "5", test9 = "5", test10 = "1")
score <- function(df, key) rowSums(sapply(names(key), function(q) !is.na(df[[q]]) & df[[q]] == key[[q]]))
Ak$comp <- score(Ak, comp_key); Ak$ctrl <- score(Ak, ctrlA_key)
Bk$comp <- score(Bk, comp_key); Bk$ctrl <- score(Bk, ctrlB_key)

A4 <- Ak[Ak$arm %in% c("Treatment", "Control"), ]; A4$treat <- as.integer(A4$arm == "Treatment")
Bk$treat <- as.integer(Bk$arm == "Treatment")
t4c1 <- feols(comp ~ treat, data = A4, vcov = "iid")
t4c2 <- feols(comp ~ treat, data = Bk, vcov = "iid")
t4c3 <- feols(ctrl ~ treat, data = A4, vcov = "iid")
t4c4 <- feols(ctrl ~ treat, data = Bk, vcov = "iid")
cat("\nTable 4 levels (Control / Treatment means):\n")
print(rbind(c1 = tapply(A4$comp, A4$arm, mean), c2 = tapply(Bk$comp, Bk$arm, mean),
            c3 = tapply(A4$ctrl, A4$arm, mean), c4 = tapply(Bk$ctrl, Bk$arm, mean)))
etable(t4c1, t4c2, t4c3, t4c4)

# ---------------- Deliberative competence ----------------
# Rounds 1-5: simple, $20..$12 in 72 days; rounds 6-10: simple, $20..$12 in 36 days;
# rounds 11-20: complex framing of the same rewards (Table 2).
pairs <- data.frame(
  s_round = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
  c_round = c(12, 14, 16, 18, 20, 11, 13, 15, 17, 19),
  R       = c(20, 18, 16, 14, 12, 20, 18, 16, 14, 12),
  delay   = c(72, 72, 72, 72, 72, 36, 36, 36, 36, 36))
mkdc <- function(val, kept) {
  v <- val[val$sid %in% kept$sid, ]
  s <- merge(pairs, v, by.x = "s_round", by.y = "round"); names(s)[names(s) == "val"] <- "vs"
  c <- v; names(c)[names(c) == "val"] <- "vc"
  d <- merge(s, c, by.x = c("sid", "c_round"), by.y = c("sid", "round"))
  d$rs <- 100 * d$vs / d$R; d$rc <- 100 * d$vc / d$R
  d$dc <- -abs(d$rc - d$rs)
  merge(d, kept[, c("sid", "arm")], by = "sid")
}
dA <- mkdc(mA$val, Ak); dB <- mkdc(mB$val, Bk)
for (a in c("Control", "Treatment", "SubstanceOnly", "RhetoricOnly")) dA[[a]] <- as.integer(dA$arm == a)
for (a in c("Control", "Treatment")) dB[[a]] <- as.integer(dB$arm == a)
t7c1 <- feols(dc ~ 0 + Control + Treatment + SubstanceOnly + RhetoricOnly, data = dA, cluster = ~sid)
t7c2 <- feols(dc ~ 0 + Control + Treatment, data = dB, cluster = ~sid)
cat("\nTable 7 columns 1-2:\n"); etable(t7c1, t7c2)
cat("Complex-frame valuation means (Table 5 style) A:", round(tapply(dA$rc, dA$arm, mean), 3), "\n")

# ---------------- Results ----------------
out <- c(
  test_score_compounding_treatment_minus_control_expA_table4_col1 = unname(coef(t4c1)["treat"]),
  test_score_compounding_treatment_minus_control_expB_table4_col2 = unname(coef(t4c2)["treat"]),
  test_score_control_module_treatment_minus_control_expA_table4_col3 = unname(coef(t4c3)["treat"]),
  test_score_control_module_treatment_minus_control_expB_table4_col4 = unname(coef(t4c4)["treat"]),
  n_obs_table4_expA_cols1_3 = nobs(t4c1),
  n_obs_table4_expB_cols2_4 = nobs(t4c2),
  deliberative_competence_control_expA_table7_col1 = unname(coef(t7c1)["Control"]),
  deliberative_competence_treatment_expA_table7_col1 = unname(coef(t7c1)["Treatment"]),
  deliberative_competence_substance_only_expA_table7_col1 = unname(coef(t7c1)["SubstanceOnly"]),
  deliberative_competence_rhetoric_only_expA_table7_col1 = unname(coef(t7c1)["RhetoricOnly"]),
  deliberative_competence_control_expB_table7_col2 = unname(coef(t7c2)["Control"]),
  deliberative_competence_treatment_expB_table7_col2 = unname(coef(t7c2)["Treatment"]),
  n_obs_table7_expA_col1 = nobs(t7c1))
cat("\n")
for (k in names(out)) cat(sprintf("RESULT:%s=%.6f\n", k, out[[k]]))
