suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/butera_2022_welfare_effects_shame_pride.script-free/Packet/Raw Data"
rd <- function(f) as.data.frame(read_csv(file.path(base, f), show_col_types = FALSE, guess_max = 100000))

pro <- rd("prolific_survey_data.csv")
ber <- rd("berkeley_survey_data.csv")
bu1 <- rd("bu_qm221_survey_data.csv")
bu2 <- rd("bu_qm222_survey_data.csv")
bu1$id <- paste0("qm221_", bu1$id)
bu2$id <- paste0("qm222_", bu2$id)
bu <- bind_rows(lapply(list(bu1, bu2), function(d) mutate(d, across(everything(), as.character))))
bu <- type.convert(bu, as.is = TRUE)

for (nm in c("pro", "ber", "bu")) {
  d <- get(nm)
  cat("## ", nm, " rows=", nrow(d), "\n", sep = "")
  cat("## columns: ", paste(names(d), collapse = ","), "\n", sep = "")
}

# ---------------- helpers ----------------
pass_attn <- function(x) {
  if (is.logical(x)) return(!is.na(x) & x)
  if (is.numeric(x)) {
    u <- sort(unique(na.omit(x)))
    if (all(u %in% c(0, 1))) return(!is.na(x) & x == 1)
    warning("attention_check numeric with values beyond 0/1; keeping non-missing")
    return(!is.na(x))
  }
  s <- tolower(trimws(as.character(x)))
  !is.na(s) & (s %in% c("1", "true", "pass", "passed", "yes", "correct", "t", "y"))
}

pref_sign <- function(p) {
  if (is.logical(p)) return(ifelse(p, 1, -1))
  if (is.numeric(p)) {
    u <- sort(unique(na.omit(p)))
    if (all(u %in% c(0, 1))) return(ifelse(p == 1, 1, -1))
    if (all(u %in% c(1, 2))) return(ifelse(p == 1, 1, -1))
    return(sign(p))
  }
  s <- tolower(trimws(as.character(p)))
  ifelse(is.na(s), NA,
         ifelse(grepl("not|^no|don|anonym|private|hidden", s), -1, 1))
}

get_wtp <- function(d) {
  pc <- grep("^preference_[0-9]+$", names(d), value = TRUE)
  ks <- as.numeric(sub("preference_", "", pc))
  o <- order(ks); pc <- pc[o]; ks <- ks[o]
  # look for amount columns with the same suffixes
  m <- regmatches(names(d), regexec("^(.*)_([0-9]+)$", names(d)))
  pref <- unique(unlist(lapply(m, function(z) if (length(z) == 3) z[2] else NULL)))
  pref <- setdiff(pref, "preference")
  cand <- pref[sapply(pref, function(p) all(paste0(p, "_", ks) %in% names(d)))]
  amt <- NULL
  if (length(cand) > 0) {
    pri <- cand[grepl("wtp|amount|value|price|bid|willing|pay|money", tolower(cand))]
    chosen <- if (length(pri) > 0) pri[1] else cand[1]
    amt <- paste0(chosen, "_", ks)
    cat("## WTP amount columns prefix: ", chosen, "\n", sep = "")
  }
  W <- matrix(NA_real_, nrow(d), length(ks))
  for (j in seq_along(ks)) {
    p <- d[[pc[j]]]
    if (is.null(amt)) {
      W[, j] <- suppressWarnings(as.numeric(p))
    } else {
      a <- abs(suppressWarnings(as.numeric(d[[amt[j]]])))
      W[, j] <- pref_sign(p) * a
    }
  }
  list(W = W, ks = ks)
}

coherent <- function(w) {
  w <- w[!is.na(w)]
  if (length(w) == 0) return(FALSE)
  if (length(w) < 2) return(TRUE)
  s <- sign(diff(w)); s <- s[s != 0]
  if (length(s) == 0) return(TRUE)
  r <- rle(s)$values
  length(r) <= 1 || (length(r) == 2 && r[1] == 1)
}

classify <- function(x) {
  x <- tolower(x)
  ifelse(grepl("paid|pay|incent|money|financ|bonus", x), "paid",
         ifelse(grepl("public|share|recog|named", x), "public",
                ifelse(grepl("anon", x), "anon", NA)))
}

find_rounds <- function(d) {
  nm <- names(d); low <- tolower(nm)
  isnum <- sapply(d, is.numeric)
  pts <- nm[isnum & grepl("point|score|click|press|effort", low) &
              !grepl("order|belief|expect|predict|guess|forecast|prefer|wtp|position", low)]
  ty <- classify(pts)
  out <- list()
  for (t in c("anon", "public", "paid")) {
    cc <- pts[!is.na(ty) & ty == t]
    out[[t]] <- if (length(cc) > 0) cc[1] else NA
  }
  cat("## points columns: ", paste(names(out), unlist(out), sep = "=", collapse = "; "), "\n", sep = "")
  out
}

find_order <- function(d, n) {
  nm <- names(d); low <- tolower(nm)
  oc <- nm[grepl("order|position|sequence", low)]
  cat("## order columns: ", paste(oc, collapse = ","), "\n", sep = "")
  if (length(oc) == 0) return(NULL)
  ty <- classify(oc)
  res <- list()
  for (t in c("anon", "public", "paid")) {
    cc <- oc[!is.na(ty) & ty == t]
    if (length(cc) > 0) res[[t]] <- as.character(d[[cc[1]]])
  }
  if (length(res) == 3) return(res)
  # single string column describing the sequence
  for (cname in oc) {
    s <- tolower(as.character(d[[cname]]))
    pa <- regexpr("paid|pay|incent|financ|bonus", s)
    pu <- regexpr("public|share|recog", s)
    an <- regexpr("anon", s)
    an2 <- an
    if (all(pa[!is.na(s)] > 0) && all(pu[!is.na(s)] > 0) && all(an[!is.na(s)] > 0)) {
      pos <- cbind(an, pu, pa)
      rk <- t(apply(pos, 1, rank))
      return(list(anon = as.character(rk[, 1]), public = as.character(rk[, 2]), paid = as.character(rk[, 3])))
    }
  }
  NULL
}

prep_sample <- function(d, label) {
  keep <- pass_attn(d$attention_check)
  cat("## ", label, ": attention pass ", sum(keep), " of ", nrow(d), "\n", sep = "")
  d <- d[keep, , drop = FALSE]
  wt <- get_wtp(d)
  coh <- apply(wt$W, 1, coherent)
  cat("## ", label, ": coherent ", sum(coh), " of ", nrow(d), "\n", sep = "")
  list(d = d[coh, , drop = FALSE], W = wt$W[coh, , drop = FALSE], ks = wt$ks)
}

run_t5 <- function(s, label) {
  d <- s$d; n <- nrow(d)
  rc <- find_rounds(d)
  if (any(is.na(unlist(rc)))) stop("could not identify round points columns for ", label)
  long <- data.frame(
    id = rep(d$id, 3),
    round = rep(c("anon", "public", "paid"), each = n),
    points = c(d[[rc$anon]], d[[rc$public]], d[[rc$paid]]),
    stringsAsFactors = FALSE
  )
  ord <- find_order(d, n)
  long$pr <- as.integer(long$round == "public")
  long$fi <- as.integer(long$round == "paid")
  if (!is.null(ord)) {
    long$ord <- c(ord$anon, ord$public, ord$paid)
    m <- feols(points ~ pr + fi + factor(ord), data = long, cluster = ~id)
  } else {
    warning("no round-order information found for ", label, "; estimating without order dummies")
    m <- feols(points ~ pr + fi, data = long, cluster = ~id)
  }
  print(summary(m))
  list(m = m, anon_mean = mean(d[[rc$anon]], na.rm = TRUE), n = nobs(m))
}

res <- list()
safe <- function(expr) tryCatch(expr, error = function(e) { cat("## ERROR: ", conditionMessage(e), "\n"); NULL })

s_pro <- safe(prep_sample(pro, "prolific"))
s_ber <- safe(prep_sample(ber, "berkeley"))
s_bu  <- safe(prep_sample(bu, "bu"))

t_pro <- if (!is.null(s_pro)) safe(run_t5(s_pro, "prolific")) else NULL
t_ber <- if (!is.null(s_ber)) safe(run_t5(s_ber, "berkeley")) else NULL
t_bu  <- if (!is.null(s_bu))  safe(run_t5(s_bu, "bu")) else NULL

getc <- function(t, v) if (is.null(t)) NA else unname(coef(t$m)[v])

res$public_recognition_points_prolific_table5_col1 <- getc(t_pro, "pr")
res$financial_incentives_points_prolific_table5_col1 <- getc(t_pro, "fi")
res$public_recognition_points_berkeley_table5_col2 <- getc(t_ber, "pr")
res$financial_incentives_points_berkeley_table5_col2 <- getc(t_ber, "fi")
res$public_recognition_points_bu_table5_col3 <- getc(t_bu, "pr")
res$financial_incentives_points_bu_table5_col3 <- getc(t_bu, "fi")
res$n_obs_prolific_table5_col1 <- if (is.null(t_pro)) NA else t_pro$n
res$n_obs_berkeley_table5_col2 <- if (is.null(t_ber)) NA else t_ber$n
res$n_obs_bu_table5_col3 <- if (is.null(t_bu)) NA else t_bu$n

# ---------------- Structural (Berkeley, action signaling) ----------------
res$action_signaling_gamma1_berkeley_table7_panelA <- NA
res$action_signaling_rho_berkeley_table7_panelA <- NA
res$cost_parameter_c_berkeley_table7_panelA <- NA
res$predicted_financial_incentive_effect_berkeley_table7_panelC <- NA

safe({
  if (is.null(s_ber) || is.null(t_ber)) stop("Berkeley inputs unavailable")
  ks <- s_ber$ks
  use <- which(ks < max(ks))  # drop the top (1700+) interval
  W <- s_ber$W
  wl <- data.frame(
    id = rep(s_ber$d$id, length(use)),
    a = rep((ks[use] + 50) / 100, each = nrow(W)),
    wtp = as.vector(W[, use])
  )
  wl <- wl[!is.na(wl$wtp), ]
  m6 <- feols(wtp ~ a + I(a^2), data = wl, cluster = ~id)
  print(summary(m6))
  r <- unname(coef(m6)); r0 <- r[1]; r1 <- r[2]; r2 <- r[3]
  bpr <- unname(coef(t_ber$m)["pr"]) / 100
  abar <- t_ber$anon_mean / 100 + bpr
  cat("## abar (hundreds, with PR) = ", abar, " ; PR effect (hundreds) = ", bpr, "\n", sep = "")
  disc <- r1^2 - 4 * r2 * r0
  if (abs(r2) < 1e-12) {
    roots <- -r0 / r1
  } else if (disc >= 0) {
    roots <- c((-r1 - sqrt(disc)) / (2 * r2), (-r1 + sqrt(disc)) / (2 * r2))
  } else stop("reduced-form PRU has no real root")
  slope <- r1 + 2 * r2 * roots
  okr <- roots[slope > 0]
  if (length(okr) == 0) okr <- roots
  xstar <- okr[which.min(abs(okr - abar))]
  rho <- xstar / abar
  gamma1 <- r1 + 2 * r2 * xstar
  cpar <- (r1 + 2 * r2 * abar) / bpr
  p <- 0.05 * 10  # 5 cents per 10 points = $0.50 per hundred points
  pred <- p / cpar
  res$action_signaling_gamma1_berkeley_table7_panelA <- gamma1
  res$action_signaling_rho_berkeley_table7_panelA <- rho
  res$cost_parameter_c_berkeley_table7_panelA <- cpar
  res$predicted_financial_incentive_effect_berkeley_table7_panelC <- pred
  TRUE
})

for (k in names(res)) {
  v <- res[[k]]
  cat(sprintf("RESULT:%s=%s\n", k, ifelse(is.na(v), "NA", format(v, digits = 10))))
}
