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
  nm <- gsub("\ufeff", "", nm, fixed = TRUE)
  nm <- gsub("^\u00ef\u00bb\u00bf", "", nm)
  nm <- trimws(nm)
  names(d) <- nm
  # drop unnamed junk columns
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
# Generic processing of one experiment
# ------------------------------------------------------------------
process <- function(d, label) {
  cat("====", label, "====\n")
  cat("rows:", nrow(d), " cols:", ncol(d), "\n")
  tcols <- grep("^T[0-9]+$", names(d), value = TRUE)
  tcols <- tcols[order(as.integer(sub("^T", "", tcols)))]
  if (length(tcols) < 20) {
    cat("Column names:\n"); print(names(d))
    stop(paste("Fewer than 20 T columns in", label))
  }
  tcols <- tcols[1:20]
  Tm <- colmat(d, tcols)
  cat("non-NA counts per T column:\n"); print(colSums(!is.na(Tm)))

  # treatment column: prefer exact 'treatment', must have 2..8 distinct nonempty values
  nonempty <- function(cc) { v <- trimws(as.character(d[[cc]])); sum(!is.na(v) & v != "") }
  nuniq <- function(cc) { v <- trimws(as.character(d[[cc]])); v <- v[!is.na(v) & v != ""]; length(unique(v)) }
  exact <- names(d)[tolower(names(d)) == "treatment"]
  cand <- unique(c(exact, grep("treat|condition", names(d), ignore.case = TRUE, value = TRUE)))
  cand <- cand[sapply(cand, function(cc) { k <- nuniq(cc); k >= 2 && k <= 8 })]
  if (length(cand) == 0) { print(names(d)); stop("no treatment column") }
  ex_ok <- intersect(exact, cand)
  if (length(ex_ok) > 0 && nonempty(ex_ok[1]) > 0) {
    trcol <- ex_ok[1]
  } else {
    ne <- sapply(cand, nonempty)
    trcol <- cand[which.max(ne)]
  }

  # score columns
  sccols <- grep("^SC0(_[0-9]+)?$", names(d), value = TRUE)
  if (length(sccols) == 0) sccols <- grep("^SC", names(d), value = TRUE)
  if (length(sccols) == 0) { print(names(d)); stop("no score columns") }
  sccols <- sort(sccols)
  S <- colmat(d, sccols)
  cat("non-NA counts per score column:\n"); print(colSums(!is.na(S)))
  S <- S[, colSums(!is.na(S)) > 0, drop = FALSE]
  if (ncol(S) == 0) stop("all score columns empty")
  if (ncol(S) >= 3) {
    for (j in seq_len(ncol(S))) {
      cc <- rowSums(is.na(S)) == 0
      if (sum(cc) > 0 && all(abs(S[cc, j] - rowSums(S[cc, -j, drop = FALSE])) < 1e-6)) {
        cat("dropping total score column:", colnames(S)[j], "\n")
        S <- S[, -j, drop = FALSE]
        break
      }
    }
  }
  if (ncol(S) > 2) S <- S[, 1:2, drop = FALSE]

  ids <- paste(d$batch_file, d$row_in_file, sep = "_")

  arm_raw <- trimws(as.character(d[[trcol]]))
  arm_ok <- !is.na(arm_raw) & arm_raw != ""
  tcnt <- rowSums(!is.na(Tm))
  sc_ok <- rowSums(!is.na(S)) > 0
  cat("treatment column:", trcol, " score columns:", paste(colnames(S), collapse = ","), "\n")
  cat("rows with arm:", sum(arm_ok), " rows with any score:", sum(sc_ok), "\n")
  cat("distribution of # nonmissing T among rows with arm:\n"); print(table(tcnt[arm_ok]))

  if (any(arm_ok & tcnt == 20)) {
    tmin <- 20
  } else if (any(arm_ok & tcnt > 0)) {
    tmin <- max(tcnt[arm_ok])
  } else {
    tmin <- NA
  }
  hasT <- !is.na(tmin)
  ok <- if (hasT) arm_ok & tcnt >= tmin else arm_ok & sc_ok
  cat("T threshold:", tmin, " complete rows:", sum(ok), "\n")

  # Exclusion of multiple switchers
  excl <- rep(NA, nrow(d))
  if ("excluded" %in% names(d)) {
    v <- tolower(trimws(as.character(d$excluded)))
    cat("excluded column values (complete rows):\n"); print(table(v[ok], useNA = "ifany"))
    excl <- ifelse(is.na(v) | v == "", NA, v %in% c("1", "true", "t", "yes", "1.0"))
  }
  swc <- grep("^switch[0-9]+$", names(d), ignore.case = TRUE, value = TRUE)
  swrule <- rep(NA, nrow(d))
  if (length(swc) > 0) {
    Sw <- colmat(d, swc)
    vals <- Sw[ok, , drop = FALSE]
    mxsw <- if (any(!is.na(vals))) max(vals, na.rm = TRUE) else NA
    cat("switch columns:", length(swc), " max switch value:", mxsw, "\n")
    if (!is.na(mxsw)) {
      if (mxsw <= 1) {
        swrule <- rowSums(Sw == 1, na.rm = TRUE) > 0
      } else {
        swrule <- rowSums(Sw >= 2, na.rm = TRUE) > 0
      }
      swrule[rowSums(!is.na(Sw)) == 0] <- NA
    }
    if (any(!is.na(excl[ok]))) {
      cat("agreement excluded vs switch rule:\n")
      print(table(excluded = excl[ok], swrule = swrule[ok], useNA = "ifany"))
    }
  }
  excl_final <- ifelse(!is.na(excl), excl, ifelse(!is.na(swrule), swrule, FALSE))
  cat("excluded among complete:", sum(excl_final[ok]), "\n")

  keep <- ok & !excl_final
  cat("kept:", sum(keep), "\n")
  print(table(arm_raw[keep]))
  if (sum(keep) == 0) stop(paste("no rows kept in", label))
  list(id = ids[keep], arm_raw = arm_raw[keep], S = S[keep, , drop = FALSE],
       Tm = Tm[keep, , drop = FALSE], hasT = hasT)
}

# ------------------------------------------------------------------
# Deliberative competence: -|r^c - r^s| in percent of future reward
# ------------------------------------------------------------------
compute_dc <- function(Tm) {
  n <- nrow(Tm)
  M <- max(Tm, na.rm = TRUE)
  cat("valuation summary:\n"); print(summary(as.vector(Tm)))
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
    cat("column maxima:\n"); print(round(mx, 2))
    cat("inferred R per column:\n"); print(Rcol)
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
    cat("pairs used:\n"); print(pairs); cat("R per pair:", Rp, "\n")
    if (!all(table(factor(Rp, levels = candR)) == 2)) cat("WARNING: inferred R per pair not balanced\n")
    P1 <- sweep(X[, pairs[, 1], drop = FALSE], 2, Rp, "/") * 100
    P2 <- sweep(X[, pairs[, 2], drop = FALSE], 2, Rp, "/") * 100
  } else {
    if (scale_type == "fraction") X <- X * 100
    pairs <- if (isTRUE(paircor(pairsB) > paircor(pairsA))) pairsB else pairsA
    cat("pairs used:\n"); print(pairs)
    P1 <- X[, pairs[, 1], drop = FALSE]
    P2 <- X[, pairs[, 2], drop = FALSE]
  }
  -abs(P1 - P2)
}

# ------------------------------------------------------------------
# Experiment A
# ------------------------------------------------------------------
compA_idx <- NA
resA <- tryCatch({
  fA <- paste0("data/raw/expAbatch", 1:8, ".csv")
  dA <- bind_rows(lapply(fA, read_one))
  A <- process(dA, "Experiment A")
  nsc <- ncol(A$S)
  s0 <- A$S[, 1]; s1 <- if (nsc >= 2) A$S[, 2] else A$S[, 1]
  codes <- unique(A$arm_raw)
  numcodes <- suppressWarnings(as.numeric(codes))
  if (all(!is.na(numcodes))) codes <- codes[order(numcodes)] else codes <- sort(codes)
  lab <- setNames(rep(NA_character_, length(codes)), codes)
  lc <- tolower(codes)
  if (any(grepl("contr|subst|rhet", lc))) {
    lab[grepl("contr", lc)] <- "Control"
    lab[grepl("subst", lc)] <- "Substance"
    lab[grepl("rhet", lc)] <- "Rhetoric"
    lab[is.na(lab) & grepl("treat|full|compound", lc)] <- "Treatment"
  }
  if (any(is.na(lab)) || length(unique(lab)) != length(codes)) {
    m0 <- tapply(s0, A$arm_raw, mean, na.rm = TRUE)[codes]
    m1 <- tapply(s1, A$arm_raw, mean, na.rm = TRUE)[codes]
    cat("arm means score1:\n"); print(m0); cat("arm means score2:\n"); print(m1)
    gapstat <- function(m) { sd_ <- sort(m, decreasing = TRUE); sa <- sort(m); (sd_[1] - sd_[2]) - (sa[2] - sa[1]) }
    ctrl_score <- if (isTRUE(gapstat(m0) >= gapstat(m1))) m0 else m1
    ctrl_code <- names(ctrl_score)[which.max(ctrl_score)]
    others <- setdiff(codes, ctrl_code)
    lab <- setNames(c("Control", c("Treatment", "Substance", "Rhetoric")[seq_along(others)]), c(ctrl_code, others))
    lab <- lab[codes]
  }
  cat("arm mapping A:\n"); print(lab)
  armA <- unname(lab[A$arm_raw])
  # orientation: compounding score rises Treatment vs Control
  if (nsc >= 2) {
    d0 <- mean(s0[armA == "Treatment"], na.rm = TRUE) - mean(s0[armA == "Control"], na.rm = TRUE)
    d1 <- mean(s1[armA == "Treatment"], na.rm = TRUE) - mean(s1[armA == "Control"], na.rm = TRUE)
    compA_idx <- if (isTRUE(d0 >= d1)) 1 else 2
  } else {
    compA_idx <- 1
  }
  comp <- A$S[, compA_idx]
  cat("compounding score column index (A):", compA_idx, "\n")

  sub <- armA %in% c("Control", "Treatment")
  tr <- as.numeric(armA[sub] == "Treatment")
  m1 <- lm(comp[sub] ~ tr)
  print(summary(m1)$coefficients)
  add_res("test_score_compounding_treatment_minus_control_expA_table4_col1", coef(m1)["tr"])
  add_res("n_obs_table4_expA_cols1_3", nobs(m1))
  if (nsc >= 2) {
    ctrlm <- A$S[, 3 - compA_idx]
    m3 <- lm(ctrlm[sub] ~ tr)
    print(summary(m3)$coefficients)
    add_res("test_score_control_module_treatment_minus_control_expA_table4_col3", coef(m3)["tr"])
  }

  if (A$hasT) {
    dcm <- compute_dc(A$Tm)
    n <- nrow(dcm)
    longA <- data.frame(id = rep(A$id, ncol(dcm)), arm = rep(armA, ncol(dcm)),
                        pair = rep(seq_len(ncol(dcm)), each = n), dc = as.vector(dcm))
    longA$arm <- factor(longA$arm, levels = c("Control", "Treatment", "Substance", "Rhetoric"))
    m7 <- feols(dc ~ 0 + arm, data = longA, cluster = ~id)
    print(summary(m7))
    add_res("deliberative_competence_control_expA_table7_col1", coef(m7)["armControl"])
    add_res("deliberative_competence_treatment_expA_table7_col1", coef(m7)["armTreatment"])
    add_res("deliberative_competence_substance_only_expA_table7_col1", coef(m7)["armSubstance"])
    add_res("deliberative_competence_rhetoric_only_expA_table7_col1", coef(m7)["armRhetoric"])
    add_res("n_obs_table7_expA_col1", nobs(m7))
  } else {
    cat("No valuation (T) data in Experiment A; skipping Table 7\n")
  }
  TRUE
}, error = function(e) { cat("Experiment A error:", conditionMessage(e), "\n"); FALSE })

# ------------------------------------------------------------------
# Experiment B
# ------------------------------------------------------------------
resB <- tryCatch({
  fB <- paste0("data/raw/expBbatch", 1:2, ".csv")
  dB <- bind_rows(lapply(fB, read_one))
  B <- process(dB, "Experiment B")
  nsc <- ncol(B$S)
  s0 <- B$S[, 1]; s1 <- if (nsc >= 2) B$S[, 2] else B$S[, 1]
  codes <- unique(B$arm_raw)
  numcodes <- suppressWarnings(as.numeric(codes))
  if (all(!is.na(numcodes))) codes <- codes[order(numcodes)] else codes <- sort(codes)
  lc <- tolower(codes)
  if (any(grepl("contr", lc))) {
    lab <- setNames(ifelse(grepl("contr", lc), "Control", "Treatment"), codes)
    armB <- unname(lab[B$arm_raw])
    if (nsc >= 2) {
      d0 <- mean(s0[armB == "Treatment"], na.rm = TRUE) - mean(s0[armB == "Control"], na.rm = TRUE)
      d1 <- mean(s1[armB == "Treatment"], na.rm = TRUE) - mean(s1[armB == "Control"], na.rm = TRUE)
      cidx <- if (isTRUE(d0 >= d1)) 1 else 2
    } else {
      cidx <- 1
    }
  } else {
    cidx <- if (nsc >= 2 && !is.na(compA_idx)) compA_idx else 1
    compm <- tapply(B$S[, cidx], B$arm_raw, mean, na.rm = TRUE)[codes]
    cat("compounding means by B code:\n"); print(compm)
    ctrl_code <- names(compm)[which.min(compm)]
    lab <- setNames(ifelse(codes == ctrl_code, "Control", "Treatment"), codes)
    armB <- unname(lab[B$arm_raw])
  }
  cat("arm mapping B:\n"); print(lab)
  comp <- B$S[, cidx]
  tr <- as.numeric(armB == "Treatment")
  m2 <- lm(comp ~ tr)
  print(summary(m2)$coefficients)
  add_res("test_score_compounding_treatment_minus_control_expB_table4_col2", coef(m2)["tr"])
  add_res("n_obs_table4_expB_cols2_4", nobs(m2))
  if (nsc >= 2) {
    ctrlm <- B$S[, 3 - cidx]
    m4 <- lm(ctrlm ~ tr)
    print(summary(m4)$coefficients)
    add_res("test_score_control_module_treatment_minus_control_expB_table4_col4", coef(m4)["tr"])
  } else {
    cat("Only one score column in Experiment B; control-module score not available\n")
  }

  if (B$hasT) {
    dcm <- compute_dc(B$Tm)
    n <- nrow(dcm)
    longB <- data.frame(id = rep(B$id, ncol(dcm)), arm = rep(armB, ncol(dcm)),
                        pair = rep(seq_len(ncol(dcm)), each = n), dc = as.vector(dcm))
    longB$arm <- factor(longB$arm, levels = c("Control", "Treatment"))
    m7b <- feols(dc ~ 0 + arm, data = longB, cluster = ~id)
    print(summary(m7b))
    add_res("deliberative_competence_control_expB_table7_col2", coef(m7b)["armControl"])
    add_res("deliberative_competence_treatment_expB_table7_col2", coef(m7b)["armTreatment"])
  } else {
    cat("No valuation (T) data in Experiment B; skipping Table 7\n")
  }
  TRUE
}, error = function(e) { cat("Experiment B error:", conditionMessage(e), "\n"); FALSE })

# ------------------------------------------------------------------
# Emit results
# ------------------------------------------------------------------
for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
}
