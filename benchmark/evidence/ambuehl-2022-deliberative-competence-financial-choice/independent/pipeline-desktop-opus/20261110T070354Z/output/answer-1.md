suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice.script-free/data/raw"
num <- function(x) suppressWarnings(as.numeric(x))

read_q <- function(f) {
  d <- readr::read_csv(f, col_types = cols(.default = col_character()),
                       name_repair = "minimal", progress = FALSE)
  nm <- gsub("^﻿", "", names(d))
  nm[nm == "" | is.na(nm)] <- paste0("unnamed_", which(nm == "" | is.na(nm)))
  names(d) <- make.unique(nm)
  idc <- if ("V1" %in% names(d)) "V1" else if ("ResponseId" %in% names(d)) "ResponseId" else names(d)[1]
  ids <- d[[idc]]
  if (sum(grepl("^R_", ids)) > 0) d <- d[grepl("^R_", ids), , drop = FALSE]
  d$.id <- d[[idc]]
  d
}

load_exp <- function(files) {
  out <- list()
  for (i in seq_along(files)) {
    d <- read_q(file.path(base, files[i]))
    d$.batch <- i
    cat("File", files[i], ": rows =", nrow(d), " cols =", ncol(d), "\n")
    out[[i]] <- d
  }
  d <- bind_rows(out)
  d$.uid <- paste(d$.batch, d$.id, seq_len(nrow(d)), sep = "_")
  d
}

A <- load_exp(paste0("expAbatch", 1:8, ".csv"))
B <- load_exp(paste0("expBbatch", 1:2, ".csv"))

diag_names <- function(d, lab) {
  cat("\n==== Columns of", lab, "(", ncol(d), ") ====\n")
  cat(paste(names(d), collapse = ", "), "\n")
  for (pat in c("treat|condition|group|arm", "^SC|score", "^switch", "^T[0-9]+$", "excluded|Finished|^V10$")) {
    cs <- grep(pat, names(d), value = TRUE, ignore.case = TRUE)
    for (cc in head(cs, 45)) {
      v <- d[[cc]]
      nv <- num(v)
      if (mean(!is.na(nv) | is.na(v) | v == "") > 0.9 && any(!is.na(nv))) {
        cat(sprintf("  %-20s numeric: n=%d mean=%.3f sd=%.3f min=%.3f max=%.3f nuniq=%d\n", cc,
                    sum(!is.na(nv)), mean(nv, na.rm = TRUE), sd(nv, na.rm = TRUE),
                    min(nv, na.rm = TRUE), max(nv, na.rm = TRUE), length(unique(nv[!is.na(nv)]))))
      } else {
        tb <- head(sort(table(v, useNA = "ifany"), decreasing = TRUE), 8)
        cat(sprintf("  %-20s char: %s\n", cc, paste(names(tb), tb, sep = ":", collapse = " | ")))
      }
    }
  }
}
diag_names(A, "Experiment A")
diag_names(B, "Experiment B")

## ---------- helpers ----------
find_arm_col <- function(d, n_arms) {
  cs <- grep("treat|condition|group|arm", names(d), value = TRUE, ignore.case = TRUE)
  cs <- c(intersect("treatment", cs), setdiff(cs, "treatment"))
  for (cc in cs) {
    v <- d[[cc]]; v <- v[!is.na(v) & v != ""]
    if (length(unique(v)) == n_arms) return(cc)
  }
  NA_character_
}

find_scores <- function(d) {
  if (all(c("SC0_0", "SC0_1") %in% names(d))) return(c("SC0_0", "SC0_1"))
  cs <- grep("^SC", names(d), value = TRUE)
  cs <- cs[sapply(cs, function(cc) { x <- num(d[[cc]]); any(!is.na(x)) && max(x, na.rm = TRUE) <= 5 })]
  if (length(cs) >= 2) return(cs[1:2])
  cs <- grep("score", names(d), value = TRUE, ignore.case = TRUE)
  cs <- cs[sapply(cs, function(cc) { x <- num(d[[cc]]); any(!is.na(x)) && max(x, na.rm = TRUE) <= 5 })]
  if (length(cs) >= 2) return(cs[1:2])
  c(NA_character_, NA_character_)
}

label_arms <- function(raw, comp, four) {
  u <- unique(raw[!is.na(raw) & raw != ""])
  nu <- num(u)
  u <- if (all(!is.na(nu))) u[order(nu)] else sort(u)
  lab <- setNames(rep(NA_character_, length(u)), u)
  lu <- tolower(u)
  if (any(grepl("[a-z]", lu))) {
    lab[grepl("contr|index|divers|base", lu)] <- "Control"
    lab[is.na(lab) & grepl("subst", lu)] <- "SubstanceOnly"
    lab[is.na(lab) & grepl("rhet", lu)] <- "RhetoricOnly"
    lab[is.na(lab) & grepl("treat|full|compound|feedback|practice", lu)] <- "Treatment"
  }
  default <- if (four) c("Control", "Treatment", "SubstanceOnly", "RhetoricOnly") else c("Control", "Treatment")
  if (any(is.na(lab)) || any(duplicated(lab))) lab[] <- default[seq_along(u)]
  arm <- unname(lab[raw])
  # data check: Control should have the lowest compound-interest score
  m <- tapply(comp, arm, mean, na.rm = TRUE)
  cat("Arm mapping:", paste(names(lab), lab, sep = "->", collapse = ", "), "\n")
  cat("Mean compounding score by arm:", paste(names(m), round(m, 3), collapse = ", "), "\n")
  lowest <- names(m)[which.min(m)]
  if (lowest != "Control") {
    cat("WARNING: arm", lowest, "has lowest compounding score; swapping its label with Control\n")
    a2 <- arm
    a2[arm == lowest] <- "Control"; a2[arm == "Control"] <- lowest
    arm <- a2
  }
  arm
}

multi_switch <- function(d) {
  sc <- grep("^switch[0-9]+$", names(d), value = TRUE, ignore.case = TRUE)
  if (length(sc) > 0) {
    S <- sapply(sc, function(cc) num(d[[cc]]))
    if (is.null(dim(S))) S <- matrix(S, nrow = nrow(d))
    mx <- suppressWarnings(max(S, na.rm = TRUE))
    if (is.finite(mx) && mx >= 2) {
      ms <- apply(S, 1, function(r) any(r >= 2, na.rm = TRUE))
      cat("Multiple switchers from switch counts (>=2):", sum(ms), "\n")
      return(ms)
    }
    if (is.finite(mx) && mx == 1) {
      ms <- apply(S, 1, function(r) any(r == 1, na.rm = TRUE))
      if (mean(ms) < 0.5) {
        cat("Multiple switchers from 0/1 switch flags:", sum(ms), "\n")
        return(ms)
      }
    }
  }
  if ("excluded" %in% names(d)) {
    ex <- num(d$excluded)
    ms <- !is.na(ex) & ex == 1
    cat("Using 'excluded' column as multiple-switch flag:", sum(ms), "\n")
    return(ms)
  }
  cat("WARNING: no multiple-switch information found\n")
  rep(FALSE, nrow(d))
}

get_vals <- function(d) {
  tc <- paste0("T", 1:20)
  if (!all(tc %in% names(d))) { cat("WARNING: T1..T20 not found\n"); return(NULL) }
  V <- sapply(tc, function(cc) num(d[[cc]]))
  ok <- rowSums(!is.na(V)) == 20
  perm <- mean(apply(V[ok, , drop = FALSE], 1, function(r) all(sort(r) == 1:20)))
  cat("Share of complete rows where T1..T20 is a permutation of 1:20:", perm, "\n")
  if (perm > 0.8) { cat("WARNING: T1..T20 look like task order, not valuations\n"); return(NULL) }
  V
}

build_dc <- function(V) {
  mx <- apply(V, 2, max, na.rm = TRUE)
  cat("Column max of valuations:", round(mx, 2), "\n")
  if (max(mx) <= 21) {
    Rs <- c(12, 14, 16, 18, 20)
    R <- sapply(mx, function(m) Rs[which.min(abs(Rs - m))])
    P <- sweep(V, 2, R, "/") * 100
  } else {
    R <- rep(NA, 20)
    P <- V
  }
  cat("Estimated R per column:", R, "\n")
  sds <- apply(P, 2, sd, na.rm = TRUE)
  mns <- colMeans(P, na.rm = TRUE)
  cx <- rank(-sds, ties.method = "first") <= 10
  cat("Column SDs:", round(sds, 2), "\n")
  cat("Column means:", round(mns, 2), "\n")
  cat("Complex-frame columns (high SD):", which(cx), "\n")
  si <- which(!cx); ci <- which(cx)
  Rs_ <- ifelse(is.na(R), 0, R)
  si <- si[order(-Rs_[si], -mns[si])]
  ci <- ci[order(-Rs_[ci], -mns[ci])]
  cat("Pairs (simple, complex):", paste0("(", si, ",", ci, ")", collapse = " "), "\n")
  if (any(Rs_[si] != Rs_[ci])) cat("WARNING: paired columns differ in R\n")
  -abs(P[, ci, drop = FALSE] - P[, si, drop = FALSE])
}

## ---------- Experiment A ----------
res <- list()
prep <- function(d, four, lab) {
  cat("\n######## Processing", lab, "########\n")
  sc <- find_scores(d)
  cat("Score columns (compounding, control module):", sc, "\n")
  if (all(c("SC0_0", "SC0_1", "SC0_2") %in% names(d))) {
    s2 <- num(d$SC0_2); s01 <- num(d$SC0_0) + num(d$SC0_1)
    cat("SC0_2 == SC0_0 + SC0_1 share:", mean(s2 == s01, na.rm = TRUE), "\n")
  }
  d$comp <- num(d[[sc[1]]]); d$ctrl <- num(d[[sc[2]]])
  ac <- find_arm_col(d, if (four) 4 else 2)
  cat("Arm column:", ac, "\n")
  d$arm <- label_arms(d[[ac]], d$comp, four)
  d$ms <- multi_switch(d)
  V <- tryCatch(get_vals(d), error = function(e) { cat("get_vals error:", conditionMessage(e), "\n"); NULL })
  complete <- !is.na(d$arm) & !is.na(d$comp) & !is.na(d$ctrl)
  if (!is.null(V)) complete <- complete & rowSums(!is.na(V)) == 20
  if ("Finished" %in% names(d)) cat("Finished table:", paste(names(table(d$Finished)), table(d$Finished), collapse = " "), "\n")
  cat("Complete:", sum(complete), " multiple switchers among complete:", sum(d$ms & complete), "\n")
  keep <- complete & !d$ms
  cat("Kept subjects:", sum(keep), "\n")
  print(table(d$arm[keep]))
  list(d = d[keep, , drop = FALSE], V = if (is.null(V)) NULL else V[keep, , drop = FALSE])
}

pa <- prep(A, TRUE, "Experiment A")
pb <- prep(B, FALSE, "Experiment B")

t4 <- function(dd, y) {
  dd$treat <- as.integer(dd$arm == "Treatment")
  m <- feols(as.formula(paste(y, "~ treat")), data = dd, vcov = "iid")
  print(summary(m))
  unname(coef(m)["treat"])
}

dA2 <- pa$d[pa$d$arm %in% c("Control", "Treatment"), ]
dB2 <- pb$d[pb$d$arm %in% c("Control", "Treatment"), ]
res$test_score_compounding_treatment_minus_control_expA_table4_col1 <- tryCatch(t4(dA2, "comp"), error = function(e) NA)
res$test_score_compounding_treatment_minus_control_expB_table4_col2 <- tryCatch(t4(dB2, "comp"), error = function(e) NA)
res$test_score_control_module_treatment_minus_control_expA_table4_col3 <- tryCatch(t4(dA2, "ctrl"), error = function(e) NA)
res$test_score_control_module_treatment_minus_control_expB_table4_col4 <- tryCatch(t4(dB2, "ctrl"), error = function(e) NA)
res$n_obs_table4_expA_cols1_3 <- nrow(dA2)
res$n_obs_table4_expB_cols2_4 <- nrow(dB2)

t7 <- function(p) {
  if (is.null(p$V)) stop("no valuations")
  DC <- build_dc(p$V)
  long <- data.frame(id = rep(p$d$.uid, times = ncol(DC)),
                     arm = rep(p$d$arm, times = ncol(DC)),
                     dc = as.vector(DC))
  m <- feols(dc ~ 0 + arm, data = long, cluster = ~id)
  print(summary(m))
  list(coef = coef(m), n = nobs(m))
}

rA <- tryCatch(t7(pa), error = function(e) { cat("Table 7 A error:", conditionMessage(e), "\n"); NULL })
rB <- tryCatch(t7(pb), error = function(e) { cat("Table 7 B error:", conditionMessage(e), "\n"); NULL })
g <- function(r, k) if (is.null(r) || !(k %in% names(r$coef))) NA else unname(r$coef[k])
res$deliberative_competence_control_expA_table7_col1 <- g(rA, "armControl")
res$deliberative_competence_treatment_expA_table7_col1 <- g(rA, "armTreatment")
res$deliberative_competence_substance_only_expA_table7_col1 <- g(rA, "armSubstanceOnly")
res$deliberative_competence_rhetoric_only_expA_table7_col1 <- g(rA, "armRhetoricOnly")
res$deliberative_competence_control_expB_table7_col2 <- g(rB, "armControl")
res$deliberative_competence_treatment_expB_table7_col2 <- g(rB, "armTreatment")
res$n_obs_table7_expA_col1 <- if (is.null(rA)) NA else rA$n

cat("\n")
for (k in names(res)) cat(sprintf("RESULT:%s=%s\n", k, format(res[[k]], digits = 10)))
