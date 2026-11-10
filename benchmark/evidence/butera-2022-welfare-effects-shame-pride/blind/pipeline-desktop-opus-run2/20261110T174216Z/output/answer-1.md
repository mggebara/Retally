suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/butera_2022_welfare_effects_shame_pride.script-free"
raw_dir <- file.path(base, "Packet", "Raw Data")

rd <- function(f) {
  d <- suppressMessages(readr::read_csv(file.path(raw_dir, f), show_col_types = FALSE, guess_max = 100000))
  as.data.frame(d)
}

prol <- rd("prolific_survey_data.csv")
berk <- rd("berkeley_survey_data.csv")
bu1 <- rd("bu_qm221_survey_data.csv")
bu2 <- rd("bu_qm222_survey_data.csv")

cat("Prolific columns:\n"); print(names(prol))
cat("Berkeley columns:\n"); print(names(berk))

# combine BU files (ids may overlap across classes)
bu1$id <- paste0("qm221_", bu1$id)
bu2$id <- paste0("qm222_", bu2$id)
common_bu <- intersect(names(bu1), names(bu2))
bu <- rbind(bu1[, common_bu], bu2[, common_bu])

# ---------------- helpers ----------------
to_num <- function(x) suppressWarnings(as.numeric(as.character(x)))

attention_pass <- function(x) {
  if (is.logical(x)) return(!is.na(x) & x)
  xn <- to_num(x)
  if (sum(!is.na(xn)) > 0 && all(xn[!is.na(xn)] %in% c(0, 1))) return(!is.na(xn) & xn == 1)
  xc <- tolower(trimws(as.character(x)))
  ok <- grepl("pass|correct|^yes|^true|^1$", xc) & !grepl("fail|incorrect|wrong", xc)
  if (sum(ok, na.rm = TRUE) == 0) {
    cat("WARNING: could not interpret attention_check; values:\n"); print(table(x, useNA = "ifany"))
    return(rep(TRUE, length(x)))
  }
  !is.na(ok) & ok
}

type_of <- function(n) {
  l <- tolower(n)
  if (grepl("paid|pay|incent|money|financ|bonus|cash", l)) return("F")
  if (grepl("public|shar|recog|named", l)) return("P")
  if (grepl("anon|private|base", l)) return("A")
  NA_character_
}

# sign of preference: +1 want recognition, -1 do not
pref_sign <- function(x) {
  xn <- to_num(x)
  if (sum(!is.na(xn)) > 0 && sum(!is.na(xn)) >= sum(!is.na(x)) * 0.99) {
    vals <- sort(unique(xn[!is.na(xn)]))
    if (all(vals %in% c(0, 1))) return(ifelse(xn == 1, 1, -1))
    if (all(vals %in% c(1, 2))) return(ifelse(xn == 1, 1, -1))
    return(sign(xn))
  }
  xc <- tolower(as.character(x))
  out <- ifelse(is.na(xc), NA_real_,
                ifelse(grepl("not|don't|do not|dont|^no|anonym|private", xc), -1, 1))
  out
}

build_wtp <- function(df) {
  nm <- names(df)
  pcols <- grep("^preference_[0-9]+$", nm, value = TRUE)
  suf <- as.numeric(sub("^preference_", "", pcols))
  ord <- order(suf); pcols <- pcols[ord]; suf <- suf[ord]
  # look for companion amount columns with same numeric suffixes
  numcols <- grep("_[0-9]+$", nm, value = TRUE)
  prefixes <- unique(sub("_[0-9]+$", "", numcols))
  prefixes <- setdiff(prefixes, "preference")
  cand <- prefixes[sapply(prefixes, function(p) all(paste0(p, "_", suf) %in% nm))]
  amt_pref <- cand[grepl("wtp|amount|value|price|pay|bid|willing|money|give", cand, ignore.case = TRUE)]
  if (length(amt_pref) == 0) amt_pref <- character(0)
  P <- sapply(pcols, function(c) to_num(df[[c]]))
  if (!is.matrix(P)) P <- matrix(P, nrow = nrow(df))
  rawP <- df[, pcols, drop = FALSE]
  is_signed_wtp <- all(sapply(pcols, function(c) {
    v <- to_num(df[[c]]); v <- v[!is.na(v)]
    length(v) > 0 && (any(v < 0) || length(unique(v)) > 3)
  }))
  if (length(amt_pref) >= 1) {
    ap <- amt_pref[1]
    cat("Using WTP amount columns with prefix:", ap, "\n")
    W <- sapply(seq_along(pcols), function(j) {
      s <- pref_sign(df[[pcols[j]]])
      a <- abs(to_num(df[[paste0(ap, "_", suf[j])]]))
      s * a
    })
  } else if (is_signed_wtp) {
    cat("preference_* columns treated as signed WTP\n")
    W <- P
  } else {
    cat("WARNING: no amount columns found; values of preference_0:\n")
    print(table(df[[pcols[1]]], useNA = "ifany"))
    W <- P
  }
  if (!is.matrix(W)) W <- matrix(W, nrow = nrow(df))
  colnames(W) <- as.character(suf)
  list(W = W, suf = suf)
}

coherent <- function(W) {
  apply(W, 1, function(w) {
    w <- w[!is.na(w)]
    if (length(w) < 2) return(FALSE)
    s <- sign(diff(w)); s <- s[s != 0]
    if (length(s) <= 1) return(TRUE)
    # allowed: +...+ -...- (monotone or single-peaked); disallowed: a -1 followed by +1
    first_neg <- which(s < 0)
    if (length(first_neg) == 0) return(TRUE)
    !any(s[first_neg[1]:length(s)] > 0)
  })
}

# Build long panel of points by round type with order position
build_points <- function(df) {
  nm <- names(df)
  excl <- grepl("preference|wtp|belief|predict|guess|expect|forecast|estimat|attention|^id$|willing|price|amount|order|position|sequence", nm, ignore.case = TRUE)
  cand <- nm[!excl & grepl("point|score|press|click|effort|perf", nm, ignore.case = TRUE)]
  types <- sapply(cand, type_of)
  cat("Candidate points columns:\n"); print(types)
  pc <- list()
  for (t in c("A", "P", "F")) {
    cc <- cand[!is.na(types) & types == t]
    if (length(cc) >= 1) pc[[t]] <- cc[1]
  }
  if (length(pc) < 3) stop("Could not identify points columns for all three rounds")
  # order columns
  ocols <- nm[grepl("order|position|sequence", nm, ignore.case = TRUE)]
  otypes <- sapply(ocols, type_of)
  pos <- NULL
  if (length(ocols) > 0 && all(c("A", "P", "F") %in% otypes)) {
    pos <- sapply(c("A", "P", "F"), function(t) to_num(df[[ocols[which(otypes == t)[1]]]]))
  } else if (length(ocols) >= 1) {
    oc <- ocols[1]
    cat("Parsing order column:", oc, "\n"); print(head(table(df[[oc]]), 10))
    pos <- t(sapply(as.character(df[[oc]]), function(s) {
      if (is.na(s)) return(c(A = NA, P = NA, F = NA))
      toks <- unlist(strsplit(s, "[^A-Za-z&]+"))
      toks <- toks[toks != ""]
      if (length(toks) < 3) {
        toks <- unlist(strsplit(gsub("[^A-Za-z]", "", s), ""))
        map <- c(a = "A", p = "P", s = "P", f = "F", m = "F", i = "F")
        tt <- map[tolower(toks)]
      } else {
        tt <- sapply(toks, type_of)
      }
      r <- c(A = NA, P = NA, F = NA)
      for (k in seq_along(tt)) if (!is.na(tt[k]) && is.na(r[tt[k]])) r[tt[k]] <- k
      r
    }))
    colnames(pos) <- c("A", "P", "F")
  }
  long <- bind_rows(lapply(c("A", "P", "F"), function(t) {
    data.frame(id = df$id, round = t, points = to_num(df[[pc[[t]]]]),
               pos = if (is.null(pos)) NA_real_ else as.numeric(pos[, t]),
               stringsAsFactors = FALSE)
  }))
  long$public <- as.numeric(long$round == "P")
  long$paid <- as.numeric(long$round == "F")
  long
}

prep <- function(df, label) {
  df$id <- as.character(df$id)
  pass <- attention_pass(df$attention_check)
  wt <- build_wtp(df)
  coh <- coherent(wt$W)
  keep <- pass & coh
  cat(label, ": N =", nrow(df), " pass attention =", sum(pass), " coherent among passers =", sum(keep), "\n")
  list(df = df[keep, , drop = FALSE], W = wt$W[keep, , drop = FALSE], suf = wt$suf)
}

run_t5 <- function(s, label) {
  long <- build_points(s$df)
  long <- long[!is.na(long$points), ]
  if (all(is.na(long$pos))) {
    cat("WARNING: no round order info for", label, "\n")
    m <- feols(points ~ public + paid, data = long, cluster = ~id)
  } else {
    m <- feols(points ~ public + paid + factor(pos), data = long, cluster = ~id)
  }
  print(summary(m))
  list(m = m, long = long)
}

P <- prep(prol, "Prolific")
B <- prep(berk, "Berkeley")
U <- prep(bu, "BU")

rP <- run_t5(P, "Prolific")
rB <- run_t5(B, "Berkeley")
rU <- run_t5(U, "BU")

# ---------------- Table 6 col 4 (Berkeley): WTP on midpoint & square, top interval excluded ----------------
W <- B$W; suf <- B$suf
top <- max(suf)
pan <- data.frame(id = rep(B$df$id, times = ncol(W)),
                  lower = rep(suf, each = nrow(W)),
                  wtp = as.vector(W))
pan <- pan[pan$lower < top & !is.na(pan$wtp), ]
pan$a <- (pan$lower + 49.5) / 100
pan$a2 <- pan$a^2
m6 <- feols(wtp ~ a + a2, data = pan, cluster = ~id)
print(summary(m6))
r0 <- unname(coef(m6)["(Intercept)"]); r1 <- unname(coef(m6)["a"]); r2 <- unname(coef(m6)["a2"])

# average points with PR in Berkeley (hundreds): anonymous mean + PR effect
lB <- rB$long
anon_mean <- mean(lB$points[lB$round == "A"], na.rm = TRUE) / 100
pr_eff <- unname(coef(rB$m)["public"]) / 100
abar <- anon_mean + pr_eff

# rho * abar solves r0 + r1 x + r2 x^2 = 0 (image payoff zero); choose root with positive slope
disc <- r1^2 - 4 * r2 * r0
if (disc >= 0 && abs(r2) > 1e-12) {
  roots <- c((-r1 + sqrt(disc)) / (2 * r2), (-r1 - sqrt(disc)) / (2 * r2))
  slopes <- r1 + 2 * r2 * roots
  okr <- roots[slopes > 0]
  x <- if (length(okr) >= 1) okr[which.min(abs(okr - abar))] else roots[which.min(abs(roots - abar))]
} else {
  x <- -r0 / r1
}
gamma2 <- r2
gamma1 <- r1 + 2 * r2 * x
rho <- x / abar
# c from: c * (PR effect) = S'(abar - rho abar) = r1 + 2 r2 abar
c_par <- (r1 + 2 * r2 * abar) / pr_eff
p_inc <- 0.05 * 10  # 5 cents per 10 points = $0.50 per hundred points
pred_fi <- p_inc / c_par

cat(sprintf("r0=%.4f r1=%.4f r2=%.4f abar=%.4f x=%.4f\n", r0, r1, r2, abar, x))

cat(sprintf("RESULT:public_recognition_points_prolific_table5_col1=%.6f\n", coef(rP$m)["public"]))
cat(sprintf("RESULT:financial_incentives_points_prolific_table5_col1=%.6f\n", coef(rP$m)["paid"]))
cat(sprintf("RESULT:public_recognition_points_berkeley_table5_col2=%.6f\n", coef(rB$m)["public"]))
cat(sprintf("RESULT:financial_incentives_points_berkeley_table5_col2=%.6f\n", coef(rB$m)["paid"]))
cat(sprintf("RESULT:public_recognition_points_bu_table5_col3=%.6f\n", coef(rU$m)["public"]))
cat(sprintf("RESULT:financial_incentives_points_bu_table5_col3=%.6f\n", coef(rU$m)["paid"]))
cat(sprintf("RESULT:n_obs_prolific_table5_col1=%d\n", nobs(rP$m)))
cat(sprintf("RESULT:n_obs_berkeley_table5_col2=%d\n", nobs(rB$m)))
cat(sprintf("RESULT:n_obs_bu_table5_col3=%d\n", nobs(rU$m)))
cat(sprintf("RESULT:action_signaling_gamma1_berkeley_table7_panelA=%.6f\n", gamma1))
cat(sprintf("RESULT:action_signaling_rho_berkeley_table7_panelA=%.6f\n", rho))
cat(sprintf("RESULT:cost_parameter_c_berkeley_table7_panelA=%.6f\n", c_par))
cat(sprintf("RESULT:predicted_financial_incentive_effect_berkeley_table7_panelC=%.6f\n", pred_fi))
