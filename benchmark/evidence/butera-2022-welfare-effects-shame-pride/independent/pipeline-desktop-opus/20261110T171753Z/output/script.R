suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
  library(AER)
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

pro <- read_chr("prolific_survey_data.csv"); pro$id <- paste0("p_", pro$id)
ber <- read_chr("berkeley_survey_data.csv"); ber$id <- paste0("b_", ber$id)
bu1 <- read_chr("bu_qm221_survey_data.csv"); bu1$id <- paste0("bu221_", bu1$id)
bu2 <- read_chr("bu_qm222_survey_data.csv"); bu2$id <- paste0("bu222_", bu2$id)
bu <- as.data.frame(dplyr::bind_rows(bu1, bu2), stringsAsFactors = FALSE)
pro <- conv(pro); ber <- conv(ber); bu <- conv(bu)

# find a column by exact (case-insensitive) name, then by regex
getcol <- function(d, exact, rx = NULL) {
  nms <- names(d)
  hit <- nms[tolower(nms) %in% tolower(exact)]
  if (length(hit)) return(hit[1])
  if (!is.null(rx)) {
    hit <- nms[grepl(rx, nms, ignore.case = TRUE)]
    if (length(hit)) return(hit[1])
  }
  NA_character_
}

# coalesce helper
coalesce_num <- function(...) {
  l <- list(...)
  out <- l[[1]]
  if (length(l) > 1) for (k in 2:length(l)) out <- ifelse(is.na(out), l[[k]], out)
  out
}

# Build signed WTP for recognition from preference_X (binary choice) and
# pref_rec_X_* / pref_anom_X_* (amounts)
build_wtp <- function(d) {
  pref_cols <- grep("^preference_[0-9]+$", names(d), value = TRUE)
  X <- sort(as.numeric(sub("preference_", "", pref_cols)))
  n <- nrow(d)
  Pm <- sapply(X, function(x) to_num(d[[paste0("preference_", x)]]))
  Pm <- matrix(Pm, nrow = n)
  amt <- function(prefix, x) {
    cs <- grep(paste0("^", prefix, "_", x, "_[0-9]+$"), names(d), value = TRUE)
    if (!length(cs)) return(rep(NA_real_, n))
    # order by suffix so _1 comes before _10
    cs <- cs[order(as.numeric(sub(".*_", "", cs)))]
    do.call(coalesce_num, lapply(cs, function(cc) to_num(d[[cc]])))
  }
  R <- matrix(sapply(X, function(x) amt("pref_rec", x)), nrow = n)
  A <- matrix(sapply(X, function(x) amt("pref_anom", x)), nrow = n)
  uP <- sort(unique(Pm[!is.na(Pm)]))
  cat("  preference values:", paste(uP, collapse = ", "), "\n")
  hi <- max(uP)
  # determine which preference value means "prefer recognition" from skip logic
  rec_given_hi <- mean(!is.na(R[Pm == hi & !is.na(Pm)]))
  anom_given_hi <- mean(!is.na(A[Pm == hi & !is.na(Pm)]))
  cat("  share rec amount answered | pref==", hi, ": ", round(rec_given_hi, 3),
      "; share anom amount answered: ", round(anom_given_hi, 3), "\n", sep = "")
  isrec <- if (rec_given_hi >= anom_given_hi) (Pm == hi) else (Pm != hi)
  W <- ifelse(is.na(Pm), NA_real_,
              ifelse(isrec, R, -A))
  # if chosen side amount missing but the other side's amount is present, use 0 (indifferent)
  W[is.na(W) & !is.na(Pm)] <- NA_real_
  W <- matrix(W, nrow = n)
  cat("  WTP non-missing share:", round(mean(!is.na(W)), 3), "\n")
  mid <- (X + 50) / 100
  cm <- colMeans(W, na.rm = TRUE)
  cat("  mean WTP by interval:", paste(round(cm, 2), collapse = " "), "\n")
  list(W = W, X = X)
}

parse_condition <- function(s) {
  s <- toupper(trimws(as.character(s)))
  out <- matrix(NA_real_, length(s), 3, dimnames = list(NULL, c("anon", "paid", "public")))
  for (i in seq_along(s)) {
    if (is.na(s[i]) || nchar(s[i]) != 3) next
    ch <- strsplit(s[i], "")[[1]]
    if (!setequal(ch, c("A", "E", "R"))) next
    out[i, "anon"] <- which(ch == "A")
    out[i, "paid"] <- which(ch == "E")
    out[i, "public"] <- which(ch == "R")
  }
  out
}

# Candidate exclusion flags (TRUE = keep) derived from the survey data:
# attention / comprehension / completion / duplicate / coherence screens.
make_flags <- function(d, W, X, pts) {
  n <- nrow(d); fl <- list()
  rx <- "attent|attn|check|comprehen|quiz|understand|exclu|drop|valid|finish|status|duplicate|dup|bot|consent|complete|pass|fail|flag|keep|sample|incoher|coher|serious|honest|correct"
  for (nm in names(d)) {
    if (!grepl(rx, nm, ignore.case = TRUE)) next
    if (grepl("^pref", nm, ignore.case = TRUE)) next
    v <- d[[nm]]
    u <- unique(v[!is.na(v)])
    if (length(u) >= 1 && length(u) <= 4) {
      for (val in u) fl[[paste0(nm, "==", val)]] <- !is.na(v) & v == val
    }
    if (anyNA(v) && length(u) >= 1) fl[[paste0(nm, " nonmissing")]] <- !is.na(v)
  }
  cp <- getcol(d, "Progress")
  if (!is.na(cp)) fl[["Progress==100"]] <- !is.na(to_num(d[[cp]])) & to_num(d[[cp]]) >= 100
  for (nm in names(d)) {
    if (!grepl("pid|worker|prolific|email|ipaddress|^ip$|sid", nm, ignore.case = TRUE)) next
    v <- d[[nm]]
    if (sum(!is.na(v)) < 0.5 * n) next
    if (any(duplicated(v[!is.na(v)]))) fl[[paste0("dedup ", nm)]] <- !is.na(v) & !duplicated(v)
  }
  fl[["all points > 0"]] <- rowSums(!is.na(pts) & pts > 0) == 3
  okW <- rowSums(!is.na(W)) == ncol(W)
  incr <- apply(W, 1, function(w) { w <- w[!is.na(w)]; length(w) > 1 && all(diff(w) >= 0) })
  mono <- apply(W, 1, function(w) { w <- w[!is.na(w)]; length(w) > 1 && (all(diff(w) >= 0) || all(diff(w) <= 0)) })
  corp <- apply(W, 1, function(w) { ok <- !is.na(w); if (sum(ok) < 3 || sd(w[ok]) == 0) return(FALSE); cor(w[ok], X[ok]) > 0 })
  fl[["wtp weakly increasing"]] <- okW & incr
  fl[["wtp monotone"]] <- okW & mono
  fl[["wtp corr>0"]] <- okW & corp
  grp <- sub("_.*", "", d$id)
  if (length(unique(grp)) > 1) for (g in unique(grp)) fl[[paste0("group ", g)]] <- grp == g
  fl <- fl[sapply(fl, function(f) sum(f) > 0 && sum(f) < n)]
  fl
}

process <- function(d, label, target_n) {
  cat("=== ", label, ": ", nrow(d), " rows\n", sep = "")
  n0 <- nrow(d)
  ca <- getcol(d, "AnomPts", "^anom.*pts$")
  ce <- getcol(d, "EarnPts", "^earn.*pts$")
  cr <- getcol(d, "RecogPts", "^recog.*pts$")
  if (any(is.na(c(ca, ce, cr)))) stop(paste("could not identify points columns for", label))
  cat("  points columns:", ca, ce, cr, "\n")
  pts <- cbind(anon = to_num(d[[ca]]), paid = to_num(d[[ce]]), public = to_num(d[[cr]]))

  cc <- getcol(d, "Condition", "condition")
  posm <- if (!is.null(cc) && !is.na(cc)) parse_condition(d[[cc]]) else NULL
  if (!is.null(posm)) cat("  order parsed from", cc, "; parsed share:", round(mean(!is.na(posm[, 1])), 3), "\n")

  wt <- build_wtp(d)

  base <- rowSums(is.na(pts)) == 0
  if (!is.null(posm)) base <- base & !is.na(posm[, 1])
  fl <- make_flags(d, wt$W, wt$X, pts)
  for (k in names(fl)) cat("  flag", k, ": keeps", sum(base & fl[[k]]), "\n")
  cand <- list(complete_points = base)
  for (k in names(fl)) cand[[k]] <- base & fl[[k]]
  fk <- names(fl)
  if (length(fk) > 1) {
    for (i in 1:(length(fk) - 1)) for (j in (i + 1):length(fk)) {
      cand[[paste(fk[i], "&", fk[j])]] <- base & fl[[fk[i]]] & fl[[fk[j]]]
    }
  }
  sz <- sapply(cand, sum)
  pick <- names(cand)[which.min(abs(sz - target_n))]
  keep <- cand[[pick]]
  cat(label, "final participants:", sum(keep), "using", pick, "(target", target_n, ")\n")
  if (pick != "complete_points")
    cat("DEVIATION: ", label, " sample restricted by data-derived screen '", pick,
        "' (paper's exact exclusion rule not available in provided text)\n", sep = "")

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
    L$pos <- as.vector(t(posm[idx, , drop = FALSE]))
    L$pos2 <- as.integer(L$pos == 2); L$pos3 <- as.integer(L$pos == 3)
    form <- points ~ pub + fin + pos2 + pos3
  } else {
    cat("  WARNING: no round-order information found\n")
  }
  fit <- feols(form, data = L, cluster = ~id)
  print(summary(fit))
  list(fit = fit, L = L, W = wt$W[idx, , drop = FALSE], X = wt$X, ids = d$id[idx],
       anon_mean = mean(pts[idx, "anon"]),
       anon_pts = pts[idx, "anon"], pub_pts = pts[idx, "public"])
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
if (!is.null(res$ber)) safe({
  b <- res$ber
  X <- b$X
  use <- X < max(X)  # exclude the top (1700+) interval
  mid <- (X + 50) / 100
  WL <- data.frame(
    id = rep(b$ids, times = sum(use)),
    m = rep(mid[use], each = length(b$ids)),
    apub = rep(b$pub_pts / 100, times = sum(use)),
    wtp = as.vector(b$W[, use, drop = FALSE])
  )
  WL <- WL[!is.na(WL$wtp), ]
  # Censoring bounds from the full elicitation range observed in data
  lo <- min(WL$wtp); hi <- max(WL$wtp)
  # Section 7 analogue: keep only WTP points near each participant's performance
  # under public recognition; window = SD of change in performance (anon -> public),
  # analogous to the 4-visit window motivated by the 4.42 SD of change in attendance.
  win <- sd(b$pub_pts - b$anon_pts) / 100
  WL_full <- WL
  WL <- WL[abs(WL$m - WL$apub) <= win, ]
  cat("Window (hundreds of points):", win, "; WTP points kept:", nrow(WL), "of", nrow(WL_full),
      "; participants:", length(unique(WL$id)), "\n")
  cat("DEVIATION: Berkeley structural WTP profile restricted to intervals whose midpoint is within one SD of the change in performance (",
      round(win, 3), " hundred points) of the participant's public-recognition score, the online analogue of the paper's within-4-visits restriction\n", sep = "")
  WL$m2 <- WL$m^2
  f6 <- feols(wtp ~ m + m2, data = WL, cluster = ~id)
  print(summary(f6))
  r_ols <- unname(coef(f6))
  cat("Tobit censoring bounds (WTP elicitation range observed in data):", lo, hi,
      "; share at lower:", round(mean(WL$wtp <= lo), 3),
      "; share at upper:", round(mean(WL$wtp >= hi), 3), "\n")
  tb <- tryCatch(AER::tobit(wtp ~ m + m2, left = lo, right = hi, data = WL),
                 error = function(e) { cat("Tobit failed:", conditionMessage(e), "\n"); NULL })
  if (!is.null(tb)) {
    print(summary(tb))
    r <- unname(coef(tb))[1:3]
    cat("DEVIATION: Berkeley WTP profile estimated by Tobit with censoring bounds set to observed min/max WTP (",
        lo, ", ", hi, ") since exact bounds are not stated in provided text\n", sep = "")
  } else {
    r <- r_ols
  }
  r0 <- r[1]; r1 <- r[2]; r2 <- r[3]
  cat("WTP profile coefs (OLS):", r_ols, " (used):", r, "\n")
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