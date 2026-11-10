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

pro <- rd("prolific_survey_data.csv")
ber <- rd("berkeley_survey_data.csv")
bu1 <- rd("bu_qm221_survey_data.csv")
bu2 <- rd("bu_qm222_survey_data.csv")

# combine BU classes
common <- intersect(names(bu1), names(bu2))
bu1c <- bu1[common]; bu1c[] <- lapply(bu1c, as.character)
bu2c <- bu2[common]; bu2c[] <- lapply(bu2c, as.character)
if ("id" %in% common) {
  bu1c$id <- paste0("qm221_", bu1c$id)
  bu2c$id <- paste0("qm222_", bu2c$id)
}
bu <- rbind(bu1c, bu2c)
bu[] <- lapply(bu, function(x) type.convert(x, as.is = TRUE))

for (nmd in c("pro", "ber", "bu")) {
  d <- get(nmd)
  cat("Dataset", nmd, "rows:", nrow(d), "\n")
  cat("  columns:", paste(names(d), collapse = ", "), "\n")
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

normstr <- function(x) trimws(tolower(as.character(x)))

# attention check: keep the modal (passing) response
attention_keep <- function(d) {
  if (!"attention_check" %in% names(d)) return(rep(TRUE, nrow(d)))
  a <- normstr(d$attention_check)
  share_nonmiss <- mean(!is.na(a) & a != "")
  cat("  attention_check non-missing share:", share_nonmiss, "\n")
  # if the attention check is essentially unrecorded (data already screened), keep everyone
  if (share_nonmiss < 0.5) {
    cat("  attention_check mostly missing; no attention-based exclusion applied\n")
    return(rep(TRUE, nrow(d)))
  }
  tab <- sort(table(a), decreasing = TRUE)
  cat("  attention_check values:", paste(names(tab), tab, sep = "=", collapse = "; "), "\n")
  vals <- names(tab)
  if (all(vals %in% c("0", "1"))) return(!is.na(a) & a == "1")
  if (all(vals %in% c("true", "false"))) return(!is.na(a) & a == "true")
  !is.na(a) & a == vals[1]
}

# WTP matrix (participants x thresholds)
get_wtp <- function(d) {
  nm <- names(d)
  pcols <- nm[grepl("^preference_[0-9]+$", nm)]
  xs <- as.numeric(sub("^preference_", "", pcols))
  o <- order(xs); pcols <- pcols[o]; xs <- xs[o]
  W <- matrix(NA_real_, nrow(d), length(xs))
  for (j in seq_along(xs)) {
    X <- xs[j]
    pref <- d[[pcols[j]]]
    amt_c <- nm[grepl(paste0("(^|_)", X, "($|_)"), nm) & !grepl("^preference", nm)]
    amt_c <- amt_c[vapply(d[amt_c], is.numeric, logical(1))]
    if (is.numeric(pref) && any(pref < 0, na.rm = TRUE)) {
      W[, j] <- pref
    } else if (length(amt_c) > 0) {
      neg <- amt_c[vapply(amt_c, function(cc) any(d[[cc]] < 0, na.rm = TRUE), logical(1))]
      if (length(neg) > 0) {
        W[, j] <- d[[neg[1]]]
      } else {
        amt <- abs(d[[amt_c[1]]])
        if (is.numeric(pref)) {
          u <- sort(unique(pref[!is.na(pref)]))
          if (all(u %in% c(0, 1))) sgn <- ifelse(pref == 1, 1, -1)
          else if (all(u %in% c(1, 2))) sgn <- ifelse(pref == 1, 1, -1)
          else sgn <- sign(pref)
        } else {
          s <- normstr(pref)
          yes <- grepl("^(1|yes|y|true)$|^yes|want|recogn|public|shar", s) &
                 !grepl("^no|not|don|n't|anonym", s)
          sgn <- ifelse(yes, 1, -1)
        }
        W[, j] <- sgn * amt
        W[is.na(pref), j] <- NA
      }
    } else {
      W[, j] <- suppressWarnings(as.numeric(pref))
    }
  }
  list(W = W, xs = xs)
}

coherent_keep <- function(d, W) {
  nm <- names(d)
  fl <- nm[grepl("incoheren|coheren|exclu|final_sample|keep|include", nm, ignore.case = TRUE)]
  if (length(fl) > 0) {
    f <- fl[1]; v <- normstr(d[[f]])
    flag <- v %in% c("1", "true", "yes")
    cat("  using coherence flag column:", f, "\n")
    if (grepl("incoheren|exclu", f, ignore.case = TRUE)) return(!flag)
    return(flag)
  }
  # heuristic: incoherent if WTP profile changes direction more than twice
  apply(W, 1, function(w) {
    w <- w[!is.na(w)]
    if (length(w) < 3) return(TRUE)
    dd <- diff(w); dd <- dd[dd != 0]
    if (length(dd) < 2) return(TRUE)
    sum(diff(sign(dd)) != 0) <= 2
  })
}

# Round order from the timer columns: {anom,earn,rec}_{ord}_timer_PageSubmit,
# where ord is a 3-letter code (a = anonymous, e = earn/paid, r = recognition)
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
      cat("  order columns (typed numeric):", paste(numoc, collapse = ","), "\n")
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
  # explicit points columns in this dataset
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
  keepC <- coherent_keep(d, w$W)
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

# reference point: root of PRU where it crosses zero upward
disc <- r1^2 - 4 * r2 * r0
k <- NA_real_
if (abs(r2) < 1e-12) {
  k <- -r0 / r1
} else if (disc >= 0) {
  roots <- c((-r1 + sqrt(disc)) / (2 * r2), (-r1 - sqrt(disc)) / (2 * r2))
  slope <- r1 + 2 * r2 * roots
  up <- roots[slope > 0]
  if (length(up) == 0) up <- roots
  k <- up[which.min(abs(up - abar1))]
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