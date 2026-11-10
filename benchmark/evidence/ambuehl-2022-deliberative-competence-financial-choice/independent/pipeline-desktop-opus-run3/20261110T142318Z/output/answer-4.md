suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice.script-free"

num <- function(x) suppressWarnings(as.numeric(gsub("[,$%]", "", trimws(as.character(x)))))

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
DEVS <- character(0)
add_dev <- function(s) DEVS <<- c(DEVS, s)

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
tabstr <- function(v, k = 8, n = 22) {
  t <- sort(table(tr_s(v, n)), decreasing = TRUE)
  t <- head(t, k)
  paste(paste0("[", names(t), "]:", as.integer(t)), collapse = " ")
}
compress_names <- function(nm) {
  nm <- iconv(nm, "", "ASCII", sub = "?")
  stem <- gsub("[0-9]+", "#", nm)
  u <- unique(stem)
  cnt <- as.integer(table(factor(stem, levels = u)))
  paste(ifelse(cnt > 1, paste0(u, "x", cnt), u), collapse = " ")
}
mode_of <- function(v) {
  v <- v[!is.na(v) & v != ""]
  if (!length(v)) return(NA_character_)
  names(sort(table(v), decreasing = TRUE))[1]
}
nonempty_any <- function(d, cols) {
  if (!length(cols)) return(rep(NA, nrow(d)))
  rowSums(do.call(cbind, lapply(cols, function(cc) { v <- trimws(as.character(d[[cc]])); !is.na(v) & v != "" }))) > 0
}

# ------------------------------------------------------------------
# Parse task descriptions T1..T20 into frame / reward R / delay t
# ------------------------------------------------------------------
parse_T <- function(x) {
  x <- tolower(gsub("[[:space:]]+", " ", as.character(x)))
  x[is.na(x)] <- ""
  cx <- grepl("interest|invest|%|compound", x)
  hasd <- grepl("[0-9]+ ?days?\\b", x, perl = TRUE)
  days <- num(ifelse(hasd, sub("^.*?([0-9]+) ?days?\\b.*$", "\\1", x, perl = TRUE), NA))
  hasdol <- grepl("\\$ ?[0-9]", x)
  dol <- num(ifelse(hasdol, sub("^.*?\\$ ?([0-9]+(\\.[0-9]+)?).*$", "\\1", x, perl = TRUE), NA))
  haspct <- grepl("[0-9] ?%", x)
  pct <- num(ifelse(haspct, sub("^.*?([0-9]*\\.?[0-9]+) ?%.*$", "\\1", x, perl = TRUE), NA))
  Rraw <- ifelse(cx, dol * (1 + pct / 100)^days, dol)
  candR <- c(12, 14, 16, 18, 20)
  R <- vapply(Rraw, function(z) if (is.na(z) || !is.finite(z)) NA_real_ else candR[which.min(abs(candR - z))], numeric(1))
  list(cx = cx, R = unname(R), t = days, Rraw = Rraw)
}

# ------------------------------------------------------------------
# Build subject sample, valuations, deliberative competence per pair
# ------------------------------------------------------------------
prep <- function(d, key) {
  nmv <- names(d)
  L <- function(...) dlog(key, ...)
  n <- nrow(d)
  L("== ", key, " rows=", n, " cols=", ncol(d))
  keep <- rep(TRUE, n)
  stc <- intersect(c("Status", "V7"), nmv)
  if (length(stc)) {
    v <- tolower(trimws(as.character(d[[stc[1]]])))
    L(stc[1], ": ", tabstr(v, 4))
    keep <- keep & !(v %in% c("1", "survey preview", "8", "spam"))
  }
  fnc <- intersect(c("Finished", "V10"), nmv)
  if (length(fnc)) {
    v <- tolower(trimws(as.character(d[[fnc[1]]])))
    L(fnc[1], ": ", tabstr(v, 4))
    fin <- v %in% c("1", "true")
    if (sum(fin & keep) >= 100) keep <- keep & fin
  }
  L("after status/finished: ", sum(keep))

  tcols <- paste0("T", 1:20)
  if (!all(tcols %in% nmv)) stop("T1..T20 missing")
  P <- lapply(tcols, function(cc) parse_T(d[[cc]]))
  Rm <- do.call(cbind, lapply(P, function(p) p$R))
  tm <- do.call(cbind, lapply(P, function(p) p$t))
  cxm <- do.call(cbind, lapply(P, function(p) p$cx))
  Rraw <- do.call(cbind, lapply(P, function(p) p$Rraw))
  kp <- matrix(keep, n, 20)
  L("tasks cx_R_t: ", tabstr(paste(cxm, Rm, tm, sep = "_")[as.vector(kp)], 22))
  alltxt <- unlist(lapply(tcols, function(cc) as.character(d[[cc]])))
  sampC <- alltxt[as.vector(cxm & kp)]
  if (length(sampC)) L("complex txt: ", tr_s(sampC[1], 150))
  dv <- abs(Rraw - Rm)[cxm & kp]
  if (length(dv) && any(!is.na(dv))) L("complex |Rraw-R| med=", round(median(dv, na.rm = TRUE), 3), " max=", round(max(dv, na.rm = TRUE), 3))

  swc <- paste0("switch", 1:20)
  Sw <- if (all(swc %in% nmv)) colmat(d, swc) else NULL

  vals <- matrix(NA_real_, n, 20); ms <- rep(FALSE, n); src <- "none"
  mm <- regmatches(nmv, regexec("^iMPL([0-9]+)_([0-9]+)_([0-9]+)", nmv))
  okm <- lengths(mm) == 4
  if (sum(okm) > 0) {
    info <- data.frame(col = nmv[okm],
                       k = as.integer(vapply(mm[okm], `[`, character(1), 2)),
                       lev = as.integer(vapply(mm[okm], `[`, character(1), 3)),
                       row = as.integer(vapply(mm[okm], `[`, character(1), 4)), stringsAsFactors = FALSE)
    info <- info[!duplicated(info[, c("k", "lev", "row")]), ]
    L("iMPL cols=", nrow(info), " tasks=", length(unique(info$k)),
      " lev1 rows=", paste(range(table(info$k[info$lev == 1])), collapse = "-"),
      " lev2 rows=", if (any(info$lev == 2)) paste(range(table(info$k[info$lev == 2])), collapse = "-") else "0")
    getM <- function(k, lev) {
      ii <- info[info$k == k & info$lev == lev, , drop = FALSE]
      if (nrow(ii) == 0) return(NULL)
      ii <- ii[order(ii$row), , drop = FALSE]
      do.call(cbind, lapply(ii$col, function(cc) { v <- trimws(as.character(d[[cc]])); v[!is.na(v) & v == ""] <- NA; v }))
    }
    M1s <- lapply(1:20, function(k) getM(k, 1))
    M2s <- lapply(1:20, function(k) getM(k, 2))
    r1 <- unlist(lapply(M1s, function(M) if (is.null(M)) NULL else M[keep, 1]))
    rl <- unlist(lapply(M1s, function(M) if (is.null(M)) NULL else M[keep, ncol(M)]))
    A1 <- mode_of(r1)
    lev1vals <- unique(unlist(lapply(M1s, function(M) if (is.null(M)) NULL else as.vector(M[keep, ]))))
    lev2pool <- unlist(lapply(M2s, function(M) if (is.null(M)) NULL else as.vector(M[keep, ])))
    L("lev1 row1: ", tabstr(r1, 4), " | lev1 last: ", tabstr(rl, 4), " | lev2: ", tabstr(lev2pool, 4))
    use_common <- all(lev2pool[!is.na(lev2pool)] %in% lev1vals)
    trans <- function(M) apply(M, 1, function(z) { z <- z[!is.na(z)]; if (length(z) < 2) 0L else sum(z[-1] != z[-length(z)]) })
    c1all <- matrix(NA_real_, n, 20)
    msk <- matrix(FALSE, n, 20)
    for (k in 1:20) {
      M1 <- M1s[[k]]; if (is.null(M1)) next
      comp1 <- rowSums(is.na(M1)) == 0
      c1 <- if (is.na(A1)) rep(0, n) else rowSums(M1 == A1, na.rm = TRUE)
      M2 <- M2s[[k]]
      c2 <- rep(0, n); t2 <- rep(0L, n)
      if (!is.null(M2)) {
        A2 <- if (use_common) A1 else mode_of(M2[keep, 1])
        if (!is.na(A2)) c2 <- rowSums(M2 == A2, na.rm = TRUE)
        t2 <- trans(M2)
      }
      t1 <- trans(M1)
      v <- 2 * c1 + 0.2 * c2
      v[!comp1] <- NA
      vals[, k] <- v
      c1all[, k] <- ifelse(comp1, c1, NA)
      msk[, k] <- (t1 >= 2 | t2 >= 2) & comp1
    }
    ms <- rowSums(msk) > 0
    src <- "iMPL"
    if (!is.null(Sw)) {
      cc <- suppressWarnings(cor(as.vector(c1all[kp]), as.vector(Sw[kp]), use = "complete.obs"))
      L("cor(lev1 count, switch)=", round(cc, 3))
    }
  }
  if (all(is.na(vals[keep, ])) && !is.null(Sw)) {
    vals <- 2 * Sw; src <- "switch"
    add_dev(paste0("DEVIATION: Exp ", key, " valuations from switch columns ($2 grid, no refinement); multiple-switch exclusion not identifiable"))
  }
  L("valuation source: ", src, "; multi-switch among keep: ", sum(ms & keep))

  keyM <- matrix(paste(Rm, tm, sep = "_"), nrow = n)
  allkeys <- sort(unique(keyM[kp & !cxm & !is.na(Rm) & !is.na(tm)]))
  L("pair keys: ", paste(allkeys, collapse = " "))
  DC <- matrix(NA_real_, n, length(allkeys))
  Rk <- as.numeric(sub("_.*", "", allkeys))
  for (j in seq_along(allkeys)) {
    S <- (keyM == allkeys[j]) & !cxm; C <- (keyM == allkeys[j]) & cxm
    S[is.na(S)] <- FALSE; C[is.na(C)] <- FALSE
    one <- rowSums(S) == 1 & rowSums(C) == 1
    vs <- rowSums(ifelse(S, vals, 0)); vc <- rowSums(ifelse(C, vals, 0))
    DC[one, j] <- -abs(vc[one] - vs[one]) / Rk[j] * 100
  }
  complete <- keep & length(allkeys) > 0 & rowSums(!is.na(DC)) == length(allkeys)

  trv <- if ("treatment" %in% nmv) trimws(as.character(d$treatment)) else rep(NA_character_, n)
  arm_ok <- trv %in% c("0", "1")
  idc <- intersect(c("amt_id", "workerId", "WorkerId", "MID"), nmv)
  dup <- rep(FALSE, n)
  if (length(idc)) {
    idv <- toupper(gsub("[^A-Za-z0-9]", "", as.character(d[[idc[1]]])))
    cand <- complete & arm_ok & !is.na(idv) & idv != ""
    dd <- duplicated(idv[cand])
    dup[which(cand)[dd]] <- TRUE
  }
  final <- complete & arm_ok & !dup & !ms
  L("complete=", sum(complete), " arm_ok=", sum(complete & arm_ok), " dup=", sum(dup),
    " multiswitch=", sum(ms & complete & arm_ok & !dup), " final=", sum(final), " tr: ", tabstr(trv[final], 3))
  list(d = d, final = final, trv = trv, DC = DC, Rk = Rk)
}

# ------------------------------------------------------------------
# Test-score answer keys from Q columns
# ------------------------------------------------------------------
build_keys <- function(d, rows, tr1, key, verbose = TRUE) {
  nmv <- names(d)
  qc <- grep("^Q[0-9]+$", nmv, value = TRUE)
  if (!length(qc)) return(NULL)
  t1 <- tr1[rows]
  st <- do.call(rbind, lapply(qc, function(q) {
    v <- trimws(as.character(d[[q]][rows])); v[!is.na(v) & v == ""] <- NA
    k1 <- mode_of(v[t1]); k0 <- mode_of(v[!t1])
    c1 <- if (is.na(k1)) rep(FALSE, length(v)) else (!is.na(v) & v == k1)
    c0 <- if (is.na(k0)) rep(FALSE, length(v)) else (!is.na(v) & v == k0)
    data.frame(q = q, nu = length(unique(v[!is.na(v)])), fr = mean(!is.na(v)), k1 = k1, k0 = k0,
               d1 = mean(c1[t1]) - mean(c1[!t1]), d0 = mean(c0[t1]) - mean(c0[!t1]), stringsAsFactors = FALSE)
  }))
  if (verbose) dlog(key, "Q(nu,fr,d1,d0): ", paste(sprintf("%s:%d,%.2f,%+.2f,%+.2f", st$q, st$nu, st$fr, st$d1, st$d0), collapse = " "))
  s2 <- st[st$nu >= 2 & st$nu <= 10 & st$fr >= 0.8, ]
  cp <- s2[s2$d1 > 0.1, ]; cp <- head(cp[order(-cp$d1), ], 5)
  rest <- s2[!(s2$q %in% cp$q) & s2$d0 < -0.05, ]; ct <- head(rest[order(rest$d0), ], 5)
  dlog(key, "comp Qs: ", paste(cp$q, collapse = ","), " | ctrl Qs: ", paste(ct$q, collapse = ","))
  list(cq = cp$q, ck = cp$k1, tq = ct$q, tk = ct$k0)
}
score_with <- function(d, qs, ks) {
  if (!length(qs)) return(rep(NA_real_, nrow(d)))
  rowSums(do.call(cbind, lapply(seq_along(qs), function(j) { v <- trimws(as.character(d[[qs[j]]])); !is.na(v) & v == ks[j] })))
}
sc0_check <- function(d, rows, comp, ctrl, key) {
  sc <- grep("^SC[0-9]", names(d), value = TRUE)
  out <- sapply(sc, function(cc) {
    x <- num(d[[cc]][rows])
    c(suppressWarnings(cor(x, comp[rows], use = "complete.obs")), suppressWarnings(cor(x, ctrl[rows], use = "complete.obs")),
      suppressWarnings(cor(x, comp[rows] + ctrl[rows], use = "complete.obs")))
  })
  if (length(sc)) dlog(key, "SC cors (comp,ctrl,sum): ", paste(paste0(sc, "=", apply(round(matrix(out, nrow = 3), 2), 2, paste, collapse = "/")), collapse = " "))
}

# ------------------------------------------------------------------
# Experiment A
# ------------------------------------------------------------------
resA <- tryCatch({
  dA <- bind_rows(lapply(paste0("data/raw/expAbatch", 1:8, ".csv"), read_one))
  pa <- prep(dA, "A")
  d <- pa$d; fr <- pa$final; tr1 <- pa$trv == "1"; n <- nrow(d)
  neT <- nonempty_any(d, grep("^TimeTreat", names(d), value = TRUE))
  neC <- nonempty_any(d, grep("^TimeContro", names(d), value = TRUE))
  k1 <- build_keys(d, fr, tr1, "A")
  comp <- score_with(d, k1$cq, k1$ck); ctrl <- score_with(d, k1$tq, k1$tk)
  b <- d$batch_file
  bt <- sort(unique(b[fr]))
  for (bb in bt) {
    r0 <- fr & b == bb & !tr1; r1 <- fr & b == bb & tr1
    dlog("A", sub("data/raw/expA", "", bb), ": n=", sum(r0), "/", sum(r1),
         " ctrl=", round(mean(ctrl[r0]), 2), "/", round(mean(ctrl[r1]), 2),
         " comp=", round(mean(comp[r0]), 2), "/", round(mean(comp[r1]), 2),
         " tC=", round(mean(neC[r0]), 2), "/", round(mean(neC[r1]), 2),
         " tT=", round(mean(neT[r0]), 2), "/", round(mean(neT[r1]), 2))
  }
  ctB <- setNames(rep(NA, length(bt)), bt)
  if (!all(is.na(neC))) {
    rr <- tapply(neC[fr & !tr1], b[fr & !tr1], mean)
    ctB[] <- rr[bt] > 0.5
  }
  if (all(is.na(ctB)) || length(unique(ctB[!is.na(ctB)])) < 2) {
    dd <- sapply(bt, function(bb) mean(ctrl[fr & b == bb & !tr1]) - mean(ctrl[fr & b == bb & tr1]))
    ctB[] <- dd > 0.4
    dlog("A", "batch type by ctrl-score gap")
  } else dlog("A", "batch type by control-video timer")
  isCT <- as.logical(ctB[b]); isCT[is.na(isCT)] <- FALSE
  arm <- rep(NA_character_, n)
  if (any(isCT & fr) && any(!isCT & fr)) {
    k2 <- build_keys(d, fr & isCT, tr1, "A", verbose = FALSE)
    if (length(k2$cq) && length(k2$tq)) {
      comp <- score_with(d, k2$cq, k2$ck); ctrl <- score_with(d, k2$tq, k2$tk)
    }
    arm[fr & isCT & !tr1] <- "Control"; arm[fr & isCT & tr1] <- "Treatment"
    sr <- fr & !isCT
    subst_is_1 <- mean(comp[sr & tr1]) >= mean(comp[sr & !tr1])
    arm[sr & tr1] <- if (subst_is_1) "Substance" else "Rhetoric"
    arm[sr & !tr1] <- if (subst_is_1) "Rhetoric" else "Substance"
    add_dev("DEVIATION: Exp A arms: Control/Treatment vs Substance/Rhetoric sessions identified per batch from data; within S/R sessions the arm with higher compounding score labelled Substance-only")
  } else {
    arm[fr] <- ifelse(tr1[fr], "Treatment", "Control")
    add_dev("DEVIATION: Exp A Substance/Rhetoric arms could not be identified; only treatment 0/1 used")
  }
  add_dev("DEVIATION: test-score answer keys inferred from modal answers (compounding: treated arm; control module: control arm) since no key is provided")
  sc0_check(d, fr, comp, ctrl, "A")
  dlog("A", "arm counts: ", tabstr(arm[fr], 4), "; comp by arm: ",
       paste(names(tapply(comp[fr], arm[fr], mean)), round(tapply(comp[fr], arm[fr], mean), 2), collapse = " "),
       "; ctrl by arm: ", paste(round(tapply(ctrl[fr], arm[fr], mean), 2), collapse = " "))

  ct <- fr & arm %in% c("Control", "Treatment")
  if (length(k1$cq)) {
    dfa <- data.frame(y = comp[ct], tr = as.numeric(arm[ct] == "Treatment"))
    m1 <- lm(y ~ tr, data = dfa)
    add_res("test_score_compounding_treatment_minus_control_expA_table4_col1", coef(m1)["tr"])
    add_res("n_obs_table4_expA_cols1_3", nobs(m1))
  }
  if (length(k1$tq)) {
    dfa3 <- data.frame(y = ctrl[ct], tr = as.numeric(arm[ct] == "Treatment"))
    m3 <- lm(y ~ tr, data = dfa3)
    add_res("test_score_control_module_treatment_minus_control_expA_table4_col3", coef(m3)["tr"])
  }
  DC <- pa$DC[fr, , drop = FALSE]
  ids <- which(fr)
  longA <- data.frame(id = rep(ids, ncol(DC)), arm = rep(arm[fr], ncol(DC)), dc = as.vector(DC),
                      dcp = as.vector(sweep(DC, 2, pa$Rk / 20, "*")))
  longA <- longA[!is.na(longA$dc), ]
  longA$arm <- factor(longA$arm, levels = intersect(c("Control", "Treatment", "Substance", "Rhetoric"), unique(longA$arm)))
  dlog("A", "DC($grid) by arm: ", paste(round(tapply(longA$dc, longA$arm, mean), 2), collapse = " "),
       "; DC(prop grid): ", paste(round(tapply(longA$dcp, longA$arm, mean), 2), collapse = " "))
  m7 <- feols(dc ~ 0 + arm, data = longA, cluster = ~id)
  add_res("deliberative_competence_control_expA_table7_col1", coef(m7)["armControl"])
  add_res("deliberative_competence_treatment_expA_table7_col1", coef(m7)["armTreatment"])
  add_res("deliberative_competence_substance_only_expA_table7_col1", coef(m7)["armSubstance"])
  add_res("deliberative_competence_rhetoric_only_expA_table7_col1", coef(m7)["armRhetoric"])
  add_res("n_obs_table7_expA_col1", nobs(m7))
  dlog("A", "NAMES: ", compress_names(names(d)))
  TRUE
}, error = function(e) { dlog("A", "Experiment A error: ", conditionMessage(e)); FALSE })
flush_diag("A", 2900)

# ------------------------------------------------------------------
# Experiment B
# ------------------------------------------------------------------
resB <- tryCatch({
  dB <- bind_rows(lapply(paste0("data/raw/expBbatch", 1:2, ".csv"), read_one))
  pb <- prep(dB, "B")
  d <- pb$d; fr <- pb$final; tr1 <- pb$trv == "1"; n <- nrow(d)
  neT <- nonempty_any(d, grep("^TimeTreat", names(d), value = TRUE))
  if (!all(is.na(neT))) {
    dlog("B", "TimeTreat nonempty tr0/tr1: ", round(mean(neT[fr & !tr1]), 2), "/", round(mean(neT[fr & tr1]), 2))
    if (mean(neT[fr & tr1]) < mean(neT[fr & !tr1]) - 0.3) {
      tr1 <- !tr1
      add_dev("DEVIATION: Exp B treatment coding flipped based on treatment-video timer")
    }
  }
  kb <- build_keys(d, fr, tr1, "B")
  comp <- score_with(d, kb$cq, kb$ck); ctrl <- score_with(d, kb$tq, kb$tk)
  sc0_check(d, fr, comp, ctrl, "B")
  arm <- rep(NA_character_, n)
  arm[fr] <- ifelse(tr1[fr], "Treatment", "Control")
  ct <- fr
  if (length(kb$cq)) {
    m2 <- lm(y ~ tr, data = data.frame(y = comp[ct], tr = as.numeric(arm[ct] == "Treatment")))
    add_res("test_score_compounding_treatment_minus_control_expB_table4_col2", coef(m2)["tr"])
    add_res("n_obs_table4_expB_cols2_4", nobs(m2))
  }
  if (length(kb$tq)) {
    m4 <- lm(y ~ tr, data = data.frame(y = ctrl[ct], tr = as.numeric(arm[ct] == "Treatment")))
    add_res("test_score_control_module_treatment_minus_control_expB_table4_col4", coef(m4)["tr"])
  }
  DC <- pb$DC[fr, , drop = FALSE]
  ids <- which(fr)
  longB <- data.frame(id = rep(ids, ncol(DC)), arm = rep(arm[fr], ncol(DC)), dc = as.vector(DC),
                      dcp = as.vector(sweep(DC, 2, pb$Rk / 20, "*")))
  longB <- longB[!is.na(longB$dc), ]
  longB$arm <- factor(longB$arm, levels = c("Control", "Treatment"))
  dlog("B", "DC($grid) by arm: ", paste(round(tapply(longB$dc, longB$arm, mean), 2), collapse = " "),
       "; DC(prop): ", paste(round(tapply(longB$dcp, longB$arm, mean), 2), collapse = " "))
  m7b <- feols(dc ~ 0 + arm, data = longB, cluster = ~id)
  add_res("deliberative_competence_control_expB_table7_col2", coef(m7b)["armControl"])
  add_res("deliberative_competence_treatment_expB_table7_col2", coef(m7b)["armTreatment"])
  TRUE
}, error = function(e) { dlog("B", "Experiment B error: ", conditionMessage(e)); FALSE })
flush_diag("B", 1800)

# ------------------------------------------------------------------
# Emit results
# ------------------------------------------------------------------
cat("DEVIATION: valuations = $2 first-level grid + $0.20 refinement from iMPL choices; multiple switching = 2+ switches in any list\n")
for (s in unique(DEVS)) cat(s, "\n", sep = "")
for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
}
