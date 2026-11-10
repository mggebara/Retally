suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/butera_2022_welfare_effects_shame_pride.script-free"
rawdir <- file.path(root, "Packet", "Raw Data")

read_chr <- function(f) {
  d <- readr::read_csv(file.path(rawdir, f),
                       col_types = readr::cols(.default = readr::col_character()),
                       show_col_types = FALSE, progress = FALSE)
  as.data.frame(d, stringsAsFactors = FALSE)
}
conv <- function(d) {
  d[] <- lapply(d, function(x) type.convert(x, as.is = TRUE))
  d
}
to_num <- function(x) suppressWarnings(readr::parse_number(as.character(x)))
to01 <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_real_, length(s))
  out[s %in% c("1", "true", "t", "yes", "y")] <- 1
  out[s %in% c("0", "false", "f", "no", "n")] <- 0
  out
}

pro <- read_chr("prolific_survey_data.csv"); pro$id <- paste0("p_", pro$id)
ber <- read_chr("berkeley_survey_data.csv"); ber$id <- paste0("b_", ber$id)
bu1 <- read_chr("bu_qm221_survey_data.csv"); bu1$id <- paste0("bu221_", bu1$id)
bu2 <- read_chr("bu_qm222_survey_data.csv"); bu2$id <- paste0("bu222_", bu2$id)
bu <- as.data.frame(dplyr::bind_rows(bu1, bu2), stringsAsFactors = FALSE)
pro <- conv(pro); ber <- conv(ber); bu <- conv(bu)

describe <- function(d, label) {
  cat("=== ", label, ": ", nrow(d), " rows, ", ncol(d), " cols\n", sep = "")
  cat("Columns:", paste(names(d), collapse = ", "), "\n")
  for (nm in names(d)) {
    if (grepl("^preference_[0-9]+$", nm) && !grepl("^preference_(0|100)$", nm)) next
    u <- unique(d[[nm]])
    cat(sprintf("  %s [%s] nuniq=%d NA=%d: %s\n", nm, class(d[[nm]])[1], length(u),
                sum(is.na(d[[nm]])), substr(paste(head(u, 6), collapse = " | "), 1, 120)))
  }
}

classify_round <- function(n) {
  n <- tolower(n)
  if (grepl("paid|pay|financ|incent|money|bonus|cash", n)) return("paid")
  if (grepl("public|shar|recog|image|named", n)) return("public")
  if (grepl("anon|private|baseline|control", n)) return("anon")
  NA_character_
}

excl_re <- "preference|wtp|forecast|predict|guess|belief|expect|attention|^id$|amount|bid|order|rank|position|sequence|date|duration|^age$|gender|female|incoher|coheren|exclu"

numeric_like <- function(d, nm) {
  v <- to_num(d[[nm]])
  mean(!is.na(v)) > 0.5 && length(unique(v[!is.na(v)])) > 5
}

find_points <- function(d) {
  nms <- names(d)
  cand <- nms[!grepl(excl_re, tolower(nms))]
  cand <- cand[vapply(cand, function(nm) numeric_like(d, nm), logical(1))]
  kw <- grepl("point|score|click|effort|press|perf|count|task|round", tolower(cand))
  out <- list()
  for (pool in list(cand[kw], cand)) {
    if (!length(pool)) next
    types <- vapply(pool, classify_round, character(1))
    for (t in c("anon", "paid", "public")) {
      if (!is.null(out[[t]])) next
      m <- pool[!is.na(types) & types == t]
      if (length(m)) {
        pr <- m[grepl("point|score", tolower(m))]
        out[[t]] <- if (length(pr)) pr[1] else m[1]
      }
    }
  }
  # position-based columns (round 1/2/3) as fallback
  pos <- list()
  pool <- cand[kw]
  if (length(pool)) {
    types <- vapply(pool, classify_round, character(1))
    pool <- pool[is.na(types)]
    for (k in 1:3) {
      m <- pool[grepl(paste0("(^|[^0-9])", k, "([^0-9]|$)"), pool)]
      if (length(m)) pos[[k]] <- m[1]
    }
  }
  list(type = out, pos = pos)
}

na3 <- c(anon = NA_real_, paid = NA_real_, public = NA_real_)
parse_order <- function(s) {
  if (is.na(s)) return(na3)
  s <- tolower(as.character(s))
  toks <- strsplit(s, "[,;|>/]+|\\s+then\\s+")[[1]]
  toks <- trimws(toks); toks <- toks[toks != ""]
  if (length(toks) != 3) {
    t2 <- strsplit(s, "[^a-z]+")[[1]]; t2 <- t2[t2 != ""]
    if (length(t2) == 3) toks <- t2
    else if (grepl("^[a-z]{3}$", s)) toks <- strsplit(s, "")[[1]]
    else return(na3)
  }
  ty <- vapply(toks, function(t) {
    r <- classify_round(t)
    if (is.na(r)) r <- switch(t, a = "anon", f = "paid", m = "paid", s = "public", r = "public", NA_character_)
    r
  }, character(1))
  if (anyNA(ty) || length(unique(ty)) != 3) return(na3)
  p <- match(c("anon", "paid", "public"), ty)
  names(p) <- c("anon", "paid", "public")
  p
}

find_order <- function(d) {
  nms <- names(d)
  oc <- nms[grepl("order|position|sequence|^seq|rank", tolower(nms)) & !grepl("^preference", nms)]
  per <- list()
  for (nm in oc) {
    t <- classify_round(nm)
    if (!is.na(t) && is.null(per[[t]])) per[[t]] <- nm
  }
  list(per = per, single = setdiff(oc, unlist(per)))
}

att_pass <- function(x) {
  xs <- tolower(trimws(as.character(x)))
  if (all(is.na(xs) | xs == "")) return(rep(TRUE, length(xs)))
  if (any(grepl("pass|correct", xs), na.rm = TRUE)) {
    return(!is.na(xs) & grepl("pass|correct", xs) & !grepl("fail|incorrect|not", xs))
  }
  tab <- sort(table(xs[!is.na(xs) & xs != ""]), decreasing = TRUE)
  md <- names(tab)[1]
  cat("  attention_check values:", paste(names(tab), tab, sep = "=", collapse = "; "), "-> keep", md, "\n")
  !is.na(xs) & xs == md
}

build_wtp <- function(d) {
  pref_cols <- grep("^preference_[0-9]+$", names(d), value = TRUE)
  X <- as.numeric(sub("preference_", "", pref_cols))
  o <- order(X); X <- X[o]; pref_cols <- pref_cols[o]
  amt_cols <- sapply(X, function(x) {
    m <- grep(paste0("_", x, "$"), names(d), value = TRUE)
    m <- m[!grepl("^preference", m)]
    if (!length(m)) return(NA_character_)
    pr <- m[grepl("wtp|amount|pay|bid|value|willing|money|dollar", tolower(m))]
    if (length(pr)) pr[1] else m[1]
  })
  P <- as.matrix(as.data.frame(lapply(pref_cols, function(nm) as.character(d[[nm]])), stringsAsFactors = FALSE))
  Pn <- suppressWarnings(matrix(as.numeric(P), nrow = nrow(P)))
  allnum <- all(is.na(P) | !is.na(Pn))
  uP <- sort(unique(Pn[!is.na(Pn)]))
  if (all(!is.na(amt_cols))) {
    cat("  amount columns:", paste(amt_cols, collapse = ", "), "\n")
    A <- sapply(amt_cols, function(nm) to_num(d[[nm]]))
    A <- matrix(A, nrow = nrow(d))
    if (any(A < 0, na.rm = TRUE)) {
      W <- A
    } else {
      if (allnum) {
        if (all(uP %in% c(0, 1)) || all(uP %in% c(1, 2))) S <- ifelse(Pn == 1, 1, -1)
        else S <- sign(Pn)
      } else {
        s <- tolower(P)
        S <- ifelse(is.na(s), NA, ifelse(grepl("not|^no|don|anonym|private|without", s), -1, 1))
      }
      S <- matrix(S, nrow = nrow(d))
      W <- S * A
      W[is.na(A) & !is.na(S)] <- 0
    }
  } else if (allnum && length(uP) > 3) {
    cat("  using preference_X directly as signed WTP\n")
    W <- Pn
  } else {
    cat("  WARNING: could not construct WTP\n")
    W <- matrix(NA_real_, nrow(d), length(X))
  }
  # sign orientation check: WTP should rise with performance on average
  mid <- (X + 50) / 100
  ok <- !is.na(W)
  if (sum(ok) > 10) {
    yy <- as.vector(W); xx <- rep(mid, each = nrow(W))
    sl <- coef(lm(yy ~ xx))[2]
    if (!is.na(sl) && sl < 0 && !any(to_num(as.vector(P)) < 0, na.rm = TRUE)) {
      cat("  flipping WTP sign (negative average slope)\n")
      W <- -W
    }
  }
  cat("  WTP summary:", paste(names(summary(as.vector(W))), round(summary(as.vector(W)), 3), collapse = "; "), "\n")
  list(W = W, X = X)
}

incoherent <- function(W) {
  apply(W, 1, function(w) {
    w <- w[!is.na(w)]
    if (length(w) < 3) return(TRUE)
    dd <- diff(w); s <- sign(dd[dd != 0])
    if (length(s) < 2) return(FALSE)
    sum(diff(s) != 0) >= 2
  })
}

process <- function(d, label, target_n) {
  describe(d, label)
  n0 <- nrow(d)
  keep <- rep(TRUE, n0)
  if ("attention_check" %in% names(d)) keep <- keep & att_pass(d$attention_check)
  cat(label, "after attention check:", sum(keep), "\n")

  wt <- build_wtp(d)
  flag_cols <- names(d)[grepl("incoher|coheren|exclu|drop|final|keep|valid|insample|in_sample", tolower(names(d)))]
  used_flag <- FALSE
  for (fc in flag_cols) {
    v <- to01(d[[fc]])
    if (all(is.na(v))) next
    used_flag <- TRUE
    if (grepl("incoher|exclu|drop", tolower(fc))) keep <- keep & !is.na(v) & v == 0
    else keep <- keep & !is.na(v) & v == 1
    cat("  applied flag", fc, "->", sum(keep), "\n")
  }
  if (!used_flag) {
    inc <- incoherent(wt$W)
    keep <- keep & !inc
    cat(label, "after incoherent-preference exclusion:", sum(keep), "\n")
  }

  fp <- find_points(d)
  fo <- find_order(d)
  pts <- NULL
  posm <- NULL
  ordfe <- NULL
  if (length(fo$per) == 3) {
    posm <- sapply(c("anon", "paid", "public"), function(t) to_num(d[[fo$per[[t]]]]))
    if (min(posm, na.rm = TRUE) == 0) posm <- posm + 1
  } else if (length(fo$single)) {
    for (oc in fo$single) {
      pm <- t(sapply(d[[oc]], parse_order))
      if (mean(!is.na(pm[, 1])) > 0.5) { posm <- pm; cat("  order parsed from", oc, "\n"); break }
    }
    if (is.null(posm)) { ordfe <- as.character(d[[fo$single[1]]]); cat("  order column used as FE:", fo$single[1], "\n") }
  }
  if (length(fp$type) == 3) {
    pts <- sapply(c("anon", "paid", "public"), function(t) to_num(d[[fp$type[[t]]]]))
    cat("  points columns:", paste(unlist(fp$type), collapse = ", "), "\n")
  } else if (length(fp$pos) == 3 && !is.null(posm)) {
    cat("  points by position:", paste(unlist(fp$pos), collapse = ", "), "\n")
    PP <- sapply(1:3, function(k) to_num(d[[fp$pos[[k]]]]))
    pts <- sapply(c("anon", "paid", "public"), function(t) PP[cbind(seq_len(n0), posm[, t])])
  } else {
    stop(paste("could not identify points columns for", label))
  }
  pts <- matrix(pts, nrow = n0); colnames(pts) <- c("anon", "paid", "public")
  keep <- keep & rowSums(is.na(pts)) == 0
  cat(label, "final participants:", sum(keep), "(target", target_n, ")\n")

  idx <- which(keep)
  L <- data.frame(
    id = rep(d$id[idx], each = 3),
    round = rep(c("anon", "paid", "public"), times = length(idx)),
    points = as.vector(t(pts[idx, , drop = FALSE])),
    stringsAsFactors = FALSE
  )
  L$pub <- as.integer(L$round == "public")
  L$fin <- as.integer(L$round == "paid")
  form <- points ~ pub + fin
  if (!is.null(posm)) {
    posm <- matrix(posm, nrow = n0); colnames(posm) <- c("anon", "paid", "public")
    L$pos <- as.vector(t(posm[idx, , drop = FALSE]))
    L$pos2 <- as.integer(L$pos == 2); L$pos3 <- as.integer(L$pos == 3)
    form <- points ~ pub + fin + pos2 + pos3
  } else if (!is.null(ordfe)) {
    L$ordfe <- rep(ordfe[idx], each = 3)
    form <- points ~ pub + fin | ordfe
  } else {
    cat("  WARNING: no round-order information found\n")
  }
  L <- L[!is.na(L$points), ]
  fit <- feols(form, data = L, cluster = ~id)
  print(summary(fit))
  list(fit = fit, L = L, W = wt$W[idx, , drop = FALSE], X = wt$X, ids = d$id[idx],
       anon_mean = mean(pts[idx, "anon"]))
}

res <- list()
safe <- function(expr) tryCatch(expr, error = function(e) { cat("ERROR:", conditionMessage(e), "\n"); NULL })
res$pro <- safe(process(pro, "Prolific", 968))
res$ber <- safe(process(ber, "Berkeley", 384))
res$bu  <- safe(process(bu,  "BU", 118))

out <- list()
emit <- function(k, v) if (!is.null(v) && length(v) == 1 && is.finite(v)) out[[k]] <<- v
if (!is.null(res$pro)) {
  emit("public_recognition_points_prolific_table5_col1", unname(coef(res$pro$fit)["pub"]))
  emit("financial_incentives_points_prolific_table5_col1", unname(coef(res$pro$fit)["fin"]))
  emit("n_obs_prolific_table5_col1", nobs(res$pro$fit))
}
if (!is.null(res$ber)) {
  emit("public_recognition_points_berkeley_table5_col2", unname(coef(res$ber$fit)["pub"]))
  emit("financial_incentives_points_berkeley_table5_col2", unname(coef(res$ber$fit)["fin"]))
  emit("n_obs_berkeley_table5_col2", nobs(res$ber$fit))
}
if (!is.null(res$bu)) {
  emit("public_recognition_points_bu_table5_col3", unname(coef(res$bu$fit)["pub"]))
  emit("financial_incentives_points_bu_table5_col3", unname(coef(res$bu$fit)["fin"]))
  emit("n_obs_bu_table5_col3", nobs(res$bu$fit))
}

# Structural action-signaling model, Berkeley
safe({
  b <- res$ber
  X <- b$X
  use <- X < max(X)  # exclude the top (1700+) interval
  mid <- (X + 50) / 100
  WL <- data.frame(
    id = rep(b$ids, times = sum(use)),
    m = rep(mid[use], each = length(b$ids)),
    wtp = as.vector(b$W[, use, drop = FALSE])
  )
  WL <- WL[!is.na(WL$wtp), ]
  f6 <- feols(wtp ~ m + I(m^2), data = WL, cluster = ~id)
  print(summary(f6))
  r <- unname(coef(f6)); r0 <- r[1]; r1 <- r[2]; r2 <- r[3]
  tau <- unname(coef(b$fit)["pub"]) / 100
  abar <- b$anon_mean / 100 + tau
  cat("Berkeley: anon mean (hundreds) =", b$anon_mean / 100, " tau =", tau, " abar =", abar, "\n")
  if (abs(r2) < 1e-12) {
    x <- -r0 / r1
  } else {
    disc <- r1^2 - 4 * r2 * r0
    roots <- if (disc >= 0) c((-r1 + sqrt(disc)) / (2 * r2), (-r1 - sqrt(disc)) / (2 * r2)) else NA
    good <- roots[!is.na(roots) & (r1 + 2 * r2 * roots) > 0]
    x <- if (length(good)) good[which.min(abs(good - abar))] else roots[which.min(abs(roots - abar))]
  }
  rho <- x / abar
  gamma1 <- r1 + 2 * r2 * x
  gamma2 <- r2
  cpar <- (r1 + 2 * r2 * abar) / tau
  p <- 0.05 * 10  # 5 cents per 10 points = $0.50 per hundred points
  pred <- p / cpar
  cat("gamma2 =", gamma2, "\n")
  emit("action_signaling_gamma1_berkeley_table7_panelA", gamma1)
  emit("action_signaling_rho_berkeley_table7_panelA", rho)
  emit("cost_parameter_c_berkeley_table7_panelA", cpar)
  emit("predicted_financial_incentive_effect_berkeley_table7_panelC", pred)
})

for (k in names(out)) cat(sprintf("RESULT:%s=%.6f\n", k, out[[k]]))
