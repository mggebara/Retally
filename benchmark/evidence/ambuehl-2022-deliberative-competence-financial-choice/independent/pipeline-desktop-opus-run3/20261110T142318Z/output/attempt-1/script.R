suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice.script-free"

num <- function(x) suppressWarnings(as.numeric(gsub("[,$%]", "", trimws(as.character(x)))))

read_one <- function(f) {
  d <- readr::read_csv(file.path(base, f), col_types = cols(.default = col_character()),
                       show_col_types = FALSE, progress = FALSE, name_repair = "unique")
  nm <- names(d)
  nm <- gsub("\ufeff", "", nm, fixed = TRUE)
  nm <- gsub("^\u00ef\u00bb\u00bf", "", nm)
  nm <- trimws(nm)
  names(d) <- nm
  d$batch_file <- f
  d$row_in_file <- seq_len(nrow(d))
  d
}

results <- list()
add_res <- function(name, val) {
  if (length(val) == 1 && !is.na(val) && is.finite(val)) results[[name]] <<- as.numeric(val)
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
  Tm <- sapply(tcols, function(cc) num(d[[cc]]))
  if (is.null(dim(Tm))) Tm <- matrix(Tm, nrow = 1)

  trcol <- names(d)[tolower(names(d)) == "treatment"]
  if (length(trcol) == 0) trcol <- grep("treat|condition|arm", names(d), ignore.case = TRUE, value = TRUE)
  if (length(trcol) == 0) { print(names(d)); stop("no treatment column") }
  trcol <- trcol[1]

  sccols <- grep("^SC0_[0-9]+$", names(d), value = TRUE)
  if (length(sccols) < 2) sccols <- grep("^SC", names(d), value = TRUE)
  if (length(sccols) < 2) { print(names(d)); stop("no score columns") }
  sccols <- sort(sccols)
  S <- sapply(sccols, function(cc) num(d[[cc]]))
  if (is.null(dim(S))) S <- matrix(S, nrow = 1, dimnames = list(NULL, sccols))

  idcol <- intersect(c("V1", "ResponseId", "ResponseID"), names(d))
  ids <- paste(d$batch_file, d$row_in_file, sep = "_")

  arm_raw <- trimws(as.character(d[[trcol]]))
  ok <- rowSums(!is.na(Tm)) == 20 & !is.na(arm_raw) & arm_raw != "" &
    !is.na(S[, 1]) & !is.na(S[, 2])
  cat("treatment column:", trcol, " score columns:", paste(sccols, collapse = ","), "\n")
  cat("complete rows:", sum(ok), "\n")

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
    Sw <- sapply(swc, function(cc) num(d[[cc]]))
    if (is.null(dim(Sw))) Sw <- matrix(Sw, ncol = length(swc))
    mxsw <- suppressWarnings(max(Sw[ok, , drop = FALSE], na.rm = TRUE))
    cat("switch columns:", length(swc), " max switch value:", mxsw, "\n")
    if (is.finite(mxsw) && mxsw <= 1) {
      swrule <- rowSums(Sw == 1, na.rm = TRUE) > 0
    } else {
      swrule <- rowSums(Sw >= 2, na.rm = TRUE) > 0
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
  list(id = ids[keep], arm_raw = arm_raw[keep], S = S[keep, , drop = FALSE],
       Tm = Tm[keep, , drop = FALSE])
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
    mx <- apply(X, 2, max, na.rm = TRUE)
    Rcol <- sapply(mx, function(m) candR[which.min(abs(candR - m))])
    cat("column maxima:\n"); print(round(mx, 2))
    cat("inferred R per column:\n"); print(Rcol)
    mA <- sum(Rcol[pairsA[, 1]] == Rcol[pairsA[, 2]])
    mB <- sum(Rcol[pairsB[, 1]] == Rcol[pairsB[, 2]])
    if (mB > mA) {
      pairs <- pairsB
    } else if (mA > mB) {
      pairs <- pairsA
    } else {
      pairs <- if (paircor(pairsB) > paircor(pairsA)) pairsB else pairsA
    }
    Rp <- pmax(Rcol[pairs[, 1]], Rcol[pairs[, 2]])
    cat("pairs used:\n"); print(pairs); cat("R per pair:", Rp, "\n")
    if (!all(table(factor(Rp, levels = candR)) == 2)) cat("WARNING: inferred R per pair not balanced\n")
    P1 <- sweep(X[, pairs[, 1], drop = FALSE], 2, Rp, "/") * 100
    P2 <- sweep(X[, pairs[, 2], drop = FALSE], 2, Rp, "/") * 100
  } else {
    if (scale_type == "fraction") X <- X * 100
    pairs <- if (paircor(pairsB) > paircor(pairsA)) pairsB else pairsA
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
  s0 <- A$S[, 1]; s1 <- A$S[, 2]
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
  if (any(is.na(lab)) || length(unique(lab)) != 4) {
    m0 <- tapply(s0, A$arm_raw, mean)[codes]
    m1 <- tapply(s1, A$arm_raw, mean)[codes]
    cat("arm means score1:\n"); print(m0); cat("arm means score2:\n"); print(m1)
    gapstat <- function(m) { sd_ <- sort(m, decreasing = TRUE); sa <- sort(m); (sd_[1] - sd_[2]) - (sa[2] - sa[1]) }
    ctrl_score <- if (gapstat(m0) >= gapstat(m1)) m0 else m1
    ctrl_code <- names(ctrl_score)[which.max(ctrl_score)]
    others <- setdiff(codes, ctrl_code)
    lab <- setNames(c("Control", c("Treatment", "Substance", "Rhetoric")[seq_along(others)]), c(ctrl_code, others))
    lab <- lab[codes]
  }
  cat("arm mapping A:\n"); print(lab)
  armA <- unname(lab[A$arm_raw])
  # orientation: compounding score rises Treatment vs Control
  d0 <- mean(s0[armA == "Treatment"]) - mean(s0[armA == "Control"])
  d1 <- mean(s1[armA == "Treatment"]) - mean(s1[armA == "Control"])
  compA_idx <- if (d0 >= d1) 1 else 2
  comp <- A$S[, compA_idx]; ctrlm <- A$S[, 3 - compA_idx]
  cat("compounding score column index (A):", compA_idx, "\n")
  cat("score max:", max(comp), max(ctrlm), "\n")

  sub <- armA %in% c("Control", "Treatment")
  tr <- as.numeric(armA[sub] == "Treatment")
  m1 <- lm(comp[sub] ~ tr); m3 <- lm(ctrlm[sub] ~ tr)
  print(summary(m1)$coefficients); print(summary(m3)$coefficients)
  add_res("test_score_compounding_treatment_minus_control_expA_table4_col1", coef(m1)["tr"])
  add_res("test_score_control_module_treatment_minus_control_expA_table4_col3", coef(m3)["tr"])
  add_res("n_obs_table4_expA_cols1_3", sum(sub))

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
  TRUE
}, error = function(e) { cat("Experiment A error:", conditionMessage(e), "\n"); FALSE })

# ------------------------------------------------------------------
# Experiment B
# ------------------------------------------------------------------
resB <- tryCatch({
  fB <- paste0("data/raw/expBbatch", 1:2, ".csv")
  dB <- bind_rows(lapply(fB, read_one))
  B <- process(dB, "Experiment B")
  s0 <- B$S[, 1]; s1 <- B$S[, 2]
  codes <- unique(B$arm_raw)
  numcodes <- suppressWarnings(as.numeric(codes))
  if (all(!is.na(numcodes))) codes <- codes[order(numcodes)] else codes <- sort(codes)
  lc <- tolower(codes)
  if (any(grepl("contr", lc))) {
    lab <- setNames(ifelse(grepl("contr", lc), "Control", "Treatment"), codes)
    armB <- unname(lab[B$arm_raw])
    d0 <- mean(s0[armB == "Treatment"]) - mean(s0[armB == "Control"])
    d1 <- mean(s1[armB == "Treatment"]) - mean(s1[armB == "Control"])
    cidx <- if (d0 >= d1) 1 else 2
  } else {
    cidx <- if (!is.na(compA_idx)) compA_idx else 1
    compm <- tapply(B$S[, cidx], B$arm_raw, mean)[codes]
    cat("compounding means by B code:\n"); print(compm)
    ctrl_code <- names(compm)[which.min(compm)]
    lab <- setNames(ifelse(codes == ctrl_code, "Control", "Treatment"), codes)
    armB <- unname(lab[B$arm_raw])
  }
  cat("arm mapping B:\n"); print(lab)
  comp <- B$S[, cidx]; ctrlm <- B$S[, 3 - cidx]
  tr <- as.numeric(armB == "Treatment")
  m2 <- lm(comp ~ tr); m4 <- lm(ctrlm ~ tr)
  print(summary(m2)$coefficients); print(summary(m4)$coefficients)
  add_res("test_score_compounding_treatment_minus_control_expB_table4_col2", coef(m2)["tr"])
  add_res("test_score_control_module_treatment_minus_control_expB_table4_col4", coef(m4)["tr"])
  add_res("n_obs_table4_expB_cols2_4", length(tr))

  dcm <- compute_dc(B$Tm)
  n <- nrow(dcm)
  longB <- data.frame(id = rep(B$id, ncol(dcm)), arm = rep(armB, ncol(dcm)),
                      pair = rep(seq_len(ncol(dcm)), each = n), dc = as.vector(dcm))
  longB$arm <- factor(longB$arm, levels = c("Control", "Treatment"))
  m7b <- feols(dc ~ 0 + arm, data = longB, cluster = ~id)
  print(summary(m7b))
  add_res("deliberative_competence_control_expB_table7_col2", coef(m7b)["armControl"])
  add_res("deliberative_competence_treatment_expB_table7_col2", coef(m7b)["armTreatment"])
  TRUE
}, error = function(e) { cat("Experiment B error:", conditionMessage(e), "\n"); FALSE })

# ------------------------------------------------------------------
# Emit results
# ------------------------------------------------------------------
for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
}