suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)
options(warn = 1)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice.script-free"
raw <- file.path(base, "data", "raw")

num <- function(x) suppressWarnings(as.numeric(as.character(x)))
dg <- function(...) cat("DIAG:", ..., "\n")

rd <- function(f) {
  d <- readr::read_csv(file.path(raw, f),
                       col_types = readr::cols(.default = readr::col_character()),
                       show_col_types = FALSE, progress = FALSE,
                       name_repair = "minimal")
  nm <- names(d)
  nm <- gsub("﻿", "", nm, fixed = TRUE)
  nm <- trimws(nm)
  blank <- nm == "" | is.na(nm)
  if (any(blank)) nm[blank] <- paste0("X_blank_", seq_len(sum(blank)))
  nm <- make.unique(nm)
  names(d) <- nm
  as.data.frame(d, stringsAsFactors = FALSE)
}

res <- list()
emit_store <- function(name, val) { res[[name]] <<- val }

lab_arm <- function(x) {
  x <- tolower(as.character(x))
  ifelse(grepl("contr", x), "Control",
    ifelse(grepl("rhet", x), "Rhetoric",
      ifelse(grepl("subst", x), "Substance",
        ifelse(grepl("treat|full|comp", x), "Treatment", NA_character_))))
}

# Relaxed score-column detection: ^SC columns first, then other "score" columns.
score_cands <- function(d, label) {
  cs1 <- grep("^SC", names(d), value = TRUE, ignore.case = TRUE)
  cs2 <- setdiff(grep("score", names(d), value = TRUE, ignore.case = TRUE), cs1)
  cs <- c(cs1, cs2)
  keep <- character(0)
  for (c in cs) {
    x <- num(d[[c]])
    shr <- mean(is.finite(x))
    if (sum(is.finite(x)) == 0) { dg(label, "score col", c, "| no numeric values"); next }
    nd <- length(unique(x[is.finite(x)]))
    dg(label, "score col", c, "| finite share", round(shr, 3), "| min", min(x, na.rm = TRUE),
       "| max", max(x, na.rm = TRUE), "| distinct", nd)
    if (shr > 0.3 && min(x, na.rm = TRUE) >= 0 && nd >= 2) keep <- c(keep, c)
  }
  keep
}

multi_flag <- function(d, label) {
  sw <- grep("^switch[0-9]+$", names(d), value = TRUE, ignore.case = TRUE)
  if (length(sw) == 0) {
    dg(label, "no switch columns found")
    if ("excluded" %in% names(d)) return(num(d$excluded) %in% 1)
    return(rep(FALSE, nrow(d)))
  }
  S <- sapply(sw, function(c) num(d[[c]]))
  if (is.null(dim(S))) S <- matrix(S, nrow = nrow(d))
  mxs <- apply(S, 1, function(x) if (all(is.na(x))) NA else max(x, na.rm = TRUE))
  vals <- unique(as.vector(S)); vals <- vals[is.finite(vals)]
  shr1 <- mean(mxs >= 1, na.rm = TRUE)
  dg(label, "switch cols:", length(sw), "| distinct values:", paste(sort(vals), collapse = " "),
     "| share any>=1:", round(shr1, 3))
  if (all(vals %in% c(0, 1)) && shr1 < 0.5) m <- mxs >= 1 else m <- mxs >= 2
  m[is.na(m)] <- FALSE
  m
}

build_dc <- function(V, label) {
  allv <- as.vector(V); allv <- allv[is.finite(allv)]
  mx <- max(allv)
  dg(label, "valuation summary: min", min(allv), "median", median(allv), "max", mx)
  tmax <- apply(V, 2, function(x) max(x, na.rm = TRUE))
  tmean <- colMeans(V, na.rm = TRUE)
  dg(label, "task max:", paste(round(tmax, 2), collapse = " "))
  dg(label, "task mean:", paste(round(tmean, 2), collapse = " "))
  schemes <- list(block = cbind(1:10, 11:20), alt = cbind(seq(1, 19, 2), seq(2, 20, 2)))
  if (mx <= 1.5) {
    pick <- "block"
    pr <- schemes[[pick]]
    P <- V * 100
  } else if (mx <= 25) {
    Rhat <- pmin(20, pmax(12, 2 * round(tmax / 2)))
    sc <- sapply(schemes, function(s) sum(Rhat[s[, 1]] == Rhat[s[, 2]]))
    dg(label, "Rhat:", paste(Rhat, collapse = " "), "| scheme matches:",
       paste(names(sc), sc, collapse = " "))
    pick <- names(sc)[which.max(sc)]
    pr <- schemes[[pick]]
    Rpair <- pmin(20, pmax(12, 2 * round(pmax(tmax[pr[, 1]], tmax[pr[, 2]]) / 2)))
    dg(label, "R per pair:", paste(Rpair, collapse = " "))
    P <- V
    for (k in seq_len(nrow(pr))) {
      P[, pr[k, 1]] <- V[, pr[k, 1]] / Rpair[k] * 100
      P[, pr[k, 2]] <- V[, pr[k, 2]] / Rpair[k] * 100
    }
  } else {
    pick <- "block"
    pr <- schemes[[pick]]
    P <- V
  }
  dg(label, "pairing scheme:", pick)
  D <- -abs(P[, pr[, 1], drop = FALSE] - P[, pr[, 2], drop = FALSE])
  D
}

find_T_cols <- function(d) {
  tc <- paste0("T", 1:20)
  if (all(tc %in% names(d))) return(tc)
  alt <- grep("^(T|r|val|value|v|task)[_ ]?[0-9]+$", names(d), value = TRUE, ignore.case = TRUE)
  if (length(alt) == 20) {
    o <- order(num(gsub("[^0-9]", "", alt)))
    return(alt[o])
  }
  NULL
}

dc_regression <- function(D, arm, levels_) {
  n <- nrow(D)
  long <- data.frame(sid = rep(seq_len(n), times = ncol(D)),
                     arm = rep(arm, times = ncol(D)),
                     d = as.vector(D), stringsAsFactors = FALSE)
  long <- long[is.finite(long$d), ]
  for (l in levels_) long[[paste0("arm_", l)]] <- as.integer(long$arm == l)
  fml <- as.formula(paste("d ~ 0 +", paste(paste0("arm_", levels_), collapse = " + ")))
  m <- feols(fml, data = long, cluster = ~sid)
  print(summary(m))
  list(coef = coef(m), nobs = nobs(m))
}

compA <- NULL

# ------------------------- Experiment A -------------------------
tryCatch({
  A <- dplyr::bind_rows(lapply(1:8, function(b) {
    d <- rd(sprintf("expAbatch%d.csv", b)); d$batch_ <- b; d
  }))
  if ("V1" %in% names(A)) A <- A[is.na(A$V1) | A$V1 != "ResponseID", ]
  if ("StartDate" %in% names(A)) A <- A[is.na(A$StartDate) | grepl("^[0-9]", A$StartDate), ]
  dg("A rows:", nrow(A), "| cols:", ncol(A))
  nmA <- names(A)
  dg("A interesting cols:", paste(head(grep("treat|cond|group|arm|^T[0-9]|switch|^SC|exclu|score|amt|line|val",
                                            nmA, value = TRUE, ignore.case = TRUE), 200), collapse = ","))
  tA <- find_T_cols(A)
  if (is.null(tA)) stop("A: valuation columns not found")
  VA <- sapply(tA, function(c) num(A[[c]]))
  okV <- rowSums(is.finite(VA)) == 20
  okT <- !is.na(A$treatment) & trimws(A$treatment) != ""
  dg("A okV:", sum(okV), "| okT:", sum(okT), "| both:", sum(okV & okT))
  scA <- score_cands(A[okV & okT, , drop = FALSE], "A")
  dg("A score candidates:", paste(scA, collapse = " "))
  if (length(scA) < 1) stop("A: no score columns")
  has2A <- length(scA) >= 2
  s1all <- num(A[[scA[1]]])
  s2all <- if (has2A) num(A[[scA[2]]]) else rep(NA_real_, nrow(A))
  completeA <- okV & okT & is.finite(s1all) & (if (has2A) is.finite(s2all) else TRUE)
  mA <- multi_flag(A, "A")
  dg("A completed:", sum(completeA), "| multi-switchers among completed:", sum(mA & completeA))
  if ("excluded" %in% names(A)) {
    dg("A table excluded vs multi (completed):")
    print(table(excluded = A$excluded[completeA], multi = mA[completeA], useNA = "ifany"))
  }
  keep <- completeA & !mA
  dg("A kept:", sum(keep))
  trtA <- trimws(A$treatment[keep])
  dg("A treatment values:"); print(table(trtA))
  s1 <- s1all[keep]; s2 <- s2all[keep]
  labs <- lab_arm(trtA)
  if (all(!is.na(labs)) && length(unique(labs)) == 4) {
    armA <- labs
    if (has2A) {
      d1 <- mean(s1[armA == "Treatment"]) - mean(s1[armA == "Control"])
      d2 <- mean(s2[armA == "Treatment"]) - mean(s2[armA == "Control"])
      comp <- if (d1 >= d2) 1 else 2
    } else comp <- 1
  } else {
    codes <- unique(trtA)
    cn <- num(codes)
    codes <- if (all(!is.na(cn))) codes[order(cn)] else sort(codes)
    if (has2A) {
      dj <- sapply(codes, function(k) mean(s1[trtA == k] - s2[trtA == k]))
      dist <- sapply(seq_along(codes), function(j) abs(dj[j] - mean(dj[-j])))
      cj <- which.max(dist)
      comp <- if (dj[cj] < mean(dj[-cj])) 1 else 2
    } else {
      dj <- sapply(codes, function(k) mean(s1[trtA == k]))
      cj <- which.min(dj)
      comp <- 1
    }
    compS <- if (comp == 1) s1 else s2
    map <- character(length(codes))
    if (cj == 1 && has2A) {
      map <- c("Control", "Treatment", "Substance", "Rhetoric")[seq_along(codes)]
    } else {
      map[cj] <- "Control"
      oth <- setdiff(seq_along(codes), cj)
      cm <- sapply(oth, function(j) mean(compS[trtA == codes[j]]))
      rj <- oth[which.min(cm)]
      map[rj] <- "Rhetoric"
      rest <- setdiff(oth, rj)
      map[rest] <- c("Treatment", "Substance")[seq_along(rest)]
    }
    dg("A code mapping:", paste(codes, map, sep = "->", collapse = " "))
    armA <- map[match(trtA, codes)]
  }
  compA <<- scA[comp]
  ctrlA <- if (has2A) scA[3 - comp] else NA
  dg("A compound score col:", compA, "| control-module score col:", ctrlA)
  scoreComp <- if (comp == 1) s1 else s2
  scoreCtrl <- if (comp == 1) s2 else s1
  print(tapply(scoreComp, armA, mean))
  if (has2A) print(tapply(scoreCtrl, armA, mean))

  # Table 4, Experiment A
  ct <- armA %in% c("Control", "Treatment")
  t4 <- data.frame(comp = scoreComp[ct], ctrl = scoreCtrl[ct], treat = as.integer(armA[ct] == "Treatment"))
  m1 <- feols(comp ~ treat, data = t4, vcov = "iid")
  print(summary(m1))
  emit_store("test_score_compounding_treatment_minus_control_expA_table4_col1", unname(coef(m1)["treat"]))
  emit_store("n_obs_table4_expA_cols1_3", nobs(m1))
  if (has2A) {
    m3 <- feols(ctrl ~ treat, data = t4, vcov = "iid")
    print(summary(m3))
    emit_store("test_score_control_module_treatment_minus_control_expA_table4_col3", unname(coef(m3)["treat"]))
  }

  # Table 7, Experiment A
  DA <- build_dc(VA[keep, , drop = FALSE], "A")
  rA <- dc_regression(DA, armA, c("Control", "Treatment", "Substance", "Rhetoric"))
  emit_store("deliberative_competence_control_expA_table7_col1", unname(rA$coef["arm_Control"]))
  emit_store("deliberative_competence_treatment_expA_table7_col1", unname(rA$coef["arm_Treatment"]))
  emit_store("deliberative_competence_substance_only_expA_table7_col1", unname(rA$coef["arm_Substance"]))
  emit_store("deliberative_competence_rhetoric_only_expA_table7_col1", unname(rA$coef["arm_Rhetoric"]))
  emit_store("n_obs_table7_expA_col1", rA$nobs)
}, error = function(e) dg("Experiment A error:", conditionMessage(e)))

# ------------------------- Experiment B -------------------------
tryCatch({
  B <- dplyr::bind_rows(rd("expBbatch1.csv"), rd("expBbatch2.csv"))
  if ("StartDate" %in% names(B)) B <- B[grepl("^[0-9]", B$StartDate), ]
  dg("B rows:", nrow(B), "| cols:", ncol(B))
  nmB <- names(B)
  trcol <- nmB[tolower(nmB) == "treatment"]
  if (length(trcol) == 0) trcol <- grep("^treat", nmB, value = TRUE, ignore.case = TRUE)
  if (length(trcol) == 0) trcol <- grep("condition|^group$|^arm$", nmB, value = TRUE, ignore.case = TRUE)
  if (length(trcol) == 0) {
    dg("B first 300 cols:", paste(head(nmB, 300), collapse = ","))
    stop("B: treatment column not found")
  }
  trcol <- trcol[1]
  dg("B treatment col:", trcol)
  tB <- find_T_cols(B)
  if (is.null(tB)) {
    dg("B first 300 cols:", paste(head(nmB, 300), collapse = ","))
    stop("B: valuation columns not found")
  }
  VB <- sapply(tB, function(c) num(B[[c]]))
  okV <- rowSums(is.finite(VB)) == 20
  okT <- !is.na(B[[trcol]]) & trimws(B[[trcol]]) != ""
  dg("B okV:", sum(okV), "| okT:", sum(okT), "| both:", sum(okV & okT))
  scB <- score_cands(B[okV & okT, , drop = FALSE], "B")
  dg("B score candidates:", paste(scB, collapse = " "))
  if (length(scB) < 1) stop("B: no score columns")
  has2B <- length(scB) >= 2
  if (!is.null(compA) && compA %in% scB) {
    compB <- compA
    ctrlB <- if (has2B) setdiff(scB, compB)[1] else NA
  } else {
    compB <- scB[1]; ctrlB <- if (has2B) scB[2] else NA
  }
  sc_all <- num(B[[compB]])
  sk_all <- if (has2B) num(B[[ctrlB]]) else rep(NA_real_, nrow(B))
  completeB <- okV & okT & is.finite(sc_all) & (if (has2B) is.finite(sk_all) else TRUE)
  mB <- multi_flag(B, "B")
  dg("B completed:", sum(completeB), "| multi-switchers among completed:", sum(mB & completeB))
  keepB <- completeB & !mB
  dg("B kept:", sum(keepB))
  trtB <- trimws(B[[trcol]][keepB])
  dg("B treatment values:"); print(table(trtB))
  sc <- sc_all[keepB]; sk <- sk_all[keepB]
  labs <- lab_arm(trtB)
  if (all(!is.na(labs)) && all(c("Control", "Treatment") %in% labs) && length(unique(labs)) == 2) {
    armB <- labs
    if (has2B && mean(sc[armB == "Treatment"]) - mean(sc[armB == "Control"]) <
        mean(sk[armB == "Treatment"]) - mean(sk[armB == "Control"])) {
      tmp <- sc; sc <- sk; sk <- tmp
      tmpn <- compB; compB <- ctrlB; ctrlB <- tmpn
    }
  } else {
    codes <- unique(trtB)
    cn <- num(codes)
    codes <- if (all(!is.na(cn))) codes[order(cn)] else sort(codes)
    mc <- sapply(codes, function(k) mean(sc[trtB == k]))
    ctrl_code <- codes[which.min(mc)]
    armB <- ifelse(trtB == ctrl_code, "Control", "Treatment")
    dg("B control code:", ctrl_code)
  }
  dg("B compound score col:", compB, "| control-module score col:", ctrlB)
  print(tapply(sc, armB, mean))
  if (has2B) print(tapply(sk, armB, mean))

  t4 <- data.frame(comp = sc, ctrl = sk, treat = as.integer(armB == "Treatment"))
  m2 <- feols(comp ~ treat, data = t4, vcov = "iid")
  print(summary(m2))
  emit_store("test_score_compounding_treatment_minus_control_expB_table4_col2", unname(coef(m2)["treat"]))
  emit_store("n_obs_table4_expB_cols2_4", nobs(m2))
  if (has2B) {
    m4 <- feols(ctrl ~ treat, data = t4, vcov = "iid")
    print(summary(m4))
    emit_store("test_score_control_module_treatment_minus_control_expB_table4_col4", unname(coef(m4)["treat"]))
  }

  DB <- build_dc(VB[keepB, , drop = FALSE], "B")
  rB <- dc_regression(DB, armB, c("Control", "Treatment"))
  emit_store("deliberative_competence_control_expB_table7_col2", unname(rB$coef["arm_Control"]))
  emit_store("deliberative_competence_treatment_expB_table7_col2", unname(rB$coef["arm_Treatment"]))
}, error = function(e) dg("Experiment B error:", conditionMessage(e)))

# ------------------------- Output -------------------------
order_names <- c(
  "test_score_compounding_treatment_minus_control_expA_table4_col1",
  "test_score_compounding_treatment_minus_control_expB_table4_col2",
  "test_score_control_module_treatment_minus_control_expA_table4_col3",
  "test_score_control_module_treatment_minus_control_expB_table4_col4",
  "n_obs_table4_expA_cols1_3",
  "n_obs_table4_expB_cols2_4",
  "deliberative_competence_control_expA_table7_col1",
  "deliberative_competence_treatment_expA_table7_col1",
  "deliberative_competence_substance_only_expA_table7_col1",
  "deliberative_competence_rhetoric_only_expA_table7_col1",
  "deliberative_competence_control_expB_table7_col2",
  "deliberative_competence_treatment_expB_table7_col2",
  "n_obs_table7_expA_col1"
)
for (nm in order_names) {
  v <- res[[nm]]
  if (!is.null(v) && length(v) == 1 && is.finite(v)) {
    cat(sprintf("RESULT:%s=%.6f\n", nm, as.numeric(v)))
  }
}
