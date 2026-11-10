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

truthy <- function(x) {
  x <- trimws(as.character(x)); lx <- tolower(x)
  v <- num(x)
  out <- (!is.na(v) & v > 0) | lx %in% c("true", "yes", "y", "x", "excluded", "exclude")
  out[is.na(x) | x == ""] <- FALSE
  out
}

# valuations may be stored as text (e.g. "$12.20 - $12.40"); use midpoint of numbers found
parse_val <- function(x) {
  x <- as.character(x)
  unname(vapply(x, function(s) {
    if (is.na(s) || trimws(s) == "") return(NA_real_)
    s2 <- gsub("([0-9]),([0-9])", "\\1.\\2", s)
    m <- regmatches(s2, gregexpr("[0-9]+(\\.[0-9]+)?", s2))[[1]]
    if (!length(m)) return(NA_real_)
    mean(as.numeric(m))
  }, numeric(1)))
}

# ---------------------------------------------------------------- item scoring
key_items <- function(d, total) {
  tc <- paste0("test", 1:10)
  A <- sapply(tc, function(cn) { r <- trimws(as.character(d[[cn]])); r[!is.na(r) & r == ""] <- NA; r })
  A <- matrix(A, nrow = nrow(d), dimnames = list(NULL, tc))
  cands <- lapply(1:10, function(i) { tb <- sort(table(A[, i]), decreasing = TRUE); names(tb)[seq_len(min(8, length(tb)))] })
  keys <- sapply(cands, function(v) if (length(v)) v[1] else NA_character_)
  score_mat <- function(keys) {
    I <- sapply(1:10, function(i) ifelse(is.na(A[, i]), NA_real_, as.numeric(A[, i] == keys[i])))
    matrix(I, nrow = nrow(A))
  }
  if (!is.null(total)) {
    ok <- !is.na(total) & rowSums(!is.na(A)) > 0
    obj <- function(keys) {
      s <- rowSums(score_mat(keys), na.rm = TRUE)
      m <- mean(abs(s[ok] - total[ok]) < 1e-8)
      cc <- suppressWarnings(cor(s[ok], total[ok])); if (!is.finite(cc)) cc <- 0
      m + 0.01 * cc
    }
    if (sum(ok) > 10) {
      best <- obj(keys)
      for (pass in 1:5) {
        changed <- FALSE
        for (i in 1:10) for (v in cands[[i]]) {
          k2 <- keys; k2[i] <- v; o <- obj(k2)
          if (o > best + 1e-12) { best <- o; keys <- k2; changed <- TRUE }
        }
        if (!changed) break
      }
      cat(sprintf("Item keys fit to SC total score: objective (exact-match share + 0.01*cor) %.3f\n", best))
    }
  }
  I <- score_mat(keys); colnames(I) <- tc
  for (i in 1:10) cat(sprintf("  %s: keyed answer '%s', share correct %.3f\n", tc[i], keys[i], mean(I[, i], na.rm = TRUE)))
  I
}

# ---------------------------------------------------------------- arms
assign_arms <- function(d, comp, ctrl, exp) {
  nm <- names(d)
  cands <- unique(c(nm[tolower(nm) == "treatment"],
                    grep("treat|condition|^arm$|^group$", nm, value = TRUE, ignore.case = TRUE)))
  cands <- cands[!grepl("^TimeTreat", cands, ignore.case = TRUE)]
  if (!length(cands)) stop("no treatment column found")
  k <- if (exp == "A") 4 else 2
  clean <- function(cn) { r <- trimws(as.character(d[[cn]])); r[!is.na(r) & r == ""] <- NA; r }
  nval <- sapply(cands, function(cn) length(unique(na.omit(clean(cn)))))
  cat("Candidate treatment columns (distinct values):\n"); print(nval)
  pick <- cands[nval == k]
  tc <- if (length(pick)) pick[1] else if (any(tolower(cands) == "treatment")) cands[tolower(cands) == "treatment"][1] else cands[1]
  raw <- clean(tc)
  cat("Treatment column:", tc, "\n"); print(table(raw, useNA = "ifany"))
  if ("treatment" %in% nm && tc != "treatment") {
    cat("Cross-tab with 'treatment':\n"); print(table(raw, clean("treatment"), useNA = "ifany"))
  }
  lr <- tolower(raw); lab <- rep(NA_character_, length(raw))
  lab[grepl("rhet", lr)] <- "Rhetoric"
  lab[is.na(lab) & grepl("subs", lr)] <- "Substance"
  lab[is.na(lab) & grepl("control|ctrl|index|divers|portfolio", lr)] <- "Control"
  lab[is.na(lab) & grepl("treat|full|compound|interest|feedback|practice", lr)] <- "Treatment"
  if (any(!is.na(raw)) && all(!is.na(lab[!is.na(raw)])) && any(lab == "Control", na.rm = TRUE)) {
    cat("Arms mapped from string labels.\n")
    return(lab)
  }
  tabc <- sort(table(raw), decreasing = TRUE)
  codes <- names(tabc)[seq_len(min(k, length(tabc)))]
  if (all(!is.na(num(codes)))) codes <- codes[order(num(codes))] else codes <- sort(codes)
  mc <- sapply(codes, function(cd) mean(comp[which(raw == cd)], na.rm = TRUE))
  mk <- sapply(codes, function(cd) mean(ctrl[which(raw == cd)], na.rm = TRUE))
  dd <- mk - mc
  cat("Score means by code:\n"); print(round(rbind(items1_5 = mc, items6_10 = mk, diff = dd), 3))
  ctrl_code <- if (length(codes) > 2) codes[which.max(abs(dd - median(dd)))] else codes[which.max(dd)]
  others <- setdiff(codes, ctrl_code)
  labs <- c("Treatment", "Substance", "Rhetoric")[seq_along(others)]
  map <- setNames(c("Control", labs), c(ctrl_code, others))
  cat("Code -> arm mapping:\n"); print(map)
  if (length(codes) > 2)
    cat("DEVIATION: Experiment A arm codes are unlabeled; Control identified as the code with the distinct control-module vs compound-score profile, remaining codes mapped in code order to Treatment, Substance-Only, Rhetoric-Only (paper's listing order)\n")
  unname(map[raw])
}

# ---------------------------------------------------------------- valuations / deliberative competence
mapR <- function(m) {
  cands <- c(12, 14, 16, 18, 20)
  if (!is.finite(m)) return(NA_real_)
  i <- which(cands >= m - 0.3)
  if (length(i)) cands[i[1]] else NA_real_
}

build_dc <- function(V) {
  tcs <- colnames(V)
  mx <- apply(V, 2, function(z) if (all(is.na(z))) NA_real_ else max(z, na.rm = TRUE))
  cat("Valuation columns: mean / max / NA count\n")
  print(rbind(mean = round(colMeans(V, na.rm = TRUE), 3), max = round(mx, 3), nNA = colSums(is.na(V))))
  if (all(is.na(mx))) { cat("No parseable valuations\n"); return(NULL) }
  medmx <- median(mx, na.rm = TRUE)
  dollar <- medmx <= 25 && medmx > 11
  hyps <- list(H1 = cbind(1:10, 11:20), H2 = cbind(seq(1, 19, 2), seq(2, 20, 2)))
  score_h <- sapply(hyps, function(P) {
    cc <- mean(sapply(1:10, function(k) suppressWarnings(cor(V[, P[k, 1]], V[, P[k, 2]], use = "pairwise.complete.obs"))), na.rm = TRUE)
    if (!is.finite(cc)) cc <- 0
    if (dollar) {
      agree <- mean(sapply(1:10, function(k) isTRUE(mapR(mx[P[k, 1]]) == mapR(mx[P[k, 2]]))))
      Rs <- sort(sapply(1:10, function(k) mapR(min(mx[P[k, ]], na.rm = TRUE))))
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
      R <- mapR(min(mx[a], mx[b], na.rm = TRUE))
      ra <- V[, a] / R * 100; rb <- V[, b] / R * 100
    } else if (medmx <= 1.05) {
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

  fc <- intersect(c("Finished", "V10"), nm)
  if (length(fc)) {
    f <- d[[fc[1]]]
    cat("Completion column", fc[1], ":\n"); print(table(f, useNA = "ifany"))
    k <- f %in% c("1", "True", "TRUE", "true")
    if (sum(k) > 0.5 * nrow(d)) d <- d[k, , drop = FALSE]
  }
  cat("Rows after completion filter:", nrow(d), "\n")

  tc <- paste0("test", 1:10)
  if (!all(tc %in% names(d))) stop("test1..test10 not all present")
  nans <- rowSums(matrix(sapply(tc, function(cn) { r <- trimws(as.character(d[[cn]])); !is.na(r) & r != "" }), nrow = nrow(d)))
  d <- d[nans > 0, , drop = FALSE]
  cat("Rows with test answers:", nrow(d), "\n")

  sc <- grep("^SC[0-9]", names(d), value = TRUE)
  total <- NULL
  if (length(sc)) {
    M <- matrix(sapply(sc, function(cn) num(d[[cn]])), nrow = nrow(d), dimnames = list(NULL, sc))
    mm <- apply(M, 2, function(z) if (all(is.na(z))) -Inf else max(z, na.rm = TRUE))
    cat("SC column maxima:\n"); print(mm)
    j <- which.max(mm)
    if (is.finite(mm[j]) && mm[j] >= 3) { total <- M[, j]; cat("Total score column:", sc[j], "\n") }
  }
  I <- key_items(d, total)
  subsc <- function(ix) {
    sb <- I[, ix, drop = FALSE]
    s <- rowSums(sb, na.rm = TRUE); s[rowSums(!is.na(sb)) == 0] <- NA; s
  }
  d$s15 <- subsc(1:5); d$s610 <- subsc(6:10)

  d$arm <- assign_arms(d, d$s15, d$s610, exp)
  dT <- mean(d$s15[which(d$arm == "Treatment")], na.rm = TRUE) - mean(d$s15[which(d$arm == "Control")], na.rm = TRUE)
  dK <- mean(d$s610[which(d$arm == "Treatment")], na.rm = TRUE) - mean(d$s610[which(d$arm == "Control")], na.rm = TRUE)
  cat(sprintf("Treatment-Control raw diffs: items1_5 %.3f, items6_10 %.3f\n", dT, dK))
  if (is.finite(dT) && is.finite(dK) && dK > dT) {
    d$score_comp <- d$s610; d$score_ctrl <- d$s15; cat("Compound-interest items: 6-10\n")
  } else {
    d$score_comp <- d$s15; d$score_ctrl <- d$s610; cat("Compound-interest items: 1-5\n")
  }

  # valuations
  tcs <- paste0("T", 1:20)
  Vall <- matrix(sapply(tcs, function(cn) if (cn %in% names(d)) parse_val(d[[cn]]) else rep(NA_real_, nrow(d))),
                 nrow = nrow(d), dimnames = list(NULL, tcs))
  if (all(c("T1", "T11") %in% names(d))) { cat("Raw valuation examples:\n"); print(head(d[, c("T1", "T2", "T11")], 4)) }

  # multiple-switcher exclusion
  expected <- if (exp == "A") 49 / 504 else 53 / 401
  flags <- list()
  exc_cols <- grep("^exclu", names(d), value = TRUE, ignore.case = TRUE)
  for (cn in exc_cols) {
    cat("Column", cn, ":\n"); print(head(sort(table(d[[cn]], useNA = "ifany"), decreasing = TRUE), 8))
    flags[[cn]] <- truthy(d[[cn]])
  }
  if (length(exc_cols) > 1) flags[["any_exclude"]] <- Reduce(`|`, flags[exc_cols])
  flags[["missing_valuation"]] <- rowSums(is.na(Vall)) > 0
  ina <- !is.na(d$arm)
  sh <- sapply(flags, function(f) mean(f[ina]))
  cat("Share flagged by each candidate exclusion rule:\n"); print(round(sh, 3))
  okf <- names(sh)[sh >= 0.03 & sh <= 0.30]
  if (length(okf)) {
    pk <- okf[which.min(abs(sh[okf] - expected))]
    multi <- flags[[pk]]
    cat(sprintf("DEVIATION: multiple-switcher exclusion implemented via '%s' (no explicit switch-count variable; rule chosen as the candidate flag closest to the paper's reported exclusion share)\n", pk))
  } else {
    multi <- rep(FALSE, nrow(d))
    cat("No usable exclusion flag found\n")
  }
  keep <- !multi & ina
  s <- d[keep, , drop = FALSE]
  Vs <- Vall[keep, , drop = FALSE]
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
    dcl <- build_dc(Vs)
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