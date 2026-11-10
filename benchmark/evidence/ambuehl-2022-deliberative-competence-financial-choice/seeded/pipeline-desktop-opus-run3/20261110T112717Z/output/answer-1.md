suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice"

num <- function(x) suppressWarnings(as.numeric(as.character(x)))

rowmax <- function(X) {
  r <- suppressWarnings(apply(X, 1, function(z) max(z, na.rm = TRUE)))
  r[!is.finite(r)] <- NA
  r
}
rowmin <- function(X) {
  r <- suppressWarnings(apply(X, 1, function(z) min(z, na.rm = TRUE)))
  r[!is.finite(r)] <- NA
  r
}

read_raw <- function(f) {
  df <- readr::read_csv(file.path(base, f),
                        col_types = readr::cols(.default = readr::col_character()),
                        name_repair = "minimal", progress = FALSE)
  df <- as.data.frame(df, stringsAsFactors = FALSE)
  raw <- names(df)
  low <- tolower(raw)
  low <- gsub("﻿", "", low, fixed = TRUE)
  norm <- gsub("[^a-z0-9_]", "", low)
  names(df) <- make.unique(norm)
  list(df = df, low = low)
}

# ---------- column maps for price lists ----------
finalize_map <- function(cm, label) {
  cm <- cm[cm$i >= 1 & cm$i <= 20 & cm$L %in% c(1, 2), , drop = FALSE]
  cm <- cm[(cm$L == 1 & cm$line >= 1 & cm$line <= 11) | (cm$L == 2 & cm$line >= 1 & cm$line <= 10), , drop = FALSE]
  cm <- cm[!duplicated(cm[, c("i", "L", "line")]), , drop = FALSE]
  if (nrow(cm) != 20 * 21) {
    stop(sprintf("Price-list column map incomplete for %s: found %d of 420", label, nrow(cm)))
  }
  cm
}

mapA <- function(low) {
  pat <- "^impl[0-9]+[^a-z0-9]+[0-9]+[^a-z0-9]+[0-9]+([^a-z0-9]+[0-9]+)?$"
  idx <- which(grepl(pat, low))
  res <- list()
  for (j in idx) {
    g <- regmatches(low[j], gregexpr("[0-9]+", low[j]))[[1]]
    i <- as.integer(g[1]); L <- as.integer(g[2])
    if (length(g) == 4) {
      k <- as.integer(g[3])
    } else if (length(g) == 3) {
      s <- g[3]
      if (nchar(s) < 2 || substr(s, nchar(s), nchar(s)) != "1") next
      k <- as.integer(substr(s, 1, nchar(s) - 1))
    } else next
    line <- if (L == 1) k else k - 2
    res[[length(res) + 1]] <- data.frame(col = j, i = i, L = L, line = line)
  }
  if (length(res) == 0) {
    message("impl-like columns: ", paste(head(low[grepl("^impl", low)], 40), collapse = ", "))
    stop("No price-list columns found in Experiment A file")
  }
  cm <- do.call(rbind, res)
  out <- tryCatch(finalize_map(cm, "A"), error = function(e) {
    message("impl-like columns: ", paste(head(low[grepl("^impl", low)], 60), collapse = ", "))
    stop(e)
  })
  out
}

mapB <- function(norm) {
  pat <- "^impl([0-9]+)([12])1_impl([0-9]+)([12])_([0-9]+)$"
  idx <- which(grepl(pat, norm))
  if (length(idx) == 0) {
    message("impl-like columns: ", paste(head(norm[grepl("^impl", norm)], 40), collapse = ", "))
    stop("No price-list columns found in Experiment B file")
  }
  m <- regmatches(norm[idx], regexec(pat, norm[idx]))
  cm <- do.call(rbind, lapply(seq_along(idx), function(z) {
    g <- m[[z]]
    L <- as.integer(g[5]); k <- as.integer(g[6])
    data.frame(col = idx[z], i = as.integer(g[4]), L = L, line = if (L == 1) k else k - 2)
  }))
  out <- tryCatch(finalize_map(cm, "B"), error = function(e) {
    message("impl-like columns: ", paste(head(norm[grepl("^impl", norm)], 60), collapse = ", "))
    stop(e)
  })
  out
}

# ---------- switching-point logic (literal translation of the do-files) ----------
process_lists <- function(df, cm) {
  n <- nrow(df)
  coarse_val <- matrix(NA_real_, n, 20)
  fine_val <- matrix(NA_real_, n, 20)
  cmulti <- matrix(0, n, 20)
  fmulti <- matrix(0, n, 20)
  for (i in 1:20) {
    for (L in 1:2) {
      nl <- if (L == 1) 11 else 10
      M <- matrix(sapply(1:nl, function(ln) {
        col <- cm$col[cm$i == i & cm$L == L & cm$line == ln][1]
        num(df[[col]])
      }), nrow = n)
      LN <- matrix(rep(1:nl, each = n), nrow = n)
      leftmask <- is.na(M) | (M != 1)
      rightmask <- is.na(M) | (M != 0)
      leftmask[is.na(leftmask)] <- TRUE
      rightmask[is.na(rightmask)] <- TRUE
      left <- LN; left[!leftmask] <- NA
      right <- LN; right[!rightmask] <- NA
      sl <- rowmax(left)
      sh <- rowmin(right)
      a <- sh; b <- sl + 1
      eq <- ifelse(is.na(a) & is.na(b), TRUE,
                   ifelse(is.na(a) | is.na(b), FALSE, a == b))
      multi <- 1 - as.numeric(eq)
      if (L == 1) {
        multi[(sh %in% 11) | is.na(sh) | (sl %in% 1) | is.na(sl)] <- 0
        v <- sh
        v[multi == 1] <- NA
        v[sh %in% 1] <- 0
        v[sl %in% 11] <- 12
        coarse_val[, i] <- 20 - 2 * (v - 1)
        cmulti[, i] <- multi
      } else {
        multi[((sh %in% 1) & is.na(sl)) | (is.na(sh) & (sl %in% 10))] <- 0
        v <- sl
        v[multi == 1] <- NA
        v[sh %in% 1] <- 0
        v[sl %in% 10] <- 10
        fv <- 1.8 - 0.2 * v
        fv[!is.na(fv) & fv < 0] <- 0
        fine_val[, i] <- fv
        fmulti[, i] <- multi
      }
    }
  }
  # After merge, master (fine) multi_switch_* are retained; coarse enter via sum_multi_switch_1 == 1
  multi_subj <- as.integer(rowSums(fmulti == 1) > 0 | rowSums(cmulti) == 1 | rowSums(fmulti) == 1)
  list(value = coarse_val + fine_val, multi = multi_subj)
}

build_long <- function(subj, value) {
  oldidx <- c(6, 1, 7, 2, 8, 3, 9, 4, 10, 5)
  amt <- c(20, 20, 18, 18, 16, 16, 14, 14, 12, 12)
  ap <- c(20.40, 20.47, 18.47, 18.73, 16.29, 16.80, 14.37, 15.16, 11.58, 11.83)
  dl <- rep(c(36, 72), 5)
  rows <- lapply(1:10, function(k) {
    vu <- value[, oldidx[k]] + 0.1
    vf <- value[, k + 10] + 0.1
    vu[!is.na(vu) & vu <= 0] <- 0
    vf[!is.na(vf) & vf <= 0] <- 0
    data.frame(subj, task = k, delay = dl[k], amount = amt[k], amount_precise = ap[k],
               v_unframed = vu, v_framed = vf)
  })
  out <- do.call(rbind, rows)
  out$discount_unframed <- out$v_unframed / out$amount * 100
  out$discount_framed <- out$v_framed / out$amount_precise * 100
  out$absDiff <- abs(out$discount_framed - out$discount_unframed)
  out$negAbsDiff <- -out$absDiff
  out
}

# ---------- Experiment A ----------
A_subj <- list(); A_val <- list()
for (b in 1:8) {
  r <- read_raw(sprintf("data/raw/expAbatch%d.csv", b))
  df <- r$df
  cm <- mapA(r$low)
  df <- df[-1, , drop = FALSE]  # drop Qualtrics description row (drop if id == 1)
  id <- b * 1000 + seq_len(nrow(df))
  fined <- num(df[["treatment"]])
  if (b %in% c(3, 6, 7, 8)) {
    f2 <- fined
    f2[fined %in% 1] <- 2
    f2[fined %in% 0] <- 3
    fined <- f2
  }
  keep <- !is.na(num(df[["help_test"]]))
  df <- df[keep, , drop = FALSE]
  id <- id[keep]; fined <- fined[keep]
  pr <- process_lists(df, cm)
  tt <- function(q, a) as.integer(num(df[[q]]) %in% a)
  t1 <- tt("test1", 2); t2 <- tt("test2", 4); t3 <- tt("test3", 4); t4 <- tt("test4", 7); t5 <- tt("test5", 6)
  sc <- t1 + t2 + t3 + t4 + t5
  score <- num(df[["sc0_0"]])
  A_subj[[b]] <- data.frame(id = id, fined = fined, score_compounding = sc,
                            score_indexing = score - sc, multi = pr$multi)
  A_val[[b]] <- pr$value
}
A_s <- do.call(rbind, A_subj)
A_v <- do.call(rbind, A_val)
A_long <- build_long(A_s, A_v)
message(sprintf("Exp A: %d completers, %d multi-switchers", nrow(A_s), sum(A_s$multi == 1)))

# ---------- Experiment B ----------
B_subj <- list(); B_val <- list()
for (b in 1:2) {
  r <- read_raw(sprintf("data/raw/expBbatch%d.csv", b))
  df <- r$df
  cm <- mapB(names(df))
  if ("responseid" %in% names(df)) {
    ok <- grepl("^R_", df[["responseid"]])
    if (sum(ok) > 0) df <- df[ok, , drop = FALSE] else df <- df[-(1:3), , drop = FALSE]
  } else {
    df <- df[-(1:3), , drop = FALSE]
  }
  id <- b * 1000 + seq_len(nrow(df))
  fined <- num(df[["treatment"]])
  keep <- !is.na(num(df[["test10"]]))
  df <- df[keep, , drop = FALSE]
  id <- id[keep]; fined <- fined[keep]
  pr <- process_lists(df, cm)
  tt <- function(q, a) as.integer(num(df[[q]]) %in% a)
  s1 <- tt("test1", 2); s2 <- tt("test2", 4); s3 <- tt("test3", 4); s4 <- tt("test4", 7); s5 <- tt("test5", 6)
  s6 <- tt("test6", 4); s7 <- tt("test7", 5); s8 <- tt("test8", 5); s9 <- tt("test9", 5); s10 <- tt("test10", 1)
  sc <- s1 + s2 + s3 + s4 + s5
  B_subj[[b]] <- data.frame(id = id, fined = fined, score_compounding = sc,
                            score_indexing = s6 + s7 + s8 + s9 + s10, multi = pr$multi)
  B_val[[b]] <- pr$value
}
B_s <- do.call(rbind, B_subj)
B_v <- do.call(rbind, B_val)
B_long <- build_long(B_s, B_v)
message(sprintf("Exp B: %d completers, %d multi-switchers", nrow(B_s), sum(B_s$multi == 1)))

# ---------- Table 4 ----------
A4 <- A_s[A_s$multi == 0 & A_s$fined %in% c(0, 1), ]
A4$Full <- as.integer(A4$fined == 1)
B4 <- B_s[B_s$multi == 0 & B_s$fined %in% c(0, 1), ]
B4$Full <- as.integer(B4$fined == 1)

m1 <- lm(score_compounding ~ Full, data = A4)
m2 <- lm(score_compounding ~ Full, data = B4)
m3 <- lm(score_indexing ~ Full, data = A4)
m4 <- lm(score_indexing ~ Full, data = B4)

# ---------- Table 7 ----------
A7 <- A_long[A_long$multi == 0, ]
A7$Control <- as.integer(A7$fined %in% 0)
A7$Full <- as.integer(A7$fined %in% 1)
A7$Rule72 <- as.integer(A7$fined %in% 2)
A7$Rhetoric <- as.integer(A7$fined %in% 3)
m7a <- lm(negAbsDiff ~ 0 + Control + Full + Rule72 + Rhetoric, data = A7)

B7 <- B_long[B_long$multi == 0, ]
B7$Control <- as.integer(B7$fined %in% 0)
B7$Full <- as.integer(B7$fined %in% 1)
m7b <- lm(negAbsDiff ~ 0 + Control + Full, data = B7)

out <- function(nm, v) cat(sprintf("RESULT:%s=%.6f\n", nm, v))
out("test_score_compounding_treatment_minus_control_expA_table4_col1", coef(m1)["Full"])
out("test_score_compounding_treatment_minus_control_expB_table4_col2", coef(m2)["Full"])
out("test_score_control_module_treatment_minus_control_expA_table4_col3", coef(m3)["Full"])
out("test_score_control_module_treatment_minus_control_expB_table4_col4", coef(m4)["Full"])
out("n_obs_table4_expA_cols1_3", nobs(m1))
out("n_obs_table4_expB_cols2_4", nobs(m2))
out("deliberative_competence_control_expA_table7_col1", coef(m7a)["Control"])
out("deliberative_competence_treatment_expA_table7_col1", coef(m7a)["Full"])
out("deliberative_competence_substance_only_expA_table7_col1", coef(m7a)["Rule72"])
out("deliberative_competence_rhetoric_only_expA_table7_col1", coef(m7a)["Rhetoric"])
out("deliberative_competence_control_expB_table7_col2", coef(m7b)["Control"])
out("deliberative_competence_treatment_expB_table7_col2", coef(m7b)["Full"])
out("n_obs_table7_expA_col1", nobs(m7a))
