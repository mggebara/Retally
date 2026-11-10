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

# ---- Diagnostics 3: variants of the multiple-switching definition (no estimates) ----
for (nm in c("A", "B")) {
  d <- if (nm == "A") A else B
  tests_ok <- rowSums(sapply(paste0("test", 1:10), function(v) d[[v]] != ""))
  tasks_ok <- rowSums(sapply(1:20, function(k) rowSums(sapply(c(L1c(k), L2c(k)), function(v) d[[v]] != "")) == 21))
  d <- d[tasks_ok == 20 & tests_ok > 0, ]
  n <- nrow(d)
  nm1 <- nm2 <- c1m <- c2m <- r1 <- r2 <- S <- N2 <- matrix(0, n, 20)
  for (k in 1:20) {
    m1 <- sapply(L1c(k), function(v) num(d[[v]])); m2 <- sapply(L2c(k), function(v) num(d[[v]]))
    c1m[, k] <- nchg(m1); c2m[, k] <- nchg(m2)
    nm1[, k] <- apply(m1, 1, is.unsorted); nm2[, k] <- apply(m2, 1, function(z) is.unsorted(rev(z)))
    S[, k] <- rowSums(m1); N2[, k] <- rowSums(m2)
    # list 2 in display order (top x+1.8 ... bottom x): count switches
  }
  f <- function(m) rowSums(m) > 0
  mid <- S >= 1 & S <= 10
  v <- list(
    nonmono_all = f(nm1 | nm2),
    nonmono1_only = f(nm1),
    nm1_or_nm2_mid = f(nm1 | (nm2 & mid)),
    nm1_or_nm2_s_ge1 = f(nm1 | (nm2 & S >= 1)),
    nm1_or_nm2_s_le10 = f(nm1 | (nm2 & S <= 10)),
    chg2_any = f(c1m >= 2 | c2m >= 2),
    chg2_or_nm1 = f(c1m >= 2 | c2m >= 2 | nm1),
    chg2_or_nm2 = f(c1m >= 2 | c2m >= 2 | nm2),
    nm1_or_chg2_l2 = f(nm1 | c2m >= 2),
    combined_nonmono = f(nm1 | nm2 | (N2 == 0 & S >= 1)),
    tasks_ge2 = rowSums(nm1 | nm2) >= 2
  )
  # drop later duplicate participation
  first <- !duplicated(d$id)
  cat("\nExp", nm, " complete", n, " first-participation", sum(first), "\n")
  for (nmv in names(v)) {
    x <- v[[nmv]]
    out <- sprintf("%-20s all=%d  firstonly=%d", nmv, sum(x), sum(x[first]))
    if (nm == "A") { grp <- d$batch %in% c(1, 2, 4, 5); out <- paste(out, sprintf(" TCkeep=%d SRkeep=%d", sum(!x & grp), sum(!x & !grp))) }
    if (nm == "B") out <- paste(out, sprintf(" keep(first)=%d", sum(!x & first)))
    cat(out, "\n")
  }
}
