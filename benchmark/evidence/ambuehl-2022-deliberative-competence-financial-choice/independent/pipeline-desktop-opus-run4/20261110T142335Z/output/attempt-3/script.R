suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)
options(warn = 1)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice.script-free"
raw <- file.path(base, "data", "raw")

# Compact diagnostics buffer (printed at the end, before RESULT lines)
DL <- character(0)
dg <- function(..., n = 300) {
  s <- paste(c(...), collapse = " ")
  s <- gsub("[\r\n\t]+", " ", s)
  if (nchar(s) > n) s <- paste0(substr(s, 1, n), "...")
  DL <<- c(DL, paste("DIAG:", s))
}
DEV <- character(0)
dev <- function(s) DEV <<- unique(c(DEV, s))

num <- function(x) {
  x <- as.character(x)
  x <- gsub("[   ﻿]", " ", x, perl = TRUE)
  x <- trimws(x)
  v <- suppressWarnings(as.numeric(x))
  bad <- is.na(v) & !is.na(x) & x != ""
  if (any(bad)) {
    y <- gsub(",", "", x[bad], fixed = TRUE)
    r <- regexpr("-?[0-9]*\\.?[0-9]+", y, perl = TRUE)
    out <- rep(NA_real_, length(y))
    if (any(r > 0)) out[r > 0] <- suppressWarnings(as.numeric(regmatches(y, r)))
    v[bad] <- out
  }
  v
}

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

clean_rows <- function(d) {
  if ("V1" %in% names(d)) d <- d[is.na(d$V1) | d$V1 != "ResponseID", , drop = FALSE]
  if ("StartDate" %in% names(d)) d <- d[!is.na(d$StartDate) & grepl("^[0-9]", d$StartDate), , drop = FALSE]
  d
}

name_summary <- function(nm) {
  p <- gsub("[0-9]+", "#", nm)
  tb <- sort(table(p), decreasing = TRUE)
  paste(names(tb), tb, sep = ":", collapse = " ")
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

lab2 <- function(codes) {
  l <- lab_arm(codes)
  if (all(!is.na(l)) && setequal(unique(l), c("Control", "Treatment"))) return(l)
  cn <- num(codes)
  if (all(is.finite(cn)) && length(unique(cn)) == 2) return(ifelse(cn == max(cn), "Treatment", "Control"))
  NULL
}

# Detect raw price-list row choices (groups of binary columns) and count switches
mpl_multi <- function(d, rows) {
  nm <- names(d)
  has <- grepl("_[0-9]+$", nm)
  pre <- sub("_[0-9]+$", "", nm)
  grp <- split(nm[has], pre[has])
  flags <- rep(FALSE, length(rows)); ng <- 0; sizes <- integer(0)
  for (g in names(grp)) {
    cs <- grp[[g]]
    if (length(cs) < 5 || length(cs) > 30) next
    cs <- cs[order(suppressWarnings(as.numeric(sub(".*_", "", cs))))]
    M <- sapply(cs, function(c) suppressWarnings(as.numeric(trimws(d[[c]][rows]))))
    if (is.null(dim(M))) next
    if (mean(is.finite(M)) < 0.3) next
    v <- unique(as.vector(M)); v <- v[is.finite(v)]
    if (length(v) != 2) next
    ng <- ng + 1; sizes <- c(sizes, length(cs))
    nsw <- apply(M, 1, function(x) { x <- x[is.finite(x)]; if (length(x) < 2) 0 else sum(diff(x) != 0) })
    flags <- flags | nsw >= 2
  }
  list(flags = flags, ng = ng, sizes = sizes)
}

# Find test questions: columns whose "correct" indicator correlates with the total score
find_q <- function(d, rows, total, skip) {
  out <- list()
  for (c in setdiff(names(d), skip)) {
    x <- trimws(as.character(d[[c]][rows])); x[x == ""] <- NA
    if (mean(!is.na(x)) < 0.9) next
    ux <- unique(x[!is.na(x)])
    if (length(ux) < 2 || length(ux) > 60) next
    best <- -1; bk <- NA
    for (v in ux) {
      ind <- as.numeric(!is.na(x) & x == v)
      if (sd(ind) == 0) next
      r <- suppressWarnings(cor(ind, total))
      if (is.finite(r) && r > best) { best <- r; bk <- v }
    }
    if (best > 0) out[[length(out) + 1]] <- data.frame(col = c, key = bk, r = best, stringsAsFactors = FALSE)
  }
  if (length(out) == 0) return(data.frame(col = character(0), key = character(0), r = numeric(0)))
  o <- do.call(rbind, out)
  o[order(-o$r), ]
}

parse_T <- function(d, rows, tc) {
  K <- length(tc); n <- length(rows)
  Fr <- matrix(NA_character_, n, K); Rv <- matrix(NA_real_, n, K); Tv <- matrix(NA_real_, n, K)
  ex <- function(x, pat) {
    m <- regmatches(x, regexec(pat, x, perl = TRUE))
    vapply(m, function(z) if (length(z) >= 2) suppressWarnings(as.numeric(z[2])) else NA_real_, numeric(1))
  }
  for (k in seq_len(K)) {
    x <- tolower(as.character(d[[tc[k]]][rows])); x[is.na(x)] <- ""
    isc <- grepl("invest", x); iss <- !isc & grepl("pay you", x)
    days <- ex(x, "([0-9]+) days")
    Rs <- ex(x, "\\$([0-9.]+) in [0-9]+ days")
    a <- ex(x, "invest \\$([0-9.]+)")
    rt <- ex(x, "([0-9.]+)% interest")
    Fr[iss, k] <- "s"; Fr[isc, k] <- "c"
    Rv[, k] <- ifelse(iss, Rs, ifelse(isc, a * (1 + rt / 100)^days, NA))
    Tv[, k] <- days
  }
  list(Fr = Fr, Rv = Rv, Tv = Tv)
}

pair_row <- function(fr, rv, tv) {
  s <- which(fr == "s"); cc <- which(fr == "c")
  if (length(s) != 10 || length(cc) != 10) return(NULL)
  if (any(!is.finite(rv[c(s, cc)])) || any(!is.finite(tv[c(s, cc)]))) return(NULL)
  C <- outer(s, cc, function(i, j) ifelse(tv[i] == tv[j], abs(log(rv[j]) - log(rv[i])), 1e6))
  P <- matrix(NA_integer_, 10, 2); Rn <- numeric(10)
  for (m in 1:10) {
    w <- which(C == min(C), arr.ind = TRUE)[1, ]
    P[m, ] <- c(s[w[1]], cc[w[2]]); Rn[m] <- rv[s[w[1]]]
    C[w[1], ] <- Inf; C[, w[2]] <- Inf
  }
  list(P = P, Rn = Rn)
}

map4 <- function(codes, Cm) {
  u <- sort(unique(codes))
  Rm <- t(sapply(u, function(k) colMeans(Cm[codes == k, , drop = FALSE])))
  dist <- sapply(seq_along(u), function(j) sum(abs(Rm[j, ] - colMeans(Rm[-j, , drop = FALSE]))))
  j0 <- which.max(dist)
  dq <- Rm[j0, ] - colMeans(Rm[-j0, , drop = FALSE])
  nq <- ncol(Cm)
  ctrlQ <- if (nq == 10) order(-dq)[1:5] else which(dq > 0)
  compQ <- setdiff(seq_len(nq), ctrlQ)
  cs <- rowSums(Cm[, compQ, drop = FALSE])
  oth <- setdiff(seq_along(u), j0)
  mc <- sapply(oth, function(j) mean(cs[codes == u[j]]))
  o <- oth[order(mc)]
  lab <- character(length(u))
  lab[j0] <- "Control"; lab[o[1]] <- "Rhetoric"; lab[o[2]] <- "Substance"; lab[o[3]] <- "Treatment"
  dg("map4 codes:", paste(u, lab, sep = "->", collapse = " "))
  lab[match(codes, u)]
}

run_exp <- function(d, label, target_n, want4) {
  dg(label, "rows", nrow(d), "cols", ncol(d))
  dg(label, "name patterns:", name_summary(names(d)), n = 700)
  for (c in intersect(c("line1", "line2", "amt1", "amt2", "Finished", "code treat"), names(d))) {
    u <- head(unique(d[[c]]), 6)
    dg(label, "sample", c, ":", paste(encodeString(as.character(u), quote = "\""), collapse = " | "), n = 200)
  }
  sw <- grep("^switch[0-9]+$", names(d), value = TRUE, ignore.case = TRUE)
  sw <- sw[order(as.numeric(gsub("\\D", "", sw)))]
  if (length(sw) != 20) stop(paste("switch cols:", length(sw)))
  S <- sapply(sw, function(c) num(d[[c]]))
  trc <- names(d)[tolower(names(d)) == "treatment"][1]
  if (is.na(trc)) stop("no treatment column")
  scs <- grep("^SC", names(d), value = TRUE)
  tot_col <- NULL; best <- -1
  for (c in scs) {
    x <- num(d[[c]])
    if (sum(is.finite(x)) > 0) { r <- max(x, na.rm = TRUE); if (r > best) { best <- r; tot_col <- c } }
  }
  total <- if (!is.null(tot_col)) num(d[[tot_col]]) else rep(NA_real_, nrow(d))
  real <- rowSums(is.finite(S)) == 20 & !is.na(d[[trc]]) & trimws(d[[trc]]) != "" & is.finite(total)
  ri <- which(real)
  dg(label, "total score col", tot_col, "| real subjects (20 switches+treatment+score):", length(ri))
  idc <- intersect(c("amt_id", "WorkerId", "workerId", "worker_id", "MID"), names(d))[1]
  if (!is.na(idc)) dg(label, "id col", idc, "| duplicated ids among real:", sum(duplicated(trimws(d[[idc]][ri]))))

  # ---- exclusion candidates (multiple switchers) ----
  cands <- list(none = rep(FALSE, length(ri)))
  if (!is.na(idc) && "excluded" %in% names(d)) {
    cells <- unique(d$excluded[!is.na(d$excluded) & nchar(trimws(d$excluded)) > 0])
    ids_all <- character(0)
    for (k in seq_along(cells)) {
      ids <- unique(regmatches(cells[k], gregexpr("A[0-9A-Z]{9,20}", cells[k]))[[1]])
      ids_all <- union(ids_all, ids)
      fl <- trimws(d[[idc]][ri]) %in% ids
      dg(label, "excluded cell", k, ": ids", length(ids), "| matched among real", sum(fl))
      if (k <= 6) cands[[paste0("cell", k)]] <- fl
    }
    if (length(cells) > 0) cands$union <- trimws(d[[idc]][ri]) %in% ids_all
  }
  mm <- mpl_multi(d, ri)
  dg(label, "binary MPL groups:", mm$ng, "| sizes:", paste(head(mm$sizes, 50), collapse = ","), "| multi flagged:", sum(mm$flags))
  if (mm$ng >= 10) cands$mpl <- mm$flags
  kept <- sapply(cands, function(f) sum(!f))
  dg(label, "kept by exclusion source:", paste(names(kept), kept, sep = "=", collapse = " "), "| target", target_n)
  pick <- names(kept)[which.min(abs(kept - target_n))]
  dg(label, "exclusion source used:", pick)
  if (pick != "none") dev(paste0(label, ": multiple-switcher exclusion taken from '", pick,
                                 "' (source chosen as the one whose kept count is closest to the paper's N)"))
  else dev(paste0(label, ": could not identify multiple switchers; no monotonicity exclusion applied"))
  keep <- ri[!cands[[pick]]]
  n <- length(keep)
  tot <- total[keep]
  codes_tr <- trimws(d[[trc]][keep])

  # ---- arms ----
  armcol <- trc
  if (want4) {
    cn <- names(d)[grepl("treat|cond|arm|group|^FL_|_DO$", names(d), ignore.case = TRUE)]
    nd <- sapply(cn, function(c) { x <- trimws(d[[c]][keep]); x <- x[!is.na(x) & x != ""]
      if (length(x) > 0.9 * n) length(unique(x)) else NA })
    dg(label, "arm col candidates (distinct):", paste(cn, nd, sep = "=", collapse = " "))
    four <- cn[!is.na(nd) & nd == 4]
    if ("code treat" %in% four) armcol <- "code treat" else if (length(four) > 0) armcol <- four[1]
    if (armcol != trc) {
      tb <- table(trimws(d[[armcol]][keep]), codes_tr)
      dg(label, "crosstab", armcol, "x treatment:", paste(capture.output(print(tb)), collapse = " / "), n = 400)
    }
  }
  codes <- trimws(d[[armcol]][keep])
  dg(label, "arm col", armcol, "| values:", paste(names(table(codes)), table(codes), sep = "=", collapse = " "))

  # ---- test questions ----
  skip <- unique(c(sw, paste0("T", 1:20), scs, trc, armcol, "code treat", "excluded", idc,
                   grep("date|^ip|response|location|time|duration|^amt|^line|finished|status|progress|_DO$|^FL_|score|treat",
                        names(d), value = TRUE, ignore.case = TRUE)))
  q <- find_q(d, keep, tot, skip)
  q <- q[q$r > 0.2 & q$r < 0.95, , drop = FALSE]
  q <- head(q, 10)
  nq <- nrow(q)
  Cm <- NULL
  if (nq >= 4) {
    Cm <- sapply(seq_len(nq), function(j) { x <- trimws(as.character(d[[q$col[j]]][keep])); as.numeric(!is.na(x) & x == q$key[j]) })
    dg(label, "questions:", paste(q$col, round(q$r, 2), sep = "@", collapse = " "), n = 500)
    dg(label, "share rowsum(correct)==total:", round(mean(rowSums(Cm) == tot), 3), "| max total", max(tot))
  } else dg(label, "question discovery failed; n found", nq)

  arm <- NULL
  if (want4 && length(unique(codes)) == 4) {
    l <- lab_arm(codes)
    if (all(!is.na(l)) && length(unique(l)) == 4) arm <- l
    else if (!is.null(Cm) && nq >= 4) arm <- map4(codes, Cm)
  }
  if (is.null(arm)) {
    arm <- lab2(codes_tr)
    if (is.null(arm)) stop("cannot map arms")
  }

  comp <- tot; ctrl <- rep(NA_real_, n)
  if (!is.null(Cm) && all(c("Control", "Treatment") %in% arm)) {
    dq <- colMeans(Cm[arm == "Treatment", , drop = FALSE]) - colMeans(Cm[arm == "Control", , drop = FALSE])
    compQ <- if (nq == 10) order(-dq)[1:5] else which(dq > 0)
    ctrlQ <- setdiff(seq_len(nq), compQ)
    dg(label, "T-C correct-rate by question:", paste(round(dq, 2), collapse = " "), "| compound Q:", paste(compQ, collapse = ","))
    comp <- rowSums(Cm[, compQ, drop = FALSE])
    if (length(ctrlQ) > 0) ctrl <- rowSums(Cm[, ctrlQ, drop = FALSE])
  } else {
    dev(paste0(label, ": compound-interest score taken as total test score (question split unavailable)"))
  }

  # ---- valuations ----
  tc <- paste0("T", 1:20)
  pairs <- vector("list", n); nfb <- 0
  if (all(tc %in% names(d))) {
    pt <- parse_T(d, keep, tc)
    for (i in seq_len(n)) {
      pr <- pair_row(pt$Fr[i, ], pt$Rv[i, ], pt$Tv[i, ])
      if (is.null(pr)) { nfb <- nfb + 1; pr <- list(P = cbind(1:10, 11:20), Rn = rep(NA_real_, 10)) }
      pairs[[i]] <- pr
    }
  } else {
    nfb <- n
    for (i in seq_len(n)) pairs[[i]] <- list(P = cbind(1:10, 11:20), Rn = rep(NA_real_, 10))
  }
  dg(label, "pairing fallback rows:", nfb, "| row1 pairs:", paste(pairs[[1]]$P[, 1], pairs[[1]]$P[, 2], sep = "-", collapse = " "),
     "| R:", paste(round(pairs[[1]]$Rn, 1), collapse = " "))

  fskip <- unique(c(skip, tc))
  fc <- character(0)
  for (c in setdiff(names(d), fskip)) {
    x <- suppressWarnings(as.numeric(trimws(d[[c]][keep])))
    if (mean(is.finite(x)) < 0.9) next
    x <- x[is.finite(x)]
    if (min(x) < 0 || max(x) > 21 || length(unique(x)) < 15) next
    fc <- c(fc, c)
  }
  dg(label, "candidate dollar-valuation cols:", length(fc), ":", paste(head(fc, 40), collapse = ","))

  D <- matrix(NA_real_, n, 10)
  Sk <- S[keep, , drop = FALSE]
  if (length(fc) == 20 && nfb == 0) {
    V <- sapply(fc, function(c) as.numeric(trimws(d[[c]][keep])))
    for (i in seq_len(n)) {
      P <- pairs[[i]]$P; Rn <- pairs[[i]]$Rn
      D[i, ] <- -abs(V[i, P[, 2]] / Rn * 100 - V[i, P[, 1]] / Rn * 100)
    }
    dg(label, "valuations: dollar columns")
  } else {
    K <- max(Sk, na.rm = TRUE)
    step <- if (K >= 2) 100 / (K - 1) else 100
    Pct <- pmin(100, pmax(0, (Sk - 0.5) * step))
    simp_mean <- mean(sapply(seq_len(n), function(i) mean(Pct[i, pairs[[i]]$P[, 1]])))
    if (simp_mean < 50) { Pct <- 100 - Pct; simp_mean <- 100 - simp_mean }
    cmp_mean <- mean(sapply(seq_len(n), function(i) mean(Pct[i, pairs[[i]]$P[, 2]])))
    dg(label, "coarse valuations from switch rows: Kmax", K, "| mean simple pct", round(simp_mean, 2),
       "| mean complex pct", round(cmp_mean, 2), "| switch col means:", paste(round(colMeans(Sk), 1), collapse = " "))
    for (i in seq_len(n)) {
      P <- pairs[[i]]$P
      D[i, ] <- -abs(Pct[i, P[, 2]] - Pct[i, P[, 1]])
    }
    dev(paste0(label, ": valuations reconstructed from first-stage switch rows (switch1..switch20) at price-list midpoints; fine-stage valuations not identified"))
  }
  dg(label, "arm counts:", paste(names(table(arm)), table(arm), sep = "=", collapse = " "),
     "| mean comp by arm:", paste(names(tapply(comp, arm, mean)), round(tapply(comp, arm, mean), 2), sep = "=", collapse = " "))
  list(arm = arm, comp = comp, ctrl = ctrl, D = D)
}

dc_reg <- function(D, arm, lv) {
  lv <- lv[lv %in% arm]
  n <- nrow(D)
  long <- data.frame(sid = rep(seq_len(n), times = ncol(D)), arm = rep(arm, times = ncol(D)),
                     d = as.vector(D), stringsAsFactors = FALSE)
  long <- long[is.finite(long$d), ]
  for (l in lv) long[[paste0("arm_", l)]] <- as.integer(long$arm == l)
  m <- feols(as.formula(paste("d ~ 0 +", paste0("arm_", lv, collapse = " + "))), data = long, cluster = ~sid)
  dg("DC reg:", paste(names(coef(m)), round(coef(m), 3), round(se(m), 3), sep = ":", collapse = " "), "| N", nobs(m))
  list(coef = coef(m), nobs = nobs(m))
}

t4_reg <- function(y, arm) {
  ct <- arm %in% c("Control", "Treatment") & is.finite(y)
  df <- data.frame(y = y[ct], treat = as.integer(arm[ct] == "Treatment"))
  m <- feols(y ~ treat, data = df, vcov = "iid")
  list(b = unname(coef(m)["treat"]), se = unname(se(m)["treat"]), n = nobs(m))
}

# ------------------------- Experiment A -------------------------
tryCatch({
  A <- dplyr::bind_rows(lapply(1:8, function(b) { d <- rd(sprintf("expAbatch%d.csv", b)); d$batch_ <- b; d }))
  A <- clean_rows(A)
  ra <- run_exp(A, "A", 455, TRUE)
  m1 <- t4_reg(ra$comp, ra$arm)
  dg("A T4 comp:", round(m1$b, 3), "(", round(m1$se, 3), ") N", m1$n)
  emit_store("test_score_compounding_treatment_minus_control_expA_table4_col1", m1$b)
  emit_store("n_obs_table4_expA_cols1_3", m1$n)
  if (any(is.finite(ra$ctrl))) {
    m3 <- t4_reg(ra$ctrl, ra$arm)
    emit_store("test_score_control_module_treatment_minus_control_expA_table4_col3", m3$b)
  }
  rA <- dc_reg(ra$D, ra$arm, c("Control", "Treatment", "Substance", "Rhetoric"))
  emit_store("deliberative_competence_control_expA_table7_col1", unname(rA$coef["arm_Control"]))
  emit_store("deliberative_competence_treatment_expA_table7_col1", unname(rA$coef["arm_Treatment"]))
  emit_store("deliberative_competence_substance_only_expA_table7_col1", unname(rA$coef["arm_Substance"]))
  emit_store("deliberative_competence_rhetoric_only_expA_table7_col1", unname(rA$coef["arm_Rhetoric"]))
  emit_store("n_obs_table7_expA_col1", rA$nobs)
}, error = function(e) dg("Experiment A error:", conditionMessage(e)))

# ------------------------- Experiment B -------------------------
tryCatch({
  B <- dplyr::bind_rows(rd("expBbatch1.csv"), rd("expBbatch2.csv"))
  B <- clean_rows(B)
  rb <- run_exp(B, "B", 348, FALSE)
  m2 <- t4_reg(rb$comp, rb$arm)
  dg("B T4 comp:", round(m2$b, 3), "(", round(m2$se, 3), ") N", m2$n)
  emit_store("test_score_compounding_treatment_minus_control_expB_table4_col2", m2$b)
  emit_store("n_obs_table4_expB_cols2_4", m2$n)
  if (any(is.finite(rb$ctrl))) {
    m4 <- t4_reg(rb$ctrl, rb$arm)
    emit_store("test_score_control_module_treatment_minus_control_expB_table4_col4", m4$b)
  }
  rB <- dc_reg(rb$D, rb$arm, c("Control", "Treatment"))
  emit_store("deliberative_competence_control_expB_table7_col2", unname(rB$coef["arm_Control"]))
  emit_store("deliberative_competence_treatment_expB_table7_col2", unname(rB$coef["arm_Treatment"]))
}, error = function(e) dg("Experiment B error:", conditionMessage(e)))

# ------------------------- Output -------------------------
for (s in DL) cat(s, "\n")
for (s in DEV) cat("DEVIATION:", s, "\n")
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