suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/butera_2022_welfare_effects_shame_pride.script-free/Packet/Raw Data"

read_one <- function(f, tag) {
  d <- suppressMessages(readr::read_csv(file.path(base, f), show_col_types = FALSE, guess_max = 100000))
  d <- as.data.frame(d)
  d$id <- paste0(tag, "_", d$id)
  d
}

prolific <- read_one("prolific_survey_data.csv", "pro")
berkeley <- read_one("berkeley_survey_data.csv", "brk")
bu1 <- read_one("bu_qm221_survey_data.csv", "bu1")
bu2 <- read_one("bu_qm222_survey_data.csv", "bu2")
common <- intersect(names(bu1), names(bu2))
bu <- rbind(bu1[, common], bu2[, common])

cat("Prolific columns:\n"); print(names(prolific))
cat("Berkeley columns:\n"); print(names(berkeley))

# ---------- helpers ----------
classify_round <- function(x) {
  x <- tolower(as.character(x))
  out <- rep(NA_character_, length(x))
  out[grepl("public|shar|recog", x)] <- "public"
  out[is.na(out) & grepl("paid|pay|incent|financ|bonus|money|cash", x)] <- "paid"
  out[is.na(out) & grepl("anon|private|base|control", x)] <- "anon"
  out
}

to_yes <- function(v) {
  if (is.logical(v)) return(v)
  if (is.numeric(v)) {
    u <- sort(unique(na.omit(v)))
    if (all(u %in% c(0, 1))) return(v == 1)
    if (all(u %in% c(1, 2))) return(v == 1)
    return(v > 0)
  }
  s <- tolower(trimws(as.character(v)))
  neg <- grepl("\\bno\\b|not|don|anonym|private|^n$", s)
  pos <- grepl("\\byes\\b|^y$|want|recogn|public|share|^1$|true", s)
  ifelse(is.na(s) | s == "", NA, pos & !neg)
}

attention_pass <- function(d) {
  if (!"attention_check" %in% names(d)) return(rep(TRUE, nrow(d)))
  v <- d$attention_check
  cat("attention_check values:\n"); print(table(v, useNA = "ifany"))
  if (is.logical(v)) return(!is.na(v) & v)
  if (is.numeric(v)) return(!is.na(v) & v == 1)
  s <- tolower(trimws(as.character(v)))
  !is.na(s) & (s %in% c("1", "true", "pass", "passed", "yes", "correct"))
}

# Build long participant x round data of points with round position
make_long <- function(d) {
  nm <- names(d)
  ptcols <- nm[grepl("point|score|click|press|effort", nm, ignore.case = TRUE) &
               !grepl("^preference", nm)]
  # Strategy A: points columns labelled by round type
  typ <- classify_round(ptcols)
  okA <- ptcols[!is.na(typ)]
  typA <- typ[!is.na(typ)]
  if (length(unique(typA)) == 3) {
    pc <- sapply(c("anon", "paid", "public"), function(t) okA[typA == t][1])
    ordcols <- nm[grepl("order|position|rank|seq", nm, ignore.case = TRUE)]
    otyp <- classify_round(ordcols)
    oc <- sapply(c("anon", "paid", "public"), function(t) {
      z <- ordcols[!is.na(otyp) & otyp == t]; if (length(z)) z[1] else NA_character_ })
    cat("Points columns used:", pc, "\nOrder columns used:", oc, "\n")
    L <- do.call(rbind, lapply(c("anon", "paid", "public"), function(t) {
      pos <- if (!is.na(oc[t])) d[[oc[t]]] else NA
      data.frame(id = d$id, round = t, points = suppressWarnings(as.numeric(d[[pc[t]]])),
                 position = pos, stringsAsFactors = FALSE)
    }))
    if (all(is.na(oc))) {
      # try a single order column describing the sequence
      oc1 <- ordcols[1]
      if (!is.na(oc1)) {
        seqs <- strsplit(as.character(d[[oc1]]), "[^A-Za-z]+")
        posm <- t(sapply(seqs, function(s) {
          cl <- classify_round(s[s != ""])
          sapply(c("anon", "paid", "public"), function(t) { w <- which(cl == t); if (length(w)) w[1] else NA })
        }))
        L$position <- c(posm[, "anon"], posm[, "paid"], posm[, "public"])
      }
    }
    return(L)
  }
  # Strategy B: round-numbered columns (round1_points, round1_type ...)
  rp <- lapply(1:3, function(k) {
    pcol <- nm[grepl(paste0("(round|r)_?", k), nm, ignore.case = TRUE) &
                 grepl("point|score|click", nm, ignore.case = TRUE)][1]
    tcol <- nm[grepl(paste0("(round|r)_?", k), nm, ignore.case = TRUE) &
                 grepl("type|treat|cond|name|arm", nm, ignore.case = TRUE)][1]
    if (is.na(pcol)) pcol <- nm[grepl(paste0("^(points|score)_?", k, "$"), nm, ignore.case = TRUE)][1]
    if (is.na(tcol)) tcol <- nm[grepl(paste0("^(type|treatment|condition|round_type)_?", k, "$"), nm, ignore.case = TRUE)][1]
    c(pcol, tcol)
  })
  cat("Strategy B columns:\n"); print(rp)
  do.call(rbind, lapply(1:3, function(k) {
    data.frame(id = d$id, round = classify_round(d[[rp[[k]][2]]]),
               points = suppressWarnings(as.numeric(d[[rp[[k]][1]]])), position = k,
               stringsAsFactors = FALSE)
  }))
}

# WTP profile (long): id, lower, wtp
make_wtp <- function(d) {
  nm <- names(d)
  pref <- nm[grepl("^preference_\\d+$", nm)]
  lows <- as.numeric(sub("^preference_", "", pref))
  out <- list()
  for (j in seq_along(pref)) {
    X <- lows[j]
    v <- d[[pref[j]]]
    if (is.numeric(v) && any(v < 0, na.rm = TRUE)) {
      w <- v
    } else {
      cand <- nm[grepl(paste0("(^|_)", X, "(_|$)"), nm) & nm != pref[j] &
                   !grepl("^preference_\\d+$|point|score|attention", nm)]
      yescols <- cand[grepl("yes", cand, ignore.case = TRUE)]
      nocols <- cand[grepl("(^|_)no(_|$)", cand, ignore.case = TRUE)]
      other <- setdiff(cand, c(yescols, nocols))
      coalesce_cols <- function(cs) {
        if (!length(cs)) return(rep(NA_real_, nrow(d)))
        m <- sapply(cs, function(cc) suppressWarnings(as.numeric(d[[cc]])))
        if (is.null(dim(m))) m <- matrix(m, ncol = 1)
        apply(m, 1, function(r) { r <- r[!is.na(r)]; if (length(r)) r[1] else NA_real_ })
      }
      y <- to_yes(v)
      if (length(yescols) || length(nocols)) {
        a_yes <- coalesce_cols(yescols); a_no <- coalesce_cols(nocols)
        w <- ifelse(is.na(y), NA, ifelse(y, a_yes, -a_no))
      } else if (length(other)) {
        a <- abs(coalesce_cols(other))
        w <- ifelse(is.na(y), NA, ifelse(y, a, -a))
      } else {
        w <- suppressWarnings(as.numeric(v))
      }
      if (j == 1) cat("WTP columns for interval", X, ":", cand, "\n")
    }
    out[[j]] <- data.frame(id = d$id, lower = X, wtp = w, stringsAsFactors = FALSE)
  }
  do.call(rbind, out)
}

incoherent_flag <- function(d, W) {
  nm <- names(d)
  ic <- nm[grepl("incoher", nm, ignore.case = TRUE)]
  if (length(ic)) { v <- d[[ic[1]]]; return(setNames(as.logical(to_yes(v)), d$id)) }
  cc <- nm[grepl("^coher", nm, ignore.case = TRUE)]
  if (length(cc)) { v <- d[[cc[1]]]; return(setNames(!as.logical(to_yes(v)), d$id)) }
  # Fallback: profiles with no discernible relation to performance: more than two
  # direction changes in WTP across ordered intervals (not monotone or single-peaked)
  W <- W[order(W$id, W$lower), ]
  fl <- tapply(seq_len(nrow(W)), W$id, function(ix) {
    w <- W$wtp[ix]; w <- w[!is.na(w)]
    if (length(w) < 3) return(TRUE)
    s <- sign(diff(w)); s <- s[s != 0]
    if (length(s) < 2) return(FALSE)
    sum(diff(s) != 0) > 2
  })
  fl[as.character(d$id)]
}

final_sample <- function(d, label) {
  cat("\n=====", label, "===== N raw:", nrow(d), "\n")
  ap <- attention_pass(d)
  W <- make_wtp(d)
  inc <- incoherent_flag(d, W)
  inc[is.na(inc)] <- FALSE
  cat("pass attention:", sum(ap), " incoherent:", sum(inc), " both ok:", sum(ap & !inc), "\n")
  keep <- ap & !inc
  list(d = d[keep, ], W = W[W$id %in% d$id[keep], ])
}

run_t5 <- function(S, label) {
  L <- make_long(S$d)
  L <- L[!is.na(L$points) & !is.na(L$round), ]
  L$public <- as.integer(L$round == "public")
  L$paid <- as.integer(L$round == "paid")
  if (all(is.na(L$position))) {
    cat("WARNING: round order not found for", label, "; no order dummies\n")
    m <- feols(points ~ public + paid, data = L, cluster = ~id)
  } else {
    L$position <- factor(L$position)
    m <- feols(points ~ public + paid + position, data = L, cluster = ~id)
  }
  print(summary(m))
  list(m = m, L = L)
}

samples <- list(
  prolific = final_sample(prolific, "Prolific"),
  berkeley = final_sample(berkeley, "Berkeley"),
  bu = final_sample(bu, "BU")
)

res <- list()
fits <- list()
for (s in names(samples)) {
  r <- tryCatch(run_t5(samples[[s]], s), error = function(e) { cat("ERROR", s, conditionMessage(e), "\n"); NULL })
  fits[[s]] <- r
}

if (!is.null(fits$prolific)) {
  res$public_recognition_points_prolific_table5_col1 <- coef(fits$prolific$m)["public"]
  res$financial_incentives_points_prolific_table5_col1 <- coef(fits$prolific$m)["paid"]
  res$n_obs_prolific_table5_col1 <- nobs(fits$prolific$m)
}
if (!is.null(fits$berkeley)) {
  res$public_recognition_points_berkeley_table5_col2 <- coef(fits$berkeley$m)["public"]
  res$financial_incentives_points_berkeley_table5_col2 <- coef(fits$berkeley$m)["paid"]
  res$n_obs_berkeley_table5_col2 <- nobs(fits$berkeley$m)
}
if (!is.null(fits$bu)) {
  res$public_recognition_points_bu_table5_col3 <- coef(fits$bu$m)["public"]
  res$financial_incentives_points_bu_table5_col3 <- coef(fits$bu$m)["paid"]
  res$n_obs_bu_table5_col3 <- nobs(fits$bu$m)
}

# ---------- Structural action-signaling model, Berkeley ----------
tryCatch({
  W <- samples$berkeley$W
  W <- W[!is.na(W$wtp) & W$lower < 1700, ]
  W$a <- (W$lower + 50) / 100          # interval midpoint in hundreds of points
  W$a2 <- W$a^2
  m6 <- feols(wtp ~ a + a2, data = W, cluster = ~id)
  print(summary(m6))
  r0 <- unname(coef(m6)[1]); r1 <- unname(coef(m6)["a"]); r2 <- unname(coef(m6)["a2"])
  L <- fits$berkeley$L
  abar0 <- mean(L$points[L$round == "anon"], na.rm = TRUE) / 100
  delta <- unname(coef(fits$berkeley$m)["public"]) / 100
  abar_pub <- abar0 + delta
  # S(a - rho*abar) = g1 (a - x) + g2 (a - x)^2 with x = rho*abar matches R(a) = r0 + r1 a + r2 a^2
  # => g2 = r2, x is a root of R, g1 = R'(x)
  disc <- r1^2 - 4 * r2 * r0
  if (abs(r2) < 1e-12) {
    roots <- -r0 / r1
  } else if (disc >= 0) {
    roots <- c((-r1 + sqrt(disc)) / (2 * r2), (-r1 - sqrt(disc)) / (2 * r2))
  } else {
    roots <- -r1 / (2 * r2)
  }
  cat("roots of PRU:", roots, " abar_pub:", abar_pub, "\n")
  x <- roots[which.min(abs(roots - abar_pub))]
  rho <- x / abar_pub
  g1 <- r1 + 2 * r2 * x
  # FOC: theta - c a + R'(a) = 0  => average effect delta = R'(abar_pub) / c
  cpar <- (r1 + 2 * r2 * abar_pub) / delta
  p <- 0.5  # 5 cents per 10 points = $0.50 per hundred points
  res$action_signaling_gamma1_berkeley_table7_panelA <- g1
  res$action_signaling_rho_berkeley_table7_panelA <- rho
  res$cost_parameter_c_berkeley_table7_panelA <- cpar
  res$predicted_financial_incentive_effect_berkeley_table7_panelC <- p / cpar
}, error = function(e) cat("ERROR structural:", conditionMessage(e), "\n"))

cat("\n")
for (k in names(res)) cat(sprintf("RESULT:%s=%.6f\n", k, as.numeric(res[[k]])))
