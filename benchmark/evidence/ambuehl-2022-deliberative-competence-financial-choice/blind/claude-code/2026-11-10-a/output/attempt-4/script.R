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

# ---- Diagnostics (no estimates of listed quantities) ----
pa <- process(A); pb <- process(B)
for (nm in c("A", "B")) {
  p <- if (nm == "A") pa else pb
  s <- p$subj
  cat("\nExp", nm, ": complete subjects", nrow(s), " multiple switchers", sum(s$multswitch), " remaining", sum(!s$multswitch), "\n")
  cat("duplicate ids among complete:", sum(duplicated(s$id)), "; dup ids multswitch:", paste(s$multswitch[s$id %in% s$id[duplicated(s$id)]], collapse = ","), "\n")
  print(table(batch = s$batch, treat = s$treatment, ms = s$multswitch))
  cat("rule72 by batch x treatment (1/2/3)\n")
  print(table(paste(s$batch, s$treatment), s$rule72))
  cat("rule72_inv by batch x treatment\n")
  print(table(paste(s$batch, s$treatment), s$rule72_inv))
  l <- p$long
  cat("R x t x frame\n"); print(table(l$R, l$t, l$frame))
  cat("pairs per subject (unique R,t,frame):", paste(range(tapply(paste(l$R, l$t, l$frame), l$row, function(z) length(unique(z)))), collapse = "-"), "\n")
  cat("valuation summary:\n"); print(summary(l$val)); cat("share val<0:", mean(l$val < 0), " val>R:", mean(l$val > l$R), "\n")
}
s <- pa$subj
cat("\nA video checks for complete subjects:\n"); print(table(paste(s$batch, s$treatment), paste(s$vidcheck_t, s$vidcheck_c)))
cat("B time on treatment page by treatment (median):\n"); print(tapply(num(pb$subj$time_t), pb$subj$treatment, median, na.rm = TRUE))
