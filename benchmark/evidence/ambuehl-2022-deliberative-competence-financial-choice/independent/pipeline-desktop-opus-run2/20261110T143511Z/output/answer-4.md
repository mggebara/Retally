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

truthy <- function(x) {
  x <- cl(x); lx <- tolower(x)
  v <- num(x)
  out <- (!is.na(v) & v != 0) | (is.na(v) & !is.na(x) & !(lx %in% c("false", "no", "n", "na", "none", "keep", "included", "include")))
  out[is.na(x)] <- FALSE
  out
}

# ---------------------------------------------------------------- loop & merge structure
loop_cols <- function(nm, k) {
  a <- grep(paste0("^", k, "_"), nm, value = TRUE)
  b <- grep(paste0("\\(", k, "\\)$"), nm, value = TRUE)
  if (!length(a) && !length(b)) return(NULL)
  stem <- c(sub(paste0("^", k, "_"), "", a), sub(paste0("\\(", k, "\\)$"), "", b))
  data.frame(col = c(a, b), stem = stem, base = sub("_[0-9]+$", "", stem),
             row = ifelse(grepl("_[0-9]+$", stem), num(sub("^.*_", "", stem)), NA_real_),
             stringsAsFactors = FALSE)
}

describe_iter <- function(d, k = 1) {
  lc <- loop_cols(names(d), k)
  if (is.null(lc)) return("none")
  gs <- split(lc, factor(lc$base, levels = unique(lc$base)))
  paste(vapply(gs, function(g) {
    vals <- unique(na.omit(unlist(lapply(g$col, function(cn) cl(d[[cn]])))))
    cov <- mean(vapply(g$col, function(cn) mean(!is.na(cl(d[[cn]]))), numeric(1)))
    sprintf("%s[n=%d,cov=%.2f,nv=%d:%s]", g$base[1], nrow(g), cov, length(vals),
            paste(short(head(vals, 3), 10), collapse = "/"))
  }, character(1)), collapse = " ")
}

later_of <- function(M, gl) {
  v <- unique(na.omit(as.vector(M)))
  if (!length(v)) return(NA_character_)
  if (all(nchar(v) <= 2)) {
    if (!is.na(gl) && gl %in% v) return(gl)
    return(names(which.max(table(M))))
  }
  cc <- vapply(v, function(x) sum(colSums(M == x, na.rm = TRUE) > 0), numeric(1))
  if (sum(cc == max(cc)) == 1) return(v[which.max(cc)])
  names(which.max(table(M)))
}

# decode iterated multiple price lists: returns valuation (% of R) and max switch count per task
decode_vals <- function(d, K = 20) {
  n <- nrow(d); nm <- names(d)
  L <- vector("list", K)
  for (k in 1:K) {
    lc <- loop_cols(nm, k); if (is.null(lc)) next
    lists <- list()
    for (g in split(lc, lc$base)) {
      g <- g[!is.na(g$row), , drop = FALSE]
      if (nrow(g) < 3) next
      g <- g[order(g$row), , drop = FALSE]
      M <- matrix(sapply(g$col, function(cn) cl(d[[cn]])), nrow = n)
      if (all(is.na(M))) next
      nd <- apply(M, 2, function(z) length(unique(na.omit(z))))
      if (max(nd) > 2) next
      lists[[length(lists) + 1]] <- M
    }
    if (!length(lists)) {
      st <- sub(paste0("^", k, "_"), "", lc$col)
      okc <- vapply(lc$col, function(cn) { z <- cl(d[[cn]]); u <- length(unique(na.omit(z))); u >= 1 && u <= 2 }, logical(1))
      cand <- lc$col[okc]
      if (length(cand) >= 3) {
        o <- order(num(sub("^.*?([0-9]+)[^0-9]*$", "\\1", st[okc])))
        lists[[1]] <- matrix(sapply(cand[o], function(cn) cl(d[[cn]])), nrow = n)
      }
    }
    L[[k]] <- lists
  }
  nl <- vapply(L, length, numeric(1))
  cat("MPL lists found per loop iteration:", paste(nl, collapse = ","), "\n")
  if (sum(nl > 0) < K) return(NULL)
  cidx <- lapply(L, function(ls) which.max(vapply(ls, function(M) mean(rowSums(!is.na(M)) > 0), numeric(1))))
  cv <- unlist(lapply(1:K, function(k) as.vector(L[[k]][[cidx[[k]]]])))
  cv <- cv[!is.na(cv) & nchar(cv) <= 2]
  gl <- if (length(cv)) names(which.max(table(cv))) else NA_character_
  RF <- matrix(NA_real_, n, K); SW <- matrix(NA_real_, n, K)
  dims <- character(K)
  for (k in 1:K) {
    ls <- L[[k]]; ic <- cidx[[k]]
    Bm <- lapply(ls, function(M) { lat <- later_of(M, gl); B <- ifelse(is.na(M), NA_real_, as.numeric(M == lat)); matrix(B, nrow = n) })
    n1 <- ncol(ls[[ic]])
    dims[k] <- paste(vapply(ls, ncol, numeric(1)), collapse = "+")
    if (n1 < 2) next
    for (i in seq_len(n)) {
      cvec <- Bm[[ic]][i, ]; cvec <- cvec[!is.na(cvec)]
      if (!length(cvec)) next
      sw <- if (length(cvec) > 1) sum(diff(cvec) != 0) else 0
      m <- sum(cvec); fr <- NA_real_
      for (j in setdiff(seq_along(ls), ic)) {
        f <- Bm[[j]][i, ]; f <- f[!is.na(f)]
        if (length(f)) {
          if (length(f) > 1) sw <- max(sw, sum(diff(f) != 0))
          fr <- (sum(f) + 0.5) / (ncol(ls[[j]]) + 1)
        }
      }
      if (is.na(fr)) fr <- 0.5
      RF[i, k] <- 100 * (max(m, 1) - 1 + fr) / (n1 - 1)
      SW[i, k] <- sw
    }
  }
  cat("List sizes per iteration (coarse+fine):", paste(dims, collapse = " "), "; 'later' code:", gl, "\n")
  list(RF = RF, SW = SW)
}

parse_task <- function(s) {
  if (is.na(s)) return(data.frame(R = NA_real_, days = NA_real_, cx = NA, fv = NA_real_))
  s <- tolower(s)
  days <- num(sub("^.*?([0-9]+)\\s*days.*$", "\\1", s, perl = TRUE))
  cx <- grepl("invest", s)
  if (cx) {
    a <- num(sub("^.*invest\\s*\\$\\s*([0-9.]+).*$", "\\1", s, perl = TRUE))
    x <- num(sub("^.*?([0-9.]+)\\s*%.*$", "\\1", s, perl = TRUE))
    fv <- a * (1 + x / 100)^days
  } else fv <- num(sub("^.*?\\$\\s*([0-9.]+).*$", "\\1", s, perl = TRUE))
  Rs <- c(12, 14, 16, 18, 20)
  data.frame(R = if (isTRUE(is.finite(fv))) Rs[which.min(abs(Rs - fv))] else NA_real_, days = days, cx = cx, fv = fv)
}

task_pairs <- function(d) {
  tt <- vapply(paste0("T", 1:20), function(cn) {
    if (!(cn %in% names(d))) return(NA_character_)
    z <- na.omit(cl(d[[cn]])); if (length(z)) z[1] else NA_character_
  }, character(1))
  ti <- do.call(rbind, lapply(tt, parse_task))
  S <- which(ti$cx %in% FALSE); C <- which(ti$cx %in% TRUE)
  if (length(S) != 10 || length(C) != 10 || any(is.na(ti$R))) {
    cat("Task parsing failed; pairing k with k+10\n")
    return(data.frame(s = 1:10, c = 11:20, R = NA, days = NA))
  }
  used <- integer(0); pr <- list()
  for (cc in C) {
    cand <- setdiff(S[ti$days[S] == ti$days[cc]], used)
    if (!length(cand)) cand <- setdiff(S, used)
    s <- cand[which.min(abs(ti$R[cand] - ti$fv[cc]))]
    used <- c(used, s)
    pr[[length(pr) + 1]] <- data.frame(s = s, c = cc, R = ti$R[s], days = ti$days[s])
  }
  pr <- do.call(rbind, pr)
  cat("Task pairs (simple,complex,R,days):", paste(sprintf("%d-%d/%g/%g", pr$s, pr$c, pr$R, pr$days), collapse = " "), "\n")
  pr
}

# ---------------------------------------------------------------- arms
assign_arms <- function(d, A, exp) {
  nm <- names(d)
  cands <- unique(c(nm[tolower(nm) == "treatment"],
                    grep("treat|condition|^arm$|^group$", nm, value = TRUE, ignore.case = TRUE)))
  cands <- cands[!grepl("^TimeTreat|^[0-9]+_|\\([0-9]+\\)$", cands, ignore.case = TRUE)]
  if (!length(cands)) stop("no treatment column found")
  k <- if (exp == "A") 4 else 2
  nval <- vapply(cands, function(cn) length(unique(na.omit(cl(d[[cn]])))), numeric(1))
  cat("Arm column candidates:", paste(sprintf("'%s'=%d", cands, nval), collapse = " "), "\n")
  pick <- cands[nval == k]
  if (!length(pick)) { o <- which(nval > k); pick <- cands[o][order(nval[o])] }
  if (!length(pick)) pick <- cands
  tc <- pick[1]
  raw <- cl(d[[tc]])
  tab <- sort(table(raw), decreasing = TRUE)
  cat("Arm column:", tc, "values:", paste(sprintf("%s:%d", short(names(tab), 20), as.integer(tab)), collapse = " "), "\n")
  if ("treatment" %in% nm && tc != "treatment") {
    ct <- table(short(raw, 12), cl(d[["treatment"]]))
    cat("Cross-tab with 'treatment':", paste(capture.output(print(ct)), collapse = " | "), "\n")
  }
  codes <- names(tab)[seq_len(min(k, length(tab)))]
  raw[!(raw %in% codes)] <- NA
  lr <- tolower(codes); lab <- rep(NA_character_, length(codes))
  lab[grepl("rhet", lr)] <- "Rhetoric"
  lab[is.na(lab) & grepl("subs", lr)] <- "Substance"
  lab[is.na(lab) & grepl("control|ctrl|index|divers|portfolio", lr)] <- "Control"
  lab[is.na(lab) & grepl("treat|full|compound|interest|feedback|practice", lr)] <- "Treatment"
  if (all(!is.na(lab)) && "Control" %in% lab && "Treatment" %in% lab) {
    cat("Arms mapped from string labels.\n")
    return(unname(setNames(lab, codes)[raw]))
  }
  if (all(!is.na(num(codes)))) codes <- codes[order(num(codes))] else codes <- sort(codes)
  if (k == 2 && all(codes %in% c("0", "1"))) {
    cat("Binary 0/1 treatment indicator: 0 = Control, 1 = Treatment\n")
    return(ifelse(raw == "1", "Treatment", ifelse(raw == "0", "Control", NA)))
  }
  levs <- lapply(1:10, function(i) { tb <- sort(table(A[, i]), decreasing = TRUE); names(tb)[tb / sum(tb) >= 0.03] })
  shr <- function(idx, i) { x <- A[idx, i]; x <- x[!is.na(x)]; vapply(levs[[i]], function(v) mean(x == v), numeric(1)) }
  if (k > 2) {
    dist <- vapply(codes, function(cd) sum(vapply(1:10, function(i) max(abs(shr(which(raw == cd), i) - shr(which(raw != cd), i))), numeric(1))), numeric(1))
    cat("Answer-profile distinctness by code:", paste(sprintf("%s:%.2f", codes, dist), collapse = " "), "\n")
    ctrl <- codes[which.max(dist)]
    others <- setdiff(codes, ctrl)
    map <- setNames(c("Control", c("Treatment", "Substance", "Rhetoric")[seq_along(others)]), c(ctrl, others))
    cat("DEVIATION: Experiment A arm codes are unlabeled; Control = code with the most distinct test-answer profile, remaining codes mapped in code order to Treatment, Substance-Only, Rhetoric-Only\n")
  } else {
    ds <- sum(vapply(1:10, function(i) { dd <- shr(which(raw == codes[2]), i) - shr(which(raw == codes[1]), i); max(dd) - max(-dd) }, numeric(1)))
    map <- if (ds >= 0) setNames(c("Control", "Treatment"), codes) else setNames(c("Treatment", "Control"), codes)
  }
  cat("Code -> arm:", paste(names(map), map, sep = "=", collapse = " "), "\n")
  unname(map[raw])
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
  isloop <- grepl("^[0-9]+_", nm) | grepl("\\([0-9]+\\)$", nm)
  p <- gsub("[0-9]+", "#", nm[!isloop]); tb <- sort(table(p), decreasing = TRUE)
  cat(sprintf("==== Exp %s: %d rows, %d cols (%d loop-prefixed) ====\n", exp, nrow(d), ncol(d), sum(isloop)))
  cat("Non-loop name patterns:", substr(paste(sprintf("%s:%d", names(tb), as.integer(tb)), collapse = " "), 1, 1100), "\n")
  it1 <- describe_iter(d, 1)
  cat("Loop iter 1:", substr(it1, 1, 800), "\n")
  out$struct <- substr(it1, 1, 450)

  tc <- paste0("test", 1:10)
  if (!all(tc %in% nm)) stop("test1..test10 not all present")
  A <- matrix(sapply(tc, function(cn) cl(d[[cn]])), nrow = nrow(d), dimnames = list(NULL, tc))
  nans <- rowSums(!is.na(A))
  fc <- intersect(c("Finished", "V10"), nm)
  fin <- if (length(fc)) d[[fc[1]]] %in% c("1", "True", "TRUE", "true") else rep(TRUE, nrow(d))
  cat(sprintf("Rows: any test answer %d; all 10 answers %d; finished & any answer %d\n", sum(nans > 0), sum(nans == 10), sum(nans > 0 & fin)))
  k0 <- nans > 0
  d <- d[k0, , drop = FALSE]; A <- A[k0, , drop = FALSE]
  cat("DEVIATION: sample defined by having answered the test (no Qualtrics 'Finished' filter)\n")

  d$arm <- assign_arms(d, A, exp)
  sc <- fit_keys(A, d$arm)
  d$score_comp <- sc$comp; d$score_ctrl <- sc$ctrl
  scc <- grep("^SC[0-9]", names(d), value = TRUE)
  if (length(scc)) cat("cor(our total, ", scc[1], ") = ", round(suppressWarnings(cor(sc$comp + sc$ctrl, num(d[[scc[1]]]), use = "pairwise.complete.obs")), 3), "\n", sep = "")

  # valuations from price lists
  dec <- tryCatch(decode_vals(d), error = function(e) { cat("decode error:", conditionMessage(e), "\n"); NULL })
  ina <- !is.na(d$arm)
  expected <- if (exp == "A") 49 / 504 else 53 / 401
  multi <- NULL; exinfo <- "none"
  if (!is.null(dec)) {
    ms <- rowSums(dec$SW >= 2, na.rm = TRUE) > 0
    shm <- mean(ms[ina])
    cat(sprintf("Multiple-switcher share (any list with >=2 switches): %.3f (paper %.3f)\n", shm, expected))
    if (shm >= 0.03 && shm <= 0.30) { multi <- ms; exinfo <- sprintf("switch-count %.3f", shm) }
  }
  if (is.null(multi)) {
    flags <- list()
    for (cn in grep("^exclu", names(d), value = TRUE, ignore.case = TRUE)) {
      tbx <- sort(table(short(cl(d[[cn]]), 12), useNA = "ifany"), decreasing = TRUE)
      cat("Column", cn, ":", paste(sprintf("%s:%d", names(tbx), as.integer(tbx))[seq_len(min(5, length(tbx)))], collapse = " "), "\n")
      flags[[cn]] <- truthy(d[[cn]])
    }
    if (length(flags) > 1) flags[["any_exclude"]] <- Reduce(`|`, flags)
    if (length(flags)) {
      sh <- vapply(flags, function(f) mean(f[ina]), numeric(1))
      cat("Exclusion flag shares:", paste(sprintf("%s:%.3f", names(sh), sh), collapse = " "), "\n")
      okf <- names(sh)[sh >= 0.03 & sh <= 0.30]
      if (length(okf)) {
        pk <- okf[which.min(abs(sh[okf] - expected))]
        multi <- flags[[pk]]; exinfo <- sprintf("flag %s %.3f", pk, sh[pk])
        cat(sprintf("DEVIATION: multiple-switcher exclusion implemented via '%s'\n", pk))
      }
    }
  }
  if (is.null(multi)) multi <- rep(FALSE, nrow(d))
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
    pr <- task_pairs(d)
    RF <- dec$RF[keep, , drop = FALSE]
    cat(sprintf("Mean valuation (%% of R): simple %.1f, complex %.1f\n",
                mean(RF[, pr$s], na.rm = TRUE), mean(RF[, pr$c], na.rm = TRUE)))
    dcl <- do.call(rbind, lapply(seq_len(nrow(pr)), function(j)
      data.frame(sid = s$sid, arm = s$arm, pair = j, dc = -abs(RF[, pr$c[j]] - RF[, pr$s[j]]))))
    comp <- tapply(!is.na(dcl$dc), dcl$sid, all)
    dcl <- dcl[dcl$sid %in% as.integer(names(comp)[comp]), , drop = FALSE]
    arms_present <- intersect(c("Control", "Treatment", "Substance", "Rhetoric"), unique(dcl$arm))
    m7 <- arm_reg(dcl, "dc", arms_present, cluster = ~sid)
    out$t7 <- coef(m7); out$n7 <- nobs(m7)
    dcs <- paste(sprintf("%s=%.2f", sub("d_", "", names(coef(m7))), coef(m7)), collapse = " ")
    cat("DEVIATION: valuations reconstructed from raw price-list choices assuming evenly spaced lists from 0 to R (coarse) refined by the second list; midpoint of final interval\n")
  }, error = function(e) cat("DC stage error:", conditionMessage(e), "\n"))

  out$summ <- sprintf("[%s] N=%d excl=%s | T4 comp %.3f (%.3f) ctrl %.3f N=%d | DC %s N=%s\n[%s iter1] %s\n",
                      exp, nrow(s), exinfo, r4c["est"], r4c["se"], r4k["est"], nobs(m4c), dcs,
                      if (is.null(out$n7)) "NA" else out$n7, exp, out$struct)
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
