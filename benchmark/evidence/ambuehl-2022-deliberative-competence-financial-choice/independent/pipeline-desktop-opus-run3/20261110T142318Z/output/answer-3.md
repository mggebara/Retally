suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice.script-free"

num <- function(x) suppressWarnings(as.numeric(gsub("[,$%]", "", trimws(as.character(x)))))

# valuations may be interval-coded text (e.g. "12.20 - 12.40"): take midpoint of all numbers found
numT <- function(x) {
  x <- as.character(x)
  out <- rep(NA_real_, length(x))
  ok <- !is.na(x) & trimws(x) != ""
  if (any(ok)) {
    m <- regmatches(x[ok], gregexpr("[0-9]*\\.?[0-9]+", x[ok]))
    out[ok] <- vapply(m, function(z) if (length(z) == 0) NA_real_ else mean(suppressWarnings(as.numeric(z))), numeric(1))
  }
  out
}

read_one <- function(f) {
  d <- suppressMessages(readr::read_csv(file.path(base, f), col_types = cols(.default = col_character()),
                       show_col_types = FALSE, progress = FALSE, name_repair = "unique"))
  nm <- names(d)
  nm <- gsub("﻿", "", nm, fixed = TRUE)
  nm <- gsub("^ï»¿", "", nm)
  nm <- trimws(nm)
  names(d) <- nm
  d <- d[, !grepl("^\\.\\.\\.[0-9]+$", names(d)), drop = FALSE]
  d$batch_file <- f
  d$row_in_file <- seq_len(nrow(d))
  d
}

results <- list()
add_res <- function(name, val) {
  if (length(val) == 1 && !is.na(val) && is.finite(val)) results[[name]] <<- as.numeric(val)
}

colmat <- function(d, cols) {
  m <- matrix(unlist(lapply(cols, function(cc) num(d[[cc]]))), nrow = nrow(d))
  colnames(m) <- cols
  m
}

# ------------------------------------------------------------------
# compact diagnostics
# ------------------------------------------------------------------
DIAG <- new.env()
assign("A", character(0), envir = DIAG)
assign("B", character(0), envir = DIAG)
dlog <- function(key, ...) assign(key, c(get(key, envir = DIAG), paste0(...)), envir = DIAG)
flush_diag <- function(key, maxch = 2700) {
  s <- paste(get(key, envir = DIAG), collapse = "\n")
  if (nchar(s, type = "bytes") > maxch) s <- paste0(substr(s, 1, maxch), " [trunc]")
  cat(s, "\n")
}
tr_s <- function(x, n = 22) {
  x <- iconv(as.character(x), "", "ASCII", sub = "?")
  x[is.na(x)] <- "<NA>"
  x <- gsub("[[:space:]]+", " ", x)
  ifelse(nchar(x) > n, paste0(substr(x, 1, n), "~"), x)
}
tabstr <- function(v, k = 8) {
  t <- sort(table(tr_s(v)), decreasing = TRUE)
  t <- head(t, k)
  paste(paste0("[", names(t), "]:", as.integer(t)), collapse = " ")
}
compress_names <- function(nm) {
  nm <- iconv(nm, "", "ASCII", sub = "?")
  stem <- sub("[0-9]+$", "#", nm)
  u <- unique(stem)
  cnt <- as.integer(table(factor(stem, levels = u)))
  paste(ifelse(cnt > 1, paste0(u, "x", cnt), u), collapse = " ")
}

# ------------------------------------------------------------------
# Generic processing of one experiment
# ------------------------------------------------------------------
analyze <- function(d, key, want) {
  nmv <- names(d)
  dlog(key, "== ", key, " rows=", nrow(d), " cols=", ncol(d))
  keep <- rep(TRUE, nrow(d))
  if ("Status" %in% nmv) {
    v <- tolower(trimws(as.character(d$Status)))
    dlog(key, "Status: ", tabstr(v, 5))
    keep <- keep & !(v %in% c("1", "survey preview", "8", "spam"))
  }
  if ("Finished" %in% nmv) {
    v <- tolower(trimws(as.character(d$Finished)))
    dlog(key, "Finished: ", tabstr(v, 5))
    fin <- v %in% c("1", "true")
    if (sum(fin) > 0) keep <- keep & fin
  }
  dlog(key, "after Status/Finished filter: ", sum(keep))
  wid <- grep("workerid|worker_id|mturk|^MID$|ResponseI[dD]", nmv, ignore.case = TRUE, value = TRUE)
  for (cc in head(wid, 3)) {
    v <- trimws(as.character(d[[cc]]))
    v2 <- v[keep & !is.na(v) & v != ""]
    dlog(key, "id col ", cc, ": nonempty=", length(v2), " unique=", length(unique(v2)))
  }

  # ---- scores ----
  scn <- grep("^SC[0-9]|score|correct", nmv, ignore.case = TRUE, value = TRUE)
  validS <- NULL
  if (length(scn) > 0) {
    Sall <- colmat(d, scn)
    Sall <- Sall[, colSums(!is.na(Sall[keep, , drop = FALSE])) > 0, drop = FALSE]
    if (ncol(Sall) > 0) {
      for (j in head(seq_len(ncol(Sall)), 10)) {
        z <- Sall[keep, j]
        dlog(key, "score ", colnames(Sall)[j], ": n=", sum(!is.na(z)), " mean=", round(mean(z, na.rm = TRUE), 3),
             " min=", min(z, na.rm = TRUE), " max=", max(z, na.rm = TRUE))
      }
      okc <- apply(Sall[keep, , drop = FALSE], 2, function(z) {
        z <- z[!is.na(z)]
        length(z) > 0 && min(z) >= 0 && max(z) <= 5 && max(z) >= 1 && mean(z) >= 0.3
      })
      validS <- Sall[, okc, drop = FALSE]
      if (ncol(validS) == 0) validS <- NULL
    }
  }
  sc_ok <- if (!is.null(validS)) rowSums(!is.na(validS)) > 0 else rep(TRUE, nrow(d))
  base_rows <- keep & sc_ok
  dlog(key, "valid score cols (0..5): ", paste(colnames(validS), collapse = ","), "; base rows=", sum(base_rows))

  # ---- arms ----
  nu <- function(cc, rows) { v <- trimws(as.character(d[[cc]][rows])); v <- v[!is.na(v) & v != ""]; length(unique(v)) }
  nne <- function(cc, rows) { v <- trimws(as.character(d[[cc]][rows])); sum(!is.na(v) & v != "") }
  cand <- grep("treat|cond|^arm|arm$|group|subst|rhet|video|version|_DO$", nmv, ignore.case = TRUE, value = TRUE)
  cand <- cand[!grepl("^SC|switch|^T[0-9]+$|batch_file", cand, ignore.case = TRUE)]
  if (length(cand) > 0) {
    cand <- cand[vapply(cand, function(cc) { k <- nu(cc, base_rows); k >= 2 && k <= 8 && nne(cc, base_rows) >= 0.5 * sum(base_rows) }, logical(1))]
  }
  for (cc in head(cand, 8)) dlog(key, "arm-cand ", cc, ": ", tabstr(d[[cc]][base_rows], 6))
  if (length(cand) == 0) stop("no treatment column")
  trc <- cand[tolower(cand) == "treatment"]
  armkey <- NULL; src <- ""
  if (want == 4) {
    c4 <- cand[vapply(cand, function(cc) nu(cc, base_rows) == 4, logical(1))]
    if (length(c4) > 0) {
      c4 <- c4[order(!grepl("treat|cond", c4, ignore.case = TRUE))]
      armkey <- trimws(as.character(d[[c4[1]]])); src <- c4[1]
    } else if (length(trc) > 0) {
      bins <- setdiff(cand[vapply(cand, function(cc) nu(cc, base_rows) == 2, logical(1))], trc)
      bins <- bins[order(!grepl("subst|rhet|cond|group|version", bins, ignore.case = TRUE))]
      t0 <- trimws(as.character(d[[trc[1]]]))
      for (bb in bins) {
        b0 <- trimws(as.character(d[[bb]]))
        k <- ifelse(is.na(t0) | t0 == "" | is.na(b0) | b0 == "", NA, paste(t0, b0, sep = "|"))
        kk <- k[base_rows & !is.na(k)]
        if (length(unique(kk)) == 4 && min(table(kk)) >= 20) { armkey <- k; src <- paste(trc[1], bb, sep = " x "); break }
      }
    }
  }
  if (is.null(armkey)) {
    cc <- if (length(trc) > 0) trc[1] else cand[which.max(vapply(cand, function(c2) nne(c2, base_rows), numeric(1)))]
    armkey <- trimws(as.character(d[[cc]])); src <- cc
  }
  armkey[!is.na(armkey) & armkey == ""] <- NA
  arm_ok <- !is.na(armkey)
  dlog(key, "arm source: ", src)

  # ---- valuations ----
  tcols <- grep("^T[0-9]+$", nmv, value = TRUE)
  tcols <- tcols[order(as.integer(sub("^T", "", tcols)))]
  Tm <- NULL
  if (length(tcols) >= 20) {
    tcols <- tcols[1:20]
    raw1 <- trimws(as.character(d[[tcols[1]]][base_rows]))
    raw1 <- raw1[!is.na(raw1) & raw1 != ""]
    dlog(key, "T1 raw nonempty=", length(raw1), " sample: ", paste(tr_s(head(raw1, 3)), collapse = " | "))
    Tm <- matrix(unlist(lapply(tcols, function(cc) numT(d[[cc]]))), nrow = nrow(d))
    colnames(Tm) <- tcols
  }
  tcnt <- if (is.null(Tm)) rep(0, nrow(d)) else rowSums(!is.na(Tm))
  hasT <- any(tcnt[base_rows & arm_ok] == 20)

  # ---- exclusion of multiple switchers ----
  excl <- rep(FALSE, nrow(d)); exsrc <- "none"
  exn <- grep("excl|multi|incons|mono|nswitch|numswitch|switches", nmv, ignore.case = TRUE, value = TRUE)
  exn <- exn[!grepl("^switch[0-9]+$", exn, ignore.case = TRUE)]
  for (cc in head(exn, 6)) dlog(key, "excl-cand ", cc, ": ", tabstr(d[[cc]][base_rows], 6))
  for (cc in exn) {
    v <- tolower(trimws(as.character(d[[cc]])))
    x <- num(v)
    xb <- x[base_rows & !is.na(x)]
    if (length(xb) >= 0.5 * sum(base_rows) && length(unique(xb)) >= 2) {
      e <- if (grepl("nswitch|numswitch|switches", cc, ignore.case = TRUE)) x >= 2 else x > 0
      e[is.na(e)] <- FALSE
      excl <- e; exsrc <- cc; break
    }
    tx <- v %in% c("true", "yes", "t", "excluded", "exclude")
    if (any(tx[base_rows])) { excl <- tx; exsrc <- paste0(cc, "(text)"); break }
  }
  swc <- grep("^switch[0-9]+$", nmv, ignore.case = TRUE, value = TRUE)
  if (length(swc) > 0) {
    Sw <- colmat(d, swc)
    raw_sw <- do.call(cbind, lapply(swc, function(cc) trimws(as.character(d[[cc]]))))
    partial <- rowSums(is.na(Sw)) > 0 & rowSums(!is.na(Sw)) > 0
    nonnum <- rowSums(!is.na(raw_sw) & raw_sw != "" & is.na(Sw)) > 0
    dlog(key, "switch values pooled: ", tabstr(as.vector(Sw[base_rows & arm_ok, , drop = FALSE]), 14))
    dlog(key, "switch: partialNA rows=", sum(partial[base_rows & arm_ok]), " nonnumeric rows=", sum(nonnum[base_rows & arm_ok]),
         " any0 rows=", sum((rowSums(Sw == 0, na.rm = TRUE) > 0)[base_rows & arm_ok]))
    if (exsrc == "none") {
      mxsw <- suppressWarnings(max(Sw[base_rows, ], na.rm = TRUE))
      if (is.finite(mxsw) && mxsw <= 1) {
        excl <- rowSums(Sw == 1, na.rm = TRUE) > 0; exsrc <- "switch==1"
      } else if (sum(nonnum[base_rows & arm_ok]) > 0) {
        excl <- nonnum; exsrc <- "switch non-numeric"
      } else if (sum(partial[base_rows & arm_ok]) > 0) {
        excl <- partial; exsrc <- "switch partial NA"
      }
      if (exsrc != "none") {
        msg <- paste0("DEVIATION: Exp ", key, " multiple-switch flag inferred from switch columns (", exsrc, ") since no explicit indicator found\n")
        cat(msg); dlog(key, trimws(msg))
      }
    }
  }
  excl[is.na(excl)] <- FALSE

  final <- base_rows & arm_ok & !excl
  if (hasT) final <- final & tcnt == 20
  dlog(key, "exclusion source: ", exsrc, "; excluded among base&arm=", sum(excl[base_rows & arm_ok]),
       "; hasT=", hasT, "; final=", sum(final))
  if (sum(final) == 0) stop("no rows kept")

  # ---- arm labels ----
  codes <- sort(unique(armkey[final]))
  lc <- tolower(codes)
  lab <- setNames(rep(NA_character_, length(codes)), codes)
  if (length(codes) >= 3 && any(grepl("contr", lc)) && any(grepl("subst", lc)) && any(grepl("rhet", lc))) {
    lab[grepl("contr", lc)] <- "Control"; lab[grepl("subst", lc)] <- "Substance"; lab[grepl("rhet", lc)] <- "Rhetoric"
    lab[is.na(lab)] <- "Treatment"
  } else if (length(codes) == 2 && sum(grepl("contr", lc)) == 1) {
    lab[] <- ifelse(grepl("contr", lc), "Control", "Treatment")
  }
  if ((any(is.na(lab)) || any(duplicated(lab))) && !is.null(validS) && length(codes) >= 2) {
    lab[] <- NA_character_
    M <- sapply(seq_len(ncol(validS)), function(j) tapply(validS[final, j], armkey[final], mean, na.rm = TRUE)[codes])
    M <- matrix(M, nrow = length(codes))
    rng <- apply(M, 2, function(z) max(z, na.rm = TRUE) - min(z, na.rm = TRUE))
    cj <- which.max(rng)
    if (length(codes) == 2) {
      lab[] <- "Control"; lab[which.max(M[, cj])] <- "Treatment"
    } else {
      others <- setdiff(seq_len(ncol(M)), cj)
      if (length(others) > 0) { mj <- others[which.max(rng[others])]; ci <- which.max(M[, mj]) } else ci <- which.min(M[, cj])
      lab[ci] <- "Control"
      rest <- setdiff(seq_along(codes), ci)
      rest <- rest[order(-M[rest, cj])]
      lab[rest] <- c("Treatment", "Substance", "Rhetoric", "Arm5", "Arm6", "Arm7", "Arm8")[seq_along(rest)]
    }
    dlog(key, "arm labels assigned from score pattern")
  }
  if (any(is.na(lab))) lab[is.na(lab)] <- paste0("Arm", which(is.na(lab)))
  dlog(key, "arm map: ", paste(paste0(tr_s(codes), "->", lab), collapse = ", "))
  arm <- rep(NA_character_, nrow(d))
  arm[arm_ok] <- unname(lab[armkey[arm_ok]])
  dlog(key, "final arm counts: ", tabstr(arm[final], 8))

  comp <- NULL; cm <- NULL
  if (!is.null(validS)) {
    dif <- vapply(seq_len(ncol(validS)), function(j)
      mean(validS[final & arm %in% "Treatment", j], na.rm = TRUE) - mean(validS[final & arm %in% "Control", j], na.rm = TRUE), numeric(1))
    if (any(is.finite(dif))) {
      dif2 <- ifelse(is.finite(dif), dif, NA)
      comp <- which.max(dif2)
      if (ncol(validS) >= 2) {
        oth <- setdiff(seq_len(ncol(validS)), comp)
        cm <- oth[which.min(dif2[oth])]
        if (length(cm) == 0) cm <- NULL
      }
    }
    for (j in seq_len(ncol(validS))) {
      mm <- tapply(validS[final, j], arm[final], mean, na.rm = TRUE)
      dlog(key, "mean ", colnames(validS)[j], " by arm: ", paste(paste0(names(mm), "=", round(mm, 3)), collapse = " "))
    }
    dlog(key, "compounding col: ", if (is.null(comp)) "none" else colnames(validS)[comp],
         "; control-module col: ", if (is.null(cm)) "none" else colnames(validS)[cm])
  }
  dlog(key, "NAMES: ", compress_names(nmv))

  list(arm = arm[final], S = if (is.null(validS)) NULL else validS[final, , drop = FALSE],
       comp = comp, cm = cm, Tm = if (is.null(Tm)) NULL else Tm[final, , drop = FALSE],
       hasT = hasT, id = paste(d$batch_file, d$row_in_file, sep = "_")[final])
}

# ------------------------------------------------------------------
# Deliberative competence: -|r^c - r^s| in percent of future reward
# ------------------------------------------------------------------
compute_dc <- function(Tm) {
  M <- max(Tm, na.rm = TRUE)
  scale_type <- if (M <= 1.05) "fraction" else if (M <= 21) "dollars" else if (M <= 105) "percent" else "cents"
  cat("scale type:", scale_type, "\n")
  X <- Tm
  if (scale_type == "cents") X <- X / 100
  pairsA <- cbind(1:10, 11:20)
  pairsB <- cbind(seq(1, 19, 2), seq(2, 20, 2))
  paircor <- function(p) mean(sapply(1:10, function(k) suppressWarnings(cor(X[, p[k, 1]], X[, p[k, 2]], use = "complete.obs"))), na.rm = TRUE)
  if (scale_type %in% c("dollars", "cents")) {
    candR <- c(12, 14, 16, 18, 20)
    mx <- apply(X, 2, function(z) if (any(!is.na(z))) max(z, na.rm = TRUE) else NA)
    Rcol <- sapply(mx, function(m) if (is.na(m)) NA else candR[which.min(abs(candR - m))])
    mA <- sum(Rcol[pairsA[, 1]] == Rcol[pairsA[, 2]], na.rm = TRUE)
    mB <- sum(Rcol[pairsB[, 1]] == Rcol[pairsB[, 2]], na.rm = TRUE)
    if (mB > mA) {
      pairs <- pairsB
    } else if (mA > mB) {
      pairs <- pairsA
    } else {
      pairs <- if (isTRUE(paircor(pairsB) > paircor(pairsA))) pairsB else pairsA
    }
    Rp <- pmax(Rcol[pairs[, 1]], Rcol[pairs[, 2]], na.rm = TRUE)
    cat("R per pair:", Rp, "\n")
    P1 <- sweep(X[, pairs[, 1], drop = FALSE], 2, Rp, "/") * 100
    P2 <- sweep(X[, pairs[, 2], drop = FALSE], 2, Rp, "/") * 100
  } else {
    if (scale_type == "fraction") X <- X * 100
    pairs <- if (isTRUE(paircor(pairsB) > paircor(pairsA))) pairsB else pairsA
    P1 <- X[, pairs[, 1], drop = FALSE]
    P2 <- X[, pairs[, 2], drop = FALSE]
  }
  -abs(P1 - P2)
}

# ------------------------------------------------------------------
# Experiment A
# ------------------------------------------------------------------
resA <- tryCatch({
  dA <- bind_rows(lapply(paste0("data/raw/expAbatch", 1:8, ".csv"), read_one))
  A <- analyze(dA, "A", 4)
  sub <- A$arm %in% c("Control", "Treatment")
  if (!is.null(A$comp)) {
    dfa <- data.frame(y = A$S[sub, A$comp], tr = as.numeric(A$arm[sub] == "Treatment"))
    m1 <- lm(y ~ tr, data = dfa)
    add_res("test_score_compounding_treatment_minus_control_expA_table4_col1", coef(m1)["tr"])
    add_res("n_obs_table4_expA_cols1_3", nobs(m1))
  }
  if (!is.null(A$cm)) {
    dfa3 <- data.frame(y = A$S[sub, A$cm], tr = as.numeric(A$arm[sub] == "Treatment"))
    m3 <- lm(y ~ tr, data = dfa3)
    add_res("test_score_control_module_treatment_minus_control_expA_table4_col3", coef(m3)["tr"])
  }
  if (A$hasT) {
    dcm <- compute_dc(A$Tm)
    n <- nrow(dcm)
    longA <- data.frame(id = rep(A$id, ncol(dcm)), arm = rep(A$arm, ncol(dcm)),
                        pair = rep(seq_len(ncol(dcm)), each = n), dc = as.vector(dcm))
    longA$arm <- factor(longA$arm, levels = c("Control", "Treatment", "Substance", "Rhetoric"))
    m7 <- feols(dc ~ 0 + arm, data = longA, cluster = ~id)
    add_res("deliberative_competence_control_expA_table7_col1", coef(m7)["armControl"])
    add_res("deliberative_competence_treatment_expA_table7_col1", coef(m7)["armTreatment"])
    add_res("deliberative_competence_substance_only_expA_table7_col1", coef(m7)["armSubstance"])
    add_res("deliberative_competence_rhetoric_only_expA_table7_col1", coef(m7)["armRhetoric"])
    add_res("n_obs_table7_expA_col1", nobs(m7))
  } else {
    dlog("A", "No valuation (T) data usable in Experiment A; skipping Table 7")
  }
  TRUE
}, error = function(e) { dlog("A", "Experiment A error: ", conditionMessage(e)); FALSE })
flush_diag("A")

# ------------------------------------------------------------------
# Experiment B
# ------------------------------------------------------------------
resB <- tryCatch({
  dB <- bind_rows(lapply(paste0("data/raw/expBbatch", 1:2, ".csv"), read_one))
  B <- analyze(dB, "B", 2)
  sub <- B$arm %in% c("Control", "Treatment")
  if (!is.null(B$comp)) {
    dfb <- data.frame(y = B$S[sub, B$comp], tr = as.numeric(B$arm[sub] == "Treatment"))
    m2 <- lm(y ~ tr, data = dfb)
    add_res("test_score_compounding_treatment_minus_control_expB_table4_col2", coef(m2)["tr"])
    add_res("n_obs_table4_expB_cols2_4", nobs(m2))
  }
  if (!is.null(B$cm)) {
    dfb4 <- data.frame(y = B$S[sub, B$cm], tr = as.numeric(B$arm[sub] == "Treatment"))
    m4 <- lm(y ~ tr, data = dfb4)
    add_res("test_score_control_module_treatment_minus_control_expB_table4_col4", coef(m4)["tr"])
  }
  if (B$hasT) {
    dcm <- compute_dc(B$Tm)
    n <- nrow(dcm)
    longB <- data.frame(id = rep(B$id, ncol(dcm)), arm = rep(B$arm, ncol(dcm)),
                        pair = rep(seq_len(ncol(dcm)), each = n), dc = as.vector(dcm))
    longB <- longB[longB$arm %in% c("Control", "Treatment"), ]
    longB$arm <- factor(longB$arm, levels = c("Control", "Treatment"))
    m7b <- feols(dc ~ 0 + arm, data = longB, cluster = ~id)
    add_res("deliberative_competence_control_expB_table7_col2", coef(m7b)["armControl"])
    add_res("deliberative_competence_treatment_expB_table7_col2", coef(m7b)["armTreatment"])
  } else {
    dlog("B", "No valuation (T) data usable in Experiment B; skipping Table 7")
  }
  TRUE
}, error = function(e) { dlog("B", "Experiment B error: ", conditionMessage(e)); FALSE })
flush_diag("B")

# ------------------------------------------------------------------
# Emit results
# ------------------------------------------------------------------
for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
}
