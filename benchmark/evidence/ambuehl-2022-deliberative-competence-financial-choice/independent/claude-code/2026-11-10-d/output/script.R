# Independent reproduction: Ambuehl, Bernheim & Lusardi (2022), "Evaluating Deliberative Competence"
# Table 4 (exam-style test scores) and Table 7 col. 1-2 (deliberative competence levels).
set.seed(42)
suppressMessages({library(readr); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-d/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) suppressMessages(read_csv(file.path(D, f), col_types=cols(.default="c"), show_col_types=FALSE, name_repair="unique"))

## ---------------- load raw Qualtrics exports ----------------
# Experiment A: 8 sessions (old Qualtrics format, row 1 = question text)
A <- list()
for (i in 1:8) { x <- rd(sprintf("expAbatch%d.csv", i)); x <- x[-1, ]; x$batch <- i; A[[i]] <- x }
cn <- Reduce(intersect, lapply(A, names))
a <- bind_rows(lapply(A, function(x) x[, cn]))
a <- a[!is.na(a$test1), ]                       # completed the study (reached the final test): 504
# Experiment B: 2 sessions (new Qualtrics format, rows 1-2 = question text / import ids)
B1 <- rd("expBbatch1.csv"); B2 <- rd("expBbatch2.csv")
b <- bind_rows(B1[-(1:2), ], B2[-(1:2), ])
b <- b[!is.na(b$test1) & b$DistributionChannel == "anonymous", ]   # completed; drops the author preview: 401
cat("Completed subjects: A =", nrow(a), " B =", nrow(b), "\n")

## ---------------- price lists ----------------
# Task k (1..20) = embedded field Tk (constant across subjects): 1-10 simply framed, 11-20 complexly framed.
# List 1 rows 1..11 = $20,$18,...,$0 ; list 2 rows 3..12 = x+1.8,...,x+0 with x = 2*s-2, s = # of rows choosing
# the future reward in list 1 (Qualtrics field switchk).  Coding: 0 = immediate amount (left), 1 = future reward (right).
colA <- function(k, l, r) sprintf("iMPL%d_%d_%d: 1", k, l, r)
colB <- function(k, l, r) sprintf("iMPL%d-%d#1_iMPL%d-%d_%d", k, l, k, l, r)
getmat <- function(df, cf, k, l) { rr <- if (l == 1) 1:11 else 3:12; m <- sapply(rr, function(r) as.numeric(df[[cf(k, l, r)]])); if (!is.matrix(m)) m <- matrix(m, nrow=1); m }
nonmono <- function(m) rowSums(m[, -ncol(m), drop=FALSE] > m[, -1, drop=FALSE]) > 0   # a "future" choice followed by an "immediate" one
proc <- function(df, cf) {
  n <- nrow(df); nm1 <- nm2 <- matrix(FALSE, n, 20); val <- S <- matrix(NA, n, 20)
  for (k in 1:20) {
    m1 <- getmat(df, cf, k, 1); m2 <- getmat(df, cf, k, 2)
    nm1[, k] <- nonmono(m1); nm2[, k] <- nonmono(m2)
    s <- rowSums(m1); kk <- rowSums(m2); S[, k] <- s
    v <- 2 * s - 2.1 + 0.2 * kk          # midpoint of the $0.20 interval in list 2
    v[s == 0] <- 0                       # immediate $0 preferred to the reward: valuation 0
    val[, k] <- v
  }
  # multiple switching: more than one switch point in any list (list 2 not used when the whole first list chose the future reward)
  flag <- (rowSums(nm1) > 0) | (rowSums(nm2 & S != 11) > 0)
  list(val=val, flag=flag)
}

## ---------------- test scores ----------------
keyC <- c(test1="2", test2="4", test3="4", test4="7", test5="6")       # 7.2 yrs; 18%; 20 yrs; 36%; $250
keyA <- c(test6="3", test7="4", test8="2", test9="3", test10="3")      # index-fund module (Exp. A control)
keyB <- c(test6="4", test7="5", test8="5", test9="5", test10="1")      # diversification module (Exp. B control)
sc <- function(df, key) rowSums(sapply(names(key), function(q) !is.na(df[[q]]) & df[[q]] == key[[q]]))

pa <- proc(a, colA); pb <- proc(b, colB)
a$flag <- pa$flag; b$flag <- pb$flag
a$score_c <- sc(a, keyC); a$score_ctl <- sc(a, keyA)
b$score_c <- sc(b, keyC); b$score_ctl <- sc(b, keyB)
a$id <- paste0("A", seq_len(nrow(a))); b$id <- paste0("B", seq_len(nrow(b)))

# Experiment A conditions: sessions 1,2,4,5 ran Treatment(=1) vs Control(=0) (control video about index funds);
# sessions 3,6,7,8 ran the two compound-interest variants. The variant with the higher compounding test score is Substance-Only.
tc <- a$batch %in% c(1, 2, 4, 5)
a$grp <- ifelse(tc, ifelse(a$treatment == "1", "Treatment", "Control"), ifelse(a$treatment == "1", "V1", "V0"))
m1 <- mean(a$score_c[a$grp == "V1" & !a$flag]); m0 <- mean(a$score_c[a$grp == "V0" & !a$flag])
a$grp[a$grp == "V1"] <- if (m1 > m0) "SubstanceOnly" else "RhetoricOnly"
a$grp[a$grp == "V0"] <- if (m1 > m0) "RhetoricOnly" else "SubstanceOnly"
b$grp <- ifelse(b$treatment == "1", "Treatment", "Control")
cat("Multiple switchers: A =", sum(a$flag), " B =", sum(b$flag), "\n")
print(table(a$grp, a$flag)); print(table(b$grp, b$flag))

ak <- a[!a$flag, ]; bk <- b[!b$flag, ]
## ---------------- Table 4 ----------------
t4a <- ak[ak$grp %in% c("Treatment", "Control"), ]; t4a$treat <- as.numeric(t4a$grp == "Treatment")
bk$treat <- as.numeric(bk$grp == "Treatment")
r1 <- lm(score_c ~ treat, data=t4a); r2 <- lm(score_c ~ treat, data=bk)
r3 <- lm(score_ctl ~ treat, data=t4a); r4 <- lm(score_ctl ~ treat, data=bk)
cat("\nTable 4\n"); for (r in list(r1, r2, r3, r4)) print(round(summary(r)$coefficients, 3))

## ---------------- Table 7 ----------------
# pairs (complex task, simple task) with identical future reward R and delay t
cx <- data.frame(task=11:20, a=c(10,10,4.5,4.5,2,2,0.9,0.9,2,2), rate=c(.02,.01,.04,.02,.06,.03,.08,.04,.05,.025),
                 t=c(36,72,36,72,36,72,36,72,36,72), R=c(20,20,18,18,16,16,14,14,12,12), simple=c(6,1,7,2,8,3,9,4,10,5))
cx$exact <- cx$a * (1 + cx$rate)^cx$t     # exact daily-compounded payoff of the complexly framed investment
panel <- function(df, p) {
  out <- NULL
  for (j in 1:10) out <- rbind(out, data.frame(id=df$id, grp=df$grp, flag=df$flag, t=cx$t[j], R=cx$R[j],
                                               rs=100 * p$val[, cx$simple[j]] / cx$R[j],
                                               rc=100 * p$val[, cx$task[j]] / cx$exact[j]))
  out$d <- -abs(out$rc - out$rs)
  out[!out$flag, ]
}
da <- panel(a, pa); db <- panel(b, pb)
da$grp <- factor(da$grp, levels=c("Control", "Treatment", "SubstanceOnly", "RhetoricOnly"))
db$grp <- factor(db$grp, levels=c("Control", "Treatment"))
t7a <- feols(d ~ 0 + grp, data=da, cluster=~id)
t7b <- feols(d ~ 0 + grp, data=db, cluster=~id)
cat("\nTable 7\n"); print(coeftable(t7a)); print(coeftable(t7b))
cat("Mean normalized valuations (A):\n"); print(aggregate(cbind(rs, rc) ~ grp, data=da, FUN=mean))

## ---------------- results ----------------
ca <- coef(t7a); cb <- coef(t7b)
cat(sprintf("RESULT:test_score_compounding_treatment_minus_control_expA_table4_col1=%.4f\n", coef(r1)["treat"]))
cat(sprintf("RESULT:test_score_compounding_treatment_minus_control_expB_table4_col2=%.4f\n", coef(r2)["treat"]))
cat(sprintf("RESULT:test_score_control_module_treatment_minus_control_expA_table4_col3=%.4f\n", coef(r3)["treat"]))
cat(sprintf("RESULT:test_score_control_module_treatment_minus_control_expB_table4_col4=%.4f\n", coef(r4)["treat"]))
cat(sprintf("RESULT:n_obs_table4_expA_cols1_3=%d\n", nobs(r1)))
cat(sprintf("RESULT:n_obs_table4_expB_cols2_4=%d\n", nobs(r2)))
cat(sprintf("RESULT:deliberative_competence_control_expA_table7_col1=%.4f\n", ca["grpControl"]))
cat(sprintf("RESULT:deliberative_competence_treatment_expA_table7_col1=%.4f\n", ca["grpTreatment"]))
cat(sprintf("RESULT:deliberative_competence_substance_only_expA_table7_col1=%.4f\n", ca["grpSubstanceOnly"]))
cat(sprintf("RESULT:deliberative_competence_rhetoric_only_expA_table7_col1=%.4f\n", ca["grpRhetoricOnly"]))
cat(sprintf("RESULT:deliberative_competence_control_expB_table7_col2=%.4f\n", cb["grpControl"]))
cat(sprintf("RESULT:deliberative_competence_treatment_expB_table7_col2=%.4f\n", cb["grpTreatment"]))
cat(sprintf("RESULT:n_obs_table7_expA_col1=%d\n", nobs(t7a)))
