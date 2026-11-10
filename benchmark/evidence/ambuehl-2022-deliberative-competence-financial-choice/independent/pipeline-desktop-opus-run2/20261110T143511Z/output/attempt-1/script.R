suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice.script-free"
num <- function(x) suppressWarnings(as.numeric(as.character(x)))
results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(as.numeric(val))) results[[name]] <<- unname(as.numeric(val))
}

# ---------------------------------------------------------------- reading
read_batch <- function(f) {
  d <- readr::read_csv(f, col_types = readr::cols(.default = readr::col_character()),
                       name_repair = "minimal", show_col_types = FALSE, progress = FALSE)
  nm <- names(d)
  nm <- gsub("﻿", "", nm, fixed = TRUE)
  nm <- gsub("^\\s+|\\s+$", "", nm)
  empty <- is.na(nm) | nm == ""
  nm[empty] <- paste0("X_", seq_along(nm))[empty]
  names(d) <- make.unique(nm)
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  keep <- rep(TRUE, nrow(d))
  idc <- intersect(c("V1", "ResponseId", "ResponseID"), names(d))
  if (length(idc) > 0) {
    k <- grepl("^R_", d[[idc[1]]])
    if (sum(k) > 0) keep <- k
  }
  if (all(keep) && nrow(d) > 0) {
    bad <- apply(d[, seq_len(min(6, ncol(d))), drop = FALSE], 1,
                 function(r) any(grepl("ImportId|ResponseI[dD]|Response ID", r)))
    keep <- !bad
  }
  d <- d[keep, , drop = FALSE]
  d$batch_file <- basename(f)
  d
}

# ---------------------------------------------------------------- scores
get_scores <- function(d) {
  sc <- grep("^SC[0-9]", names(d), value = TRUE)
  if (length(sc) == 0) sc <- grep("score", names(d), value = TRUE, ignore.case = TRUE)
  if (length(sc) == 0) return(character(0))
  M <- matrix(sapply(sc, function(cn) num(d[[cn]])), nrow = nrow(d), dimnames = list(NULL, sc))
  ok <- sapply(sc, function(cn) {
    x <- M[, cn]; x <- x[!is.na(x)]
    length(x) > 0.5 * nrow(M) && max(x) <= 5 && min(x) >= 0 && max(x) >= 1 &&
      all(abs(x - round(x)) < 1e-8)
  })
  cand <- sc[ok]
  if (length(cand) >= 3) {
    drop <- character(0)
    for (cc in cand) {
      oth <- setdiff(cand, c(cc, drop))
      if (length(oth) >= 2) {
        pr <- combn(oth, 2)
        for (j in seq_len(ncol(pr))) {
          s <- M[, pr[1, j]] + M[, pr[2, j]]
          if (mean(abs(M[, cc] - s) < 1e-8, na.rm = TRUE) > 0.95) { drop <- c(drop, cc); break }
        }
      }
    }
    cand <- setdiff(cand, drop)
  }
  cand
}

# ---------------------------------------------------------------- arms
assign_arms <- function(d, M, exp) {
  nm <- names(d)
  tc <- nm[tolower(nm) == "treatment"]
  if (!length(tc)) tc <- grep("treat|condition|^arm$|^group$", nm, value = TRUE, ignore.case = TRUE)
  if (!length(tc)) stop("no treatment column found")
  tc <- tc[1]
  raw <- trimws(as.character(d[[tc]])); raw[!is.na(raw) & raw == ""] <- NA
  cat("Treatment column:", tc, "\n"); print(table(raw, useNA = "ifany"))
  lr <- tolower(raw); lab <- rep(NA_character_, length(raw))
  lab[grepl("rhet", lr)] <- "Rhetoric"
  lab[is.na(lab) & grepl("subs", lr)] <- "Substance"
  lab[is.na(lab) & grepl("control|ctrl|index|divers|portfolio", lr)] <- "Control"
  lab[is.na(lab) & grepl("treat|full|compound|interest|feedback|practice", lr)] <- "Treatment"
  sc <- colnames(M)
  if (any(!is.na(raw)) && all(!is.na(lab[!is.na(raw)])) && any(lab == "Control", na.rm = TRUE)) {
    arm <- lab
    cat("Arms mapped from string labels.\n")
  } else {
    tabc <- sort(table(raw), decreasing = TRUE)
    k <- if (exp == "A") 4 else 2
    codes <- names(tabc)[seq_len(min(k, length(tabc)))]
    if (all(!is.na(num(codes)))) codes <- codes[order(num(codes))] else codes <- sort(codes)
    means <- sapply(codes, function(cd) colMeans(M[which(raw == cd), , drop = FALSE], na.rm = TRUE))
    means <- matrix(means, nrow = length(sc), dimnames = list(sc, codes))
    cat("Score means by treatment code:\n"); print(round(means, 3))
    L <- apply(means, 1, function(mr) max(sapply(seq_along(mr), function(j) mean(mr[-j]) - mr[j])))
    compc <- sc[which.max(L)]
    ctrl_code <- codes[which.min(means[compc, ])]
    others <- setdiff(codes, ctrl_code)
    labs <- if (exp == "A") c("Treatment", "Substance", "Rhetoric") else c("Treatment")
    map <- setNames(c("Control", labs[seq_along(others)]), c(ctrl_code, others))
    cat("Code -> arm mapping (Control identified from scores; others by code order):\n"); print(map)
    arm <- unname(map[raw])
  }
  diffs <- sapply(sc, function(cn) mean(M[which(arm == "Treatment"), cn], na.rm = TRUE) -
                    mean(M[which(arm == "Control"), cn], na.rm = TRUE))
  cat("Treatment - Control raw diffs by score column:\n"); print(round(diffs, 3))
  list(arm = arm, comp = sc[which.max(diffs)], ctrlmod = sc[which.min(diffs)])
}

# ---------------------------------------------------------------- valuations / deliberative competence
mapR <- function(m) {
  cands <- c(12, 14, 16, 18, 20)
  if (!is.finite(m)) return(NA_real_)
  i <- which(cands >= m - 0.3)
  if (length(i)) cands[i[1]] else NA_real_
}

build_dc <- function(s) {
  tcs <- paste0("T", 1:20)
  if (!all(tcs %in% names(s))) { cat("T1..T20 not all present; cannot build valuations\n"); return(NULL) }
  V <- matrix(sapply(tcs, function(cn) num(s[[cn]])), nrow = nrow(s), dimnames = list(NULL, tcs))
  mx <- suppressWarnings(apply(V, 2, max, na.rm = TRUE))
  cat("Valuation columns: mean / max / NA count\n")
  print(rbind(mean = round(colMeans(V, na.rm = TRUE), 3), max = round(mx, 3), nNA = colSums(is.na(V))))
  dollar <- all(is.finite(mx)) && max(mx) <= 21 && max(mx) > 11
  hyps <- list(H1 = cbind(1:10, 11:20), H2 = cbind(seq(1, 19, 2), seq(2, 20, 2)))
  score_h <- sapply(hyps, function(P) {
    cc <- mean(sapply(1:10, function(k) suppressWarnings(cor(V[, P[k, 1]], V[, P[k, 2]], use = "pairwise.complete.obs"))), na.rm = TRUE)
    if (!is.finite(cc)) cc <- 0
    if (dollar) {
      agree <- mean(sapply(1:10, function(k) isTRUE(mapR(mx[P[k, 1]]) == mapR(mx[P[k, 2]]))))
      Rs <- sort(sapply(1:10, function(k) mapR(max(mx[P[k, ]]))))
      ms <- as.numeric(length(Rs) == 10 && isTRUE(all(Rs == sort(rep(c(12, 14, 16, 18, 20), 2)))))
      agree + ms + cc
    } else cc
  })
  cat("Pairing hypothesis scores:\n"); print(round(score_h, 3))
  P <- hyps[[which.max(score_h)]]
  rows <- list()
  for (k in 1:10) {
    a <- P[k, 1]; b <- P[k, 2]
    if (dollar) {
      R <- mapR(max(mx[a], mx[b]))
      ra <- V[, a] / R * 100; rb <- V[, b] / R * 100
    } else if (max(mx) <= 1.05) {
      R <- NA_real_; ra <- V[, a] * 100; rb <- V[, b] * 100
    } else {
      R <- NA_real_; ra <- V[, a]; rb <- V[, b]
    }
    rows[[k]] <- data.frame(row = seq_len(nrow(V)), pair = k, colA = tcs[a], colB = tcs[b], R = R, dc = -abs(ra - rb))
  }
  out <- do.call(rbind, rows)
  cat("Pairs used (column A, column B, R):\n"); print(unique(out[, c("pair", "colA", "colB", "R")]))
  out
}

arm_reg <- function(df, y, arms, cluster = NULL) {
  for (a in arms) df[[paste0("d_", a)]] <- as.numeric(df$arm == a)
  fml <- as.formula(paste(y, "~ 0 +", paste0("d_", arms, collapse = " + ")))
  if (is.null(cluster)) feols(fml, data = df, vcov = "iid") else feols(fml, data = df, cluster = cluster)
}

# ---------------------------------------------------------------- experiment pipeline
process_exp <- function(files, exp) {
  out <- list()
  d <- dplyr::bind_rows(lapply(files, read_batch))
  nm <- names(d)
  cat(sprintf("\n==== Experiment %s: %d rows, %d cols after header-row removal ====\n", exp, nrow(d), ncol(d)))
  cat("Last 120 names:", paste(tail(nm, 120), collapse = ", "), "\n")
  cat("Key names:", paste(grep("treat|cond|^SC[0-9]|score|switch|^T[0-9]+$|excl|Finished|^V10$|^val",
                               nm, value = TRUE, ignore.case = TRUE), collapse = ", "), "\n")

  fc <- intersect(c("Finished", "V10"), nm)
  if (length(fc)) {
    f <- d[[fc[1]]]
    cat("Completion column", fc[1], ":\n"); print(table(f, useNA = "ifany"))
    k <- f %in% c("1", "True", "TRUE", "true")
    if (sum(k) > 0.5 * nrow(d)) d <- d[k, , drop = FALSE]
  }
  cat("Rows after completion filter:", nrow(d), "\n")

  sc <- get_scores(d)
  if (length(sc) < 2) stop("could not identify two 0-5 score columns")
  cat("Candidate score columns:", sc, "\n")
  M <- matrix(sapply(sc, function(cn) num(d[[cn]])), nrow = nrow(d), dimnames = list(NULL, sc))
  am <- assign_arms(d, M, exp)
  d$arm <- am$arm
  d$score_comp <- num(d[[am$comp]]); d$score_ctrl <- num(d[[am$ctrlmod]])
  cat("Compound-interest score column:", am$comp, "; control-module score column:", am$ctrlmod, "\n")

  # multiple-switcher exclusion
  swc <- grep("^switch[0-9]+$", names(d), value = TRUE, ignore.case = TRUE)
  multi <- rep(NA, nrow(d))
  if (length(swc)) {
    S <- matrix(sapply(swc, function(cn) num(d[[cn]])), nrow = nrow(d))
    cat("Switch columns (", length(swc), "): value distribution\n"); print(table(as.vector(S), useNA = "ifany"))
    mxs <- suppressWarnings(max(S, na.rm = TRUE))
    q90 <- suppressWarnings(quantile(S, 0.9, na.rm = TRUE))
    if (is.finite(mxs) && mxs <= 1) {
      multi <- apply(S, 1, function(r) any(r == 1, na.rm = TRUE))
      cat("Switch columns treated as multiple-switch indicators\n")
    } else if (is.finite(q90) && q90 <= 1) {
      multi <- apply(S, 1, function(r) any(r >= 2, na.rm = TRUE))
      cat("Switch columns treated as switch counts (>=2 => excluded)\n")
    }
  }
  exc <- if ("excluded" %in% names(d)) num(d$excluded) else rep(NA_real_, nrow(d))
  cat("multi vs excluded:\n"); print(table(multi = multi, excluded = exc, useNA = "ifany"))
  if (all(is.na(multi))) {
    if (any(!is.na(exc))) { multi <- !is.na(exc) & exc == 1; cat("Using 'excluded' column for sample restriction\n") }
    else multi <- rep(FALSE, nrow(d))
  }
  s <- d[!multi & !is.na(d$arm), , drop = FALSE]
  s$sid <- seq_len(nrow(s))
  cat("Analysis sample N =", nrow(s), "\n"); print(table(s$arm))

  # Table 4: Control + Treatment only, one obs per subject
  ct <- s[s$arm %in% c("Control", "Treatment"), , drop = FALSE]
  m4c <- arm_reg(ct, "score_comp", c("Control", "Treatment"))
  m4k <- arm_reg(ct, "score_ctrl", c("Control", "Treatment"))
  dfun <- function(m) {
    b <- coef(m); V <- vcov(m)
    est <- b["d_Treatment"] - b["d_Control"]
    se <- sqrt(V["d_Treatment", "d_Treatment"] + V["d_Control", "d_Control"] - 2 * V["d_Treatment", "d_Control"])
    c(est = unname(est), se = unname(se))
  }
  r4c <- dfun(m4c); r4k <- dfun(m4k)
  cat(sprintf("Table 4 %s compound: diff %.3f (SE %.3f), N=%d\n", exp, r4c["est"], r4c["se"], nobs(m4c)))
  cat(sprintf("Table 4 %s control module: diff %.3f (SE %.3f), N=%d\n", exp, r4k["est"], r4k["se"], nobs(m4k)))
  out$t4_comp <- r4c["est"]; out$t4_ctrl <- r4k["est"]; out$n_t4 <- nobs(m4c)

  # Table 7: deliberative competence levels
  out$t7 <- NULL
  tryCatch({
    dcl <- build_dc(s)
    if (!is.null(dcl)) {
      dcl$arm <- s$arm[dcl$row]; dcl$sid <- s$sid[dcl$row]
      dcl <- dcl[!is.na(dcl$dc), , drop = FALSE]
      arms_present <- intersect(c("Control", "Treatment", "Substance", "Rhetoric"), unique(dcl$arm))
      m7 <- arm_reg(dcl, "dc", arms_present, cluster = ~sid)
      print(summary(m7))
      out$t7 <- coef(m7); out$n7 <- nobs(m7)
    }
  }, error = function(e) cat("DC stage error:", conditionMessage(e), "\n"))
  out
}

fa <- file.path(base, "data/raw", paste0("expAbatch", 1:8, ".csv"))
fb <- file.path(base, "data/raw", paste0("expBbatch", 1:2, ".csv"))
resA <- tryCatch(process_exp(fa, "A"), error = function(e) { cat("Experiment A error:", conditionMessage(e), "\n"); NULL })
resB <- tryCatch(process_exp(fb, "B"), error = function(e) { cat("Experiment B error:", conditionMessage(e), "\n"); NULL })

if (!is.null(resA)) {
  emit("test_score_compounding_treatment_minus_control_expA_table4_col1", resA$t4_comp)
  emit("test_score_control_module_treatment_minus_control_expA_table4_col3", resA$t4_ctrl)
  emit("n_obs_table4_expA_cols1_3", resA$n_t4)
  if (!is.null(resA$t7)) {
    emit("deliberative_competence_control_expA_table7_col1", resA$t7["d_Control"])
    emit("deliberative_competence_treatment_expA_table7_col1", resA$t7["d_Treatment"])
    emit("deliberative_competence_substance_only_expA_table7_col1", resA$t7["d_Substance"])
    emit("deliberative_competence_rhetoric_only_expA_table7_col1", resA$t7["d_Rhetoric"])
    emit("n_obs_table7_expA_col1", resA$n7)
  }
}
if (!is.null(resB)) {
  emit("test_score_compounding_treatment_minus_control_expB_table4_col2", resB$t4_comp)
  emit("test_score_control_module_treatment_minus_control_expB_table4_col4", resB$t4_ctrl)
  emit("n_obs_table4_expB_cols2_4", resB$n_t4)
  if (!is.null(resB$t7)) {
    emit("deliberative_competence_control_expB_table7_col2", resB$t7["d_Control"])
    emit("deliberative_competence_treatment_expB_table7_col2", resB$t7["d_Treatment"])
  }
}

cat("\n")
for (n in names(results)) cat(sprintf("RESULT:%s=%s\n", n, format(results[[n]], digits = 10)))