suppressPackageStartupMessages({
  library(dplyr)
  library(fixest)
})
set.seed(42)
options(width = 200, warn = 1)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice.script-free"
num <- function(x) suppressWarnings(as.numeric(as.character(x)))

read_q <- function(f) {
  d <- tryCatch(
    read.csv(f, stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character",
             fileEncoding = "UTF-8-BOM", na.strings = c("", "NA")),
    error = function(e) read.csv(f, stringsAsFactors = FALSE, check.names = FALSE,
                                 colClasses = "character", na.strings = c("", "NA")))
  nm <- names(d)
  nm <- gsub("^﻿", "", nm)
  nm <- gsub("^\xef\xbb\xbf", "", nm, useBytes = TRUE)
  nm <- gsub("^.*V1$", "V1", nm)
  nm <- trimws(nm)
  nm[nm == ""] <- paste0("unnamed_", which(nm == ""))
  names(d) <- make.unique(nm)
  d
}

keep_responses <- function(d, idcol) {
  if (!idcol %in% names(d)) return(d)
  id <- d[[idcol]]
  k <- !is.na(id) & grepl("^R_", id)
  if (sum(k) < 0.5 * nrow(d)) {
    k <- !is.na(id) & !(id %in% c("ResponseID", "ResponseId", "Response ID")) & !grepl("ImportId", id)
  }
  d[k, , drop = FALSE]
}

col_summary <- function(d, maxlines = 2000) {
  cat(sprintf("%-40s %6s %10s %10s %6s  %s\n", "column", "nonNA", "min", "max", "nuniq", "examples"))
  i <- 0
  for (v in names(d)) {
    i <- i + 1
    if (i > maxlines) break
    x <- d[[v]]
    xn <- num(x)
    nn <- sum(!is.na(x))
    nu <- length(unique(x[!is.na(x)]))
    ex <- paste(head(unique(x[!is.na(x)]), 4), collapse = " | ")
    ex <- substr(ex, 1, 60)
    if (sum(!is.na(xn)) > 0) {
      cat(sprintf("%-40s %6d %10.3g %10.3g %6d  %s\n", substr(v, 1, 40), nn,
                  min(xn, na.rm = TRUE), max(xn, na.rm = TRUE), nu, ex))
    } else {
      cat(sprintf("%-40s %6d %10s %10s %6d  %s\n", substr(v, 1, 40), nn, "-", "-", nu, ex))
    }
  }
}

# ---------------------------------------------------------------- Experiment A
fa <- file.path(base, "data/raw", paste0("expAbatch", 1:8, ".csv"))
A <- bind_rows(lapply(seq_along(fa), function(i) {
  d <- read_q(fa[i])
  d <- keep_responses(d, "V1")
  d$batch <- as.character(i)
  d
}))
cat("Experiment A rows after dropping header rows:", nrow(A), "\n")
cat("Experiment A column names:\n"); print(names(A))
cat("\n--- Experiment A column summary ---\n")
col_summary(A)

if ("V10" %in% names(A)) { cat("\nTable V10 (Finished):\n"); print(table(A$V10, useNA = "ifany")) }
cat("\nTable treatment by batch (A):\n"); print(table(A$treatment, A$batch, useNA = "ifany"))
if ("excluded" %in% names(A)) { cat("\nTable excluded (A):\n"); print(table(A$excluded, useNA = "ifany")) }

# Finished filter
if ("V10" %in% names(A) && all(na.omit(A$V10) %in% c("0", "1"))) {
  A <- A[!is.na(A$V10) & A$V10 == "1", , drop = FALSE]
}
A <- A[!is.na(A$treatment) & A$treatment != "", , drop = FALSE]
cat("Experiment A completers with treatment:", nrow(A), "\n")

multi_switch <- function(d) {
  sw <- grep("^switch", names(d), ignore.case = TRUE, value = TRUE)
  cat("Switch columns:", paste(sw, collapse = ", "), "\n")
  if (length(sw) > 0) {
    m <- sapply(sw, function(v) num(d[[v]]))
    if (is.null(dim(m))) m <- matrix(m, nrow = nrow(d))
    mx <- apply(m, 1, function(r) if (all(is.na(r))) NA_real_ else max(r, na.rm = TRUE))
    cat("Distribution of max switches per subject:\n"); print(table(mx, useNA = "ifany"))
    out <- !is.na(mx) & mx >= 2
  } else if ("excluded" %in% names(d)) {
    out <- !is.na(num(d$excluded)) & num(d$excluded) == 1
  } else out <- rep(FALSE, nrow(d))
  if ("excluded" %in% names(d)) {
    cat("Cross-tab multi-switch vs excluded:\n"); print(table(out, d$excluded, useNA = "ifany"))
  }
  out
}

A$multi <- multi_switch(A)
cat("Multiple switchers in A:", sum(A$multi), "\n")

map_arm_A <- function(x) {
  xs <- tolower(trimws(x))
  out <- rep(NA_character_, length(xs))
  if (any(grepl("[a-z]", xs[!is.na(xs)]))) {
    out[grepl("contr|index", xs)] <- "Control"
    out[grepl("subst", xs)] <- "Substance"
    out[grepl("rhet", xs)] <- "Rhetoric"
    out[is.na(out) & grepl("treat|full|compound", xs)] <- "Treatment"
  } else {
    v <- num(xs); lv <- sort(unique(v[!is.na(v)]))
    labs <- c("Control", "Treatment", "Substance", "Rhetoric")
    if (length(lv) <= 4) for (k in seq_along(lv)) out[!is.na(v) & v == lv[k]] <- labs[k]
  }
  out
}
A$arm <- map_arm_A(A$treatment)
cat("Arm mapping (A):\n"); print(table(A$treatment, A$arm, useNA = "ifany"))

A4 <- A[!A$multi & !is.na(A$arm), , drop = FALSE]
cat("Experiment A analysis sample (4 arms):", nrow(A4), "\n"); print(table(A4$arm))
ATC <- A4[A4$arm %in% c("Treatment", "Control"), , drop = FALSE]
cat("Experiment A Treatment+Control sample:", nrow(ATC), "\n")

# ---------------------------------------------------------------- Experiment B
fb <- file.path(base, "data/raw", paste0("expBbatch", 1:2, ".csv"))
B <- bind_rows(lapply(seq_along(fb), function(i) {
  d <- read_q(fb[i])
  d <- keep_responses(d, "ResponseId")
  d$batch <- as.character(i)
  d
}))
cat("\nExperiment B rows after dropping header rows:", nrow(B), "\n")
cat("Experiment B column names:\n"); print(names(B))
cat("\n--- Experiment B column summary ---\n")
col_summary(B)

if ("Finished" %in% names(B)) { cat("\nTable Finished (B):\n"); print(table(B$Finished, useNA = "ifany")) }
if ("Finished" %in% names(B)) {
  fin <- tolower(B$Finished) %in% c("true", "1")
  if (sum(fin) > 0) B <- B[fin, , drop = FALSE]
}

tcandB <- grep("^treatment$", names(B), ignore.case = TRUE, value = TRUE)
if (length(tcandB) == 0) tcandB <- grep("treat|condition|^arm|group", names(B), ignore.case = TRUE, value = TRUE)
cat("Treatment candidates (B):", paste(tcandB, collapse = ", "), "\n")
for (v in tcandB) { cat("  ", v, ":\n"); x <- B[[v]]; if (length(unique(x)) <= 8) print(table(x, useNA = "ifany")) }
tcolB <- NA_character_
for (v in tcandB) {
  ux <- unique(na.omit(B[[v]]))
  if (length(ux) == 2) { tcolB <- v; break }
}
if (is.na(tcolB) && length(tcandB) > 0) tcolB <- tcandB[1]
cat("Using treatment column (B):", tcolB, "\n")

map_arm_B <- function(x) {
  xs <- tolower(trimws(x))
  out <- rep(NA_character_, length(xs))
  if (any(grepl("[a-z]", xs[!is.na(xs)]))) {
    out[grepl("contr|divers|portf", xs)] <- "Control"
    out[is.na(out) & grepl("treat|compound|interest", xs)] <- "Treatment"
  } else {
    v <- num(xs); lv <- sort(unique(v[!is.na(v)]))
    if (length(lv) == 2) {
      out[!is.na(v) & v == lv[1]] <- "Control"
      out[!is.na(v) & v == lv[2]] <- "Treatment"
    }
  }
  out
}
B$arm <- if (!is.na(tcolB)) map_arm_B(B[[tcolB]]) else NA_character_
if (!is.na(tcolB)) { cat("Arm mapping (B):\n"); print(table(B[[tcolB]], B$arm, useNA = "ifany")) }
B <- B[!is.na(B$arm), , drop = FALSE]
cat("Experiment B completers with arm:", nrow(B), "\n")
B$multi <- multi_switch(B)
cat("Multiple switchers in B:", sum(B$multi), "\n")
B2 <- B[!B$multi, , drop = FALSE]
cat("Experiment B analysis sample:", nrow(B2), "\n"); print(table(B2$arm))

# ---------------------------------------------------------------- Test scores (Table 4)
score_cols <- function(d) {
  sc <- unique(c(grep("^SC", names(d), value = TRUE), grep("score", names(d), ignore.case = TRUE, value = TRUE)))
  sc[sapply(sc, function(v) { x <- num(d[[v]]); sum(!is.na(x)) > 0 && max(x, na.rm = TRUE) <= 5 && min(x, na.rm = TRUE) >= 0 })]
}
pick_scores <- function(d, label) {
  sc <- score_cols(d)
  cat("\nScore candidate columns (", label, "):", paste(sc, collapse = ", "), "\n")
  if (length(sc) == 0) return(list(comp = NA, ctrl = NA))
  diffs <- sapply(sc, function(v) {
    x <- num(d[[v]])
    mean(x[d$arm == "Treatment"], na.rm = TRUE) - mean(x[d$arm == "Control"], na.rm = TRUE)
  })
  for (v in sc) {
    x <- num(d[[v]])
    cat(sprintf("  %s: mean T=%.3f C=%.3f diff=%.3f nNA=%d\n", v,
                mean(x[d$arm == "Treatment"], na.rm = TRUE), mean(x[d$arm == "Control"], na.rm = TRUE),
                diffs[v], sum(is.na(x))))
  }
  # Compound-interest score: SC0_0 if present, otherwise the column with largest T-C gain;
  # control-module score: SC0_1 if present, otherwise the column with the largest C-T gain.
  comp <- if ("SC0_0" %in% sc) "SC0_0" else names(which.max(diffs))
  ctrl <- if ("SC0_1" %in% sc) "SC0_1" else names(which.min(diffs))
  if (!("SC0_0" %in% sc && "SC0_1" %in% sc)) {
    comp <- names(which.max(diffs)); ctrl <- names(which.min(diffs))
  }
  cat("  -> compounding score:", comp, "; control-module score:", ctrl, "\n")
  list(comp = comp, ctrl = ctrl)
}
tc_diff <- function(d, v) {
  if (is.na(v)) return(c(NA, NA))
  dd <- data.frame(y = num(d[[v]]), treat = as.numeric(d$arm == "Treatment"))
  m <- lm(y ~ treat, data = dd)
  c(coef(m)["treat"], sqrt(diag(vcov(m)))["treat"])
}

sA <- pick_scores(ATC, "A")
sB <- pick_scores(B2, "B")
r1 <- tryCatch(tc_diff(ATC, sA$comp), error = function(e) c(NA, NA))
r2 <- tryCatch(tc_diff(B2, sB$comp), error = function(e) c(NA, NA))
r3 <- tryCatch(tc_diff(ATC, sA$ctrl), error = function(e) c(NA, NA))
r4 <- tryCatch(tc_diff(B2, sB$ctrl), error = function(e) c(NA, NA))
cat("Table 4 diffs (coef, se):\n"); print(rbind(r1, r2, r3, r4))

# ---------------------------------------------------------------- Valuations / deliberative competence
find_vals <- function(d, label) {
  # Option 1: T1..T20 look like dollar valuations (not a task-order permutation)
  tc <- paste0("T", 1:20)
  if (all(tc %in% names(d))) {
    m <- sapply(tc, function(v) num(d[[v]]))
    perm <- mean(apply(m, 1, function(r) all(!is.na(r)) && all(sort(r) == 1:20)), na.rm = TRUE)
    cat(label, ": share of rows where T1..T20 is a permutation of 1:20 =", perm, "\n")
    if (perm < 0.5 && max(m, na.rm = TRUE) <= 25 && median(m, na.rm = TRUE) > 1) return(tc)
  }
  # Option 2: columns named like valuations
  cand <- grep("val|equiv|indiff|^ce_?[0-9]|midpoint|wtp", names(d), ignore.case = TRUE, value = TRUE)
  cand <- cand[sapply(cand, function(v) { x <- num(d[[v]]); sum(!is.na(x)) > 0.5 * nrow(d) })]
  cat(label, ": valuation-like candidate columns:", paste(cand, collapse = ", "), "\n")
  if (length(cand) == 20) return(cand)
  NULL
}

dc_long <- function(d, vc) {
  m <- sapply(vc, function(v) num(d[[v]]))
  mx <- apply(m, 2, max, na.rm = TRUE)
  Rgrid <- c(12, 14, 16, 18, 20)
  out <- list()
  for (k in 1:10) {
    s <- m[, k]; cpx <- m[, k + 10]
    if (max(mx) <= 1.01) {
      rs <- 100 * s; rc <- 100 * cpx
    } else if (max(mx) > 25) {
      rs <- s; rc <- cpx
    } else {
      R <- Rgrid[which.min(abs(Rgrid - max(mx[k], mx[k + 10])))]
      rs <- 100 * s / R; rc <- 100 * cpx / R
    }
    out[[k]] <- data.frame(id = seq_len(nrow(d)), arm = d$arm, pair = k, dc = -abs(rc - rs))
  }
  bind_rows(out)
}

dc_means <- function(L, arms) {
  L <- L[!is.na(L$dc), ]
  for (a in arms) L[[a]] <- as.numeric(L$arm == a)
  f <- as.formula(paste("dc ~ 0 +", paste(arms, collapse = " + ")))
  m <- feols(f, data = L, cluster = ~id)
  print(summary(m))
  list(coef = coef(m), n = nobs(m))
}

resA <- NULL; resB <- NULL
vA <- tryCatch(find_vals(A4, "A"), error = function(e) NULL)
if (!is.null(vA)) resA <- tryCatch(dc_means(dc_long(A4, vA), c("Control", "Treatment", "Substance", "Rhetoric")),
                                   error = function(e) { cat("DC A error:", conditionMessage(e), "\n"); NULL })
vB <- tryCatch(find_vals(B2, "B"), error = function(e) NULL)
if (!is.null(vB)) resB <- tryCatch(dc_means(dc_long(B2, vB), c("Control", "Treatment")),
                                   error = function(e) { cat("DC B error:", conditionMessage(e), "\n"); NULL })

gv <- function(r, nm) if (is.null(r) || !(nm %in% names(r$coef))) NA else unname(r$coef[nm])
nA7 <- if (!is.null(resA)) resA$n else 10 * nrow(A4)

out <- function(name, v) cat(sprintf("RESULT:%s=%s\n", name, ifelse(is.na(v), "NA", format(v, digits = 10))))
out("test_score_compounding_treatment_minus_control_expA_table4_col1", unname(r1[1]))
out("test_score_compounding_treatment_minus_control_expB_table4_col2", unname(r2[1]))
out("test_score_control_module_treatment_minus_control_expA_table4_col3", unname(r3[1]))
out("test_score_control_module_treatment_minus_control_expB_table4_col4", unname(r4[1]))
out("n_obs_table4_expA_cols1_3", nrow(ATC))
out("n_obs_table4_expB_cols2_4", nrow(B2))
out("deliberative_competence_control_expA_table7_col1", gv(resA, "Control"))
out("deliberative_competence_treatment_expA_table7_col1", gv(resA, "Treatment"))
out("deliberative_competence_substance_only_expA_table7_col1", gv(resA, "Substance"))
out("deliberative_competence_rhetoric_only_expA_table7_col1", gv(resA, "Rhetoric"))
out("deliberative_competence_control_expB_table7_col2", gv(resB, "Control"))
out("deliberative_competence_treatment_expB_table7_col2", gv(resB, "Treatment"))
out("n_obs_table7_expA_col1", nA7)
