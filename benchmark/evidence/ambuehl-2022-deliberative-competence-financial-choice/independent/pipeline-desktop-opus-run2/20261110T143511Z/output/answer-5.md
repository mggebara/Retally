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
cl <- function(x) { r <- trimws(as.character(x)); r[!is.na(r) & r == ""] <- NA; r }
short <- function(s, n = 14) { s <- as.character(s); ifelse(nchar(s) > n, paste0(substr(s, 1, n), "~"), s) }

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

mode_code <- function(z) { z <- z[!is.na(z)]; if (length(z)) names(which.max(table(z))) else NA_character_ }

# binarize a price list: 1 = the reference option (numeric code X, or the delayed option when cells hold text)
binz <- function(M, X) {
  vals <- unique(na.omit(as.vector(M)))
  if (length(vals) && any(grepl("[A-Za-z]", vals))) {
    B <- ifelse(is.na(M), NA_real_, as.numeric(grepl("days|later|week|month|future", tolower(M))))
  } else {
    B <- ifelse(is.na(M), NA_real_, as.numeric(!is.na(X) & M == X))
  }
  matrix(B, nrow = nrow(M))
}
row_switches <- function(B) {
  if (ncol(B) < 2) return(rep(0, nrow(B)))
  apply(B, 1, function(z) { z <- z[!is.na(z)]; if (length(z) > 1) sum(diff(z) != 0) else 0 })
}

# ---------------------------------------------------------------- iterated MPL decoding from iMPL* columns
decode_impl <- function(d) {
  n <- nrow(d); nm <- names(d)
  ic <- grep("^iMPL", nm, value = TRUE)
  cat("iMPL columns:", length(ic), "\n")
  if (length(ic) < 40) return(NULL)
  cat("iMPL names (first 4 / 20-23 / last 2):", paste(c(head(ic, 4), ic[20:23], tail(ic, 2)), collapse = " | "), "\n")
  tl <- regmatches(ic, gregexpr("[0-9]+", ic))
  len <- lengths(tl)
  L0 <- as.integer(names(which.max(table(len))))
  ic <- ic[len == L0]
  tok <- matrix(as.numeric(unlist(tl[len == L0])), ncol = L0, byrow = TRUE)
  ndist <- apply(tok, 2, function(z) length(unique(z)))
  cat("Tokens per name:", L0, "; distinct values by position:", paste(ndist, collapse = ","), "\n")
  V <- matrix(sapply(ic, function(cn) cl(d[[cn]])), nrow = n)
  av <- sort(table(V), decreasing = TRUE)
  cat("iMPL cell values:", paste(sprintf("%s:%d", short(names(av), 14), as.integer(av))[seq_len(min(8, length(av)))], collapse = " "), "\n")

  mk_groups <- function(p) {
    key <- if (L0 > 1) apply(tok[, -p, drop = FALSE], 1, paste, collapse = "-") else rep("k", length(ic))
    gs <- split(seq_along(ic), key)
    lapply(gs, function(g) g[order(tok[g, p])])
  }
  best <- NULL; bestsc <- -1
  for (p in which(ndist >= 3)) {
    gs <- mk_groups(p); sz <- lengths(gs)
    if (length(gs) < 10 || median(sz) < 4) {
      cat(sprintf("Row-position %d: %d lists, median size %g -> skipped\n", p, length(gs), median(sz))); next
    }
    scs <- c(); wts <- c()
    for (g in gs) {
      M <- V[, g, drop = FALSE]
      B <- binz(M, mode_code(M[, 1]))
      ok <- rowSums(!is.na(B)) >= 3
      if (!any(ok)) next
      sw <- row_switches(B[ok, , drop = FALSE])
      scs <- c(scs, mean(sw <= 1)); wts <- c(wts, sum(ok))
    }
    sc <- if (length(scs)) sum(scs * wts) / sum(wts) else 0
    tsz <- table(sz)
    cat(sprintf("Row-position %d: %d lists (size x count: %s), monotone share %.3f\n", p, length(gs),
                paste(names(tsz), as.integer(tsz), sep = "x", collapse = ","), sc))
    if (sc > bestsc) { bestsc <- sc; best <- list(p = p, gs = gs) }
  }
  if (is.null(best)) { cat("No usable iMPL grouping\n"); return(NULL) }
  p <- best$p; gs <- best$gs; rem <- setdiff(seq_len(L0), p)
  K <- do.call(rbind, lapply(gs, function(g) tok[g[1], rem]))
  if (is.null(dim(K))) K <- matrix(K, ncol = length(rem))
  ord <- do.call(order, as.data.frame(K)); gs <- gs[ord]; K <- K[ord, , drop = FALSE]
  nl <- length(gs)
  tkey <- NULL
  if (nl == 20) tkey <- seq_len(20)
  if (is.null(tkey)) for (q in seq_len(ncol(K))) if (length(unique(K[, q])) == 20) { tkey <- match(K[, q], sort(unique(K[, q]))); break }
  if (is.null(tkey) && ncol(K) > 1) for (s in seq_len(ncol(K))) if (length(unique(K[, s])) == 2) {
    kk <- apply(K[, -s, drop = FALSE], 1, paste, collapse = "-")
    if (length(unique(kk)) == 20) { tkey <- match(kk, unique(kk)); break }
  }
  if (is.null(tkey) && nl == 40) {
    sz <- lengths(gs)
    tkey <- if (length(unique(sz[1:20])) == 1 && length(unique(sz[21:40])) == 1 && sz[1] != sz[21]) rep(1:20, 2) else rep(1:20, each = 2)
  }
  if (is.null(tkey)) { cat("Could not map", nl, "iMPL lists onto 20 tasks\n"); return(NULL) }

  share1 <- function(z) { z <- z[!is.na(z)]; if (length(z)) max(table(z)) / length(z) else 0 }
  unan <- function(g) { M <- V[, g, drop = FALSE]; share1(M[, 1]) + share1(M[, ncol(M)]) }
  coarse <- integer(20); fine <- vector("list", 20)
  for (k in 1:20) {
    li <- which(tkey == k)
    if (!length(li)) { cat("Task", k, "has no list\n"); return(NULL) }
    ci <- if (length(li) == 1) li else li[which.max(vapply(li, function(j) unan(gs[[j]]), numeric(1)))]
    coarse[k] <- ci; fine[[k]] <- setdiff(li, ci)
  }
  gl <- mode_code(unlist(lapply(coarse, function(ci) V[, gs[[ci]][1]])))
  cat(sprintf("Lists: %d, mapped to 20 tasks; coarse/fine sizes task1: %d/%s; reference code '%s'\n", nl,
              length(gs[[coarse[1]]]), paste(lengths(gs[fine[[1]]]), collapse = "+"), gl))
  RF <- matrix(NA_real_, n, 20); SW <- matrix(NA_real_, n, 20)
  for (k in 1:20) {
    Mc <- V[, gs[[coarse[k]]], drop = FALSE]; Bc <- binz(Mc, gl)
    n1 <- ncol(Mc)
    cs <- if (n1 %in% 10:11) 10 else 100 / max(n1 - 1, 1)
    ansc <- rowSums(!is.na(Bc)) > 0
    cc <- rowSums(Bc, na.rm = TRUE)
    sw <- row_switches(Bc)
    fpart <- rep(0, n)
    if (length(fine[[k]])) {
      for (jj in seq_along(fine[[k]])) {
        Mf <- V[, gs[[fine[[k]][jj]]], drop = FALSE]
        X2 <- if (!is.na(gl) && gl %in% Mf) gl else mode_code(Mf[, 1])
        Bf <- binz(Mf, X2); nf <- ncol(Mf)
        sw <- pmax(sw, row_switches(Bf))
        if (jj == 1) {
          fs <- if (nf %in% 9:11) cs / 10 else cs / (nf + 1)
          gcount <- ifelse(rowSums(!is.na(Bf)) > 0, rowSums(Bf, na.rm = TRUE), nf / 2)
          fpart <- fs * (gcount + 0.5)
        }
      }
    } else fpart <- cs / 2
    v <- cs * cc + fpart
    RF[ansc, k] <- v[ansc]; SW[ansc, k] <- sw[ansc]
  }
  cat("DEVIATION: valuations reconstructed from raw iMPL choices: coarse list step = 10% of R, refining list step = 1% of R, interval midpoint (a constant offset that cancels in r^c - r^s)\n")
  list(RF = RF, SW = SW)
}

# ---------------------------------------------------------------- task texts and pairing
parse1 <- function(s) {
  s <- tolower(s)
  days <- if (grepl("[0-9]+\\s*days", s)) num(sub("^.*?([0-9]+)\\s*days.*$", "\\1", s, perl = TRUE)) else NA_real_
  cx <- grepl("invest|interest|%", s)
  if (cx) {
    a <- num(sub("^.*?\\$\\s*([0-9]+(\\.[0-9]+)?).*$", "\\1", s, perl = TRUE))
    x <- num(sub("^.*?([0-9]+(\\.[0-9]+)?)\\s*%.*$", "\\1", s, perl = TRUE))
    fv <- a * (1 + x / 100)^days
  } else fv <- num(sub("^.*?\\$\\s*([0-9]+(\\.[0-9]+)?).*$", "\\1", s, perl = TRUE))
  c(fv, days, as.numeric(cx))
}

pair_one <- function(P) {
  fv <- P[, 1]; dy <- P[, 2]; cx <- P[, 3]
  if (any(is.na(cx)) || any(is.na(fv)) || any(is.na(dy)) || sum(cx == 0) != 10 || sum(cx == 1) != 10) return(NULL)
  S <- which(cx == 0); C <- which(cx == 1)
  S <- S[order(dy[S], fv[S])]
  used <- integer(0); out <- matrix(NA_integer_, 10, 2)
  for (j in seq_along(S)) {
    s <- S[j]; cand <- setdiff(C[dy[C] == dy[s]], used); if (!length(cand)) cand <- setdiff(C, used)
    cc <- cand[which.min(abs(fv[cand] - fv[s]))]; used <- c(used, cc); out[j, ] <- c(s, cc)
  }
  out
}

task_pairs <- function(d) {
  n <- nrow(d); tcols <- paste0("T", 1:20)
  def <- cbind(1:10, 11:20)
  if (!all(tcols %in% names(d))) {
    cat("DEVIATION: no T1..T20 task texts; simple task k paired with complex task k+10\n")
    return(rep(list(def), n))
  }
  TT <- matrix(sapply(tcols, function(cn) cl(d[[cn]])), nrow = n)
  ut <- unique(na.omit(as.vector(TT)))
  cat("Task texts: distinct", length(ut), "; T1 distinct", length(unique(na.omit(TT[, 1]))), "; e.g.",
      paste(short(head(ut, 2), 90), collapse = " || "), "\n")
  PP <- if (length(ut)) t(vapply(ut, parse1, numeric(3))) else NULL
  sig <- apply(TT, 1, paste, collapse = "|")
  us <- unique(sig); res <- vector("list", length(us))
  for (u in seq_along(us)) {
    i <- match(us[u], sig); idx <- match(TT[i, ], ut)
    res[u] <- list(if (is.null(PP) || any(is.na(idx))) NULL else pair_one(PP[idx, , drop = FALSE]))
  }
  ok <- !vapply(res, is.null, logical(1))
  cat("Task-text signatures:", length(us), "parsed into 10 pairs:", sum(ok), "\n")
  if (any(ok)) {
    tab <- table(sig[sig %in% us[ok]])
    fallback <- res[[match(names(which.max(tab)), us)]]
  } else {
    fallback <- def
    cat("DEVIATION: task texts unparseable; simple task k paired with complex task k+10\n")
  }
  cat("Pairs (simple-complex, most common):", paste(sprintf("%d-%d", fallback[, 1], fallback[, 2]), collapse = " "), "\n")
  lapply(sig, function(s) { r <- res[[match(s, us)]]; if (is.null(r)) fallback else r })
}

# ---------------------------------------------------------------- arms
assign_arms <- function(d, exp) {
  nm <- names(d)
  if (!("treatment" %in% nm)) stop("no treatment column")
  tr <- cl(d$treatment)
  cat("batch x treatment:\n"); print(table(d$batch_file, tr, useNA = "ifany"))
  for (cn in intersect(c("codeWC", "codeWT", "code treat"), nm)) {
    cat("'", cn, "' non-missing by treatment:\n", sep = ""); print(table(tr, nonmissing = !is.na(cl(d[[cn]]))))
  }
  arm <- ifelse(tr %in% "0", "Control", ifelse(tr %in% "1", "Treatment", NA))
  if (exp == "A" && "code treat" %in% nm) {
    ct <- tolower(cl(d[["code treat"]]))
    cat("batch x has 'code treat':\n"); print(table(d$batch_file, has_code = !is.na(ct)))
    g <- ifelse(grepl("^\\W*int", ct), "grpI", ifelse(grepl("^\\W*comp", ct), "grpC",
           ifelse(grepl("int", ct), "grpI", ifelse(grepl("comp|ound", ct), "grpC", "grpOther"))))
    arm[!is.na(ct)] <- g[!is.na(ct)]
    arm[arm %in% "grpOther"] <- NA
    cat("DEVIATION: Experiment A: subjects with a 'code treat' entry are the Substance-Only/Rhetoric-Only arms (split by code word interest/compounding); others are Control (treatment=0) / Treatment (treatment=1)\n")
  }
  print(table(arm, useNA = "ifany"))
  arm
}

# answer keys: compound items keyed by Treatment-arm modal answer, control-module items by Control-arm modal answer
fit_keys <- function(A, arm) {
  keys <- character(10); dir <- numeric(10)
  sh <- function(x, v) mean(x == v, na.rm = TRUE)
  for (i in 1:10) {
    xT <- A[which(arm == "Treatment"), i]; xC <- A[which(arm == "Control"), i]
    mT <- names(which.max(table(xT))); mC <- names(which.max(table(xC)))
    d1 <- sh(xT, mT) - sh(xC, mT); d2 <- sh(xC, mC) - sh(xT, mC)
    if (d1 >= d2) { keys[i] <- mT; dir[i] <- d1 } else { keys[i] <- mC; dir[i] <- -d2 }
  }
  comp <- sort(order(dir, decreasing = TRUE)[1:5])
  cat("Item keys:", paste(sprintf("t%d=%s(%+.2f)", 1:10, short(keys, 8), dir), collapse = " "), "\n")
  cat("Compound-interest items:", paste(comp, collapse = ","), "\n")
  I <- sapply(1:10, function(i) ifelse(is.na(A[, i]), 0, as.numeric(A[, i] == keys[i])))
  I <- matrix(I, nrow = nrow(A))
  list(comp = rowSums(I[, comp, drop = FALSE]), ctrl = rowSums(I[, setdiff(1:10, comp), drop = FALSE]))
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
  cat(sprintf("==== Exp %s: %d rows, %d cols ====\n", exp, nrow(d), ncol(d)))

  tc <- paste0("test", 1:10)
  if (!all(tc %in% nm)) stop("test1..test10 not all present")
  A <- matrix(sapply(tc, function(cn) cl(d[[cn]])), nrow = nrow(d), dimnames = list(NULL, tc))
  nans <- rowSums(!is.na(A))
  k0 <- nans > 0
  d <- d[k0, , drop = FALSE]; A <- A[k0, , drop = FALSE]
  target <- if (exp == "A") 504 else 401
  cat("Rows with any test answer:", nrow(d), "(paper", target, ")\n")
  if ("Status" %in% names(d)) {
    st <- cl(d$Status); cat("Status values:", paste(names(table(st, useNA = "ifany")), table(st, useNA = "ifany"), sep = ":", collapse = " "), "\n")
    prev <- st %in% c("1", "Survey Preview", "Survey Test", "Spam")
    if (any(prev) && nrow(d) > target) {
      d <- d[!prev, , drop = FALSE]; A <- A[!prev, , drop = FALSE]
      cat("Dropped", sum(prev), "preview/test responses\n")
    }
  }
  if (nrow(d) > target && "amt_id" %in% names(d)) {
    id <- cl(d$amt_id); dup <- !is.na(id) & duplicated(id)
    cat("Duplicated amt_id rows:", sum(dup), "\n")
    if (any(dup)) {
      d <- d[!dup, , drop = FALSE]; A <- A[!dup, , drop = FALSE]
      cat("DEVIATION: dropped repeat submissions by the same MTurk worker id (keeping first)\n")
    }
  }
  cat("Subjects:", nrow(d), "\n")

  arm <- assign_arms(d, exp)
  sc <- fit_keys(A, arm)
  d$score_comp <- sc$comp; d$score_ctrl <- sc$ctrl
  if (any(arm %in% c("grpI", "grpC"))) {
    mI <- mean(sc$comp[arm %in% "grpI"]); mC <- mean(sc$comp[arm %in% "grpC"])
    cat(sprintf("Compound score: code-word 'interest' group %.3f, 'compounding' group %.3f; Control %.3f Treatment %.3f\n",
                mI, mC, mean(sc$comp[arm %in% "Control"]), mean(sc$comp[arm %in% "Treatment"])))
    subs <- if (mI >= mC) "grpI" else "grpC"
    arm[arm %in% subs] <- "Substance"
    arm[arm %in% setdiff(c("grpI", "grpC"), subs)] <- "Rhetoric"
    cat("DEVIATION: Substance-Only = code-word group with higher compound-interest test score; the other = Rhetoric-Only\n")
  }
  d$arm <- arm
  for (scc in grep("^SC[0-9]", names(d), value = TRUE)) {
    cat(sprintf("cor with %s: comp %.3f ctrl %.3f total %.3f\n", scc,
                suppressWarnings(cor(sc$comp, num(d[[scc]]), use = "pairwise.complete.obs")),
                suppressWarnings(cor(sc$ctrl, num(d[[scc]]), use = "pairwise.complete.obs")),
                suppressWarnings(cor(sc$comp + sc$ctrl, num(d[[scc]]), use = "pairwise.complete.obs"))))
  }

  # valuations from price lists
  dec <- tryCatch(decode_impl(d), error = function(e) { cat("decode error:", conditionMessage(e), "\n"); NULL })
  ina <- !is.na(d$arm)
  expected <- if (exp == "A") 49 / 504 else 53 / 401
  multi <- NULL; exinfo <- "none"
  if (!is.null(dec)) {
    ms <- rowSums(dec$SW >= 2, na.rm = TRUE) > 0
    shm <- mean(ms[ina])
    cat(sprintf("Multiple-switcher share (any list with >=2 switches): %.3f (%d; paper %.3f)\n", shm, sum(ms[ina]), expected))
    if (shm >= 0.03 && shm <= 0.30) { multi <- ms; exinfo <- sprintf("switch-count %.3f", shm) }
  }
  if (is.null(multi)) { cat("No multiple-switcher exclusion applied\n"); multi <- rep(FALSE, nrow(d)) }
  keep <- !multi & ina
  s <- d[keep, , drop = FALSE]
  s$sid <- seq_len(nrow(s))
  at <- table(s$arm)
  cat("Analysis sample N =", nrow(s), ":", paste(names(at), as.integer(at), sep = "=", collapse = " "), "\n")

  ct <- s[s$arm %in% c("Control", "Treatment"), , drop = FALSE]
  m4c <- arm_reg(ct, "score_comp", c("Control", "Treatment"))
  m4k <- arm_reg(ct, "score_ctrl", c("Control", "Treatment"))
  dfun <- function(m) {
    b <- coef(m); V <- vcov(m)
    c(est = unname(b["d_Treatment"] - b["d_Control"]),
      se = unname(sqrt(V["d_Treatment", "d_Treatment"] + V["d_Control", "d_Control"] - 2 * V["d_Treatment", "d_Control"])))
  }
  r4c <- dfun(m4c); r4k <- dfun(m4k)
  out$t4_comp <- r4c["est"]; out$t4_ctrl <- r4k["est"]; out$n_t4 <- nobs(m4c)

  out$t7 <- NULL; dcs <- ""
  if (!is.null(dec)) tryCatch({
    prs <- task_pairs(d)[keep]
    RF <- dec$RF[keep, , drop = FALSE]
    ns <- nrow(s)
    vs <- t(vapply(seq_len(ns), function(i) RF[i, prs[[i]][, 1]], numeric(10)))
    vc <- t(vapply(seq_len(ns), function(i) RF[i, prs[[i]][, 2]], numeric(10)))
    cat(sprintf("Mean valuation index: simple %.1f, complex %.1f\n", mean(vs, na.rm = TRUE), mean(vc, na.rm = TRUE)))
    dcm <- -abs(vc - vs)
    dcl <- data.frame(sid = rep(s$sid, 10), arm = rep(s$arm, 10), pair = rep(1:10, each = ns), dc = as.vector(dcm))
    comp <- tapply(!is.na(dcl$dc), dcl$sid, all)
    dcl <- dcl[dcl$sid %in% as.integer(names(comp)[comp]), , drop = FALSE]
    arms_present <- intersect(c("Control", "Treatment", "Substance", "Rhetoric"), unique(dcl$arm))
    m7 <- arm_reg(dcl, "dc", arms_present, cluster = ~sid)
    out$t7 <- coef(m7); out$n7 <- nobs(m7)
    dcs <- paste(sprintf("%s=%.2f", sub("d_", "", names(coef(m7))), coef(m7)), collapse = " ")
  }, error = function(e) cat("DC stage error:", conditionMessage(e), "\n"))

  out$summ <- sprintf("[%s] N=%d excl=%s | T4 comp %.3f (%.3f) ctrl %.3f N=%d | DC %s N=%s\n",
                      exp, nrow(s), exinfo, r4c["est"], r4c["se"], r4k["est"], nobs(m4c), dcs,
                      if (is.null(out$n7)) "NA" else out$n7)
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

cat("\n==== SUMMARY ====\n")
if (!is.null(resA)) cat(resA$summ)
if (!is.null(resB)) cat(resB$summ)
for (n in names(results)) cat(sprintf("RESULT:%s=%s\n", n, format(results[[n]], digits = 10)))
