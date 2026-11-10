suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- file.path("<repo>/.cache/datasets/butera_2022_welfare_effects_shame_pride.script-free",
                  "Packet", "Raw Data")

rd <- function(f) {
  d <- read_csv(file.path(base, f), show_col_types = FALSE, guess_max = 100000)
  as.data.frame(d, stringsAsFactors = FALSE)
}

normstr <- function(x) trimws(tolower(as.character(x)))

# attention check: keep the modal (passing) response
attention_keep <- function(d) {
  if (!"attention_check" %in% names(d)) return(rep(TRUE, nrow(d)))
  a <- normstr(d$attention_check)
  nonmiss <- !is.na(a) & a != ""
  share_nonmiss <- mean(nonmiss)
  cat("  attention_check non-missing share:", share_nonmiss, "\n")
  if (sum(nonmiss) == 0) return(rep(TRUE, nrow(d)))
  tab <- sort(table(a[nonmiss]), decreasing = TRUE)
  cat("  attention_check values:", paste(names(tab), tab, sep = "=", collapse = "; "), "\n")
  vals <- names(tab)
  if (all(vals %in% c("0", "1"))) pass <- "1"
  else if (all(vals %in% c("true", "false"))) pass <- "true"
  else pass <- vals[1]
  if (share_nonmiss < 0.5) {
    # mostly unrecorded: drop only explicit failures
    cat("  attention_check mostly missing; dropping only explicit failures\n")
    return(!(nonmiss & a != pass))
  }
  nonmiss & a == pass
}

pro <- rd("prolific_survey_data.csv")
ber <- rd("berkeley_survey_data.csv")
bu1 <- rd("bu_qm221_survey_data.csv")
bu2 <- rd("bu_qm222_survey_data.csv")

cat("BU qm221 raw rows:", nrow(bu1), "\n")
cat("BU qm222 raw rows:", nrow(bu2), "\n")
# The paper describes the BU subject pool as a single BU statistics class.
# The reported participant-rounds (354 = 118 x 3) match the qm222 class, not
# the two classes combined, so only the qm222 class is used.
cat("DEVIATION: BU sample restricted to the single statistics class file bu_qm222 (paper describes one BU statistics class; combined classes far exceed the reported N)\n")
bu <- bu2

for (nmd in c("pro", "ber", "bu")) {
  d <- get(nmd)
  cat("Dataset", nmd, "rows:", nrow(d), "\n")
}

# ------------------------------------------------------------------
# helpers
# ------------------------------------------------------------------
classify_type <- function(s) {
  s <- tolower(as.character(s))
  out <- rep(NA_character_, length(s))
  is_paid <- grepl("paid|pay|incent|money|financ|bonus|cash|earn", s)
  is_pub  <- grepl("public|shar|recog|image", s)
  is_anon <- grepl("anon|private|baseline|control", s)
  out[is_anon & !is_paid & !is_pub] <- "anon"
  out[is_pub & !is_paid] <- "public"
  out[is_paid] <- "paid"
  out[is.na(s)] <- NA_character_
  out
}

pts_pat <- "point|score|click|press|pts"
excl_pat <- "^preference|wtp|forecast|predict|guess|expect|belief|estim|bid|amount|order|position|sequence|rank|practice|final|clicked"

coalesce_cols <- function(d, cols) {
  if (length(cols) == 0) return(rep(NA_real_, nrow(d)))
  out <- rep(NA_real_, nrow(d))
  for (cc in cols) {
    x <- suppressWarnings(as.numeric(d[[cc]]))
    out[is.na(out)] <- x[is.na(out)]
  }
  out
}

# WTP matrix (participants x thresholds)
# Recognition-preferrers report the amount in pref_rec_X_*, anonymity-preferrers in
# pref_anom_X_*.  WTP = +rec amount or -anon amount.
get_wtp <- function(d) {
  nm <- names(d)
  pcols <- nm[grepl("^preference_[0-9]+$", nm)]
  xs <- as.numeric(sub("^preference_", "", pcols))
  o <- order(xs); pcols <- pcols[o]; xs <- xs[o]
  W <- matrix(NA_real_, nrow(d), length(xs))
  P <- matrix(NA_real_, nrow(d), length(xs))
  for (j in seq_along(xs)) {
    X <- xs[j]
    pref <- d[[pcols[j]]]
    P[, j] <- suppressWarnings(as.numeric(normstr(pref)))
    rc <- nm[grepl(paste0("^pref_rec_", X, "_"), nm)]
    ac <- nm[grepl(paste0("^pref_anom_", X, "_"), nm)]
    if (j == 1 || X == 1000) {
      for (cc in c(rc, ac)) {
        x <- suppressWarnings(as.numeric(d[[cc]]))
        cat(sprintf("    %s: nonmiss=%d mean=%.3f min=%.3f max=%.3f\n", cc, sum(!is.na(x)),
                    mean(x, na.rm = TRUE), suppressWarnings(min(x, na.rm = TRUE)),
                    suppressWarnings(max(x, na.rm = TRUE))))
      }
      tp <- table(normstr(pref), useNA = "ifany")
      cat("    ", pcols[j], "values:", paste(names(tp), tp, sep = "=", collapse = "; "), "\n")
    }
    if (is.numeric(pref) && any(pref < 0, na.rm = TRUE)) {
      W[, j] <- pref
      next
    }
    if (length(rc) > 0 || length(ac) > 0) {
      ramt <- abs(coalesce_cols(d, rc))
      aamt <- abs(coalesce_cols(d, ac))
      # map preference values to sign using association with which amount was filled
      p <- normstr(pref)
      sgn <- rep(NA_real_, nrow(d))
      only_r <- !is.na(ramt) & is.na(aamt)
      only_a <- is.na(ramt) & !is.na(aamt)
      for (v in unique(p[!is.na(p) & p != ""])) {
        idx <- !is.na(p) & p == v
        nr <- sum(idx & only_r); na_ <- sum(idx & only_a)
        if (nr + na_ > 0) {
          sgn[idx] <- ifelse(nr >= na_, 1, -1)
        } else {
          yes <- grepl("^(yes|y|true)$|^yes|want|recogn|public|shar", v) &
                 !grepl("^no|not|don|n't|anonym", v)
          sgn[idx] <- ifelse(yes, 1, -1)
        }
      }
      w <- rep(NA_real_, nrow(d))
      w[only_r] <- ramt[only_r]
      w[only_a] <- -aamt[only_a]
      both <- !is.na(ramt) & !is.na(aamt)
      w[both & !is.na(sgn) & sgn > 0] <- ramt[both & !is.na(sgn) & sgn > 0]
      w[both & !is.na(sgn) & sgn < 0] <- -aamt[both & !is.na(sgn) & sgn < 0]
      # stated a preference but left the amount slider untouched -> WTP 0
      none <- is.na(ramt) & is.na(aamt) & !is.na(p) & p != ""
      w[none] <- 0
      W[, j] <- w
    } else {
      W[, j] <- suppressWarnings(as.numeric(pref))
    }
  }
  cat("  WTP matrix: nonmissing =", sum(!is.na(W)), " mean =", mean(W, na.rm = TRUE),
      " share positive =", mean(W > 0, na.rm = TRUE), "\n")
  list(W = W, P = P, xs = xs)
}

# Incoherent = stated recognition/anonymity preference has no discernible relation
# to performance: the binary preference switches back and forth more than twice
# across thresholds (monotone profiles switch at most once, peaked profiles twice).
coherent_keep <- function(d, W, P) {
  nm <- names(d)
  fl <- nm[grepl("incoheren|coheren|exclu|final_sample|keep|include", nm, ignore.case = TRUE)]
  if (length(fl) > 0) {
    f <- fl[1]; v <- normstr(d[[f]])
    flag <- v %in% c("1", "true", "yes")
    cat("  using coherence flag column:", f, "\n")
    if (grepl("incoheren|exclu", f, ignore.case = TRUE)) return(!flag)
    return(flag)
  }
  apply(P, 1, function(p) {
    p <- p[!is.na(p)]
    if (length(p) < 3) return(TRUE)
    sum(diff(p) != 0) <= 2
  })
}

get_positions_timer <- function(d) {
  nm <- names(d)
  tc <- nm[grepl("^(anom|earn|rec)_[aer]{3}_timer", nm)]
  if (length(tc) == 0) return(NULL)
  ords <- unique(sub("^(anom|earn|rec)_([aer]{3})_timer.*$", "\\2", tc))
  n <- nrow(d)
  ordv <- rep(NA_character_, n)
  for (o in ords) {
    cols <- tc[grepl(paste0("_", o, "_timer"), tc)]
    has <- Reduce(`|`, lapply(cols, function(cc) {
      x <- d[[cc]]
      !is.na(x) & as.character(x) != ""
    }))
    ordv[is.na(ordv) & has] <- o
  }
  cat("  order assignment from timer columns:",
      paste(names(table(ordv, useNA = "ifany")), table(ordv, useNA = "ifany"), sep = "=", collapse = "; "), "\n")
  if (mean(!is.na(ordv)) < 0.5) return(NULL)
  pos_of <- function(letter) {
    vapply(ordv, function(o) if (is.na(o)) NA_real_ else as.numeric(regexpr(letter, o)), numeric(1))
  }
  cbind(anon = unname(pos_of("a")), paid = unname(pos_of("e")), public = unname(pos_of("r")))
}

parse_order_strings <- function(v) {
  v <- as.character(v)
  try_split <- function(sep) {
    lapply(strsplit(v, sep), function(tk) { tk <- trimws(tk); tk[tk != ""] })
  }
  for (sep in c("[,;|>/]+", "\\s*-\\s*", "\\s+", "_")) {
    toks <- try_split(sep)
    ok <- vapply(toks, function(tk) {
      isTRUE(length(tk) == 3 && all(sort(classify_type(tk)) == c("anon", "paid", "public")))
    }, logical(1))
    if (length(ok) > 0 && mean(ok) > 0.9) {
      pos <- t(sapply(seq_along(toks), function(i) {
        if (!ok[i]) return(c(anon = NA, paid = NA, public = NA))
        ty <- classify_type(toks[[i]])
        c(anon = which(ty == "anon"), paid = which(ty == "paid"), public = which(ty == "public"))
      }))
      return(pos)
    }
  }
  NULL
}

get_positions <- function(d) {
  pt <- get_positions_timer(d)
  if (!is.null(pt)) return(pt)
  nm <- names(d)
  oc <- nm[grepl("order|position|sequence|rank", nm, ignore.case = TRUE)]
  if (length(oc) > 0) {
    numoc <- oc[vapply(d[oc], is.numeric, logical(1))]
    numty <- classify_type(numoc)
    if (all(c("anon", "paid", "public") %in% numty)) {
      pos <- sapply(c("anon", "paid", "public"), function(t) {
        x <- numoc[numty == t & !is.na(numty)]; d[[x[which.min(nchar(x))]]]
      })
      return(pos)
    }
    charoc <- oc[!vapply(d[oc], is.numeric, logical(1))]
    for (cc in charoc) {
      p <- tryCatch(parse_order_strings(d[[cc]]), error = function(e) NULL)
      if (!is.null(p)) { cat("  order parsed from string column:", cc, "\n"); return(p) }
    }
  }
  cat("  WARNING: could not find round order; order dummies omitted\n")
  NULL
}

build_long <- function(d) {
  nm <- names(d)
  d$pid <- seq_len(nrow(d))
  if (all(c("AnomPts", "EarnPts", "RecogPts") %in% nm)) {
    pc <- c(anon = "AnomPts", paid = "EarnPts", public = "RecogPts")
  } else {
    isnum <- vapply(d[nm], is.numeric, logical(1))
    cand <- nm[grepl(pts_pat, nm, ignore.case = TRUE) & !grepl(excl_pat, nm, ignore.case = TRUE) & isnum]
    ty <- classify_type(cand)
    if (!all(c("anon", "paid", "public") %in% ty)) stop("Could not identify points columns")
    pc <- sapply(c("anon", "paid", "public"), function(t) {
      x <- cand[ty == t & !is.na(ty)]; x[which.min(nchar(x))]
    })
  }
  cat("  points columns:", paste(names(pc), pc, sep = "=", collapse = "; "), "\n")
  pos <- get_positions(d)
  long <- do.call(rbind, lapply(c("anon", "paid", "public"), function(t) {
    data.frame(pid = d$pid, type = t, points = suppressWarnings(as.numeric(d[[pc[[t]]]])),
               position = if (is.null(pos)) NA else pos[, t], stringsAsFactors = FALSE)
  }))
  long
}

prep_sample <- function(d, label) {
  cat("\n==== ", label, " ====\n")
  keepA <- attention_keep(d)
  cat("  N raw:", nrow(d), " pass attention:", sum(keepA), "\n")
  d <- d[keepA, , drop = FALSE]
  w <- get_wtp(d)
  keepC <- coherent_keep(d, w$W, w$P)
  cat("  coherent:", sum(keepC), " dropped incoherent:", sum(!keepC), "\n")
  d <- d[keepC, , drop = FALSE]
  W <- w$W[keepC, , drop = FALSE]
  list(d = d, W = W, xs = w$xs)
}

run_table5 <- function(s) {
  long <- build_long(s$d)
  long <- long[!is.na(long$points) & !is.na(long$type), ]
  long$public <- as.integer(long$type == "public")
  long$paid <- as.integer(long$type == "paid")
  if (all(is.na(long$position)) || length(unique(na.omit(long$position))) < 2) {
    m <- feols(points ~ public + paid, data = long, cluster = ~pid)
  } else {
    long$position <- factor(long$position)
    m <- feols(points ~ public + paid + position, data = long, cluster = ~pid)
  }
  print(summary(m))
  list(m = m, long = long)
}

cat("DEVIATION: Incoherent participants defined as those whose binary recognition/anonymity choice switches more than twice across performance thresholds (exact rule not given in the provided text)\n")

S_pro <- prep_sample(pro, "Prolific")
S_ber <- prep_sample(ber, "Berkeley")
S_bu  <- prep_sample(bu, "BU")

T_pro <- run_table5(S_pro)
T_ber <- run_table5(S_ber)
T_bu  <- run_table5(S_bu)

# ------------------------------------------------------------------
# Berkeley structural (action-signaling), Table 6 col 4 / Table 7
# ------------------------------------------------------------------
W <- S_ber$W; xs <- S_ber$xs
wl <- data.frame(pid = rep(seq_len(nrow(W)), times = length(xs)),
                 X = rep(xs, each = nrow(W)),
                 wtp = as.vector(W))
wl <- wl[!is.na(wl$wtp) & wl$X < 1700, ]
wl$m <- (wl$X + 50) / 100
pru <- feols(wtp ~ m + I(m^2), data = wl, cluster = ~pid)
print(summary(pru))
r0 <- unname(coef(pru)[1]); r1 <- unname(coef(pru)[2]); r2 <- unname(coef(pru)[3])

lb <- T_ber$long
abar0 <- mean(lb$points[lb$type == "anon"], na.rm = TRUE) / 100
delta <- unname(coef(T_ber$m)["public"]) / 100
abar1 <- abar0 + delta
cat("abar0 =", abar0, " delta =", delta, " abar1 =", abar1, "\n")

disc <- r1^2 - 4 * r2 * r0
k <- NA_real_
if (abs(r2) > 1e-12 && disc >= 0) {
  roots <- c((-r1 + sqrt(disc)) / (2 * r2), (-r1 - sqrt(disc)) / (2 * r2))
  slope <- r1 + 2 * r2 * roots
  up <- roots[slope > 0]
  if (length(up) == 0) up <- roots
  k <- up[which.min(abs(up - abar1))]
}
if (is.na(k) || k < 0 || k > 2 * max(wl$m)) {
  # quadratic PRU has no usable zero crossing: fall back to linear PRU
  cat("DEVIATION: Quadratic PRU has no usable zero crossing; using linear PRU for the structural parameters\n")
  pru_l <- feols(wtp ~ m, data = wl, cluster = ~pid)
  print(summary(pru_l))
  r0 <- unname(coef(pru_l)[1]); r1 <- unname(coef(pru_l)[2]); r2 <- 0
  k <- -r0 / r1
}
rho <- k / abar1
gamma1 <- r1 + 2 * r2 * k
c_par <- (r1 + 2 * r2 * abar1) / delta
p_inc <- 0.05 * 10  # 5 cents per 10 points = $0.50 per hundred points
pred_fin <- p_inc / c_par

# ------------------------------------------------------------------
cat(sprintf("RESULT:public_recognition_points_prolific_table5_col1=%.6f\n", coef(T_pro$m)["public"]))
cat(sprintf("RESULT:financial_incentives_points_prolific_table5_col1=%.6f\n", coef(T_pro$m)["paid"]))
cat(sprintf("RESULT:public_recognition_points_berkeley_table5_col2=%.6f\n", coef(T_ber$m)["public"]))
cat(sprintf("RESULT:financial_incentives_points_berkeley_table5_col2=%.6f\n", coef(T_ber$m)["paid"]))
cat(sprintf("RESULT:public_recognition_points_bu_table5_col3=%.6f\n", coef(T_bu$m)["public"]))
cat(sprintf("RESULT:financial_incentives_points_bu_table5_col3=%.6f\n", coef(T_bu$m)["paid"]))
cat(sprintf("RESULT:n_obs_prolific_table5_col1=%d\n", nobs(T_pro$m)))
cat(sprintf("RESULT:n_obs_berkeley_table5_col2=%d\n", nobs(T_ber$m)))
cat(sprintf("RESULT:n_obs_bu_table5_col3=%d\n", nobs(T_bu$m)))
cat(sprintf("RESULT:action_signaling_gamma1_berkeley_table7_panelA=%.6f\n", gamma1))
cat(sprintf("RESULT:action_signaling_rho_berkeley_table7_panelA=%.6f\n", rho))
cat(sprintf("RESULT:cost_parameter_c_berkeley_table7_panelA=%.6f\n", c_par))
cat(sprintf("RESULT:predicted_financial_incentive_effect_berkeley_table7_panelC=%.6f\n", pred_fin))
