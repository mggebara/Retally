# ---- Data construction for Ambuehl, Bernheim & Lusardi (2022), Experiments A and B ----
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-a/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) {
  z <- read.csv(file.path(D, f), check.names = FALSE, colClasses = "character", encoding = "UTF-8", fileEncoding = "UTF-8-BOM")
  n <- names(z); n[is.na(n) | n == ""] <- "blank"; names(z) <- make.unique(n); z
}
num <- function(v) suppressWarnings(as.numeric(v))

# Standardise column names of the price lists: L1_k_j (j = 1..11, j=1 is $20 ... j=11 is $0),
# L2_k_j (j = 3..12; amount = x + 0.2*(12 - j), x = 2*s - 2)
stdA <- function(x) {
  for (k in 1:20) {
    for (j in 1:11) names(x)[names(x) == sprintf("iMPL%d_1_%d: 1", k, j)] <- sprintf("L1_%d_%d", k, j)
    for (j in 3:12) names(x)[names(x) == sprintf("iMPL%d_2_%d: 1", k, j)] <- sprintf("L2_%d_%d", k, j)
  }
  x
}
stdB <- function(x) {
  for (k in 1:20) {
    for (j in 1:11) names(x)[names(x) == sprintf("iMPL%d-1#1_iMPL%d-1_%d", k, k, j)] <- sprintf("L1_%d_%d", k, j)
    for (j in 3:12) names(x)[names(x) == sprintf("iMPL%d-2#1_iMPL%d-2_%d", k, k, j)] <- sprintf("L2_%d_%d", k, j)
  }
  x
}
keep <- c("id", "batch", "treatment", "finished", paste0("test", 1:10), "rule72", "rule72_inv", paste0("T", 1:20),
          as.vector(outer(1:20, 1:11, function(k, j) sprintf("L1_%d_%d", k, j))),
          as.vector(outer(1:20, 3:12, function(k, j) sprintf("L2_%d_%d", k, j))), "vidcheck_t", "vidcheck_c", "time_t", "time_c")
A <- do.call(rbind, lapply(1:8, function(i) {
  x <- stdA(rd(sprintf("expAbatch%d.csv", i))[-1, ])
  x$id <- x$amt_id; x$batch <- i; x$finished <- x$V10
  x$vidcheck_t <- tolower(trimws(x[["code treat"]])); x$vidcheck_c <- tolower(trimws(x$Q130))
  x$time_t <- x$TimeTreat_3; x$time_c <- x$TimeContro_3
  x[, keep]
}))
B <- do.call(rbind, lapply(1:2, function(i) {
  x <- stdB(rd(sprintf("expBbatch%d.csv", i))[-(1:2), ])
  x$id <- x$amt_id; x$batch <- i; x$finished <- x$Finished
  x$vidcheck_t <- NA; x$vidcheck_c <- NA; x$time_t <- x[["TimeTreat_Page Submit"]]; x$time_c <- NA
  x[, keep]
}))
A$exp <- "A"; B$exp <- "B"

# Valuations and multiple switching
L1c <- function(k) sprintf("L1_%d_%d", k, 1:11)
L2c <- function(k) sprintf("L2_%d_%d", k, 12:3)   # ordered from amount x (bottom) up to x+1.8 (top)
nchg <- function(m) rowSums(m[, -1, drop = FALSE] != m[, -ncol(m), drop = FALSE])
process <- function(d) {
  d$complete <- rowSums(sapply(paste0("test", 1:10), function(v) d[[v]] != "")) == 10 &
    rowSums(sapply(1:20, function(k) rowSums(sapply(c(L1c(k), L2c(k)), function(v) d[[v]] != "")) == 21)) == 20
  d <- d[d$complete, ]
  ms <- rep(0, nrow(d)); val <- matrix(NA_real_, nrow(d), 20); Rm <- tm <- frame <- matrix(NA, nrow(d), 20)
  for (k in 1:20) {
    m1 <- sapply(L1c(k), function(v) num(d[[v]])); m2 <- sapply(L2c(k), function(v) num(d[[v]]))
    # 0 = immediate amount (left), 1 = future reward (right); list 1 runs $20 (top) to $0 (bottom)
    ms <- pmax(ms, nchg(m1), nchg(m2))
    s <- rowSums(m1)                # number of future choices in list 1 (from $0 upward) = switch index
    x <- 2 * s - 2                  # second list runs from x to x + 1.8
    n2 <- rowSums(m2)               # number of future choices in list 2
    val[, k] <- x + 0.2 * n2 - 0.1  # midpoint of the indifference interval
    txt <- d[[paste0("T", k)]]
    simple <- grepl("pay you \\$", txt)
    tt <- as.numeric(sub(".* in ([0-9]+) days.*", "\\1", txt))
    a <- as.numeric(sub(".*invest \\$([0-9.]+) in.*", "\\1", ifelse(simple, "invest $0 in", txt)))
    rate <- as.numeric(sub(".*with ([0-9.]+)% interest.*", "\\1", ifelse(simple, "with 0% interest", txt)))
    Rs <- as.numeric(sub(".*pay you \\$([0-9.]+) in.*", "\\1", ifelse(simple, txt, "pay you $0 in")))
    Rc <- sapply(a * 2^(rate * tt / 72), function(v) c(20, 18, 16, 14, 12)[which.min(abs(v - c(20, 18, 16, 14, 12)))])  # nominal R of Table 2
    Rm[, k] <- ifelse(simple, Rs, Rc); tm[, k] <- tt; frame[, k] <- ifelse(simple, "s", "c")
  }
  d$multswitch <- ms >= 2
  long <- data.frame(id = rep(d$id, 20), row = rep(seq_len(nrow(d)), 20), k = rep(1:20, each = nrow(d)),
                     val = as.vector(val), R = as.vector(Rm), t = as.vector(tm), frame = as.vector(frame))
  list(subj = d, long = long)
}

# ---- Sample construction ----
suppressPackageStartupMessages(library(fixest))
set.seed(42)
prep <- function(d) {
  # completed the study: all 20 iterated price lists answered and the test reached
  tests_ok <- rowSums(sapply(paste0("test", 1:10), function(v) d[[v]] != ""))
  tasks_ok <- rowSums(sapply(1:20, function(k) rowSums(sapply(c(L1c(k), L2c(k)), function(v) d[[v]] != "")) == 21))
  d <- d[tasks_ok == 20 & tests_ok > 0, ]
  n <- nrow(d); viol <- rep(FALSE, n); val <- matrix(NA_real_, n, 20); Rm <- tm <- matrix(NA_real_, n, 20); fr <- matrix(NA_character_, n, 20)
  for (k in 1:20) {
    m1 <- sapply(L1c(k), function(v) num(d[[v]]))   # $20 (top) ... $0 (bottom); 0 = immediate, 1 = future
    m2 <- sapply(L2c(k), function(v) num(d[[v]]))   # x (bottom) ... x+1.8 (top)
    s <- rowSums(m1)
    nm1 <- apply(m1, 1, is.unsorted)                         # more than one switch / switch back in list 1
    nm2 <- apply(m2, 1, function(z) is.unsorted(rev(z)))     # same for list 2
    viol <- viol | nm1 | (nm2 & s >= 1 & s <= 10)            # list 2 only informative for an interior switch in list 1
    x <- 2 * s - 2
    val[, k] <- x + 0.2 * rowSums(m2) - 0.1                  # midpoint of the $0.20 interval
    txt <- d[[paste0("T", k)]]
    simple <- grepl("pay you \\$", txt)
    tt <- as.numeric(sub(".* in ([0-9]+) days.*", "\\1", txt))
    a <- as.numeric(sub(".*invest \\$([0-9.]+) in.*", "\\1", ifelse(simple, "invest $0 in", txt)))
    rate <- as.numeric(sub(".*with ([0-9.]+)% interest.*", "\\1", ifelse(simple, "with 0% interest", txt)))
    Rs <- as.numeric(sub(".*pay you \\$([0-9.]+) in.*", "\\1", ifelse(simple, txt, "pay you $0 in")))
    Rc <- sapply(a * 2^(rate * tt / 72), function(v) c(20, 18, 16, 14, 12)[which.min(abs(v - c(20, 18, 16, 14, 12)))])
    Rm[, k] <- ifelse(simple, Rs, Rc); tm[, k] <- tt; fr[, k] <- ifelse(simple, "s", "c")
  }
  d$multswitch <- viol
  d$sid <- seq_len(n)
  long <- data.frame(sid = rep(d$sid, 20), val = as.vector(val), R = as.vector(Rm), t = as.vector(tm), frame = as.vector(fr))
  list(subj = d, long = long)
}
pa <- prep(A); pb <- prep(B)
sa <- pa$subj; sb <- pb$subj
cat("Exp A completed:", nrow(sa), " multiple switchers:", sum(sa$multswitch), "\n")
cat("Exp B completed:", nrow(sb), " (duplicate participations:", sum(duplicated(sb$id)), ")\n")
sb$dup <- duplicated(sb$id)              # one worker took Exp B twice: keep first participation
cat("Exp B completed, first participations:", sum(!sb$dup), " multiple switchers among them:", sum(sb$multswitch & !sb$dup), "\n")

# Conditions. Exp A sessions came in two designs: batches 1,2,4,5 (Treatment vs Control: index funds video)
# and batches 3,6,7,8 (two dissected compound-interest videos). Identified from the video attention checks
# and from the self-report on knowing the rule of 72 (the Rhetoric-Only video omits the rule of 72).
sa$cond <- ifelse(sa$batch %in% c(1, 2, 4, 5), ifelse(sa$treatment == "1", "Treatment", "Control"),
                  ifelse(sa$treatment == "1", "SubstanceOnly", "RhetoricOnly"))
cat("\nExp A condition x video check (treatment-block word / control-block word):\n")
print(table(sa$cond, paste(sa$vidcheck_t, "/", sa$vidcheck_c)))
cat("Exp A condition x 'did you use rule of 72' (3 = I don't know the rule of 72):\n"); print(table(sa$cond, sa$rule72))
sb$cond <- ifelse(sb$treatment == "1", "Treatment", "Control")
cat("Exp B condition x rule72:\n"); print(table(sb$cond, sb$rule72))

# Test scores (answer codes follow on-screen option order)
keyC <- c(2, 4, 4, 7, 6)            # 7.2 yrs; 18%; 20 yrs; by 36%; $250
keyA <- c(3, 4, 2, 3, 3)            # Franklin quote; 90%; Sinclair quote; 50-70%; market portfolio
keyB <- c(4, 5, 5, 5, 1)            # GM & Microsoft; 0.7; stocks; stocks; 1
score <- function(d, qs, key) rowSums(sapply(seq_along(qs), function(i) { z <- num(d[[paste0("test", qs[i])]]); !is.na(z) & z == key[i] }))
sa$sc_comp <- score(sa, 1:5, keyC); sa$sc_ctrl <- score(sa, 6:10, keyA)
sb$sc_comp <- score(sb, 1:5, keyC); sb$sc_ctrl <- score(sb, 6:10, keyB)

A_an <- sa[!sa$multswitch, ]
B_an <- sb[!sb$multswitch & !sb$dup, ]
cat("\nExp A analysis sample by condition:\n"); print(table(A_an$cond))
cat("Exp B analysis sample by condition:\n"); print(table(B_an$cond))

# ---- Table 4 ----
t4a <- A_an[A_an$cond %in% c("Treatment", "Control"), ]
t4a$treat <- as.integer(t4a$cond == "Treatment"); B_an$treat <- as.integer(B_an$cond == "Treatment")
m1 <- lm(sc_comp ~ treat, data = t4a); m2 <- lm(sc_comp ~ treat, data = B_an)
m3 <- lm(sc_ctrl ~ treat, data = t4a); m4 <- lm(sc_ctrl ~ treat, data = B_an)
cat("\nTable 4:\n"); for (m in list(m1, m2, m3, m4)) print(round(summary(m)$coefficients, 3))

# ---- Table 7: deliberative competence ----
dc <- function(p, keep_sid, conds) {
  l <- p$long[p$long$sid %in% keep_sid, ]
  l$r <- 100 * l$val / l$R
  w <- reshape(l[, c("sid", "R", "t", "frame", "r")], idvar = c("sid", "R", "t"), timevar = "frame", direction = "wide")
  w$dc <- -abs(w$r.c - w$r.s)
  w$cond <- conds[match(w$sid, p$subj$sid)]
  w
}
wa <- dc(pa, A_an$sid, sa$cond)
wb <- dc(pb, B_an$sid, sb$cond)
wa$cond <- factor(wa$cond, levels = c("Control", "Treatment", "SubstanceOnly", "RhetoricOnly"))
wb$cond <- factor(wb$cond, levels = c("Control", "Treatment"))
f7a <- feols(dc ~ 0 + cond, data = wa, cluster = ~sid)
f7b <- feols(dc ~ 0 + cond, data = wb, cluster = ~sid)
cat("\nTable 7 col 1 (Exp A):\n"); print(coeftable(f7a)); cat("nobs", nobs(f7a), "\n")
cat("Table 7 col 2 (Exp B):\n"); print(coeftable(f7b)); cat("nobs", nobs(f7b), "\n")
ca <- coef(f7a); cb <- coef(f7b)

cat("\n")
cat(sprintf("RESULT:test_score_compounding_treatment_minus_control_expA_table4_col1=%.6f\n", coef(m1)["treat"]))
cat(sprintf("RESULT:test_score_compounding_treatment_minus_control_expB_table4_col2=%.6f\n", coef(m2)["treat"]))
cat(sprintf("RESULT:test_score_control_module_treatment_minus_control_expA_table4_col3=%.6f\n", coef(m3)["treat"]))
cat(sprintf("RESULT:test_score_control_module_treatment_minus_control_expB_table4_col4=%.6f\n", coef(m4)["treat"]))
cat(sprintf("RESULT:n_obs_table4_expA_cols1_3=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_obs_table4_expB_cols2_4=%d\n", nobs(m2)))
cat(sprintf("RESULT:deliberative_competence_control_expA_table7_col1=%.6f\n", ca["condControl"]))
cat(sprintf("RESULT:deliberative_competence_treatment_expA_table7_col1=%.6f\n", ca["condTreatment"]))
cat(sprintf("RESULT:deliberative_competence_substance_only_expA_table7_col1=%.6f\n", ca["condSubstanceOnly"]))
cat(sprintf("RESULT:deliberative_competence_rhetoric_only_expA_table7_col1=%.6f\n", ca["condRhetoricOnly"]))
cat(sprintf("RESULT:deliberative_competence_control_expB_table7_col2=%.6f\n", cb["condControl"]))
cat(sprintf("RESULT:deliberative_competence_treatment_expB_table7_col2=%.6f\n", cb["condTreatment"]))
cat(sprintf("RESULT:n_obs_table7_expA_col1=%d\n", nobs(f7a)))
