suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice.script-free"
num <- function(x) suppressWarnings(as.numeric(as.character(x)))

read_batch <- function(f) {
  df <- readr::read_csv(f, col_types = cols(.default = col_character()),
                        show_col_types = FALSE, progress = FALSE)
  names(df) <- sub("^﻿", "", names(df))
  names(df) <- sub("^\xef\xbb\xbf", "", names(df), useBytes = TRUE)
  df$.batch <- basename(f)
  df$.batchno <- as.integer(gsub("\\D", "", sub(".*batch", "", basename(f))))
  df
}

out <- list()
emit <- function(name, val) {
  v <- if (is.null(val) || length(val) == 0 || is.na(val)) "NA" else format(val, digits = 10)
  cat(sprintf("RESULT:%s=%s\n", name, v))
}

## ---------- helpers ----------
safe_filter_keep <- function(df, keep, label) {
  keep[is.na(keep)] <- TRUE
  if (mean(keep) < 0.3) {
    message(label, ": filter would drop ", sum(!keep), " of ", length(keep), " rows; skipped")
    return(df)
  }
  message(label, ": dropping ", sum(!keep), " rows")
  df[keep, , drop = FALSE]
}

switch_exclusion <- function(df, label) {
  sw <- grep("^switch_?\\d+$", names(df), value = TRUE, ignore.case = TRUE)
  if (length(sw) == 0) sw <- grep("switch", names(df), value = TRUE, ignore.case = TRUE)
  if (length(sw) == 0) { message(label, ": no switch columns"); return(df) }
  M <- sapply(sw, function(s) num(df[[s]]))
  if (is.null(dim(M))) M <- matrix(M, nrow = nrow(df))
  mx <- apply(M, 1, function(r) if (all(is.na(r))) NA else max(r, na.rm = TRUE))
  overall <- suppressWarnings(max(mx, na.rm = TRUE))
  message(label, ": switch cols=", length(sw), " overall max=", overall)
  if (is.finite(overall) && overall >= 2) {
    drop <- !is.na(mx) & mx >= 2
  } else if (is.finite(overall) && overall == 1) {
    drop <- !is.na(mx) & mx >= 1
    if (mean(drop) > 0.5) drop <- rep(FALSE, nrow(df))
  } else drop <- rep(FALSE, nrow(df))
  message(label, ": multiple switchers dropped = ", sum(drop))
  df[!drop, , drop = FALSE]
}

get_scores <- function(df) {
  sc <- grep("^SC\\d", names(df), value = TRUE)
  sc <- sc[sapply(sc, function(s) mean(!is.na(num(df[[s]]))) > 0.5)]
  if (length(sc) >= 3) {
    M <- sapply(sc, function(s) num(df[[s]]))
    for (j in seq_along(sc)) {
      others <- rowSums(M[, -j, drop = FALSE])
      if (mean(abs(M[, j] - others) < 1e-8, na.rm = TRUE) > 0.9) { sc <- sc[-j]; break }
    }
  }
  if (length(sc) > 2) {
    ok <- sc[sapply(sc, function(s) max(num(df[[s]]), na.rm = TRUE) <= 5)]
    if (length(ok) >= 2) sc <- ok
    sc <- sc[1:2]
  }
  message("score columns used: ", paste(sc, collapse = ","))
  sc
}

label_arms <- function(tr, s1, s2, batchno, nArms) {
  lt <- tolower(trimws(tr))
  lab <- rep(NA_character_, length(lt))
  lab[grepl("rhet", lt)] <- "Rhetoric"
  lab[is.na(lab) & grepl("subst", lt)] <- "Substance"
  lab[is.na(lab) & grepl("control|index|divers|portfolio", lt)] <- "Control"
  lab[is.na(lab) & grepl("treat|compound|interest", lt)] <- "Treatment"
  if (mean(!is.na(lab[!is.na(lt)])) > 0.9) return(lab)
  # numeric / opaque codes: identify from data
  codes <- sort(unique(lt[!is.na(lt) & lt != ""]))
  m1 <- tapply(s1, lt, mean, na.rm = TRUE)[codes]
  m2 <- tapply(s2, lt, mean, na.rm = TRUE)[codes]
  ctrl <- codes[which.max(m2 - m1)]
  rest <- setdiff(codes, ctrl)
  map <- setNames(rep(NA_character_, length(codes)), codes)
  map[ctrl] <- "Control"
  if (nArms == 2 || length(rest) == 1) {
    map[rest[1]] <- "Treatment"
  } else {
    rhet <- rest[which.min(m1[rest])]
    map[rhet] <- "Rhetoric"
    rest2 <- setdiff(rest, rhet)
    if (length(rest2) >= 2) {
      firstb <- sapply(rest2, function(cd) min(batchno[lt == cd], na.rm = TRUE))
      ord <- order(firstb, suppressWarnings(as.numeric(rest2)), rest2)
      map[rest2[ord[1]]] <- "Treatment"
      map[rest2[ord[2]]] <- "Substance"
    } else if (length(rest2) == 1) map[rest2] <- "Treatment"
  }
  message("arm code map: ", paste(names(map), map, sep = "=", collapse = "; "))
  unname(map[lt])
}

find_pairs <- function(df) {
  nm <- names(df)
  # 1) named columns carrying reward and delay
  rx <- "(^|[^0-9])(12|14|16|18|20)[^0-9]+(36|72)([^0-9]|$)"
  cand <- nm[grepl(rx, nm)]
  cand <- cand[sapply(cand, function(s) mean(!is.na(num(df[[s]]))) > 0.5)]
  if (length(cand) >= 20) {
    R <- as.numeric(sub(paste0(".*", rx, ".*"), "\\2", cand))
    t <- as.numeric(sub(paste0(".*", rx, ".*"), "\\3", cand))
    key <- paste(R, t)
    tab <- table(key)
    if (all(tab == 2) && length(tab) == 10) {
      pairs <- lapply(names(tab), function(k) {
        cc <- cand[key == k]; list(a = cc[1], b = cc[2], R = R[key == k][1])
      })
      message("pairs from named columns")
      return(pairs)
    }
  }
  # 2) T1..T20 block
  tc <- paste0("T", 1:20)
  if (!all(tc %in% nm)) return(NULL)
  M <- sapply(tc, function(s) num(df[[s]]))
  q99 <- apply(M, 2, function(x) quantile(x, 0.99, na.rm = TRUE))
  message("T col q99: ", paste(round(q99, 2), collapse = ","))
  Rs <- c(12, 14, 16, 18, 20)
  Rhat <- sapply(q99, function(q) if (is.finite(q) && q >= 9 && q <= 23) Rs[which.min(abs(Rs - q))] else NA)
  mk <- function(idx) lapply(idx, function(p) list(a = tc[p[1]], b = tc[p[2]], R = Rhat[p[1]]))
  P1 <- lapply(1:10, function(k) c(k, k + 10))
  P2 <- lapply(1:10, function(k) c(2 * k - 1, 2 * k))
  if (all(!is.na(Rhat))) {
    if (all(sapply(P1, function(p) Rhat[p[1]] == Rhat[p[2]]))) { message("pairs (k,k+10)"); return(mk(P1)) }
    if (all(sapply(P2, function(p) Rhat[p[1]] == Rhat[p[2]]))) { message("pairs (2k-1,2k)"); return(mk(P2)) }
    grp <- split(seq_along(tc), Rhat)
    if (all(sapply(grp, length) == 4)) {
      P3 <- unlist(lapply(grp, function(g) list(c(g[1], g[3]), c(g[2], g[4]))), recursive = FALSE)
      message("pairs within inferred-R groups")
      return(mk(P3))
    }
  }
  message("pairs default (k,k+10)")
  mk(P1)
}

build_dc <- function(df, arm) {
  pairs <- find_pairs(df)
  if (is.null(pairs)) return(NULL)
  rows <- lapply(seq_along(pairs), function(j) {
    p <- pairs[[j]]
    va <- num(df[[p$a]]); vb <- num(df[[p$b]])
    allv <- c(va, vb); mx <- max(allv, na.rm = TRUE)
    if (mx <= 1.05) { ra <- 100 * va; rb <- 100 * vb }
    else if (mx > 25) { ra <- va; rb <- vb }
    else { R <- if (is.na(p$R)) 20 else p$R; ra <- 100 * va / R; rb <- 100 * vb / R }
    data.frame(id = seq_len(nrow(df)), pair = j, arm = arm, d = -abs(ra - rb))
  })
  dd <- do.call(rbind, rows)
  dd[!is.na(dd$d) & !is.na(dd$arm), ]
}

diff_tc <- function(y, arm) {
  keep <- arm %in% c("Treatment", "Control") & !is.na(y)
  d <- data.frame(y = y[keep], tr = as.numeric(arm[keep] == "Treatment"))
  m <- lm(y ~ tr, data = d)
  list(coef = unname(coef(m)["tr"]), n = nrow(d))
}

## ---------- Experiment A ----------
fA <- file.path(base, "data/raw", paste0("expAbatch", 1:8, ".csv"))
A <- bind_rows(lapply(fA, read_batch))
if ("V1" %in% names(A)) A <- A[!(A$V1 %in% c("ResponseID", "Response ID")) & !grepl("ImportId", A$V1), ]
message("Exp A raw rows: ", nrow(A))
if ("V10" %in% names(A)) A <- safe_filter_keep(A, A$V10 %in% c("1", "True", "TRUE") | is.na(A$V10), "A finished")
if ("excluded" %in% names(A)) A <- safe_filter_keep(A, !(num(A$excluded) %in% 1), "A excluded")
A <- A[!is.na(A$treatment) & trimws(A$treatment) != "", ]
message("Exp A treatment values: ", paste(names(table(A$treatment)), table(A$treatment), collapse = "; "))
A <- switch_exclusion(A, "A")
scA <- get_scores(A)
s1A <- num(A[[scA[1]]]); s2A <- num(A[[scA[2]]])
armA <- label_arms(A$treatment, s1A, s2A, A$.batchno, 4)
message("Exp A arms: ", paste(names(table(armA)), table(armA), collapse = "; "))

t1 <- diff_tc(s1A, armA); t3 <- diff_tc(s2A, armA)
dcA <- build_dc(A, armA)

## ---------- Experiment B ----------
fB <- file.path(base, "data/raw", paste0("expBbatch", 1:2, ".csv"))
B <- bind_rows(lapply(fB, read_batch))
if ("StartDate" %in% names(B)) B <- B[grepl("^\\d", B$StartDate), ]
message("Exp B raw rows: ", nrow(B))
if ("Status" %in% names(B)) B <- safe_filter_keep(B, !(B$Status %in% c("1", "Survey Preview")), "B status")
if ("Finished" %in% names(B)) B <- safe_filter_keep(B, B$Finished %in% c("1", "True", "TRUE"), "B finished")
if ("excluded" %in% names(B)) B <- safe_filter_keep(B, !(num(B$excluded) %in% 1), "B excluded")
trcol <- names(B)[tolower(names(B)) == "treatment"]
if (length(trcol) == 0) trcol <- names(B)[tolower(names(B)) %in% c("condition", "group", "arm", "treat")]
t2 <- list(coef = NA, n = NA); t4 <- list(coef = NA, n = NA); dcB <- NULL
if (length(trcol) > 0) {
  B$treatment <- B[[trcol[1]]]
  B <- B[!is.na(B$treatment) & trimws(B$treatment) != "", ]
  message("Exp B treatment values: ", paste(names(table(B$treatment)), table(B$treatment), collapse = "; "))
  B <- switch_exclusion(B, "B")
  scB <- get_scores(B)
  if (length(scB) >= 2) {
    s1B <- num(B[[scB[1]]]); s2B <- num(B[[scB[2]]])
    armB <- label_arms(B$treatment, s1B, s2B, B$.batchno, 2)
    message("Exp B arms: ", paste(names(table(armB)), table(armB), collapse = "; "))
    t2 <- diff_tc(s1B, armB); t4 <- diff_tc(s2B, armB)
    dcB <- build_dc(B, armB)
  }
} else message("Exp B: no treatment column found")

## ---------- Table 7 ----------
lvl <- function(dc, a) {
  if (is.null(dc) || !any(dc$arm == a)) return(NA)
  dc$arm <- factor(dc$arm)
  m <- lm(d ~ 0 + arm, data = dc)
  unname(coef(m)[paste0("arm", a)])
}

emit("test_score_compounding_treatment_minus_control_expA_table4_col1", t1$coef)
emit("test_score_compounding_treatment_minus_control_expB_table4_col2", t2$coef)
emit("test_score_control_module_treatment_minus_control_expA_table4_col3", t3$coef)
emit("test_score_control_module_treatment_minus_control_expB_table4_col4", t4$coef)
emit("n_obs_table4_expA_cols1_3", t1$n)
emit("n_obs_table4_expB_cols2_4", t2$n)
emit("deliberative_competence_control_expA_table7_col1", lvl(dcA, "Control"))
emit("deliberative_competence_treatment_expA_table7_col1", lvl(dcA, "Treatment"))
emit("deliberative_competence_substance_only_expA_table7_col1", lvl(dcA, "Substance"))
emit("deliberative_competence_rhetoric_only_expA_table7_col1", lvl(dcA, "Rhetoric"))
emit("deliberative_competence_control_expB_table7_col2", lvl(dcB, "Control"))
emit("deliberative_competence_treatment_expB_table7_col2", lvl(dcB, "Treatment"))
emit("n_obs_table7_expA_col1", if (is.null(dcA)) NA else nrow(dcA))