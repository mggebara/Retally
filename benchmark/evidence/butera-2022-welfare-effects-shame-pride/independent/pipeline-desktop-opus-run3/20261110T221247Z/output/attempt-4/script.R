suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
  library(survival)
})
set.seed(42)

base <- "<repo>/.cache/datasets/butera_2022_welfare_effects_shame_pride.script-free/Packet/Raw Data"

rd <- function(f) {
  d <- as.data.frame(read_csv(file.path(base, f), show_col_types = FALSE, guess_max = 100000))
  names(d) <- trimws(names(d))
  d
}
num <- function(x) suppressWarnings(as.numeric(as.character(x)))

classify_round <- function(s) {
  s <- tolower(s)
  out <- rep(NA_character_, length(s))
  out[grepl("public|recog|shared|share|image|social", s)] <- "public"
  out[grepl("anon|anom", s) & is.na(out)] <- "anon"
  out[grepl("paid|pay|incent|financ|money|bonus|cash|earn", s)] <- "paid"
  out
}

parse_pref <- function(x) {
  xn <- num(x)
  if (sum(!is.na(xn)) >= 0.5 * sum(!is.na(x)) && sum(!is.na(x)) > 0) {
    u <- sort(unique(na.omit(xn)))
    if (all(u %in% c(0, 1))) return(xn == 1)
    if (all(u %in% c(1, 2))) return(xn == 1)
    return(xn > 0)
  }
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA, length(s))
  out[grepl("^(yes|y|true)|want|recogn|public|show|share", s)] <- TRUE
  out[grepl("^(no|n|false)\\b|not|don|anonym|prefer not", s)] <- FALSE
  out
}

modal <- function(x) {
  x <- as.character(x); x <- x[!is.na(x)]
  if (length(x) == 0) return(NA)
  names(sort(table(x), decreasing = TRUE))[1]
}

# ---------- WTP matrix (old generic fallback) ----------
get_wtp_old <- function(d) {
  nm <- names(d)
  pc <- grep("^preference_[0-9]+$", nm, value = TRUE)
  lev <- as.numeric(sub("preference_", "", pc))
  o <- order(lev); pc <- pc[o]; lev <- lev[o]
  nlev <- length(lev)
  P <- sapply(pc, function(c) parse_pref(d[[c]]))
  if (is.null(dim(P))) P <- matrix(P, nrow = nrow(d))
  pn <- sapply(pc, function(c) num(d[[c]]))
  if (length(unique(na.omit(as.vector(pn)))) > 3) {
    cat("Preference columns treated as signed WTP\n")
    W <- pn
  } else {
    cat("No WTP amounts found; using preference sign only\n")
    W <- ifelse(P, 1, -1)
  }
  list(W = W, lev = lev, P = P)
}

# ---------- WTP matrix: combine anonymity (negative) and recognition (positive) amounts ----------
get_wtp <- function(d) {
  nm <- names(d)
  if (!any(grepl("^pref_(anom|rec)_[0-9]+_", nm))) return(get_wtp_old(d))
  pc <- grep("^preference_[0-9]+$", nm, value = TRUE)
  lev <- sort(as.numeric(sub("preference_", "", pc)))
  pc <- paste0("preference_", lev)
  nlev <- length(lev); n <- nrow(d)
  side_amt <- function(side, L) {
    cc <- grep(paste0("^pref_", side, "_", L, "_[0-9]+$"), nm, value = TRUE)
    if (!length(cc)) return(rep(NA_real_, n))
    M <- sapply(cc, function(c) num(d[[c]]))
    if (is.null(dim(M))) M <- matrix(M, nrow = n)
    apply(M, 1, function(r) if (all(is.na(r))) NA_real_ else r[!is.na(r)][1])
  }
  P <- sapply(pc, function(c) parse_pref(d[[c]]))
  if (is.null(dim(P))) P <- matrix(P, nrow = n)
  A <- sapply(lev, function(L) abs(side_amt("anom", L)))
  R <- sapply(lev, function(L) abs(side_amt("rec", L)))
  if (is.null(dim(A))) A <- matrix(A, nrow = n)
  if (is.null(dim(R))) R <- matrix(R, nrow = n)
  # orient preference indicator: TRUE should mean "wants recognition"
  onlyR <- !is.na(R) & is.na(A) & !is.na(P)
  onlyA <- is.na(R) & !is.na(A) & !is.na(P)
  agree <- (sum(P[onlyR]) + sum(!P[onlyA])) / max(1, sum(onlyR) + sum(onlyA))
  cat("Preference orientation agreement:", agree, "\n")
  if (agree < 0.5) P <- !P
  cat("Anon amounts summary:\n"); print(summary(as.vector(A)))
  cat("Recog amounts summary:\n"); print(summary(as.vector(R)))
  W <- matrix(NA_real_, n, nlev)
  for (j in seq_len(nlev)) {
    a <- A[, j]; r <- R[, j]; pj <- P[, j]
    w <- rep(NA_real_, n)
    i1 <- !is.na(r) & is.na(a); w[i1] <- r[i1]
    i2 <- is.na(r) & !is.na(a); w[i2] <- -a[i2]
    i3 <- !is.na(r) & !is.na(a) & !is.na(pj)
    w[i3] <- ifelse(pj[i3], r[i3], -a[i3])
    i4 <- is.na(r) & is.na(a) & !is.na(pj)
    w[i4] <- 0
    W[, j] <- w
  }
  cat("WTP built from pref_anom/pref_rec amounts\n")
  list(W = W, lev = lev, P = P)
}

# ---------- round order from timer columns (e.g. anom_aer_timer_PageSubmit) ----------
get_order_from_timers <- function(d) {
  nm <- names(d)
  codes <- c("aer", "ear", "are", "era", "rea", "rae")
  ord <- rep(NA_character_, nrow(d))
  found <- FALSE
  for (cd in codes) {
    cc <- nm[grepl(paste0("_", cd, "_timer"), nm, ignore.case = TRUE)]
    if (length(cc) == 0) next
    found <- TRUE
    has <- Reduce(`|`, lapply(cc, function(c) !is.na(d[[c]]) & as.character(d[[c]]) != ""))
    ord[is.na(ord) & has] <- cd
  }
  if (!found) return(NULL)
  cat("Order codes from timers:\n"); print(table(ord, useNA = "ifany"))
  POS <- matrix(NA_real_, nrow(d), 3, dimnames = list(NULL, c("anon", "paid", "public")))
  ok <- !is.na(ord)
  POS[ok, "anon"]   <- regexpr("a", ord[ok], fixed = TRUE)
  POS[ok, "paid"]   <- regexpr("e", ord[ok], fixed = TRUE)
  POS[ok, "public"] <- regexpr("r", ord[ok], fixed = TRUE)
  if (all(is.na(POS))) return(NULL)
  POS
}

# ---------- points and order ----------
get_points <- function(d) {
  nm <- names(d); low <- tolower(nm)
  P <- NULL; POS <- NULL
  direct <- c(anon = "AnomPts", paid = "EarnPts", public = "RecogPts")
  if (all(direct %in% nm)) {
    cat("Points columns (direct):", direct, "\n")
    P <- sapply(c("anon", "paid", "public"), function(r) num(d[[direct[[r]]]]))
    P <- matrix(P, ncol = 3, dimnames = list(NULL, c("anon", "paid", "public")))
    POS <- get_order_from_timers(d)
    return(list(P = P, POS = POS))
  }
  isorder <- grepl("order|position|sequence|^pos_|_pos(_|$)", low)
  pcand <- nm[grepl("point|pts|score|click|press|effort|perf|count", low) &
                !grepl("^preference|wtp|attention", low) & !isorder]
  cat("Points candidates:", paste(pcand, collapse = ", "), "\n")
  cls <- classify_round(pcand)
  pts <- list()
  for (r in c("anon", "paid", "public")) {
    cc <- pcand[!is.na(cls) & cls == r]
    if (length(cc) > 1) { cc2 <- cc[grepl("point|pts", tolower(cc))]; if (length(cc2) > 0) cc <- cc2 }
    if (length(cc) >= 1) pts[[r]] <- cc[1]
  }
  if (length(pts) == 3) {
    cat("Points columns:", unlist(pts), "\n")
    P <- sapply(c("anon", "paid", "public"), function(r) num(d[[pts[[r]]]]))
    POS <- get_order_from_timers(d)
    if (is.null(POS)) {
      ocand <- nm[isorder]
      cat("Order candidates:", paste(ocand, collapse = ", "), "\n")
      if (length(ocand) > 0) {
        ocls <- classify_round(ocand)
        if (all(c("anon", "paid", "public") %in% ocls)) {
          POS <- sapply(c("anon", "paid", "public"), function(r) num(d[[ocand[which(ocls == r)[1]]]]))
        }
      }
    }
  } else {
    pk <- tk <- character(0)
    for (k in 1:3) {
      a <- nm[grepl(paste0("round_?", k), low) & grepl("point|score|click|press", low)]
      b <- nm[grepl(paste0("round_?", k), low) & grepl("type|treat|cond|name|label|kind", low)]
      pk[k] <- if (length(a)) a[1] else NA; tk[k] <- if (length(b)) b[1] else NA
    }
    cat("Round-based columns:", pk, "|", tk, "\n")
    if (all(!is.na(pk)) && all(!is.na(tk))) {
      P <- matrix(NA_real_, nrow(d), 3, dimnames = list(NULL, c("anon", "paid", "public")))
      POS <- P
      for (k in 1:3) {
        cl <- classify_round(as.character(d[[tk[k]]]))
        for (r in c("anon", "paid", "public")) {
          i <- which(cl == r)
          P[i, r] <- num(d[[pk[k]]])[i]; POS[i, r] <- k
        }
      }
    }
  }
  if (!is.null(POS)) {
    POS <- matrix(as.numeric(POS), ncol = 3, dimnames = list(NULL, c("anon", "paid", "public")))
    if (min(POS, na.rm = TRUE) == 0) POS <- POS + 1
  }
  list(P = P, POS = POS)
}

process <- function(d, label) {
  cat("\n==========", label, "==========\n")
  cat("N rows:", nrow(d), "\n")
  ac <- as.character(d$attention_check)
  cat("attention_check table:\n"); print(head(sort(table(ac, useNA = "ifany"), decreasing = TRUE), 8))
  if (mean(is.na(ac)) > 0.5) {
    pass <- is.na(ac)
    cat("attention_check mostly missing: treating missing as pass\n")
  } else {
    m <- modal(ac)
    pass <- !is.na(ac) & ac == m
  }
  w <- get_wtp(d)
  W <- w$W
  ccol <- grep("coher", names(d), ignore.case = TRUE, value = TRUE)
  if (length(ccol) > 0) {
    v <- parse_pref(d[[ccol[1]]]); v[is.na(v)] <- FALSE
    incoh <- if (grepl("incoher", tolower(ccol[1]))) v else !v
    cat("Using coherence flag column", ccol[1], "\n")
  } else {
    sw <- apply(W, 1, function(r) {
      s <- sign(r); s <- s[!is.na(s) & s != 0]
      if (length(s) < 2) return(0)
      sum(diff(s) != 0)
    })
    allna <- apply(W, 1, function(r) all(is.na(r)))
    cat("Sign switches distribution among attention-pass:\n"); print(table(sw[pass]))
    cat("All-missing WTP among attention-pass:", sum(allna & pass), "\n")
    incoh <- sw > 2 | allna
  }
  pp <- get_points(d)
  if (is.null(pp$P)) stop("Could not identify points columns for ", label)
  complete <- apply(pp$P, 1, function(r) all(!is.na(r)))
  keep <- pass & !incoh & complete
  cat("attention pass:", sum(pass), " coherent among pass:", sum(pass & !incoh),
      " complete points:", sum(complete), " final:", sum(keep), "\n")
  ids <- if (!is.null(d$id)) as.character(d$id) else as.character(seq_len(nrow(d)))
  long <- do.call(rbind, lapply(c("anon", "paid", "public"), function(r) {
    data.frame(id = ids, round = r, points = pp$P[, r],
               pos = if (!is.null(pp$POS)) pp$POS[, r] else NA_real_, keep = keep,
               stringsAsFactors = FALSE)
  }))
  long <- long[long$keep, ]
  long$public <- as.integer(long$round == "public")
  long$paid <- as.integer(long$round == "paid")
  wl <- data.frame(id = rep(ids, times = length(w$lev)), lev = rep(w$lev, each = nrow(d)),
                   wtp = as.vector(W), keep = rep(keep, times = length(w$lev)))
  wl <- wl[wl$keep & !is.na(wl$wtp), ]
  list(long = long, wtp = wl)
}

run_reg <- function(long) {
  if (any(!is.na(long$pos)) && length(unique(na.omit(long$pos))) >= 2) {
    long$pos2 <- as.integer(long$pos == 2); long$pos3 <- as.integer(long$pos == 3)
    f <- feols(points ~ public + paid + pos2 + pos3, data = long, cluster = ~id)
  } else {
    cat("No round order info: estimating without order dummies\n")
    f <- feols(points ~ public + paid, data = long, cluster = ~id)
  }
  print(summary(f))
  f
}

# Tobit for WTP censored at the slider bounds
tobit_fit <- function(wl) {
  hi <- max(abs(wl$wtp), na.rm = TRUE); lo <- -hi
  cat("Tobit censoring bounds:", lo, hi, "\n")
  t1 <- ifelse(wl$wtp <= lo, NA, wl$wtp)
  t2 <- ifelse(wl$wtp >= hi, NA, wl$wtp)
  y <- Surv(t1, t2, type = "interval2")
  m <- survreg(y ~ mid + mid2, data = wl, dist = "gaussian")
  print(summary(m))
  m
}

cat("DEVIATION: WTP rebuilt by combining pref_rec (positive) and pref_anom (negative) slider amounts across both slider scales; only participants with no WTP responses or >2 sign switches are treated as incoherent\n")
cat("DEVIATION: Berkeley structural PRU (Table 7) uses a Tobit fit of WTP on midpoint and midpoint^2 (censored at the slider bounds) instead of OLS, following the paper's use of Tobit censoring assumptions in the structural analysis\n")
cat("DEVIATION: BU sample restricted to the single statistics class file (QM221) rather than pooling QM221 and QM222, as the paper describes one BU statistics class\n")

res <- list()

# ---------- Prolific ----------
tryCatch({
  pr <- process(rd("prolific_survey_data.csv"), "Prolific")
  f1 <- run_reg(pr$long)
  res$public_recognition_points_prolific_table5_col1 <- coef(f1)["public"]
  res$financial_incentives_points_prolific_table5_col1 <- coef(f1)["paid"]
  res$n_obs_prolific_table5_col1 <- nobs(f1)
}, error = function(e) cat("Prolific error:", conditionMessage(e), "\n"))

# ---------- Berkeley ----------
tryCatch({
  be <- process(rd("berkeley_survey_data.csv"), "Berkeley")
  f2 <- run_reg(be$long)
  res$public_recognition_points_berkeley_table5_col2 <- coef(f2)["public"]
  res$financial_incentives_points_berkeley_table5_col2 <- coef(f2)["paid"]
  res$n_obs_berkeley_table5_col2 <- nobs(f2)

  # Table 6 col 4: quadratic WTP on midpoint (hundreds), excluding 1700+
  wl <- be$wtp
  maxlev <- max(wl$lev)
  wl <- wl[wl$lev < maxlev, ]
  wl$mid <- (wl$lev + 50) / 100
  wl$mid2 <- wl$mid^2
  g <- feols(wtp ~ mid + mid2, data = wl, cluster = ~id)
  print(summary(g))
  gt <- tobit_fit(wl)
  r0 <- unname(coef(gt)[1]); r1 <- unname(coef(gt)["mid"]); r2 <- unname(coef(gt)["mid2"])
  tau <- unname(coef(f2)["public"]) / 100
  abar0 <- mean(be$long$points[be$long$round == "anon"], na.rm = TRUE) / 100
  abar <- abar0 + tau
  cat("r0,r1,r2:", r0, r1, r2, " abar_anon:", abar0, " abar_public:", abar, " tau:", tau, "\n")
  if (abs(r2) < 1e-12) {
    x <- -r0 / r1
  } else {
    disc <- r1^2 - 4 * r2 * r0
    if (disc < 0) {
      x <- NA
    } else {
      roots <- c((-r1 + sqrt(disc)) / (2 * r2), (-r1 - sqrt(disc)) / (2 * r2))
      up <- roots[r1 + 2 * r2 * roots > 0]
      cand <- if (length(up) >= 1) up else roots
      x <- cand[which.min(abs(cand - abar))]
    }
  }
  rho <- x / abar
  gamma1 <- r1 + 2 * r2 * x
  cpar <- (r1 + 2 * r2 * abar) / tau
  pinc <- 0.05 * 10
  pred <- pinc / cpar
  res$action_signaling_gamma1_berkeley_table7_panelA <- gamma1
  res$action_signaling_rho_berkeley_table7_panelA <- rho
  res$cost_parameter_c_berkeley_table7_panelA <- cpar
  res$predicted_financial_incentive_effect_berkeley_table7_panelC <- pred
}, error = function(e) cat("Berkeley error:", conditionMessage(e), "\n"))

# ---------- BU ----------
tryCatch({
  b1 <- rd("bu_qm221_survey_data.csv")
  b1$id <- paste0("qm221_", b1$id)
  b1$id <- as.character(b1$id)
  bb <- process(b1, "BU (QM221)")
  f3 <- run_reg(bb$long)
  res$public_recognition_points_bu_table5_col3 <- coef(f3)["public"]
  res$financial_incentives_points_bu_table5_col3 <- coef(f3)["paid"]
  res$n_obs_bu_table5_col3 <- nobs(f3)
  tryCatch({
    b2 <- rd("bu_qm222_survey_data.csv")
    b2$id <- paste0("qm222_", b2$id)
    bb2 <- process(b2, "BU (QM222, diagnostic only)")
    cat("QM222 final participant-rounds (not used):", nrow(bb2$long), "\n")
  }, error = function(e) cat("QM222 diagnostic error:", conditionMessage(e), "\n"))
}, error = function(e) cat("BU error:", conditionMessage(e), "\n"))

cat("\n")
for (n in names(res)) {
  v <- unname(res[[n]])
  if (length(v) == 1 && !is.na(v)) cat(sprintf("RESULT:%s=%.6f\n", n, v))
}